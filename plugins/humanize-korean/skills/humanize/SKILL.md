---
name: humanize
version: "2.0.0"
description: Explicit entry command for Korean AI-tell removal. Runs the humanize-korean pipeline in fast mode by default, or the five-agent pipeline with `--strict`. Trigger — "/humanize".
argument-hint: "[Korean text to polish, or a file path]"
disable-model-invocation: true
---

# /humanize — remove AI tells from Korean text

Invokes the `humanize-korean` skill on the text (or file) passed as an argument.
This is the deterministic entry point: `disable-model-invocation: true` means it
fires only when the user types it, never on the model's own initiative.

## Input
$ARGUMENTS

## Behaviour
1. Empty argument → print `윤문할 텍스트를 붙여넣어 주세요` and stop.
2. Argument is a `.txt` / `.md` path → load it with `Read`.
3. Argument is text → use it directly.
4. Follow the `humanize-korean` SKILL.md procedure end to end (Phase 0 through
   delivery). Fast mode by default; `--strict` runs the five-agent pipeline.
   Inputs over 8,000 characters auto-promote to strict.
5. Deliver:
   - one-line status: `완료. 변경률 X% / 등급 Y / 자체검증 N/6 통과`
   - the rewritten body in a markdown block
   - per-category detection counts, before → after
   - 3–5 notable changes (before → after)
   - if grade is B or below, mention that `/humanize-redo` can run a second pass

## Options (appended in natural language)
- `장르: 칼럼|리포트|블로그|공적` — genre (inferred from the first 300 characters if omitted)
- `강도: 보수|기본|적극` — rewrite intensity (default 기본)
- `최소심각도: S1|S2|S3` — detection threshold (default S2)
- `--strict` — force the five-agent pipeline

## Notes
Reference files are resolved by `humanize-korean` SKILL.md, which turns
`${CLAUDE_PLUGIN_ROOT}/skills/humanize-korean/references/` into an absolute path
and passes it down. Do not construct reference paths here.
