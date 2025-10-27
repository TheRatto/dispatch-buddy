# FIR NOTAMs Implementation Roadmap

## 📋 Overview

This document outlines the implementation plan for adding Flight Information Region (FIR) NOTAMs to Briefing Buddy. The initial scope focuses on the two Australian FIRs (YMMM and YBBB), with a future vision for worldwide FIR support.

## 🎯 Simplified Approach

### Key Decisions
1. ✅ **Always fetch both YMMM and YBBB** for ALL briefing requests (no airport-based logic)
2. ✅ **No data model changes** - use existing `icao` field to distinguish FIR vs airport NOTAMs
3. ✅ **Ungrouped list display** - start simple, like airport NOTAMs, add grouping later
4. ✅ **Defer FIR selection input** - will revisit when updating input screen

### Storage/Caching Answer
**Current Structure**: NOTAMs are stored as `Map<String, dynamic>` keyed by NOTAM ID

```dart
briefing.notams = {
  "H1234/25": { "icao": "YSSY", ... },
  "H5678/25": { "icao": "YMML", ... },
  // FIR NOTAMs will be added with same structure:
  "F001/25": { "icao": "YMMM", ... },  // Melbourne FIR
  "F002/25": { "icao": "YBBB", ... }, // Brisbane FIR
}
```

**Filtering approach**: Use `icao` field to identify type when displaying:
- Airport NOTAMs: `notam.icao in airports`  
- FIR NOTAMs: `notam.icao == "YMMM" || notam.icao == "YBBB"`

**No structural changes needed** - just add FIR NOTAMs to the same map! ✨

## 🎯 Goals

1. Fetch and display FIR NOTAMs for all briefing requests
2. Provide comprehensive aeronautical information beyond airport-specific NOTAMs
3. Maintain consistency with existing NOTAM filtering and display patterns
4. Establish foundation for future worldwide FIR support

## 📊 Current Architecture Analysis

### Existing NOTAM System
- **Source**: FAA API
- **Storage**: FlightProvider manages NOTAMs as part of briefing data
- **Q Codes**: Already parsed and categorized via `Notam.dart`
- **Filtering**: Time-based filtering with 6h/12h/24h/72h options
- **Display**: Tab-based system with airport pills for selection

### FIR Considerations
- **Australian FIRs**: YMMM (Melbourne), YBBB (Brisbane)
- **Data Source**: Same FAA API as airport NOTAMs
- **Filtering**: Same Q code system applies
- **Scope**: Fetch both FIRs for ANY Australian airport (simplified approach)

## 💾 Storage/Caching Decision Explained

### The Question
When storing/fetching NOTAMs, how do we distinguish between:
- Airport NOTAMs (e.g., NOTAM for YSSY)  
- FIR NOTAMs (e.g., NOTAM for YMMM region)

### Options Analyzed

**Option A: Use `icao` field with FIR codes** ✅ CHOSEN
- **How it works**: FIR NOTAMs have `icao = "YMMM"` or `icao = "YBBB"`
- **Pros**: No data model changes needed, simple implementation
- **Cons**: Could confuse (not technically an airport code)
- **Storage**: Store all NOTAMs in same list, identify by `icao` value

**Option B: Add `isFIRNotam` boolean field**
- **How it works**: Add boolean flag to distinguish type
- **Pros**: Explicit distinction, clear in code
- **Cons**: Requires model changes, serialization updates
- **Storage**: Still store in same list, filter by boolean

**Option C: Separate storage arrays**
- **How it works**: Store FIR NOTAMs in separate list in briefing
- **Pros**: Clear separation at data level
- **Cons**: Duplicates filtering/display logic, more complex state management

### Decision: **Option A** - Use `icao` Field

**Rationale**:
- Simplest implementation with zero data model changes
- FAA API already returns FIR codes in `icao` field naturally
- Easy to filter: `notam.icao == "YMMM"` identifies FIR NOTAM
- Minimal changes required to existing codebase

**Implementation**:
```dart
// All NOTAMs stored together
List<Notam> allNotams = [...airportNotams, ...firNotams];

// Filter for FIR NOTAMs when needed
List<Notam> firNotams = allNotams.where((n) => 
  ['YMMM', 'YBBB'].contains(n.icao)
).toList();

// Filter for airport NOTAMs
List<Notam> airportNotams = allNotams.where((n) =>
  n.icao != 'YMMM' && n.icao != 'YBBB'
).toList();
```

## 🚀 Implementation Plan (Simplified)

### Phase 1: Core Implementation

#### 1.1 Create FIR NOTAM Service
**File**: `lib/services/fir_notam_service.dart`

```dart
class FIRNotamService {
  static const List<String> australianFIRs = ['YMMM', 'YBBB'];
  
  /// Fetch FIR NOTAMs for Australian FIRs
  /// Always fetches both YMMM and YBBB for ALL briefing requests
  Future<List<Notam>> fetchAustralianFIRNotams() async {
    final apiService = ApiService();
    final allFIRNotams = <Notam>[];
    
    for (final fir in australianFIRs) {
      try {
        final notams = await apiService.fetchNotams(fir);
        allFIRNotams.addAll(notams);
      } catch (e) {
        debugPrint('Failed to fetch FIR NOTAMs for $fir: $e');
      }
    }
    
    return allFIRNotams;
  }
}
```

**Tasks**:
- [ ] Create `FIRNotamService` class
- [ ] Implement fetch logic using existing FAA API
- [ ] Add error handling and logging
- [ ] Write unit tests

#### 1.2 NO Data Model Changes Needed ✅
**Decision**: Use existing `icao` field to distinguish FIR NOTAMs
- FIR NOTAMs have `icao = "YMMM"` or `icao = "YBBB"`
- Airport NOTAMs have different ICAO codes
- No changes to `Notam` model required

**Tasks**: None - using existing model ✨

#### 1.3 FIR Detection Helper
**File**: `lib/services/fir_manager.dart`

```dart
class FIRManager {
  /// Get relevant FIRs for a list of airports
  static List<String> getFIRsForAirports(List<String> airports) {
    final bool hasAustralianAirport = airports.any(
      (airport) => airport.toUpperCase().startsWith('Y')
    );
    
    if (hasAustralianAirport) {
      return ['YMMM', 'YBBB'];
    }
    
    return [];
  }
  
  /// Check if airport is Australian
  static bool isAustralianAirport(String icao) {
    return icao.toUpperCase().startsWith('Y');
  }
}
```

**Tasks**:
- [ ] Create `FIRManager` utility
- [ ] Implement FIR detection logic
- [ ] Add helper methods
- [ ] Write unit tests

### Phase 2: Integration with Briefing System (Week 2-3)

#### 2.1 Extend FlightProvider for FIR NOTAMs
**File**: `lib/providers/flight_provider.dart`

**Changes Required**:
1. Add FIR NOTAMs to briefing data structure
2. Implement fetch logic for FIR NOTAMs
3. Add state management for FIR NOTAMs

**Important**: FIR NOTAMs are stored in the same list as airport NOTAMs, identified by `icao` field

```dart
// In FlightProvider - add FIR fetch during briefing creation
Future<void> _createBriefing() async {
  // ... existing airport NOTAM fetching ...
  
  // ALWAYS fetch FIR NOTAMs for ALL briefings (YMMM and YBBB)
  final firService = FIRNotamService();
  final firNotams = await firService.fetchAustralianFIRNotams();
  
  // Add FIR NOTAMs to the same NOTAM list
  allNotams.addAll(firNotams);
}
```

**Tasks**:
- [ ] Modify briefing creation to always fetch FIR NOTAMs
- [ ] Store FIR NOTAMs in existing `notams` list in briefing
- [ ] Update briefing save/load (no structural changes needed)
- [ ] Handle errors gracefully

#### 2.2 NO Separate FIR State Needed ✅
**Decision**: Since FIR NOTAMs use same `Notam` model and same storage, no separate state required

**Implementation**:
```dart
// Filter for FIR NOTAMs when displaying FIR tab
List<Notam> displayFIRNotams = briefing.notams.where((n) => 
  ['YMMM', 'YBBB'].contains(n.icao)
).toList();

// Filter for airport NOTAMs when displaying airport tab
List<Notam> displayAirportNotams = briefing.notams.where((n) =>
  n.icao != 'YMMM' && n.icao != 'YBBB'
).toList();
```

**Tasks**: 
- [ ] Add filtering logic to extract FIR NOTAMs from briefing
- [ ] No new state variables needed ✨

#### 2.3 Update Briefing Refresh Service
**File**: `lib/services/briefing_refresh_service.dart`

**Changes**: Include FIR NOTAMs in refresh operations

```dart
// In _fetchFreshData
Future<RefreshData> _fetchFreshData(List<String> airports) async {
  final notams = <Notam>[];
  final weather = <Weather>[];
  
  // Existing airport NOTAM fetching...
  
  // Add FIR NOTAM fetching for Australian flights
  if (airports.any((a) => a.startsWith('Y'))) {
    final firService = FIRNotamService();
    final firNotams = await firService.fetchAustralianFIRNotams();
    notams.addAll(firNotams);
  }
  
  return RefreshData(notams: notams, weather: weather);
}
```

**Tasks**:
- [ ] Add FIR NOTAM fetch to refresh logic
- [ ] Update cache clearing to include FIR NOTAMs
- [ ] Ensure proper error handling
- [ ] Test refresh with FIR NOTAMs

### Phase 3: UI Implementation (Week 3-4)

#### 3.1 Add FIR NOTAMs Tab to Raw Data Screen
**File**: `lib/screens/raw_data_screen.dart`

**Changes**: Add new tab after existing tabs

```dart
// In _buildTabBar
BottomNavigationBarItem(
  label: 'FIR NOTAMs',
  icon: Icon(Icons.flight_takeoff),
),
```

**Tasks**:
- [ ] Add FIR NOTAMs tab to navigation
- [ ] Implement tab switching logic
- [ ] Add loading state for FIR NOTAMs
- [ ] Handle empty state

#### 3.2 Create FIR Pill Selection Widget  
**File**: `lib/widgets/fir_pills_widget.dart`

```dart
class FIRPillsWidget extends StatelessWidget {
  final List<String> firCodes;
  final String? selectedFIR;
  final Function(String) onFIRSelected;
  
  Widget build(BuildContext context) {
    return Row(
      children: firCodes.map((fir) {
        final isSelected = fir == selectedFIR;
        return GestureDetector(
          onTap: () => onFIRSelected(fir),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange : Colors.grey[700],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(fir),
          ),
        );
      }).toList(),
    );
  }
}
```

**Tasks**:
- [ ] Create FIR pills widget using existing airport pill pattern
- [ ] Style to match airport pills
- [ ] Implement selection logic
- [ ] Add transition animations

#### 3.3 FIR NOTAMs Display (UNGROUPED - Like Airports)
**File**: `lib/screens/raw_data_screen.dart`

**Simplified Display**: Just show list of FIR NOTAMs, ungrouped, with pills for selection

```dart
Widget _buildFIRNotamsTab(BuildContext context, List<Notam> firNotams, FlightProvider flightProvider) {
  if (firNotams.isEmpty) {
    return Center(child: Text('No FIR NOTAMs available'));
  }
  
  // Filter by selected FIR pill and time
  String? selectedFIR;
  final filteredNotams = notams
    .where((notam) => selectedFIR == null || notam.icao == selectedFIR)
    .toList();
  
  // Apply time filtering (reuse existing method)
  final timeFilteredNotams = _filterNotamsByTime(filteredNotams);
  
  // Display as simple list - same style as airport NOTAMs
  return ListView.builder(
    itemCount: timeFilteredNotams.length,
    itemBuilder: (context, index) {
      return NotamCard(notam: timeFilteredNotams[index]);
    },
  );
}
```

**Tasks**:
- [ ] Implement ungrouped FIR NOTAMs display
- [ ] Add FIR pill selection filtering
- [ ] Reuse existing time filtering
- [ ] **NO grouping initially** - just simple list like airports
- [ ] Implement loading states

**Note**: Grouping (by Q code, category, etc.) will be added later after user testing

#### 3.4 Time Filtering Integration
**File**: `lib/screens/raw_data_screen.dart`

**Note**: Reuse existing `_filterNotamsByTime` method

**Tasks**:
- [ ] Apply same time filters to FIR NOTAMs
- [ ] Ensure filter state is shared
- [ ] Test with various time ranges

### Phase 4: Polish & Testing (Week 4-5)

#### 4.1 Performance Optimization
**Considerations**:
- FIR NOTAMs can be numerous (larger geographic scope)
- Need efficient caching
- Should implement lazy loading if dataset is large

**Tasks**:
- [ ] Implement FIR NOTAM caching
- [ ] Add pagination if needed
- [ ] Optimize rendering performance
- [ ] Test with large datasets

#### 4.2 User Experience Enhancements
**Ideas**:
- Visual distinction between FIR and airport NOTAMs
- FIR selection persistence
- Quick filters for Q codes
- Grouping by FIR

**Tasks**:
- [ ] Add visual indicators for FIR NOTAMs
- [ ] Implement FIR selection persistence
- [ ] Test user workflows
- [ ] Gather feedback

#### 4.3 Testing
**Test Cases**:
1. Briefing with Australian airports → FIR NOTAMs appear
2. Briefing with non-Australian airports → No FIR NOTAMs
3. Time filtering works for FIR NOTAMs
4. FIR selection changes displayed NOTAMs
5. Refresh updates FIR NOTAMs
6. Offline handling of cached FIR NOTAMs

**Tasks**:
- [ ] Write unit tests for FIR service
- [ ] Write widget tests for FIR UI
- [ ] Write integration tests for full flow
- [ ] Test edge cases and errors

### Phase 5: Future Enhancements

#### 5.1 Worldwide FIR Support
**Planning for Future**:
- User selection of FIRs
- Manual FIR entry field
- Linking FIRs to airports in database
- Multi-country FIR support

**Questions to Resolve**:
1. How should users select FIRs?
   - Searchable dropdown?
   - Manual entry field?
   - Autocomplete from ICAO database?
2. How to handle multiple countries?
   - Per-country FIR lists?
   - Global search?
3. Storage approach?
   - User-specified FIRs per briefing?
   - Auto-detected plus user-added?

**Tasks** (Future):
- [ ] Research worldwide FIR mappings
- [ ] Design user input UI for FIR selection
- [ ] Implement multi-country FIR support
- [ ] Create FIR database or lookup service

#### 5.2 Advanced Filtering
**Potential Enhancements**:
- Q code-based filtering for FIR NOTAMs
- Geographic filtering (boundaries)
- Category-based grouping
- Priority/severity indicators

**Tasks** (Future):
- [ ] Implement Q code filters
- [ ] Add geographic boundary checking
- [ ] Create advanced filtering UI

## 📝 Implementation Details

### FIR vs Airport NOTAMs - Visual Distinction

**Option 1**: Tab-level indicator
```dart
// Show "FIR NOTAMs" label prominently
Text('FIR NOTAMs (2 regions)')
```

**Option 2**: In-list indicators
```dart
// Show badge on each NOTAM card
Badge(
  label: Text('FIR: ${notam.icao}'),
  backgroundColor: Colors.blue,
)
```

**Option 3**: Group headers
```dart
// Group by FIR in list
ListTile(
  title: Text('YMMM - Melbourne FIR'),
  subtitle: Text('${notams.length} NOTAMs'),
)
```

**Recommendation**: Combination of Option 1 and 3 - clear label + grouped display

### Caching Strategy

**Approach**: Cache FIR NOTAMs separately from airport NOTAMs

```dart
// In BriefingStorageService
Future<void> storeFIRNotams(String flightId, List<Notam> firNotams) async {
  // Store FIR NOTAMs with prefix
}

Future<List<Notam>> loadFIRNotams(String flightId) async {
  // Load cached FIR NOTAMs
}
```

**Benefits**:
- Easier cache invalidation
- Clearer data separation
- Better performance

### Error Handling

**Scenarios**:
1. FAA API failure for FIR
2. Network timeouts
3. Invalid FIR codes
4. Empty FIR NOTAM response

**Strategy**:
- Graceful degradation (show airport NOTAMs even if FIR fails)
- Clear error messages
- Retry logic for transient failures
- Cache previous data on failure

## 🎯 Success Metrics

### Functional Requirements
- ✅ FIR NOTAMs automatically fetch for Australian flights
- ✅ Both YMMM and YBBB FIR NOTAMs available
- ✅ Time filtering works identically to airport NOTAMs
- ✅ Users can filter by individual FIR
- ✅ FIR NOTAMs refresh with briefing updates

### Performance Requirements
- Fetch time: < 5 seconds for both FIRs
- UI remains responsive during fetch
- Smooth scrolling with 100+ FIR NOTAMs
- Offline access to cached FIR NOTAMs

### User Experience Requirements
- Clear visual distinction from airport NOTAMs
- Intuitive FIR selection
- Consistent with existing patterns
- Helpful error messages

## 🔄 Rollout Plan

### Phase A: Development (Weeks 1-4)
- Implement core functionality
- Internal testing
- Bug fixes

### Phase B: Beta Testing (Week 5)
- Release to beta users
- Gather feedback
- Performance monitoring

### Phase C: Production Release (Week 6)
- Full release
- Monitor usage and errors
- Quick bug fixes

### Phase D: Iteration (Ongoing)
- User feedback integration
- Performance optimization
- Feature enhancements

## 📋 Checklist

### Pre-Implementation
- [x] Review existing NOTAM architecture
- [x] Confirm Australian FIR codes (YMMM, YBBB)
- [x] Decide on data source (FAA API)
- [ ] Test FAA API for FIR NOTAM availability
- [ ] Design UI mockups

### Implementation
- [ ] Create FIRNotamService
- [ ] Create FIRManager
- [ ] Extend Notam model (if needed)
- [ ] Integrate with FlightProvider
- [ ] Add UI tab
- [ ] Implement FIR pills
- [ ] Add filtering logic
- [ ] Integrate with refresh service
- [ ] Add caching
- [ ] Write tests

### Testing
- [ ] Unit tests for services
- [ ] Widget tests for UI
- [ ] Integration tests
- [ ] Performance tests
- [ ] User acceptance testing

### Deployment
- [ ] Code review
- [ ] Documentation updates
- [ ] Release notes
- [ ] Production deployment
- [ ] Monitor and support

## 🚨 Known Limitations

1. **Initial Scope**: Only Australian FIRs (YMMM, YBBB)
2. **Auto-detection**: All Australian airports get both FIRs
3. **No user override**: Can't deselect a FIR initially
4. **Future work**: Worldwide FIR support needs more planning

## ✅ Implementation Status: COMPLETED

### **🎯 Final Implementation Summary**

**Date Completed**: October 27, 2025

The FIR NOTAM feature has been **successfully implemented** with a parallel grouping structure that maintains consistency with airport NOTAMs while providing FIR-specific categorization.

### **🏗️ Architecture Delivered**

✅ **Parallel Structure**: FIR groups (9-14) separate from airport groups (1-8)  
✅ **Intelligent Grouping**: Pattern-based categorization using ID prefixes and content keywords  
✅ **Consistent UI**: All components support FIR groups with distinct colors and labels  
✅ **Zero Compilation Errors**: All exhaustive switch statements updated  
✅ **Real Data Analysis**: Grouping based on actual YMMM/YBBB NOTAM patterns  

### **📊 FIR Groups Implemented**

| Group | ID Pattern | Color | Label | Description |
|-------|------------|-------|-------|-------------|
| **FIR Airspace Restrictions** (9) | E-series | Dark Red | AIRSPACE | Military airspace, restricted areas |
| **FIR ATC/Navigation** (10) | L-series | Blue | ATC/NAV | Radar coverage, navigation services |
| **FIR Obstacles & Charts** (11) | F-series | Orange | OBST | New obstacles, chart amendments |
| **FIR Infrastructure** (12) | H-series | Emerald | INFRA | Airport infrastructure changes |
| **FIR Drone Operations** (13) | Content-based | Violet | DRONE | UA OPS, unmanned aircraft |
| **FIR Administrative** (14) | G/W-series | Slate | ADMIN | General warnings, admin notices |

### **🔧 Technical Components Delivered**

- **`FIRNotamGroupingService`**: Intelligent categorization with detailed logging
- **Extended `NotamGroup` enum**: 6 new FIR-specific values
- **Updated UI Components**: 8+ files updated for exhaustive switch coverage
- **Consistent Styling**: Distinct colors, icons, and labels for FIR groups
- **Integration**: Seamless integration with existing NOTAM infrastructure

### **🧪 Testing Ready**

The implementation is **production-ready** and will automatically:
1. Fetch YMMM and YBBB FIR NOTAMs for all Australian briefings
2. Categorize them into appropriate FIR groups
3. Display them with proper colors, icons, and grouping
4. Provide detailed logging for debugging and analysis

## 💡 Future Considerations

1. **Geographic Boundary Mapping**: Use lat/lon to precisely determine FIR
2. **User Preferences**: Allow users to set default FIR subscriptions
3. **FIR Database**: Maintain worldwide FIR lookup
4. **Smart Filtering**: Filter by flight route to determine relevant FIRs
5. **International Expansion**: Support multiple country FIRs

## 📚 References

- [ICAO NOTAM Format](docs/decodes/icao_notam_q_codes_full.md)
- [NOTAM Grouping](docs/notam_grouping_roadmap.md)
- [ERSA Integration](docs/ersa_integration_implementation.md)
- [Current Architecture](lib/models/notam.dart)
- [FIR Grouping Service](lib/services/fir_notam_grouping_service.dart)
