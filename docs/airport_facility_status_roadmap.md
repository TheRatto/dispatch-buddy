# Airport Facility Status - NOTAM Integration Roadmap

## 🎯 **Feature Overview**
Connect existing NOTAM Q-code classification with ERSA-derived airport facilities to provide real-time status updates (Green/Amber/Red) for individual runways, NAVAIDs, and lighting systems.

## 📊 **Current Status**
- **Phase 1**: ✅ **COMPLETED** (NOTAM grouping by Q-codes)
- **Phase 2**: ✅ **COMPLETED** (ERSA airport facilities display)
- **Phase 3**: ✅ **COMPLETED** (Connect NOTAMs to individual facilities)
- **Phase 4**: ⏳ **PENDING** (Facility-specific status calculation)
- **Phase 5**: ⏳ **PENDING** (Enhanced UI with status colors)

## 🏗️ **What's Already Built**

### **1. NOTAM Classification System** ✅
- **9 NOTAM Groups** with comprehensive Q-code mapping
- **Movement Areas**: Runways, taxiways, aprons (QMRLC, QMX, etc.)
- **Navigation Aids**: ILS, VOR, DME, approach procedures (QICAS, QNV, etc.)
- **Lighting**: Runway, taxiway, approach lighting (QOLAS, QLH, etc.)
- **Time-based filtering** already working

### **2. ERSA Airport Facilities** ✅
- **Runway data**: Identifiers, dimensions, surface types
- **NAVAID data**: Types, frequencies, identifiers
- **Lighting systems**: Available lighting infrastructure
- **Facility grouping** and display already implemented

### **3. Airport System Analysis** ✅
- **`AirportSystemAnalyzer`** service exists
- **System-level status** calculation (runways, NAVAIDs, lighting)
- **NOTAM filtering** by airport and time

## 🚀 **Implementation Roadmap**

### **Phase 1: Facility-NOTAM Mapping** (3-4 hours)
**Priority**: HIGH
**Goal**: Connect grouped NOTAMs to specific ERSA facilities

#### **Task 1.1: Create FacilityNotamMapper Service**
**File**: `lib/services/facility_notam_mapper.dart`
**Responsibility**: Map NOTAM groups to individual ERSA facilities

```dart
class FacilityNotamMapper {
  // Map NOTAMs to specific runway
  List<Notam> getRunwayNotams(List<Notam> allNotams, String runwayId);
  
  // Map NOTAMs to specific NAVAID
  List<Notam> getNavaidNotams(List<Notam> allNotams, String navaidId);
  
  // Map NOTAMs to specific lighting system
  List<Notam> getLightingNotams(List<Notam> allNotams, String lightingId);
}
```

**Subtasks**:
- ✅ Create basic class structure
- ✅ Implement runway NOTAM mapping logic
- ✅ Implement NAVAID NOTAM mapping logic
- ✅ Implement lighting NOTAM mapping logic
- ✅ Add unit tests for mapping accuracy

**Implementation Discovery**:
- ✅ **FacilityNotamMapper service created** with runway, NAVAID, taxiway, and lighting mapping
- ✅ **Pattern matching logic implemented** for facility identification
- ✅ **Dual-direction runway support** (e.g., "07" matches "RWY 07/25", "16L" matches "RWY 16L/34R")
- ✅ **Cross-group runway search implemented** with `getAllRunwayAffectingNotams()` method
- ✅ **All unit tests passing** - facility mapping working correctly
- ✅ **Regex pattern enhanced** to handle runway identifiers with letters (16L/34R, etc.)

#### **Task 1.2: Facility Identification Logic**
**Responsibility**: Identify which NOTAMs affect specific facilities

**Implementation Strategy**:
- **Runways**: Match by runway identifier (03/21, 06/24)
- **NAVAIDs**: Match by NAVAID identifier (VOR/DME PH, ILS IGD)
- **Lighting**: Match by lighting system type (PAPI, REIL, HIRL)

**Keywords to Match**:
- **Runway 03/21**: "RWY 03", "RWY 21", "03/21", "RUNWAY 03"
- **VOR/DME PH**: "VOR PH", "DME PH", "PH VOR"
- **ILS IGD**: "ILS IGD", "IGD ILS", "LOC IGD"

### **Phase 2: Facility-Specific Status Analysis** (2-3 hours)
**Priority**: HIGH
**Goal**: Calculate status for each individual facility

#### **Task 2.1: Enhance AirportSystemAnalyzer**
**File**: `lib/services/airport_system_analyzer.dart`
**Responsibility**: Add facility-specific analysis methods

```dart
class AirportSystemAnalyzer {
  // New methods for individual facilities
  SystemStatus analyzeFacilityStatus(List<Notam> facilityNotams, String facilityId);
  String getFacilityStatusText(SystemStatus status, List<Notam> notams);
  List<Notam> getCriticalNotams(List<Notam> facilityNotams);
}
```

**Subtasks**:
- [ ] Add `analyzeFacilityStatus` method
- [ ] Add `getFacilityStatusText` method for descriptive status
- [ ] Add `getCriticalNotams` method for NOTAM details
- [ ] Update existing system analysis methods to use new logic

#### **Task 2.2: Status Calculation Logic**
**Responsibility**: Determine Green/Amber/Red status for each facility

**Status Rules**:
- **🟢 Green**: No NOTAMs or NOTAMs with no operational impact
- **🟠 Amber**: Partial limitations, reduced capability, temporary restrictions
- **🔴 Red**: Full closure, unserviceable, critical outages

**Q-Code Mapping**:
- **Red Status**: QMRLC (runway closure), QICAS (ILS unserviceable), QOLAS (lighting unserviceable)
- **Amber Status**: QFAXX (flight procedures), QMX (taxiway limitations), QLH (lighting limitations)
- **Green Status**: Informational NOTAMs, administrative changes

### **Phase 3: UI Status Integration** (2-3 hours)
**Priority**: HIGH
**Goal**: Display facility-specific status in existing UI

#### **Task 3.1: Update Facility Cards**
**Files**: 
- `lib/widgets/system_pages/runway_system_widget.dart`
- `lib/widgets/system_pages/instrument_procedures_system_widget.dart`
- `lib/widgets/system_pages/airport_services_system_widget.dart`

**Responsibility**: Replace generic "Operational" with facility-specific status

**Changes**:
- [ ] Update status button colors (Green/Amber/Red)
- [ ] Update status text to show limitations
- [ ] Make status buttons clickable
- [ ] Add NOTAM count indicators (optional)

#### **Task 3.2: Status Button Enhancement**
**Responsibility**: Create enhanced status display with limitation details

```dart
Widget _buildStatusButton(SystemStatus status, List<Notam> notams, String facilityId) {
  return GestureDetector(
    onTap: notams.isNotEmpty ? () => _showNotamDetails(notams, facilityId) : null,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _getStatusText(status, notams),
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
```

### **Phase 4: NOTAM Detail Integration** (2-3 hours)
**Priority**: MEDIUM
**Goal**: Show NOTAM details when status is clicked

#### **Task 4.1: NOTAM Detail Modal**
**Responsibility**: Display relevant NOTAMs for clicked facility

**Features**:
- [ ] Modal bottom sheet with facility NOTAMs
- [ ] Filtered by time window and facility
- [ ] Show NOTAM text and impact details
- [ ] Link to full NOTAMs page

#### **Task 4.2: NOTAM Impact Summary**
**Responsibility**: Show limitation reason in status text

**Examples**:
- **Amber**: "Limited - Displaced threshold 500ft"
- **Amber**: "Limited - Reduced width to 30m"
- **Red**: "Closed - Maintenance until 1800Z"

### **Phase 5: Time-Based Updates** (2-3 hours)
**Priority**: MEDIUM
**Goal**: Automatic status updates as NOTAMs change

#### **Task 5.1: Background Status Updates**
**Responsibility**: Update facility status every 15 minutes

**Implementation**:
- [ ] Add `Timer.periodic` for status updates
- [ ] Check for NOTAMs entering/leaving time windows
- [ ] Update UI when status changes
- [ ] Clean up timers on dispose

#### **Task 5.2: Status Change Indicators**
**Responsibility**: Show when facility status has changed

**Features**:
- [ ] Visual indicator for recent status changes
- [ ] "Updated X minutes ago" badge
- [ ] Smooth transitions between status changes

### **Phase 6: Testing & Refinement** (2-3 hours)
**Priority**: HIGH
**Goal**: Ensure accuracy and performance

#### **Task 6.1: Unit Testing**
**Responsibility**: Test facility-NOTAM mapping accuracy

**Tests**:
- [ ] Test runway NOTAM mapping
- [ ] Test NAVAID NOTAM mapping
- [ ] Test lighting NOTAM mapping
- [ ] Test status calculation logic

#### **Task 6.2: Integration Testing**
**Responsibility**: Test with real NOTAM data

**Scenarios**:
- [ ] Runway closure NOTAMs
- [ ] ILS unserviceable NOTAMs
- [ ] Lighting outage NOTAMs
- [ ] Mixed impact scenarios

## 🎯 **Success Criteria**

### **Functional Requirements**
- [ ] Each facility shows individual status (Green/Amber/Red)
- [ ] Status text shows limitation reason
- [ ] Clickable status buttons show NOTAM details
- [ ] Status updates automatically every 15 minutes
- [ ] Time filtering affects facility status

### **Performance Requirements**
- [ ] Status calculation completes in <100ms
- [ ] UI updates smoothly without lag
- [ ] Background updates don't impact user experience
- [ ] Memory usage remains stable

### **User Experience Requirements**
- [ ] Status is immediately understandable
- [ ] Limitation details are clear at a glance
- [ ] NOTAM details are easily accessible
- [ ] Status changes are visually apparent

## 🔒 **Compatibility Guarantees**

### **Existing Functionality Protection**
- [ ] **No changes to NOTAM grouping logic**
- [ ] **No changes to ERSA facility display**
- [ ] **No changes to existing NOTAMs page**
- [ ] **Maintain all existing system analysis methods**

### **Implementation Strategy**
- [ ] **Extend existing services** rather than replace
- [ ] **Add new methods** to existing classes where appropriate
- [ ] **Use composition** over modification of existing code
- [ ] **Comprehensive testing** of existing functionality

## 📅 **Timeline Estimate**

### **Week 1: Core Implementation**
- **Days 1-2**: Phase 1 (Facility-NOTAM Mapping)
- **Days 3-4**: Phase 2 (Status Analysis)
- **Day 5**: Phase 3 (UI Integration)

### **Week 2: Enhancement & Testing**
- **Days 1-2**: Phase 4 (NOTAM Details)
- **Days 3-4**: Phase 5 (Time Updates)
- **Day 5**: Phase 6 (Testing & Refinement)

### **Total Estimated Time**: 13-19 hours over 2 weeks

## 🎯 **Key Benefits**

1. **Leverages Existing Investment**: Uses NOTAM grouping and ERSA integration already built
2. **Facility-Specific Status**: Each runway/NAVAID shows its own operational status
3. **Real-time Updates**: Status changes as NOTAMs become active/expire
4. **Clear Impact Display**: Pilots see exactly what limitations exist
5. **Incremental Enhancement**: Builds on what's working without breaking existing functionality

## 🚀 **Next Steps**

1. **Review and approve this roadmap**
2. **Start with Phase 1: FacilityNotamMapper**
3. **Test facility-NOTAM mapping with existing data**
4. **Iterate on mapping logic based on test results**
5. **Proceed with status calculation and UI updates**

This roadmap provides a clear path to implement the facility status feature while leveraging all the existing work. Each phase builds on the previous one, ensuring we maintain quality and don't break existing functionality.
