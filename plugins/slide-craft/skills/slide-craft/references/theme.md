# Theming contract

A layout must never hard-code what a color *means*. Layouts consume **role tokens**; a project
supplies the values and any domain semantics.

## Resolution order

1. `slide-theme.json` in the project root (or the directory the user names) — wins.
2. `slide-theme.md` in the same place — a human-readable table with the same keys.
3. The neutral default below.

If the project also uses the deck-harness plugin, its `references/palette-presets.md` and
`.claude/deck-harness.local.md` are a good source to derive `slide-theme.json` from, so the
project's report pages and talk decks stay in one visual family. Derive, don't import — the two
carry different page geometry.

If a project theme exists but lacks a key, fall back to the neutral default for that key only.
If none exists and the project clearly has a house style (existing slides, a brand deck), offer
to write a `slide-theme.json` from it rather than inventing colors slide by slide.

## Token schema (`slide-theme.json`)

```json
{
  "name": "neutral-default",
  "page": { "width": 1600, "print": "A3-landscape" },
  "font": {
    "stack": "\"Pretendard\",\"Apple SD Gothic Neo\",\"Malgun Gothic\",-apple-system,BlinkMacSystemFont,\"Segoe UI\",sans-serif",
    "floor": 13,
    "title": 44
  },
  "color": {
    "ink": "#1b2a44", "muted": "#5a6b82", "line": "#dbe3ee",
    "card": "#ffffff", "bg": "#eef2f8",
    "deep": "#12285c", "deep2": "#0d2b6b", "accent": "#ffd479",
    "series": ["#2f6fd0", "#6a4fa3", "#158a78", "#4a9a3d", "#df6a2c"],
    "inactive": "#8a93a6",
    "alert": "#df6a2c"
  },
  "semantics": []
}
```

**Role meanings** — layouts may rely on these and nothing else:

| Token | Role |
|---|---|
| `ink` / `muted` | Primary and secondary text |
| `line` | Borders, dividers |
| `card` / `bg` | Surface and page background |
| `deep` / `deep2` | Dark banner gradient (hero, foundation band) |
| `accent` | The single highlight color used on dark surfaces |
| `series[]` | Ordered categorical palette — assign by position, never by hardcoded meaning |
| `inactive` | Not-yet-started / provisional entities (pair with a dashed border) |
| `alert` | Principle strips, warnings, the one thing that must be noticed |

`semantics[]` is optional and **project-owned**: `[{"key":"<entity>","label":"<display name>","series":0}]`
maps a domain entity to a `series` index so the same entity keeps the same color across every
slide. A layout reads `semantics` generically; it never contains the entity names itself. See
the worked example at the end of this file for what a filled-in `semantics` block looks like.

## CSS variable convention

Emit tokens as CSS custom properties on `:root`, then write all layout CSS against the
variables. This is what makes a slide re-themeable without touching layout.

```css
:root{
  --ink:#1b2a44; --muted:#5a6b82; --line:#dbe3ee;
  --card:#fff; --bg:#eef2f8;
  --deep:#12285c; --deep2:#0d2b6b; --accent:#ffd479;
  --s1:#2f6fd0; --s2:#6a4fa3; --s3:#158a78; --s4:#4a9a3d; --s5:#df6a2c;
  --inactive:#8a93a6; --alert:#df6a2c;
  --s1-soft:#e9f1fb; --s1-line:#c7dcf5;   /* per-series soft fill + border */
  --s2-soft:#f0ecf8; --s2-line:#d9cdec;
  --s3-soft:#e5f3f0; --s3-line:#bfe1da;
  --s4-soft:#eef6ea; --s4-line:#cfe6c4;
  --s5-soft:#fbeee4; --s5-line:#f2cba9;
  --font:"Pretendard","Apple SD Gothic Neo","Malgun Gothic",-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;
}
*{box-sizing:border-box;margin:0;padding:0}
svg text{font-family:inherit}          /* SVG labels inherit the body stack */
body{background:var(--bg);color:var(--ink);font-family:var(--font);word-break:keep-all;
     -webkit-font-smoothing:antialiased;display:flex;justify-content:center;padding:26px}
.slide{width:1600px;background:var(--card);border-radius:10px;padding:38px 44px 32px;
       position:relative;overflow:hidden;box-shadow:0 10px 40px rgba(15,35,70,.12)}
```

Soft/line variants: derive by mixing the series color toward white (~92% and ~72% white). Keep
them as explicit variables so the QA contrast check has stable values to measure.

## Fonts — embedding

`slide_qa.py` fails on any external request, so a webfont file **must** be inlined as a
`data:` URI inside `@font-face`, or omitted entirely in favour of the system stack. The default
stack above resolves on macOS, Windows and most corporate Linux images without any download.
Prefer the stack; only inline a font when brand compliance demands it, and expect the file to
grow by hundreds of KB.

## Worked example — a domain theme

This is what a consuming project's `slide-theme.json` looks like once it encodes house
semantics. **It is an example, not a built-in.** The entity names below belong to one specific
program and must not appear in any layout file.

```json
{
  "name": "ax-tf",
  "page": { "width": 1600, "print": "A3-landscape" },
  "color": {
    "deep": "#12285c", "deep2": "#0d2b6b", "accent": "#ffd479",
    "series": ["#2f6fd0", "#6a4fa3", "#158a78", "#4a9a3d", "#df6a2c"],
    "inactive": "#8a93a6", "alert": "#df6a2c"
  },
  "semantics": [
    { "key": "GA", "label": "Guide Agent",  "series": 0 },
    { "key": "SA", "label": "System Agent", "series": 1 },
    { "key": "OA", "label": "Operation Agent", "series": null,
      "style": "inactive-dashed", "note": "not yet started — never draw with a solid line" },
    { "key": "KG", "label": "performance graph", "style": "deep-band",
      "note": "the shared foundation — always the dark bottom band, accent highlights" }
  ],
  "flowRules": [
    { "from": "SA", "to": "KG", "label": "build" },
    { "from": "KG", "to": "GA", "label": "serve" },
    { "forbid": ["GA->KG", "SA<->GA"], "note": "direction carries meaning; no other edges" }
  ]
}
```

Two things this example demonstrates, both generalizable:

- **Color memory is an asset.** Once an audience has seen an entity in a color, keep it. Pin it
  in `semantics` rather than re-deciding per slide.
- **Edge direction can be semantic.** A project may forbid certain arrows. Encode that in the
  theme (`flowRules`) so every archetype honours it; the layout just draws what it's told.
