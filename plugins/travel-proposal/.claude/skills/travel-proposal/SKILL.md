---
name: travel-proposal
description: Build a magazine-quality, fully self-contained interactive HTML travel proposal (기획서) for any destination/topic. Trigger on "여행 기획서", "여행계획서 만들어", "/travel-proposal", or any request to plan/design a trip document. Produces one offline-capable .html with topic tabs, embedded interactive maps, dining/shopping cards, personalized from the user's saved Google Maps lists and stated tastes. Korean deliverable, Airbnb design system.
---

# Travel Proposal Builder

Build a **premium, self-contained, interactive HTML travel proposal**. This skill is the standing format for ALL travel documents for this user, across any destination or theme. It gets **stronger with every round of feedback** — read and honor `references/feedback-log.md` before building, and append any new preference the user gives.

## Non-negotiables (read first)

1. **Deliverable = ONE self-contained `.html`** that works offline and can be handed to another person. Embed EVERYTHING: photos (base64 JPEG), Leaflet library (inlined JS+CSS), and **map tiles (base64 PNG) so maps zoom offline**. No external fonts/CSS/JS/tile fetches at runtime. The only allowed external URLs are `<a>` links to Google Maps and attribution/credit links (user-initiated navigations, not resource loads).
2. **Korean output, English internal.** All page copy in Korean; all subagent prompts, research data, and inter-agent messages in English (token efficiency). See memory `feedback-english-internal-korean-output`.
3. **개조식 copy, not prose.** Concise, noun-ending fragments ("라벨: 핵심"), title + small subtitle structure. Scannable. Apply `humanize-korean` to any genuinely prose passages before shipping (memory `feedback-humanize-travel-deliverables`).
4. **NO em-dash (—) anywhere.** Use `·`, commas, or line breaks. Grep must return 0.
5. **Delegate to subagents.** Main session communicates; subagents research and build (memory `feedback-delegate-work-to-subagents`). Research subagents run in parallel.
6. **Never invent facts.** Verify hours/prices/access from official sites; flag uncertain items "확인 필요". Be honest about limits (it's a proposal, not a booking service): surface TODOs (reservations, ticket prices, flight confirmation).
7. **Design system = Airbnb** (see `references/design-airbnb.md`). White canvas, coral (#ff385c) accent, rounded cards/pills, soft hover shadow, photography-forward.
8. **Keep old files.** Never delete prior versions; write new deliverable alongside.

## Pipeline

### 1. Gather context
- Confirm/derive: destination, dates, travelers, theme (shopping? food? nature?), the user's personal tastes (drinks, hobbies, pace, wake time).
- Pull the user's **saved Google Maps shared lists** if relevant (Playwright, public, no login — scroll-scrape). For Kobe the shopping list URL is in memory `project-kobe-trip-2026-08`.
- Read any existing plan `.md` for that trip as the factual source of truth.

### 2. Research (parallel subagents, English)
Spawn focused research agents by dimension, e.g.: logistics (flights/transit/hotel), shopping by area, **dining by mealtime (아침/점심/저녁)**, **coffee·dessert**, **bars (맥주/위스키/사케 or the user's drink taste)**, activities/exhibits, swimming/fitness or the trip's hobby. Each returns structured English data: name (KO+native), area/station, signature, price band, hours+closed day, why-it-fits, caveats, source URL. Verify; flag unknowns.

### 3. Build the HTML (subagent)
Follow `references/build-and-verify.md` exactly (structure, tabs, offline map-tile embedding, file-handling for the huge base64 file, verification). Assemble facts from research + plan; personalize with the user's own map memos as coral pull-quotes (verbatim).

### 4. Verify (Playwright, in the build agent)
Offline (all external requests blocked) + mobile 400px. Confirm: every tab/sub-tab switches, maps render tiles+pins+zoom offline with invalidateSize on activation, cards render, 0 em-dashes, 0 external resource loads, no horizontal overflow, no console errors. Screenshot desktop + mobile.

### 5. Report (Korean) & save feedback
Summarize design/content decisions in Korean. When the user gives feedback, APPLY it and APPEND a dated entry to `references/feedback-log.md` so the next proposal inherits it.

## Standard deliverable structure
Cover hero (photo + eyebrow + title + subtitle + date pill) → topic tab bar. Tabs: **컨셉 / 숙소 / 일정 / 쇼핑 / 맛집·술 / 예산·팁** (adapt to theme). Sub-tabs: 일정→days, 쇼핑→areas, 맛집·술→아침/점심/저녁/술집/커피·디저트. Per-day: left map + right timeline (stack on mobile), walking badge, shop chips. Footer: photo credits + map attribution + Google Maps list link + 작성일.

Save deliverable in the trip's topic folder (e.g. `/mnt/f/04_여행/`), filename `{YYYY-MM} {목적지}여행 기획서.html`.
