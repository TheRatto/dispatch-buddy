# Previous Briefings Feature Roadmap

## 🎯 Overview

The Previous Briefings feature allows users to save and recall complete briefing data, providing offline access to historical briefings with smart refresh capabilities. This eliminates repetitive data entry and supports professional flight planning workflows.

## 📊 Current Status

**✅ COMPLETED:**
- Core data models and storage infrastructure
- Basic UI with auto-save functionality
- Smart naming and data freshness indicators
- Integration with home screen
- Swipeable cards with delete functionality
- Debug logging for storage investigation
- **Data Conversion Service** - Bridge between Briefing storage and Flight models
- **Navigation Integration** - Open briefings in existing summary screen
- **Rename Functionality** - Inline editing with keyboard support
- **Button Order Fix** - Correct reveal order (Delete → Rename → Flag)
- **Time Threshold Fix** - Accurate age display (minutes instead of "Just now")

**🔄 CURRENT PHASE:**
- **Phase 1: Data Conversion Foundation** ✅ **COMPLETED**
- **Phase 2: Navigation Integration** ✅ **COMPLETED**
- **Phase 3: Refresh Capability** ⏳ **NEXT**

**⏳ NEXT PHASES:**
- Refresh capability with safety rollback
- Age warnings and offline indicators
- Airport editing functionality

## 📋 Detailed Implementation Checklist

### **Phase 1: Data Conversion Foundation** ✅ **COMPLETED**

#### **1.1 Create BriefingConversionService** ✅ **COMPLETED**
- ✅ Create `lib/services/briefing_conversion_service.dart`
- ✅ Implement `briefingToFlight(Briefing briefing)` method
  - Convert `Map<String, dynamic>` NOTAMs to `List<Notam>`
  - Convert `Map<String, dynamic>` weather to `List<Weather>`
  - Reconstruct `List<Airport>` objects with system status
  - Create Flight object with briefing data
- ✅ Implement `flightToBriefing(Flight flight, {String? name})` method
  - Convert `List<Notam>` to storage format
  - Convert `List<Weather>` to storage format
  - Create Briefing object
- ✅ Add comprehensive error handling
- ✅ Add unit tests for conversion methods

#### **1.2 Update FlightProvider** ✅ **COMPLETED**
- ✅ Add `loadBriefing(Briefing briefing)` method
  - Convert briefing to Flight using conversion service
  - Set as current flight
  - Update weather grouping
  - Calculate system status
- ✅ Add `getCurrentBriefing()` method to track loaded briefing
- ✅ Add briefing refresh state management
- ✅ Update existing methods to handle briefing context

#### **1.3 Update SwipeableBriefingCard** ✅ **COMPLETED**
- ✅ Implement `onTap` functionality
  - Load briefing into FlightProvider
  - Navigate to BriefingTabsScreen
  - Add loading state during conversion
- ✅ Add error handling for failed conversions
- ✅ Add debug logging for troubleshooting
- ✅ **NEW: Inline Rename Functionality**
  - Card snaps back when rename is tapped
  - Inline text field appears in place of title
  - OS keyboard pops up automatically
  - Save/Cancel buttons for user control
  - Submit on Enter for quick saving
- ✅ **NEW: Button Order Fix**
  - Correct reveal order: Delete → Rename → Flag
  - Proper animation thresholds
  - Adequate snap-open width for all buttons

### **Phase 2: Navigation Integration** ✅ **COMPLETED**

#### **2.1 Update BriefingTabsScreen** ✅ **COMPLETED**
- ✅ Add briefing context awareness
- ✅ Show briefing name in header
- ✅ Add age warning banner for stale data
- ✅ Implement pull-to-refresh for briefing updates
- ✅ Add "Back to Home" navigation

#### **2.2 Add Age Warning System** ✅ **COMPLETED**
- ✅ Create `DataFreshnessService` for UI components
- ✅ Implement age warning banners
  - 12h+ = Yellow warning
  - 24h+ = Red warning with refresh button
- ✅ Add offline indicators
- ✅ Show last refresh timestamp
- ✅ **NEW: Accurate Time Display**
  - Fixed "Just now" threshold (now shows minutes)
  - Granular time display (5 minutes ago, 30 minutes ago, etc.)
  - Proper age calculation and formatting

### **Phase 3: Refresh Capability** ⏳ **NEXT**

#### **3.1 Create BriefingRefreshService** ⏳ **NEXT**
- [ ] Implement `refreshBriefing(Briefing briefing)` method
  - **Safety-First Approach:**
    - Immediate backup of original briefing data
    - Fetch fresh data without touching original
    - Validate data quality before any updates
    - Only update storage after quality validation
    - Automatic rollback on any failure
  - **Data Quality Validation:**
    - Weather coverage (80%+ of airports)
    - NOTAM validity (not all empty/invalid)
    - API error detection
    - Network connectivity checks
  - **Error Handling:**
    - Network failures → rollback to original
    - API errors → rollback to original
    - Quality check failures → rollback to original
    - Storage failures → rollback to original
  - [ ] Add comprehensive error handling
  - [ ] Add progress indicators
  - [ ] Add detailed logging for debugging

#### **3.2 Implement Hybrid Refresh UI** ⏳ **NEXT**
- [ ] **Pull-to-Refresh in BriefingTabsScreen**
  - Detailed progress indicators (weather fetching, NOTAM fetching)
  - Show individual API call status
  - Works when briefing is actively viewed
- [ ] **Refresh Button on SwipeableBriefingCard**
  - Small refresh icon in top-right corner
  - Shows refresh status (idle/loading/success/error)
  - Quick individual refresh without opening
- [ ] **"Refresh All" Button in PreviousBriefingsList**
  - Bulk refresh multiple briefings
  - Background processing with overall progress
  - Power user feature for updating everything
- [ ] **Progress and Status Indicators**
  - Loading spinners and progress bars
  - Success/error messages
  - Last refresh timestamp display
  - Offline indicators

#### **3.3 Data Safety Implementation** ⏳ **NEXT**
- [ ] **Backup-Restore System**
  - `_backupOriginalBriefing()` method
  - `_restoreOriginalBriefing()` method
  - Atomic storage operations
- [ ] **Quality Validation Engine**
  - Weather coverage validation (80%+ threshold)
  - NOTAM validity checks
  - API error detection
  - Network connectivity validation
- [ ] **Rollback Mechanism**
  - Automatic rollback on any failure
  - User notification of rollback
  - Detailed error logging
- [ ] **Error Recovery**
  - Graceful handling of all failure scenarios
  - User-friendly error messages
  - Retry mechanisms with exponential backoff

### **Phase 4: Airport Editing** ⏳ **PLANNED**

#### **4.1 Create BriefingEditService** ⏳ **PLANNED**
- [ ] Implement `editBriefingAirports(Briefing briefing, List<String> newAirports)`
  - Add new airports to briefing
  - Fetch data for new airports
  - Remove data for removed airports
  - Update briefing storage
- [ ] Add airport validation
- [ ] Handle API failures during editing
- [ ] Add undo functionality

#### **4.2 Integrate with Existing Airport UI** ⏳ **PLANNED**
- [ ] Enable airport bubble editing in briefing context
- [ ] Add airport management to briefing cards
- [ ] Show airport count and list
- [ ] Handle airport addition/removal

## 🔧 Technical Implementation Details

### **Data Conversion Strategy**

#### **Briefing → Flight Conversion:**
```dart
static Flight briefingToFlight(Briefing briefing) {
  // 1. Convert NOTAMs from Map to List
  final notams = _convertNotamsMapToList(briefing.notams);
  
  // 2. Convert Weather from Map to List  
  final weather = _convertWeatherMapToList(briefing.weather);
  
  // 3. Reconstruct Airports with system status
  final airports = _reconstructAirports(briefing.airports, notams);
  
  // 4. Create Flight object
  return Flight(
    id: briefing.id,
    route: briefing.airports.join(' → '),
    departure: briefing.airports.first,
    destination: briefing.airports.last,
    etd: briefing.timestamp,
    flightLevel: 'FL000', // Default
    alternates: briefing.airports.skip(2).toList(),
    createdAt: briefing.timestamp,
    airports: airports,
    notams: notams,
    weather: weather,
  );
}
```

#### **Flight → Briefing Conversion:**
```dart
static Briefing flightToBriefing(Flight flight, {String? name}) {
  // 1. Convert NOTAMs to storage format
  final notamsMap = _convertNotamsListToMap(flight.notams);
  
  // 2. Convert Weather to storage format
  final weatherMap = _convertWeatherListToMap(flight.weather);
  
  // 3. Create Briefing
  return Briefing.create(
    name: name,
    airports: flight.airports.map((a) => a.icao).toList(),
    notams: notamsMap,
    weather: weatherMap,
  );
}
```

### **Data Quality Validation**

#### **Acceptable Quality Standards:**
- ✅ Weather coverage: 80%+ of airports have weather data
- ✅ NOTAMs: Optional (small airports may have none)
- ✅ API errors: No critical failures (US airports should have NOTAMs)
- ✅ Data validity: NOTAMs have valid raw text

#### **Quality Check Implementation:**
```dart
static bool _isDataQualityAcceptable(
  List<List<Notam>> notamResults,
  List<Weather> metars,
  List<Weather> tafs,
  List<String> airports,
) {
  // Weather coverage check
  final airportsWithWeather = <String>{};
  for (final weather in [...metars, ...tafs]) {
    airportsWithWeather.add(weather.icao);
  }
  final weatherCoverage = airportsWithWeather.length / airports.length;
  if (weatherCoverage < 0.8) return false;
  
  // NOTAM validity check (optional)
  final totalNotams = notamResults.expand((list) => list).length;
  if (totalNotams > 0) {
    final validNotams = notamResults.expand((list) => list)
        .where((notam) => notam.rawText.isNotEmpty)
        .length;
    if (validNotams == 0) return false;
  }
  
  return true;
}
```

### **Error Handling Strategy**

#### **Conversion Errors:**
- ❌ Invalid data format in storage
- ❌ Missing required fields
- ❌ Corrupted briefing data

#### **Refresh Errors:**
- ❌ Network connectivity issues
- ❌ API rate limiting
- ❌ Data quality failures
- ❌ Storage write failures

#### **Recovery Actions:**
- 🔄 Rollback to original data
- 🔄 Show user-friendly error messages
- 🔄 Log detailed errors for debugging
- 🔄 Maintain offline functionality

## 📁 File Structure

```
lib/
├── models/
│   └── briefing.dart                    # ✅ COMPLETED
├── services/
│   ├── briefing_storage_service.dart    # ✅ COMPLETED
│   ├── data_freshness_service.dart     # ✅ COMPLETED
│   ├── briefing_conversion_service.dart # ⏳ NEXT
│   ├── briefing_refresh_service.dart    # ⏳ PLANNED
│   └── briefing_edit_service.dart       # ⏳ PLANNED
├── widgets/
│   ├── previous_briefings_list.dart     # ✅ COMPLETED
│   └── swipeable_briefing_card.dart     # ✅ COMPLETED
└── providers/
    └── flight_provider.dart             # 🔄 UPDATE NEEDED
```

## 🎯 Success Criteria

### **Phase 1 Complete:** ✅ **ACHIEVED**
- ✅ User can tap briefing card
- ✅ Briefing data loads into existing summary screen
- ✅ Same UI/UX as new briefing generation
- ✅ Cached data displays correctly
- ✅ No breaking changes to existing functionality
- ✅ **NEW: Inline rename functionality works**
- ✅ **NEW: Button order is correct**
- ✅ **NEW: Time display is accurate**

### **Phase 2 Complete:** ✅ **ACHIEVED**
- ✅ Age warnings display for stale data
- ✅ Pull-to-refresh works in briefing context
- ✅ Navigation flows smoothly
- ✅ Offline indicators work correctly
- ✅ **NEW: Accurate time thresholds**

### **Phase 3 Complete:** ⏳ **NEXT**
- [ ] Refresh updates briefing with fresh data
- [ ] Safety rollback works on failures
- [ ] Data quality validation prevents bad updates
- [ ] User gets clear feedback on refresh status

### **Phase 4 Complete:** ⏳ **PLANNED**
- [ ] Users can add/remove airports from saved briefings
- [ ] Airport editing integrates with existing UI
- [ ] Changes persist correctly
- [ ] Error handling works for all scenarios

## 🚀 Implementation Priority

### **Completed (This Session):** ✅ **DONE**
1. ✅ **Create BriefingConversionService** - Foundation for everything
2. ✅ **Update FlightProvider** - Enable briefing loading
3. ✅ **Update SwipeableBriefingCard** - Enable navigation
4. ✅ **Add inline rename functionality** - Elegant UX
5. ✅ **Fix button order** - Correct reveal sequence
6. ✅ **Fix time thresholds** - Accurate age display

### **Next Session:**
1. **Create BriefingRefreshService** - Add refresh capability with safety-first approach
2. **Implement data quality validation** - Prevent bad updates with comprehensive checks
3. **Add hybrid refresh UI** - Pull-to-refresh, card buttons, and bulk refresh
4. **Implement backup-restore system** - Ensure data safety with automatic rollback

### **Future Sessions:**
1. **Add airport editing** - Complete the feature set
2. **Performance optimization** - Handle large briefings
3. **Advanced features** - Templates, export/import

## ⚠️ Risk Mitigation

### **Data Loss Prevention:**
- ✅ Backup original data before any operations
- ✅ Validate data quality before updates
- ✅ Rollback on any failures
- ✅ Comprehensive error logging

### **Performance Considerations:**
- ✅ Efficient data conversion algorithms
- ✅ Lazy loading for large briefings
- ✅ Memory management for large datasets
- ✅ Background processing for refresh operations

### **User Experience:**
- ✅ Clear loading states
- ✅ Informative error messages
- ✅ Consistent UI patterns
- ✅ Offline-first design

## 📝 Testing Strategy

### **Unit Tests:**
- [ ] BriefingConversionService tests
- [ ] Data quality validation tests
- [ ] Error handling tests
- [ ] Edge case tests

### **Integration Tests:**
- [ ] Briefing load workflow
- [ ] Refresh functionality
- [ ] Airport editing
- [ ] Error recovery

### **UI Tests:**
- [ ] Card interactions
- [ ] Navigation flows
- [ ] Refresh operations
- [ ] Error scenarios 

## Data Storage Format (as of July 2024)

### Weather Data (METAR/TAF)
- **Key format:** Each weather report is stored in the briefing's weather map with a key of the form:
  - `METAR_<ICAO>_<briefingId>` for METARs
  - `TAF_<ICAO>_<briefingId>` for TAFs
- **Rationale:** This ensures that both METAR and TAF for the same airport and briefing are stored separately and do not overwrite each other. This is critical for accurate recall of all weather data associated with a briefing.
- **Example:**
  ```json
  {
    "METAR_YSSY_briefing_1753416661996": { ... },
    "TAF_YSSY_briefing_1753416661996": { ... }
  }
  ```
- **How to replicate for other data types:**
  - Use a composite key that includes the data type, unique identifier (e.g., ICAO), and briefing ID.
  - This pattern prevents collisions and ensures all relevant data is preserved for each briefing.

### NOTAM Data
- **Key format:** Each NOTAM is stored with a key of the form:
  - `<notamId>_<briefingId>`
- **Rationale:** Ensures that NOTAMs with the same ID from different briefings do not overwrite each other.

## Implementation Notes
- When adding new data types to the briefing storage, always use a composite key that uniquely identifies the data by type, location, and briefing.
- Update both the saving logic and the conversion service to handle the new key format.
- Add debug logging to verify the structure of stored and loaded data. 