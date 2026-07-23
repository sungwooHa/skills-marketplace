---
name: slide-craft
description: Build self-contained HTML report pages — dense one-pagers and printed report sets for executives and stakeholders — then prove they render correctly with a quantitative QA gate (font floor, fill ratio, clipping, zero external requests, PDF page count). Covers relationship/overview maps, timeline roadmaps, comparison/decision matrices, status dashboards, process/cycle diagrams, and multi-page report sets. Use for "보고 슬라이드", "조감도 스타일로", "A3 한 장으로", "경영진 보고 자료", "관계도 한 페이지", "로드맵 시각화", "대시보드 한 장", "비교표 슬라이드", "한 페이지로 정리해줘", "이런 식으로 표현해줘" (HTML slide context), and English "make a report slide", "one-pager", "wall chart", "roadmap graphic", "decision matrix slide". Also use to verify an existing slide before calling it done. NOT for talk decks with a presenter, speaker notes, or PPTX export — those go to the generate-presentation skill.
---

# slide-craft

Print/present-grade HTML slides that are **self-contained** (zero external resources) and
**verified by measurement** before anyone claims they are finished.

Two non-negotiables, everything else is selectable:

1. **No CDN, no external anything.** No icon webfonts, no remote CSS/JS/fonts/images. On an
   offline or firewalled corporate network every external glyph becomes a broken box — this
   has actually happened. Icons = system-safe glyphs (✓ ✕ … ! → ▲ ●) inside CSS badges.
   Decoration = inline SVG. Fonts = a system fallback stack.
2. **Measure before claiming done.** Run `scripts/slide_qa.py` (below). A slide that has not
   been rendered and measured is not finished, no matter how good the markup looks.

## Scope — and when to hand off instead

slide-craft owns the **page**: a dense, self-contained artifact that a reader takes in whole, at
their own pace, on screen or on paper. It does not own **talks**.

| The deliverable is… | Use |
|---|---|
| A one-pager / report page / wall chart / A3–A4 landscape PDF | **slide-craft** (this skill) |
| A set of report pages shipped as one printed document | **slide-craft**, `report-set` archetype |
| A talk: presenter, sequential 16:9 slides, speaker notes, PPTX export | **`generate-presentation`** (deck-harness plugin) — stop here and use it |

Signals that you are actually in deck-harness territory: someone will *present* this; there is a
time budget in minutes; a presenter-script view or PPTX is wanted; the audience sees one slide at
a time. deck-harness runs a full PLAN→BUILD→VERIFY pipeline with a plan-approval gate and a
5-axis critic panel — do not reimplement any of that here.

The doctrines genuinely differ and must not be blended: a talk slide wants **≥30% whitespace and
≤40 words**; a report page wants the page **filled**, because dead space on a one-pager reads as
an unfinished artifact rather than as breathing room.

## Step 1 — Intake (ask, don't guess)

Establish these before writing markup. If two or more are unknown and the answer changes the
layout, ask the user with 2–3 concrete options rather than picking silently.

| Question | Why it matters |
|---|---|
| Who reads it, at what distance? | Exec-in-a-room ⇒ presentation scale typography; desk read ⇒ denser |
| One page or a set? | Decides single-page archetypes vs `report-set` |
| Is the content **relational**, **temporal**, **comparative**, **quantitative**, or **sequential**? | This is the primary archetype key |
| Print (A3/A4 landscape PDF) or screen only? | Decides `@page` sizing and whether PDF page-count is a gate |
| Is there a source-of-truth document? | All facts/labels/numbers must derive from it — never invent |
| Does the project have a theme file? | See `references/theme.md` |

## Step 2 — Pick the archetype

Each archetype has a **distinct page economy and reading order** — that is what makes them
different, not the palette.

| Archetype | Content shape | Page economy | Reading order | Spec |
|---|---|---|---|---|
| **overview-map** | Relational — entities, layers, what sits on what | 1 page, ≤5 visual groups, full-bleed | Top→bottom (aspiration → layers → foundation) or left→right flow | `references/overview-map.md` |
| **timeline-roadmap** | Temporal — dates, phases, milestones | 1 page, N lanes × one time axis | Left→right along the calendar | `references/timeline-roadmap.md` |
| **report-set** | Argument that needs several pages | N pages, **one message per page** | Page 1→N as one document | `references/report-set.md` |
| **comparison-matrix** | Comparative — options × criteria, a decision | 1 page, options × criteria grid + verdict | Scan columns (criteria), settle on a row (option) | `references/comparison-matrix.md` |
| **status-dashboard** | Quantitative — KPIs, progress, health | 1 page, headline band + fixed tile grid | Headline numbers first, then drill tiles | `references/status-dashboard.md` |
| **process-flow** | Sequential/cyclical — steps, loops, flywheels | 1 page, one chain or one ring | Follow the arrows | `references/process-flow.md` |

**Decision rules, in order:**

0. Someone will stand up and present it → not this skill; hand off to `generate-presentation`.
1. Multiple distinct messages that cannot coexist on one page → **report-set**
   (each page inside it then picks one of the single-page archetypes).
2. Every element carries a date or duration → **timeline-roadmap**.
3. The deliverable is a recommendation among named options → **comparison-matrix**.
4. Numbers are the subject, not the illustration → **status-dashboard**.
5. Order is logical (step 1 causes step 2) and may loop → **process-flow**.
6. Otherwise, structure is "what contains/feeds what" → **overview-map**.

Ambiguous? Ask. Example: *"Roadmap content, but you also want the org structure. Two options:
(a) timeline-roadmap with owners as lane labels, (b) a 2-page report-set — structure page
then timeline page. Which?"* Do not merge two archetypes onto one page; that is the single
most common cause of an unreadable slide.

**Load only the chosen archetype's reference file.** Do not read all six.

## Step 3 — Theme

Read `references/theme.md`. Short version: if the project root has `slide-theme.json` (or
`slide-theme.md`), its tokens win. Otherwise use the neutral default token set in that file.
Never hard-code a domain's color semantics into a layout — semantics belong in the theme.

## Step 4 — Universal craft rules

These apply to every archetype (they are layout-agnostic; content/tone rules belong to the
consuming project, not to this skill):

- **Typography is the hierarchy.** Category title (large) > item identifier (medium) >
  detail (small). Never explain hierarchy in words that the sizes should convey.
- **Presentation-scale floor.** On a 1600px page: body text ≥13px, titles/identifiers ≥16px.
  13px is the floor, not the target — judge at 50% zoom (viewing-distance simulation).
- **Full-width groups must be filled.** A one-line item stretched across a 1600px box leaves
  dead space that reads as emptiness, not as whitespace. Either the content fills the width or
  the box shrinks to the content. Chip/tag rows must distribute across the width, not clump left.
- **Parallel items get parallel weight.** Side-by-side peer boxes match in line count, size and
  visual weight. Differing sizes imply differing rank — only use that when rank actually differs.
- **Visual containment = conceptual containment.** If A is "inside" B in the text, draw A inside
  B's box. Adjacency is not containment.
- **Don't narrate the artifact.** No "how to read this", no "Q1–Q4" scaffolding labels, no
  meta-commentary about the document's own purpose. Layout carries that.
- **Unconfirmed ≠ confirmed.** Draw provisional items dashed/muted; keep the qualifier.
- **Facts come from the source document only.** No invented dates, numbers or names.

## Step 5 — Verify (mandatory before reporting done)

```bash
python3 <skill_dir>/scripts/slide_qa.py <slide.html> --out /tmp/slide-qa
# multi-page / print check
python3 <skill_dir>/scripts/slide_qa.py <slide.html> --out /tmp/slide-qa \
        --pdf --page-size A3-landscape --expect-pages 1
# tune the gates for a non-1600px page
python3 <skill_dir>/scripts/slide_qa.py <slide.html> --width 1280 --font-floor 12
```

The script renders with Playwright/Chromium and hard-fails on: text under the font floor,
full-width boxes under the occupancy threshold, elements clipped outside the document,
**any external resource request** (the No-CDN rule, enforced by network interception),
low-contrast text, and — with `--pdf` — a PDF page count different from `--expect-pages`.
Absolute-position overlaps are reported but are **not** an automatic fail (some overlap is
intentional layering); every reported pair must still be judged by eye.

**Measurement passing is not completion.** The script writes a full-size PNG and a 50%-scale
PNG. Open both with the Read tool and actually look at them: hierarchy, intended-vs-accidental
whitespace, overlap pairs, containment. Report done only after that.

Setup, if Playwright is missing: `pip install playwright && playwright install chromium`.

**Why this and not deck-harness's `build-verifier`:** that agent verifies the deck contract —
it asserts `#deck .slide` exists, requires a presenter-script file, and checks PPTX integrity. It
cannot run against a standalone one-pager, and its whitespace doctrine is the inverse of this
one's. If you are producing a talk deck, use `build-verifier`; for a report page, use this script.

## Files

- `references/theme.md` — theming contract, neutral default tokens, worked example
- `references/<archetype>.md` — layout spec + HTML skeleton per archetype
- `scripts/slide_qa.py` — the verification gate (self-contained, stdlib + Playwright)
