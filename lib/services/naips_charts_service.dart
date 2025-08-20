import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chart_item.dart';
import 'naips_service.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

/// Service to fetch and parse NAIPS Chart Directory
class NaipsChartsService {
  final NAIPSService naipsService;
  NaipsChartsService({required this.naipsService});

  /// Fetches the NAIPS Chart Directory HTML (requires authenticated session cookies).
  /// Endpoint: https://www.airservicesaustralia.com/naips/ChartDirectory/ChartDirectorySearch
  Future<String> fetchDirectoryHtml() async {
    // Warm up ChartDirectory landing page to ensure required cookies for search
    try {
      final warmHeaders = naipsService.buildAuthHeaders(referer: 'https://www.airservicesaustralia.com/naips/');
      final warmResp = await http.get(
        Uri.parse('https://www.airservicesaustralia.com/naips/ChartDirectory'),
        headers: warmHeaders,
      );
      debugPrint('DEBUG: ChartsService - warm ChartDirectory status=${warmResp.statusCode}');
      final warmBody = utf8.decode(warmResp.bodyBytes);
      // If this is the login page, stop early so the caller can authenticate
      if (warmBody.contains('User Not Logged in') || warmBody.contains('Login') || warmBody.contains('User Name')) {
        throw Exception('NAIPS charts require login. Please check credentials.');
      }

      // Emulate pressing the Submit button by scraping the form and then posting to the Search endpoint
      final _FormPost form = _extractDirectoryForm(warmBody);
      // Ensure exact fields the browser sends
      form.fields['SearchCriteria'] = form.fields['SearchCriteria'] ?? '';
      form.fields['ChartCategory'] = form.fields['ChartCategory'] ?? 'None';
      // Server expects this specific submit name
      form.fields['SubmitChartSearch'] = 'Submit';
      // Force target to ChartDirectorySearch; the Search page produces the initial listing
      final actionUri = Uri.parse('https://www.airservicesaustralia.com/naips/ChartDirectory/ChartDirectorySearch');
      debugPrint('DEBUG: ChartsService - form action: ${form.action ?? '(null)'} -> posting to ${actionUri.toString()}');
      debugPrint('DEBUG: ChartsService - form submit name: ${form.submitName ?? '(none)'}');
      debugPrint('DEBUG: ChartsService - form fields count: ${form.fields.length}');

      final stdHeaders = naipsService.buildAuthHeaders(referer: 'https://www.airservicesaustralia.com/naips/ChartDirectory/ChartDirectorySearch');

      // POST the form fields to the Search endpoint (this is what the browser does)
      final postHeaders = {
        ...stdHeaders,
        'Content-Type': 'application/x-www-form-urlencoded',
        'Origin': 'https://www.airservicesaustralia.com',
      };
      final postResp = await http.post(actionUri, headers: postHeaders, body: form.fields);
      debugPrint('DEBUG: ChartsService - POST action status=${postResp.statusCode} length=${postResp.bodyBytes.length}');
      if (postResp.statusCode == 200) {
        final body = utf8.decode(postResp.bodyBytes);
        final sample = body.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');
        debugPrint('DEBUG: ChartsService - body sample: ${sample.substring(0, sample.length > 240 ? 240 : sample.length)}');
        if (!(body.contains('User Not Logged in') || body.contains('Login'))) {
          return body;
        }
      }
    } catch (e) {
      debugPrint('DEBUG: ChartsService - warm ChartDirectory error: $e');
    }

    // Fallback: try a direct GET as before (in case POST is not required in some sessions)
    // Fallback: GET the Search endpoint (legacy)
    final searchUri = Uri.parse('https://www.airservicesaustralia.com/naips/ChartDirectory/ChartDirectorySearch');
    final headers = naipsService.buildAuthHeaders(referer: 'https://www.airservicesaustralia.com/naips/ChartDirectory/ChartDirectorySearch');
    final response = await http.get(searchUri, headers: headers);
    debugPrint('DEBUG: ChartsService - ChartDirectorySearch GET status=${response.statusCode}');
    final body2 = utf8.decode(response.bodyBytes);
    debugPrint('DEBUG: ChartsService - GET returned body length=${response.bodyBytes.length}');
    if (response.statusCode != 200) {
      throw Exception('NAIPS Chart Directory fetch failed: ${response.statusCode}');
    }
    if (body2.contains('User Not Logged in') || body2.contains('Login') || body2.contains('User Name')) {
      debugPrint('DEBUG: ChartsService - Received login page instead of directory');
      throw Exception('NAIPS charts require login. Please check credentials.');
    }
    return body2;
  }

  /// Fetch curated list of charts from the directory
  Future<List<ChartItem>> fetchCuratedCatalog() async {
    final html = await fetchDirectoryHtml();
    debugPrint('DEBUG: NAIPS charts directory fetched, length=${html.length}');
    return _parseDirectory(html);
  }

  // Parse the NAIPS Chart Directory HTML into curated ChartItem list
  List<ChartItem> _parseDirectory(String html) {
    final doc = html_parser.parse(html);
    final text = doc.body?.text ?? '';
    final List<ChartItem> items = [];

    // Strategy 0: Parse the main directory table by header columns (most reliable)
    try {
      final tables = doc.querySelectorAll('table');
      debugPrint('DEBUG: ChartsParser - tables found: ${tables.length}');
      dom.Element? dirTable;
      for (final t in tables) {
        final ths = t.querySelectorAll('th');
        final headers = ths.map((e) => e.text.trim().toUpperCase()).toList();
        if (headers.isNotEmpty) {
          debugPrint('DEBUG: ChartsParser - table headers: ${headers.join('|')}');
        }
        if (headers.contains('CODE') && headers.contains('NAME') && (headers.contains('VALID FROM') || headers.contains('VALIDFROM'))) {
          dirTable = t;
          break;
        }
        if (ths.isEmpty) {
          final firstRowTds = t.querySelector('tr')?.querySelectorAll('td') ?? [];
          final headerTexts = firstRowTds.map((e) => e.text.trim().toUpperCase()).toList();
          if (headerTexts.isNotEmpty) {
            debugPrint('DEBUG: ChartsParser - first row tds: ${headerTexts.join('|')}');
          }
          if (headerTexts.contains('CODE') && headerTexts.contains('NAME')) {
            dirTable = t;
            break;
          }
        }
      }

      // Fallback: choose the table with most rows where first cell looks like a 4-5 digit code
      if (dirTable == null) {
        int bestScore = 0;
        for (final t in tables) {
          int score = 0;
          for (final tr in t.querySelectorAll('tr')) {
            final tds = tr.querySelectorAll('td');
            if (tds.isEmpty) continue;
            final first = tds.first.text.trim();
            if (RegExp(r'^\d{4,5}$').hasMatch(first)) score++;
          }
          debugPrint('DEBUG: ChartsParser - table codeRows score: $score');
          if (score > bestScore) {
            bestScore = score;
            dirTable = t;
          }
        }
        if (bestScore > 0) {
          debugPrint('DEBUG: ChartsParser - selected table by codeRows: $bestScore');
        }
      }

      if (dirTable != null) {
        debugPrint('DEBUG: ChartsParser - directory table detected with ${dirTable.querySelectorAll('tr').length} rows');
        int rowIndex = 0;
        for (final tr in dirTable.querySelectorAll('tr')) {
          if (tr.querySelectorAll('th').isNotEmpty) continue; // skip header
          final tds = tr.querySelectorAll('td');
          if (tds.length < 2) continue;

          final codeText = tds[0].text.trim();
          // Expect 4-5 digit product code
          if (!RegExp(r'^\d{4,5}$').hasMatch(codeText)) continue;

          final name = tds.length > 1 ? tds[1].text.trim() : '';
          final fromText = tds.length > 2 ? tds[2].text.trim() : '';
          final tillText = tds.length > 3 ? tds[3].text.trim() : '';

          final from = _parseFullTimestamp(fromText) ?? _parseDayHourZ(_maybeExtractDayHourZ(fromText)) ?? DateTime.now().toUtc();
          final to = tillText.toUpperCase().contains('PERM') ? null : _parseFullTimestamp(tillText) ?? _parseDayHourZ(_maybeExtractDayHourZ(tillText));

          Uri? loRes;
          Uri? hiRes;
          Uri? pdf;
          // Search the row for any asset links
          for (final a in tr.querySelectorAll('a[href]')) {
            final href = a.attributes['href'] ?? '';
            if (href.isEmpty) continue;
            if (href.startsWith('javascript:')) continue; // skip JS anchors
            Uri abs;
            try {
              abs = _toAbs(href);
            } catch (_) {
              continue; // ignore malformed links
            }
            final h = href.toLowerCase();
            if (h.endsWith('.pdf')) { pdf ??= abs; continue; }
            if (h.endsWith('.jpg') || h.endsWith('.jpeg')) { hiRes ??= abs; continue; }
            if (h.endsWith('.png')) { loRes ??= abs; continue; }
            // Details page link (deferred resolution)
            if (h.contains('/chartdirectory/details/')) {
              if (h.contains('hires=true')) {
                hiRes ??= abs;
              } else {
                loRes ??= abs;
              }
            }
          }

          final category = _categorize(name);
          // Derive single-time charts (e.g., SIGWX, GP WINDS, SATPIC) as ±3h around the
          // single valid time. Prefer the table's Valid From when Valid Till is PERM; otherwise
          // fall back to a "VALID HHMMZ" token in the name.
          final bool singleTime = (to == null);
          final DateTime? nameValidAt = _extractValidAtFromName(name);
          final DateTime? validAt = singleTime ? from : nameValidAt;
          final DateTime fromAdj = (validAt != null) ? validAt.subtract(const Duration(hours: 3)) : from;
          final DateTime? toAdj = (validAt != null) ? validAt.add(const Duration(hours: 3)) : to;
          // Keep all recognized chart products; earlier we filtered too aggressively.

          final item = ChartItem(
            code: codeText,
            name: name,
            validFromUtc: fromAdj,
            validTillUtc: toAdj,
            validAtUtc: validAt,
            category: category,
            loResUrl: loRes,
            hiResUrl: hiRes,
            pdfUrl: pdf,
          );
          items.add(item);

          if (rowIndex < 5) {
            debugPrint('DEBUG: ChartsParser - row ${rowIndex + 1} parsed: code=$codeText name="$name" from="$fromText" till="$tillText" loRes=${loRes != null} hiRes=${hiRes != null} pdf=${pdf != null}');
          }
          rowIndex++;
        }
        debugPrint('DEBUG: ChartsParser - table rows parsed into ${items.length} items before ordering');
      }
    } catch (e) {
      debugPrint('DEBUG: ChartsParser - table parse error: $e');
    }

    // Strategy 1: Link-centric grouping (fallback; robust to layout changes)
    final Map<String, _ChartCandidate> codeToCandidate = {};
    final anchors = doc.querySelectorAll('a[href]');
    debugPrint('DEBUG: ChartsParser - anchors found: ${anchors.length}');
    int png = 0, jpg = 0, pdf = 0;
    for (final a in anchors) {
      final href = a.attributes['href'] ?? '';
      if (href.startsWith('javascript:')) continue;
      final label = a.text.trim();
      if (!_looksLikeChartLink(href, label)) continue;

      final abs = _toAbs(href);
      final code = _extractCode(href) ?? label.replaceAll(RegExp(r'\s+'), '_');
      final cat = _categorize(label.isNotEmpty ? label : href);
      final from = _inferTimeFromNode(a);
      final to = _inferEndFromNode(a);

      final cand = codeToCandidate.putIfAbsent(code, () => _ChartCandidate(code: code, name: label.isNotEmpty ? label : href, category: cat));
      cand.validFromUtc ??= from;
      cand.validTillUtc ??= to;
      if (href.toLowerCase().endsWith('.pdf')) { cand.pdfUrl = abs; pdf++; }
      if (href.toLowerCase().endsWith('.jpg')) { cand.hiResUrl = abs; jpg++; }
      if (href.toLowerCase().endsWith('.png')) { cand.loResUrl = abs; png++; }
      if (href.toLowerCase().contains('/chartdirectory/details/')) {
        if (href.toLowerCase().contains('hires=true')) {
          cand.hiResUrl ??= abs;
        } else {
          cand.loResUrl ??= abs;
        }
      }
    }
    debugPrint('DEBUG: ChartsParser - asset anchors by type: png=$png jpg=$jpg pdf=$pdf');

    // Promote curated candidates only
    for (final cand in codeToCandidate.values) {
      // Skip items without any asset URL
      if (cand.loResUrl == null && cand.hiResUrl == null && cand.pdfUrl == null) continue;
      // Prefer hi-res when available
      final name = cand.name;
      items.add(ChartItem(
        code: cand.code,
        name: name,
        validFromUtc: _deriveFrom(cand.validFromUtc, name),
        validTillUtc: _deriveTill(cand.validFromUtc, cand.validTillUtc, name),
        validAtUtc: _extractValidAtFromName(name) ?? cand.validFromUtc,
        category: cand.category,
        loResUrl: cand.loResUrl,
        hiResUrl: cand.hiResUrl,
        pdfUrl: cand.pdfUrl,
      ));
    }

    // Strategy 2: Heuristic line scan for validity windows (fills times when link context lacks them)
    if (items.isEmpty) {
      final lineRegex = RegExp(r'(MSL|MSLP|SIGWX|SIGMET|SATPIC|Grid Point Winds)[\s\S]*?(\d{2,5})?[\s\S]*?(\b\d{2}\d{2}Z)\s*(?:to|-)\s*(\d{2}\d{2}Z)?', caseSensitive: false);
      for (final m in lineRegex.allMatches(text)) {
        final name = m.group(0)!.trim();
        final code = m.group(2) ?? '';
        final from = _parseDayHourZ(m.group(3));
        final to = _parseDayHourZ(m.group(4));
        items.add(ChartItem(
          code: code,
          name: name,
          validFromUtc: from ?? DateTime.now().toUtc(),
          validTillUtc: to,
          category: _categorize(name),
        ));
      }
    } else {
      // Back-fill validity from surrounding text when missing
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (item.validTillUtc == null || item.validFromUtc == DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)) {
          final around = doc.body?.text ?? '';
          final m = RegExp(r'(\d{2})(\d{2})Z\s*(?:to|-)\s*(\d{2})(\d{2})Z', caseSensitive: false).firstMatch(around);
          if (m != null) {
            final from = _parseDayHourZ('${m.group(1)}${m.group(2)}Z');
            final to = _parseDayHourZ('${m.group(3)}${m.group(4)}Z');
            items[i] = ChartItem(
              code: item.code,
              name: item.name,
              validFromUtc: from ?? item.validFromUtc,
              validTillUtc: to ?? item.validTillUtc,
              category: item.category,
              level: item.level,
              cycleZ: item.cycleZ,
              loResUrl: item.loResUrl,
              hiResUrl: item.hiResUrl,
              pdfUrl: item.pdfUrl,
            );
          }
        }
      }
    }

    // Diagnostics: list categories and sample items before ordering
    debugPrint('DEBUG: ChartsParser - items before ordering: ${items.length}');
    final Map<String, int> catCounts = {};
    for (final it in items) {
      catCounts.update(it.category, (v) => v + 1, ifAbsent: () => 1);
    }
    debugPrint('DEBUG: ChartsParser - category counts: ' + catCounts.entries.map((e) => '${e.key}:${e.value}').join(', '));
    int iLog = 0;
    for (final it in items) {
      if (iLog++ >= 40) break; // cap log size
      debugPrint('DEBUG: ChartsParser - item: code=${it.code} name="${it.name}" cat=${it.category} from=${it.validFromUtc.toIso8601String()} till=${it.validTillUtc?.toIso8601String()}');
    }

    final result = items;

    result.sort((a, b) {
      final o = _orderKey(a).compareTo(_orderKey(b));
      if (o != 0) return o;
      if (a.isCurrentlyValid != b.isCurrentlyValid) return a.isCurrentlyValid ? -1 : 1;
      return a.validFromUtc.compareTo(b.validFromUtc);
    });

    debugPrint('DEBUG: ChartsParser - returning ${result.length} items after ordering');
    return result;
  }

  // (unused) legacy helper kept during development; consider removing once flow stabilizes

  // Capture the Chart Directory form (inputs, selects, submit button)
  _FormPost _extractDirectoryForm(String html) {
    final doc = html_parser.parse(html);
    final form = doc.querySelector('form');
    final Map<String, String> fields = {};
    String? action = form?.attributes['action'];
    String? submitName;

    // Inputs
    for (final input in form?.querySelectorAll('input') ?? <dom.Element>[]) {
      final type = (input.attributes['type'] ?? 'text').toLowerCase();
      final name = input.attributes['name'];
      if (name == null || name.isEmpty) continue;
      if (type == 'submit') {
        // Prefer the explicit submit button used by the page
        submitName ??= name;
        continue;
      }
      String value = input.attributes['value'] ?? '';
      // Force default values for known fields
      if (name.toLowerCase().contains('search')) value = '';
      fields[name] = value;
    }

    // Selects
    for (final select in form?.querySelectorAll('select') ?? <dom.Element>[]) {
      final name = select.attributes['name'];
      if (name == null || name.isEmpty) continue;
      final selected = select.querySelector('option[selected]');
      final first = select.querySelector('option');
      String value = selected?.attributes['value'] ?? first?.attributes['value'] ?? '';
      // Some sites want empty category to list all products
      if (name.toLowerCase().contains('category')) value = '';
      fields[name] = value;
    }

    // Add hidden fields too
    for (final hidden in form?.querySelectorAll('input[type="hidden"]') ?? <dom.Element>[]) {
      final name = hidden.attributes['name'];
      if (name == null || name.isEmpty) continue;
      fields.putIfAbsent(name, () => hidden.attributes['value'] ?? '');
    }

    // Include the submit button name/value if we found one
    if (submitName != null && submitName.isNotEmpty) {
      fields[submitName] = 'Submit';
    } else {
      // Fallback to a generic key used by some forms
      fields.putIfAbsent('Submit', () => 'Submit');
    }

    return _FormPost(action: action, fields: fields, submitName: submitName);
  }

  Uri _toAbs(String href) => Uri.parse(href.startsWith('http') ? href : 'https://www.airservicesaustralia.com$href');

  String _categorize(String name) {
    final n = name.toUpperCase();
    if (n.contains('MSL') && n.contains('ANAL')) return 'MSL_ANALYSIS';
    if (n.contains('MSL') && (n.contains('PROG') || n.contains('PROGNOS'))) return 'MSL_PROGNOSIS';

    if (n.contains('SIGWX')) {
      if (n.contains('MID')) return 'SIGWX_MID';
      // Additional regional SIGWX products usually have a region before SIGWX
      final startsWithCore = n.trim().startsWith('SIGWX ');
      return startsWithCore ? 'SIGWX_HIGH_CORE' : 'SIGWX_HIGH_REGIONAL';
    }

    if (n.contains('SIGMET')) {
      if (n.contains('ALL LEVEL')) return 'SIGMET_ALL';
      if (n.contains('HIGH')) return 'SIGMET_HIGH';
      if (n.contains('LOW')) return 'SIGMET_LOW';
      return 'SIGMET_OTHER';
    }

    if ((n.contains('SAT') || n.contains('SATPIC'))) {
      if ((n.contains('AUST') || n.contains('AUSTRALIA')) && n.contains('REGIONAL')) return 'SATPIC_AUST_REGIONAL';
      return 'SATPIC_OTHER';
    }

    if (n.contains('GRID') || n.contains('POINT') || n.contains('WINDS')) {
      if (n.contains('HIGH-LEVEL')) return 'GP_WINDS_HIGH';
      if (n.contains('MID-LEVEL')) return 'GP_WINDS_MID';
      return 'GP_WINDS';
    }
    return 'OTHER';
  }

  bool _isCuratedCategory(String c) {
    return c == 'MSL_ANALYSIS' || c == 'MSL_PROGNOSIS' || c == 'SIGWX_HIGH' || c == 'SIGWX_MID' || c == 'GP_WINDS' || c == 'SATPIC' || c == 'SIGMET';
  }

  DateTime? _parseDayHourZ(String? s) {
    if (s == null) return null;
    final m = RegExp(r'^(\d{2})(\d{2})Z$').firstMatch(s.trim());
    if (m == null) return null;
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  bool _looksLikeChartLink(String href, String label) {
    final h = href.toLowerCase();
    final l = label.toLowerCase();
    final hasAssetExt = h.endsWith('.png') || h.endsWith('.jpg') || h.endsWith('.jpeg') || h.endsWith('.pdf');
    if (!hasAssetExt) return false;

    // Must be a ChartDirectory asset
    final inChartDir = h.contains('/naips/chartdirectory/') || h.contains('/chartdirectory/');
    if (!inChartDir) return false;

    // Exclude obvious non-product docs
    final isDoc = l.contains('guide') || l.contains('faq') || l.contains('frequently') || l.contains('conversion') || l.contains('utc') || l.contains('user') || h.contains('guide') || h.contains('faq');
    if (isDoc) return false;

    // Prefer a product code in filename (4-5 consecutive digits) but do not require (some links are generic "Hi‑Res")
    // Keep if either link has code or nearby text likely includes product words
    final hasCode = RegExp(r'\d{4,5}').hasMatch(h);

    // Require product keywords in either label or path
    final s = '$h $l';
    final looksProduct = s.contains('msl') || s.contains('mslp') || s.contains('sigwx') || s.contains('satpic') || s.contains('sat') || s.contains('grid') || s.contains('winds') || s.contains('sigmet');
    return looksProduct || hasCode;
  }

  DateTime? _parseFullTimestamp(String s) {
    final m = RegExp(r'^(\d{4})(\d{2})(\d{2})\s+(\d{2})(\d{2})').firstMatch(s.trim());
    if (m == null) return null;
    final year = int.parse(m.group(1)!);
    final month = int.parse(m.group(2)!);
    final day = int.parse(m.group(3)!);
    final hour = int.parse(m.group(4)!);
    final minute = int.parse(m.group(5)!);
    return DateTime.utc(year, month, day, hour, minute);
  }

  String? _maybeExtractDayHourZ(String s) {
    final m = RegExp(r'(\d{2})(\d{2})Z').firstMatch(s);
    if (m == null) return null;
    return '${m.group(1)}${m.group(2)}Z';
  }

  String? _extractCode(String href) {
    final m = RegExp(r'(\d{4,5})').firstMatch(href);
    return m?.group(1);
  }

  DateTime? _inferTimeFromNode(dom.Node a) {
    final ctx = (a.parent?.text ?? a.text) ?? '';
    final m = RegExp(r'(\d{2})(\d{2})Z').firstMatch(ctx);
    if (m == null) return null;
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  DateTime? _inferEndFromNode(dom.Node a) {
    final ctx = (a.parent?.text ?? a.text) ?? '';
    final matches = RegExp(r'(\d{2})(\d{2})Z').allMatches(ctx).toList();
    if (matches.length >= 2) {
      final now = DateTime.now().toUtc();
      return DateTime.utc(now.year, now.month, int.parse(matches[1].group(1)!), int.parse(matches[1].group(2)!));
    }
    return null;
  }

  int _orderKey(ChartItem item) {
    const order = [
      'MSL_ANALYSIS',
      'MSL_PROGNOSIS',
      'SIGWX_HIGH_CORE',
      'SIGMET_ALL',
      'SIGMET_HIGH',
      'SIGMET_LOW',
      'SATPIC_AUST_REGIONAL',
      'SIGWX_MID',
      'GP_WINDS_HIGH',
      'GP_WINDS_MID',
      // fallbacks
      'SIGWX_HIGH_REGIONAL',
      'SIGMET_OTHER',
      'SATPIC_OTHER',
      'GP_WINDS',
      'OTHER',
    ];
    final idx = order.indexOf(item.category);
    return idx == -1 ? order.length : idx;
  }

  // Extract "VALID HHMMZ" from product name when present and map to next occurrence in UTC
  DateTime? _extractValidAtFromName(String name) {
    final m = RegExp(r'VALID\s+(\d{4})Z', caseSensitive: false).firstMatch(name);
    if (m == null) return null;
    final hh = int.parse(m.group(1)!.substring(0, 2));
    final mm = int.parse(m.group(1)!.substring(2, 4));
    final now = DateTime.now().toUtc();
    var candidate = DateTime.utc(now.year, now.month, now.day, hh, mm);
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  DateTime _deriveFrom(DateTime? fromCandidate, String name) {
    final validAt = _extractValidAtFromName(name) ?? fromCandidate;
    if (validAt != null) return validAt.subtract(const Duration(hours: 3));
    return DateTime.now().toUtc();
  }

  DateTime? _deriveTill(DateTime? fromCandidate, DateTime? tillCandidate, String name) {
    final validAt = _extractValidAtFromName(name) ?? fromCandidate;
    if (validAt != null && tillCandidate == null) return validAt.add(const Duration(hours: 3));
    return tillCandidate;
  }
}

class _ChartCandidate {
  final String code;
  final String name;
  final String category;
  DateTime? validFromUtc;
  DateTime? validTillUtc;
  Uri? loResUrl;
  Uri? hiResUrl;
  Uri? pdfUrl;

  _ChartCandidate({required this.code, required this.name, required this.category});
}

class _FormPost {
  final String? action;
  final Map<String, String> fields;
  final String? submitName;
  _FormPost({required this.action, required this.fields, this.submitName});
}

/// Resolved assets from a Details page
class ChartAssetResolution {
  final Uri? imageUri;
  final Uri? pdfUri;
  ChartAssetResolution({this.imageUri, this.pdfUri});
}

extension NaipsChartsAssetOps on NaipsChartsService {
  /// Given a Details URL (e.g., /naips/ChartDirectory/Details/B178T221?hires=true)
  /// fetch the page and extract the actual image and/or PDF URLs.
  Future<ChartAssetResolution> resolveAssetsFromDetails(Uri detailsUri) async {
    final headers = naipsService.buildAuthHeaders(referer: 'https://www.airservicesaustralia.com/naips/ChartDirectory/ChartDirectorySearch');
    final resp = await http.get(detailsUri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Details fetch failed: ${resp.statusCode}');
    }
    final body = utf8.decode(resp.bodyBytes);
    final doc = html_parser.parse(body);
    Uri? img;
    Uri? pdf;
    // Prefer explicit PDF links
    for (final a in doc.querySelectorAll('a[href]')) {
      final href = a.attributes['href'] ?? '';
      if (href.toLowerCase().endsWith('.pdf')) {
        pdf = _toAbs(href);
        break;
      }
    }
    // Find the chart image. NAIPS uses a GetImage endpoint without file extension
    // (e.g., /naips/ChartDirectory/GetImage/<ID>?ProductNumber=1&hires=True&lores=False)
    // So accept any <img src> that is under /ChartDirectory/.
    img ??= doc.querySelector('img#chartImage1')?.attributes['src'] != null
        ? _toAbs(doc.querySelector('img#chartImage1')!.attributes['src']!)
        : null;
    if (img == null) {
      for (final image in doc.querySelectorAll('img[src]')) {
        final src = image.attributes['src'] ?? '';
        if (src.isEmpty) continue;
        if (src.startsWith('javascript:')) continue;
        final lower = src.toLowerCase();
        // Accept extensionless GetImage endpoints as well
        if (lower.contains('/chartdirectory/getimage') || lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
          img = _toAbs(src);
          break;
        }
      }
    }
    return ChartAssetResolution(imageUri: img, pdfUri: pdf);
  }

  /// Fetch image bytes using authenticated NAIPS cookies so protected assets load.
  Future<Uint8List> fetchImageBytes(Uri assetUri, {Uri? referer}) async {
    final headers = naipsService.buildAuthHeaders(
      referer: (referer ?? Uri.parse('https://www.airservicesaustralia.com/naips/ChartDirectory/')).toString(),
    );
    // Hint we expect an image
    headers['Accept'] = 'image/webp,image/apng,image/*,*/*;q=0.8';
    final resp = await http.get(assetUri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Image fetch failed: ${resp.statusCode}');
    }
    return resp.bodyBytes;
  }
}


