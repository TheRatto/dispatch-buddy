# Charts Feature TODO

## Phase 1 — Directory + Curated List
- [x] Add bottom nav item "More" → opens modal sheet
- [x] Add "Charts" entry in the sheet (others as placeholders)
- [x] Service: `NaipsChartsService.fetchDirectory()` using NAIPS session cookies (login + form submit)
- [x] Parser: parse main table + Details pages; build `ChartItem` with `validFromUtc`, `validTillUtc`, `validAtUtc`
- [x] Provider: `ChartsProvider` for catalog, validity tick, auth flow and retry
- [x] Catalog now includes core and regional products; no over‑pruning
- [x] Sorting: custom product order (MSL → SIGWX core → SIGMETs → SATPIC AUST REGIONAL → SIGWX MID → GP WINDS High/Mid → others), then current‑valid first, then time
- [x] Validity display (UTC) + live countdown; single‑time products use ±3h window
- [x] Missing credentials banner with link to Settings

## Phase 2 — Viewer + Downloads
- [x] Viewer screen with pinch‑to‑zoom (prefer Hi‑Res); fallback action to open PDF
- [x] Page swipe between charts; auto‑disable when zoomed; bottom arrows for nudge
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
- [ ] Icons per category (done); validity time color legend in a help tip
- [ ] Improve SATPIC/GP Winds icons; consider custom assets

## Phase 4 — Quality, Metrics, Docs
- [ ] Unit tests: parser (codes, times, links), provider (ordering, validity), caching (atomicity)
- [ ] Integration tests: end‑to‑end NAIPS session + directory + asset fetch (mocked)
- [ ] Telemetry: counts for downloads, cache hits, errors (debug only)
- [ ] Docs: update README/roadmap; add user guide snippet for Charts

## Notes from initial spike
- Implemented scaffold: `MoreSheet`, `ChartsScreen`, `ChartItem`, `NaipsChartsService`, `ChartsProvider`.
- Follow‑ups completed: auth + form submit, robust table parser, Details → image resolution, single‑time ±3h windows, ordering, viewer UX.

## Future (Backlog)
- [ ] Background prefetch of next cycle when on Wi‑Fi + charging
- [ ] Favorites / pinned chart groups
- [ ] Auto‑pin charts for current briefing time window
- [ ] Route‑aware suggestions (match cruise altitude)
- [ ] “All” tab with broader catalog (beyond curated)
- [ ] Source badges (NAIPS) + debug diagnostics view
- [ ] AI integration: store downscaled rasters + metadata for local AI
