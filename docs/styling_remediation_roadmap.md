# Styling Remediation Roadmap
## Apple UI Guidelines Compliance

### Overview
This document outlines the comprehensive remediation plan to bring Briefing Buddy into full compliance with Apple's Human Interface Guidelines. The audit identified several areas where the app's styling and interaction patterns need improvement to meet iOS standards.

**📱 iOS 26 Design Resources**: Sketch and Figma screenshots have been provided and need detailed analysis for exact specifications.

---

## Priority 1: Critical Visual Issues

### 1.1 Color Scheme Standardization
**Status**: 🔴 High Priority  
**Impact**: Core visual identity and accessibility

#### Tasks:
- [ ] **Extract iOS 26 color values from screenshots**
  - Get exact hex codes for primary blue from button components
  - Extract background colors for light and dark modes
  - Identify text color hierarchy (primary, secondary, tertiary)
  - Document semantic colors (red, green, orange) for different states
  - Extract border and separator colors

- [ ] **Replace custom blue theme with iOS system colors**
  - Replace `#2196F3` with exact iOS 26 blue from screenshots
  - Replace `#1976D2` with iOS 26 blue variant
  - Replace `#0D47A1` with iOS 26 blue dark
  - Update all custom blue instances in weather colors and UI elements

- [ ] **Implement proper iOS color semantics**
  - Use exact iOS 26 system colors from screenshots
  - Use `Colors.systemBlue` for primary actions
  - Use `Colors.systemGreen` for success states
  - Use `Colors.systemRed` for errors/warnings
  - Use `Colors.systemOrange` for caution states
  - Use `Colors.systemGray` for secondary text

- [ ] **Add dark mode support**
  - Implement `ThemeData.dark()` variant using exact colors from screenshots
  - Test all screens in both light and dark modes
  - Ensure proper contrast ratios (4.5:1 minimum)

#### Files to Update:
- `lib/constants/weather_colors.dart`
- All screen files with custom color usage
- Theme configuration in `main.dart`

---

### 1.2 Typography System
**Status**: 🔴 High Priority  
**Impact**: Readability and visual hierarchy

#### Tasks:
- [ ] **Extract iOS 26 typography specifications from screenshots**
  - Get exact font sizes for different text styles (large title, title1, body, caption)
  - Extract font weight values (regular, medium, semibold, bold)
  - Document letter spacing values for each text style
  - Identify line height specifications

- [ ] **Implement iOS typography scale**
  - Replace custom font sizes with exact iOS 26 sizes from screenshots
  - Use SF Pro Display for headings with exact specifications
  - Use SF Pro Text for body text with exact specifications
  - Use SF Pro Text for captions with exact specifications

- [ ] **Standardize text styles**
  - Create consistent `TextStyle` definitions using exact specs
  - Implement proper font weights from screenshots
  - Ensure proper line heights and letter spacing from screenshots

- [ ] **Fix text contrast issues**
  - Ensure all text meets WCAG AA contrast standards
  - Test with accessibility features enabled

#### Files to Update:
- All screen files with custom `TextStyle` usage
- Create `lib/constants/typography.dart`

---

## Priority 2: Interactive Elements

### 2.1 Button Standardization
**Status**: 🟡 Medium Priority  
**Impact**: User interaction consistency

#### Tasks:
- [ ] **Extract iOS 26 button specifications from screenshots**
  - Get exact corner radius values for buttons
  - Extract padding and margin specifications
  - Document button states (normal, pressed, disabled)
  - Identify exact touch target sizes

- [ ] **Replace custom buttons with iOS-style buttons**
  - Use exact iOS 26 button styling from screenshots
  - Implement proper button sizes from specifications
  - Add proper button states using exact colors and styling
  - Use system button colors and typography from screenshots

- [ ] **Standardize button hierarchy**
  - Primary actions: Use exact iOS 26 primary button styling
  - Secondary actions: Use exact iOS 26 secondary button styling
  - Destructive actions: Use exact iOS 26 red button styling
  - Disabled state: Use exact iOS 26 disabled styling

#### Files to Update:
- `lib/widgets/flight_plan_form_card.dart`
- `lib/widgets/quick_start_card.dart`
- All screen files with custom button styling

---

### 2.2 Card Design System
**Status**: 🟡 Medium Priority  
**Impact**: Visual consistency and information hierarchy

#### Tasks:
- [ ] **Extract iOS 26 card specifications from screenshots**
  - Get exact corner radius values for cards
  - Extract shadow specifications (blur, offset, color)
  - Document padding and margin values
  - Identify card states (normal, pressed, selected)

- [ ] **Implement iOS-style cards**
  - Use exact iOS 26 card styling from screenshots
  - Add exact shadow values from specifications
  - Use exact padding values from screenshots
  - Implement proper card states using exact colors

- [ ] **Standardize card content layout**
  - Consistent header styling using exact specs
  - Proper content spacing from screenshots
  - Standardized action buttons using exact styling
  - Proper touch targets from specifications

#### Files to Update:
- `lib/widgets/decoded_weather_card.dart`
- `lib/widgets/flight_plan_form_card.dart`
- `lib/widgets/quick_start_card.dart`
- `lib/widgets/raw_taf_card.dart`
- `lib/widgets/taf_period_card.dart`

---

### 2.3 Navigation Patterns
**Status**: 🟡 Medium Priority  
**Impact**: User experience and app flow

#### Tasks:
- [ ] **Extract iOS 26 navigation specifications from screenshots**
  - Get exact navigation bar styling
  - Extract toolbar specifications (top and bottom)
  - Document search bar styling and behavior
  - Identify exact icon specifications

- [ ] **Implement proper iOS navigation**
  - Use exact iOS 26 navigation styling from screenshots
  - Replace `AppBar` with exact iOS 26 navigation bar
  - Use exact iOS 26 page transitions from specifications
  - Implement proper back button behavior using exact styling

- [ ] **Standardize navigation elements**
  - Use exact system navigation bar styling from screenshots
  - Implement exact title styling from specifications
  - Add exact navigation bar buttons from screenshots
  - Use exact system back button icon

#### Files to Update:
- `lib/main.dart`
- All screen files with custom navigation bars

---

## Priority 3: Layout and Spacing

### 3.1 Spacing System
**Status**: 🟡 Medium Priority  
**Impact**: Visual consistency and readability

#### Tasks:
- [ ] **Extract iOS 26 spacing specifications from screenshots**
  - Get exact spacing values for all components
  - Extract margin and padding specifications
  - Document component spacing values
  - Identify safe area specifications

- [ ] **Implement iOS spacing scale**
  - Use exact iOS 26 spacing values from screenshots
  - Standardize margins and padding using exact specs
  - Implement exact component spacing from screenshots
  - Use exact safe area specifications

- [x] **Fix layout issues** ✅ COMPLETED
  - ✅ Fixed NOTAM modal spacing consistency across all display methods
  - ✅ Removed unnecessary spacing between validity and text sections
  - ✅ Aligned facilities modal with raw data modal appearance
  - ✅ Ensured consistent spacing in swipe view NOTAM cards
  - [ ] Ensure exact content margins from screenshots
  - [ ] Implement exact section spacing from specifications
  - [ ] Fix overlapping elements using exact spacing
  - [ ] Ensure exact list item spacing from screenshots

#### Files to Update:
- ✅ `lib/widgets/facilities_widget.dart` - Fixed NOTAM modal spacing consistency
- All screen files with custom spacing
- Create `lib/constants/spacing.dart`

---

### 3.2 List and Grid Layouts
**Status**: 🟡 Medium Priority  
**Impact**: Information presentation and scanning

#### Tasks:
- [ ] **Extract iOS 26 list specifications from screenshots**
  - Get exact list item heights from screenshots
  - Extract list item styling specifications
  - Document separator specifications
  - Identify exact typography for list items

- [ ] **Standardize list designs**
  - Use exact iOS 26 list styling from screenshots
  - Implement exact list item heights from specifications
  - Add exact list item separators from screenshots
  - Use exact list item typography from specifications

- [ ] **Improve grid layouts**
  - Use exact grid spacing from screenshots
  - Implement exact grid item sizing from specifications
  - Add exact grid item styling from screenshots
  - Ensure exact responsive grid behavior

#### Files to Update:
- `lib/widgets/grid_item.dart`
- `lib/widgets/grid_item_with_concurrent.dart`
- `lib/widgets/notam_grouped_list.dart`
- `lib/widgets/swipeable_notam_card.dart`

---

## Priority 4: Accessibility and Usability

### 4.1 Accessibility Features
**Status**: 🟢 Lower Priority  
**Impact**: Inclusive design and compliance

#### Tasks:
- [ ] **Extract iOS 26 accessibility patterns from screenshots**
  - Identify semantic label patterns
  - Document accessibility hint specifications
  - Extract accessibility trait specifications
  - Identify VoiceOver support patterns

- [ ] **Add semantic labels**
  - Add exact iOS 26 semantic labels from screenshots
  - Implement exact accessibility hints from specifications
  - Add exact accessibility traits from screenshots
  - Test with VoiceOver using exact patterns

- [ ] **Improve touch targets**
  - Ensure exact minimum touch target sizes from screenshots
  - Add exact touch target spacing from specifications
  - Test with different finger sizes using exact specs

- [ ] **Add haptic feedback**
  - Implement exact iOS 26 haptic patterns from screenshots
  - Use exact haptic patterns from specifications
  - Test on different devices using exact patterns

#### Files to Update:
- All interactive widgets
- All screen files with custom interactions

---

### 4.2 Form and Input Design
**Status**: 🟢 Lower Priority  
**Impact**: Data entry experience

#### Tasks:
- [ ] **Extract iOS 26 form specifications from screenshots**
  - Get exact text field styling from screenshots
  - Extract input validation styling specifications
  - Document error state styling from screenshots
  - Identify exact input field sizing from specifications

- [ ] **Standardize form elements**
  - Use exact iOS 26 text field styling from screenshots
  - Implement exact input validation styling from specifications
  - Add exact error state styling from screenshots
  - Use exact input field sizing from specifications

- [ ] **Improve date/time pickers**
  - Use exact iOS 26 picker styling from screenshots
  - Implement exact picker animations from specifications
  - Add exact picker styling from screenshots
  - Use exact system date/time formatting from specifications

#### Files to Update:
- `lib/widgets/date_time_picker_dialog.dart`
- `lib/screens/input_screen.dart`
- All forms and input fields

---

## Priority 5: Advanced iOS Features

### 5.1 System Integration
**Status**: 🟢 Lower Priority  
**Impact**: Native iOS experience

#### Tasks:
- [ ] **Extract iOS 26 system integration patterns from screenshots**
  - Identify app icon specifications from screenshots
  - Document launch screen specifications
  - Extract share sheet styling from screenshots
  - Identify URL scheme patterns from specifications

- [ ] **Add system integration**
  - Implement exact iOS 26 app icon specifications from screenshots
  - Add exact launch screen styling from specifications
  - Use exact share sheet styling from screenshots
  - Implement exact URL scheme patterns from specifications

- [ ] **Add iOS-specific features**
  - Implement exact keyboard handling from screenshots
  - Add exact status bar styling from specifications
  - Use exact alert styling from screenshots
  - Implement exact app lifecycle handling from specifications

#### Files to Update:
- iOS configuration files
- `lib/main.dart`
- All alert and dialog implementations

---

### 5.2 Performance and Polish
**Status**: 🟢 Lower Priority  
**Impact**: User experience quality

#### Tasks:
- [ ] **Extract iOS 26 animation specifications from screenshots**
  - Get exact animation curve specifications
  - Extract transition timing from screenshots
  - Document loading state specifications
  - Identify performance optimization patterns

- [ ] **Optimize animations**
  - Use exact iOS 26 animation curves from screenshots
  - Implement exact transition timing from specifications
  - Add exact loading states from screenshots
  - Optimize animation performance using exact specs

- [ ] **Add polish**
  - Implement exact loading indicators from screenshots
  - Add exact empty states from specifications
  - Use exact error states from screenshots
  - Add exact success feedback from specifications

#### Files to Update:
- All screen transitions
- Loading and error states
- Success feedback implementations

---

## Priority 6: Apple HIG Specific Enhancements

### 6.1 iOS Design Language
**Status**: 🟡 Medium Priority  
**Impact**: Native iOS feel and user expectations

#### Tasks:
- [ ] **Extract iOS 26 modal specifications from screenshots**
  - Get exact modal presentation styles from screenshots
  - Extract modal dismissal gestures from specifications
  - Document modal animations from screenshots
  - Identify exact modal styling from specifications

- [ ] **Implement iOS-style modals and sheets**
  - Use exact iOS 26 modal styling from screenshots
  - Implement exact modal presentation styles from specifications
  - Add exact modal dismissal gestures from screenshots
  - Use exact modal animations from specifications

- [ ] **Add iOS-style alerts and action sheets**
  - Use exact iOS 26 alert styling from screenshots
  - Implement exact action sheet styling from specifications
  - Add exact alert button styling from screenshots
  - Use exact alert animations from specifications

- [ ] **Implement iOS-style lists and tables**
  - Use exact iOS 26 list styling from screenshots
  - Implement exact list item styling from specifications
  - Add exact list item separators from screenshots
  - Use exact list item heights from specifications

#### Files to Update:
- All modal and dialog implementations
- List and table components
- Alert and confirmation dialogs

---

### 6.2 iOS-Specific Interactions
**Status**: 🟡 Medium Priority  
**Impact**: User interaction expectations

#### Tasks:
- [ ] **Extract iOS 26 gesture specifications from screenshots**
  - Get exact swipe-to-delete patterns from screenshots
  - Extract pull-to-refresh specifications from screenshots
  - Document long-press patterns from specifications
  - Identify exact gesture recognizer patterns from screenshots

- [ ] **Add iOS-style gestures**
  - Implement exact iOS 26 swipe-to-delete from screenshots
  - Add exact pull-to-refresh functionality from specifications
  - Implement exact long-press actions from screenshots
  - Add exact gesture recognizers from specifications

- [ ] **Implement iOS-style feedback**
  - Add exact iOS 26 haptic feedback from screenshots
  - Use exact system sound effects from specifications
  - Implement exact visual feedback from screenshots
  - Add exact loading states from specifications

- [ ] **Add iOS-style animations**
  - Use exact iOS 26 animation curves from screenshots
  - Implement exact transition animations from specifications
  - Add exact micro-interactions from screenshots
  - Use exact animation durations from specifications

#### Files to Update:
- All interactive components
- Navigation transitions
- Loading and feedback states

---

### 6.3 iOS System Integration
**Status**: 🟢 Lower Priority  
**Impact**: Native iOS experience

#### Tasks:
- [ ] **Extract iOS 26 status bar specifications from screenshots**
  - Get exact status bar styling from screenshots
  - Extract status bar color changes from specifications
  - Document status bar visibility patterns from screenshots
  - Identify exact safe area handling from specifications

- [ ] **Implement proper iOS status bar handling**
  - Use exact iOS 26 status bar styling from screenshots
  - Implement exact status bar color changes from specifications
  - Add exact status bar visibility control from screenshots
  - Handle exact safe area insets from specifications

- [ ] **Add iOS-style keyboard handling**
  - Implement exact keyboard avoidance from screenshots
  - Add exact keyboard toolbar from specifications
  - Handle exact keyboard appearance from screenshots
  - Use exact input field focus management from specifications

- [ ] **Implement iOS-style sharing**
  - Use exact share sheet styling from screenshots
  - Implement exact share functionality from specifications
  - Add exact share preview from screenshots
  - Handle exact share completion from specifications

#### Files to Update:
- Status bar configuration
- Keyboard handling components
- Share functionality implementations

---

## Priority 7: iOS 26 Specific Implementation

### 7.1 iOS 26 Design System Integration
**Status**: 🔴 High Priority (Screenshots Available)  
**Impact**: Latest iOS design patterns and user expectations

#### Tasks:
- [ ] **Analyze iOS 26 Design Resources**
  - Extract exact color values from Sketch/Figma screenshots
  - Document exact typography specifications from screenshots
  - Identify exact component specifications from screenshots
  - Document exact interaction patterns from screenshots

- [ ] **Implement iOS 26 Color System**
  - Update color palette with exact iOS 26 values from screenshots
  - Implement exact semantic color definitions from screenshots
  - Add exact iOS 26 color variants from specifications
  - Update exact dark mode color specifications from screenshots

- [ ] **Update Typography for iOS 26**
  - Implement exact iOS 26 font specifications from screenshots
  - Update typography scale with exact iOS 26 sizes from screenshots
  - Add exact iOS 26 font weights from specifications
  - Implement exact iOS 26 text styles from screenshots

#### Files to Update:
- `lib/constants/weather_colors.dart` (with exact iOS 26 colors from screenshots)
- `lib/constants/typography.dart` (with exact iOS 26 specs from screenshots)
- All screen files with updated design tokens from screenshots

---

### 7.2 iOS 26 Component Updates
**Status**: 🟡 Medium Priority (Screenshots Available)  
**Impact**: Latest iOS component patterns

#### Tasks:
- [ ] **Update Button Components**
  - Implement exact iOS 26 button specifications from screenshots
  - Add exact iOS 26 button variants from specifications
  - Update exact button interaction patterns from screenshots
  - Implement exact iOS 26 button animations from specifications

- [ ] **Update Card and List Components**
  - Implement exact iOS 26 card specifications from screenshots
  - Update exact list item styling for iOS 26 from specifications
  - Add exact iOS 26 list patterns from screenshots
  - Implement exact iOS 26 interaction patterns from specifications

- [ ] **Update Navigation Components**
  - Implement exact iOS 26 navigation patterns from screenshots
  - Update exact navigation bar styling from specifications
  - Add exact iOS 26 navigation features from screenshots
  - Implement exact iOS 26 transition animations from specifications

#### Files to Update:
- All button components with exact iOS 26 specs from screenshots
- Card and list components with exact iOS 26 styling from screenshots
- Navigation components with exact iOS 26 patterns from specifications
- Modal and dialog components with exact iOS 26 styling from screenshots

---

### 7.3 iOS 26 Interaction Patterns
**Status**: 🟡 Medium Priority (Screenshots Available)  
**Impact**: Latest iOS interaction expectations

#### Tasks:
- [ ] **Implement iOS 26 Gestures**
  - Add exact iOS 26 gesture patterns from screenshots
  - Update exact gesture implementations from specifications
  - Implement exact iOS 26 haptic feedback from screenshots
  - Add exact iOS 26 micro-interactions from specifications

- [ ] **Update Animation Patterns**
  - Implement exact iOS 26 animation curves from screenshots
  - Update exact transition animations from specifications
  - Add exact iOS 26 animations from screenshots
  - Implement exact iOS 26 loading states from specifications

- [ ] **Add iOS 26 Accessibility Features**
  - Implement exact iOS 26 accessibility patterns from screenshots
  - Add exact iOS 26 VoiceOver features from specifications
  - Update exact accessibility labels for iOS 26 from screenshots
  - Implement exact iOS 26 assistive technology support from specifications

#### Files to Update:
- All interactive components with exact iOS 26 patterns from screenshots
- Animation implementations with exact iOS 26 specs from screenshots
- Accessibility implementations with exact iOS 26 patterns from specifications

---

## Implementation Strategy

### Phase 1: Foundation (Weeks 1-2)
1. Extract exact iOS 26 color values from screenshots
2. Extract exact iOS 26 typography specifications from screenshots
3. Extract exact iOS 26 spacing specifications from screenshots
4. Update core navigation with exact iOS 26 specs from screenshots

### Phase 2: Components (Weeks 3-4)
1. Extract exact iOS 26 button specifications from screenshots
2. Extract exact iOS 26 card specifications from screenshots
3. Extract exact iOS 26 list specifications from screenshots
4. Extract exact iOS 26 navigation specifications from screenshots

### Phase 3: iOS Integration (Weeks 5-6)
1. Extract exact iOS 26 modal specifications from screenshots
2. Extract exact iOS 26 gesture specifications from screenshots
3. Extract exact iOS 26 animation specifications from screenshots
4. Extract exact iOS 26 system integration specifications from screenshots

### Phase 4: iOS 26 Integration (Weeks 7-8) ⭐ NEW
1. Implement exact iOS 26 design system from screenshots
2. Update all components with exact iOS 26 specifications from screenshots
3. Implement exact iOS 26 interaction patterns from screenshots
4. Add exact iOS 26 accessibility features from screenshots

### Phase 5: Polish and Testing (Week 9)
1. Add exact iOS 26 accessibility features from screenshots
2. Implement exact iOS 26 system features from specifications
3. Add exact iOS 26 animations from screenshots
4. Performance optimization and testing with exact iOS 26 specs

---

## Success Metrics

### Visual Consistency
- [ ] All screens use exact iOS 26 color scheme from screenshots
- [ ] Typography follows exact iOS 26 standards from screenshots
- [ ] Spacing follows exact iOS 26 grid system from screenshots
- [ ] Interactive elements follow exact iOS 26 patterns from screenshots

### iOS Native Feel
- [ ] App feels exactly like iOS 26 using specifications from screenshots
- [ ] Interactions match exact iOS 26 expectations from screenshots
- [ ] Animations use exact iOS 26 curves from screenshots
- [ ] System integration works exactly like iOS 26 from specifications

### iOS 26 Compliance ⭐ NEW
- [ ] App implements exact iOS 26 design patterns from screenshots
- [ ] Uses exact iOS 26 color and typography specifications from screenshots
- [ ] Implements exact iOS 26 interactions from screenshots
- [ ] Follows exact iOS 26 accessibility guidelines from specifications

### Accessibility
- [ ] All interactive elements have exact iOS 26 semantic labels from screenshots
- [ ] Touch targets meet exact iOS 26 size requirements from screenshots
- [ ] Color contrast meets exact iOS 26 standards from specifications
- [ ] VoiceOver compatibility verified with exact iOS 26 patterns from screenshots

### Performance
- [ ] Smooth 60fps animations using exact iOS 26 timing from screenshots
- [ ] Exact iOS 26 loading states from screenshots
- [ ] Exact iOS 26 touch feedback from screenshots
- [ ] Efficient memory usage with exact iOS 26 patterns from specifications

### User Experience
- [ ] Intuitive navigation patterns using exact iOS 26 specs from screenshots
- [ ] Consistent interaction feedback using exact iOS 26 patterns from screenshots
- [ ] Proper error handling using exact iOS 26 styling from screenshots
- [ ] Seamless iOS integration using exact iOS 26 specifications from screenshots

---

## Apple HIG Compliance Checklist

### Design Principles
- [ ] **Clarity**: Text is legible at all sizes, icons are precise and lucid
- [ ] **Deference**: Content fills the screen, while translucent UI elements hint at more
- [ ] **Depth**: Distinct visual layers and realistic motion convey hierarchy

### Layout Guidelines
- [ ] **Safe Areas**: Content respects safe areas and doesn't interfere with system UI
- [ ] **Margins**: Use exact iOS 26 margins from screenshots
- [ ] **Spacing**: Follow exact iOS 26 grid system from screenshots
- [ ] **Touch Targets**: Exact iOS 26 minimum sizes from screenshots

### Typography Standards
- [ ] **SF Pro**: Use exact iOS 26 system fonts from screenshots
- [ ] **Font Sizes**: Follow exact iOS 26 typography scale from screenshots
- [ ] **Font Weights**: Use exact iOS 26 weights from screenshots
- [ ] **Line Heights**: Exact iOS 26 spacing from screenshots

### Color Guidelines
- [ ] **System Colors**: Use exact iOS 26 semantic colors from screenshots
- [ ] **Dark Mode**: Support exact iOS 26 dark mode from screenshots
- [ ] **Contrast**: Meet exact iOS 26 contrast standards from screenshots
- [ ] **Accessibility**: Test with exact iOS 26 accessibility features from screenshots

### Interaction Patterns
- [ ] **Touch Feedback**: Provide exact iOS 26 visual feedback from screenshots
- [ ] **Haptic Feedback**: Use exact iOS 26 haptic patterns from screenshots
- [ ] **Gestures**: Implement exact iOS 26 gestures from screenshots
- [ ] **Animations**: Use exact iOS 26 animation curves and durations from screenshots

### iOS 26 Specific ⭐ NEW
- [ ] **Latest Design System**: Implement exact iOS 26 design tokens from screenshots
- [ ] **New Components**: Use exact iOS 26 UI components from screenshots
- [ ] **Updated Interactions**: Implement exact iOS 26 interaction patterns from screenshots
- [ ] **Enhanced Accessibility**: Follow exact iOS 26 accessibility guidelines from screenshots

---

## Notes

- All changes should maintain existing functionality
- Test thoroughly on different iOS versions
- Consider backward compatibility
- Document all style changes for future reference
- Regular design reviews during implementation
- Follow Apple's latest HIG updates and recommendations
- **iOS 26 Resources**: Screenshots available - need detailed analysis and specification extraction

---

**Last Updated**: January 2025  
**Status**: Screenshots Available - Need Detailed Analysis  
**Next Review**: After extracting exact specifications from iOS 26 screenshots 