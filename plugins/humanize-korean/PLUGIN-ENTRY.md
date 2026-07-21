# Marketplace registration — apply by hand

`.claude-plugin/marketplace.json` and the root `README.md` were deliberately
**not** touched on this branch: parallel plugin work makes both of them the known
conflict point. Apply the two snippets below at merge time.

## 1. `.claude-plugin/marketplace.json` → append to `plugins[]`

```json
{
  "name": "humanize-korean",
  "source": "./plugins/humanize-korean",
  "description": "한글 AI 티 제거 번들. AI가 쓴 한국어를 내용 불변으로 문체·리듬만 윤문. taxonomy v2.0 — 10대 카테고리 71패턴, 한국 번역학계 8대 번역투 계보 + post-editese 3축 반영. Fast(monolith 1콜)/Strict(5인 파이프라인) 2모드. 회귀 하네스 168 assertion 동반.",
  "version": "2.0.0",
  "keywords": ["humanize", "korean", "한글", "윤문", "번역투", "translationese", "ai-detection", "post-editing", "style-rewriting"]
}
```

## 2. Root `README.md` → add one row to the 수록 스킬 table

```markdown
| [humanize-korean](./plugins/humanize-korean) | 2.0.0 | 한글 AI 티 제거 — 내용 불변으로 문체·리듬만 윤문. 71패턴 분류 체계 + 회귀 하네스 | 3 |
```

Match the existing column order before pasting — the table shape may have moved.

## 3. Badge count

The root README badge currently under-counts the catalog. Whoever merges last
should reconcile it against the actual `plugins[]` length rather than
incrementing blindly.

## Verify after merging

```bash
python3 plugins/humanize-korean/tests/run_tests.py   # expect 168/168
```
