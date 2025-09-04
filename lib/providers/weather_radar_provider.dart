import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/radar_site.dart';
import '../models/radar_image.dart';
import '../services/bom_radar_service.dart';

/// Provider for managing weather radar state and data
class WeatherRadarProvider extends ChangeNotifier {
  final BomRadarService _radarService = BomRadarService();

  // State
  List<RadarSite> _availableSites = [];
  RadarSite? _selectedSite;
  List<RadarImage> _currentRadarLoop = [];
  RadarImage? _currentImage;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedRange = '256km';
  bool _isAnimating = false;
  int _currentFrameIndex = 0;
  DateTime? _lastRefresh;
  Timer? _animationTimer;
  List<String> _favoriteSiteIds = [];
  bool _layersLoading = false;  // Track if layers are still loading
  Timer? _loadingGraceTimer;    // Grace period for layer loading

  // Getters
  List<RadarSite> get availableSites => _availableSites;
  RadarSite? get selectedSite => _selectedSite;
  List<RadarImage> get currentRadarLoop => _currentRadarLoop;
  RadarImage? get currentImage => _currentImage;
  bool get isLoading => _isLoading || _layersLoading;
  String? get errorMessage => _errorMessage;
  String get selectedRange => _selectedRange;
  bool get isAnimating => _isAnimating;
  int get currentFrameIndex => _currentFrameIndex;
  DateTime? get lastRefresh => _lastRefresh;
  List<String> get favoriteSiteIds => _favoriteSiteIds;

  /// Get radar sites grouped by state
  Map<String, List<RadarSite>> get sitesByState {
    final Map<String, List<RadarSite>> grouped = {};
    for (final site in _availableSites) {
      // Exclude National radar from state tabs
      if (site.state != 'NATIONAL') {
        grouped.putIfAbsent(site.state, () => []).add(site);
      }
    }
    return grouped;
  }

  /// Get favorite radar sites
  List<RadarSite> get favoriteSites {
    return _availableSites.where((site) => _favoriteSiteIds.contains(site.id)).toList();
  }

  /// Check if a site is in favorites
  bool isFavorite(String siteId) {
    return _favoriteSiteIds.contains(siteId);
  }

  /// Toggle favorite status of a site
  void toggleFavorite(String siteId) {
    if (_favoriteSiteIds.contains(siteId)) {
      _favoriteSiteIds.remove(siteId);
    } else {
      _favoriteSiteIds.add(siteId);
    }
    notifyListeners();
  }

  /// Check if data needs refresh (older than 6 minutes)
  bool get needsRefresh {
    if (_lastRefresh == null) return true;
    return DateTime.now().toUtc().difference(_lastRefresh!).inMinutes >= 6;
  }

  /// Get current frame for display
  RadarImage? get displayImage {
    if (_currentRadarLoop.isEmpty) return _currentImage;
    if (_currentFrameIndex >= _currentRadarLoop.length) return null;
    return _currentRadarLoop[_currentFrameIndex];
  }

  /// Initialize provider with available radar sites
  Future<void> initialize() async {
    try {
      debugPrint('DEBUG: WeatherRadarProvider - Initializing with available radar sites');
      _availableSites = BomRadarService.getAvailableRadarSites();
      
      // Set default site to National if available
      if (_availableSites.isNotEmpty) {
        _selectedSite = _availableSites.firstWhere(
          (site) => site.id == 'NATIONAL', // National radar ID
          orElse: () => _availableSites.first,
        );
        debugPrint('DEBUG: WeatherRadarProvider - Default site set to: ${_selectedSite?.displayName}');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: WeatherRadarProvider - Initialization failed: $e');
      _setError('Failed to initialize radar sites: $e');
    }
  }

  /// Select a radar site and load its data
  Future<void> selectSite(RadarSite site) async {
    if (_selectedSite?.id == site.id) return;

    debugPrint('DEBUG: WeatherRadarProvider - Selecting site: ${site.displayName}');
    _selectedSite = site;
    _currentRadarLoop.clear();
    _currentImage = null;
    _currentFrameIndex = 0;
    _errorMessage = null;
    
    // Set default range if current range not supported
    if (!site.supportsRange(_selectedRange)) {
      _selectedRange = site.defaultRange;
    }
    
    notifyListeners();
    
    // Load data for new site - start with loop mode
    await loadRadarLoop();
    if (_currentRadarLoop.isNotEmpty) {
      startAnimation();
    }
  }

  /// Change radar range and reload data
  Future<void> changeRange(String range) async {
    if (_selectedRange == range) return;
    if (_selectedSite == null || !_selectedSite!.supportsRange(range)) return;

    debugPrint('DEBUG: WeatherRadarProvider - Changing range to: $range');
    _selectedRange = range;
    _currentRadarLoop.clear();
    _currentImage = null;
    _currentFrameIndex = 0;
    
    notifyListeners();
    
    // Reload data with new range - start with loop mode
    await loadRadarLoop();
    if (_currentRadarLoop.isNotEmpty) {
      startAnimation();
    }
  }

  /// Load the latest radar image for selected site
  Future<void> loadLatestRadarImage() async {
    if (_selectedSite == null) return;

    debugPrint('DEBUG: WeatherRadarProvider - Loading latest radar image for ${_selectedSite!.id}');
    _setLoading(true);

    try {
      final image = await _radarService.fetchLatestRadarImage(
        _selectedSite!.id,
        range: _selectedRange,
      );

      if (image != null) {
        _currentImage = image;
        _lastRefresh = DateTime.now().toUtc();
        _errorMessage = null;
        debugPrint('DEBUG: WeatherRadarProvider - Successfully loaded radar image: ${image.formattedTime}');
        
        // Start layers loading grace period for single images too
        _startLayersLoadingGracePeriod();
      } else {
        _setError('No recent radar images available for ${_selectedSite!.name}');
      }
    } catch (e) {
      debugPrint('ERROR: WeatherRadarProvider - Failed to load radar image: $e');
      _setError('Failed to load radar image: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load radar loop for animation
  Future<void> loadRadarLoop({int frames = 6}) async {
    if (_selectedSite == null) return;

    debugPrint('DEBUG: WeatherRadarProvider - Loading radar loop for ${_selectedSite!.id} ($frames frames)');
    _setLoading(true);

    try {
      List<RadarImage> images;
      
      // Special handling for National radar - uses hourly loop structure
      if (_selectedSite!.id == 'NATIONAL') {
        debugPrint('DEBUG: WeatherRadarProvider - Fetching National radar hourly loop ($frames hourly frames)');
        images = await _radarService.fetchNationalRadarLoop(frames: frames);
      } else {
        // Regular regional radar loop
        images = await _radarService.fetchRadarLoop(
          _selectedSite!.id,
          range: _selectedRange,
          frames: frames,
        );
      }

      if (images.isNotEmpty) {
        _currentRadarLoop = images;
        _currentFrameIndex = images.length - 1; // Start with latest frame
        _currentImage = null; // Use loop instead
        _lastRefresh = DateTime.now().toUtc();
        _errorMessage = null;
        debugPrint('DEBUG: WeatherRadarProvider - Successfully loaded ${images.length} frames for animation');
        
        // Log frame timestamps for debugging
        for (int i = 0; i < images.length; i++) {
          debugPrint('DEBUG: Frame $i: ${images[i].formattedTime} UTC');
        }
        
        // Start layers loading grace period
        _startLayersLoadingGracePeriod();
      } else {
        _setError('No radar loop data available for ${_selectedSite!.name}');
      }
    } catch (e) {
      debugPrint('ERROR: WeatherRadarProvider - Failed to load radar loop: $e');
      _setError('Failed to load radar loop: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Start radar animation
  void startAnimation() {
    if (_currentRadarLoop.isEmpty) return;

    debugPrint('DEBUG: WeatherRadarProvider - Starting radar animation');
    _isAnimating = true;
    
    // Cancel layers loading grace period since animation indicates readiness
    if (_layersLoading) {
      // Wait a bit before cancelling to let first frame properly load
      Timer(const Duration(milliseconds: 1500), () {
        _cancelLayersLoadingGracePeriod();
      });
    }
    
    // Start animation timer - advance frame every 800ms
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (_isAnimating && _currentRadarLoop.isNotEmpty) {
        nextFrame();
      } else {
        timer.cancel();
      }
    });
    
    notifyListeners();
  }

  /// Stop radar animation
  void stopAnimation() {
    debugPrint('DEBUG: WeatherRadarProvider - Stopping radar animation');
    _isAnimating = false;
    _animationTimer?.cancel();
    _animationTimer = null;
    notifyListeners();
  }

  /// Toggle animation state
  void toggleAnimation() {
    if (_isAnimating) {
      stopAnimation();
    } else {
      startAnimation();
    }
  }

  /// Set current frame index for animation
  void setFrameIndex(int index) {
    if (index < 0 || index >= _currentRadarLoop.length) return;
    
    _currentFrameIndex = index;
    notifyListeners();
  }

  /// Move to next frame in animation
  void nextFrame() {
    if (_currentRadarLoop.isEmpty) return;
    
    final nextIndex = (_currentFrameIndex + 1) % _currentRadarLoop.length;
    debugPrint('DEBUG: Animation advancing to frame $nextIndex/${_currentRadarLoop.length - 1}');
    setFrameIndex(nextIndex);
  }

  /// Move to previous frame in animation
  void previousFrame() {
    if (_currentRadarLoop.isEmpty) return;
    
    final prevIndex = _currentFrameIndex == 0 
        ? _currentRadarLoop.length - 1 
        : _currentFrameIndex - 1;
    setFrameIndex(prevIndex);
  }

  /// Refresh data if needed
  Future<void> refreshIfStale({Duration? ttl}) async {
    final refreshThreshold = ttl ?? const Duration(minutes: 6);
    
    if (_lastRefresh == null || 
        DateTime.now().toUtc().difference(_lastRefresh!).compareTo(refreshThreshold) >= 0) {
      debugPrint('DEBUG: WeatherRadarProvider - Data is stale, refreshing...');
      
      if (_isAnimating || _currentRadarLoop.isNotEmpty) {
        await loadRadarLoop();
      } else {
        await loadLatestRadarImage();
      }
    }
  }

  /// Force refresh current data
  Future<void> refresh() async {
    debugPrint('DEBUG: WeatherRadarProvider - Force refreshing data');
    
    if (_isAnimating || _currentRadarLoop.isNotEmpty) {
      await loadRadarLoop();
    } else {
      await loadLatestRadarImage();
    }
  }

  /// Check if BOM service is available
  Future<bool> checkServiceAvailability() async {
    return await _radarService.checkServiceAvailability();
  }

  /// Clear all data and reset state
  void clear() {
    debugPrint('DEBUG: WeatherRadarProvider - Clearing all data');
    _currentRadarLoop.clear();
    _currentImage = null;
    _selectedSite = null;
    _currentFrameIndex = 0;
    _isAnimating = false;
    _animationTimer?.cancel();
    _animationTimer = null;
    _errorMessage = null;
    _lastRefresh = null;
    notifyListeners();
  }

  /// Start layers loading grace period to avoid jumping
  void _startLayersLoadingGracePeriod() {
    debugPrint('DEBUG: WeatherRadarProvider - Starting layers loading grace period');
    _layersLoading = true;
    notifyListeners();
    
    // Cancel any existing timer
    _loadingGraceTimer?.cancel();
    
    // Give layers 4 seconds to load before hiding loading indicator
    _loadingGraceTimer = Timer(const Duration(seconds: 4), () {
      debugPrint('DEBUG: WeatherRadarProvider - Layers loading grace period ended');
      _layersLoading = false;
      notifyListeners();
    });
  }

  /// Cancel layers loading grace period (if layers load faster)
  void _cancelLayersLoadingGracePeriod() {
    debugPrint('DEBUG: WeatherRadarProvider - Cancelling layers loading grace period (layers ready)');
    _loadingGraceTimer?.cancel();
    _layersLoading = false;
    notifyListeners();
  }

  /// Dispose of resources
  @override
  void dispose() {
    _animationTimer?.cancel();
    _loadingGraceTimer?.cancel();
    super.dispose();
  }

  // Private methods

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _errorMessage = null;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    debugPrint('ERROR: WeatherRadarProvider - $error');
    notifyListeners();
  }
}
