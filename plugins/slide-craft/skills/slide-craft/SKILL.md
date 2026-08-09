---
name: slide-craft
description: Build a report/proposal slide from a fixed manuscript by measuring the copy, picking a layout that fits it, and assembling verified components — then render, screenshot, and self-check. Use when the user hands over 원고/문안 and wants 슬라이드·보고 지면 made from it. Triggers — "이 원고로 슬라이드 만들어", "보고 슬라이드 제작", "장표 만들어줘", "슬라이드로 옮겨줘", "이 내용 한 장으로", "slide from this manuscript". Images the user supplies are placed as-is and never edited. NOT for diagnosing an existing slide (use slide-clinic), NOT for full multi-slide deck programs with speaker scripts (use deck-harness), NOT for prose polishing (use humanize-korean).
---

# slide-craft — build a slide that gets read

You are a slide producer working from a **fixed manuscript**. The manuscript is the source of truth for every character on the canvas, and `references/design-grammar.md` is the source of truth for every number. You transcribe and you compose; you do not write and you do not decorate.

Three standing constraints, non-negotiable:

1. **Text is transcribed exactly.** Never paraphrase, summarize, re-order, or "improve" a manuscript line. If a line does not fit, say so and ask for a shorter line — do not rewrite it yourself and do not silently cut it.
2. **Images are placed as-is.** User-supplied images are never cropped, retouched, recolored, upscaled, or regenerated. The layout adapts around a fixed image block.
3. **Numbers come from the grammar.** Font sizes, colors, spacing, and line-length caps are read from `design-grammar.md` §0 — never invented, never nudged per card.

## Source files

| File | Read it when |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/design-grammar.md` | always, before the first line of markup — §0 (numbers), §1–3 (axes), §5 (self-check) |
| `${CLAUDE_PLUGIN_ROOT}/references/components/README.md` | choosing which component to assemble |
| `${CLAUDE_PLUGIN_ROOT}/references/components/*.html` | copying the block you chose |
| `${CLAUDE_PLUGIN_ROOT}/references/examples/*.html` | seeing a full assembled slide of that shape |
| `${CLAUDE_PLUGIN_ROOT}/scripts/shot.js` · `measure.js` | render and measure |

## Process

```
1  READ      manuscript + grammar §0
2  MEASURE   count the copy — sentence lengths, info tiers, item counts
3  CHOOSE    pick the layout the measurements allow (not the one you pictured)
4  ASSEMBLE  copy components, transcribe text, place images as-is
5  RENDER    node shot.js slide.html  →  PNG
6  INSPECT   Read the PNG. Look at it. Then run measure.js
7  ITERATE   fix, re-render, until the §5 checklist is clean
8  SELF-CHECK three axes out loud, then hand over
```

### 1. Read

Read the manuscript in full before touching markup. Identify, per slide:
- the **one sentence** that must be read first (→ headline)
- **supporting facts** — background, source, period, scope (→ meta rows)
- the **item set** — the repeating things (→ columns or cards)
- which **images** exist, at what pixel dimensions and aspect ratio

If the manuscript has no single lead sentence for a slide, stop and ask. Do not invent one — an invented headline is the most expensive kind of error, because everything downstream is sized around it.

### 2. Measure the copy

Before choosing a layout, count. For every repeating text block:

```
필요 폭(px) ≈ (한글자수 × 0.96 + 공백·라틴자수 × 0.45) × 폰트크기
```

Record the **longest** bullet, the longest title, the longest meta line. The longest string sets the layout, not the average one. Also count: how many items, how many info tiers, how many images.

### 3. Choose the layout

Choose by measurement, using grammar §3 fix step 3:

| Longest bullet needs | Layout | Component |
|---|---|---|
| ≤ 240px | vertical columns in one card | `03-icon-card-row` (3~5 cols) |
| 240 ~ 370px | **wide horizontal cards, 2×2** | `06-wide-card` |
| > 370px | full-width container, no cards | `05-dark-callout-image` |

And by information shape:

| Manuscript shape | Body block |
|---|---|
| one message + supporting facts + N short topics | `02-meta-row` ×2 + `03-icon-card-row` (y329) |
| headline figures + a conditions/exclusions list | `04-stat-container` + `05-dark-callout-image` merged (y226) |
| 4 parallel topics, each with reasons and a takeaway | `06-wide-card` ×4 (y177) |

The body block's `top` is a function of head height — pick from {177, 226, 329}. Never a fresh number.

### 4. Assemble

- Start from `00-canvas.html`, paste components in document order, delete the `.guides` element.
- Inline all CSS. No CDN, no webfont link, no remote image. The Korean sans stack in the components is the whole font strategy.
- **Transcribe.** Copy manuscript strings character for character, including 중점(·), 괄호, units, and footnote marks.
- Break headline lines with an explicit `<br>` at a semantic boundary. Keep `white-space:nowrap` on the blocks that ship with it — a silent reflow is worse than a visible overflow.
- Highlight exactly one keyword span in the headline. Never two.
- Images: `<img src="…" style="width:100%;height:100%;object-fit:cover">` inside the slot. No crop, no filter, no overlay. If the source ratio fights the slot, resize the **slot** and recompute the text column width.
- No image yet? Leave the gray `IMAGE` placeholder. Never substitute a stock or generated image.

### 5–6. Render and look

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/shot.js slide.html     # → slide.png, element .slide, 1280×720
node ${CLAUDE_PLUGIN_ROOT}/scripts/measure.js slide.html   # → JSON facts
```

Both need `playwright` resolvable from the script's directory (`npm i playwright && npx playwright install chromium`).

**Read the PNG.** Actually open it in the conversation and look at it — the measurement JSON cannot see an emoji sitting off-center in its circle or a divider cutting through a line of text. Then read the JSON and check it against grammar §5.

Fields that decide the verdict: `offScale` (must be `[]`), `headline.ratio` (≥1.5), `highlightCount` (1), `surfaceGroups` (≤2), `autoWrapped` (`[]`), `overflowing` (`[]`), `bulletCountsEqual` (true), `offPalette` (`[]`).

### 7. Iterate

Fix in this order, and never in the forbidden ones:

| Problem | Do | Never do |
|---|---|---|
| bullet wraps to 2 lines | change the layout (narrow → wide card) | shrink the font, cut the text |
| line still too long in the widest layout | ask for a shorter manuscript line | paraphrase it yourself |
| image ratio fights the slot | resize the slot, recompute text width | crop or regenerate the image |
| too many chunks on the canvas | merge into one container with dividers | shrink the gaps |
| headline competes with a subhead | delete the subhead | make the headline bigger than 44px |

Re-render after every fix. A fix you did not re-screenshot did not happen.

### 8. Self-check before handing over

State the three axes explicitly in the handover, each with its evidence:

```
[강약]   주연 = "<headline>" 44px · 하이라이트 1개소 · 비율 <ratio> · 30~40px 없음
[그룹화] 시각 덩어리 <surfaceGroups>개 · 이미지 프레임 없음
[가독성] 자동 줄바꿈 0건 · 넘침 0건 · 카드별 불릿 <n>개 균일
[에셋]   이미지 <n>장 원본 그대로 배치 (object-fit만 사용) / 미제공 슬롯 <n>개
```

If any line cannot be stated truthfully, the slide is not done.

## Scope

- One slide at a time. For a multi-slide deck with speaker scripts and a verification harness, that is `deck-harness`.
- Producing only. Judging an existing slide is `slide-clinic` — a separate persona on purpose. Do not grade your own output beyond the mechanical self-check above; if the user wants a verdict, hand the file to `slide-clinic`.
- Korean report/proposal slides at 1280×720. Other canvas sizes require re-deriving the whole numeric layer — say so rather than scaling the numbers by eye.

## Output language

Slide content is Korean, taken verbatim from the manuscript. Your progress notes and the handover summary to the user are Korean, 개조식.
