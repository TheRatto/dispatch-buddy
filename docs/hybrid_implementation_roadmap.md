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

## Phase 3: Implement Runway System Page (Pilot)
**Goal**: Build the first system-specific page as proof of concept

### Tasks:
- [ ] Create RunwaySystemPage extending SystemDetailScreen
- [ ] Implement runway-specific status logic
- [ ] Extract key operational impacts from runway NOTAMs
- [ ] Display individual runway status (e.g., "Runway 03: Operational")
- [ ] Add "View All Runway NOTAMs" button
- [ ] Test with real runway NOTAM data

### Files to Create:
- `lib/screens/runway_system_page.dart`
- `lib/services/runway_status_analyzer.dart`

### Acceptance Criteria:
- [ ] Shows individual runway status
- [ ] Displays key operational impacts
- [ ] Links to filtered raw data
- [ ] Clean, operational-focused UI

## Phase 4: Implement Remaining System Pages
**Goal**: Build system-specific pages for all 7 groups

### Tasks:
- [ ] Create TaxiwaySystemPage
- [ ] Create InstrumentProceduresSystemPage
- [ ] Create AirportServicesSystemPage
- [ ] Create HazardsSystemPage
- [ ] Create AdminSystemPage
- [ ] Create OtherSystemPage
- [ ] Implement system-specific analyzers for each
- [ ] Add navigation from AirportDetailScreen to all systems

### Files to Create:
- `lib/screens/taxiway_system_page.dart`
- `lib/screens/instrument_procedures_system_page.dart`
- `lib/screens/airport_services_system_page.dart`
- `lib/screens/hazards_system_page.dart`
- `lib/screens/admin_system_page.dart`
- `lib/screens/other_system_page.dart`
- `lib/services/taxiway_status_analyzer.dart`
- `lib/services/instrument_procedures_status_analyzer.dart`
- `lib/services/airport_services_status_analyzer.dart`
- `lib/services/hazards_status_analyzer.dart`
- `lib/services/admin_status_analyzer.dart`
- `lib/services/other_status_analyzer.dart`

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
- [ ] Test navigation flow and user experience
- [ ] Optimize performance for large NOTAM datasets
- [ ] Gather feedback on operational usefulness

## Phase 7: Progressive Abstraction Features
**Goal**: Add features to help pilots adapt to higher abstraction levels

### Tasks:
- [ ] Add abstraction level indicators
- [ ] Implement "Show More Detail" options
- [ ] Add contextual help for new users
- [ ] Consider AI-powered operational impact summaries

## Technical Considerations

### Data Flow:
1. FlightProvider → AirportSystemAnalyzer → System-specific analyzers
2. System analyzers extract operational impacts from NOTAMs
3. System pages display human-readable summaries
4. Raw data provides full NOTAM details

### Performance:
- System-specific data should be calculated once and cached
- Lazy loading for system pages
- Efficient NOTAM filtering for raw data integration

### User Experience:
- Consistent navigation patterns across all system pages
- Clear visual hierarchy and status indicators
- Fast access to detailed information when needed

## Success Metrics
- [ ] Reduced information overload on airport status page
- [ ] Faster access to system-specific operational impacts
- [ ] Positive pilot feedback on information hierarchy
- [ ] Successful navigation between abstraction levels
- [ ] No overflow issues in UI

## Future Considerations
- Weather integration in system pages
- Real-time updates during flight
- Offline capability for system data
- Export functionality for system summaries 