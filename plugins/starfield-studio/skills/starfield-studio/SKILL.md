---
name: starfield-studio
description: Skill for producing star (starfield) motion assets. Describe intent as a spec (JSON) → 콘티 HTML approval gate → deterministic render to GIF/MP4. Triggers — "별 배경 만들어", "스타필드 에셋", "별 GIF", "광원이 지나가는 별", "별이 모이는/수렴 연출", "특정 구간만 반짝이게", "별 루프 배경", "starfield". Requests to modify an existing starfield-derived HTML also go to this skill (steer toward writing a new spec).
---

# Starfield Studio — star motion-asset studio

## Principles (why it's done this way)

- **Intent lives only in the spec (JSON).** There is exactly one engine HTML inside the skill (`assets/engine_template.html`).
  Duplicating·modifying the HTML per staging is forbidden — code duplication = intent loss = non-reproducible.
  A request to "tweak this starfield HTML" is answered by editing its spec and rebuilding, never by hand-editing derived HTML.
- **Same spec = same pixels.** Seeded PRNG + fixed steps mean the frame seen in the 콘티 (browser) and the
  rendered GIF are frame-for-frame identical (verified: md5 match across two renders). No non-deterministic elements like the mouse.
- **콘티 approval gate.** No render before the user approves the 콘티.
  Since the render is local (free · 180 frames ≈ 2s), there is no cost/estimate gate — approval is about the staging, not the spend.

## Paths

Read `.claude/starfield-studio.local.md` at the project root if it exists (`key: value` lines).
Only one key is used; everything else has a fixed default.

| Key | Default | Meaning |
|---|---|---|
| `asset_root` | `starfield_studio` | Directory (project-root-relative or absolute) holding this skill's working files |

Under `<asset_root>` the layout is fixed:

| What | Where |
|---|---|
| spec | `<asset_root>/specs/<name>.spec.json` |
| 콘티 (for approval, self-contained HTML) | `<asset_root>/conti/<name>.conti.html` |
| Output | `<asset_root>/out/<name>_<width>_<loop\|once>.gif` + `<name>_master.mp4` |

The engine·scripts themselves live inside the installed plugin and are the only place to modify engine behaviour.
`${CLAUDE_PLUGIN_ROOT}` resolves to the plugin root when Claude Code runs a plugin skill; if it is unset in your
shell, substitute the directory this SKILL.md sits in.

```bash
SF="${CLAUDE_PLUGIN_ROOT}/skills/starfield-studio"
```

## Workflow

1. **Listen to intent → map to primitives.** Translate via the table below. If ambiguous, ask here (not after rendering).

   | User expression | Primitive |
   |---|---|
   | "광원/빛 하나가 ~방향으로 지나가게" | `orbs` (path·trail·brightening of nearby stars) |
   | "특정 영역만 / 특정 시점에만 반짝이게" | `pulses` (time window × spatial zone) |
   | "별들이 심볼/로고로 모이게" | `timeline`'s `progress` (default symbol = a regular hexagon; replace via `align.paths`) |
   | "별들이 글자를 만들게" (한글 포함) | `groups[].text` — real-font rasterization; `mode: "fill"` recommended for legibility |
   | "여러 심볼/글자가 각자 위치·타이밍으로" | `groups` (multi alignment groups, each with its own `at`·`size`·`timeline`) |
   | "장면 여러 개가 심리스하게 이어지게" | ONE long spec (one continuous simulation) + render `--split "6,12"` → per-scene files with zero seams |
   | "피날레에 중앙으로 확 수축" | `timeline`'s `collapse` |
   | "잔잔한 배경 무한 루프" | `loop: true` (guarantees a seamless full loop) |

2. **Write the spec.** See the schema·recipes in `references/spec-guide.md`.
   Starting from a copy of `examples/demo_light_sweep.spec.json` or `examples/demo_converge_finale.spec.json`
   is faster than writing one from scratch. `name` becomes the output filename (English snake_case).

3. **Build the 콘티 → request approval.**
   ```bash
   node "$SF/scripts/build_conti.mjs" \
     "<asset_root>/specs/<name>.spec.json" \
     "<asset_root>/conti/<name>.conti.html"
   open "<asset_root>/conti/<name>.conti.html"
   ```
   The 콘티 has play/pause·a frame scrubber attached (space = play toggle).
   **Do not render before the user approves.** Modification request → edit spec → rebuild → re-approve.

4. **Render (after approval).**
   ```bash
   node "$SF/scripts/render.mjs" \
     "<asset_root>/conti/<name>.conti.html" \
     --out "<asset_root>/out"
   ```
   Options: `--formats gif,mp4` (default) · `--gif-width 960` (shrinks the GIF only, saves size) · `--keep-frames` (keeps the PNG sequence)
   · `--split "6,12"` (cuts the continuous simulation at those seconds into `_p1`,`_p2`,… scene files — adjacent scenes share consecutive frames, so transitions are seamless; a full `_master.mp4` is also produced for seam inspection).

5. **Report.** Output path + size + (if needed) a check of a representative frame. PPT-insertion note:
   GIF = auto-loop playback in the slide, `_master.mp4` = high-quality master (for keynote/video editing).

## Constraints (must confirm when writing a spec)

- `loop: true` ⇔ `timeline`'s progress/collapse **cannot be used together** (loop mode is analytic drift).
  Do convergence·collapse staging with `loop: false` (once). A violation warning appears at the top of the 콘티.
- The rhythmic variety of loop twinkle is proportional to duration — loop backgrounds are **recommended 8~12s** (6s floor).
- If a 1920-wide GIF is heavy, use `--gif-width 960|1280` or spec `fps: 24`.
- If an orb·pulse time window (`t`) sits at 0 or spans the duration, the loop seam becomes visible —
  in loop assets keep the time window inward (the fade absorbs it) or make it an always-on effect across the whole span.
- If the render looks wrong, look at the 콘티 first — since the 콘티 and the render are pixel-identical, the cause is always the spec.

## Troubleshooting

- `Chrome/Chromium 을 찾지 못했습니다` → the renderer needs a local Chrome/Chromium; specify it via the
  `CHROME_BIN=<경로>` environment variable. See the plugin README's prerequisites section.
- `ffmpeg 실패` / `spawnSync ffmpeg ENOENT` → `ffmpeg` is not on PATH. Install it (`brew install ffmpeg`).
- If the render is slow: 1920×1080, 6s, 30fps ≈ frame capture within 10s is normal. Most of the time is ffmpeg assembly.
- For engine improvements (new primitives, etc.), modify only the single place `assets/engine_template.html`, then
  rebuild existing specs to check for regressions. Do not modify the 콘티 HTML directly.
- Superseded specs·outputs: keep, don't delete — move them wherever the host project archives old revisions.
