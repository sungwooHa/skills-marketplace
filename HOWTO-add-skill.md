# 새 스킬 추가 가이드

이 마켓플레이스에 스킬 하나를 추가하는 최소 절차.

## 1. 폴더 만들기

```
plugins/<skill-name>/
  .claude-plugin/plugin.json
  .claude/skills/<skill-name>/SKILL.md
  README.md            # 선택이지만 권장
```

`.claude/skills/<skill-name>/SKILL.md` 의 프론트매터:

```markdown
---
name: <skill-name>
description: 언제 발동하는지 한 줄. 트리거 키워드 포함.
---

# 스킬 본문 (지침)
```

`references/` 하위 파일로 긴 지침·자산을 분리해도 됩니다.

## 2. plugin.json

```json
{
  "name": "<skill-name>",
  "version": "1.0.0",
  "description": "...",
  "author": { "name": "sungwooHa" },
  "homepage": "https://github.com/sungwooHa/skills-marketplace/tree/main/plugins/<skill-name>",
  "repository": "https://github.com/sungwooHa/skills-marketplace",
  "license": "MIT",
  "keywords": ["..."],
  "skills": ["./.claude/skills/"]
}
```

## 3. 마켓플레이스 카탈로그에 등록

루트 `.claude-plugin/marketplace.json` 의 `plugins[]` 에 추가:

```json
{
  "name": "<skill-name>",
  "source": "./plugins/<skill-name>",
  "description": "...",
  "version": "1.0.0",
  "keywords": ["..."]
}
```

## 4. 목록 갱신 + 푸시

- 루트 `README.md` 의 "수록 스킬" 표에 한 줄 추가.
- `git add -A && git commit && git push`.
- 사용자: `/plugin marketplace update skills-marketplace` → `/plugin install <skill-name>@skills-marketplace`.

## 규칙

- 스킬 지침(SKILL.md·references·서브에이전트 프롬프트)은 **영어**로 작성(토큰 절약). 사용자에게 보여주는 산출물만 한국어.
- 하나의 스킬은 하나의 목적. 여러 목적이면 스킬을 나눈다.
- 버전은 스킬별로 관리(plugin.json + marketplace.json 양쪽 동기화).
