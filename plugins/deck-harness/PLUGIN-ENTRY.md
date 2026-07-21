# deck-harness — marketplace 등록 스니펫

이 브랜치는 `.claude-plugin/marketplace.json` 과 루트 `README.md` 를 **건드리지 않았다**
(두 플러그인이 병렬 준비 중이라 충돌 지점). 오케스트레이터가 아래 두 조각을 통합한다.

## 1. `.claude-plugin/marketplace.json` → `plugins[]` 에 추가

```json
{
  "name": "deck-harness",
  "source": "./plugins/deck-harness",
  "description": "발표자료(덱) 제작 하네스 — 9개 에이전트가 PLAN→BUILD→VERIFY 3단계로 HTML 슬라이드 + 발표자 스크립트 뷰어 + PPTX를 만든다. plan.md 사용자 승인 게이트 + 5축 병렬 검증(빌드/의도/디자인/발표/한국어 자연스러움), 1축이라도 CRITICAL이면 통과 불가. 검증 결과는 피드백 루프로 누적돼 다음 덱의 에이전트 체크리스트가 된다.",
  "version": "1.0.0",
  "keywords": ["presentation", "deck", "slides", "발표자료", "슬라이드", "pptx", "keynote", "html-slides", "agent-team", "verification-gate", "presenter-script"]
}
```

## 2. 루트 `README.md` "수록 스킬" 표에 추가할 행

```markdown
| [deck-harness](plugins/deck-harness) | 발표자료 덱 제작 하네스 — 에이전트 9종 · 3단계 게이트 · 5축 검증 · 피드백 누적 | `/plugin install deck-harness@skills-marketplace` |
```

> 배지가 `skills-N` 형식이면 카운트도 함께 올려야 한다 (현재 표와 배지가 이미 불일치 상태 —
> 260721 인벤토리 §8-7 참조).
