# comparison-matrix — options × criteria, resolved into a decision

**Use when** the deliverable is a *choice*: alternatives evaluated against shared criteria, with
a recommendation. If there is no recommendation and no criteria, it is not this archetype — it
is a status-dashboard or an overview-map.

**Page economy** — one page. A grid of `options × criteria`, plus a verdict region. Practical
limits: **2–4 options, 4–7 criteria**. Beyond that, cells drop under the readable font floor;
promote the overflow to an appendix and keep only decision-relevant criteria on the page. Budget
roughly: header 12%, criteria/option grid 60%, verdict band 20%, footnotes 8%.

**Reading order** — column-then-row. The reader scans a criterion across all options to see the
spread, repeats for each criterion, and *lands on one row*. Two consequences:

- **Criteria are the columns' identity and must be self-evident** — a criterion needing an
  explanation sentence is really two criteria.
- **The recommended option must be visually resolved,** not left for the reader to compute.
  Highlight the recommended row and state the verdict in words in the band. A matrix that ends
  in a tie is an unfinished analysis, not a neutral one.

## Orientation choice

- **Options as rows, criteria as columns** (default) — best for 3–4 options; the recommended row
  can be emphasized as a whole band, which is the strongest possible visual verdict.
- **Options as columns** — use when each option needs a paragraph per criterion rather than a
  rating. Then it becomes 2–3 tall panels side by side; keep panel line-counts equal.

## Rating vocabulary

Pick exactly one scale and use it in every cell. Never mix.

- Glyph scale: `●` full / `◐` partial / `○` none / `—` n/a — self-contained, no icon font.
- Short verdict words: `strong` / `adequate` / `gap`.
- Numbers only when they are real measurements, with units in the column header.

Encode strength with the *glyph*, and use color only as reinforcement — a color-only matrix
fails for print and for color-blind readers.

## Skeleton

```html
<style>
.matrix{display:grid;gap:10px;position:relative;z-index:2}       /* rows are grid rows */
.mrow{display:grid;grid-template-columns:250px repeat(var(--cols),1fr);gap:10px;align-items:stretch}
.mhead{font-size:14px;font-weight:800;color:var(--deep);padding:10px 12px;
       background:#f4f7fc;border-radius:10px;display:grid;place-items:center;text-align:center}
.mhead .unit{display:block;font-size:11.5px;font-weight:600;color:var(--muted);margin-top:2px}
.opt{background:var(--card);border:1.5px solid var(--line);border-radius:12px;padding:12px 14px}
.opt .on{font-size:19px;font-weight:800;color:var(--deep)}       /* option identifier: LARGE */
.opt .od{font-size:12.5px;color:var(--muted);line-height:1.5;margin-top:5px}
.cell{border:1px solid var(--line);border-radius:12px;padding:11px 13px;background:var(--card);
      display:flex;flex-direction:column;gap:5px}
.cell .rate{font-size:19px;font-weight:800;line-height:1}
.cell .rate.full{color:var(--s4)} .cell .rate.part{color:var(--s5)} .cell .rate.none{color:var(--muted)}
.cell p{font-size:12.8px;line-height:1.45}

.mrow.pick .opt,.mrow.pick .cell{border-color:var(--s1);border-width:2px;background:var(--s1-soft)}

.verdict{margin-top:14px;background:linear-gradient(120deg,var(--deep2),#123a86);border-radius:15px;
         padding:18px 26px;display:flex;gap:24px;align-items:center;color:#fff}
.verdict .vt{flex:0 0 300px;font-size:20px;font-weight:800;line-height:1.35}
.verdict .vt em{font-style:normal;color:var(--accent)}
.verdict .vb{flex:1;font-size:13.5px;line-height:1.6;color:#dce7fa}
.foot{margin-top:10px;font-size:12px;color:var(--muted);line-height:1.5}
</style>

<div class="slide">
  <div class="header">…</div>
  <div class="matrix" style="--cols:4">
    <div class="mrow">
      <div class="mhead" style="background:none"></div>
      <div class="mhead">Criterion A</div>
      <div class="mhead">Criterion B<span class="unit">months</span></div>
      <div class="mhead">Criterion C</div>
      <div class="mhead">Criterion D</div>
    </div>

    <div class="mrow pick">
      <div class="opt"><div class="on">Option 1</div><div class="od">one-line description</div></div>
      <div class="cell"><span class="rate full">●</span><p>evidence</p></div>
      <div class="cell"><span class="rate full">3</span><p>evidence</p></div>
      <div class="cell"><span class="rate part">◐</span><p>evidence</p></div>
      <div class="cell"><span class="rate full">●</span><p>evidence</p></div>
    </div>

    <div class="mrow">
      <div class="opt"><div class="on">Option 2</div><div class="od">one-line description</div></div>
      <div class="cell"><span class="rate part">◐</span><p>evidence</p></div>
      <div class="cell"><span class="rate none">9</span><p>evidence</p></div>
      <div class="cell"><span class="rate full">●</span><p>evidence</p></div>
      <div class="cell"><span class="rate none">○</span><p>evidence</p></div>
    </div>
  </div>

  <div class="verdict">
    <div class="vt">Recommendation: <em>Option 1</em></div>
    <div class="vb">Why it wins, and what we accept by choosing it.</div>
  </div>
  <div class="foot">● meets · ◐ partial · ○ does not meet — criteria and evidence from &lt;source&gt;</div>
</div>
```

## Archetype-specific failure modes

- Ragged rows: option 1's cells are one line, option 2's are four. Equalize by trimming evidence
  to the decisive fact, not by padding the short ones.
- Criteria that are really the same criterion twice (cost / budget impact).
- Color-only ratings.
- No visible recommendation.
- Ratings that flatter the preferred option — the analysis must survive a reader who disagrees.
  A recommended option with zero weak cells is usually a sign the criteria were chosen backwards
  from the conclusion; show the trade-off you are accepting in the verdict band.
- Marking an option as recommended when the decision is actually still open — draw it as an
  open comparison with the pending question stated, rather than manufacturing a verdict.
