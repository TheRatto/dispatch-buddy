# Weather Radar Feature Roadmap

## 🎯 **STATUS: PHASE 1 COMPLETE ✅**
Core weather radar functionality implemented and working! Regional radars, favorites, animation, legend, and UI complete.

## ✅ **COMPLETED FEATURES (Working)**
- **✅ Regional Radar Sites**: All Australian radar sites by state (NSW, VIC, QLD, WA, SA, TAS, NT)
- **✅ BOM Multi-Layer System**: Background, locations, range, topography, radar data layers  
- **✅ Site Selection by State**: Clean tabbed interface with state filtering
- **✅ Favorites System**: Star/unstar radar sites with dedicated favorites tab
- **✅ Range Selection**: 64km/128km/256km/512km buttons (conditional per site)
- **✅ Animation Controls**: Play/pause with timeline dots showing current frame
- **✅ Time Scale Display**: Visual timeline below radar showing animation progress
- **✅ Zoom & Pan**: InteractiveViewer for detailed radar inspection
- **✅ Custom Legend**: Cropped BOM legend for better visibility
- **✅ National Radar**: Basic national composite button (needs URL fixes)
- **✅ Z Time Display**: Consistent UTC time in app bar
- **✅ Error Handling**: Graceful fallbacks for network issues
- **✅ Responsive UI**: Proper layout on different screen sizes

## 🚧 **NEXT PHASE ITEMS**
1. **Fix National Radar URLs**: Correct layer transparency paths for national composite
2. **Revert Legend**: Use original BOM legend positioned under radar display  
3. **Doppler Wind**: Add wind velocity radar layer option
4. **Favorites Persistence**: Save favorites between app sessions
5. **Weather Observations**: Add current weather station data overlay

## Overview
Add BOM (Bureau of Meteorology) weather radar imagery and animation loops to the app via the existing "More" entry point. Users can browse Australian radar sites by state/location, view live radar imagery with animation controls, manage favorite locations, and access radar loops offline. All times shown in UTC per project standards.

## Entry Point & Navigation
- Bottom navigation: existing "More" item opens modal sheet
- Add "Weather Radar" entry in the More sheet (between Charts and "More coming soon")
- Selecting Weather Radar opens the WeatherRadarScreen
- Entry point icon: `Icons.radar` with blue accent color `Color(0xFF3B82F6)`

## Sources & Access
- Primary: Bureau of Meteorology (BOM) radar imagery via HTTP
- Base URL: `https://www.bom.gov.au/radar/`
- Loop Pages: `https://www.bom.gov.au/products/IDR{site_id}.loop.shtml`
- **🆕 Multi-Layer Architecture**: Each radar image composed of 6 separate PNG layers
- Real-time updates every 5 minutes at x4 and x9 intervals (e.g., 10:04, 10:09, 10:14, 10:19)
- Multiple scan ranges per site: 64km, 128km, 256km, 512km

### BOM Multi-Layer System (Implemented ✅)
For each radar site (e.g., IDR402 - Canberra), BOM provides these layers:
```
├── IDR402.background.png    # Geographical base map (coastlines, borders)
├── IDR402.locations.png     # City/town name labels overlay  
├── IDR402.range.png         # Distance ring circles (64km, 128km, etc.)
├── IDR402.topography.png    # Terrain/elevation features
├── IDR.legend.0.png         # Color scale legend (shared across sites)
└── IDR402.T.202508301259.png # Actual radar data (timestamped)
    └─ Pattern: [SITE].T.[YYYYMMDDHHMM].png
```

### Data Extraction Process (Implemented ✅)
1. **Fetch Loop Page**: `GET /products/IDR402.loop.shtml`
2. **Parse HTML**: Extract radar data URLs using regex `IDR402\.T\.\d{12}\.png`
3. **Build Layer URLs**: Construct static layer URLs from site ID  
4. **Create RadarLayers**: Package all layer URLs into `RadarLayers` object
5. **Composite Display**: Stack layers in correct order for professional radar view

### Anti-Scraping Handling (Implemented ✅)
- **Akamai CDN Protection**: Direct image requests may return 403 Forbidden
- **Browser Headers**: User-Agent, Accept, Referer headers added to requests
- **HTML Parsing**: Extract actual image URLs from official BOM loop pages
- **Graceful Fallback**: Custom mock radar display when BOM blocks access

## Product Scope (Phase 1 - Core Radar Sites)
Australian radar sites by state:
1) **NSW**: Sydney (IDR71), Newcastle (IDR72), Wollongong (IDR71), Wagga Wagga (IDR73)
2) **VIC**: Melbourne (IDR02), Geelong (IDR02), Mildura (IDR30)
3) **QLD**: Brisbane (IDR66), Gold Coast (IDR71), Townsville (IDR73), Cairns (IDR31)
4) **WA**: Perth (IDR70), Geraldton (IDR69), Kalgoorlie (IDR31)
5) **SA**: Adelaide (IDR64), Mount Gambier (IDR66)
6) **TAS**: Hobart (IDR76)
7) **NT**: Darwin (IDR63), Alice Springs (IDR64)

Initial focus: Major capital city radars (Sydney, Melbourne, Brisbane, Perth, Adelaide)

## Architecture & Implementation

### Data Layer
th ```
Services:
├── BomRadarService          # Fetch radar images and metadata
├── RadarLocationService     # Australian radar sites database
└── RadarCacheManager       # Image caching and offline storage

Models:
├── RadarSite               # Location, ID, coverage areas, state
├── RadarImage              # Timestamp, URL, scan range, validity
└── RadarFavorite          # User preferences and quick access
```

### State Management
```
Providers:
├── WeatherRadarProvider    # Main state management
│   ├── availableSites      # List of all radar locations
│   ├── currentRadarLoop    # Current animation frames
│   ├── selectedSite        # Currently viewing location
│   ├── animationState      # Play/pause/speed controls
│   └── loadingState        # Network/cache status
└── RadarFavoritesProvider  # Favorites management
    ├── favoriteList        # User's starred locations
    ├── addFavorite()       # Add location to favorites
    └── removeFavorite()    # Remove from favorites
```

### UI Components
```
Screens:
├── WeatherRadarScreen      # Main radar display screen
├── RadarLocationSelector   # State/location picker modal
└── RadarSettingsSheet     # Preferences and options

Widgets:
├── RadarImageViewer        # Image display with pinch-to-zoom
├── RadarAnimationControls  # Play/pause/speed/step controls
├── RadarLocationGrid       # Grid of available locations
├── RadarFavoritesBar      # Quick access to starred locations
├── RadarRangeSelector     # 64km/128km/256km/512km toggle
└── RadarUpdateIndicator   # Last updated + countdown timer
```

## UI/UX Design

### WeatherRadarScreen Layout
```
┌─────────────────────────────────────┐
│ [←] Sydney Radar          [↻] [⋮] │  ← App bar with location name
├─────────────────────────────────────┤
│ ⭐ SYD  ⭐ MEL  + ADD FAVORITE     │  ← Favorites quick access bar
├─────────────────────────────────────┤
│                                     │
│        🌧️ RADAR IMAGE              │  ← Main radar image viewer
│        (Pinch to zoom)              │    with animation overlay
│                                     │
├─────────────────────────────────────┤
│ ⏵ PLAY  ⏸ PAUSE  🔄 LOOP  📏 256km │  ← Animation controls
├─────────────────────────────────────┤
│ Updated: 14:23Z  Next: 2min         │  ← Update status
├─────────────────────────────────────┤
│ [📍 Change Location] [⚙️ Settings]  │  ← Action buttons
└─────────────────────────────────────┘
```

### State/Location Selector
```
┌─────────────────────────────────────┐
│ Select Radar Location               │
├─────────────────────────────────────┤
│ 🇦🇺 NSW    VIC    QLD    WA        │  ← State tabs
├─────────────────────────────────────┤
│ 📍 Sydney (Terrey Hills)           │
│ 📍 Newcastle                       │  ← Location list for selected state
│ 📍 Wollongong                      │
│ 📍 Wagga Wagga                     │
└─────────────────────────────────────┘
```

### Animation Features
- **Loop Control**: Play/Pause with speed adjustment (0.5x, 1x, 2x)
- **Frame Stepping**: Manual forward/backward frame navigation
- **Range Selection**: Toggle between scan ranges (64km → 512km)
- **Auto-refresh**: Background updates with visual countdown
- **Smooth Transitions**: Fade between frames, no jarring jumps

## Implementation Phases

### Phase 1: Core Infrastructure ✅ COMPLETED
**Goal**: Basic radar image fetching and display with multi-layer support

**Deliverables**:
- [x] `BomRadarService` - HTTP client with HTML parsing and layer extraction
- [x] `RadarSite` model with accurate Australian radar locations  
- [x] `RadarImage` model with `RadarLayers` support for compositing
- [x] `WeatherRadarProvider` - state management with error handling
- [x] Add Weather Radar entry to `more_sheet.dart`
- [x] `WeatherRadarScreen` - image display with mock radar fallback
- [x] Error handling for network failures and BOM blocking

**Technical Tasks**:
```dart
// Add to more_sheet.dart
ListTile(
  leading: const Icon(Icons.radar, color: Color(0xFF3B82F6)),
  title: const Text('Weather Radar'),
  subtitle: const Text('Live BOM radar imagery and loops'),
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WeatherRadarScreen()),
    );
  },
),
```

### Phase 1.5: Multi-Layer Radar Display (NEXT PRIORITY) 🚀
**Goal**: Implement proper layer compositing for professional radar display

**Deliverables**:
- [ ] Update `WeatherRadarScreen` to display all 6 layers using `Stack` widget
- [ ] Layer stacking order: Background → Topography → Range → Locations → Radar Data → Legend
- [ ] Individual layer error handling (graceful degradation for missing layers)
- [ ] Performance optimization for multi-layer rendering
- [ ] Layer toggle controls (show/hide individual layers)

**Technical Implementation Required**:
```dart
// Enhanced radar display with proper layer stacking
Widget _buildLayeredRadarDisplay(RadarImage image) {
  return Stack(
    children: [
      // Layer 1: Background map (base layer)
      Image.network(image.layers!.backgroundUrl, 
        errorBuilder: (_, __, ___) => Container()),
      
      // Layer 2: Topography (terrain features)
      Image.network(image.layers!.topographyUrl, 
        errorBuilder: (_, __, ___) => Container()),
      
      // Layer 3: Range circles (distance references)
      Image.network(image.layers!.rangeUrl, 
        errorBuilder: (_, __, ___) => Container()),
      
      // Layer 4: Location labels (city names)
      Image.network(image.layers!.locationsUrl, 
        errorBuilder: (_, __, ___) => Container()),
      
      // Layer 5: Radar data (actual weather - animated)
      Image.network(image.layers!.radarDataUrl, 
        errorBuilder: (_, __, ___) => Container()),
      
      // Layer 6: Legend overlay (positioned)
      Positioned(
        bottom: 16, right: 16,
        child: Image.network(image.layers!.legendUrl, width: 120),
      ),
    ],
  );
}
```

### Phase 2: Location Selection & Favorites (Week 2-3)
**Goal**: Full location browsing and user favorites

**Deliverables**:
- [ ] `RadarLocationSelector` - state/location picker modal
- [ ] `RadarFavoritesProvider` - persistent favorites storage
- [ ] `RadarFavoritesBar` - quick access widget
- [ ] Location data for all major Australian radar sites
- [ ] Settings integration for favorites persistence

**Features**:
- Hierarchical state → location selection
- Add/remove favorites with star icons
- Persistent favorites storage in SharedPreferences
- Quick access bar for instant location switching

### Phase 3: Animation & Advanced Display (Week 3-4)
**Goal**: Radar animation loops and advanced viewing

**Deliverables**:
- [ ] `RadarAnimationControls` - play/pause/speed controls
- [ ] `RadarImageViewer` - pinch-to-zoom with animation overlay
- [ ] `RadarRangeSelector` - scan range switching
- [ ] Multi-frame radar loop fetching
- [ ] Smooth animation timing and transitions

**Features**:
- 6-10 frame animation loops (last hour of data)
- Variable playback speed (0.5x, 1x, 2x)
- Frame stepping (forward/backward)
- Zoom persistence across animation frames
- Range switching with cache management

### Phase 4: Caching & Offline Support (Week 4)
**Goal**: Reliable offline access and performance optimization

**Deliverables**:
- [ ] `RadarCacheManager` - intelligent image caching
- [ ] Offline detection and graceful degradation
- [ ] Background refresh with timestamp validation
- [ ] Cache size management and cleanup
- [ ] Performance optimization for large images

**Features**:
- Cache latest loop for each favorite location
- Offline radar viewing with age indicators
- Smart cache eviction (keep favorites, remove old data)
- Compressed image storage for mobile bandwidth
- Background updates every 6-10 minutes when app is active

## Data Management & Caching

### Cache Strategy
- **Active Location**: Keep last 10 frames (1 hour) in memory + disk cache
- **Favorite Locations**: Cache last loop (6 frames) for offline access
- **Non-favorites**: Memory cache only, evict after 30 minutes
- **Cache Size Limit**: 100MB total, auto-cleanup oldest non-favorite data

### Update Strategy
- **Foreground Updates**: Every 6 minutes when screen is active
- **Background Updates**: Update favorites cache when app returns to foreground
- **Smart Refresh**: Only fetch new frames, skip if timestamp hasn't changed
- **Offline Fallback**: Show cached data with "Last updated" timestamp

### Image Optimization
- **Progressive Loading**: Show low-res preview, then high-res
- **Bandwidth Detection**: Adjust image quality based on connection speed
- **Compression**: Store compressed versions for cache efficiency
- **Format**: Prefer PNG for quality, fallback to JPEG for size

## Error Handling & Edge Cases

### Network Issues
- **Connection Failure**: Show cached data with offline indicator
- **Slow Network**: Progressive loading with timeout handling
- **BOM Server Issues**: Graceful degradation with user messaging
- **Partial Failures**: Continue with available frames, note missing data

### Data Issues
- **Missing Frames**: Fill gaps in animation loop with last available frame
- **Timestamp Gaps**: Detect and handle irregular BOM update schedules
- **Invalid Images**: Skip corrupted frames, log for debugging
- **Site Offline**: Clear messaging when radar site is down for maintenance

### User Experience
- **Loading States**: Skeleton screens during initial load
- **Empty States**: Helpful messaging when no data available
- **Error Recovery**: "Retry" buttons with exponential backoff
- **Accessibility**: Screen reader support for all controls

## Technical Integration Points

### BOM Multi-Layer Service (Implemented ✅)
```dart
// lib/services/bom_radar_service.dart - Actual implementation
class BomRadarService {
  static const String baseUrl = 'https://www.bom.gov.au/radar/';
  static const String loopBaseUrl = 'https://www.bom.gov.au/products/';
  
  // Extract complete layer information from BOM loop pages
  Future<List<RadarImage>> _fetchRadarImagesWithLayers(String siteId) async {
    final loopUrl = '${loopBaseUrl}$siteId.loop.shtml';
    
    // Parse HTML to extract timestamped radar data URLs
    final radarDataRegex = RegExp('$siteId\\.T\\.\\d{12}\\.png');
    final matches = radarDataRegex.allMatches(html);
    
    // Build complete layer URLs for each frame
    for (final match in matches) {
      final layers = RadarLayers(
        backgroundUrl: '${baseUrl}$siteId.background.png',
        locationsUrl: '${baseUrl}$siteId.locations.png',
        rangeUrl: '${baseUrl}$siteId.range.png', 
        topographyUrl: '${baseUrl}$siteId.topography.png',
        legendUrl: '${baseUrl}IDR.legend.0.png',
        radarDataUrl: baseUrl + match.group(0)!,
      );
      // Package into RadarImage with layer data
    }
  }
}
```

### Provider Integration
```dart
// Follow charts_provider.dart patterns
class WeatherRadarProvider extends ChangeNotifier {
  // Similar lifecycle management to ChartsProvider
  Future<void> refreshRadarLoop({
    required String siteId,
    Duration ttl = const Duration(minutes: 6),
  }) async {
    // Implementation follows charts refresh patterns
  }
}
```

### Settings Integration
- Add "Weather Radar" section to Settings screen
- Options: Auto-refresh interval, Cache size limit, Image quality
- Favorites management: Export/import favorite locations
- Data usage controls: Wi-Fi only mode, compression settings

## Testing Strategy

### Unit Tests
- [ ] `BomRadarService` - HTTP client and URL generation
- [ ] `RadarLocationService` - Location data parsing and filtering
- [ ] `WeatherRadarProvider` - State management and data flow
- [ ] `RadarCacheManager` - Cache logic and storage limits

### Widget Tests
- [ ] `WeatherRadarScreen` - UI rendering and user interactions
- [ ] `RadarAnimationControls` - Play/pause/speed functionality
- [ ] `RadarLocationSelector` - State/location selection logic
- [ ] `RadarFavoritesBar` - Add/remove favorites workflow

### Integration Tests
- [ ] End-to-end radar viewing workflow
- [ ] Offline functionality with cached data
- [ ] Favorites persistence across app restarts
- [ ] Animation performance with multiple frames

## Performance Targets

### Loading Performance
- **Initial Load**: < 3 seconds for first radar image
- **Location Switch**: < 2 seconds to display new location
- **Animation Start**: < 1 second to begin loop playback
- **Cache Hit**: < 500ms for cached image display

### Memory Usage
- **Image Memory**: < 50MB for active radar loop (6 frames)
- **Total Memory**: < 100MB for entire radar feature
- **Cache Storage**: < 100MB persistent storage
- **Memory Leaks**: Zero retained objects after screen exit

### Network Efficiency
- **Bandwidth Usage**: < 5MB per location per hour (compressed images)
- **Request Optimization**: Batch requests, avoid redundant fetches
- **Background Usage**: Minimal when app is backgrounded
- **Offline Capability**: 100% functionality with cached data

## Accessibility & Usability

### Screen Reader Support
- Descriptive labels for all radar controls
- Announced updates for animation state changes
- Clear navigation between locations and favorites
- Alt text for radar images with weather description

### Visual Accessibility
- High contrast mode compatibility
- Scalable fonts for all text elements
- Color-blind friendly indicators (not just color-coded)
- Large touch targets for mobile interaction

### Motor Accessibility
- Gesture alternatives for pinch-to-zoom
- Voice control compatibility
- Simplified interaction modes
- Configurable touch sensitivity

## Success Metrics

### User Engagement
- **Adoption Rate**: % of users who access Weather Radar within 30 days
- **Retention**: % of users who return to feature within 7 days
- **Session Duration**: Average time spent viewing radar imagery
- **Favorites Usage**: % of users who create favorite locations

### Technical Performance
- **Error Rate**: < 1% of radar load attempts fail
- **Cache Hit Rate**: > 80% of image requests served from cache
- **Update Success**: > 95% of background updates complete successfully
- **Crash Rate**: Zero crashes attributable to radar feature

### User Satisfaction
- **Load Time**: 95% of users experience < 3 second initial load
- **Animation Smoothness**: 60fps animation playback on target devices
- **Offline Reliability**: 100% cached data accessibility when offline
- **Feature Completeness**: Comparable functionality to dedicated radar apps

## Future Enhancements (Post-MVP)

### Advanced Features
- **Weather Overlays**: Temperature, wind direction, precipitation intensity
- **Forecast Integration**: Link radar to TAF/METAR data for context
- **Export Options**: Save radar loops as GIF/MP4 for sharing
- **Push Notifications**: Alerts for severe weather in favorite locations

### Integration Opportunities
- **Flight Planning**: Show radar along flight routes
- **Airport Integration**: Link airport details to local radar coverage
- **NOTAM Correlation**: Highlight weather-related NOTAMs on radar
- **Briefing Export**: Include radar snapshots in flight briefings

### Platform Expansion
- **Apple Watch**: Quick radar glance with favorites
- **iPad Optimization**: Split-screen radar + other weather data
- **Desktop Web**: Full-screen radar viewing experience
- **API Access**: Allow third-party integrations

## Risk Assessment & Mitigation

### Technical Risks
- **BOM Service Reliability**: 
  - Risk: BOM servers unavailable or slow
  - Mitigation: Robust caching, graceful degradation, user messaging
  
- **Image Size & Performance**:
  - Risk: Large radar images cause memory issues
  - Mitigation: Image compression, progressive loading, memory monitoring

- **Network Variability**:
  - Risk: Poor mobile connections affect user experience
  - Mitigation: Adaptive quality, timeout handling, offline-first design

### User Experience Risks
- **Complexity Overload**:
  - Risk: Too many options confuse users
  - Mitigation: Progressive disclosure, sensible defaults, guided onboarding

- **Data Usage Concerns**:
  - Risk: Users worry about mobile data consumption
  - Mitigation: Clear data usage indicators, Wi-Fi-only options, compression

### Business Risks
- **BOM Terms of Service**:
  - Risk: BOM changes access policy or blocks automated access
  - Mitigation: Monitor TOS changes, implement rate limiting, have backup plan

- **Maintenance Overhead**:
  - Risk: Feature requires ongoing maintenance and updates
  - Mitigation: Robust error handling, comprehensive testing, monitoring

## Implementation Timeline

| Week | Focus Area | Key Deliverables | Success Criteria |
|------|------------|------------------|------------------|
| **Week 1** | Core Infrastructure | BomRadarService, Models, Basic UI | Single radar image displays correctly |
| **Week 2** | Location & Navigation | State selector, Location browsing | Users can browse all radar locations |
| **Week 3** | Favorites & Animation | Favorites system, Animation controls | Radar loops play smoothly with favorites |
| **Week 4** | Polish & Performance | Caching, Offline support, Testing | Offline usage works, performance optimized |

**Total Effort**: 4 weeks full-time development  
**Dependencies**: None (leverages existing architecture)  
**Risk Level**: Low (proven patterns, reliable data source)

---

## Development Notes

### Code Style & Patterns
- Follow existing service patterns from `naips_charts_service.dart`
- Use provider pattern consistent with `charts_provider.dart`
- Implement error handling similar to existing API services
- Follow UTC time standards per project requirements
- Use established color scheme and Material Design patterns

### Documentation Requirements
- API documentation for BomRadarService methods
- User guide for radar feature (add to existing docs)
- Technical architecture documentation
- Testing procedures and automation setup

### Quality Assurance
- Code review with focus on performance and memory usage
- Testing on multiple device sizes and network conditions
- Accessibility testing with screen readers
- User acceptance testing with aviation domain experts

This roadmap provides a comprehensive plan for implementing a professional-grade Weather Radar feature that integrates seamlessly with Dispatch Buddy's existing architecture and user experience patterns.