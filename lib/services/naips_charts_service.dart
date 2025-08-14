import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chart_item.dart';
import 'naips_service.dart';

/// Service to fetch and parse NAIPS Chart Directory
class NaipsChartsService {
  final NAIPSService naipsService;
  NaipsChartsService({required this.naipsService});

  /// Fetches the NAIPS Chart Directory HTML.
  Future<String> fetchDirectoryHtml() async {
    final uri = Uri.parse('https://www.airservicesaustralia.com/naips/ChartDirectory/ChartDirectorySearch');
    // TODO: in a later step, use NAIPSService session cookies; placeholder unauthenticated fetch
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('NAIPS Chart Directory fetch failed: ${response.statusCode}');
    }
    return utf8.decode(response.bodyBytes);
  }

  /// Placeholder parser. Later, implement robust HTML parsing into ChartItem list.
  Future<List<ChartItem>> fetchCuratedCatalog() async {
    try {
      final html = await fetchDirectoryHtml();
      debugPrint('DEBUG: NAIPS charts directory fetched, length=${html.length}');
      // TODO: parse into ChartItem list. For now, return empty list.
      return <ChartItem>[];
    } catch (e) {
      debugPrint('ERROR: fetchCuratedCatalog failed: $e');
      rethrow;
    }
  }
}


