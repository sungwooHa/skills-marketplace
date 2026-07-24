# Report structure & writing rules

The house style for a Korean strategy/planning report: **개조식** (terse bullet prose), each
section opening with a **one-line declaration**, tables for structure, and visual components where
a list would be flat. This file defines the section patterns, the writing discipline, and the
AI-tell patterns to avoid. The writer in step 2 of the skill follows this exactly.

## The single-source rule

Write **one Markdown file**. Both deliverables (A4 HTML, Word docx) render from it. The docx
carries the linear content 1:1; the HTML additionally promotes marked sections into visual
components. Never maintain two divergent copies.

## Section grammar

Every `##` section is built the same way:

```
## N. <section title>
> <one-sentence declaration for this section>     ← becomes the highlight/declaration box
- **<claim>** <supporting sentence>.
- **<claim>** <supporting sentence>.
```

- The **declaration** is the section's thesis in one sentence. It must serve the report's single
  핵심 메시지. If a section has no declaration, it has no reason to exist — cut or merge it.
- Each bullet leads with a **bolded claim**, then one sentence of support. Not two ideas per bullet.
- Prefer 3–5 bullets per section. More than that → split the section or move to a table.

## Section patterns (pick and adapt in step 1)

**A. 실행 계획 / 그라운드룰 (why → what → how → pledge)**
1. 왜 함께여야 하는가 / 왜 지금인가 — the problem and the stakes
2. 무엇을 실행하는가 — the concrete actions (often a `cycle-row` or table)
3. 어떻게 운영하는가 — cadence, roles, schedule (often a `calendar`)
4. 무엇으로 점검하는가 — how success is checked (often a `check-row`)
5. 선언 — the pledge (`declaration` box)

**B. 전략 제안 (situation → options → recommendation → plan)**
1. 배경·문제 정의
2. 선택지 비교 (table)
3. 권고안과 근거
4. 실행 로드맵 (calendar / table)
5. 기대 효과·리스크

**C. 회고·개선 (KPT-driven)**
1. 이번 주기 요약
2. Keep / Problem / Try (`kpt-row`)
3. 다음 주기 실행 항목 (table)

Component → use when:
- `cycle-row` — a repeating loop or ordered process (2–5 steps).
- `kpt-row` — any three-way grouping you want color-coded (Keep/Problem/Try, 좋음/문제/시도).
- `check-row` — N equal pillars/criteria side by side.
- `calendar` — a cadence or schedule laid on months/weeks.
- `declaration` — a framed pledge/thesis, usually the closing section.

## Writing rules (개조식 discipline)

- **Decisive verb endings.** `…하겠다`, `…한다`, `…이다`. Not `…하고자 합니다`, `…라고 볼 수
  있습니다`, `…인 것 같다`. A plan commits; it does not hedge.
- **One idea per bullet.** Bold the claim so a skimming reader gets the spine from bold text alone.
- **Concrete over abstract.** "격주 목요일 스프린트 리뷰" beats "정기적인 소통 강화".
- **No filler openers.** Cut "먼저", "또한", "그리고", "이를 통해" when they carry no meaning.
- **Numbers and nouns, not adjectives.** Say the date, the count, the owner.

## AI-tell / 번역투 to avoid

These make a report read as machine-written. Scan for them in the verify pass.

- **번역투 명사구 남발** — "~에 대한", "~에 있어서", "~를 통한", "~로 인한" stacked. Rewrite to verbs.
- **기계적 병렬** — every bullet the same length/shape/rhythm. Vary sentence length deliberately.
- **접속사 남발** — "또한/그리고/하지만/따라서" opening consecutive sentences.
- **형식명사 과다** — "~하는 것", "~라는 점", "~할 수 있다는 측면" as padding.
- **영어 병기 남발** — needless "(alignment)", "(synergy)" after Korean terms.
- **과잉 완충** — "~라고 할 수 있습니다", "~인 경향이 있습니다" softening a claim that should be flat.
- **불릿·이모지 과다** — decorative emoji, over-nesting. Keep it clean and printed-page serious.

If the prose still reads AI-ish after the pass, hand it to the `humanize-korean` skill (if
installed) for a content-invariant style rewrite.
