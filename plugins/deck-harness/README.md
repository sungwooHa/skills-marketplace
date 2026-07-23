# deck-harness

발표자료 한 벌을 **에이전트 팀이 협업해서** 만들고, **스스로 검증**하고, **검증 결과를 다음 덱에 누적**하는 하네스.

산출물은 3종 세트다.

| 파일 | 역할 |
|---|---|
| `output/{title}/index.html` | 청중용 메인 슬라이드 뷰어 (1920×1080, `F` 전체화면 / `P` 발표자뷰) |
| `output/{title}/스크립트_화면.html` | 발표자용 스크립트 뷰어 (BroadcastChannel로 메인 덱과 동기화) |
| `output/{title}/index.pptx` | 배포용 PPT (선택 — HTML 스크린샷 + 발표자 노트 임베드) |

## 설치

```
/plugin marketplace add sungwooHa/skills-marketplace
/plugin install deck-harness@skills-marketplace
```

PPTX 빌드와 빌드 검증에는 Python 의존성이 필요하다 (덱 HTML만 만들 거면 없어도 된다):

```bash
pip install -r "<plugin>/skills/generate-presentation/scripts/requirements.txt"
playwright install chromium
```

## 사용

빈 폴더에서 그냥 말하면 된다.

```
발표자료 만들어줘: 분기 OKR 리뷰, 임원 대상 15분
```

참고자료가 있으면 먼저 떨궈두면 에이전트가 알아서 찾아 쓴다 (없어도 그냥 돈다).

```bash
mkdir -p output/분기_OKR_리뷰/reference && cp ~/자료/* $_
```

## 파이프라인 — 3단계 + 피드백

```
Phase 1  PLAN     presentation-strategist ∥ design-director  →  _workspace/plan.md
                  ── 사용자 승인 게이트 (여기서 멈춘다) ──
Phase 2  BUILD    asset-curator → deck-builder               →  index.html · 스크립트_화면.html
Phase 3  VERIFY   build-verifier ∥ intent-verifier ∥ design-critic
                  ∥ delivery-critic ∥ naturalness-critic     →  _verify_*.md  (5축 병렬)
Phase 3.5 FEEDBACK  검증 결과 누적 → 다음 덱의 체크리스트로 승격
```

**게이트는 두 개뿐이고, 둘 다 강하다.**
- Phase 1 뒤 `plan.md` 사용자 승인 — 승인 전에는 빌드로 못 넘어간다.
- Phase 3에서 5축 중 **한 축이라도 CRITICAL이면 통과 불가**. 사용자에게 4지선다(자동수정/무시/중단/재생성)를 강제한다.

## 에이전트 9종

| Phase | 에이전트 | 하는 일 |
|---|---|---|
| PLAN | `presentation-strategist` | 청중·의도(감정/생각/행동)·핵심 메시지·스토리 아크·**검증 기준**을 plan.md에 못박음 |
| PLAN | `design-director` | 시각 컨셉·컬러·타이포·슬라이드 패턴 매핑 확정 |
| BUILD | `asset-curator` | 이미지·비디오 큐레이션, 차트를 인라인 SVG로 생성 (외부 URL 금지) |
| BUILD | `deck-builder` | plan.md → HTML 슬라이드 + 발표 스크립트, 메인↔스크립트 1:1 sync 책임 |
| VERIFY | `build-verifier` | Playwright/python-pptx로 렌더·에셋 404·sync·PPTX 무결성 + **외부 요청 0**(네트워크 가로채기 — CDN이 성공 로드돼도 CRITICAL)·**슬라이드 경계 밖 잘림**·**PDF 페이지 수 대조**(내보내기 있을 때) |
| VERIFY | `intent-verifier` | plan.md가 약속한 의도가 산출물에 실제로 있는지 1:1 대조 |
| VERIFY | `design-critic` | 디자인 품질 (Tufte / Reynolds / Bringhurst) |
| VERIFY | `delivery-critic` | 발표 품질 (Anderson / Gallo / Duarte) |
| VERIFY | `naturalness-critic` | 한국어 "AI 티" 탐지 — 생략 불가한 5번째 축 |

**제작자와 비평가는 항상 다른 페르소나다.** `design-director`가 자기 디자인을 비평하지 않고
`design-critic`이 한다. 자기 작품 자기 심사는 심사가 아니다.

## 피드백 루프 — 캡처는 싸게, 승격은 비싸게

검증에서 나온 CRITICAL/ERROR와 세션 중 사용자 교정은 `feedback/raw/`에 **원문 그대로** 즉시 쌓인다
(로컬 전용, push 안 됨). 완료 시점에 딱 한 번 **콘텐츠를 제거하고 방법론 규칙으로 일반화**해서
`feedback/lessons.md` · `patterns.json`으로 승격하고, 2회 이상 반복된 패턴은 해당 에이전트의
`## Learned patterns` 섹션에 체크리스트로 박힌다.

콘텐츠 방화벽은 승격 관문에서만 집행한다: 인명·조직명·행사명·수치·슬라이드 문구는 승격본에 못 올라간다.
자기점검 한 줄 — *"이 줄만 보고 발표 내용을 유추할 수 있나?"*

## 스킬 2종

| 스킬 | 트리거 |
|---|---|
| `generate-presentation` | "발표자료 만들어줘", `/generate-presentation`, "템플릿으로 발표 만들어" |
| `feedback-consolidator` | Phase 3 완료 후 자동, "피드백 통합", `/feedback-consolidate` |

## 프로젝트 설정

폰트·출력 경로·발표자 기본값처럼 프로젝트마다 다른 값은 하드코딩하지 않는다.
필요하면 `deck-harness.local.md.example`을 `.claude/deck-harness.local.md`로 복사해서 채운다.
**전부 선택이다** — 파일이 없으면 기본값으로 그냥 돈다.

### 폰트

**폰트 바이너리는 동봉하지 않는다.** 템플릿은 `DeckSans` 8 weight를 선언하고
`-apple-system, sans-serif`로 폴백하므로 아무것도 설치하지 않아도 정상 렌더된다.
특정 서체를 쓰려면 `font_dir`에 8개 weight를 `DeckSans-200.otf` … `DeckSans-900.otf`로 넣는다.
덱에 폰트를 실어 배포할 거면 **임베딩·재배포 라이선스를 먼저 확인**할 것.

## 라이선스

MIT. 동봉된 템플릿·스크립트·에이전트 정의 전부 포함.
폰트는 동봉하지 않으므로 사용자가 넣는 서체의 라이선스는 사용자 책임이다.
