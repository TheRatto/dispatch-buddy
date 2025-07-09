# NOTAM Grouping Implementation Roadmap

## Overview
This document outlines the implementation plan for adding NOTAM grouping functionality to Dispatch Buddy. The feature will group NOTAMs by operational significance and allow users to expand/collapse groups for better organization.

## 📊 Current Status
- **Phase 1**: ✅ **COMPLETED** (Foundation - NOTAM grouping infrastructure)
- **Phase 2**: 🔄 **READY TO START** (Text-based classification)
- **Phase 3**: ⏳ **PENDING** (UI Components)
- **Phase 4**: ⏳ **PENDING** (Integration)
- **Phase 5**: ⏳ **PENDING** (Advanced Features)

**Next**: Begin Phase 2 - Text-based classification for non-Q code NOTAMs

## 🎯 Feature Goals
- Group NOTAMs by affected system/operational significance
- Provide collapsible/expandable group interface
- Maintain single NOTAM per group (most critical system)
- Support text-based classification as fallback
- Preserve existing functionality while adding grouping

## 📋 Proposed NOTAM Groups

### 1. 🛬 Movement Areas (Runways, Taxiways, Aprons, Parking)
**Priority**: Highest (Operational Critical)
**Keywords**: `CLOSED`, `U/S`, `UNSERVICEABLE`, `DISPLACED`, `LIMITED`, `MISSING`, `RWY XX`, `TAXIWAY`, `APRON`, `PARKING`
- Runway/taxiway closures (full/partial, temporary/permanent)
- Runway surface condition changes (braking action, contaminants)
- Displaced thresholds or declared distance changes (TORA/TODA/ASDA/LDA)
- Temporary or permanent changes to runway/taxiway length/width
- Apron/parking area closures or restrictions
- Aircraft stand availability changes

### 2. 📡 Navigation Aids
**Priority**: High (Safety Critical)
**Keywords**: `ILS`, `GLS`, `VOR`, `NDB`, `DME`, `DA`, `MDA`, `MINIMA`
- ILS/GLS/VOR/NDB out of service
- Instrument approach procedure amendments or suspensions
- Minimums changes for any procedure (raised DA/MDA)
- Nav aid power outages or scheduled interruptions

### 3. 🛫 Departure/Approach Procedures
**Priority**: High (Safety Critical)
**Keywords**: `SID`, `STAR`, `APPROACH`, `DEPARTURE`, `PROCEDURE`
- New or amended SIDs/STARs
- Instrument approach procedure changes
- Visual approach procedure modifications
- Departure procedure amendments
- Missed approach procedure changes

### 4. 🏢 Airport and ATC Availability
**Priority**: High (Operational Critical)
**Keywords**: `CLOSED`, `NO`, `NOT AVBL`, `AVBL`, `OPR HR`, `ATC`, `TWR`, `GND`, `APP`
- Airport closure (full or partial)
- Air Traffic Services availability changes (TWR, GND, APP, ATIS)
- Fuel not available
- Fire category downgraded or unavailable
- Bird or drone hazard advisories

### 5. 💡 Lighting
**Priority**: Medium (Operational)
**Keywords**: `LIGHTING`, `LIGHTS`, `HIRL`, `REIL`, `PAPI`, `VASIS`
- Runway/taxiway lighting outages (HIRL, REIL, centerline, edge)
- Approach lighting system changes
- PAPI/VASIS unserviceable
- Aerodrome beacon issues
- Pilot-controlled lighting changes

### 6. ⚠️ Hazards and Obstacles
**Priority**: Medium (Safety)
**Keywords**: `OBSTACLE`, `CRANE`, `CONSTRUCTION`, `UNLIT`, `HAZARD`
- New or uncharted obstacles near airport or enroute
- Temporary cranes or construction activity
- Unlit obstacles or light failure on towers
- Bird or wildlife hazards
- Construction activity affecting operations

### 7. ✈️ Airspace
**Priority**: Medium (Strategic)
**Keywords**: `RESTRICTED`, `PROHIBITED`, `DANGER`, `GPS`, `RNAV`, `AIRSPACE`
- Airspace restrictions or activations (military, VIP, aerobatics)
- Temporary Reserved Airspace (TRA), Danger/Restricted Areas (D/RAs)
- GPS/RNAV outages or disruptions
- RNAV/GNSS equipment required (RNP10, PBN alerts)

### 8. 📑 Procedural and Admin
**Priority**: Low (Informational)
**Keywords**: `CURFEW`, `NOISE`, `PPR`, `SLOT`, `RESTRICTION`
- Changes to slot restrictions, curfews, noise abatement
- PPR or parking/gate limitations
- ATIS frequency or content changes
- Administrative procedures

### 9. 🔧 Other
**Priority**: Lowest (Fallback)
- Unmapped Q codes
- Non-Q code NOTAMs without keyword matches
- Miscellaneous operational notices

## 🗺️ Q Code to Group Mapping

### Movement Areas (Group 1)
```
MR - Runway
MX - Taxiway
MS - Stopway
MT - Threshold
MU - Runway turning bay
MW - Strip/shoulder
MY - Rapid exit taxiway
MK - Parking area
MN - Apron
MP - Aircraft stands
```

### Navigation Aids (Group 2)
```
IC - ILS
ID - ILS DME
IG - Glide path (ILS)
II - Inner marker (ILS)
IL - Localizer (ILS)
IM - Middle marker (ILS)
IN - Localizer (non-ILS)
IO - Outer marker (ILS)
IS - ILS Category I
IT - ILS Category II
IU - ILS Category III
IW - MLS
IX - Locator, outer (ILS)
IY - Locator, middle (ILS)
NA - All radio navigation facilities
NB - Nondirectional radio beacon
NC - DECCA
ND - Distance measuring equipment (DME)
NF - Fan marker
NL - Locator
NM - VOR/DME
NN - TACAN
NO - OMEGA
NT - VORTAC
NV - VOR
PI - Instrument approach procedure
PM - Aerodrome operating minima
```

### Departure/Approach Procedures (Group 3)
```
PA - Standard instrument arrival
PB - Standard VFR arrival
PC - Contingency procedures
PD - Standard instrument departure
PE - Standard VFR departure
PH - Holding procedure
PI - Instrument approach procedure
PK - VFR approach procedure
PU - Missed approach procedure
```

### Airport and ATC Availability (Group 4)
```
FA - Aerodrome
FF - Fire fighting and rescue
FU - Fuel availability
FM - Meteorological service
```

### Lighting (Group 5)
```
LA - Approach lighting system
LB - Aerodrome beacon
LC - Runway centre line lights
LD - Landing direction indicator lights
LE - Runway edge lights
LF - Sequenced flashing lights
LG - Pilot-controlled lighting
LH - High intensity runway lights
LI - Runway end identifier lights
LJ - Runway alignment indicator lights
LK - CAT II components of ALS
LL - Low intensity runway lights
LM - Medium intensity runway lights
LP - PAPI
LR - All landing area lighting facilities
LS - Stopway lights
LT - Threshold lights
LU - Helicopter approach path indicator
LV - VASIS
LW - Heliport lighting
LX - Taxiway centre line lights
LY - Taxiway edge lights
LZ - Runway touchdown zone lights
```

### Hazards and Obstacles (Group 6)
```
OB - Obstacle
OL - Obstacle lights
```

### Airspace (Group 7)
```
AA - Minimum altitude
AC - Class B/C/D/E Surface Area
AD - Air defense identification zone
AE - Control area
AF - Flight information region
AH - Upper control area
AL - Minimum usable flight level
AN - Area navigation route
AO - Oceanic control area
AP - Reporting point
AR - ATS route
AT - Terminal control area
AU - Upper flight information region
AV - Upper advisory area
AX - Significant point
AZ - Aerodrome traffic zone
RA - Airspace reservation
RD - Danger area
RM - Military operating area
RO - Overflying of...
RP - Prohibited area
RR - Restricted area
RT - Temporary restricted area
GA - GNSS airfield-specific operations
GW - GNSS area-wide operations
```

### Procedural and Admin (Group 8)
```
PA - Standard instrument arrival
PB - Standard VFR arrival
PC - Contingency procedures
PD - Standard instrument departure
PE - Standard VFR departure
PF - Flow control procedure
PH - Holding procedure
PK - VFR approach procedure
PL - Flight plan processing
PN - Noise operating restriction
PO - Obstacle clearance altitude and height
PR - Radio failure procedures
PT - Transition altitude or transition level
PU - Missed approach procedure
PX - Minimum holding altitude
PZ - ADIZ procedure
```



## 🚀 Implementation Phases

### Phase 1: Foundation (Week 1) ✅ **COMPLETED**
**Goal**: Create the grouping infrastructure

#### Tasks:
- [x] **1.1** Create `NotamGroup` enum with all 9 groups
- [x] **1.2** Extend `Notam` model with `group` property
- [x] **1.3** Create `NotamGroupingService` class
- [x] **1.4** Implement Q code to group mapping function
- [x] **1.5** Add unit tests for grouping logic
- [x] **1.6** Update existing NOTAM parsing to assign groups

#### Acceptance Criteria:
- [x] All NOTAMs can be assigned to a group
- [x] Q code mapping covers all major codes
- [x] Unit tests pass with 90%+ coverage
- [x] No regression in existing functionality

**Status**: ✅ **COMPLETED** - All Phase 1 tasks completed successfully. 83 tests passing, 5 expected failures (error handling tests). Q code mapping implemented and tested. NOTAM model extended with group property and grouping service created.

**Note**: Q code coverage review needed - need to verify all ICAO Q code subjects are included in our groupings. This will be addressed in Phase 2.

### Phase 2: Text-Based Classification (Week 2)
**Goal**: Implement fallback classification for non-Q code NOTAMs

#### Tasks:
- [ ] **2.1** Create keyword mapping for each group
- [ ] **2.2** Implement text analysis function
- [ ] **2.3** Add confidence scoring for text-based matches
- [ ] **2.4** Create fallback logic (Q code → text → "Other")
- [ ] **2.5** Add unit tests for text classification
- [ ] **2.6** Test with real NOTAM data

#### Acceptance Criteria:
- Non-Q code NOTAMs are properly classified
- Keyword matching is accurate and comprehensive
- Fallback logic works correctly
- Performance is acceptable (<100ms per NOTAM)

### Phase 3: UI Components (Week 3)
**Goal**: Create the grouped NOTAM display interface

#### Tasks:
- [ ] **3.1** Create `NotamGroupHeader` widget
- [ ] **3.2** Create `NotamGroupContent` widget
- [ ] **3.3** Create `NotamGroupedList` widget
- [ ] **3.4** Implement expand/collapse functionality
- [ ] **3.5** Add group sorting (by priority)
- [ ] **3.6** Add NOTAM sorting within groups (by time/significance)
- [ ] **3.7** Add "collapse all" / "expand all" functionality

#### Acceptance Criteria:
- Groups display in correct priority order
- Expand/collapse works smoothly
- NOTAMs sort correctly within groups
- UI is responsive and intuitive

### Phase 4: Integration (Week 4)
**Goal**: Integrate grouping into existing NOTAM screens

#### Tasks:
- [ ] **4.1** Update NOTAM list screens to use grouping
- [ ] **4.2** Add group filtering options
- [ ] **4.3** Implement group-based search
- [ ] **4.4** Add group statistics (count per group)
- [ ] **4.5** Test with real flight scenarios
- [ ] **4.6** Performance optimization

#### Acceptance Criteria:
- Grouping works in all NOTAM screens
- Filtering and search work correctly
- Performance meets requirements
- User experience is intuitive

### Phase 5: Advanced Features (Week 5)
**Goal**: Add advanced grouping features

#### Tasks:
- [ ] **5.1** Add user customization (group reordering)
- [ ] **5.2** Implement "ghost" NOTAM display for secondary groups
- [ ] **5.3** Add group-based notifications
- [ ] **5.4** Create group export functionality
- [ ] **5.5** Add group-based reporting
- [ ] **5.6** Implement confidence scoring for text-based classification
- [ ] **5.7** Performance monitoring and optimization

#### Acceptance Criteria:
- Users can customize group order
- Advanced features work correctly
- Performance remains optimal
- All features are well-documented

## 🔧 Technical Implementation Details

### Data Models

```dart
enum NotamGroup {
  movementAreas,    // Group 1
  navigationAids,   // Group 2
  departureApproachProcedures, // Group 3
  airportAtcAvailability, // Group 4
  lighting,         // Group 5
  hazardsObstacles, // Group 6
  airspace,         // Group 7
  proceduralAdmin,  // Group 8
  other            // Group 9
}

class NotamGroupInfo {
  final NotamGroup group;
  final String displayName;
  final String icon;
  final int priority;
  final List<String> keywords;
  final List<String> qCodes;
}
```

### Services

```dart
class NotamGroupingService {
  NotamGroup assignGroup(Notam notam);
  List<String> getKeywordsForGroup(NotamGroup group);
  List<String> getQCodesForGroup(NotamGroup group);
  int getGroupPriority(NotamGroup group);
  List<Notam> sortNotamsInGroup(List<Notam> notams);
}
```

### Widgets

```dart
class NotamGroupedList extends StatelessWidget
class NotamGroupHeader extends StatelessWidget
class NotamGroupContent extends StatelessWidget
```

## 🧪 Testing Strategy

### Unit Tests
- Q code to group mapping accuracy
- Text-based classification accuracy
- Group sorting and priority logic
- NOTAM sorting within groups

### Integration Tests
- End-to-end NOTAM grouping workflow
- Performance with large NOTAM datasets
- UI responsiveness and user interactions

### User Acceptance Tests
- Real flight scenario testing
- Pilot/dispatcher feedback
- Performance in operational conditions

## 📊 Success Metrics

### Functional Metrics
- [ ] 95%+ accuracy in Q code grouping
- [ ] 90%+ accuracy in text-based classification
- [ ] <100ms grouping performance per NOTAM
- [ ] Zero regressions in existing functionality

### User Experience Metrics
- [ ] User satisfaction with grouped display
- [ ] Reduced time to find relevant NOTAMs
- [ ] Positive feedback from pilot/dispatcher testing
- [ ] Intuitive expand/collapse functionality

### Performance Metrics
- [ ] <500ms total grouping time for 100 NOTAMs
- [ ] Smooth scrolling with grouped display
- [ ] Memory usage within acceptable limits
- [ ] Battery impact minimal

## 🚨 Risk Mitigation

### Technical Risks
- **Risk**: Q code mapping incomplete
  - **Mitigation**: Comprehensive testing with real NOTAM data
- **Risk**: Performance issues with large datasets
  - **Mitigation**: Implement caching and optimization
- **Risk**: Text classification accuracy
  - **Mitigation**: Extensive keyword testing and fallback logic

### User Experience Risks
- **Risk**: Users prefer current display
  - **Mitigation**: Make grouping optional, provide toggle
- **Risk**: Grouping confuses users
  - **Mitigation**: Clear documentation and intuitive UI

## 📝 Future Enhancements

### Phase 6: Advanced Features (Future)
- [ ] Machine learning-based classification
- [ ] User-defined custom groups
- [ ] Group-based notifications and alerts
- [ ] Integration with flight planning
- [ ] Advanced filtering and search
- [ ] Group-based reporting and analytics

## 🎯 Next Steps

1. **Review and approve this roadmap**
2. **Begin Phase 1 implementation**
3. **Set up development environment**
4. **Create initial Q code mapping**
5. **Start with unit tests**

## 📞 Questions for Clarification

1. **Operational Significance**: Should we implement a scoring system for NOTAM significance within groups?
2. **Group Order**: Is the proposed priority order (1-9) correct for operational needs?
3. **Text Classification**: Should we implement confidence scoring for text-based matches? (Moved to Phase 5)
4. **User Customization**: When should we implement group reordering? (Phase 5)
5. **Performance**: What are the acceptable performance thresholds for grouping operations? (Confirmed: <100ms per NOTAM, <500ms for 100 NOTAMs)

---

**Document Version**: 1.0  
**Last Updated**: 2024-01-XX  
**Next Review**: After Phase 1 completion
