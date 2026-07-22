---
name: humanize-redo
version: "2.0.0"
description: Runs a second pass over the most recent humanize result — by category, by paragraph, or at a different intensity. Re-enters humanize-korean strict rewriting (Phase B) on the existing run_id to clear residual findings. Trigger — "/humanize-redo".
argument-hint: "[adjustment — e.g. \"번역투만 다시\" \"이 문단만\" \"강도 낮춰\"]"
disable-model-invocation: true
---

# /humanize-redo — second pass / partial rerun

Finds the most recent `_workspace/{run_id}/` under the user's cwd and re-enters
`humanize-korean` strict mode at Phase B. Unlike `/humanize`, this reuses the
existing run rather than starting a new one, so detection results and prior
edits stay available.

## User instruction
$ARGUMENTS

## Behaviour
1. Identify the latest `run_id` with `Glob` against a marker file —
   `_workspace/YYYY-MM-DD-*/final.md`, falling back to `01_input.txt`. Glob
   cannot match bare directories, so always match a file inside them. If nothing
   matches, print `이전 실행이 없습니다. /humanize로 시작하세요` and stop.
2. Parse the instruction:
   - **category** ("번역투만", "관용구만", "이모지만") → re-rewrite only that category's findings
   - **paragraph** ("이 문단만", "두 번째 문단만") → only findings in that range
   - **intensity** ("강도 낮춰" / "보수적으로" → S1 only; "강도 높여" → S1+S2+S3)
   - **rollback** ("이 변경 되돌려줘") → hand that edit to `content-fidelity-auditor` as a rollback
   - no instruction / "2차 윤문해줘" → round 2 over all residual findings
3. Re-call `korean-style-rewriter` with the residual findings from the existing
   `02_detection.json` or `05_naturalness_review.json`, plus the user's
   instruction as `target_filter`.
4. Write output to `03_rewrite_v2.md` (or `v3`). Back up the previous `final.md`
   to `final_prev.md` first.
5. Run strict Phase C verification in parallel, then Phase D — comparison table
   plus the new grade.

## Loop limit
Round 3 maximum. Beyond that, `hold_and_report` and recommend human review.

## Notes
- A fresh full run is `/humanize`.
- Reference paths come from `humanize-korean` SKILL.md, which resolves
  `${CLAUDE_PLUGIN_ROOT}/skills/humanize-korean/references/` once and passes
  absolute paths down. Do not construct them here.
