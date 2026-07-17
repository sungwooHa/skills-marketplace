# travel-proposal

여행 기획서(계획서)를 **오프라인에서도 동작하는 자립형 인터랙티브 HTML** 한 장으로 만들어 주는 Claude Code 스킬.

파일 하나만 있으면 인터넷 없이도, 다른 사람에게 그대로 전달해도 사진·지도·줌·탭이 전부 동작합니다.

## 특징

- **단일 자립형 HTML** — 사진·Leaflet 라이브러리·지도 타일까지 전부 base64 내장. 외부 리소스 요청 0.
- **인터랙티브 오프라인 지도** — 줌인·줌아웃·팬 되는 Leaflet 지도, 마커마다 구글맵 링크. 타일까지 내장이라 오프라인에서도 표시.
- **주제별 탭 구성** — 컨셉 / 숙소 / 일정 / 쇼핑 / 맛집·술 / 예산·팁. 일정은 날짜, 쇼핑은 지역, 맛집·술은 아침·점심·저녁·술집·커피디저트 서브탭.
- **카드 UI** — 맛집·쇼핑·디저트를 카드로. 사용자의 구글맵 저장 메모를 그대로 인용.
- **Airbnb 디자인 시스템** — 화이트 캔버스, 코럴(#ff385c) 액센트, 둥근 카드·알약 탭, 사진 우선. 다른 디자인으로 교체 가능.
- **한국어 개조식** — AI 티 없는 간결한 산출물. 병렬 리서치 서브에이전트로 영업시간·가격을 검증(불확실하면 "확인 필요" 표기).
- **모바일 대응 + 다크모드**.

## 설치

### 방법 ① 플러그인 마켓플레이스 (권장, 클론 불필요)

```
/plugin marketplace add ttlhi10/travel-proposal-skill
/plugin install travel-proposal@travel-proposal-skill
```

### 방법 ② 클론 + 스크립트

```bash
git clone https://github.com/ttlhi10/travel-proposal-skill.git
cd travel-proposal-skill
./install.sh
```

`~/.claude/skills/travel-proposal` 에 심링크합니다(저장소 수정 즉시 반영). `--copy` 로 복사 설치, `--force` 로 기존 파일 백업 후 덮어쓰기.

## 사용

새 세션에서:

```
/travel-proposal
```

또는 자연어로 "고베 여행 기획서 만들어줘", "삿포로 4박5일 계획서" 처럼 요청하면 발동합니다.

스킬이 목적지·날짜·취향을 확인하고, 병렬 리서치 후 자립형 HTML을 만들어 오프라인·모바일 검증까지 마친 뒤 전달합니다.

## 피드백으로 강화

이 스킬은 피드백을 받을수록 좋아집니다. 사용자가 선호를 말하면 `.claude/skills/travel-proposal/references/feedback-log.md` 에 날짜와 함께 누적되어, 다음 기획서가 자동으로 물려받습니다.

## 구성

```
.claude/skills/travel-proposal/
  SKILL.md                       # 파이프라인·불가침 규칙
  references/
    design-airbnb.md             # 디자인 토큰·컴포넌트(Airbnb)
    build-and-verify.md          # 빌드 기술·오프라인 지도 내장·검증 체크리스트
    feedback-log.md              # 누적 피드백(사용할수록 강화)
```

## 업데이트 / 제거

- 업데이트: `./update.sh` (새 버전 자동 감지 + 적용) · `./update.sh --check` (감지만)
- 제거: `./uninstall.sh` (이 저장소 심링크만 제거) · 마켓플레이스: `/plugin uninstall travel-proposal`

## 요구 사항

- Claude Code (플러그인/스킬 지원 버전)
- Playwright MCP (지도 타일·검증에 사용), ffmpeg (이미지 압축), python3
- macOS · Linux의 `bash` (Windows는 WSL 권장 — 심링크 때문에)

## 라이선스

MIT
