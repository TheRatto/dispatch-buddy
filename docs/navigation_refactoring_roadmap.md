# Navigation Refactoring Roadmap

## 🎯 **Objective**
Implement nested navigation so that system status pages (Runways, Taxiways, etc.) are part of the "Airports" tab rather than separate routes, ensuring the bottom navigation bar remains visible on all pages.

## 📊 **Current State**
- ✅ Bottom navigation bar exists in `BriefingTabsScreen` (using Flutter's `BottomNavigationBar`)
- ✅ 7 system pages exist as separate routes (using `Navigator.push()`)
- ❌ Bottom navigation disappears on system pages
- ❌ No "last viewed" state tracking

## 🗺️ **Implementation Roadmap**

### **Phase 1: Foundation & State Management** ⚡ **SAFE**

#### **Step 1.1: Add Navigation State to FlightProvider** 
**Status**: ✅ **COMPLETED**
**Goal**: Track which system page and Raw Data tab user was last viewing
**Files**: 
- `lib/providers/flight_provider.dart`

**Changes**:
- [x] Add `_lastViewedSystemPage` property (int index)
- [x] Add `_lastViewedRawDataTab` property (int index) 
- [x] Add getter/setter methods for navigation state
- [x] Add methods to save/restore navigation state

**Testing**: 
- [x] Verify state persists when switching tabs
- [x] Verify state resets appropriately for new briefings

#### **Step 1.2: Create System Navigation State**
**Status**: ✅ **COMPLETED**
**Goal**: Track current system page within AirportDetailScreen
**Files**: 
- `lib/screens/airport_detail_screen.dart`

**Changes**:
- [x] Add `_currentSystemIndex` state variable
- [x] Add system page list constant
- [x] Add system page switching logic

**Testing**: 
- [x] Verify system selection works without breaking existing navigation

---

### **Phase 2: AirportDetailScreen Refactoring** ⚡ **SAFE**

#### **Step 2.1: Add System Navigation Tabs**
**Status**: ✅ **COMPLETED**
**Goal**: Add secondary navigation within AirportDetailScreen
**Files**: 
- `lib/screens/airport_detail_screen.dart`

**Changes**:
- [x] Add TabBar for system selection (Overview, Runways, Taxiways, etc.)
- [x] Add TabController for system navigation
- [x] Style tabs to match app design

**Testing**: 
- [x] Verify tabs work and don't break existing functionality
- [x] Verify tab styling matches app design

#### **Step 2.2: Create System Page Widgets**
**Status**: ✅ **COMPLETED**
**Goal**: Convert system pages to widgets (not full screens)
**Files**: 
- Create `lib/widgets/system_pages/` directory
- Convert each system page to widget format

**Changes**:
- [x] Create `lib/widgets/system_pages/runway_system_widget.dart`
- [x] Create `lib/widgets/system_pages/taxiway_system_widget.dart`
- [x] Create `lib/widgets/system_pages/instrument_procedures_system_widget.dart`
- [x] Create `lib/widgets/system_pages/airport_services_system_widget.dart`
- [x] Create `lib/widgets/system_pages/hazards_system_widget.dart`
- [x] Create `lib/widgets/system_pages/admin_system_widget.dart`
- [x] Create `lib/widgets/system_pages/other_system_widget.dart`
- [x] Remove Scaffold/AppBar from all system widgets
- [x] Keep all existing functionality intact

**Testing**: 
- [x] Verify each system page renders correctly as widget
- [x] Verify all existing functionality works

#### **Step 2.3: Integrate System Widgets**
**Status**: ✅ **COMPLETED**
**Goal**: Add system widgets to AirportDetailScreen
**Files**: 
- `lib/screens/airport_detail_screen.dart`

**Changes**:
- [x] Add IndexedStack with system page widgets
- [x] Connect TabController to IndexedStack
- [x] Add system page switching logic
- [x] Reorder layout (tabs above airport selector)
- [x] Remove duplicate bottom navigation bar
- [x] Add static time filter between airport selector and content
- [x] Remove time filters from individual system widgets

**Testing**: 
- [x] Verify switching between systems works
- [x] Verify no performance issues
- [x] Verify layout order is correct
- [x] Verify single bottom navigation bar
- [x] Verify static time filter is always visible

---

### **Phase 3: Navigation Logic Implementation** ⚡ **SAFE**

#### **Step 3.1: Implement "Last Viewed" Logic**
**Status**: ✅ **COMPLETED**
**Goal**: Remember which system page user was viewing
**Files**: 
- `lib/providers/flight_provider.dart`
- `lib/screens/airport_detail_screen.dart`

**Changes**:
- [x] Save system page index when user switches tabs
- [x] Restore system page when returning to Airports tab
- [x] Handle edge cases (new briefing, no previous state)

**Testing**: 
- [x] Verify switching between main tabs preserves system selection
- [x] Verify new briefings start with Overview tab

#### **Step 3.2: Add Bottom Navigation to AirportDetailScreen**
**Status**: ⏳ **PENDING**
**Goal**: Include bottom nav in AirportDetailScreen
**Files**: 
- `lib/screens/airport_detail_screen.dart`

**Changes**:
- [ ] Add bottomNavigationBar property to Scaffold
- [ ] Copy BottomNavigationBar from BriefingTabsScreen
- [ ] Add navigation handlers for Summary/Raw Data tabs

**Testing**: 
- [ ] Verify bottom nav appears and works correctly
- [ ] Verify navigation between main tabs works from system pages

#### **Step 3.3: Implement Navigation Handlers**
**Status**: ⏳ **PENDING**
**Goal**: Handle bottom nav taps from system pages
**Files**: 
- `lib/screens/airport_detail_screen.dart`
- `lib/screens/briefing_tabs_screen.dart`

**Changes**:
- [ ] Add navigation logic for Summary/Raw Data tabs
- [ ] Save current system page before navigating
- [ ] Handle navigation back to Airports tab

**Testing**: 
- [ ] Verify navigation between main tabs works from system pages
- [ ] Verify system page state is preserved

---

### **Phase 4: Raw Data Integration** ⚡ **SAFE**

#### **Step 4.1: Add "Last Viewed" Logic to Raw Data**
**Status**: ⏳ **PENDING**
**Goal**: Remember which tab (NOTAMs/METARs/TAFs) user was viewing
**Files**: 
- `lib/providers/flight_provider.dart`
- `lib/screens/raw_data_screen.dart`

**Changes**:
- [ ] Save Raw Data tab index when user switches tabs
- [ ] Restore Raw Data tab when returning to Raw Data
- [ ] Handle default tab (NOTAMs) for new briefings

**Testing**: 
- [ ] Verify Raw Data tab selection persists
- [ ] Verify new briefings open to NOTAMs tab

#### **Step 4.2: Update Raw Data Navigation**
**Status**: ⏳ **PENDING**
**Goal**: Handle navigation from system pages to Raw Data
**Files**: 
- `lib/screens/raw_data_screen.dart`

**Changes**:
- [ ] Add logic to restore last viewed tab
- [ ] Handle navigation from system pages
- [ ] Preserve airport selection and time filter

**Testing**: 
- [ ] Verify Raw Data opens to correct tab
- [ ] Verify airport selection and time filter persist

---

### **Phase 5: Cleanup & Polish** ⚡ **SAFE**

#### **Step 5.1: Remove Old Navigation Code**
**Status**: ✅ **COMPLETED**
**Goal**: Clean up old Navigator.push() calls
**Files**: 
- `lib/screens/airport_detail_screen.dart`

**Changes**:
- [x] Remove old navigation logic
- [x] Remove unused imports
- [x] Clean up any dead code

**Testing**: 
- [x] Verify no broken navigation links
- [x] Verify no console errors

#### **Step 5.2: Update System Page Imports**
**Status**: ✅ **COMPLETED**
**Goal**: Update imports to use widget versions
**Files**: 
- All files that import system pages

**Changes**:
- [x] Update all system page imports
- [x] Remove unused imports
- [x] Verify no import errors

**Testing**: 
- [x] Verify no import errors
- [x] Verify app compiles successfully

#### **Step 5.3: Final Testing & Validation**
**Status**: ⏳ **PENDING**
**Goal**: Comprehensive testing of all navigation flows
**Files**: 
- All modified files

**Testing**: 
- [ ] Full user flow testing
- [ ] Performance testing
- [ ] Edge case testing
- [ ] Cross-platform testing

---

## 🚨 **Safety Measures**

### **Backup Strategy**
- [ ] Create backup branch before each phase
- [ ] Test each step before proceeding
- [ ] Keep old system pages as backup until fully tested

### **Rollback Plan**
- [ ] Each phase can be reverted independently
- [ ] Old navigation still works until Phase 5
- [ ] No breaking changes until final cleanup

### **Testing Checklist**
- [ ] Bottom nav visible on all pages
- [ ] System page selection persists
- [ ] Raw Data tab selection persists
- [ ] Airport selection persists
- [ ] Time filter persists
- [ ] Navigation between main tabs works
- [ ] No performance degradation
- [ ] No console errors
- [ ] No broken functionality

---

## 📊 **Implementation Timeline**

**Phase 1**: 1-2 hours (Foundation)
**Phase 2**: 2-3 hours (Refactoring)
**Phase 3**: 1-2 hours (Navigation Logic)
**Phase 4**: 1 hour (Raw Data)
**Phase 5**: 1 hour (Cleanup)

**Total**: 6-9 hours with safety breaks

---

## 🎯 **Success Criteria**

✅ Bottom navigation visible on ALL pages  
✅ System page selection persists across tab switches  
✅ Raw Data opens to last viewed tab  
✅ Airport selection persists across navigation  
✅ Time filter persists across navigation  
✅ No performance degradation  
✅ Clean, maintainable code  
✅ No breaking changes to existing functionality  

---

## 📝 **Notes**

- The current bottom navigation bar is already a Flutter `BottomNavigationBar` widget
- We don't need to create a custom widget, just reuse the existing one
- The main challenge is integrating it into the system pages
- Each phase is designed to be safe and reversible
- Testing is built into each step to catch issues early 