# Design system — Airbnb (from voltagent/awesome-design-md)

Photography-forward, white canvas, single coral accent, rounded, soft shadows. This overrides any austere/editorial defaults.

## CSS tokens
```css
:root{
  --color-canvas:#ffffff; --surface-soft:#f7f7f7; --surface-strong:#f2f2f2;
  --ink:#222222; --body:#3f3f3f; --muted:#6a6a6a; --muted-soft:#929292;
  --hairline:#dddddd; --hairline-soft:#ebebeb;
  --rausch:#ff385c; --rausch-active:#e00b41;      /* PRIMARY accent — the only brand color */
}
@media (prefers-color-scheme:dark){ :root{
  --color-canvas:#181818; --surface-soft:#222; --surface-strong:#2a2a2a;
  --ink:#ebebeb; --body:#d0d0d0; --muted:#9a9a9a; --hairline:#333; --hairline-soft:#2a2a2a;
}}
```
`:root[data-theme="dark"]` / `[data-theme="light"]` overrides should mirror the above if a theme toggle exists.

## Type
- Stack: `Pretendard,'Airbnb Cereal VF',Inter,-apple-system,system-ui,Roboto,'Helvetica Neue',sans-serif` (Pretendard first for Korean; system fallback keeps it right offline on other machines). **No serif.**
- Weights: headings 600–700, body 400.
- Scale: hero h1 28–40px/700; section header 21px/700; sub-section 20px/600 (-0.18px); card title 16px/600; body 16px/400 line-1.5; meta 14px/400 muted; small 13px; eyebrow/micro-label ~11–12px/700 uppercase in `--rausch`.

## Shape & elevation
- Radius: buttons/pills 8px; cards + images + map containers 14px; tab/category pills 9999px.
- Shadow (single soft tier, only on card:hover + sticky/floating): `rgba(0,0,0,.02) 0 0 0 1px, rgba(0,0,0,.04) 0 2px 6px 0, rgba(0,0,0,.1) 0 4px 8px 0`.
- **No gradients.**
- Spacing: 8px base · 16px card gutters · 24px between · 64px major section rhythm.

## Components
- **Cover:** rounded-14 full-width hero photo; coral uppercase eyebrow; ink 28–40 title; muted subtitle; optional coral date pill.
- **Top tabs:** sticky horizontally-scrollable pill strip; active = white text on `--rausch` fill (or coral text + 2px coral underline). Keep aria/role/keyboard/hash wiring.
- **Sub-tabs:** smaller pills 14px/500, hairline border; active = ink fill + white text.
- **Cards** (한눈에/쇼핑/커피·디저트/결정): white, radius 14, hairline border, 16px padding, soft shadow on hover; category chip = coral-tint pill (`rgba(255,56,92,.1)` bg, coral text); title 16/600; meta muted; caveat tags = small pills.
- **User memo pull-quotes:** coral text with a left coral hairline accent. Memo text VERBATIM.
- **Tables:** hairline row dividers, no heavy borders, headers 14/600, time column coral or ink-600, wrap wide tables in `.tblwrap{overflow-x:auto}`.
- **Map pins:** Leaflet `divIcon` numbered dots in `--rausch` (highlighted/candidate pins larger, white ring); map container radius 14, overflow hidden.
- **Footer:** white, hairline top border, muted 14px columns.

## Responsive (Airbnb breakpoints)
Cards 1-col under 744px; tab bars scroll horizontally on mobile; per-day map stacks above schedule under 760px; no horizontal overflow at 360–400px.

## Other design systems
73 systems exist at github.com/voltagent/awesome-design-md (`design-md/<name>/DESIGN.md` on branch main, raw fetch). If the user wants a different look, fetch that DESIGN.md and swap tokens/components. Good travel-fit alternatives: Airbnb (default), Notion, Apple, Mastercard.
