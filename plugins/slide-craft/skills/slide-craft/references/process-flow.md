# process-flow — one page, one chain or one ring

**Use when** the ordering is *logical*: step 1 causes step 2, and the sequence may close into a
loop. Distinct from overview-map (which shows containment, not order) and from timeline-roadmap
(which is ordered by the calendar, not by causation). If your steps have dates, use the timeline.

**Page economy** — one page, **one flow**. Two flows on one page means the reader must decide
which to follow first, and they will pick wrong. Two variants:

- **Linear chain:** 3–6 stages across the full width, each stage an equal-width panel with an
  arrow between. Below the chain, an optional detail band aligned to the stages.
- **Cycle / flywheel:** one ring, 3–5 segments, drawn as inline SVG. Center holds the name of
  the loop and what it accumulates. Around it, the segment labels. Do not put more than one ring
  on a page.

**Reading order** — follow the arrows, and the arrows must be unambiguous. For a linear chain
that means one direction only. For a ring it means the rotation direction is visibly stated by
arrowheads, and the entry point is marked — a ring with no marked entry is a picture, not a
process.

## Rules

- **Equal weight for equal steps.** All stage panels the same width, same line count, same type
  scale. A wider panel implies a bigger step. If one step really is bigger, say so in words
  rather than by geometry.
- **Every arrow is labeled with what moves.** "→" alone says only "then"; "→ *draft*" says what
  is handed over. The exception is a pure cycle where the whole ring has one labeled motion.
- **A loop must state what accumulates.** A flywheel that returns to its start with nothing
  gained is a circle. Put the accumulating quantity in the ring's center.
- **Feedback edges look different from forward edges** — dashed, thinner, on the opposite side.
- **Provisional steps are dashed and muted.** Do not draw a step you have not built as a solid
  part of the chain.

## SVG ring — self-contained

Inline SVG only, no libraries. Arrowheads via `<marker>`; text inherits the body font stack via
the `svg text{font-family:inherit}` reset in the theme.

```html
<svg viewBox="0 0 720 460" width="720" height="460" fill="none">
  <defs>
    <marker id="ah" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7"
            orient="auto-start-reverse">
      <path d="M0 0 L10 5 L0 10 z" fill="var(--s1)"/>
    </marker>
  </defs>

  <!-- three arcs of one ring; each ends in an arrowhead so rotation is unambiguous -->
  <path d="M360 60 A170 170 0 0 1 507 315" stroke="var(--s1)" stroke-width="14"
        stroke-linecap="round" marker-end="url(#ah)"/>
  <path d="M493 340 A170 170 0 0 1 227 340" stroke="var(--s2)" stroke-width="14"
        stroke-linecap="round" marker-end="url(#ah)"/>
  <path d="M213 315 A170 170 0 0 1 346 60"  stroke="var(--s3)" stroke-width="14"
        stroke-linecap="round" marker-end="url(#ah)"/>

  <text x="360" y="222" text-anchor="middle" font-size="20" font-weight="800"
        fill="var(--deep)">Loop name</text>
  <text x="360" y="248" text-anchor="middle" font-size="14"
        fill="var(--muted)">what accumulates each turn</text>

  <text x="560" y="150" font-size="17" font-weight="800" fill="var(--s1)">Stage 1</text>
  <text x="360" y="425" text-anchor="middle" font-size="17" font-weight="800"
        fill="var(--s2)">Stage 2</text>
  <text x="60"  y="150" font-size="17" font-weight="800" fill="var(--s3)">Stage 3</text>
</svg>
```

## Linear chain skeleton

```html
<style>
.chain{display:flex;align-items:stretch;gap:0;position:relative;z-index:2}
.step{flex:1;min-width:0;border:1.5px solid var(--line);border-radius:14px;background:var(--card);
      padding:16px 18px;display:flex;flex-direction:column;gap:8px}
.step.provisional{border-style:dashed;background:#fbfcfe;color:var(--muted)}
.step .sn{font-size:13px;font-weight:800;letter-spacing:.4px;color:var(--s1)}
.step .st{font-size:20px;font-weight:800;color:var(--deep);line-height:1.25}
.step p{font-size:13px;line-height:1.5}
.arrow{flex:0 0 78px;display:grid;place-items:center;position:relative}
.arrow .g{font-size:24px;font-weight:800;color:#b9c6dd;line-height:1}
.arrow .al{position:absolute;bottom:22px;font-size:12px;font-weight:700;color:var(--muted);
           white-space:nowrap}                     /* what is handed over */
.feedback{margin-top:10px;border-top:2px dashed var(--s5-line);position:relative;height:34px}
.feedback .fl{position:absolute;top:6px;left:50%;transform:translateX(-50%);font-size:12.5px;
              font-weight:700;color:var(--alert)}
</style>

<div class="chain">
  <div class="step"><div class="sn">01</div><div class="st">Stage</div><p>what happens</p></div>
  <div class="arrow"><span class="g">→</span><span class="al">handoff</span></div>
  <div class="step"><div class="sn">02</div><div class="st">Stage</div><p>what happens</p></div>
  <div class="arrow"><span class="g">→</span><span class="al">handoff</span></div>
  <div class="step provisional"><div class="sn">03</div><div class="st">Stage</div><p>not built yet</p></div>
</div>
<div class="feedback"><span class="fl">↰ feedback: what returns to stage 01</span></div>
```

## Archetype-specific failure modes

- Two flows on one page.
- Unlabeled handoffs.
- Unequal step panels implying unintended rank.
- A ring whose rotation direction or entry point is not visible.
- A loop with no stated accumulation.
- Absolutely-positioned SVG labels overlapping the arcs — this archetype produces the most
  overlap findings in QA; check every reported pair in the PNG and reposition rather than
  dismissing them.
