## Lessons learned – NAIPS + API weather, parsing and display

- NAIPS TAF parsing
  - Leading whitespace and optional variants (AMD/COR/TAF3) appear frequently in NAIPS. Our TAF regex must allow leading spaces before `TAF` and optional markers after it, and it must stop at the next section boundary without eating it.
  - Always preserve the full multi‑line NAIPS TAF in `Weather.rawText` for display and highlighting. Build a compact, single‑line version only for decoding.
  - Normalize line endings (CR/LF) and collapse stray blank lines to prevent random spacing.
  - Showing the initial weather: if the first body line is initial weather (not a period marker), join it to the header for readability, but never swallow trailing markers like `TAF3`.
  - Ensure `TAF3` is retained and displayed on its own line so users can see the version.

- ATIS timestamp and age
  - Deduplication and “age” must use the actual broadcast time, not fetch time. Parse the 6‑digit `ddhhmm` from the ATIS and set `Weather.timestamp` (and `DecodedWeather.timestamp`) in UTC.
  - Convert ATIS to a `StatefulWidget` and update age on a timer, mirroring TAF behavior.

- Merge strategy and staleness
  - Treat METAR, TAF, and ATIS independently. Select the newest item per ICAO and per type; do not let a stale result of one type override a fresh result of another.
  - Prefer NAIPS TAFs on ties and give NAIPS a small advantage: API replaces a NAIPS TAF only if it is clearly newer (>2 minutes). This avoids NAIPS being displaced by negligible API skew while still surfacing genuinely newer API data when NAIPS lags.
  - For API METARs, always route through `Weather.fromMetar` to ensure full decode and the true issue timestamp.

- Display and highlighting
  - INITIAL highlighting should begin after the TAF header and extend until the first explicit period (FM/BECMG/TEMPO/INTER/PROBxx), so initial wind/vis on the next line is fully included.
  - Formatter should insert line breaks before forecast tokens and keep `TAF3` visible.

- Parser hardening process
  - Build and maintain a corpus of NAIPS outputs (TAF/METAR/ATIS) with variants (COR, AUTO, AMD, TAF3, spacing) and keep an acceptance matrix.
  - Add targeted debug logs (e.g., TAF regex match counts) to validate changes quickly without flooding logs.
  - **Debugging Strategy**: When investigating parsing issues, remove verbose logging from other components (e.g., NOTAM processing) to focus on the specific problem area. Use targeted test files to isolate regex patterns without Flutter dependencies.

- TAF Priority Logic Debugging (January 2025)
  - **Problem**: NAIPs TAF parsing was working (confirmed by logs), but UI still showed API TAFs
  - **Root Cause**: Merge logic used "newest wins" - API TAFs had newer timestamps than NAIPs TAFs
  - **Debugging Process**: 
    1. Removed verbose NOTAM logging to see TAF logs clearly
    2. Confirmed NAIPs TAFs were being parsed successfully (`source=naips`)
    3. Identified that API TAFs were winning the merge due to newer timestamps
    4. Fixed by prioritizing NAIPs TAFs regardless of timestamp
  - **Solution**: Add NAIPs TAFs first, then only add API TAFs as fallback if no NAIPs TAF exists for that airport
  - **Key Lesson**: When parsing works but wrong data is displayed, check the merge/priority logic, not just the parsing

- Pitfalls we hit
  - Accidentally overwriting full raw TAF with compact text caused "first‑line only" rendering.
  - Assuming `Z` had no space before it; NAIPS occasionally inserts optional spaces.
  - Using fetch time for ATIS led to incorrect ages and dedupe order.
  - A tie‑blind "NAIPS over API" merge allowed older NAIPS to suppress newer API; a naive "newest‑wins" then suppressed NAIPS too aggressively. The 2‑minute NAIPS preference is a pragmatic balance.
  - **TAF Priority Logic Regression (January 2025)**: After fixing NAIPs TAF parsing regex, the merge logic was still using "newest wins" which caused API TAFs to override NAIPs TAFs due to newer timestamps. **Solution**: Prioritize NAIPs TAFs regardless of timestamp - add NAIPs TAFs first, then only add API TAFs as fallback if no NAIPs TAF exists for that airport.

## Lessons learned – NAIPS Charts directory and viewer

- Directory access
  - The Chart Directory requires a login then a form POST to `ChartDirectorySearch` (not `ChartListing`). Mimic the browser: warm GET `/naips/ChartDirectory`, scrape hidden inputs, then POST with `SearchCriteria`, `ChartCategory`, and `SubmitChartSearch=Submit`.
  - Some sessions still return the login/docs page with 200 OK; explicitly detect by content and re‑auth.

- Parsing strategy
  - Parse the main table by headers (Code | Name | Valid From | Valid Till | Lo‑Res | Hi‑Res | PDF). Fall back to link‑centric discovery if structure changes.
  - “Details” pages do not link images directly; resolve to `/ChartDirectory/GetImage/...` and fetch bytes with NAIPS cookies and a proper Referer.
  - Treat `Valid Till = PERM` as a single‑time product; compute a 6‑hour window centered on the valid time (±3h). If the name contains `VALID HHMMZ`, prefer that as `validAtUtc`.

- Ordering vs pruning
  - Avoid over‑pruning. We initially filtered to a narrow curated set and dropped many legitimate products. The correct approach is: keep the full set, then apply a stable ordering to surface the most useful first.
  - Categorize broadly (MSL Analysis/Prognosis, SIGWX core vs regional, SIGMET All/High/Low, SATPIC Australia Regional, GP Winds High/Mid, others) and sort using explicit precedence.

- Viewer UX
  - Combine pinch‑to‑zoom and page‑swipe by disabling page scrolling whenever zoom > ~1x, and provide bottom arrow buttons as an alternative.
  - Double‑tap zoom should center on the tap point by mapping the tap into scene coordinates and animating the transform.
  - Show compact validity at the top; single‑time color coding (e.g., 0000Z/0600Z) helps quickly group cycles.

- Diagnostics
  - Log table headers, counts, and a capped sample of rows (code, name, category, times) to validate parsing without noisy logs.
  - When things look empty but status=200, assume login/docs body and check the Referer/POST path.

# Lessons Learned - Dispatch Buddy Development

## Navigation & UX Design

### Bottom Navigation Best Practices
**Date**: December 2024
**Context**: Adding Home button to bottom navigation bar

**Lessons:**
- ✅ **Always show bottom nav** - Users expect consistent navigation patterns
- ✅ **Don't hide tabs** - Apple HIG recommends persistent tab bars for main navigation
- ✅ **Use empty states** - Better than hiding content or disabling tabs
- ✅ **Educational content** - Help users understand what each tab does
- ✅ **Clear next steps** - Provide obvious actions for empty states

**Implementation:**
- Added Home button to left of Summary in bottom nav
- Updated tab indices: Home(0), Summary(1), Airports(2), Raw Data(3)
- Created Apple-style empty states with helpful descriptions and action buttons

**Apple Design Principles Applied:**
- Progressive disclosure - Show tabs, let users explore
- Educational onboarding - Help users understand app structure
- Consistent navigation - Never hide main navigation elements
- Friendly, helpful language in empty states

### Empty State Design Patterns
**Date**: December 2024
**Context**: Creating empty states for tabs without active briefing

**Lessons:**
- ✅ **Explain what the tab does** when there's no data
- ✅ **Provide clear next steps** for users
- ✅ **Use friendly, helpful language**
- ✅ **Include relevant icons** to illustrate the purpose
- ✅ **Prominent action buttons** - Make the next step obvious

**Implementation:**
- Large icons (80px) with clear titles
- Descriptive text explaining tab purpose
- "Start New Briefing" buttons that navigate to input screen
- Consistent styling across all empty states

## Data Management & Persistence

### Pull-to-Refresh Consistency
**Date**: December 2024
**Context**: Fixing pull-to-refresh data persistence issues

**Problem:**
- Pull-to-refresh used `refreshFlightData()` (memory only)
- Refresh buttons used `BriefingRefreshService.refreshBriefing()` (storage)
- Inconsistent behavior between refresh methods
- Data lost when navigating away and back

**Solution:**
- ✅ **Unified refresh method** `refreshCurrentData()` in FlightProvider
- ✅ **Smart routing**: Uses `BriefingRefreshService.refreshBriefing()` for both current and previous briefings
- ✅ **Consistent behavior**: Both methods now work identically
- ✅ **Proper persistence**: Creates versioned backups and updates timestamps

**Technical Implementation:**
```dart
/// Unified refresh method that handles both current and previous briefings
Future<void> refreshCurrentData({
  bool? naipsEnabled,
  String? naipsUsername,
  String? naipsPassword,
}) async {
  if (_currentBriefing != null) {
    // For previous briefings, use the briefing refresh method
    await refreshBriefingByIdUnified(_currentBriefing!.id);
  } else {
    // For current briefings, refresh flight data and save to storage
    await refreshFlightData(
      naipsEnabled: naipsEnabled,
      naipsUsername: naipsUsername,
      naipsPassword: naipsPassword,
    );
    
    // Convert the refreshed flight to a briefing and save it
    if (_currentFlight != null) {
      final briefing = Briefing(/* ... */);
      await BriefingStorageService.saveBriefing(briefing);
    }
  }
}
```

**Benefits:**
- Consistent UX across all refresh methods
- Data persistence when navigating
- Proper versioning and backup creation
- Home screen timestamp updates
- Error handling through proven workflows

## Text Formatting & Parsing

### ATIS Text Formatting Iterative Development
**Date**: January 2025
**Context**: Reformatting ATIS (Automatic Terminal Information Service) text for better readability

**Problem:**
- Raw ATIS text had inconsistent line breaks and poor visual hierarchy
- Users needed clear section separation and indentation
- Continuation lines within sections were hard to identify
- ATIS identifier line needed to be prominently displayed

**Initial Requirements:**
- ATIS identifier on its own line with no indentation
- Section headers (APCH:, RWY:, SFC COND:, etc.) with content on same line
- Additional indentation for continuation content within sections
- Highlighted lines (starting with "+") with minimal indentation

**Development Process:**
1. **First Attempt**: Applied simple formatting rules to raw text
   - Result: Section headers and content appeared on separate lines
   - Lesson: User wanted header and content together

2. **Second Attempt**: Modified to keep headers and content on same line
   - Result: APCH: not starting on second line as expected
   - Lesson: Raw text might combine ATIS identifier with first section

3. **Third Attempt**: Added logic to split first line if it contained both
   - Result: Content after section headers was being lost
   - Lesson: Need to handle continuation content properly

4. **Fourth Attempt**: Introduced cleanup phase to join fragmented lines
   - Result: Random line breaks still present
   - Lesson: Need more robust preprocessing

5. **Final Solution**: Two-phase approach with proper state management
   - Result: Clean, readable ATIS formatting

**Final Implementation:**
```dart
String _formatAtisText(String rawText) {
  final lines = rawText.split('\n');
  final cleanedLines = <String>[];
  final formattedLines = <String>[];
  
  String currentSection = '';
  String currentContent = '';
  
  // Phase 1: Cleanup - Join fragmented lines into logical sections
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    
    // Special handling for first line (ATIS identifier + possible first section)
    if (i == 0 && line.startsWith('ATIS')) {
      if (line.contains(':')) {
        // Split ATIS identifier from first section
        final colonIndex = line.indexOf(':');
        final beforeColon = line.substring(0, colonIndex).trim();
        final afterColon = line.substring(colonIndex + 1).trim();
        
        final wordsBeforeColon = beforeColon.split(' ');
        final sectionHeader = wordsBeforeColon.last;
        final atisInfo = wordsBeforeColon.take(wordsBeforeColon.length - 1).join(' ');
        
        cleanedLines.add(atisInfo);
        currentSection = sectionHeader;
        currentContent = afterColon;
      } else {
        cleanedLines.add(line);
      }
      continue;
    }
    
    // Identify section headers and accumulate continuation content
    if (line.contains(':') && _isSectionHeader(line)) {
      if (currentSection.isNotEmpty && currentContent.isNotEmpty) {
        cleanedLines.add('$currentSection: $currentContent');
        currentContent = '';
      }
      currentSection = line.substring(0, line.indexOf(':')).trim();
      currentContent = line.substring(line.indexOf(':') + 1).trim();
    } else if (line.startsWith('+')) {
      // Handle highlighted lines
      if (currentSection.isNotEmpty && currentContent.isNotEmpty) {
        cleanedLines.add('$currentSection: $currentContent');
        currentSection = '';
        currentContent = '';
      }
      cleanedLines.add(line);
    } else if (line.startsWith('TMP:') || line.startsWith('QNH:')) {
      // Handle standalone sections
      if (currentSection.isNotEmpty && currentContent.isNotEmpty) {
        cleanedLines.add('$currentSection: $currentContent');
        currentSection = '';
        currentContent = '';
      }
      cleanedLines.add(line);
    } else {
      // Accumulate continuation content
      if (currentContent.isNotEmpty) {
        currentContent += ' $line';
      } else {
        currentContent = line;
      }
    }
  }
  
  // Add final section
  if (currentSection.isNotEmpty && currentContent.isNotEmpty) {
    cleanedLines.add('$currentSection: $currentContent');
  }
  
  // Phase 2: Apply formatting with proper indentation
  for (int i = 0; i < cleanedLines.length; i++) {
    final line = cleanedLines[i].trim();
    if (line.isEmpty) continue;
    
    if (i == 0 && line.startsWith('ATIS')) {
      formattedLines.add(line); // No indentation for ATIS identifier
    } else if (_isSectionHeader(line)) {
      formattedLines.add('    $line'); // 4 spaces for section headers
    } else if (line.startsWith('+')) {
      formattedLines.add('  $line'); // 2 spaces for highlighted lines
    } else if (line.startsWith('TMP:') || line.startsWith('QNH:')) {
      formattedLines.add('    $line'); // 4 spaces for standalone sections
    } else {
      formattedLines.add('            $line'); // 12 spaces for continuation content
    }
  }
  
  return formattedLines.join('\n');
}
```

**Key Lessons Learned:**
- ✅ **Two-phase approach works best**: Cleanup phase to join fragmented content, then formatting phase for indentation
- ✅ **State management is crucial**: Track current section and content during cleanup
- ✅ **Handle edge cases first**: Special logic for first line that might contain both ATIS identifier and first section
- ✅ **Iterative development pays off**: Each attempt revealed new insights about the data structure
- ✅ **User feedback is essential**: Without user guidance, we would have implemented the wrong solution
- ✅ **Sometimes simpler is better**: Complex text measurement and auto-wrapping would have overcomplicated the solution

**Final Result:**
- ATIS identifier prominently displayed with no indentation
- Section headers clearly visible with 4-space indentation
- Continuation content properly indented with 12 spaces for clear hierarchy
- Highlighted lines (+ WIND:, + VIS:, etc.) with 2-space indentation
- Clean, readable format that's easy to scan and understand

**User Satisfaction:**
- User confirmed the final formatting meets their needs
- ATIS text is now much more readable than raw format
- Clear visual hierarchy makes information easy to find
- No need for complex auto-wrapping or text measurement

## iOS Design Patterns

### Apple Human Interface Guidelines
**Date**: December 2024
**Context**: Implementing navigation and empty states

**Key Principles Applied:**
- ✅ **Tab Bar Best Practices**: Always show tab bar, don't hide tabs
- ✅ **Empty State Guidelines**: Explain what tab does, provide clear next steps
- ✅ **Progressive Disclosure**: Show tabs, let users explore
- ✅ **Educational Onboarding**: Help users understand app structure
- ✅ **Consistent Navigation**: Never hide main navigation elements

**Implementation Examples:**
- Photos, Mail, Calendar apps use helpful empty states
- Bottom navigation remains visible across all screens
- Educational content explains tab purposes
- Clear action buttons guide users

## Technical Architecture

### State Management Patterns
**Date**: December 2024
**Context**: Managing navigation state and data persistence

**Lessons:**
- ✅ **Unified refresh logic** - Single method handles multiple scenarios
- ✅ **Smart routing** - Different logic for current vs previous briefings
- ✅ **Consistent data flow** - All refresh methods use same underlying service
- ✅ **Proper error handling** - Use proven, tested workflows

**Pattern Applied:**
- Centralized refresh logic in FlightProvider
- Delegation to appropriate services based on context
- Consistent interface across all screens
- Proper state persistence and restoration

## User Experience Insights

### Navigation Consistency
**Date**: December 2024
**Context**: User feedback on navigation patterns

**Key Insights:**
- Users expect consistent navigation across all screens
- Bottom navigation should always be visible
- Empty states should educate, not confuse
- Clear next steps are essential for user flow

**Implementation Results:**
- Improved user understanding of app structure
- Reduced confusion about tab purposes
- Better onboarding experience for new users
- Consistent behavior across all refresh methods

## Future Considerations

### Scalability
- Navigation patterns established for future features
- Empty state framework can be reused for new tabs
- Unified refresh pattern can accommodate new data sources
- Apple design principles provide solid foundation for growth
- ATIS formatting approach can be applied to other aviation text formats

### Maintenance
- Centralized refresh logic reduces code duplication
- Consistent patterns make debugging easier
- Educational empty states reduce user support needs
- Apple design patterns ensure long-term usability
- Two-phase text formatting approach is maintainable and extensible 