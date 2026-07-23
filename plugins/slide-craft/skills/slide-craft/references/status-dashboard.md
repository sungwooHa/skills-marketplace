# status-dashboard — one page where the numbers are the subject

**Use when** the reader's question is "where are we?" and the answer is quantitative: KPIs,
progress against targets, health by area. If the numbers merely illustrate a story, you want a
different archetype — here the numbers *are* the story.

**Page economy** — one page, two zones with a fixed budget:

- **Headline band (~25% of height):** 3–5 numbers, and nothing else. These are the numbers the
  reader repeats afterwards.
- **Tile grid (~65%):** a regular grid — 3×2, 4×2 or 4×3. **Uniform tiles.** Every tile the same
  size unless one is deliberately double-width, and then exactly double.
- **Footer (~10%):** as-of date, source, and definition notes.

Never exceed 12 tiles. A 16-tile dashboard is a spreadsheet screenshot.

**Reading order** — headline numbers first (large, left to right), then the tile grid scanned
row-major. This is the only archetype where the eye is *supposed* to bounce; the grid must be
regular enough that bouncing is cheap. Irregular tile sizes destroy this.

## Rules specific to numbers

- **Every number carries its unit and its comparison.** `72%` alone is unreadable; `72% (target
  85%)` or `72% ▲6pp vs. last month` is a status. A number without a reference point cannot be
  good or bad.
- **The number is the largest type in its tile** — larger than the tile label. If the label is
  bigger than the value, the tile is a text box pretending to be a metric.
- **Direction glyphs, not icon fonts:** `▲ ▼ ▬`. Color reinforces but never carries alone.
- **State the as-of date once, prominently.** A dashboard without a timestamp is a rumor.
- **Do not draw a target line you do not have.** Missing target = show the value and say the
  target is not set, rather than inventing one.
- **Progress bars must be to scale.** A bar at 60% width for a 45% value is a fabricated fact —
  it fails the same way an off-scale timeline does.

## Skeleton

```html
<style>
.kpis{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:16px;position:relative;z-index:2}
.kpi{background:linear-gradient(120deg,var(--deep2),#173f8f);border-radius:15px;padding:18px 22px;
     border-top:3px solid var(--accent);color:#fff}
.kpi .klab{font-size:13px;font-weight:700;color:#cfe0fb;letter-spacing:.2px}
.kpi .kval{font-size:46px;font-weight:800;line-height:1.05;margin-top:6px;letter-spacing:-1.5px}
.kpi .kval small{font-size:20px;font-weight:700;margin-left:3px}
.kpi .kdelta{font-size:13px;font-weight:800;margin-top:6px;color:var(--accent)}

.tiles{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;position:relative;z-index:2}
.tile{background:var(--card);border:1.5px solid var(--line);border-radius:14px;padding:14px 16px;
      display:flex;flex-direction:column;gap:8px;min-height:150px}
.tile.wide{grid-column:span 2}
.tile .tlab{font-size:14px;font-weight:800;color:var(--deep)}
.tile .tval{font-size:32px;font-weight:800;line-height:1;color:var(--ink)}
.tile .tval small{font-size:15px;color:var(--muted);font-weight:700;margin-left:4px}
.tile .tnote{font-size:12.5px;color:var(--muted);line-height:1.45;margin-top:auto}
.up{color:var(--s4)} .down{color:var(--s5)} .flat{color:var(--muted)}

.bar{height:9px;border-radius:5px;background:#eef2f8;overflow:hidden;position:relative}
.bar i{display:block;height:100%;background:var(--s1);border-radius:5px}   /* width = real % */
.bar .target{position:absolute;top:-3px;bottom:-3px;width:2px;background:var(--deep)}

.foot{margin-top:14px;display:flex;justify-content:space-between;font-size:12.5px;color:var(--muted)}
</style>

<div class="slide">
  <div class="header">…</div>

  <div class="kpis">
    <div class="kpi"><div class="klab">Headline metric</div>
      <div class="kval">72<small>%</small></div>
      <div class="kdelta">▲ 6pp vs. last month · target 85%</div></div>
    <!-- 3–5 total -->
  </div>

  <div class="tiles">
    <div class="tile">
      <div class="tlab">Area</div>
      <div class="tval">12<small>/ 18</small></div>
      <div class="bar"><i style="width:66.7%"></i><span class="target" style="left:85%"></span></div>
      <div class="tnote"><span class="up">▲</span> +2 this period · target line at 85%</div>
    </div>
    <div class="tile wide">
      <div class="tlab">Area needing two columns</div>
      <div class="tval">3.4<small>days</small></div>
      <div class="tnote"><span class="flat">▬</span> flat · definition note</div>
    </div>
  </div>

  <div class="foot"><span>As of YYYY-MM-DD</span><span>Source: &lt;system / document&gt;</span></div>
</div>
```

## Archetype-specific failure modes

- Bare numbers with no target, baseline or delta.
- Tile labels typographically louder than the values.
- Irregular tile sizes that break row-major scanning.
- Progress bars not drawn to scale.
- Prose paragraphs smuggled into tiles — a tile holds a value, a comparison, and at most one
  short note. Longer explanation belongs on a different page.
- No as-of date.
- Red/green as the only carrier of good/bad.
