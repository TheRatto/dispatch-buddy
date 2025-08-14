import 'dart:convert';
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
    final uri = Uri.parse('https://www.airservicesaustralia.com/naips/ChartDirectory/ChartDirectorySearch');
    final headers = naipsService.buildAuthHeaders(referer: 'https://www.airservicesaustralia.com/naips/');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('NAIPS Chart Directory fetch failed: ${response.statusCode}');
    }
    return utf8.decode(response.bodyBytes);
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

    // Heuristic line scan
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

    // Fallback: inspect links
    for (final a in doc.querySelectorAll('a[href]')) {
      final href = a.attributes['href'] ?? '';
      final label = a.text.trim();
      if (_looksLikeChartLink(href, label)) {
        items.add(ChartItem(
          code: _extractCode(href) ?? '',
          name: label.isNotEmpty ? label : href,
          validFromUtc: _inferTimeFromNode(a) ?? DateTime.now().toUtc(),
          validTillUtc: _inferEndFromNode(a),
          category: _categorize(label),
          loResUrl: href.endsWith('.png') ? _toAbs(href) : null,
          hiResUrl: href.endsWith('.jpg') ? _toAbs(href) : null,
          pdfUrl: href.endsWith('.pdf') ? _toAbs(href) : null,
        ));
      }
    }

    // Sort curated order then validity
    items.sort((a, b) {
      final o = _orderKey(a).compareTo(_orderKey(b));
      if (o != 0) return o;
      if (a.isCurrentlyValid != b.isCurrentlyValid) return a.isCurrentlyValid ? -1 : 1;
      return a.validFromUtc.compareTo(b.validFromUtc);
    });

    return items;
  }

  Uri _toAbs(String href) => Uri.parse(href.startsWith('http') ? href : 'https://www.airservicesaustralia.com$href');

  String _categorize(String name) {
    final n = name.toUpperCase();
    if (n.contains('MSL') && n.contains('ANAL')) return 'MSL_ANALYSIS';
    if (n.contains('MSL') && (n.contains('PROG') || n.contains('PROGNOS'))) return 'MSL_PROGNOSIS';
    if (n.contains('SIGWX') && n.contains('HIGH')) return 'SIGWX_HIGH';
    if (n.contains('SIGWX') && n.contains('MID')) return 'SIGWX_MID';
    if (n.contains('SIGMET')) return 'SIGMET';
    if (n.contains('SAT') || n.contains('SATPIC')) return 'SATPIC';
    if (n.contains('GRID') || n.contains('POINT') || n.contains('WINDS')) return 'GP_WINDS';
    return 'OTHER';
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
    return (h.contains('chart') || h.contains('/charts')) && (h.endsWith('.png') || h.endsWith('.jpg') || h.endsWith('.pdf'));
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
      'SIGWX_HIGH',
      'SIGWX_MID',
      'SIGMET',
      'SATPIC',
      'GP_WINDS',
      'OTHER',
    ];
    return order.indexOf(item.category);
  }
}


