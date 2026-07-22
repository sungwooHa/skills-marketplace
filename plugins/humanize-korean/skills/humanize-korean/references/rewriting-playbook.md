# Korean Rewriting Playbook (v2.0.0)

The conversion rulebook the rewriter agent follows when it reads a detection report and actually fixes sentences. It expands each per-pattern prescription in `ai-tell-taxonomy.md` into an **executable substitution recipe**.

## 0. The Prime Directives

1. **Fidelity**: preserve facts, claims, figures, proper nouns, quotations, and causal relations character for character. Never fill in a gap on your own, even where the source is ambiguous.
2. **Tone Match**: formal input stays formal, an essay stays an essay. A rewrite never converts the original into a different genre.
3. **Locality**: do not rewrite whole sentences wholesale. Operate surgically on the spans that carry the AI tell.
4. **Natural > Perfect**: do not over-literarize. Target the median rhythm of an everyday Korean writer.
5. **Span-Grounded**: every change ties back to a span in the detection report. Never touch a span that was not flagged.
6. **Over-Polish Alarm**: if more than 50% of a sentence changes, the content has likely been damaged. Monitor the change rate.

## 1. Substitution Recipes by Category

### A. Translation-ese Recipes

| Source pattern | Rewrite options |
|-----------|----------|
| X에 대해 논의한다 | X를 논의한다 / X를 이야기한다 |
| X를 통해 Y한다 | X로 Y한다 / X해서 Y한다 / X함으로써 Y한다 |
| X에 있어서 | X에서 / X를 볼 때 / X에서는 |
| X라는 점에서 | X해서 / X라는 이유로 / X이기 때문에 |
| X와 관련하여 | X에서 / X에는 / X를 두고 |
| X에 기반하여 / X을 바탕으로 | X로 / X를 근거로 / X를 보고 |
| 경쟁력을 가지고 있다 | 경쟁력이 있다 / 경쟁력이 강하다 |
| 판단되어진다 | 판단된다 / 판단한다 |
| AI에 의해 생성된 | AI가 만든 |
| 높일 수 있다 | 높인다 (사실 서술일 때) / 높일 여지가 있다 (가능성일 때) |
| X을 위해 Y한다 | X하려고 Y한다 / X하도록 Y한다 |
| 합의가 이루어졌다 | 합의했다 / 합의에 이르렀다 |
| 기술 발전 속도 가속화 | 기술의 발전 속도가 빨라진다 |
| 그리고 (문두) | (삭제) / "-고" 연결어미로 압축 |

### B. English Citation and Terminology Prescriptions

- **Parenthetical glosses**: for a general readership, gloss the English once on first occurrence and use Korean alone thereafter. For a specialist readership, keep the gloss but do not repeat it every time.
- **Frequent English-word substitutions**:
  - pipeline → 파이프라인 (유지 OK) / 흐름 / 공정
  - framework → 체계 / 틀 / 구조
  - leverage → 활용하다 / 기대다 / 끌어올리다
  - seamless → 매끄러운 / 끊김 없는
  - robust → 튼튼한 / 견고한
  - scalable → 확장성 있는
  - insight → 통찰 / 눈 / 시사점
  - impact → 영향 / 파장
  - holistic → 전체적 / 총체적
- **English quotations**: keep the original when its nuance is the point, with a Korean rendering alongside. Otherwise unpack it into Korean and footnote only the source.

### C. Structural Recipes

- **Mechanical parallelism "첫째/둘째/셋째"**:
  - If the enumeration is essential → vary the wording: "우선 / 이어서 / 마지막으로" and the like.
  - If the enumeration is decorative → dissolve it into prose: "A다. B도 마찬가지다. 여기에 C가 더해진다."
- **Bullets → prose, worked example**:
  - Source:
    ```
    - 속도가 빠르다
    - 비용이 저렴하다
    - 확장성이 높다
    ```
  - Rewrite: "속도는 빠르고 비용도 낮다. 무엇보다 확장 여지가 크다."
- **Strip headings**: in essays and columns, drop H2-and-below headings entirely and carry the structure through paragraph flow.
- **Break the topic-sentence formula**: not every paragraph should open with a summary sentence — start some with a scene, a figure, or a question.
- **Delete all emoji** (essay and report contexts). They may stay in product copy and social posts.

### D. Signature-Phrase Prescriptions (delete first)

| Target for deletion | Replacement |
|----------|------|
| 결론적으로 | (삭제) — the final paragraph is the conclusion already, so labeling it is unnecessary |
| 요약하면 / 정리하자면 | (삭제), or "한 줄로 말하면" |
| ~라고 할 수 있다 | ~이다 (where assertion is warranted) / ~로 보인다 (where it is an observation) |
| 매우 중요하다 | Replace with concrete grounds: "X 없이는 Y가 성립하지 않는다" |
| 시사하는 바가 크다 | (삭제), or "의미는 분명하다" |
| 주목할 만하다 | (삭제) — unnecessary when the sentence already commands attention |
| 혁신적인 / 획기적인 | Delete in most cases. If needed, make it concrete: "처음 시도한" / "이전과 다른" |
| ~의 지평을 열다 / ~시대가 도래했다 | Delete, then describe the actual change |

### E. Rhythm Prescriptions

- **Input analysis**: the detector computes mean sentence length and standard deviation.
- **When uniformity is detected**:
  - Inject 1-2 short sentences (10-15 characters) per paragraph: "맞다. 그게 핵심이다."
  - Allow one long sentence (80+ characters).
- **Vary sentence endings**: never run 4-5 consecutive sentences on the same ending. Mix "~다 / ~았다 / ~인 것 / 명사형 종결".

### F. Modifier Prescriptions

- Degree adverbs ("매우", "정말", "대단히") → delete about 90% by default. Where emphasis is genuinely needed, use a concrete figure or comparison.
- Redundant paired modifiers ("중요하고 핵심적인") → keep only one.
- The affixes "~적 / ~성 / ~화" → unpack into a concrete verb or noun.
  - "근본적 변화" → "뿌리부터 바뀐다"
  - "구조적 문제" → "구조가 문제다" / "구조 자체가 문제다"

### G. Hedging Prescriptions

- **Three-step hedge downgrade**:
  - "~할 수 있을 것으로 보인다" → "~로 보인다" → "~일 것이다" → "~이다"
- Where assertion is possible, drop two or three steps and assert. Keep a single step of hedging only where the fact really is uncertain.

### H. Connective Prescriptions

- Three or more consecutive sentence-initial connectives → delete 70%.
- "또한" → delete in most cases. Where it is truly needed, vary the wording: "여기에"·"거기에"·"더해".
- "따라서 / 그러므로" → delete where the causality is self-evident. Where needed, swap in "그래서".
- Repeated "하지만 / 그러나" → alternate them, or turn one into "그런데".

### I. Formal-Noun Prescriptions

- "것이다" endings → connect the sentence ending directly.
  - "변화가 크다는 것이다" → "변화가 크다"
- "~할 필요가 있다" → "~해야 한다" / "~할 만하다", or a concrete instruction to act.
- "~이 필요하다" → make it concrete with a subject and a verb. "혁신이 필요하다" → "이 회사가 제품을 다시 만들어야 한다" (where context allows).

### J. Decoration Prescriptions

- **Bold**: strip almost entirely from body text. Allow it only at heading level.
- **Quotation marks**: restrict to actual quotations and special usages.
- **Em dash (—)**: at most 1-2 per document. Replace the rest with commas, parentheses, or a sentence break.

### 1.X. English-to-Korean PE Integrated Checklist (15 items, new in v2.0.0)

> Integrates Toral 2019, Baker 1993, and Toury 1995 with the Korean PE guidelines (윤미선 외 2018·김혜림 2022·이상빈 2017·2018a·2018b·마승혜 2018). Each prescription is bound to a taxonomy pattern ID so the rewriter can apply the whole set in one pass. The full academic citation record ships beside this file as `scholarship.md`.

| PE# | Trigger | Fix (one line) | Taxonomy ID |
|---|---|---|---|
| PE1 | 무생물 주어 + 사역·인지 동사 | Adverbial clause "X 때문에/덕분에/로 인해 Y", or the split construction "…에 따르면 …이다" | A-15·D-5 |
| PE2 | "~에 의해" by-passive | Return to active voice, or simplify to "~에/~에게" | A-9 |
| PE3 | 이중 피동 "~되어지다·~여지다" | Simple passive "~되다·~지다·잊히다·보이다" | A-8 |
| PE4 | "그/그녀/그것/그들" 단락 ≥3회 | Drop 50%+ to 영형(생략), plus some 호칭·명사구 | A-16 |
| PE5 | 무정물·추상명사 + "-들" | Delete nearly all of them. For distributivity use "여러·다양한·갖가지·저마다·각자" | (A-17 hold — awaiting v2.1 revival, scholarship.md §4) |
| PE6 | 명사 앞 ≥3어절 관형구 | Split the sentence, or use a trailing appositive clause ("X를 만났는데, 그 X는 …") | A-18 |
| PE7 | "have/make/take/give + N" 직역 ("회의를 가지다") | Restore the verb ("회의를 했다"), or use a double subject ("X는 Y가 …") | A-7 |
| PE8 | "-에서의·-에로의·-으로의·-에의" 이중 조사 (단순 ~의는 제외, C5) | Unpack into a clause or phrase ("주점 2층에서 시작한 살림") | A-19 |
| PE9 | "~다" ≥4문장 연속 | Vary with "~었다·~ㄴ다·~는다·~기 마련이다·~ㄹ 것이다·~을 수 있다" | E-2 |
| PE10 | "~고 있다" 남발 | Check whether it can be reduced to simple tense ("읽고 있다 → 읽는다") | E-2 |
| PE11 | "-tion·-ment·-ness·-ity" 한국어 명사 직역 ("the implementation of the policy") | Unpack into a verb or adjective ("정책 시행" / "정책을 시행하기") | F-4 |
| PE12 | "~로부터·~에 관하여·~을 통하여" | Replace with whatever reads naturally in context (refuse 1:1 prepositional-phrase mapping) | A-2·A-5 |
| PE13 | 영어 단순 현재·과거 단조 매핑 | Diversify Korean narrative tense and mood ("~었던·~었다가·~더라·~었으니") | E-2 |
| PE14 | 대화체 화자–청자 관계 누락 | Apply 해라/하게/하오/해요/합쇼체 consistently (genre guard: dialogue and speech only) | E-7 (estimated, C1) |
| PE15 | "Mr./Ms./Dr." 직역 ("그/그녀") | Korean address terms (선생님·박사님·과장님), or omission | A-16 |

> **Caveat guards**:
> - C3 — flag `"speculative": true` when applying the post-editese 3-axis directly (no quantitative Korean validation exists).
> - C5 — under PE8/A-19, plain "~의" is explicitly excluded from both detection and rewriting.
> - C1 — the PE14 addressee-honorific threshold stays marked "estimated" until the 김혜영 2019 PDF is obtained.
> - PE5 (A-17 hold) — retained for its academic anchor and for metric validation; taxonomy entry deferred to v2.1 pending a run on raw NMT output.

## 2. Change-Rate Monitoring

- The rewriter computes **Levenshtein distance / source length** across the before and after text and records the change rate.
- Recommended band: 5-30%.
- Above 30%: possible over-polish → review again.
- Below 5%: under-polish → recheck whether S1 patterns remain.

## 3. Substitution Hazards (Do-NOT list)

These may look like AI tells stylistically, but **changing them changes the meaning**, so preserve them:

- 전문 고유명사·제품명·모델명(GPT-4, Claude 3, Gemini 등)
- 수치·단위·날짜
- 직접 인용된 문장(큰따옴표 "" 내부)
- 법률·규정 조문 인용
- 학술 개념어가 불가피한 경우 (예: "확률적 앵무새", "창발")

## 4. Genre Tuning

| Genre | Allowed | Forbidden |
|------|------|------|
| 칼럼·에세이 | short sentences, personal voice, literary figures | emoji, heavy headings, bullet overuse |
| 리포트 | one heading level, statistics and citations | excessive emoji, hype 어휘 |
| 블로그 포스트 | friendly voice, questions | the mechanical "첫째/둘째" formula |
| 공적 연설·축사 | 격식체, 문어체 | colloquial voice, emoji, bullets |

The rewriter reads the first 100 characters of the input, infers the genre, and tunes the allowed/forbidden line against this table.

## 5. Repeat-Rewrite Policy

- First pass → if the naturalness reviewer finds residual S1/S2 patterns, trigger a second pass.
- Three passes maximum. If patterns still remain after the third, mark that span in the report as "사람이 직접 확인 요망".
