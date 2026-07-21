---
name: feedback-consolidator
description: "검증 결과 + 세션 중 사용자 교정 피드백을 누적 피드백으로 통합하는 스킬. CRITICAL/ERROR를 카테고리별로 분류 → feedback/lessons.md에 누적 → patterns.json 갱신 → 반복 패턴(2회+)을 해당 agent의 Learned patterns 섹션에 자동 패치. 콘텐츠 배제 원칙 적용. 트리거: Phase 3 완료 후 자동, 세션 중 사용자 교정 피드백 발생 시, '/feedback-consolidate', '피드백 통합'."
---

# Feedback Consolidator — two-stage capture → promotion

**Capture (raw, local-only) and promotion (distilled, pushed) are separate stages.** The content firewall is
enforced at the promotion gate only, so capture stays fast and lossless.

Set `$FC` once for the commands below:

```bash
FC="${CLAUDE_PLUGIN_ROOT}/skills/feedback-consolidator"
```

## Stage 1: capture — `feedback/raw/{YYYY-MM-DD}-{deck-type}.md` (never pushed)

**User channel (immediate, done by the model directly)**
When corrective feedback arrives mid-session (design taste, style notes, process corrections), append it to
the raw file on the spot — verbatim, with its context. `raw/` is local-only, so content is allowed there.
This is not skippable even in sessions that never ran Phase 3.

**Verification channel (after Phase 3, via script)**
When the 5-axis verification has completed, at least one `_verify_*.md` exists, and at least one
CRITICAL/ERROR was reported:

```bash
python "$FC/scripts/consolidate_feedback.py" output/{title}/
```

The script writes the **verbatim** issue text into the raw file, updates `patterns.json` with only a category
count plus a generalized description, and auto-patches agents for patterns at count >= 2.

## Stage 2: promotion — once, at completion (done by the model directly)

1. Convert this session's raw records into rules with **content removed and the lesson generalized**.
   - e.g. "this deck is too dark" → "do not apply a dark theme by default without checking audience and context"
2. Append to the matching build section of `feedback/lessons.md` in the form
   `- [user] {rule} (axis: design|delivery|naturalness|build|process)`
3. Increment count in `feedback/patterns.json`. Reuse the script's category taxonomy (the constants at the top
   of `consolidate_feedback.py`); if nothing fits, create `user-{axis}-{slug}`.
   Schema: `{"count": N, "last_seen": "YYYY-MM-DD", "issues": [...]}`
4. At count >= 2, patch the rule into that agent's `## Learned patterns` section (same format the script uses)

## Content firewall (mandatory check at the promotion gate)

For every line written into a pushed file (`lessons.md`, `patterns.json`, agent patches):

- No personal names, organization names, event names, personal anecdotes, figures, or slide copy — leave the
  methodology rule and nothing else
- A `lessons.md` entry title is `date · deck type`. Never an event name or a person's name.
- Self-check: "could someone infer what the presentation was about from this line alone?" If yes, generalize further.

## Outputs

1. **feedback/raw/** — verbatim capture (local-only, never committed)
2. **feedback/lessons.md** — promoted, generalized rules appended
3. **feedback/patterns.json** — per-category counts updated
4. **agent .md patches** — patterns at count >= 2 update that agent's `## Learned patterns` section

## User confirmation

Summarize in one line, then ask the user to confirm commit/push:

```
피드백 통합 완료: CRITICAL N, ERROR M
신규/갱신 패턴: {category} (→ {count}회)
패치된 에이전트: {agent1}.md, {agent2}.md

커밋하시겠습니까?
  git add feedback/
  git commit -m "feedback: {title} 검증 누적 (CRITICAL N, ERROR M)"
  git push
```

Commit and push **only** after the user approves.

## Manual run

```bash
# Consolidate feedback for one deck
python "$FC/scripts/consolidate_feedback.py" output/분기_OKR_리뷰/

# Dry run (report only, no writes)
python "$FC/scripts/consolidate_feedback.py" output/분기_OKR_리뷰/ --dry-run
```
