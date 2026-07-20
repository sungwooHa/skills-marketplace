# Starfield Studio — spec schema & recipes

spec = the single source of truth for staging intent. It's a partial override on top of the engine defaults, so write only the keys you need.

## Full schema (with defaults)

```jsonc
{
  "name": "asset_name",          // required. Basis for the output filename (English snake_case)
  "width": 1920, "height": 1080, // canvas pixels (콘티·render identical)
  "fps": 30,                     // lowering to 24 saves GIF size
  "duration": 6,                 // seconds
  "loop": false,                 // true = full loop (see loop mode below)
  "seed": 1234,                  // same seed = same star layout. If you dislike the layout, just change the seed
  "bg": "#030712",               // background color (baked into the frame). "transparent" = no bg, alpha preserved
                                 //   → transparent GIF. Note: GIF alpha is 1-bit, so soft halos hard-cut at the
                                 //   alpha threshold — transparent assets read best over dark slides.

  "stars": {
    "density": 7500,             // larger value = sparser stars (area/density = count)
    "max": 340,
    "brightRatio": 0.22,         // ratio of bright stars
    "sparkleRatio": 0.07,        // ratio of cross-glint stars
    "palette": null,             // per-star color list, e.g. ["#ff9d4d", "#7fb2ff"] — null = all white
    "sizeScale": 1,              // multiplies every star's size (e.g. 1.4 = a bit bigger)
    "glow": 0                    // 0~1 soft halo around each star (light-source feel). 0 = off
  },
  "connections": {
    "enabled": true,             // constellation connection lines
    "dist": 90,                  // connection distance (px)
    "opacity": 0.5
  },

  "timeline": [ /* keyframe array — once only */ ],
  "orbs":     [ /* moving-light array */ ],
  "pulses":   [ /* interval-sparkle array */ ],
  "mask":     null,              // {"type":"circle","x":0.5,"y":0.5,"r":0.5,"feather":2} crops every frame to a
                                 //   circle (r = radius / min(W,H), feather in px). For round standalone-light GIF
                                 //   assets bake a dark bg INSIDE the circle: GIF alpha is 1-bit, so a transparent
                                 //   bg hard-cuts glow falloff — a baked dark bg keeps the glare as 8-bit gradient

  "align": {                     // symbol that progress aligns to
    "size": 0.4,                 // symbol size relative to min(W,H)
    "ratio": 0.82,               // ratio of stars participating in alignment
    "pull": 1,                   // center-pull strength of non-aligned stars. 0 = keep the background starfield (recommended for text/logo convergence)
    "tint": "#3b82f6",           // tint of aligned stars (#ffffff = no color change)
    "paths": null                // null = regular-hexagon default. Replaceable with [{d, cx, cy}] SVG paths
  },
  "collapseDur": 1.5             // collapse duration (seconds)
}
```

### timeline — temporal staging (loop: false only)

```jsonc
"timeline": [
  { "t": 0.5, "progress": 0 },                  // alignment 0~1 at time t (seconds). Intervals use smoothstep interpolation
  { "t": 3.0, "progress": 1 },                  // "ease": "linear" enables linear interpolation
  { "t": 4.2, "collapse": true }                // from this point, center collapse over collapseDur
]
```
- progress: before the first keyframe holds the first value; after the last holds the last value.
- collapse: turn on with true and (rarely) release with false. Stars get meteor tails during collapse.

### orbs — moving light (comet)

```jsonc
"orbs": [{
  "t": [0.5, 5.5],                              // active time window (0.3s fade at each end).
                                                //   OMIT t entirely = always-on, fixed at the path start point —
                                                //   for loop standalone-light assets (no fade → no loop seam)
  "path": [[0.05, 0.82], [0.45, 0.5], [0.95, 0.15]],  // 0~1 normalized coords. 3+ points → curve (Catmull-Rom)
  "size": 80,                                   // glow radius (px)
  "color": "#8ab4ff",
  "trail": 0.5,                                 // tail length 0 (none)~1 (long)
  "ease": "smooth",                             // path-progress easing. "linear" possible
  "ramp": 0.3,                                  // fade in/out time (seconds)
  "hold": false,                                // true = t[1] is the ARRIVAL time; no fade-out — the orb
                                                //   rests at the path end until the video ends (trail settles
                                                //   over ~0.8s after arrival). once mode recommended.
  "boost": {
    "radius": 150,                              // influence radius (px)
    "brighten": 0.7,                            // brightening of nearby stars on pass 0~1
    "attract": 0.5                              // slightly pulls stars (works in once mode only)
  },
  "pulse": {                                    // heartbeat: brightness AND glow radius thump together.
    "amp": 0.3,                                 //   brightness gain at peak (0~1, on top of baseline)
    "swell": 0.25,                              //   radius expansion ratio at peak — size the canvas for size*(1+swell)
    "cycles": 8,                                //   beats per duration; forced to an integer → loop-seamless
    "sharp": 3                                  //   waveform sharpness: higher = snappier beat, longer rest.
  }                                             //   t=0 phase = rest, so the loop boundary sits between beats.
                                                //   Also available on dots[] with the same fields.
}]
```

### pulses — interval sparkle (time window × spatial zone)

```jsonc
"pulses": [{
  "t": [2.0, 4.5],                              // when (ramp fade at each end, default 0.3s)
  "zone": { "type": "circle", "x": 0.7, "y": 0.3, "r": 0.18 },  // where (0~1 normalized)
  "effect": "sparkle",                          // sparkle (glint flicker) | brighten | dim
  "strength": 1.0,
  "ratio": 1.0                                  // ratio of stars reacting inside the zone (0.5 = only half)
}]
```
- zone types: `{"type":"circle","x","y","r"}` · `{"type":"rect","x0","y0","x1","y1"}` · `"all"` (whole screen).
- Overlapping a dim on an "all" zone with a brighten pulse on the desired area produces a "only that part alive" effect.

### dots — count-exact dot appearance (staggered fade-in · rise · once recommended)

Explicit foreground dots, independent of the background starfield (own PRNG — adding dots never
changes existing star layouts). Use when the staging needs an EXACT number of points
(e.g. "29 items"), precise positions, or a dotted scale line. Drawn topmost.

```jsonc
"dots": [{
  "t": [0.5, 3.2],               // appearance window — dots fade in staggered inside it
  "zone": { "type": "rect", "x0": 0.06, "y0": 0.36, "x1": 0.3, "y1": 0.64 },  // scatter zone (rect|circle)
  "points": null,                // OR explicit positions [[x,y],...] (0~1). count fills the rest from zone
  "count": 29,                   // exact number of dots
  "size": 3.5,                   // core radius px
  "color": "#ffd2a1",
  "glow": 0.45,                  // 0~1 halo strength
  "rise": 24,                    // px — floats up this distance while fading in ("떠오름")
  "twinkle": 0.4,                // 0~1 subtle alpha shimmer after appearing
  "stagger": "random",           // appear order: "random" | "ltr" (left→right, good for scale lines)
  "fade": 0.5,                   // per-dot fade-in duration (seconds)
  "pulse": null                  // heartbeat {amp, swell, cycles, sharp} — same semantics as orbs[].pulse
}]
```
- once mode: staggered fade-in·rise as configured. loop mode: the appearance staging is skipped
  (dots are always-on) and twinkle frequency is quantized to multiples of 2π/duration → seamless
  loop, usable for standalone twinkling-light assets.
- Proven combination for a data-flavoured cut: a `count`-exact scatter of pale dots → a few deeper,
  larger dots on top → a dotted scale line (`stagger: "ltr"`) → one large `hold` orb sliding to the
  position being called out.

### align.paths — replacing the alignment symbol

Pass the d string of an SVG path and each path's center offset (cx, cy), and stars gather to that outline.
Extract paths from a logo SVG and use them (multiple paths allowed, auto-scaled·center-aligned).
Star distribution is proportional to path perimeter length — density stays even even if you mix paths of different lengths, like letters.
Recommended settings for text/logo convergence: `align.pull: 0` (keep the background starfield) + `connections.dist 55~65` (prevents lines
crossing between letters) + `stars.density 4000~4500` (secures outline density).

```jsonc
"align": { "paths": [ { "d": "M10 80 C 40 10, 65 10, 95 80 ...", "cx": 0, "cy": 0 } ], "size": 0.45 }
```

### groups — multiple alignment groups (symbols/text, each with its own position·timing)

When `groups` is present it replaces the single `align`+`timeline` progress mechanism
(global `align.ratio`/`pull` still apply; `timeline` remains for `collapse`).
Stars are budgeted across groups proportionally to each group's perimeter/area, and each
group recruits the stars nearest to its `at` position (natural local convergence).

```jsonc
"groups": [{
  "text": { "value": "사람",       // any string incl. Hangul — rasterized with a real font
            "weight": 600,         // font-weight. 600 recommended (800 fills letter counters)
            "mode": "fill",        // "fill" = star-dust body (best legibility) | "outline" = contour trace
            "font": null },        // CSS font-family override (default: -apple-system + Apple SD Gothic Neo)
  "paths": null,                   // alternative to text: [{d, cx, cy}] SVG paths (logo etc.)
  "size": 0.22,                    // text: height / min(W,H); paths: max dimension / min(W,H)
  "at": [0.7, 0.5],                // group center position (0~1 normalized)
  "tint": "#ffffff",
  "timeline": [ { "t": 12.8, "progress": 0 }, { "t": 15.6, "progress": 1 } ]  // per-group schedule
}]
```

Text legibility guide (settings that survived repeated iteration):
- Budget many stars: `stars: { "density": 1600, "max": 700 }`, `align.ratio 0.7`, `align.pull 0`.
- `connections.dist 36` — larger values web across letter gaps/counters and smudge glyphs.
- Hangul needs ~15% larger `size` than Latin caps and `weight` ≤ 600 to keep counters open.
- Note: text targets are rasterized by the viewing browser's font engine — preview the 콘티 in
  Chrome (same engine as the renderer) for pixel-exact conti↔render matching.

### Multi-scene seamless sequences

Do NOT chain separate specs — state cannot carry across simulations. Author ONE spec whose
duration covers all scenes (e.g., 18s = 3 scenes × 6s), schedule each group's formation inside
its scene window, then render with `--split "6,12"`. Cut points land between consecutive
frames of one simulation, so scene N's last frame flows into scene N+1's first frame with zero seam.

## Loop mode (loop: true) behavior

- Star drift switches to analytic (Lissajous) positions, and twinkle·glint frequencies are quantized to multiples of
  2π/duration, so the last frame → first frame connects seamlessly.
- Since there is no physics integration, progress/collapse/attract are ignored (a warning shows in the 콘티).
- orb·pulse are usable, but keep the time window off the 0/duration boundary (so the fade ends inside).

## Recipes

| Intent | Key spec |
|---|---|
| Calm background infinite loop | `loop: true`, `duration: 10`, no orbs/pulses |
| Light-sweep loop | `loop: true` + 1 orb (`t` inward, e.g., [1, 9] within 10s) |
| Emphasize a specific area | 1 pulse (circle zone + sparkle), place the zone at the emphasis target |
| Converge → hold | `loop: false`, timeline: progress 0→1, then hold (holds the last keyframe value) |
| Converge → finale collapse | add `{ "t": ..., "collapse": true }` to the above, collapseDur+0.3s before the end |
| Logo/custom-symbol convergence | convergence recipe + `align.paths` replacement |
| Round standalone-light GIF asset (glare preserved) | `loop: true` + baked dark `bg` + `mask` circle + dot twinkle or orb `pulse` (no `t`) |

Runnable starting points ship with the skill in `examples/`: `demo_light_sweep.spec.json` (loop + light + pulse)
and `demo_converge_finale.spec.json` (converge + collapse). Copy one into `<asset_root>/specs/` and edit.
