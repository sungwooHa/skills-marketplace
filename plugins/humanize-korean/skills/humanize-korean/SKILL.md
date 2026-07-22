---
name: humanize-korean
version: "2.0.0"
description: Polishes Korean text written by AI (ChatGPT, Claude, Gemini, …) so it reads like a human wrote it. Detects and classifies 60+ AI-tell patterns across 10 categories — 번역투, 영어 인용 과다, 기계적 병렬, 관용구, 피동태 남용, 접속사 남발, 리듬 균일성, 이모지·불릿 과다 — then rewrites style, rhythm, and expression only, without altering a single character of the content. Triggers — "AI 티 없애줘", "AI 같은 글 자연스럽게", "GPT/ChatGPT 문체", "AI 번역투 고쳐", "사람이 쓴 것처럼 윤문", "AI 윤문", "ChatGPT 티 제거", "한글 AI 탐지·윤문", "AI 글 사람처럼", "번역투 제거", "영어 인용 많은 글 윤문", "AI 글 티 안 나게", "휴머나이저", "humanize Korean", "AI detector bypass 한글". Follow-ups — "특정 카테고리만 다시", "윤문 강도 조정", "장르 바꿔서", "이 문단만", "2차 윤문" — belong here too. Plain spelling/typo fixes are handled directly; translation goes to a translation skill; a rewrite that adds or removes content goes to a writing skill.
---

# Humanize Korean — AI-tell removal orchestrator (v2.0.0)

Two modes. **Fast** (default) runs a single monolith agent. **Strict** runs the
five-agent pipeline when the text is long or the user wants verification split
out from rewriting.

The taxonomy is v2.0: 10 categories, 60+ patterns, with the Korean
translation-studies lineage (이영옥 2001 · 김정우 2007 · 김도훈 2009 ·
김혜영 2019) and the post-editese literature (Baker 1993 · Toury 1995 ·
Toral 2019) folded in.

## Resolving reference files

Reference files live at `${CLAUDE_PLUGIN_ROOT}/skills/humanize-korean/references/`.
Resolve that directory **once**, at Phase 0, into an absolute path — call it
`REFS` — and pass absolute paths to every agent you spawn.

1. If `CLAUDE_PLUGIN_ROOT` is set, `REFS = ${CLAUDE_PLUGIN_ROOT}/skills/humanize-korean/references`.
2. If it is unset, locate the directory with
   `Glob("**/skills/humanize-korean/references/quick-rules.md")` and take the
   parent of the first match.

**Never hand an agent a bare relative path like `references/quick-rules.md`.**
An agent's working directory is the user's project, not the skill directory, so
a relative path resolves to `<user-cwd>/references/…` and the read fails —
silently, because the agent then proceeds without the rulebook it was supposed
to obey.

## Phase 0 — context and mode

Print exactly one line before doing anything else:

```
humanize-korean v2.0.0 — {fast|strict} 모드 / run_id: {YYYY-MM-DD-NNN}
```

### Mode
- User says `--strict`, "정밀 모드", or "5인 파이프라인" → **strict**
- Input longer than 8,000 characters → **strict** (auto-promote, tell the user in one line)
- Everything else → **fast**

### run_id
- All paths are relative to the user's **cwd**. Create `_workspace/{YYYY-MM-DD-NNN}/` under cwd.
- Find the current sequence with the `Glob` tool against a marker file:
  `Glob(pattern="_workspace/YYYY-MM-DD-*/01_input.txt")`, then extract the folder
  names and take max(NNN) + 1. Glob cannot match bare directories, so you must
  match a file inside them. Do not use `Bash ls` — path resolution varies by
  shell and OS.
- No folder for today → NNN = 001.
- A partial-rerun signal ("이 카테고리만 다시", "2차 윤문") reuses the existing
  run_id and auto-promotes to strict.

## Fast mode (default)

### Phase 1 — store input
1. Create `_workspace/{run_id}/` under cwd.
2. Write the input text to `01_input.txt`.
3. Infer genre from the first 300 characters (an explicit user genre wins).

### Phase 2 — optional metric pre-pass
If `python3` is available, run the metric calculator **before** the agent call so
the model does not burn tool-call budget counting commas and suffixes:

```bash
python3 "$REFS/metrics_v2.py" --input _workspace/{run_id}/01_input.txt \
    --genre essay --output _workspace/{run_id}/00_metrics.json
```

Prepend a compact digest of that JSON to the input as
`01_input_with_metrics.txt` and pass that path to the monolith instead.
If python3 is unavailable or the run fails, skip this phase silently and pass
`01_input.txt` — the pipeline does not depend on it.

Baseline cells in `baseline_v2.json` are flagged `_placeholder: true` and the
runner reports them in `v2_baseline_warnings`. Treat v2 z-scores as directional,
not calibrated, until that flag clears.

### Phase 3 — monolith call
Call the `humanize-monolith` agent once with the `Agent` tool:

```
input_path:       <abs>/_workspace/{run_id}/01_input.txt   (or 01_input_with_metrics.txt)
quick_rules_path: <REFS>/quick-rules.md                    (absolute — resolved at Phase 0)
genre_hint:       칼럼 | 리포트 | 블로그 | 공적 | null
```

The monolith writes **one** file: `_workspace/{run_id}/final.md`, with an
`<!-- HUMANIZE-SUMMARY -->` HTML comment block appended after the body carrying
metrics, per-category before→after counts, the 6-item self-check, grade, and
highlights. HTML comments do not render, so `final.md` can be published or
copied as-is.

Inside that single call the agent loads the rulebook, detects, rewrites,
self-checks, rolls back automatically past a 50% change rate, and re-runs once
if the self-check fails. Its budget is **3 tool calls** — that cap is the whole
reason the fast path exists.

### Phase 4 — deliver
Return four things:
1. One-line status: `완료. 변경률 X% / 등급 Y / 자체검증 N/6 통과`
2. The rewritten body (markdown block)
3. The key table from the summary block (metrics + category detections + self-check)
4. If grade is B or below: offer `--strict` for the five-agent pipeline

Wall-clock targets: ≤5,000 chars in 2–3 min; 8,000 chars in 5–7 min.

## Strict mode (`--strict` or auto-promoted)

### Phase A — detect
`ai-tell-detector` with `taxonomy_path: <REFS>/ai-tell-taxonomy.md` → `02_detection.json`

### Phase B — rewrite (up to 3 rounds)
`korean-style-rewriter` with `playbook_path: <REFS>/rewriting-playbook.md` and
`taxonomy_path: <REFS>/ai-tell-taxonomy.md` → `03_rewrite.md` + `03_rewrite_diff.json`

### Phase C — parallel verification
Spawn both in one message:
- `content-fidelity-auditor` → `04_fidelity_audit.json` (semantic equivalence)
- `naturalness-reviewer` with `taxonomy_path: <REFS>/ai-tell-taxonomy.md` → `05_naturalness_review.json` (residual tells + over-polish)

Then branch on the combined verdict:

| fidelity | naturalness | verdict | next |
|---|---|---|---|
| full_pass | accept / accept_with_note | **approved** | Phase D |
| full_pass | rewrite_round_2 | **second pass** | Phase B, targeted at the finding |
| full_pass | rollback_and_rewrite | **roll back, then rewrite** | instruct rewriter to revert those edits |
| conditional_pass | — | **retry rolled-back edits only** | Phase B |
| fail | — | **full redo** | Phase B from scratch |

Round 2 and 3 write `03_rewrite_v2.md` / `v3.md`. **After 3 rounds without
resolution, stop and `hold_and_report`** for human review.

### Phase D — final output
1. Copy the accepted text to `final.md`
2. Append the same `<!-- HUMANIZE-SUMMARY -->` block the fast path uses
3. Return result + grade to the user

## Partial rerun / follow-up commands

| user signal | handling |
|---|---|
| "특정 카테고리만 다시" | switch to strict, re-run Phase B on that category's findings only |
| "이 문단만" | strict, new run_id with just that paragraph as input |
| "2차 윤문" · `/humanize-redo` | feed the existing run's `final.md` back through strict Phase B |
| "윤문 강도 조정" | strict, change `min_severity`, re-run from Phase A |
| "장르 바꿔서" | change `genre_hint`, re-run from Phase A |

## Options (appended in natural language)

- `장르: 칼럼|리포트|블로그|공적` — genre (auto-inferred if omitted)
- `강도: 보수|기본|적극` — rewrite intensity (default 기본)
- `최소심각도: S1|S2|S3` — detection threshold (default S2)
- `--strict` — force the five-agent pipeline

## Data flow

### Fast
```
01_input.txt
    ↓ (optional) metrics_v2.py → 00_metrics.json → 01_input_with_metrics.txt
    ↓ [humanize-monolith — one call, 3 tool calls]
    └→ final.md  (body + <!-- HUMANIZE-SUMMARY --> block)
```

### Strict
```
01_input.txt
    ↓ [ai-tell-detector]
02_detection.json
    ↓ [korean-style-rewriter]
03_rewrite.md + 03_rewrite_diff.json
    ↓ [parallel]
    ├→ [content-fidelity-auditor] → 04_fidelity_audit.json
    └→ [naturalness-reviewer]     → 05_naturalness_review.json
    ↓ [orchestrator combines]
    ├→ (redo) back to Phase B, max 3 rounds
    └→ (approved) final.md
```

## Agents

All agents run on `model: opus`. Downgrading was tried and abandoned — the real
bottleneck is the tool-call chain, not the model tier.

The plugin ships six agent definitions in `agents/`, discovered automatically on
install:

| agent | mode | role |
|---|---|---|
| `humanize-monolith` | fast | detect + rewrite + self-check in one call |
| `ai-tell-detector` | strict | span-level detection → JSON report |
| `korean-style-rewriter` | strict | surgical rewrite from the detection report |
| `content-fidelity-auditor` | strict | semantic-equivalence audit, rollback orders |
| `naturalness-reviewer` | strict | residual tells + over-polish detection |
| `korean-ai-tell-taxonomist` | maintenance | owns the taxonomy SSOT; not called during a normal run |

## Hard rules

- **Meaning never changes.** This outranks everything. Violation → immediate rollback.
- **Numbers, proper nouns, and direct quotations are out of scope** for both detection and rewriting. Obey the Do-NOT list.
- **Stay in genre.** A 칼럼 does not become an 에세이; an 에세이 does not become literary prose.
- **Preserve register.** 격식체 in → 격식체 out. The AI tell is the grammar and the rhetoric, not the formality level itself.
- **Change rate: >30% warns, >50% aborts.**
- **No auto-loading.** Never parse a project's CLAUDE.md or other files to infer options.

## Test scenarios

**Fast, normal** — a 2,000–5,000 char AI-drafted 칼럼 dense with 번역투, 결말 공식,
and hype 어휘. Expect: one monolith call, 15–25% change rate, grade A/B, 2–3 min,
self-check 5–6/6.

**Strict** — explicit `--strict` or 8,000+ chars. Full pipeline, 18–22% change
rate, verification team returns full_pass.

**Edge — already human-written** — almost no matches, change rate under 5%, and a
"윤문 불필요 가능성" note in the summary block.

## References

Load on demand — these are not read unless a phase calls for them.

- [`references/quick-rules.md`](references/quick-rules.md) — slim rulebook, fast path only. S1/S2 patterns + the 6-item self-check.
- [`references/ai-tell-taxonomy.md`](references/ai-tell-taxonomy.md) — the SSOT. 10 categories × 60+ patterns, strict path.
- [`references/rewriting-playbook.md`](references/rewriting-playbook.md) — per-category substitution recipes, genre allowance table, 15-item PE checklist.
- [`references/scholarship.md`](references/scholarship.md) — academic provenance for the v2.0 patterns. **Never loaded at runtime**; it exists so taxonomy claims stay checkable.
- [`references/metrics.py`](references/metrics.py) + [`references/baseline.json`](references/baseline.json) — 8 baseline metrics.
- [`references/metrics_v2.py`](references/metrics_v2.py) + [`references/baseline_v2.json`](references/baseline_v2.json) — 14 post-editese / T1–T8 metrics. Imports `metrics.py`; both pairs must stay together.
