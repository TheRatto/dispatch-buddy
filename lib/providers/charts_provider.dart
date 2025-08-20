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
  bool _inFlight = false;
  DateTime? _lastLoadedAt;

  List<ChartItem> get items => _items;
  bool get loading => _loading;
  String? get error => _error;
  DateTime? get lastLoadedAt => _lastLoadedAt;

  Future<void> refreshCatalog() async {
    if (_inFlight) return;
    _inFlight = true;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await chartsService.fetchCuratedCatalog();
      _lastLoadedAt = DateTime.now().toUtc();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      _inFlight = false;
      notifyListeners();
    }
  }

  /// Authenticate to NAIPS (if enabled and credentials supplied) then load catalog.
  Future<void> refreshCatalogWithAuth({
    required bool naipsEnabled,
    required String? username,
    required String? password,
  }) async {
    if (_inFlight) return;
    _inFlight = true;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (naipsEnabled && (username?.isNotEmpty == true) && (password?.isNotEmpty == true)) {
        final NAIPSService svc = chartsService.naipsService;
        // Step 1: if existing cookies grant access, reuse them; else authenticate
        final sessionOk = await svc.ensureChartsSession();
        if (!sessionOk) {
          final ok = await svc.authenticate(username!, password!);
          if (!ok) {
            _error = 'NAIPS authentication failed';
            _items = [];
            _loading = false;
            _inFlight = false;
            notifyListeners();
            return;
          }
        }
      }
      _items = await chartsService.fetchCuratedCatalog();
      _lastLoadedAt = DateTime.now().toUtc();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      _inFlight = false;
      notifyListeners();
    }
  }

  /// Load only if cache is stale by TTL, using auth when available.
  Future<void> refreshCatalogIfStale({
    Duration ttl = const Duration(minutes: 5),
    required bool naipsEnabled,
    required String? username,
    required String? password,
  }) async {
    if (_inFlight) return;
    final now = DateTime.now().toUtc();
    if (_lastLoadedAt != null && now.difference(_lastLoadedAt!) < ttl && _items.isNotEmpty) {
      return;
    }
    await refreshCatalogWithAuth(
      naipsEnabled: naipsEnabled,
      username: username,
      password: password,
    );
  }
}


