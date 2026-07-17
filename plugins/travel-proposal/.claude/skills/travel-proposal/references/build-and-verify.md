# Build & verify — technical playbook

## Handling the huge base64 file
The finished HTML is ~7–8MB (embedded photos + map tiles + inlined Leaflet). **Never read the whole file** — base64 overflows context.
- Inspect only non-base64 parts: `python3 -c "import re;h=open(P,encoding='utf-8').read();print(re.sub(r'data:[^\"')]+','DATA',h)[OFFSET:OFFSET+40000])"`, or grep class names / the `<style>` block.
- Edit via targeted `python3` `.replace()` on exact CSS/markup snippets, or the Edit tool on SHORT unique strings. Never paste base64. Never rewrite the whole file.
- Leaflet JS, the `TILES` base64 object, photo data-URIs, and map marker LOGIC stay byte-for-byte; change marker color via CSS only.

## Images
- Source photos: Wikimedia Commons API (needs a custom User-Agent). Compress with `ffmpeg -y -i in -vf "scale=1100:-2" -q:v 6 out.jpg` (no PIL/ImageMagick here). Inline as base64 data-URI via a python3 pass over `{{IMG:name}}` placeholders.
- Keep a `credits.json` `{file,subject,author,license,source_url}`; render attribution in the footer for CC BY / BY-SA.

## Offline interactive maps (the hard part)
- Use **Leaflet 1.9.4 inlined** (fetch leaflet.css + leaflet.js via curl, embed in `<style>`/`<script>` — zero external refs).
- **Embed tiles for offline zoom:** pre-fetch raster tiles (curl + User-Agent) over a TIGHT bbox per map area, limited zoom range (~z14–17 for the main city, z14–16 for wider areas). Serve them from a custom `L.TileLayer` subclass whose `getTileUrl` returns a data-URI from an embedded `TILES["z/x/y"]` object; missing key → a blank canvas-colored tile (never a broken image). Constrain each map `minZoom`/`maxZoom`/`maxBounds` (viscosity 1) to the embedded data so users can't pan into grey. `fitBounds` on the marker group for initial view.
- **Tile source:** `tile.openstreetmap.org` bulk-blocks (403). Use **Carto Voyager** (same OSM data, light basemap fitting the paper/white aesthetic, CDN allows fetch). Attribution: "© OpenStreetMap contributors © CARTO" in-map + footer.
- Markers: `divIcon` coral dots + popup with place name + `https://www.google.com/maps/search/?api=1&query=<lat,lon or URL-encoded 이름 지역>`.
- Multiple maps on one page = unique div id + own `L.map()` via a shared factory (Leaflet can't share one instance). The same city map reused across days → reuse the tile data (don't re-embed); duplicate only the cheap marker markup.
- Budget: keep total file < ~8MB. If tiles blow the budget, tighten bboxes / drop the top zoom level / prioritize the most-used city map's depth.

## Tabs (accessible, offline)
- Vanilla JS. Real `<button role="tab">` with aria-selected/aria-controls/roving tabindex; panels `role="tabpanel"` + `hidden`; Left/Right arrow nav; active tab reflected in `location.hash` via `history.replaceState`.
- **Leaflet-in-hidden-panel fix (critical):** maps in hidden tabs render at 0 size → grey. Keep map refs in `window.__maps`; on every tab/sub-tab activation, after un-hiding, `requestAnimationFrame(() => { invalidateSize(); re-fitBounds; })` over visible maps only.
- Isolate new card grids from existing classes (name collisions like `.cards`/`.card` break earlier grids — use distinct names, e.g. `.cafegrid`/`.ccard`).

## Verification checklist (Playwright, in the build agent)
- Network fully blocked / offline: **0 external resource loads**; every map renders tiles+pins after switching to its tab; zoom works within embedded range; invalidateSize fires.
- All top tabs + all sub-tabs switch; cards render; popups open with well-formed Google Maps links.
- `grep` = 0 em-dashes; 0 `unpkg`, 0 live `tile.openstreetmap.org` runtime fetch, 0 external `<script src=http>`/`<link href=http>`.
- No horizontal overflow at 360–400px; no console errors (favicon 404 is harmless).
- Screenshot desktop + mobile.
- File size stayed in budget; old files untouched.

## Content standards
- Personalize: user's Google Maps memos as verbatim coral pull-quotes; tailor sections to stated tastes.
- Mealtime dining split (아침/점심/저녁), plus 술집 (by the user's drink taste) and 커피·디저트 as cards.
- Heat/season-aware pacing; walking budgets per day (거리 중심); respect the user's wake time.
- Every place: 지역·역 · 가격대 · 영업시간(휴무) · 예약/확인 태그 · 구글맵 링크. Flag "확인 필요" honestly.
- Keep a parallel plan `.md` in sync with the HTML facts.
