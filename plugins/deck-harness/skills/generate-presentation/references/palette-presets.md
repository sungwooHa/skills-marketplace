# Palette Presets — Color System Catalog

So that `design-director` does not invent a color system from scratch on every deck, this catalog offers
three field-proven presets — each has shipped on a real deck and survived adversarial verification. Pick one
against audience, intent, and genre — or, if none fit, **derive** a new one from the principles below (one
dominant accent, restrained support colors). Inventing a fresh palette is not the default. Look here first.

## How to pick

| Deck character | Preset |
|---|---|
| Executive strategy / business-plan reporting, dense multi-axis information | **A. Structural Cool** |
| Narrative storyline where distinguishing 3 categories (e.g. market / customer / technology) *is* the message | **B. Tri-Axis Categorical** |
| TED-style conviction, one message per slide, an emotional curve as the spine | **C. Dark Cinematic** (harness template default) |

If the mood is ambiguous, look at the **emotion** axis of `presentation-strategist`'s 3-axis intent first:
"trust / conviction" → A or C, "structure / comparison / judgement" → A, "pivot / vision" → B.

> These are proven color systems, not brand identities. If you are presenting under an organization's brand,
> replace the accent and category hues with that brand's tokens and keep the **role structure** (one accent,
> verdict colors separated from category colors) intact — the structure is the part that was verified, and it
> carries over to any hue set.

---

## A. Structural Cool — light dashboard · single accent + separated verdict colors

**Mood**: calm navy structure with a single teal accent. The tone of a dense, multi-axis report where axes
and verdicts (go / hold / stop) are carried by distinct colors. Minimal decoration; color's only job is
information hierarchy.

| Token | Value | Role | Limit |
|---|---|---|---|
| `--ink` | `#15212e` | Body text | Nearly all type |
| `--navy` / `--navy2` | `#0a1a2f` / `#112744` | Structure (header/footer fills) | Large areas |
| `--accent` (teal) | `#137a6c` | The only accent | Focus, links, 1-2 key spots |
| `--support` | `#b08a4a` | Secondary marker | Sparse — annotations, secondary sourcing only |
| `--go` / `--stop` | `#1f8a5b` / `#9c5247` | Verdict (proceed / halt) | Verdicts only; never repurpose as general emphasis |
| `--line` / `--bg` / `--card` | `#e3e7ed` / `#eef1f6` / `#fff` | Neutrals | Borders, fills |

**Rule**: a single view's dominant colors are ink + teal, and nothing else. Support and verdict colors appear
only as points, only where they mean something. Soft tints belong to verdict rows only.

---

## B. Tri-Axis Categorical — light flat · 3-category coding

**Mood**: white ground, three near-primary category hues, plus one hero accent. Flat — no gradients, no
decorative chrome. Fits a narrative deck that must visually separate three axes (market / customer /
technology, or team / product / market).

| Token | Value | Role | Limit |
|---|---|---|---|
| `--ink` / `--ink2` | `#121214` / `#3f4348` | Body, titles | |
| `--muted` / `--off` | `#858585` / `#C5C6C7` | Subtext, disabled | |
| `--bg` / `--stageout` | `#ffffff` / `#ececec` | Backgrounds | |
| `--hero` (accent) | `#236DF6` | The only accent (blue) | Tabs, highlights, badges, focus |
| Axis 1 | `#FED132` | Category A (e.g. market) | On a yellow fill, dark ink text is mandatory (legibility) |
| Axis 2 | `#236DF6` (= hero) | Category B (e.g. customer) | |
| Axis 3 | `#FF6641` | Category C (e.g. technology) | |
| Verdict | go `#0e7c63` / hold `#9a6a1f` / stop `#bf4233` | Gates and stamps only | Must sit apart on the color wheel from the axis hues (avoid confusion) |

**Rule**: keep axis hues near-primary in saturation, but never set text directly in them (legibility floor).
The stop color must be separated in lightness and saturation from whichever axis hue it sits nearest
(usually the orange).

---

## C. Dark Cinematic — dark navy · single accent (harness default)

**Mood**: near-black navy ground, bright text, one accent. Best for TED- or keynote-style conviction. This
preset is already the default token set in `assets/templates/index.html`, so it needs no substitution to use.

| Token | Value | Role |
|---|---|---|
| `--bg-navy` | `#0A0F21` | Default background |
| `--bg-black` | `#000000` | Act transition / provocation slides |
| `--bg-white` | `#FFFFFF` | Closing / pivot |
| `--accent` | `#398EF6` | Emphasis (the one value you may change) |
| `--red-cross` | `#E63946` | Negation, cancellation |

**Variant**: the presenter-only view (script viewer, never shown to the audience) may switch its accent to
`#36C39B` (mint) to separate it visually from the main deck — the audience never sees it, so it is free of
brand-consistency constraints.

---

## Adding a preset

Promote a combination into this catalog only once it has actually shipped — that is, been used on a real
deck and survived adversarial verification. Criteria: (1) obeys the one-accent (max two) rule, (2) keeps
verdict and category colors role-separated from the general accent, (3) has at least one real deployment.
Record experimental palettes in `plan.md` §8 only; do not add them here.
