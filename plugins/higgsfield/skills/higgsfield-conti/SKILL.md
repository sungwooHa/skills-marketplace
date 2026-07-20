---
name: higgsfield-conti
description: |
  Mandatory 콘티 (storyboard) gate before video generation. Before making a video (bridge·hero, etc.) with Higgsfield,
  generate one 6-step progress comic 콘티 and get user approval, then transcribe the confirmed 콘티 into the
  video prompt's timeline narration. Triggers — "콘티 만들어", "콘티 게이트", "스토리보드 그려줘",
  or when a video-generation request arrives without 콘티 approval (route through this skill first). No video generation before approval.
argument-hint: "[motion-arc description] [--start <image>] [--end <image>]"
version: 1.0.0
---

# Higgsfield 콘티 Gate (G1)

Video is the most expensive asset. Before generating, **confirm the motion on paper** — the reason this skill exists is to prevent
video regeneration (72cr+ per run) with one 콘티 (2~5cr).

## Step 0 — Read project config

At gate entry, read `.claude/higgsfield.local.md` from the project root if present. The parsing rules and the full key table
are specified once, in `higgsfield-estimate` Step 0 — follow that spec; it is not restated here.

This skill uses `style_source`, `approval_keyword`, and `escalation_role`.

Missing file = all defaults. Do not invent values, and do not block on the config — `style_source` and `approval_keyword`
both change behavior, and both have defined fallbacks (ask the user for palette·mood·negatives; approve on "진행").

## Inputs (provided by the requester; if missing, ask one at a time)

1. **Motion arc** — what moves and how (one paragraph is enough)
2. **Start·end anchors** — start/end frame images (if available, the path). If `style_source` is set, check that document for an
   existing plate/anchor spec before asking; if that document is an archived or superseded revision, confirm currency with the
   `escalation_role` before use
3. **Style lock** — palette·mood·negatives. If `style_source` is set, inherit from it; if not set, ask the user for palette·mood·negatives

## Procedure

### 1. Motion arc → break into 6 steps
- Split by progress 0 / 15 / 35 / 55 / 75 / 100%. Each step = 1 line of scene + 1 line of camera
- Describe as **fixed subject + moving camera** (no numeric rotation-amount instructions — the model can't hold them; measured: request 180° → 270°)
- Show the user the table first and confirm the narration (text-stage feedback = free)

### 2. Generate the 콘티 image (measurement-verified prompt pattern)
After applying the `higgsfield-estimate` discipline (the 콘티 is paid too). The plugin's `PreToolUse` hook enforces this at
execution time — if this command comes back blocked, the estimate gate has not been passed; run `higgsfield-estimate` and get
the user's approval keyword rather than trying to route around it:

```bash
higgsfield generate create gpt_image_2 --prompt "<아래 템플릿>" --aspect_ratio 16:9 --resolution 2k --wait
```

Prompt template (keep in English — verified original):

```
A single-page film storyboard sheet with exactly 6 comic panels arranged in a 3x2 grid,
rough black and white pencil sketch style, hand-drawn film pre-production storyboard look.
All panels depict the SAME <피사체/장면 서술>, one continuous single-take camera move,
drawn from the same filming perspective evolving smoothly.
Panel 1 captioned '0%': <장면>. Panel 2 captioned '15%': <장면>. ... Panel 6 captioned '100%': <장면,
텍스트/CTA 여백 필요 시 명시>.
Each panel has its percent caption and small camera angle notes, motion arrows,
sketchy pencil shading, 16:9 sheet. No people, no logos other than captions, no color.
```

### 3. Approval loop
- Show the 콘티 and **stop**. Don't move to video until the user says the `approval_keyword` (default "진행")
- Specific-step feedback (e.g., "35%를 더 측면으로") → fix only that panel's narration and regenerate; repeat until satisfied
- The final approved version = the **confirmed 콘티**. Only the approved latest version is valid, not a draft

### 4. Transcribe into video
- Move the confirmed 콘티's 6 steps verbatim into the video prompt's timeline narration (no hardcoded initial draft)
- **Never put the 콘티 image itself into the video input** — the measured hazard is that motion arrows·captions appear as real objects inside the scene. Video input = start/end anchor images + prompt narration only

## Rules (summary)

- No video generation before approval · use only the approved latest 콘티 · the 콘티 must not be a video reference
- Fixed subject + moving camera · if holding the end state matters, specify it at a "REMAIN"-level of emphasis
- No readable-text instructions in the generation prompt (unstable glyph rendering + external-grade boundary)
