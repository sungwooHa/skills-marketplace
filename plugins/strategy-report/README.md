# strategy-report

한국어 전략/기획 보고서를 **자립형 A4 인쇄용 HTML**과 **짝이 맞는 Word(.docx)**로 찍어내는 경량
보고서 빌더. 하나의 마크다운 소스에서 두 산출물이 나온다.

## 무엇을 하나

- **개조식 · 선언문 우선 구조** — 섹션마다 한 줄 선언 → 굵은 주장 불릿. `그라운드룰_기획서` 스타일.
- **재사용 시각 컴포넌트** — 사이클, KPT, 점검 카드, 달력, 선언문 박스 (HTML 한정).
- **단일 소스 → 2종 산출** — 마크다운 하나로 HTML(리치 컴포넌트) + docx(맑은 고딕 A4) 동시 생성.
- **경량 워크플로우** — 프레임 확정 → 작성 → 렌더 2종 → 가벼운 검증. 인터뷰·멀티에이전트 검증은 선택.

## 구성

```
skills/strategy-report/
  SKILL.md
  scripts/md_to_docx.py           # Markdown → 스타일드 A4 .docx (python-docx)
  references/html-template.html   # 자립형 A4 인쇄 HTML 셸 + 컴포넌트 갤러리
  references/report-structure.md  # 섹션 패턴 · 개조식 규칙 · AI 티 회피 목록
```

## 사용

`/plugin install strategy-report@skills-marketplace` 후:

> "전략 보고서 만들어줘" / "이 내용 그라운드룰 문서로" / "Word 보고서로 뽑아줘"

docx 렌더러는 `python-docx`가 필요하다 (`pip install python-docx`). HTML은 브라우저만 있으면 된다.
