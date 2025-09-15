# Bug Fixes & Improvements Todo List

## STATUS: ACTIVE - READY FOR IMPLEMENTATION

### OVERVIEW
This document tracks all identified bugs and improvements across the Dispatch Buddy app. Items are organized by screen/feature area for systematic resolution.

---

## 🏠 HOME SCREEN

### Bug 1.1: Shrink Banner and Change Heading
**Priority**: MEDIUM | **Estimated Time**: 1 hour
**Status**: ✅ COMPLETED

**Description**: 
- Reduce banner size for better screen real estate
- Update heading text for clarity
- Redesigned banner with horizontal layout for better space utilization

**Files to Modify**:
- `lib/screens/home_screen.dart`

**Acceptance Criteria**:
- [x] Banner takes up less vertical space
- [x] Heading text is more concise and clear
- [x] Layout remains responsive on different screen sizes
- [x] Horizontal layout with logo on left, text on right
- [x] "Briefing Buddy" as main text, "Preflight Briefing Assistant" as byline
- [x] Removed redundant "Briefing Buddy" from app bar
- [x] More space available for content below banner

---

### Bug 1.2: Split Start New Briefing into Two Pathways
**Priority**: HIGH | **Estimated Time**: 3 hours
**Status**: ⏳ PENDING

**Description**: 
- Create separate buttons/options for:
  - Quick/Simple briefing (current flow)
  - Flight plan style briefing (upload PDF/input flight plan)

**Files to Modify**:
- `lib/screens/home_screen.dart`
- `lib/widgets/` (new briefing selection widget)

**Acceptance Criteria**:
- [ ] Two distinct briefing pathways clearly presented
- [ ] Quick briefing maintains current functionality
- [ ] Flight plan briefing integrates with existing PDF upload
- [ ] UI is intuitive and user-friendly

---

### Bug 1.3: Change Flag to Star on Previous Briefings
**Priority**: LOW | **Estimated Time**: 30 minutes
**Status**: ✅ COMPLETED

**Description**: 
- Replace flag icon with star icon to match radar screen styling
- Maintain same functionality (favorites/saved briefings)

**Files to Modify**:
- `lib/screens/home_screen.dart`
- `lib/widgets/` (previous briefing cards)

**Acceptance Criteria**:
- [x] Star icon replaces flag icon
- [x] Icon matches radar screen styling
- [x] Functionality remains unchanged
- [x] Both filled star (Icons.star) and outlined star (Icons.star_border) implemented
- [x] Consistent with radar screen star styling

---

### Bug 1.4: Add Airport Pill Should Add to Current Previous Briefing
**Priority**: MEDIUM | **Estimated Time**: 2 hours
**Status**: ✅ COMPLETED

**Description**: 
- When using "Add Airport" pill on Airports or Raw Data screens
- Should add airport to the current previous briefing for future reloads
- Currently only adds to current session
- **COMPLETED**: Airport addition now persists to previous briefings with full data

**Files to Modify**:
- `lib/screens/airport_detail_screen.dart`
- `lib/screens/raw_data_screen.dart`
- `lib/providers/flight_provider.dart`

**Acceptance Criteria**:
- [x] Add airport pill persists airport to saved briefing
- [x] Airport appears when briefing is reloaded
- [x] Works consistently across Airports and Raw Data screens
- [x] Weather and NOTAM data also persists for added airports
- [x] Uses versioned data storage system for proper persistence

---

## 📊 RAW DATA SCREEN

### Bug 2.1: Adding Airport on TAF Doesn't Fetch NOTAMs
**Priority**: HIGH | **Estimated Time**: 2 hours
**Status**: ✅ COMPLETED

**Description**: 
- When adding airport via TAF section, NOTAMs are not automatically fetched
- Should fetch both TAF and NOTAMs when adding new airport
- **COMPLETED**: Airport addition now fetches all data types (NOTAMs, weather, TAFs)

**Files to Modify**:
- `lib/screens/raw_data_screen.dart`
- `lib/providers/flight_provider.dart`

**Acceptance Criteria**:
- [x] Adding airport via TAF section fetches both TAF and NOTAMs
- [x] Behavior matches other airport addition methods
- [x] Loading states properly displayed
- [x] All data types (NOTAMs, METAR, TAFs) are fetched when adding airport
- [x] Consistent behavior across all airport addition methods

---

### Bug 2.2: NOTAM Group Expansion Needs Auto-Scroll
**Priority**: MEDIUM | **Estimated Time**: 1.5 hours
**Status**: ⏳ PENDING

**Description**: 
- When expanding bottom NOTAM group (usually "Other")
- Page should auto-scroll to show expanded NOTAMs
- Currently expanded content may be hidden below viewport

**Files to Modify**:
- `lib/screens/raw_data_screen.dart`
- `lib/widgets/notam_group_widget.dart`

**Acceptance Criteria**:
- [ ] Page scrolls to show expanded NOTAMs
- [ ] Smooth scrolling animation
- [ ] Works for all NOTAM groups, not just "Other"

---

### Bug 2.3: NOTAM Modal Valid Time Shows Both Z and UTC
**Priority**: LOW | **Estimated Time**: 30 minutes
**Status**: ✅ COMPLETED

**Description**: 
- NOTAM modal shows "03/09 03:01Z - 19/09 07:00Z UTC"
- Redundant display of both Z and UTC
- Should show only one format

**Files to Modify**:
- `lib/widgets/facilities_widget.dart`
- `lib/screens/raw_data_screen.dart`

**Acceptance Criteria**:
- [x] Remove redundant time format display
- [x] Show only "Z" format consistently (UTC removed)
- [x] Maintain time accuracy and readability

---

### Bug 2.4: Remove "Schedule" Word from NOTAM Modal
**Priority**: LOW | **Estimated Time**: 30 minutes
**Status**: ✅ COMPLETED

**Description**: 
- NOTAM modal shows "Schedule: MON-FRI 2100 TO 0700"
- Remove "Schedule:" word but keep the actual schedule times
- Should show "MON-FRI 2100 TO 0700" only

**Files to Modify**:
- `lib/widgets/facilities_widget.dart`
- `lib/screens/raw_data_screen.dart`

**Acceptance Criteria**:
- [x] "Schedule:" text removed
- [x] Schedule times still displayed clearly
- [x] Layout remains clean and readable
- [x] Clock icon removed for cleaner appearance

---

### Bug 2.5: Fix NOTAM F&G Incorrectly Showing
**Priority**: HIGH | **Estimated Time**: 2 hours
**Status**: ⏳ PENDING

**Description**: 
- NOTAMs incorrectly showing F&G (Fire and Ground) classification
- Example: YSRI runway NOTAM showing as F&G
- Should show correct NOTAM classification

**Files to Modify**:
- `lib/services/notam_classification_service.dart`
- `lib/models/notam.dart`

**Acceptance Criteria**:
- [ ] NOTAMs show correct classification
- [ ] Runway NOTAMs show as "RWY" not "F&G"
- [ ] Classification logic is accurate and reliable

---

### Bug 2.6: TAF Vertical Size - Keep Time Slider Visible
**Priority**: MEDIUM | **Estimated Time**: 2 hours
**Status**: ⏳ PENDING

**Description**: 
- TAF section vertical size needs adjustment
- Time slider should remain visible on smaller screens
- Consider locking time slider in position

**Files to Modify**:
- `lib/screens/raw_data_screen.dart`
- `lib/widgets/taf_widget.dart`

**Acceptance Criteria**:
- [ ] Time slider always visible on smaller screens
- [ ] TAF content doesn't push slider off screen
- [ ] Consider sticky/fixed slider position

---

### Bug 2.7: TAF Slider Time Position Not Covered by Thumb
**Priority**: MEDIUM | **Estimated Time**: 1.5 hours
**Status**: ⏳ PENDING

**Description**: 
- TAF time slider thumb covers the time display
- Move time display to position not covered by thumb
- Improve usability during sliding

**Files to Modify**:
- `lib/widgets/taf_widget.dart`

**Acceptance Criteria**:
- [ ] Time display visible during sliding
- [ ] Thumb doesn't cover time text
- [ ] Smooth sliding experience maintained

---

### Bug 2.8: TAF Color Differentiation for TEMPO Periods
**Priority**: MEDIUM | **Estimated Time**: 2 hours
**Status**: ⏳ PENDING

**Description**: 
- TAF needs additional color differentiation for separate TEMPO periods
- Multiple TEMPO periods active at same time need visual distinction
- Improve readability of overlapping periods

**Files to Modify**:
- `lib/widgets/taf_widget.dart`
- `lib/models/weather.dart`

**Acceptance Criteria**:
- [ ] Different colors for different TEMPO periods
- [ ] Clear visual distinction between overlapping periods
- [ ] Color scheme remains accessible and readable

---

## 🏢 AIRPORT FACILITIES

### Bug 3.1: Airport Pill "Add" Button Says "Coming Soon"
**Priority**: HIGH | **Estimated Time**: 1 hour
**Status**: ✅ COMPLETED

**Description**: 
- Airport pill "Add" button shows "Coming Soon"
- Should use same functionality as Raw Data add airport
- Enable actual airport addition functionality

**Files to Modify**:
- `lib/screens/airport_detail_screen.dart`
- `lib/widgets/airport_pill_widget.dart`

**Acceptance Criteria**:
- [x] "Add" button functional
- [x] Uses same logic as Raw Data screen
- [x] Airport addition works consistently
- [x] Edit airport functionality also implemented
- [x] Remove airport functionality also implemented
- [x] Full airport management capabilities available

---

### Bug 3.2: Airport Title Too Large
**Priority**: LOW | **Estimated Time**: 30 minutes
**Status**: ⏳ PENDING

**Description**: 
- Airport title text is unnecessarily large
- Reduce size for better screen utilization
- Maintain readability

**Files to Modify**:
- `lib/screens/airport_detail_screen.dart`

**Acceptance Criteria**:
- [ ] Airport title size reduced
- [ ] Text remains readable
- [ ] Layout looks more balanced

---

### Bug 3.3: Link NAVAID Tags to Show NOTAM
**Priority**: MEDIUM | **Estimated Time**: 2 hours
**Status**: ✅ COMPLETED

**Description**: 
- NAVAID "Limited" and "Unserviceable" tags should be clickable
- Tapping should show relevant NOTAM details
- Improve user experience for NOTAM access
- **ENHANCED**: Implemented two-stage filtering for precise NOTAM matching

**Files to Modify**:
- `lib/widgets/facilities_widget.dart`
- `lib/screens/airport_detail_screen.dart`

**Acceptance Criteria**:
- [x] NAVAID tags are clickable
- [x] Tapping shows relevant NOTAM modal
- [x] NOTAM information is accurate and complete
- [x] Two-stage filtering prevents false positives
- [x] Precise matching for specific NAVAID systems

---

### Bug 3.4: Change "Unserviceable" to "U/S"
**Priority**: LOW | **Estimated Time**: 15 minutes
**Status**: ✅ COMPLETED

**Description**: 
- Change "Unserviceable" tag text to "U/S"
- More concise display
- Standard aviation abbreviation

**Files to Modify**:
- `lib/widgets/facilities_widget.dart`

**Acceptance Criteria**:
- [x] "Unserviceable" changed to "U/S"
- [x] All instances updated consistently
- [x] Meaning remains clear

---

### Bug 3.5: Add First/Last Light
**Priority**: MEDIUM | **Estimated Time**: 1.5 hours
**Status**: ⏳ PENDING

**Description**: 
- Add first light and last light information to airport facilities
- Important for flight planning and operations
- Display sunrise/sunset times

**Files to Modify**:
- `lib/widgets/facilities_widget.dart`
- `lib/models/airport.dart`
- `lib/services/` (new service for sunrise/sunset)

**Acceptance Criteria**:
- [ ] First light time displayed
- [ ] Last light time displayed
- [ ] Times are accurate for airport location
- [ ] Times update based on date

---

### Bug 3.6: Implement Two-Stage Filtering for Runways and Lighting
**Priority**: HIGH | **Estimated Time**: 3 hours
**Status**: ✅ COMPLETED

**Description**: 
- Apply the same precise two-stage filtering approach used for NAVAIDs to runways and lighting
- Prevent false positives where runway status shows from unrelated NOTAMs
- Improve accuracy of facility status display
- Ensure only relevant NOTAMs are linked to specific facilities

**Files to Modify**:
- `lib/widgets/facilities_widget.dart`

**Acceptance Criteria**:
- [x] Two-stage filtering implemented for runways
- [x] Two-stage filtering implemented for lighting
- [x] Runway status only shows from relevant runway NOTAMs
- [x] Lighting status only shows from relevant lighting NOTAMs
- [x] Debug logging added for transparency
- [x] Handles dual runways (e.g., "16L/34R")
- [x] Supports various NOTAM text formats
- [x] Consistent approach with NAVAID filtering

---

## 📋 CHARTS

### Bug 4.1: Fix Pinch Zoom vs Swipe Conflict
**Priority**: HIGH | **Estimated Time**: 3 hours
**Status**: ⏳ PENDING

**Description**: 
- Pinch zoom gesture conflicts with swipe to next chart
- Need to distinguish between zoom and swipe gestures
- Improve chart navigation experience

**Files to Modify**:
- `lib/screens/charts_screen.dart`
- `lib/widgets/chart_viewer_widget.dart`

**Acceptance Criteria**:
- [ ] Pinch zoom works without triggering swipe
- [ ] Swipe navigation works without interfering with zoom
- [ ] Gesture recognition is accurate and responsive

---

### Bug 4.2: Charts List Validity Time Colors
**Priority**: MEDIUM | **Estimated Time**: 1.5 hours
**Status**: ⏳ PENDING

**Description**: 
- Charts list validity time colors need fixing
- Charts of same validity should be clearly identifiable
- Improve visual organization

**Files to Modify**:
- `lib/screens/charts_screen.dart`
- `lib/widgets/chart_list_widget.dart`

**Acceptance Criteria**:
- [ ] Validity time colors are distinct and clear
- [ ] Same validity charts are easily identifiable
- [ ] Color scheme is consistent and logical

---

### Bug 4.3: SIGMET Validity Period Shows 6hr Instead of 3hr
**Priority**: MEDIUM | **Estimated Time**: 1 hour
**Status**: ⏳ PENDING

**Description**: 
- SIGMET validity period incorrectly shows 6 hours
- Should show 3 hour length
- Fix calculation or display logic

**Files to Modify**:
- `lib/services/sigmet_service.dart`
- `lib/models/sigmet.dart`

**Acceptance Criteria**:
- [ ] SIGMET validity shows 3 hours
- [ ] Calculation is accurate
- [ ] Display is consistent across all SIGMETs

---

## ⚙️ SETTINGS

### Bug 5.1: Build Out Dark Mode Functionality
**Priority**: MEDIUM | **Estimated Time**: 4 hours
**Status**: ⏳ PENDING

**Description**: 
- Implement full dark mode functionality
- Apply dark theme across all screens
- Ensure proper contrast and readability

**Files to Modify**:
- `lib/providers/settings_provider.dart`
- `lib/main.dart`
- All screen files (theme application)

**Acceptance Criteria**:
- [ ] Dark mode toggle works
- [ ] All screens support dark mode
- [ ] Proper contrast maintained
- [ ] Theme persists across app restarts

---

### Bug 5.2: Build Out Font Size Functionality
**Priority**: MEDIUM | **Estimated Time**: 3 hours
**Status**: ⏳ PENDING

**Description**: 
- Implement font size adjustment functionality
- Allow users to increase/decrease text size
- Apply across all screens consistently

**Files to Modify**:
- `lib/providers/settings_provider.dart`
- `lib/main.dart`
- All screen files (font size application)

**Acceptance Criteria**:
- [ ] Font size controls work
- [ ] Text scales appropriately
- [ ] Layout remains functional at all sizes
- [ ] Settings persist across app restarts

---

### Bug 5.3: Consider Pre-loaded NAIPS Logins
**Priority**: LOW | **Estimated Time**: 8 hours
**Status**: ⏳ PENDING

**Description**: 
- Consider loading with ~10 NAIPS logins
- Abstract need for users to input credentials
- Build random rotating login system
- Different browser simulation for each login

**Files to Modify**:
- `lib/services/naips_service.dart`
- `lib/providers/settings_provider.dart`
- New service for login rotation

**Acceptance Criteria**:
- [ ] Multiple NAIPS logins available
- [ ] Random rotation system works
- [ ] Browser simulation prevents detection
- [ ] System is reliable and maintainable

---

## 🌦️ WEATHER RADAR

### Bug 7.1: Add Loading Delay to Prevent Juttering
**Priority**: MEDIUM | **Estimated Time**: 1 hour
**Status**: ✅ COMPLETED

**Description**: 
- Add loading delay to prevent juttering as radar images load
- Improve smoothness of image transitions
- Better user experience during image loading

**Files to Modify**:
- `lib/screens/weather_radar_screen.dart`
- `lib/providers/weather_radar_provider.dart`

**Acceptance Criteria**:
- [x] Loading delay prevents juttering
- [x] Image transitions are smooth
- [x] Loading states are properly managed
- [x] Performance remains good

---

### Bug 7.2: Reorder Layers for Scale and Names Visibility
**Priority**: MEDIUM | **Estimated Time**: 1.5 hours
**Status**: ✅ COMPLETED

**Description**: 
- Reorder radar layers so scale and location names are visible above weather layer
- Currently scale and names may be hidden behind weather data
- Improve readability of radar information

**Files to Modify**:
- `lib/screens/weather_radar_screen.dart`
- `lib/providers/weather_radar_provider.dart`
- `lib/widgets/radar_layer_widget.dart`

**Acceptance Criteria**:
- [x] Scale is always visible above weather layer
- [x] Location names are always visible above weather layer
- [x] Layer ordering is logical and functional
- [x] Weather data doesn't obscure important information

---

## 📊 RAW DATA SCREEN (Additional)

### Bug 2.9: Consider Switching Tab Order
**Priority**: LOW | **Estimated Time**: 30 minutes
**Status**: ⏳ PENDING

**Description**: 
- Consider switching order of NOTAMs, METAR/ATIS, TAFs tabs
- Current order may not be most useful for users
- Evaluate optimal information hierarchy

**Files to Modify**:
- `lib/screens/raw_data_screen.dart`
- `lib/widgets/state_tab_selector.dart`

**Acceptance Criteria**:
- [ ] Tab order optimized for user workflow
- [ ] Most important information easily accessible
- [ ] Order makes logical sense for briefing flow

---

## 🍔 DRAWER MENU

### Bug 8.1: Remove Menu Heading
**Priority**: LOW | **Estimated Time**: 15 minutes
**Status**: ⏳ PENDING

**Description**: 
- Remove "Menu" heading from drawer menu
- Clean up unnecessary text
- Improve visual simplicity

**Files to Modify**:
- `lib/screens/home_screen.dart` (drawer implementation)
- `lib/widgets/` (drawer widget if separate)

**Acceptance Criteria**:
- [ ] "Menu" heading removed
- [ ] Drawer looks cleaner
- [ ] Functionality remains unchanged

---

## 📱 APP BAR

### Bug 9.1: Consider Adding Logo
**Priority**: LOW | **Estimated Time**: 1 hour
**Status**: ⏳ PENDING

**Description**: 
- Consider adding Dispatch Buddy logo to app bar
- Improve brand recognition
- Enhance visual identity

**Files to Modify**:
- `lib/main.dart` (app bar theme)
- All screen files with app bars
- `assets/images/logo.png`

**Acceptance Criteria**:
- [ ] Logo added to app bar
- [ ] Logo is appropriately sized
- [ ] Logo works across all screens
- [ ] Brand consistency maintained

---

## 🎨 APP ICON

### Bug 10.1: Zoom Out Slightly to Prevent Cropping
**Priority**: MEDIUM | **Estimated Time**: 1 hour
**Status**: ⏳ PENDING

**Description**: 
- Zoom out app icon slightly so image is not cropped on edges
- Ensure full logo/icon is visible
- Improve icon appearance on home screen

**Files to Modify**:
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- `android/app/src/main/res/` (various mipmap folders)
- `assets/images/logo.png` (source image)

**Acceptance Criteria**:
- [ ] App icon shows complete image without cropping
- [ ] Icon looks good at all sizes
- [ ] No important elements are cut off
- [ ] Icon maintains visual quality

---

## 📝 SUMMARY

### Bug 6.1: Link AI Briefing from Drawer Menu
**Priority**: MEDIUM | **Estimated Time**: 2 hours
**Status**: ⏳ PENDING

**Description**: 
- Link AI briefing from drawer menu into Summary screen
- Enable Foundational Model integration
- Improve access to AI briefing features

**Files to Modify**:
- `lib/screens/summary_screen.dart`
- `lib/screens/ai_briefing_screen.dart`
- `lib/providers/ai_briefing_provider.dart`

**Acceptance Criteria**:
- [ ] AI briefing accessible from Summary screen
- [ ] Foundational Model integration works
- [ ] Navigation is intuitive and smooth

---

## ⏱️ AIRPORT ADDITION UX

### Bug 11.1: Improve Airport Addition Loading UX
**Priority**: HIGH | **Estimated Time**: 1 hour
**Status**: ✅ COMPLETED

**Description**: 
- Airport addition takes 30+ seconds with no visual feedback
- Blocking popup for 30+ seconds is annoying rather than helpful
- Need inline loading states that don't block user interaction

**Files to Modify**:
- `lib/screens/airport_detail_screen.dart`
- `lib/screens/raw_data_screen.dart`
- `lib/providers/flight_provider.dart`

**Acceptance Criteria**:
- [x] Simple dialog closes immediately after "Add" button pressed
- [x] Raw Data screen shows inline loading states in tabs during airport addition
- [x] Users can still navigate and use other parts of the app
- [x] Loading indicators show which sections are being updated
- [x] Clear indication that process may take 30+ seconds
- [x] Added airports are persisted to previous briefings
- [x] Consistent experience across Airport Facilities and Raw Data screens

**Implementation Details**:
- [x] Reverted blocking popup approach
- [x] Implemented inline loading states using `flightProvider.isLoading`
- [x] Added `_buildLoadingTab()` method for consistent loading UI
- [x] Loading states show specific messages per tab:
  - NOTAMs: "Fetching NOTAMs and airport data..."
  - METAR/ATIS: "Fetching METAR and ATIS data..."
  - TAFs: "Fetching TAF data..."
- [x] Added `await saveCurrentFlight()` to all airport management methods
- [x] Ensured airport changes persist to previous briefings
- [x] Non-blocking UX allows continued app usage during loading

---

### Bug 11.2: Fix Weather and NOTAM Data Persistence for Added Airports
**Priority**: HIGH | **Estimated Time**: 2 hours
**Status**: ✅ COMPLETED

**Description**: 
- Added airports persist in previous briefings but their weather and NOTAM data doesn't
- When switching between briefings, the airport is there but data is missing
- Data format inconsistency between sequential keys and versioned data system

**Files to Modify**:
- `lib/providers/flight_provider.dart`
- `lib/services/briefing_storage_service.dart`

**Acceptance Criteria**:
- [x] Weather data persists when switching between briefings
- [x] NOTAM data persists when switching between briefings
- [x] Data format consistent with versioned data system
- [x] Uses proper NOTAM ID keys instead of sequential numbering
- [x] Uses proper TYPE_ICAO format for weather keys
- [x] Creates new versioned data for updated briefings
- [x] Debug logging shows data persistence process

**Implementation Details**:
- [x] Fixed data format inconsistency between sequential and versioned formats
- [x] Updated NOTAM storage to use `notam.id` as key (e.g., "F2984/25")
- [x] Updated weather storage to use `"${type}_${icao}"` format (e.g., "METAR_YBBN")
- [x] Implemented versioned data storage using `BriefingStorageService.createNewVersion()`
- [x] Added comprehensive debug logging for data persistence tracking
- [x] Ensured consistency with `BriefingConversionService` format
- [x] Both add and remove airport operations now use versioned data system

---

## 📊 PRIORITY SUMMARY

### HIGH PRIORITY (Fix First)
1. **Bug 1.2**: Split Start New Briefing into Two Pathways
2. **Bug 2.1**: Adding Airport on TAF Doesn't Fetch NOTAMs ✅
3. **Bug 2.5**: Fix NOTAM F&G Incorrectly Showing
4. **Bug 3.1**: Airport Pill "Add" Button Says "Coming Soon" ✅
5. **Bug 3.6**: Implement Two-Stage Filtering for Runways and Lighting ✅
6. **Bug 4.1**: Fix Pinch Zoom vs Swipe Conflict
7. **Bug 11.1**: Add Loading Indicator for Airport Addition Process ✅
8. **Bug 11.2**: Fix Weather and NOTAM Data Persistence for Added Airports ✅

### MEDIUM PRIORITY (Fix Second)
1. **Bug 1.4**: Add Airport Pill Should Add to Current Previous Briefing ✅
2. **Bug 2.2**: NOTAM Group Expansion Needs Auto-Scroll
3. **Bug 2.6**: TAF Vertical Size - Keep Time Slider Visible
4. **Bug 2.7**: TAF Slider Time Position Not Covered by Thumb
5. **Bug 2.8**: TAF Color Differentiation for TEMPO Periods
6. **Bug 3.3**: Link NAVAID Tags to Show NOTAM
7. **Bug 3.5**: Add First/Last Light
8. **Bug 4.2**: Charts List Validity Time Colors
9. **Bug 4.3**: SIGMET Validity Period Shows 6hr Instead of 3hr
10. **Bug 5.1**: Build Out Dark Mode Functionality
11. **Bug 5.2**: Build Out Font Size Functionality
12. **Bug 6.1**: Link AI Briefing from Drawer Menu
13. **Bug 7.1**: Add Loading Delay to Prevent Juttering (Weather Radar)
14. **Bug 7.2**: Reorder Layers for Scale and Names Visibility (Weather Radar)
15. **Bug 10.1**: Zoom Out App Icon Slightly to Prevent Cropping

### LOW PRIORITY (Fix Last)
1. **Bug 1.1**: Shrink Banner and Change Heading ✅
2. **Bug 1.3**: Change Flag to Star on Previous Briefings ✅
3. **Bug 2.3**: NOTAM Modal Valid Time Shows Both Z and UTC ✅
4. **Bug 2.4**: Remove "Schedule" Word from NOTAM Modal ✅
5. **Bug 2.9**: Consider Switching Tab Order (Raw Data)
6. **Bug 3.2**: Airport Title Too Large
7. **Bug 3.4**: Change "Unserviceable" to "U/S"
8. **Bug 5.3**: Consider Pre-loaded NAIPS Logins
9. **Bug 8.1**: Remove Menu Heading (Drawer Menu)
10. **Bug 9.1**: Consider Adding Logo (App Bar)

---

## 🎯 IMPLEMENTATION STRATEGY

### Phase 1: Critical Functionality (Week 1)
- Fix high priority bugs that affect core functionality
- Focus on airport addition and NOTAM display issues

### Phase 2: User Experience (Week 2)
- Address medium priority UI/UX improvements
- Implement dark mode and font size controls

### Phase 3: Polish & Enhancement (Week 3)
- Fix low priority items
- Implement advanced features like pre-loaded logins

---

## 📝 NOTES

- Each bug includes estimated time for planning
- Acceptance criteria ensure clear completion standards
- Priority levels help focus on most impactful fixes first
- Consider user impact when prioritizing fixes
- Test each fix thoroughly before moving to next item

---

*This document should be updated as bugs are fixed and new issues are discovered. Use checkboxes to track progress and add completion dates when items are resolved.*
