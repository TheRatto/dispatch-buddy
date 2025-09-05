# Charts Feature Roadmap

## STATUS: PHASE 2 SUBSTANTIALLY COMPLETE ✅

## Overview
Add NAIPS graphical charts to the app via a new "More" entry point. Users can browse a curated list of AUS charts (MSL Analysis/Prognosis, SIGWX High/Mid, SIGMET, SATPIC, Grid Point Winds), inspect validity and download Hi‑Res images/PDFs with pinch‑to‑zoom, and quickly flip between valid times. All times shown in UTC.

## COMPLETED FEATURES ✅

### Phase 1: Directory + Curated List ✅
- ✅ Bottom nav "More" tab with modal sheet
- ✅ Charts entry in More sheet
- ✅ `NaipsChartsService` with NAIPS authentication
- ✅ Chart directory parsing and `ChartItem` model
- ✅ `ChartsProvider` with catalog management
- ✅ Custom product ordering and validity display
- ✅ Live countdown timers and UTC time display
- ✅ Missing credentials banner with Settings link

### Phase 2: Viewer + Core Functionality ✅
- ✅ Full chart viewer with pinch-to-zoom
- ✅ Page swipe between charts
- ✅ PDF fallback action
- ✅ Chart rotation functionality
- ✅ Navigation arrows and controls
- ✅ Validity status display
- ✅ Category icons and color coding

## REMAINING FEATURES

### Phase 3: Advanced Features 📋
- [ ] Download manager with atomic writes and verification
- [ ] Cache management with TTL and retention policies
- [ ] Offline support with client-side validity computation
- [ ] Time and level filters
- [ ] Pull-to-refresh and background updates
- [ ] Enhanced error handling and retry policies

### Phase 4: Polish & Testing 📋
- [ ] Unit tests for parser and provider
- [ ] Integration tests for NAIPS session flow
- [ ] Telemetry and metrics collection
- [ ] Documentation updates

## TECHNICAL IMPLEMENTATION

### Architecture ✅
- **Service Layer**: `NaipsChartsService` with NAIPS authentication
- **State Management**: `ChartsProvider` with catalog management
- **Data Model**: `ChartItem` with validity and metadata
- **UI Components**: `ChartsScreen`, `_ChartViewerScreen` with full viewer functionality
- **Navigation**: Integrated via "More" tab in bottom navigation

### Features Implemented ✅
- **Chart Categories**: MSL Analysis/Prognosis, SIGWX High/Mid, SIGMET, SATPIC, Grid Point Winds
- **Authentication**: NAIPS session management with credential validation
- **Viewer**: Pinch-to-zoom, rotation, PDF fallback, page navigation
- **Validity Display**: Live countdown timers, color-coded status
- **UI/UX**: Professional interface with category icons and smooth navigation

## Downloads & Caching
- Strategy
  - On opening Charts screen, prefetch metadata (directory) and lazily fetch chart assets on first view (with user‑visible progress). Optional background prefetch of the next valid asset per product.
  - Atomic downloads: write to temp file, verify size/type, then swap into cache; never delete the existing cached asset until the new one completes successfully.
- Cache policy
  - Keyed by product code + valid window (from/till).
  - Retain latest 2 cycles per product (configurable) + any user‑pinned charts.
  - TTL: expire assets once outside their valid window unless pinned; metadata refreshed on screen open and via pull‑to‑refresh.
- Offline
  - Display cached assets with an "Offline" chip; ages/validity remain dynamic (computed from stored times, not fetch time).

## Error Handling
- NAIPS session expiry: auto re‑auth and retry once; otherwise show actionable banner with Settings link.
- Missing/404 asset: show friendly retry; allow fallback to alternate format (Lo‑Res/PDF) if available.
- Network: preserve current cached asset; do not evict on failed refresh.
- Logging: structured debug entries for directory parse, asset fetch, cache swaps.

## Data Model
```dart
class ChartItem {
  final String code;            // e.g., 81210
  final String name;            // e.g., SIGMET AUSTRALIA ALL LEVELS
  final DateTime validFromUtc;
  final DateTime? validTillUtc; // null for PERM; typically set for time‑bound charts
  final String category;        // MSL, SIGWX, SIGMET, SATPIC, GPWinds
  final String? level;          // e.g., High, Mid, A050/A100/F185/F340
  final String? cycleZ;         // 0000/0600/1200/1800 when available
  final Uri? loResUrl;
  final Uri? hiResUrl;
  final Uri? pdfUrl;
  final String source;          // 'naips'
}
```

## Services & Architecture
- `NaipsChartsService`
  - Fetch directory HTML using existing NAIPS session cookies
  - Parse table rows → `ChartItem` list
  - Resolve relative asset links (Lo‑Res/Hi‑Res/PDF)
- `NaipsChartsParser`
  - Robust HTML parsing; tolerate whitespace/label variations
  - Extract validity timestamps, product codes, names
- `ChartsProvider`
  - Holds chart catalog, filters, cache manifest, and download states
  - Exposes queries: curated list (ordered), next valid per product, get adjacent cycles
- Reuse global minute‑tick to update validity countdowns

## Security & Permissions
- Use HTTPS; store cookies securely; no credentials in logs
- Respect NAIPS ToS; throttle requests; user‑initiated downloads preferred

## Future Enhancements
- Auto‑pin charts for current briefing time window
- Route‑aware suggestions (e.g., levels matching cruise altitude)
- Background prefetch of next cycle when on Wi‑Fi and charging
- Favorites and quick access groupings
- AI integration: downscaled raster + structured metadata for local AI briefings
- Multi‑region support (e.g., WAFC London/Tokyo SIGWX) with clear provenance

## Milestones
1) Directory parse + curated list display with validity and countdowns
2) Viewer with Hi‑Res/zoom and adjacent‑valid navigation
3) Secure downloads/caching with atomic swap and offline use
4) Filters (time/level) + “All” tab (skeleton)
5) Error handling polish + session management
6) Optional background prefetch of “next valid” per product
