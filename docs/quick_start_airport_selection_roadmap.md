# Quick Start Airport Selection Feature Roadmap

## Overview
This document outlines the implementation plan for the Quick Start Airport Selection feature, which replaces the static sample buttons with a dynamic airport selection modal that allows users to select airports from their usage history and by Australian state.

## Current Understanding
- ✅ Replace sample buttons with "Select Airports" button
- ✅ Bottom sheet modal (like radar location selector)
- ✅ Loading state until data is ready
- ✅ ICAO codes only on pills
- ✅ Persist selections until briefing generated
- ✅ Clear area for up to 10 selected airports
- ✅ Load ICAO data upfront, other data as needed

---

## Phase 1: Data Foundation & Airport Tracking
**Priority**: High | **Estimated Time**: 2-3 hours

### 1.1 Create Airport Usage Tracking Service
**File**: `lib/services/airport_usage_tracker.dart`

**Purpose**: Analyze briefing history to determine most frequently used airports

**Features**:
- Analyze `Briefing.airports` from `BriefingStorageService.loadAllBriefings()`
- Count airport usage frequency across all briefings
- Return top 10 most used airports (or fallback to major airports)
- Handle edge cases (no history, insufficient data)
- Cache results for performance

**Implementation**:
```dart
class AirportUsageTracker {
  static Future<List<String>> getMostUsedAirports({int limit = 10}) async {
    // Load all briefings
    // Count airport frequency
    // Return top N airports
    // Fallback to major Australian airports if no history
  }
  
  static Future<Map<String, int>> getAirportUsageCounts() async {
    // Return detailed usage counts for debugging
  }
}
```

### 1.2 Create Australian Airport State Mapping
**File**: `lib/data/australian_airport_states.dart`

**Purpose**: Map Australian airports to their states/territories for filtering

**Features**:
- Map each ICAO to state (NSW, VIC, QLD, WA, SA, TAS, NT, ACT)
- Group airports by state in alphabetical order
- Include all airports from `AustralianAirportDatabase.initialAirports`
- Add major regional airports for better coverage
- Provide state-to-airports lookup

**Implementation**:
```dart
class AustralianAirportStates {
  static const Map<String, String> airportToState = {
    'YSSY': 'NSW',
    'YMML': 'VIC',
    'YBBN': 'QLD',
    'YPPH': 'WA',
    // ... complete mapping
  };
  
  static Map<String, List<String>> get airportsByState {
    // Group airports by state, sorted alphabetically
  }
  
  static List<String> get allStates => ['NSW', 'VIC', 'QLD', 'WA', 'SA', 'TAS', 'NT', 'ACT'];
}
```

---

## Phase 2: Modal UI Components
**Priority**: High | **Estimated Time**: 3-4 hours

### 2.1 Create Airport Selection Modal
**File**: `lib/widgets/airport_selection_modal.dart`

**Purpose**: Main modal for airport selection using existing patterns

**Design Pattern**: Follow `_LocationSelectorSheet` from `weather_radar_screen.dart`

**Features**:
- Bottom sheet with drag handle (reuse existing styling)
- Three sections: Selected Airports, Common Airports, State Tabs
- State management for selected airports (max 10)
- Clear all functionality
- Generate button (disabled when no selection)
- Loading state while data loads

**UI Structure**:
```
┌─────────────────────────────────┐
│ ─── (drag handle)               │
│ Select Airports                 │
│                                 │
│ Selected (0/10):                │
│ [Empty area for selected pills] │
│                                 │
│ Commonly Used:                  │
│ [Grid of 10 airport pills]      │
│                                 │
│ [NSW] [VIC] [QLD] [WA] [SA]...  │
│ [Grid of state airports]        │
│                                 │
│ [Clear All] [Generate Briefing] │
└─────────────────────────────────┘
```

### 2.2 Create Airport Pill Widget
**File**: `lib/widgets/airport_pill_widget.dart`

**Purpose**: Reusable airport selection pill using existing styling

**Design Pattern**: Follow `_buildAirportBubble` from `TafAirportSelector`

**Features**:
- ICAO code display only
- Selected/unselected states (orange/grey like TAF selector)
- Tap to toggle selection
- Consistent styling with existing pills
- Visual feedback for selection
- Disabled state when limit reached

**Styling**:
```dart
// Selected state (orange)
color: const Color(0xFFF97316)
textColor: Colors.white
fontWeight: FontWeight.bold

// Unselected state (grey)
color: Colors.grey[700]!
textColor: Colors.white70
fontWeight: FontWeight.normal
```

### 2.3 Create State Tab Selector
**File**: `lib/widgets/state_tab_selector.dart`

**Purpose**: Horizontal state selection tabs using existing patterns

**Design Pattern**: Follow `TabBar` from `weather_radar_screen.dart` and `airport_detail_screen.dart`

**Features**:
- Tab-style navigation (NSW, VIC, QLD, WA, SA, TAS, NT, ACT)
- Active state highlighting (blue indicator)
- Smooth scrolling for overflow
- Consistent with existing tab styling
- No scroll physics (like radar selector)

**Styling**:
```dart
labelColor: const Color(0xFF1E3A8A)
indicatorColor: const Color(0xFF1E3A8A)
indicatorWeight: 3
fontSize: 14
```

---

## Phase 3: Integration & Logic
**Priority**: High | **Estimated Time**: 2-3 hours

### 3.1 Update Quick Start Card
**File**: `lib/widgets/quick_start_card.dart`

**Changes**:
- Remove sample buttons (`YPPH → YSSY`, `YMML → YBBN`)
- Add "Select Airports" button using existing button styling
- Open airport selection modal
- Handle modal results and navigation

**Button Styling**: Follow existing `ElevatedButton` patterns from the app

### 3.2 Create Airport Selection Logic
**File**: `lib/services/airport_selection_service.dart`

**Purpose**: Handle airport selection business logic

**Features**:
- Validate airport selections (max 10)
- Format selected airports for briefing generation
- Integration with existing briefing generation flow
- State management for selections
- Clear all functionality

**Integration Points**:
- `FlightProvider.generateBriefing()` for actual briefing generation
- `BriefingStorageService` for saving results
- Navigation to briefing results

### 3.3 Update Input Screen Integration
**File**: `lib/screens/input_screen.dart`

**Changes**:
- Integrate with airport selection modal
- Handle modal close and navigation
- Trigger briefing generation from modal
- Maintain existing route input functionality (parallel path)
- Navigate to appropriate screen after generation

**Navigation Flow**:
1. User taps "Select Airports" → Opens modal
2. User selects airports → Updates selection state
3. User taps "Generate Briefing" → Closes modal → Generates briefing → Navigates to results

---

## Phase 4: Polish & Testing
**Priority**: Medium | **Estimated Time**: 1-2 hours

### 4.1 UI/UX Polish
**Features**:
- Smooth animations for selection (follow existing patterns)
- Loading states for data fetching
- Error handling for edge cases
- Responsive design for different screen sizes
- Accessibility improvements
- Consistent spacing and typography

### 4.2 Testing & Validation
**Features**:
- Test with no briefing history (fallback to major airports)
- Test with extensive briefing history (top 10 selection)
- Test state filtering functionality
- Test selection limits and validation
- Test modal close and navigation
- Test integration with existing briefing flow

---

## Technical Architecture

### Data Flow
1. **Quick Start Card** → Opens **Airport Selection Modal**
2. **Modal** loads **Common Airports** (from usage tracker) + **State Tabs**
3. **User selects airports** → Updates selection state (max 10)
4. **Generate button** → Triggers briefing generation → Closes modal → Navigates to briefing

### Key Components
- `AirportUsageTracker` - Analyzes briefing history
- `AirportSelectionModal` - Main UI component (bottom sheet)
- `AirportPillWidget` - Individual airport pills (reuse TAF styling)
- `StateTabSelector` - State filtering tabs (reuse radar styling)
- `AirportSelectionService` - Business logic

### State Management
- Selected airports list (max 10)
- Current state filter
- Loading states for data fetching
- Modal open/close state

### Reused Patterns
- **Bottom Sheet**: `showModalBottomSheet` + `DraggableScrollableSheet` (from radar selector)
- **Pill Styling**: `_buildAirportBubble` colors and styling (from TAF selector)
- **Tab Styling**: `TabBar` configuration (from radar and airport detail screens)
- **Button Styling**: `ElevatedButton` patterns (from existing screens)
- **Loading States**: Follow existing loading patterns

---

## Implementation Order

### Step 1: Data Foundation (Phase 1)
1. Create `AirportUsageTracker` service
2. Create `AustralianAirportStates` data mapping
3. Test data loading and fallback scenarios

### Step 2: Core Components (Phase 2)
1. Create `AirportPillWidget` (reuse TAF styling)
2. Create `StateTabSelector` (reuse radar tab styling)
3. Create `AirportSelectionModal` (reuse radar bottom sheet pattern)

### Step 3: Integration (Phase 3)
1. Update `QuickStartCard` to remove samples and add modal trigger
2. Create `AirportSelectionService` for business logic
3. Update `InputScreen` integration

### Step 4: Polish (Phase 4)
1. Add loading states and error handling
2. Test all scenarios and edge cases
3. UI/UX refinements

---

## Success Criteria
- ✅ Modal opens smoothly with loading state
- ✅ Common airports load from briefing history (or fallback)
- ✅ State tabs filter airports correctly
- ✅ Airport pills select/deselect with visual feedback
- ✅ 10 airport limit enforced
- ✅ Clear all functionality works
- ✅ Generate button triggers briefing generation
- ✅ Modal closes and navigates to results
- ✅ Consistent styling with existing app patterns
- ✅ Handles edge cases (no history, network issues)

---

## Future Enhancements (Not in Scope)
- Manual favorites management
- International airport support
- Airport search functionality
- Recent selections (separate from commonly used)
- Airport details in pills (names, cities)
- Custom airport lists
- Integration with route input field

---

## Files to Create
- `lib/services/airport_usage_tracker.dart`
- `lib/data/australian_airport_states.dart`
- `lib/widgets/airport_selection_modal.dart`
- `lib/widgets/airport_pill_widget.dart`
- `lib/widgets/state_tab_selector.dart`
- `lib/services/airport_selection_service.dart`

## Files to Modify
- `lib/widgets/quick_start_card.dart`
- `lib/screens/input_screen.dart`

## Dependencies
- Existing `BriefingStorageService` for history analysis
- Existing `AustralianAirportDatabase` for airport data
- Existing `FlightProvider` for briefing generation
- Existing UI patterns and styling
