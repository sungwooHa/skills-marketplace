# humanize-korean

[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-D97757?logo=anthropic&logoColor=white)](https://github.com/sungwooHa/skills-marketplace)
[![version](https://img.shields.io/badge/version-2.0.0-informational)](./.claude-plugin/plugin.json)
[![skills](https://img.shields.io/badge/skills-3%20bundled-4C9A2A)](#수록-스킬-3종)
[![agents](https://img.shields.io/badge/agents-6-8a63d2)](#에이전트-6종)
[![taxonomy](https://img.shields.io/badge/taxonomy-v2.0%20·%2071%20patterns-ff6b35)](./skills/humanize-korean/references/ai-tell-taxonomy.md)
[![tests](https://img.shields.io/badge/tests-168%20assertions-2ea44f)](./tests/run_tests.py)
[![license](https://img.shields.io/badge/license-MIT-blue)](./NOTICE)

AI(ChatGPT · Claude · Gemini 등)가 쓴 한글 텍스트를 **내용은 한 글자도 건드리지 않고**
문체 · 리듬 · 표현만 자연스러운 한국어로 되돌립니다.

번역투, 과도한 영어 병기, 기계적 병렬, "결론적으로 / 시사하는 바가 크다" 같은 AI 특유
관용구, 피동태 남용, 문두 접속사 남발, 리듬 균일성, 이모지 · 불릿 남용 —
**10대 카테고리 × 71개 패턴**을 심각도(S1/S2/S3)로 분류해 스팬 단위로 탐지한 뒤 윤문합니다.

## 설치

```
/plugin marketplace update skills-marketplace
/plugin install humanize-korean@skills-marketplace
```

## 사용

```
/humanize <윤문할 텍스트 또는 파일 경로>
/humanize <텍스트> --strict          # 5인 파이프라인 강제
/humanize-redo 번역투만 다시          # 2차 윤문 · 부분 재실행
```

자연어로도 발동합니다 — "AI 티 없애줘", "번역투 제거", "사람이 쓴 것처럼 윤문".

## 두 가지 모드

| 모드 | 언제 | 구조 | 목표 시간 |
|---|---|---|---|
| **Fast** (기본) | 5,000자 이하 | `humanize-monolith` 단일 호출 — 탐지 · 윤문 · 자체검증을 한 콜에서. **도구 호출 3회 캡** | 2~3분 |
| **Strict** (`--strict`) | 8,000자 초과 시 자동 승급, 또는 명시 요청 | 5인 파이프라인 — 탐지 → 윤문 → (충실도 감사 ∥ 자연스러움 리뷰) → 최대 3회 재윤문 | 5~7분 |

Fast가 기본인 이유는 이력에 있습니다. v1.2~v1.4에서 voice profile · candidate pool ·
역할별 모델 분산을 얹었더니 5,000자 입력에 **25분**이 걸렸습니다. 병목은 모델 티어가
아니라 **에이전트 간 컨텍스트 재로딩과 도구 호출 chain**이었고, v1.5에서 단순 구조로
롤백한 뒤 monolith 한 콜만 남겼습니다. 3회 캡은 그 교훈의 이름입니다.

## 수록 스킬 3종

| 스킬 | 역할 |
|---|---|
| **humanize-korean** | 오케스트레이터. 모드 판정 · run_id 채번 · 에이전트 배선 · 결과 종합 |
| **humanize** | `/humanize` 진입 명령 (`disable-model-invocation` — 사용자가 칠 때만 발동) |
| **humanize-redo** | `/humanize-redo` 2차 윤문 · 카테고리/문단/강도 단위 부분 재실행 |

## 에이전트 6종

| 에이전트 | 모드 | 역할 |
|---|---|---|
| `humanize-monolith` | fast | 한 콜에서 탐지 + 윤문 + 자체검증 |
| `ai-tell-detector` | strict | span 단위 탐지 → JSON 리포트 |
| `korean-style-rewriter` | strict | 탐지 리포트 기반 수술적 윤문 |
| `content-fidelity-auditor` | strict | 의미 보존 감사 · 롤백 지시 |
| `naturalness-reviewer` | strict | 잔존 AI 티 + **과윤문** 탐지 |
| `korean-ai-tell-taxonomist` | 유지보수 | 분류 체계 SSOT 관리. 일반 실행 중에는 호출되지 않음 |

## 철칙

- **의미 불변이 최상위 규칙.** 사실 · 주장 · 수치 · 날짜 · 고유명사 · 직접 인용은 원문과 100% 일치.
- **변경률 30% 초과 = 경고, 50% 초과 = 강제 중단 · 롤백.**
- **register 보존.** 격식체 입력 → 격식체 출력. AI 티는 문법 · 수사이지 격식 자체가 아닙니다.
- **장르 이탈 금지.** 칼럼이 에세이로, 에세이가 문학체로 옮겨가지 않습니다.

`content-fidelity-auditor`와 `naturalness-reviewer`가 서로 반대 방향을 봅니다 — 전자는
"내용이 훼손됐나", 후자는 "너무 고쳤나". 윤문 스킬에서 진짜 위험은 덜 고치는 쪽이 아니라
**과윤문**입니다.

## 분류 체계 v2.0

세 축 위에 서 있습니다.

1. **이론 기반** — 한국 번역학계 8대 번역투 유형 (이영옥 2001 · 김정우 2007 ·
   김도훈 2009 · 김혜영 2019 등)
2. **정량 검증** — KatFish (Park et al., 인간 470 vs LLM 1,624편) + LREAD 인간 판독 실험.
   최강 단일 지표는 `C-11` 연결어미 뒤 쉼표로 **4.84배** 분리도
3. **전산 탐지** — post-editese 3축(Baker 1993 · Toury 1995 · Toral 2019)을 한국어
   정량 지표 14종으로 구현한 `metrics_v2.py`

v2.0 신규 4건 — `A-16` 영어 대명사 직역 · `A-18` 관계절 좌향 수식 · `A-19` 이중 조사 결합 ·
`E-7` 청자 경어법 일관성. 보강 4건 — `A-15` · `A-7` · `F-4` · `E-2`.
`A-17`(무정물 '-들')은 학술 근거는 강하나 실측 양성 0건이라 **보류** 상태입니다.

## 회귀 하네스

```bash
python3 plugins/humanize-korean/tests/run_tests.py
```

**168 assertion**, 실패 시 비0 종료. 표준 라이브러리만 씁니다.

| 그룹 | 검사 |
|---|---|
| A. 구조 | 매니페스트 · 프론트매터 · 이름/버전 정합 · 드롭된 에이전트 부재 |
| B. 배선 | SKILL.md가 부르는 에이전트 · references 링크가 실재하는가 · 폐기 파일 참조 잔존 |
| C. 경로 앵커링 | 개발자 홈 절대경로 0 · 상대경로 룰북 읽기 0 · `metrics_v2` 타 cwd 임포트 · baseline 해석 |
| D. 지표 | baseline 배선 · 코드↔baseline 드리프트 · **한글 픽스처 분리도**(AI 밀집 vs 사람 작성) |

D 그룹은 주장이 아니라 사실로 검증합니다. `tests/fixtures/`의 한글 지문 두 개를 넣고
피동 · 대명사 밀도 · '-들' 과용 · have/make 직역 · 이중 조사 · interference index가
**AI 지문 쪽에서 더 높게 나오는지**를 확인합니다. 뒤집히면 탐지 로직이 회귀한 것입니다.

`baseline_v2.json`의 모든 셀은 `_placeholder: true`입니다 — 비번역 한국어 코퍼스 대비
정밀 보정을 아직 안 했습니다. 러너가 `v2_baseline_warnings`로 매번 보고하므로 v2 z-score는
**방향 지시용**으로만 읽으십시오. 숨기지 않는 것이 이 파일의 설계 의도입니다.

## 출처

`epoko77-ai/im-not-ai` (MIT)에서 파생했습니다. 상세한 출처 · 라이선스 · 상류 대비
변경 내역은 [`NOTICE`](./NOTICE)를 보십시오.
