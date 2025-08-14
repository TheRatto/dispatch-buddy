import 'package:flutter/foundation.dart';
import '../models/chart_item.dart';
import '../services/naips_charts_service.dart';
import '../services/naips_service.dart';

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

  /// Authenticate to NAIPS (if enabled and credentials supplied) then load catalog.
  Future<void> refreshCatalogWithAuth({
    required bool naipsEnabled,
    required String? username,
    required String? password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (naipsEnabled && (username?.isNotEmpty == true) && (password?.isNotEmpty == true)) {
        final NAIPSService svc = chartsService.naipsService;
        final ok = await svc.authenticate(username!, password!);
        if (!ok) {
          _error = 'NAIPS authentication failed';
          _items = [];
          _loading = false;
          notifyListeners();
          return;
        }
      }
      _items = await chartsService.fetchCuratedCatalog();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}


