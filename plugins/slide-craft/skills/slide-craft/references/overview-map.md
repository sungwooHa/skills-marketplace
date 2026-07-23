# overview-map — single-page relationship / structure map

**Use when** the content is *relational*: entities, layers, what contains what, what feeds what.
The reader should be able to point at the page and say "so that sits on top of that."

**Page economy** — one page, full bleed, **at most 5 visual groups**. Every group earns its
place; a sixth group means something belongs on a second page (→ report-set) or belongs in
an appendix. Density target: the page is *filled*, not crowded — no group thinner than ~90px,
no group taller than ~40% of the page.

**Reading order** — two valid grammars. Pick one and commit; mixing them is the failure mode.

- **Vertical (default):** aspiration → layers → foundation. Header, then a hero band carrying
  the one framing message, then the stacked entity cards, then a dark foundation band at the
  bottom holding whatever everything else rests on.
- **Horizontal:** when the truth of the page is a left→right flow (producer → shared middle →
  consumer). Use three column panels, not vertical cards, and **label every arrow with its
  direction's meaning** (build/read, write/serve). An unlabeled arrow between columns is a
  guess invitation.

## Components

| Slot | Purpose | Notes |
|---|---|---|
| `.header` | Large title + one-line subtitle + page marker | Title is the largest type on the page |
| `.hero` | Dark band: the single framing message of this page | Facts only — no reading instructions |
| `.layer` cards | The entities/levels themselves | chip (identifier) + fixed-width title column + body |
| `.strip` | One-line principle between cards | The relationship rule, e.g. "the graph is the only contact point" |
| `.base` | Dark bottom band | Not necessarily "foundation" — it's whatever floors this page: shared base, current status, or a commitment list |

Card body patterns: an N-stage arrow chain (`.stage` → `.stage` → `.stage`), a zone grid, or a
detail column. Mark the "current"/emphasized cell with a heavier border only — not a new color.

## Skeleton

```html
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>Title — Subtitle</title>
<style>
/* :root tokens from references/theme.md go here */
.header{display:flex;align-items:flex-end;justify-content:space-between;gap:34px;margin-bottom:18px;position:relative;z-index:2}
.title{font-size:44px;font-weight:800;color:var(--deep);letter-spacing:-1.5px;line-height:1;white-space:nowrap}
.sub{font-size:15.5px;font-weight:600;color:var(--s1);padding-bottom:4px}
.pageno{font-size:13px;font-weight:700;color:var(--muted);padding-bottom:6px;white-space:nowrap}

.hero{display:flex;gap:26px;align-items:center;background:linear-gradient(120deg,var(--deep2),#173f8f);
      border-radius:15px;padding:16px 26px;margin-bottom:14px;border-top:3px solid var(--accent);
      position:relative;z-index:2;overflow:hidden}
.hero .left{flex:0 0 430px}
.badge{display:inline-flex;align-items:baseline;gap:10px;background:rgba(255,212,121,.16);
       border:1px solid rgba(255,212,121,.45);color:var(--accent);font-weight:800;font-size:15px;
       padding:4px 15px;border-radius:30px}
.hhead{font-size:22px;font-weight:800;color:#fff;line-height:1.36;margin-top:10px;letter-spacing:-.5px}
.hhead em{font-style:normal;color:var(--accent)}
.hero .right{flex:1;display:flex;flex-direction:column;gap:9px}
.hitem{display:flex;align-items:center;gap:12px;background:rgba(255,255,255,.08);
       border:1px solid rgba(255,255,255,.17);border-radius:11px;padding:10px 15px;
       font-size:14.5px;font-weight:700;color:#eaf1fc}

/* glyph badges — replaces any icon webfont (No-CDN rule) */
.gl{flex:0 0 auto;width:22px;height:22px;border-radius:50%;display:grid;place-items:center;
    font-size:13px;font-weight:900;font-style:normal}
.gl.warn{background:rgba(255,212,121,.2);color:var(--accent);border:1px solid rgba(255,212,121,.5)}
.gl.ok{background:rgba(143,182,242,.18);color:#8fb6f2;border:1px solid rgba(143,182,242,.45)}

.layers{display:flex;flex-direction:column;gap:12px;position:relative;z-index:2}
.layer{display:flex;gap:18px;background:var(--card);border:1.5px solid var(--line);
       border-radius:15px;padding:15px 20px;align-items:stretch}
.layer.provisional{border-style:dashed;background:#fbfcfe}
.chip{flex:0 0 auto;width:40px;height:40px;border-radius:11px;color:#fff;font-size:16px;
      font-weight:800;display:grid;place-items:center;background:var(--deep)}
.s-1 .chip{background:var(--s1)} .s-2 .chip{background:var(--s2)} .s-off .chip{background:var(--inactive)}
.lhead{flex:0 0 258px;padding-right:6px;border-right:1.5px solid #eef2f7}
.lhead .lt{font-size:20px;font-weight:800;color:var(--deep);line-height:1.28;letter-spacing:-.4px}
.lhead .ld{font-size:12.5px;color:var(--muted);line-height:1.5;margin-top:7px}
.lbody{flex:1;min-width:0;display:flex;align-items:center;gap:2px}

.stage{flex:1;min-width:0;border-radius:11px;padding:10px 13px;border:1px solid}
.stage .sh b{font-size:12px;font-weight:800;letter-spacing:.3px}
.stage p{font-size:12.8px;line-height:1.5;margin-top:5px}
.s-1 .stage{background:var(--s1-soft);border-color:var(--s1-line)} .s-1 .stage .sh b{color:var(--s1)}
.s-2 .stage{background:var(--s2-soft);border-color:var(--s2-line)} .s-2 .stage .sh b{color:var(--s2)}
.stage.now{border-width:1.5px}
.sarr{flex:0 0 auto;color:#b9c6dd;font-size:17px;font-weight:800;padding:0 4px}

.strip{display:flex;justify-content:center;margin:2px 0;position:relative;z-index:2}
.strip span{display:inline-flex;align-items:center;gap:8px;font-size:13px;font-weight:800;
            color:var(--alert);background:var(--s5-soft);border:1px solid var(--s5-line);
            border-radius:30px;padding:6px 18px}

.base{margin-top:12px;background:linear-gradient(120deg,var(--deep2),#123a86);border-radius:15px;
      padding:18px 26px;display:flex;gap:24px;align-items:center;position:relative;z-index:2;overflow:hidden}
.base .bhead{flex:0 0 280px}
.base .bt{font-size:20px;font-weight:800;color:#fff;line-height:1.35}
.base .bt em{font-style:normal;color:var(--accent)}
.base .bd{font-size:12.5px;color:#cfe0fb;margin-top:6px;line-height:1.5}
.base .bbody{flex:1;display:flex;flex-direction:column;gap:9px}
.base .bnote{font-size:13px;color:#dce7fa;line-height:1.6}

@page{size:420mm 297mm;margin:0}                 /* A3 landscape — see theme page.print */
@media print{body{background:#fff;padding:0;margin:0;display:grid;place-items:center;height:296mm;overflow:hidden}
             .slide{box-shadow:none;border-radius:0;zoom:.97}}
</style></head><body>
<div class="slide">
  <div class="header">
    <div style="display:flex;align-items:flex-end;gap:26px">
      <div class="title">Title</div><div class="sub">The question this page answers</div>
    </div>
    <div class="pageno">Report · N / M</div>
  </div>

  <div class="hero">
    <div class="left">
      <div class="badge">Frame <span>one-line rider</span></div>
      <div class="hhead">The <em>single message</em> of this page</div>
    </div>
    <div class="right">
      <div class="hitem"><span class="gl warn">!</span>Context / problem</div>
      <div class="hitem"><span class="gl ok">=</span>Our answer</div>
    </div>
  </div>

  <div class="layers">
    <div class="layer s-1">
      <div class="chip">A</div>
      <div class="lhead"><div class="lt">Entity</div><div class="ld">one-line definition</div></div>
      <div class="lbody">
        <div class="stage"><div class="sh"><b>Step 1</b></div><p>detail</p></div>
        <span class="sarr">→</span>
        <div class="stage now"><div class="sh"><b>Now</b></div><p>detail</p></div>
      </div>
    </div>
    <div class="strip"><span>The relationship rule, one line</span></div>
  </div>

  <div class="base">
    <div class="bhead"><div class="bt"><em>Foundation</em><br>one-line definition</div>
      <div class="bd">supporting line</div></div>
    <div class="bbody"><div class="bnote">What everything above rests on.</div></div>
  </div>
</div></body></html>
```

## Archetype-specific failure modes

- Two grammars on one page (vertical stack *and* a left→right flow) — pick one.
- A card body that is one thin line stretched across 1200px. Either promote detail from the
  source document into a right-hand column, or shrink the box.
- An entity drawn beside its container instead of inside it.
- Unlabeled cross-column arrows.
- Using the dark `.base` band as decoration when the page has no floor concept — then drop it
  and give the space back to the cards.
