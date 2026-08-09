# Component library

Self-contained HTML+inline-CSS blocks. No CDN, no webfont, no remote asset — the Korean sans stack falls back to the OS font. Every file opens standalone in a browser at 1280×720 and screenshots via `.slide`.

Numbers here implement `../design-grammar.md` §0. **Change the grammar first, then the components.**

| File | Component | Axis it serves | Key numbers |
|---|---|---|---|
| `_base.css` | token sheet (readable copy; inlined into every component) | — | palette, radius, shadow |
| `00-canvas.html` | slide canvas 1280×720 + footer | 스펙 | content box 46…1234 · footer y682 |
| `01-eyebrow-headline.html` | eyebrow + 44px headline + keyword highlight | **E** 강약 | 44/800 · lh56 · ≤2 lines · 1 highlight |
| `02-meta-row.html` | one-line meta row (조연 강등) | **E** 강약 | 22.4px · label 100px · pitch 44 · ≤2 rows |
| `03-icon-card-row.html` | N columns in ONE card, divider-split | **E**+**G** | 3~5 cols · flex 1 1 0 · desc 12~13자×3 |
| `04-stat-container.html` | stats merged into one vessel | **G** 그룹화 | h206 · 3-way split 396 · divider #F0F0F2 |
| `05-dark-callout-image.html` | dark callout with flush image | **G**+**A** | photo 574 flush right · bullet ≤28자 1행 |
| `06-wide-card.html` | wide horizontal card 2×2 grid | **R** 가독성 | 586×227 · text col 367 · bullet 20~23자 |
| `07-image-slot.html` | image slot / placeholder | **A** 에셋 | cover + object-position only |

## Assembly order

```
00-canvas
  └ 01-eyebrow-headline          (always, exactly one)
    └ 02-meta-row                (optional, ≤2 rows)
      └ ONE body block:
          03-icon-card-row                      → y329 (headline 2행 + meta 2행)
          04-stat-container + 05-dark-callout   → y226 (headline 2행)
          06-wide-card grid                     → y177 (headline 1행)
```

The body block's `top` is a function of how tall the head is. Pick from {177, 226, 329} — never a fresh number.

## Combining 04 + 05 into one seamless block

Put both inside one `.block` that owns `border-radius:16px; overflow:hidden`. The children (`.stats`, `.dark`) get **no** radius of their own — that is what erases the seam and turns two tiers into one visual object.

```html
<div class="block">          <!-- radius + overflow:hidden + shadow live here -->
  <div class="stats">…</div> <!-- height 206, white -->
  <div class="dark">…</div>  <!-- flex:1,  #1A1A1A, photo flush right -->
</div>
```

## Assembled examples

`../examples/` — three reference slides (one per axis) and `smoke-test.html`, a fourth slide built from these components with unrelated copy to prove they compose.
