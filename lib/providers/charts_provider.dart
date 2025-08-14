import 'package:flutter/foundation.dart';
import '../models/chart_item.dart';
import '../services/naips_charts_service.dart';

class ChartsProvider extends ChangeNotifier {
  final NaipsChartsService chartsService;
  ChartsProvider({required this.chartsService});

  List<ChartItem> _items = [];
  bool _loading = false;
  String? _error;

  List<ChartItem> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> refreshCatalog() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await chartsService.fetchCuratedCatalog();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}


