---
name: produce-verify-pair
description: Pair a producer with an adversarial verifier — separate personas and sessions so nothing judges its own output, a verifier that judges only and may not edit, binary PASS/FAIL with default-deny, every defect attributed to a written criterion, a loop with an explicit termination condition, and a verification-request fallback when spawning is impossible. Carries the inverse guardrail — autonomous back-and-forth debate between agents is forbidden, and the produce↔verify loop is the one place round-tripping earns its cost. Use when deciding whether work needs an independent check, when a producing agent is about to declare its own work done, or when someone proposes agents "discussing" a problem. Triggers — "검증까지 해줘", "제대로 됐는지 확인", "QA 해줘", "에이전트끼리 토론시켜", "리뷰 에이전트 붙여줘", "review my output", "add a verifier", "have the agents debate this". NOT a rendering or QA-tooling skill — the medium's actual gate belongs to slide-craft or deck-harness.
---

# produce-verify-pair

Two rules, and they are both about restraint:

1. **Nothing judges its own output.** A session that made the artifact will find it acceptable.
2. **Agents do not talk to each other freely.** Round-tripping between agents is expensive and
   unstable, and it earns its cost in exactly one shape — producer ↔ verifier.

## The inverse guardrail (read this before adding agents)

Multi-agent setups fail far more often from too much conversation than from too little. Each
exchange reloads context, multiplies tokens, and lets two models converge on a shared mistake
while sounding thorough.

- **Default: hand-off through an orchestrator.** A's output becomes B's input. One direction.
- **Forbidden: autonomous agent-to-agent debate.** No "let them discuss until they agree", no
  round-robin critique panels, no agent that may re-prompt another agent at will.
- **The one exception: the produce↔verify adversarial loop.** Here the round trip is justified
  because the two sides have *opposed* objectives (ship it vs. reject it), the exchange is
  structured (artifact out, verdict in), and it terminates on an explicit condition.
- Do not generalize the exception. If a proposed loop is not producer↔verifier with a PASS
  condition, it is a hand-off, and it runs once.

When to skip the pair entirely: trivial or reversible work, single-line edits, exploratory drafts
that nobody will act on. The pair costs a full extra context — spend it where a wrong PASS is
expensive.

## Roles

| | Producer | Verifier |
|---|---|---|
| Goal | Get the artifact to PASS | Find reasons it must not pass |
| May edit the artifact | yes | **no — never** |
| Output | The artifact, plus a loop until PASS | A verdict report only |
| Verdict authority | none | sole |
| Knows the criteria | applies them | judges by them and only them |

**Separation is by session, not just by name.** A different persona in the same session that
produced the work is not an independent verifier — it has the producer's rationalizations in
context. Spawn a fresh subagent, or hand the work to a later session with the artifact and the
criteria and nothing else.

## Verifier rules

1. **Binary verdict: PASS or FAIL.** No "mostly fine", no "some room for improvement". A verdict
   that cannot be acted on is not a verdict.
2. **Default-deny.** In doubt, FAIL. A wrong PASS ships a defect to the audience; a wrong FAIL
   costs one more loop. The costs are not symmetric.
3. **Do not fix.** No edits to the artifact, the manuscript, the spec, or the criteria — the
   verifier writes a defect report and returns it. A verifier that fixes things has become a
   producer and has lost the ability to judge.
4. **No opinions outside the criteria.** Every defect is attributed to a written criterion by its
   identifier. An observation with no criterion behind it goes on a separate **criteria-gap**
   track: recorded, *not counted toward the verdict*, and proposed as a future criterion.
5. **No self-verification.** Never judge an artifact produced in the same session or the same
   delegation.
6. **No verdict without evidence.** No FAIL without a located defect; no PASS without stating what
   was checked and with what measurement.
7. **Escape hatch, not override.** If the criteria themselves look wrong, keep the FAIL and append
   a *criteria-review proposal* to the report. Lowering a bar is the owner's call, not the
   verifier's.

## The loop

```
producer builds ──► verifier judges ──► PASS ─► promote (see ssot-doc-pipeline)
      ▲                     │
      └──── defect report ◄─┘ FAIL
```

Termination conditions — declare which one is in force before starting:

- **PASS** — the normal exit.
- **Iteration cap** (default 3 FAIL cycles). On the cap, stop and escalate to the human with the
  outstanding defect list. Do not keep looping; repeated FAIL on the same defect usually means the
  criteria, the source content, or the scope is wrong — none of which the loop can fix.
- **Repeat defect** — the same defect identifier surviving two consecutive cycles is an immediate
  escalation, not a third attempt.

The producer owns the loop; the producer never owns the verdict. "Verification passed" is a claim
only the verifier can make, and the producer must not report done without it.

## Defect report shape

```markdown
# Verdict: PASS | FAIL   (defects: N)

| # | Location | Gate | Criterion ID | Evidence (measurement / quote / coordinates) | Direction |
|---|---|---|---|---|---|

## Criteria gaps (not counted toward the verdict)
- observation, and the criterion it suggests

## Criteria-review proposal (optional; the verdict stands regardless)
- which criterion looks wrong, and why
```

"Direction" is a direction, not a rewrite. The verifier says what is wrong; the producer decides
how to fix it. A verifier that supplies replacement text has written the artifact.

## Fallback when spawning is not possible

Some environments cannot spawn a subagent. Do not resolve this by self-verifying. Instead, return
a **verification request** to the orchestrator or the user, containing everything a fresh session
needs and nothing else:

1. Artifact path(s).
2. The criteria — file paths, or the criteria inline if they are not written down anywhere.
3. The gates to run, with exact commands.
4. The output path and shape for the verdict report.
5. An explicit statement that the requester produced the artifact and therefore cannot judge it.

An unverified artifact is reported as unverified. It is never reported as done.

## Relationship to other skills

- **`deck-harness`** (plugin) — implements this pair concretely for talk decks: `deck-builder` and
  `design-director` produce; `build-verifier`, `intent-verifier`, `design-critic`,
  `delivery-critic` and `naturalness-critic` judge in parallel, and one CRITICAL blocks the deck.
  Use its agents rather than reimplementing them. This skill supplies what that harness does not
  state: when *not* to reach for a pair, and why the loop must not be generalized into debate.
- **`slide-craft`** (marketplace plugin, when installed) — the quantitative gate for report pages:
  font floor, occupancy, clipping, zero external requests, contrast, PDF page count. A verifier for
  that medium runs the plugin's script; it does not invent its own metrics. Where no such gate
  exists for the medium, the criteria come from the consuming project — never from the verifier's
  taste.
- **`ssot-doc-pipeline`** — the pipeline this loop sits inside; PASS is what allows promotion out
  of the drafts area.
