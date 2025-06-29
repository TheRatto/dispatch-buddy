# Development Guidelines - Dispatch Buddy

## Quick Reference for Ongoing Development

### Code Organization Principles

#### 1. Single Responsibility Principle
```dart
// ✅ Good: Each class has one clear purpose
class TafDisplayService {
  // Only handles TAF display logic
}

// ❌ Bad: Class doing too many things
class TafManager {
  // Handles display, parsing, caching, UI, etc.
}
```

#### 2. Dependency Injection
```dart
// ✅ Good: Use interfaces for dependencies
class TafDecodedCard extends StatelessWidget {
  final TafDisplayService displayService;
  
  const TafDecodedCard({
    required this.displayService,
    super.key,
  });
}

// ❌ Bad: Direct instantiation
class TafDecodedCard extends StatelessWidget {
  final displayService = TafDisplayService(); // Hard to test
}
```

#### 3. Consistent Naming
```dart
// ✅ Good: Clear, descriptive names
class TafPeriodService {}
class TafHighlightingService {}
class TafCacheManager {}

// ❌ Bad: Unclear names
class TafHelper {}
class TafUtils {}
class TafStuff {}
```

### File Structure Standards

#### Services (`lib/services/`)
- One service per file
- Clear interface definitions
- Comprehensive error handling
- Unit tests for each service

#### Widgets (`lib/widgets/`)
- One widget per file
- Stateless when possible
- Clear props interface
- Widget tests for each component

#### Providers (`lib/providers/`)
- One provider per file
- Clear state management
- Proper error handling
- Integration tests

### Performance Best Practices

#### 1. Caching Strategy
```dart
// ✅ Good: Smart caching with invalidation
class TafDisplayService {
  final Map<String, dynamic> _cache = {};
  
  void clearCacheIfDataChanged(Weather taf) {
    final hash = _generateTafHash(taf);
    if (_lastHash != hash) {
      _cache.clear();
      _lastHash = hash;
    }
  }
}
```

#### 2. Widget Optimization
```dart
// ✅ Good: Use RepaintBoundary for static content
RepaintBoundary(
  child: TafDecodedCard(displayService: displayService),
)

// ✅ Good: Use const constructors
const SizedBox(height: 8),
const Text('Label', style: TextStyle(fontSize: 12)),
```

#### 3. State Management
```dart
// ✅ Good: Minimal state updates
class TafTimelineState extends ChangeNotifier {
  void updateSliderPosition(double value) {
    if ((value - _currentValue).abs() > 0.001) {
      _currentValue = value;
      notifyListeners();
    }
  }
}
```

### Testing Standards

#### 1. Unit Tests
```dart
// ✅ Good: Test service methods
test('should cache active periods correctly', () {
  final service = TafDisplayService();
  final result1 = service.getActivePeriods(data, time1);
  final result2 = service.getActivePeriods(data, time1);
  
  expect(result2, equals(result1)); // Should use cache
});
```

#### 2. Widget Tests
```dart
// ✅ Good: Test widget behavior
testWidgets('should display weather information', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TafDecodedCard(displayService: mockService),
    ),
  );
  
  expect(find.text('Wind'), findsOneWidget);
  expect(find.text('280° at 10kt'), findsOneWidget);
});
```

#### 3. Integration Tests
```dart
// ✅ Good: Test component interactions
testWidgets('should update when slider changes', (tester) async {
  await tester.pumpWidget(MyApp());
  
  await tester.drag(find.byType(Slider), Offset(50, 0));
  await tester.pump();
  
  expect(find.text('New Time'), findsOneWidget);
});
```

### Error Handling Patterns

#### 1. Service Error Handling
```dart
// ✅ Good: Comprehensive error handling
class TafDisplayService {
  Future<Map<String, dynamic>> getActivePeriods(Weather taf, DateTime time) async {
    try {
      // Processing logic
      return result;
    } catch (e) {
      print('Error getting active periods: $e');
      return _getDefaultPeriods();
    }
  }
}
```

#### 2. Widget Error Handling
```dart
// ✅ Good: Graceful error display
class TafDecodedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: displayService.getActivePeriods(taf, time),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorWidget('Failed to load TAF data');
        }
        if (!snapshot.hasData) {
          return LoadingWidget();
        }
        return TafDataWidget(data: snapshot.data!);
      },
    );
  }
}
```

### Documentation Standards

#### 1. Code Comments
```dart
// ✅ Good: Explain complex logic
/// Calculates active periods for a given time by finding baseline and concurrent
/// periods that are active at that specific moment.
/// 
/// [taf] - The TAF data containing forecast periods
/// [time] - The time to find active periods for
/// Returns a map with 'baseline' and 'concurrent' periods
Map<String, dynamic> findActivePeriodsAtTime(Weather taf, DateTime time) {
  // Implementation
}
```

#### 2. API Documentation
```dart
/// Service for managing TAF display state and caching.
/// 
/// This service handles:
/// - Active period calculations
/// - Weather data caching
/// - Performance monitoring
/// - UI state management
class TafDisplayService {
  /// Gets active periods for a specific time, using cache when possible.
  /// 
  /// Returns cached result if available, otherwise calculates and caches.
  Map<String, dynamic> getActivePeriods(Weather taf, DateTime time);
}
```

### Performance Monitoring

#### 1. Cache Metrics
```dart
// ✅ Good: Track cache performance
class TafDisplayService {
  int _cacheHits = 0;
  int _cacheMisses = 0;
  
  double get cacheHitRate => _cacheHits / (_cacheHits + _cacheMisses);
  
  void logPerformanceStats() {
    print('Cache hit rate: ${(cacheHitRate * 100).toStringAsFixed(1)}%');
  }
}
```

#### 2. Build Performance
```dart
// ✅ Good: Monitor widget rebuilds
class TafDecodedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('DEBUG: TafDecodedCard rebuilt at ${DateTime.now()}');
    // Widget implementation
  }
}
```

### Common Patterns

#### 1. Service Pattern
```dart
// ✅ Good: Service with clear interface
abstract class ITafDisplayService {
  Map<String, dynamic> getActivePeriods(Weather taf, DateTime time);
  void clearCache();
  void logPerformanceStats();
}

class TafDisplayService implements ITafDisplayService {
  // Implementation
}
```

#### 2. Widget Pattern
```dart
// ✅ Good: Stateless widget with clear props
class TafDecodedCard extends StatelessWidget {
  final TafDisplayService displayService;
  final Weather taf;
  final DateTime currentTime;
  
  const TafDecodedCard({
    required this.displayService,
    required this.taf,
    required this.currentTime,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    // Implementation
  }
}
```

#### 3. State Management Pattern
```dart
// ✅ Good: Provider with clear state
class TafState extends ChangeNotifier {
  Weather? _currentTaf;
  DateTime? _currentTime;
  Map<String, dynamic>? _activePeriods;
  
  Weather? get currentTaf => _currentTaf;
  DateTime? get currentTime => _currentTime;
  Map<String, dynamic>? get activePeriods => _activePeriods;
  
  void updateTaf(Weather taf) {
    _currentTaf = taf;
    _recalculateActivePeriods();
    notifyListeners();
  }
}
```

### Code Review Checklist

#### Before Submitting:
- [ ] Code follows single responsibility principle
- [ ] Dependencies are properly injected
- [ ] Error handling is comprehensive
- [ ] Performance considerations implemented
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] No breaking changes introduced
- [ ] Code is readable and maintainable

#### During Review:
- [ ] Architecture is sound
- [ ] Performance impact is acceptable
- [ ] Error cases are handled
- [ ] Tests cover edge cases
- [ ] Documentation is clear
- [ ] Code follows established patterns

### UI Extraction Best Practices
- Before extracting a widget, review the full context in the source file.
- Ensure the widget does not depend on hidden state or global variables.
- Pass all required data as parameters.
- After extraction, update all usages and remove obsolete code.
- Update documentation (roadmap, sprint tasks, guidelines) after each major extraction.

**Example:**
- The METAR tab extraction (2024-06-13) followed this pattern and was successful.

---

**Last Updated**: [Current Date]
**Next Review**: [Next Review Date] 