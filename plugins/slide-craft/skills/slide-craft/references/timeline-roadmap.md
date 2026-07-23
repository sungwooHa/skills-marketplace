# timeline-roadmap — single-page time axis

**Use when** every element carries a date or a duration. If some elements are undated, they are
not roadmap content — move them to a legend, a lane label, or another page.

**Page economy** — one page. One shared horizontal time axis owns the full content width; each
lane is a horizontal band across it. 2–4 lanes is the workable range; 5+ lanes forces the band
height below readable. Vertical space budget: axis header ~60px, each lane ~110–160px, an
optional bottom band for the commitment/summary.

**Reading order** — strictly left→right along the calendar. The eye must never be asked to jump
back. Consequence: **horizontal position is data, not layout.** Every box's `left` and `width`
must be computed from its real dates.

## The position rule

Map dates to percentages once, at the top of the CSS, and never place anything by eye:

```
left%  = (start - axisStart) / (axisEnd - axisStart) * 100
width% = (end   - start)     / (axisEnd - axisStart) * 100
```

A phase box whose number sits over the wrong month is the single most common roadmap defect,
and it is invisible in code review — it only shows in the render. Check it in the PNG.

## Lane grammar

- **Lanes are your own work.** If a lane belongs to another team and is drawn from *their*
  internal perspective while your other lane is from yours, the page has two incompatible axes.
  Restate everything in one owner's terms.
- **External dates are reference markers, not lanes.** Someone else's launch date becomes a thin
  vertical marker with a *smaller, lower-contrast* label than your own phase labels. If a
  reference marker is drawn at the same weight as a phase, the reader cannot tell whose work is
  whose.
- **Outputs must be wired to the work that produces them.** A milestone floating on an "assets"
  lane above a "work" lane, with no connector, reads as an unsupported claim. Draw the drop
  connector from the work that creates it, and phrase the rider as *action → expected result*,
  never as a static precondition ("already in place").
- **Quarter/period shading** behind the lanes gives the eye its coarse grid; month ticks give the
  fine grid. Both belong to the axis, not to any lane.

## Skeleton

```html
<style>
/* tokens from references/theme.md */
.axis{position:relative;height:34px;margin:0 0 8px;border-bottom:1.5px solid var(--line)}
.tick{position:absolute;top:0;bottom:0;width:1px;background:#e3e9f3}
.tick .lab{position:absolute;top:6px;left:6px;font-size:13px;font-weight:800;color:var(--muted);white-space:nowrap}
.band{position:absolute;top:0;bottom:0;background:#f4f7fc}          /* quarter shading */

.lane{position:relative;border:1.5px solid var(--line);border-radius:15px;background:var(--card);
      padding:14px 0 14px 0;margin-bottom:12px;min-height:120px}
.lane .lname{position:absolute;left:0;top:0;bottom:0;width:150px;display:grid;place-items:center;
             border-right:1.5px solid #eef2f7;font-size:17px;font-weight:800;color:var(--deep)}
.plot{position:relative;margin-left:150px;height:100%}              /* % coordinates live here */

.phase{position:absolute;top:14px;height:56px;border-radius:11px;padding:8px 12px;
       border:1px solid var(--s1-line);background:var(--s1-soft);overflow:hidden}
.phase .pn{font-size:16px;font-weight:800;color:var(--s1)}          /* stage label: LARGE */
.phase p{font-size:13px;line-height:1.45;margin-top:3px}

.marker{position:absolute;top:0;bottom:0;width:2px;background:#c9d6ea}   /* external reference */
.marker .mlab{position:absolute;top:-2px;left:5px;font-size:11.5px;font-weight:700;
              color:var(--muted);white-space:nowrap}                     /* SMALLER than .pn */
.marker.join{width:3px;background:var(--alert)}

.wire{position:absolute;border-left:2px dashed var(--s5-line)}      /* work → output connector */
.out{position:absolute;height:40px;border-radius:9px;background:var(--deep);color:#fff;
     display:grid;place-items:center;padding:0 14px;font-size:14px;font-weight:800}
</style>

<div class="slide">
  <div class="header">…</div>

  <div style="margin-left:150px">
    <div class="axis">
      <div class="band" style="left:0%;width:33.3%"></div>
      <div class="tick" style="left:0%"><span class="lab">Jul</span></div>
      <div class="tick" style="left:16.6%"><span class="lab">Sep</span></div>
      <div class="tick" style="left:50%"><span class="lab">Dec</span></div>
    </div>
  </div>

  <div class="lane">
    <div class="lname">Workstream A</div>
    <div class="plot">
      <div class="phase" style="left:0%;width:28%">
        <div class="pn">1st goal</div><p>what is complete at the end of this window</p>
      </div>
      <div class="marker" style="left:41%"><span class="mlab">ext. release</span></div>
      <div class="wire" style="left:28%;top:70px;height:40px"></div>
      <div class="out" style="left:24%;top:110px">Output produced by the phase above</div>
    </div>
  </div>
</div>
```

## Archetype-specific failure modes

- Boxes placed by eye; label sits over the wrong tick.
- A reference marker rendered as large as a phase label.
- Outputs and work drawn as two parallel lanes with no causal connector.
- Empty stretches of axis with no ticks or labels — then the emptiness reads as an error rather
  than as "nothing is scheduled here." Keep the grid visible across the full width.
- Riders written as prose or metaphor. Roadmap riders are terse and nominal.
- Period cells described by activity intensity ("ramp-up", "in progress") instead of the state
  reached by the end of that period ("migration complete").
