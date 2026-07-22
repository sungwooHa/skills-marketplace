# Interview — intent-first, ≤4 questions (Q5 conditional)

Ask **intent** ("what are you trying to do"), not requirements ("what do you need"). Keep it shallow:
one pass, no deep drill-down. Ask the question text in the user's language (Korean below). Each answer
maps to exactly one spec field — the mapping is authoritative.

Ask one at a time; accept short answers; infer sensible defaults rather than interrogating.

## Q1 — Mission (free text) → `spec.mission`

> **이 프로젝트로 무엇을 이루려 하나요? 한두 문장으로요.**

Capture the outcome, not a feature list. Becomes the `## 미션` line of the generated core.

## Q2 — Work type (single select) → `spec.workType`

> **주로 어떤 종류의 일인가요? (하나)**
> ① 코드  ② 문서·글  ③ 리서치·분석  ④ 운영·조율  ⑤ 혼합

Store the enum value: `코드 | 문서·글 | 리서치·분석 | 운영·조율 | 혼합`. Steers the default role mix
for Q3 (code → lean executor+reviewer; research → researcher; etc.) but does not itself add agents.

## Q3 — Recurring delegable tasks (free, 2–4 items) → `spec.agents`

> **반복해서 위임하게 될 일이 뭔가요? 2~4개만 적어주세요.**
> (예: "코드 리뷰", "외부 레퍼런스 조사", "대량 구현·마이그레이션")

Each item becomes ONE seed agent. For each, derive:
- **name** — a PROJECT-DOMAIN Korean noun (e.g. "코드리뷰어", "스펙조사가", "백엔드실행가"). Never a
  generic role word.
- **role** — classify the task: hands-on building/editing → `execute`; verifying/judging without editing
  → `review`; gathering external references → `research`.
- **triggers** — 2–4 short Korean phrases that should route to this agent.
- **focus** — one sentence: what this agent owns in THIS project (this is where per-project tailoring lives).

## Q4 — Irreversible / outward-facing actions (free) → `spec.gates`

> **되돌릴 수 없거나 외부로 나가는 행동이 있나요? (배포·발행·전송 등)**

Each named action becomes a gate string. These are the actions the generated core routes through the
`advisor` go/no-go gate. If none, use an empty list (the generator renders a "없음" placeholder).

## Q5 — Output language/style (conditional) → `spec.responseStyle`

Ask ONLY if the user hasn't already implied it. Default without asking: `개조식 한국어`.

> **산출물·답변의 기본 언어와 문체는? (기본값: 개조식 한국어)**

## Field mapping summary

| Question | Spec field | Shape |
|---|---|---|
| Q1 mission | `mission` | string |
| Q2 work type | `workType` | enum (5 values) |
| Q3 recurring tasks | `agents[]` | `{name, role, triggers[], focus}` |
| Q4 irreversible actions | `gates[]` | string[] |
| Q5 language/style | `responseStyle` | string (default `개조식 한국어`) |
| (fixed) | `chassisVersion` | integer = current canon version |

After the interview, author the spec per `spec-schema.md`, then run the generator.
