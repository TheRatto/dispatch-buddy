# NAIPS Integration Investigation Plan

## Problem Statement
- **Previous briefing refresh**: "Failed to refresh" 
- **Pull-to-refresh**: Gets ATIS sometimes
- **Generate new briefing**: Does not get ATIS
- **Inconsistent behavior** across different data flows

## Investigation Goals
1. **Verify consistent NAIPS usage** across all data products (METARs, TAFs, ATIS)
2. **Ensure consistent methods** for new briefings, home refresh, and pull-to-refresh
3. **Identify why ATIS is intermittent** and fix the root cause
4. **Standardize the data flow** with only minor differences as specified

## Phase 1: Code Review and Architecture Analysis

### 1.1 Review NAIPS Integration Points
**Files to examine:**
- `lib/services/api_service.dart` - Main API routing logic
- `lib/services/naips_service.dart` - NAIPS web simulation
- `lib/services/naips_parser.dart` - NAIPS data parsing
- `lib/providers/flight_provider.dart` - Data flow orchestration

**Questions to answer:**
- Are all weather types (METAR, TAF, ATIS) using the same NAIPS integration path?
- Is NAIPS being called consistently across all refresh methods?
- Are there different parsing logic for different weather types?

### 1.2 Review Data Flow Methods
**Methods to compare:**
- `FlightProvider.refreshFlightData()` - Used by pull-to-refresh
- `FlightProvider.refreshCurrentData()` - Used by pull-to-refresh  
- `FlightProvider.refreshBriefingByIdUnified()` - Used by previous briefing refresh
- `FlightProvider.addAirportToFlight()` - Used by new briefing creation

**Questions to answer:**
- Do all methods pass NAIPS settings to API service?
- Do all methods use the same API service methods?
- Are there different error handling paths?

### 1.3 Review API Service Methods
**Methods to examine:**
- `ApiService.fetchWeather()` - For METARs and ATIS
- `ApiService.fetchTafs()` - For TAFs
- `ApiService.fetchNotamsWithSatcomFallback()` - For NOTAMs

**Questions to answer:**
- Do all methods handle NAIPS settings consistently?
- Are there different fallback strategies?
- Is ATIS parsing handled differently than METAR/TAF?

## Phase 2: Manual Testing and Log Analysis

### 2.1 Test New Briefing Creation
**Steps:**
1. Enable NAIPS in settings
2. Create new briefing with YSCB
3. Check debug logs for:
   - NAIPS settings being passed
   - NAIPS service being called
   - ATIS parsing attempts
   - Final weather data count

**Expected logs to look for:**
```
DEBUG: 🔄 FlightProvider - NAIPS settings being passed to API: enabled=true, username=SET, password=SET
DEBUG: 🔍 NAIPS returned X weather items
DEBUG: 🔍 NAIPS weather breakdown - METARs: X, TAFs: X, ATIS: X
DEBUG: NAIPSParser - Parsing ATIS from content length: X
DEBUG: NAIPSParser - Found "ATIS" in content
```

### 2.2 Test Pull-to-Refresh
**Steps:**
1. Navigate to METAR/ATIS tab
2. Pull to refresh
3. Check same debug logs as above

### 2.3 Test Previous Briefing Refresh
**Steps:**
1. Go to Home tab
2. Tap refresh button on a previous briefing card
3. Check debug logs for:
   - `refreshBriefingByIdUnified` being called
   - NAIPS settings being loaded
   - BriefingRefreshService being called with NAIPS settings

**Expected logs:**
```
DEBUG: 🚀 refreshBriefingByIdUnified called for briefing X
DEBUG: BriefingRefreshService - Starting refresh for briefing X
DEBUG: BriefingRefreshService - Fetching fresh data for airports: [YSCB]
DEBUG: 🔍 NAIPS returned X weather items
```

### 2.4 Test Home Page Refresh
**Steps:**
1. On Home tab, tap refresh button
2. Check debug logs for same patterns as pull-to-refresh

## Phase 3: Specific Issues Investigation

### 3.1 ATIS Parsing Investigation
**Questions to answer:**
- Is ATIS data being returned by NAIPS service?
- Is ATIS data being parsed correctly?
- Is ATIS data being stored in the briefing?
- Is ATIS data being displayed in the UI?

**Debug points to add:**
- Add logging in `naips_parser.dart` for ATIS parsing
- Add logging in `flight_provider.dart` for ATIS processing
- Add logging in `metar_tab.dart` for ATIS display

### 3.2 Previous Briefing Refresh Failure
**Questions to answer:**
- What specific error is causing "Failed to refresh"?
- Is it a NAIPS authentication issue?
- Is it a data parsing issue?
- Is it a storage issue?

**Debug points to add:**
- Add try-catch logging in `refreshBriefingByIdUnified`
- Add logging in `BriefingRefreshService.refreshBriefing`
- Add logging for NAIPS settings loading

### 3.3 New Briefing vs Refresh Differences
**Questions to answer:**
- Why does new briefing not get ATIS but refresh sometimes does?
- Are different API service methods being called?
- Are different parsing methods being used?
- Are different storage methods being used?

## Phase 4: Remediation Plan

### 4.1 Standardize Data Flow
**Goal:** Ensure all refresh methods use the same core logic with only minor differences.

**Proposed unified approach:**
1. **All methods** should call the same API service methods with NAIPS settings
2. **All methods** should use the same parsing logic
3. **All methods** should use the same storage logic
4. **Only differences:**
   - New briefing: Generate new briefing ID
   - Refresh: Use existing briefing ID
   - Pull-to-refresh: Use current briefing ID

### 4.2 Fix ATIS Integration
**Issues to address:**
- Ensure ATIS is included in all NAIPS requests
- Ensure ATIS parsing is consistent
- Ensure ATIS storage is consistent
- Ensure ATIS display is consistent

### 4.3 Fix Previous Briefing Refresh
**Issues to address:**
- Fix NAIPS settings loading in `refreshBriefingByIdUnified`
- Fix error handling in `BriefingRefreshService`
- Ensure consistent data flow with other refresh methods

## Phase 5: Implementation Steps

### 5.1 Code Review Tasks
- [ ] Review `ApiService.fetchWeather()` for ATIS handling
- [ ] Review `naips_parser.dart` for ATIS parsing consistency
- [ ] Review `flight_provider.dart` for refresh method consistency
- [ ] Review `BriefingRefreshService` for NAIPS integration

### 5.2 Testing Tasks
- [ ] Test new briefing creation with debug logging
- [ ] Test pull-to-refresh with debug logging
- [ ] Test previous briefing refresh with debug logging
- [ ] Test home page refresh with debug logging
- [ ] Compare logs across all methods

### 5.3 Fix Tasks
- [ ] Fix ATIS parsing in NAIPS parser
- [ ] Fix NAIPS settings passing in all refresh methods
- [ ] Fix error handling in previous briefing refresh
- [ ] Standardize data flow across all methods
- [ ] Add comprehensive logging for debugging

## Phase 6: Validation

### 6.1 Success Criteria
- [ ] New briefing creation gets ATIS consistently
- [ ] Pull-to-refresh gets ATIS consistently
- [ ] Previous briefing refresh works without errors
- [ ] All methods use the same core logic
- [ ] Debug logs show consistent NAIPS usage

### 6.2 Test Cases
- [ ] Create new briefing with YSCB → Should get ATIS
- [ ] Pull-to-refresh on METAR/ATIS tab → Should get ATIS
- [ ] Refresh previous briefing card → Should work without errors
- [ ] Refresh home page → Should get ATIS
- [ ] All methods should show similar debug logs

## Next Steps

1. **Start with Phase 1** - Code review to understand current architecture
2. **Move to Phase 2** - Manual testing with debug logging
3. **Analyze results** and identify specific issues
4. **Implement fixes** based on findings
5. **Validate** that all methods work consistently

This plan will help us identify the root cause of the inconsistencies and ensure all NAIPS integration points work reliably. 