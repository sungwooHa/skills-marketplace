# {{DECK_TITLE}} — Deck Rules

## 기본 정보

- **제목**: {{DECK_TITLE}}
- **부제**: {{DECK_SUBTITLE}}
- **발표자**: {{PRESENTER}}
- **일자**: {{DECK_DATE}}
- **청중**: {{AUDIENCE}}
- **시간**: {{DURATION}}
- **슬라이드 수**: {{SLIDE_COUNT}}
- **목적**: {{PURPOSE}}

## 산출물 구조

| 파일 | 역할 |
|------|------|
| `index.html` | 메인 슬라이드 뷰어 (1920x1080, F=전체화면, P=발표자뷰) |
| `스크립트_화면.html` | 발표자 스크립트 뷰어 (BroadcastChannel sync) |
| `index.pptx` | 청중 배포용 PPT (선택) |
| `assets/fonts/` | 덱 폰트 `DeckSans-200`~`DeckSans-900` .otf (선택 — 없으면 시스템 sans 폴백) |
| `assets/images/` | 슬라이드 이미지 에셋 |
| `assets/videos/` | 슬라이드 비디오 에셋 |

## 편집 규칙

- index.html 수정 시 스크립트_화면.html과 1:1 sync 유지 필수
- 슬라이드 추가/삭제 시 양쪽 파일 동시 수정
- 폰트는 assets/fonts/의 `DeckSans` 패밀리만 사용 (미설치 시 시스템 sans 폴백)
- 외부 URL 참조 금지 (자급자족 원칙)

## 디자인 안티패턴 (금지)

아래 요소는 "AI가 만든 티"가 강하게 나므로 사용 금지.

| 금지 요소 | 이유 | 대안 |
|-----------|------|------|
| 네모 박스 / 카드 격자 | AI 생성물 전형 레이아웃. 시각적 위계 소멸 | 타이포 크기·굵기 + 여백으로 위계 표현 |
| `border-left` 세로선 인용 | AI 챗봇 UI 패턴 | 큰 따옴표, 들여쓰기, 폰트 크기 강조 |
| `<hr>` / em dash 구분선 | 기계적 구분. 인간 발표에서 불사용 | 여백, 슬라이드 분리, 자연어 연결 |
| 텍스트 화살표 (`→`) 플로우 | 다이어그램 외 텍스트에 남용 시 AI 패턴 | 자연어 서술, 번호, 시각적 타임라인 |

## 이미지 배경 원칙

- 전체 슬라이드의 **30% 이하**만 이미지 배경 사용 (과용 시 산만)
- 이미지 배경 슬라이드 필수 구조:
  ```html
  <div class="slide" style="background: url('...') center/cover">
    <div class="overlay"></div>  <!-- 그라데이션 오버레이 필수 -->
    <div class="content">...</div>
  </div>
  ```
- `file://` 프로토콜에서는 상대 경로 이미지가 깨질 수 있음 → HTTP 서버로 열 것

## PPTX 재빌드

```bash
python scripts/build_pptx_screenshot.py index.html
```
