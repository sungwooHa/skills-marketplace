# Quick Rules — Monolith Fast Path (v2.0.0)

Slim rulebook the `humanize-monolith` agent reads once per run so that detection, rewriting, and self-check all finish in a single call. Distilled from the full taxonomy (`ai-tell-taxonomy.md`) down to the S1/S2 core patterns, each compressed to one line together with its fix.

**Format:** one line of definition, one line of prescription. No examples. Pattern IDs map 1:1 to the full taxonomy.

**Do-NOT (excluded from both detection and rewriting):** 고유명사·제품명·모델명·기관명, 수치·날짜·단위, 큰따옴표 안 직접 인용, 법률 조문, 수학·화학·통계 표기, 영어 약어(LLM·GPU·MCP·API 등 업계 표준).

**Over-polish guard:** change rate above 30% = warning; above 50% = hard stop and roll back.

---

## A. Translation-ese (번역투)

| ID | Pattern | Severity | Fix |
|---|---|---|---|
| A-1 | "~에 대해(서)" | S1 | Attach the object particle directly ("X에 대해 논의" → "X를 논의") |
| A-2 | "~를 통해/통하여" 남발 | S1 | Spread across "~로", "~해서", "~함으로써" |
| A-3 | "~에 있어(서)" | S1 | Use "~에서", "~을 볼 때" |
| A-4 | "~라는 점에서" 3회+ | S2 | Use "~서", "~라는 이유로" |
| A-5 | "~와 관련하여/관련된" | S2 | Use "~에", "~의" |
| A-6 | "~에 기반하여/바탕으로" 남발 | S2 | Use "~로", "~을 보고" |
| A-7 | "가지고 있다" / have·make·take·give + N 직역 | S1 | Restore an adjective or verb, or use a double-subject construction ("회의를 가지다" → "회의를 했다", "강한 경쟁력을 가지고 있다" → "경쟁력이 강하다") |
| A-8 | 이중 피동 "~되어진다" | S1 | Use active voice or a single passive ("판단되어진다" → "판단된다") |
| A-9 | "~에 의해" 피동 | S2 | Make the agent the subject ("AI에 의해 생성" → "AI가 만든") |
| A-10 | "~할 수 있다" 남발 | S2 | State it flatly ("높일 수 있다" → "높인다") |
| A-11 | "~을 위해" 목적절 남발 | S2 | Use "~려고", "~위한" |
| A-15 | 추상 주어 + 만능 동사 / 사역·인지 동사 | S2 | Restore a concrete subject; render causatives as an adverbial clause ("X 때문에/덕분에/로 인해"); split cognition verbs (suggest/show/indicate/reveal) into "~에 따르면 ~이다" or "~으로 ~이 드러났다" |
| A-16 | "그/그녀/그것/그들" 단락 ≥3회 영어 대명사 직역 | S1 | Drop 50%+ to 영형(생략), or replace with 호칭·명사구 (김도훈 2009) |
| A-18 | 명사 앞 ≥3어절 관형구·관계절 좌향 수식 | S2 | Split the sentence or use a trailing appositive clause ("X를 만났는데, 그 X는 …") (박옥수 2018) |
| A-19 | 이중 조사 "~에서의/~에로의/~으로의/~에의/~으로부터의" | S2 | Unpack into a clause or phrase. Simple ~의 is out of scope (김정우 2007) |

## B. Excess English Citation and Terminology

| ID | Pattern | Severity | Fix |
|---|---|---|---|
| B-1 | 한글 + 괄호 영어 매번 ("~(Sovereign AI)" 처럼) | S2 | Gloss only on first occurrence; Korean alone afterward |
| B-2 | 영어 어휘 직역 가능한데 그대로 | S2 | Render in Korean, but keep industry-standard terms as-is |

## C. Structural AI Patterns

| ID | Pattern | Severity | Fix |
|---|---|---|---|
| C-5 | 이모지 남발 | S1 | Delete all of them in column and report genres |
| C-7 | "먼저·반면·결국" 3단 공식 | S2 | Cut to one or two connectives, or dissolve them into the prose |
| C-8 | "A인가·B인가" 대구 반복 | S2 | Keep one; turn the rest into plain declaratives |
| C-9 | 숫자 괄호 인덱싱 "(1)·(2)·(3)" | S2 | Dissolve into the prose, or use plain line breaks |
| C-10 | 콜론 부제 헤딩 "X: Y" 반복 | S1 | Shorten the heading, or make it declarative |
| C-11 | 연결어미 뒤 쉼표 (-고/-며/-지만/-며서/-아서/-어서 직후 쉼표) | S1 | Remove the comma. 6+ occurrences = strong signal. KatFish separation 4.84x |

## D. AI Signature Phrases

| ID | Pattern | Severity | Fix |
|---|---|---|---|
| D-1 | 결산 피벗 lexicon "결론적으로/따라서/이를 통해/그러므로/요약하면/정리하면" | S1 | Above 3 occurrences, swap 1-2 for a different closing and delete the rest |
| D-2 | "시사하는 바가 크다/주목할 만하다" | S1 | Delete, or replace with a concrete conclusion |
| D-3 | "본질적으로/핵심적으로" | S1 | Delete |
| D-4 | hype 어휘(파격적·압도적·강력한·획기적·치명적) 3회+ | S1 | Reduce to concrete figures and facts |
| D-5 | 의인화 추상 주어("기술이 묻는다·시대가 부른다") | S1 | Use a person or institution as the subject |
| D-6 | 결말 공식 "~할 때다/~해야 한다/~지금이야말로" | S1 | Close with a declarative, or delete |
| D-7 | 변환 공식 "X에서 Y로" 반복 | S2 | Keep one; write the rest as ordinary description |

## E. Rhythm and Sentence Endings

| ID | Pattern | Severity | Fix |
|---|---|---|---|
| E-1 | 문장 길이 균일(stdev 8 미만) | S2 | Deliberately place 1-2 short sentences and one long sentence in each paragraph |
| E-2 | 동일 종결어미 "~다" 4문장 연속 + 진행형 "~고 있다" 자동 매핑 | S2 | Vary with "~었다·~ㄴ다·~는다·~기 마련이다·~ㄹ 것이다". Reduce "~고 있다" to simple tense wherever possible ("읽고 있다" → "읽는다") |
| E-7 | 청자 경어법 4단계(해라/하게/하오/해요/합쇼) 일관성 손실 (대화·구어 한정) | S2 | No mixing within a paragraph; keep the formality level consistent (김혜영 2019, estimated) |

## F. Excess Modification and Redundancy

| ID | Pattern | Severity | Fix |
|---|---|---|---|
| F-4 | 한자어 명사화 -성/-적/-화 + 영어 명사화 -tion/-ment/-ness/-ity 누적 (한 글 12회+) | S2 | Restore to verb or adjective roots ("the implementation of the policy" → "정책 시행" 또는 "정책을 시행하기") |
| F-5 | "~적 N" 추상 체인 ("전략적 함의·실천적 기반") | S2 | Use noun+noun, or unpack it ("전략 함의·실천의 기반") |

## G. Hedging

| ID | Pattern | Severity | Fix |
|---|---|---|---|
| G-1 | "~것이다/~할 것이다" 미래 단정 남발 | S2 | Use present or definite forms |
| G-2 | "~로 보인다/~인 듯하다" 추정 남발 | S2 | Assert wherever assertion is warranted |
| G-3 | 안전 균형 lexicon "양쪽 모두/두 가지 모두/장점도 있지만/신중하게/균형" | S2 | Above 4 occurrences, swap 1-2 for the writer's own position |

## H. Connective Overuse

| ID | Pattern | Severity | Fix |
|---|---|---|---|
| H-1 | 문두 접속사 "또한·따라서·즉·나아가·아울러·게다가·더욱이" 5회+ | S1 | Delete most of them. Let the sentences themselves carry the flow |
| H-3 | 메타 진입 "이는·이 점에서·이 관점에서·이 말은" 3회+ | S1 | Dissolve into the prose, or delete |
| H-4 | "즉" 남발 | S2 | Limit to one |

## I. Formal and Bound Nouns

| ID | Pattern | Severity | Fix |
|---|---|---|---|
| I-1 | "~인 것이다/~한 것이다" 결말 | S1 | Use a plain declarative |
| I-2 | "X은 ~라는 점에 있다" | S2 | Say it directly as "X는 ~다" |
| I-3 | "~다는 뜻이다/~다는 의미다" 결말 | S2 | Unpack it into the body text |
| I-4 | 권고형 결말 "~해야 한다·~합니다" 반복 | S2 | Use declarative assertion |

## J. Visual Decoration

| ID | Pattern | Severity | Fix |
|---|---|---|---|
| J-1 | 헤딩 마크다운 ** 강조 남발 | S2 | Remove nearly all of it in column and report genres |
| J-2 | 따옴표 강조 5회+ | S1 | Keep one or two key ones; make the rest plain |
| J-3 | 불릿 리스트 (장르가 칼럼·리포트일 때) | S2 | Merge into paragraph prose |

---

## Self-Check Checklist (run by monolith right after rewriting)

Check the following within five seconds of finishing the rewrite. A violation on any single item means rolling that edit back.

1. **Proper nouns, figures, dates, and quotations 100% preserved**: not one character differs from the source
2. **Change rate**: at or below 30% (stop work above 50%)
3. **No genre drift**: a column has not turned into an essay or literary piece; a report has not slid into blog voice
4. **Register preserved**: if the source is formal (격식체), the output stays formal. Never drop to 평어체
5. **Zero residual S1 patterns**: none of the core S1 set — D-1~D-7, A-7, A-8, A-16, C-5, C-10, C-11, H-1, I-1, J-2 — remains
6. **No invented expression**: no metaphor, flourish, or literary phrasing absent from the source was added during the rewrite

On violation: roll the edit back, rewrite again, recheck. At most one self-loop. If it still does not resolve, emit the result as-is but record "자가검증 미통과 항목 N건" in `summary.md`.

## Grading Criteria (self-scored)

- **A**: 0 residual S1, at most 2 residual S2, change rate 10-25%, all 6 self-check items pass
- **B**: 0 residual S1, at most 4 residual S2, at least 5 self-check items pass
- **C**: 1-2 residual S1, or 4 or fewer self-check items pass — recommend strict mode to the user
- **D**: 3+ residual S1, or change rate above 50% — recommend stopping work

> v2.0.0 adds or strengthens 8 patterns: A-7·A-15·A-16·A-18·A-19·E-2·E-7·F-4 (**A-17 on hold**). The full academic citation record ships beside this file as `scholarship.md`. The post-editese 3-axis metric is not reflected in this rulebook (metric-only track). A-17 (무정물·추상명사 '-들') has strong academic anchors (전영철 2007·곽은주·진실로 2011) but produced zero positives on an external run (six wiki articles, 2026-05-07) — re-evaluate under the same ID in v2.1 after a run on raw NMT output.
