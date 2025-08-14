# Charts Feature Roadmap

## Overview
Add NAIPS graphical charts to the app via a new "More" entry point. Users can browse a curated list of AUS charts (MSL Analysis/Prognosis, SIGWX High/Mid, SIGMET, SATPIC, Grid Point Winds), inspect validity and download Hi‑Res images/PDFs with pinch‑to‑zoom, and quickly flip between valid times. All times shown in UTC.

## Entry Point & Navigation
- Bottom navigation: add fifth item "More".
- Tapping More opens a modal sheet (sheet can expand to full‑screen) with additional areas:
  - Charts (implemented in this feature)
  - Placeholders for future: ERSA tools, NAIPS utilities, Previous Briefings shortcuts, Settings shortcuts.
- Selecting Charts opens the Charts screen.

## Sources & Access
- Primary: NAIPS Chart Directory (HTML) – requires NAIPS session for full fidelity.
- If NAIPS credentials are missing/invalid:
  - Show banner with link to Settings to add credentials.
  - Optionally show publicly accessible directory subset if available; otherwise placeholder with guidance.
- Reuse existing NAIPS cookie/session flow; add dedicated endpoints for chart directory + asset retrieval.

## Product Scope (Phase 1 Curated)
Order and grouping as listed by product owner:
1) MSL Analysis
2) MSL Prognosis
3) SIGWX High Level
4) SIGWX Mid Level
5) SIGMET (Australia All/High/Low)
6) SATPIC (Satellite imagery; visible/IR as provided)
7) Grid Point Winds (AUS High‑Level at cycle times: 0000Z/0600Z/1200Z/1800Z)

Exclude all other items for now (e.g., TEST, conversions, perm reference docs).

## UI/UX
- Charts screen layout
  - Tabs: Curated (default), All (for future expansion)
  - Filters: time window (reuse NOTAM time filter component), level filter (for winds High/Mid levels)
  - List cards show: Name, Valid From/Valid Till (UTC), countdown badge, source label, quick actions (View, Download)
  - Sorting: order by curated priority; within each product, current‑valid first, then nearest upcoming validity
- Chart viewer
  - Prefer Hi‑Res image; show a secondary action to open PDF when present
  - Pinch‑to‑zoom, pan, single‑tap controls, share/export
  - Quick toggle/swipe to next/previous valid time within same product
- Validity presentation
  - Badge and text: "Valid 12:00–18:00Z" + live countdown (updates each minute)
  - Color rules: green (currently valid, >2h left), amber (≤2h left), red (expired), grey (upcoming)

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
