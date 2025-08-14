# Charts Feature TODO

## Phase 1 — Directory + Curated List
- [ ] Add bottom nav item "More" → opens modal sheet
- [x] Add "Charts" entry in the sheet (others as placeholders)
- [ ] Service: `NaipsChartsService.fetchDirectory()` using NAIPS session cookies
- [ ] Parser: `NaipsChartsParser.parseDirectory(html)` → `List<ChartItem>`
- [ ] Provider: `ChartsProvider` for catalog, filters, validity tick
- [ ] Curated list only: MSL Analysis, MSL Prognosis, SIGWX High/Mid, SIGMET (All/High/Low), SATPIC, Grid Point Winds
- [ ] Sorting: product order, then current‑valid first, then upcoming by time
- [ ] Validity display (UTC) + live countdown color states
- [ ] Missing credentials banner with link to Settings

## Phase 2 — Viewer + Downloads
- [ ] Viewer screen with pinch‑to‑zoom (prefer Hi‑Res); fallback action to open PDF
- [ ] Adjacent valid navigation (next/previous within same product)
- [ ] Download manager: atomic writes, verify before swap
- [ ] Cache keys: product code + valid window
- [ ] Retain latest 2 cycles/product + pinned charts; TTL respects validity
- [ ] Offline chip; ages/validity computed client‑side

## Phase 3 — Filters + Polish
- [ ] Add time filter (reuse NOTAM filter component)
- [ ] Add level filter for winds (High/Mid or explicit FL groups)
- [ ] Pull‑to‑refresh directory; background refresh when screen opens
- [ ] Error banners: session expiry (re‑auth), 404 asset, network fallback
- [ ] Throttling & retry policy

## Phase 4 — Quality, Metrics, Docs
- [ ] Unit tests: parser (codes, times, links), provider (ordering, validity), caching (atomicity)
- [ ] Integration tests: end‑to‑end NAIPS session + directory + asset fetch (mocked)
- [ ] Telemetry: counts for downloads, cache hits, errors (debug only)
- [ ] Docs: update README links; add user guide snippet for Charts

## Notes from initial spike
- Implemented scaffold: `MoreSheet`, `ChartsScreen`, `ChartItem`, `NaipsChartsService` (stub), `ChartsProvider` (stub).
- Next return point: implement directory parsing (curated only) and hook into provider list.

## Future (Backlog)
- [ ] Background prefetch of next cycle when on Wi‑Fi + charging
- [ ] Favorites / pinned chart groups
- [ ] Auto‑pin charts for current briefing time window
- [ ] Route‑aware suggestions (match cruise altitude)
- [ ] “All” tab with broader catalog (beyond curated)
- [ ] Source badges (NAIPS) + debug diagnostics view
- [ ] AI integration: store downscaled rasters + metadata for local AI
