# research-harness

빠른 병렬 웹 리서치. 하위 질문마다 리서처를 동시에 띄우고, 분석가 한 명이 합쳐 출처 달린 보고서를 낸다.

```
질문 → [Frame: 질문 · 검증할 내부 주장 · 출력 언어 · 폴더]
     → [Split: 하위 질문 3~6개]
     → researcher × N  (sonnet, 병렬 — 한 메시지에 동시 디스패치)
     → research-analyst (opus — 병합 · 충돌 판정 · 주장 판정 · 핵심 출처 재확인)
     → report.md
```

| 구성 | 모델 | 역할 |
|---|---|---|
| `skills/research` | — | 오케스트레이터: 쪼개기 → 병렬 디스패치 → 합성 → 보고 |
| `agents/researcher` | sonnet | 하위 질문 1개. 주장마다 실제로 연 출처 + 원문 인용, 내부 주장 판정 |
| `agents/research-analyst` | opus | 노트 병합 · 충돌 판정 · supported / contradicted / unverifiable · 재확인 |

산출물: `<run>/r<N>-<slug>.md`(하위 질문별 노트, 영어) + `<run>/report.md`(사용자 언어).

트리거: "조사해줘", "리서치", "시장 조사", "보강해", 공개 자료로 주장 검증.

설치:

```
/plugin marketplace update skills-marketplace
/plugin install research-harness@skills-marketplace
```
