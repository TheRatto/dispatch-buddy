# Hybrid Implementation Roadmap

## Overview
Implementation roadmap for the new hybrid approach with system-specific pages, providing 4-layer information abstraction while maintaining operational focus.

## Phase 1: Clean Up Current Airport Status Page
**Goal**: Simplify the current page to show only system status overview

### Tasks:
- [ ] Remove embedded NOTAM details from AirportDetailScreen
- [ ] Remove expandable sections and NOTAM cards
- [ ] Keep simple status indicators with color coding
- [ ] Add navigation preparation for system-specific pages
- [ ] Test with real data to ensure clean display

### Files to Modify:
- `lib/screens/airport_detail_screen.dart`
- `lib/providers/flight_provider.dart` (if needed for navigation)

### Acceptance Criteria:
- [ ] Clean system status display without overflow
- [ ] No embedded NOTAM details
- [ ] Clear visual hierarchy
- [ ] Ready for system-specific navigation

## Phase 2: Create System-Specific Page Infrastructure
**Goal**: Build the foundation for system-specific pages

### Tasks:
- [ ] Create base SystemDetailScreen widget
- [ ] Implement navigation from AirportDetailScreen to system pages
- [ ] Create system-specific data models
- [ ] Build system status extraction logic
- [ ] Add "View All NOTAMs" button functionality

### Files to Create:
- `lib/screens/system_detail_screen.dart`
- `lib/models/system_status.dart`
- `lib/services/system_status_extractor.dart`

### Files to Modify:
- `lib/screens/airport_detail_screen.dart` (add navigation)
- `lib/providers/flight_provider.dart` (add system data methods)

## Phase 3: Implement Widget-Based System Pages ✅ COMPLETED
**Goal**: Build system-specific widgets embedded within AirportDetailScreen

### Tasks:
- [x] Create RunwaySystemWidget (embedded widget, no Scaffold/AppBar)
- [x] Create TaxiwaySystemWidget (embedded widget, no Scaffold/AppBar)
- [x] Create InstrumentProceduresSystemWidget (embedded widget, no Scaffold/AppBar)
- [x] Create AirportServicesSystemWidget (embedded widget, no Scaffold/AppBar)
- [x] Create HazardsSystemWidget (embedded widget, no Scaffold/AppBar)
- [x] Create AdminSystemWidget (embedded widget, no Scaffold/AppBar)
- [x] Create OtherSystemWidget (embedded widget, no Scaffold/AppBar)
- [x] Implement system-specific analyzers for each
- [x] Add tabbed navigation within AirportDetailScreen
- [x] Update system status card navigation to use tabs

### Files Created:
- `lib/widgets/system_pages/runway_system_widget.dart`
- `lib/widgets/system_pages/taxiway_system_widget.dart`
- `lib/widgets/system_pages/instrument_procedures_system_widget.dart`
- `lib/widgets/system_pages/airport_services_system_widget.dart`
- `lib/widgets/system_pages/hazards_system_widget.dart`
- `lib/widgets/system_pages/admin_system_widget.dart`
- `lib/widgets/system_pages/other_system_widget.dart`

### Files Modified:
- `lib/screens/airport_detail_screen.dart` (added tabbed navigation)
- `lib/providers/flight_provider.dart` (added system page state management)

### Acceptance Criteria:
- [x] All system widgets work as embedded components
- [x] Tabbed navigation preserves bottom navigation bar
- [x] System status cards navigate to appropriate tabs
- [x] State persistence when switching between tabs
- [x] Clean, operational-focused UI for each system
- [x] Consistent time filtering across all system widgets

### Benefits:
- [x] **Nested Navigation**: System pages are part of Airport tab, preserving bottom navigation
- [x] **State Persistence**: Last viewed system page is remembered
- [x] **Consistent UX**: Same navigation pattern as other tabs
- [x] **Reduced Code**: No need for separate full-screen pages
- [x] **Better Performance**: Embedded widgets are more efficient

## Phase 5: Raw Data Integration
**Goal**: Ensure seamless navigation to filtered raw data

### Tasks:
- [ ] Modify RawDataScreen to accept system filters
- [ ] Implement "View All NOTAMs" functionality
- [ ] Add system-specific filtering to existing NOTAM display
- [ ] Test navigation flow from system pages to raw data

### Files to Modify:
- `lib/screens/raw_data_screen.dart`
- `lib/widgets/notam_grouped_list.dart`

## Phase 6: Testing and Refinement
**Goal**: Validate the hybrid approach with real data

### Tasks:
- [ ] Test with multiple airports and NOTAM scenarios
- [ ] Validate information hierarchy and abstraction levels
- [ ] Performance testing with large datasets
- [ ] User feedback collection and integration
- [ ] Refine UI/UX based on testing results

## Phase 7: Airport Selector Implementation ✅ COMPLETED
**Goal**: Add airport selector bubbles to Airport Status page for better UX

### Tasks:
- [x] Add horizontal scrollable airport selector at top of page
- [x] Implement single airport view instead of scrolling through all airports
- [x] Integrate with existing FlightProvider.selectedAirport
- [x] Maintain existing NOTAM filtering and system status calculation
- [x] Add placeholder dialogs for future airport management
- [x] Test with multiple airports and switching functionality

### Files Modified:
- `lib/screens/airport_detail_screen.dart`

### Features Implemented:
- [x] **Airport Selector Bubbles**: Horizontal scrollable airport selector at top of page
- [x] **Single Airport View**: One airport per page instead of scrolling through all airports
- [x] **Consistent UX**: Same pattern as Raw Data page for familiarity
- [x] **Quick Switching**: Easy airport selection and comparison
- [x] **Space Efficient**: More room for system status details
- [x] **Add/Edit Functionality**: Placeholder dialogs for future airport management

### User Experience Benefits:
- [x] **Better Navigation**: No scrolling through multiple airports
- [x] **Focused View**: One airport at a time for better readability
- [x] **Consistent Design**: Same pattern as Raw Data page
- [x] **Quick Comparison**: Easy switching between airports
- [x] **More Space**: Additional room for system status details

### Acceptance Criteria:
- [x] Airport selector displays all flight airports
- [x] Single airport view shows detailed system status
- [x] Quick switching between airports works smoothly
- [x] Consistent with Raw Data page design pattern
- [x] All existing functionality preserved

## Phase 8: Airport Analysis and Database Infrastructure ⭐ NEW
**Goal**: Build comprehensive airport-specific database and analysis tools

### Tasks:
- [ ] Create airport runway database with actual runway identifiers
- [ ] Create airport taxiway database with actual taxiway layouts  
- [ ] Create airport NAVAID database with actual navigation aids
- [ ] Build airport analysis service for operational impact assessment
- [ ] Integrate airport-specific data with system status pages
- [ ] Enhance status reporting with actual airport infrastructure

### Files to Create:
- `lib/services/airport_analysis_service.dart`
- `lib/models/airport_infrastructure.dart`
- `lib/services/airport_database_service.dart`
- `lib/data/airport_infrastructure_data.dart`

### Features to Implement:
- [ ] **Runway Analysis**: Show when one ILS approach is unavailable, indicate if another is available
- [ ] **Taxiway Analysis**: Identify alternative routes when specific taxiways are closed
- [ ] **NAVAID Analysis**: Show backup navigation options when primary aids are unavailable
- [ ] **Operational Impact Assessment**: Calculate actual operational impact based on available alternatives
- [ ] **Enhanced Status Reporting**: Show status for actual airport components (e.g., "RWY 03/21" instead of "General Runway")

### Benefits:
- [ ] More precise operational impact assessment
- [ ] Better integration with airport diagrams
- [ ] Enhanced pilot decision-making support
- [ ] Accurate component-specific status reporting
- [ ] Intelligent alternative route suggestions

### Acceptance Criteria:
- [ ] Airport database covers major airports with accurate infrastructure data
- [ ] System status pages show actual airport component status
- [ ] Operational impact assessment considers available alternatives
- [ ] Enhanced status reporting provides actionable information
- [ ] Integration with existing NOTAM analysis maintains consistency

## Phase 8: System Page Fit-for-Purpose Review
**Goal**: Comprehensive review and refinement of all system-specific pages

### Tasks:
- [ ] Review each system page for operational relevance
- [ ] Validate information hierarchy and user workflow
- [ ] Assess integration with airport analysis infrastructure
- [ ] Optimize performance and user experience
- [ ] Implement user feedback and improvements
- [ ] Final testing and validation

### Review Criteria:
- [ ] **Operational Focus**: Does the page provide actionable information for pilots?
- [ ] **Information Hierarchy**: Is the information presented in the right order of importance?
- [ ] **User Workflow**: Does the navigation flow support efficient decision-making?
- [ ] **Accuracy**: Are the status assessments accurate and reliable?
- [ ] **Completeness**: Does the page cover all relevant operational aspects?
- [ ] **Performance**: Does the page load quickly and respond smoothly?

### Files to Review:
- `lib/screens/runway_system_page.dart`
- `lib/screens/taxiway_system_page.dart`
- `lib/screens/instrument_procedures_system_page.dart`
- `lib/screens/airport_services_system_page.dart`
- `lib/screens/hazards_system_page.dart`
- `lib/screens/admin_system_page.dart`
- `lib/screens/other_system_page.dart`

## Phase 8: Global Time Filter Implementation ✅ COMPLETED
**Goal**: Add global time filter to all system pages for consistent user experience

### Tasks:
- [x] Add global time filter state to FlightProvider
- [x] Implement shared time filter methods (setTimeFilter, filterNotamsByTimeAndAirport)
- [x] Update Airport Detail Screen to use global time filter
- [x] Add time filter header to all system pages (Runways, Taxiways, Instrument Procedures, Airport Services, Hazards, Admin, Other)
- [x] Wrap all system pages with Consumer<FlightProvider>
- [x] Update all tests to work with Provider pattern
- [x] Test time filter functionality across all pages

### Files Modified:
- `lib/providers/flight_provider.dart`
- `lib/screens/airport_detail_screen.dart`
- `lib/screens/runway_system_page.dart`
- `lib/screens/taxiway_system_page.dart`
- `lib/screens/instrument_procedures_system_page.dart`
- `lib/screens/airport_services_system_page.dart`
- `lib/screens/hazards_system_page.dart`
- `lib/screens/admin_system_page.dart`
- `lib/screens/other_system_page.dart`
- `test/admin_system_page_test.dart`
- `test/hazards_system_page_test.dart`
- `test/other_system_page_test.dart`

### Features Implemented:
- [x] **Global Time Filter State**: Centralized time filter in FlightProvider
- [x] **Consistent UX**: All system pages now have the same time filter
- [x] **Shared State**: Time filter changes propagate across all pages
- [x] **No Navigation Required**: Users can change time filter on any page
- [x] **Default 24 Hours**: Sensible default time window
- [x] **Time Options**: 6h, 12h, 24h, 72h, All Future
- [x] **NOTAM Filtering**: All pages filter NOTAMs by selected time window
- [x] **Test Updates**: All tests updated to work with Provider pattern

### Benefits:
- [x] **User Experience**: No need to navigate back to change time filter
- [x] **Consistency**: Same time filter behavior across all pages
- [x] **Operational Efficiency**: Quick time window adjustments
- [x] **Reduced Friction**: Eliminates multi-step navigation for time changes

## Success Criteria

### Phase 1-6 (Current Implementation):
- [ ] Clean airport status overview without embedded details
- [ ] Functional navigation to system-specific pages
- [ ] Consistent NOTAM classification across all pages
- [ ] Operational-focused system status displays
- [ ] Seamless integration with raw data views

### Phase 7 (Airport Infrastructure):
- [ ] Comprehensive airport database with accurate infrastructure data
- [ ] Enhanced status reporting with actual airport components
- [ ] Intelligent operational impact assessment
- [ ] Integration with existing NOTAM analysis

### Phase 8 (Fit-for-Purpose Review):
- [ ] All system pages provide actionable operational information
- [ ] Information hierarchy supports efficient pilot decision-making
- [ ] Performance and user experience optimized
- [ ] User feedback integrated and validated

## Timeline

### Current Status:
- ✅ Phase 1: Clean Up Current Airport Status Page
- ✅ Phase 2: Create System-Specific Page Infrastructure  
- ✅ Phase 3: Implement Runway System Page (Pilot)
- ✅ Phase 4: Implement Remaining System Pages (Partial)
- ✅ Phase 5: Raw Data Integration
- ✅ Phase 6: Testing and Refinement (Partial)
- ✅ Phase 7: Airport Selector Implementation

### Next Steps:
- 🔄 Phase 4: Complete remaining system pages (Hazards, Admin, Other)
- ⏳ Phase 7: Airport Analysis and Database Infrastructure
- ⏳ Phase 8: System Page Fit-for-Purpose Review

## Technical Architecture

### Current Implementation:
```
Flight Summary → Airport Status → System-Specific Pages → Raw Data
     ↑              ↑                    ↑                    ↑
High-level    System overview    Component details    Full NOTAM data
```

### Future Implementation (Phase 7+):
```
Flight Summary → Airport Status → System-Specific Pages → Raw Data
     ↑              ↑                    ↑                    ↑
High-level    System overview    Component details    Full NOTAM data
     ↑              ↑                    ↑                    ↑
Airport DB    Airport Analysis   Enhanced Status     Filtered Views
```

## User Experience Goals

### Information Architecture (4-Layer Abstraction):
1. **Flight Summary**: High-level route overview with risk assessment
2. **Airport Status**: System-level status with color-coded indicators
3. **System-Specific Pages**: Detailed component analysis with operational impacts
4. **Raw Data**: Full NOTAM details with intelligent filtering

### Operational Focus:
- Fast access to critical information
- Clear status indicators for quick decision-making
- Detailed drill-down for comprehensive analysis
- Consistent classification and presentation
- Integration with actual airport infrastructure 