---
name: ssot-doc-pipeline
description: Run any produced document as three layers — manuscript (the single source of truth), context file (the production spec, exactly one per document), and artifact (HTML/PDF/slides/site, derived and never edited directly) — with a fixed edit order, a session-start drift check between the layers, a freeze convention for shipped documents, and promotion to the canonical location only after verification passes. Use when a document will be rendered into another format, revised repeatedly, or produced across sessions. Triggers — "보고서 수정해줘", "PDF 다시 뽑아줘", "슬라이드 문구 바꿔줘", "원고랑 산출물이 안 맞아", "이 문서 구조 잡아줘", "regenerate the deck", "update the report", "the PDF and the doc disagree". NOT for one-off throwaway text with no rendered artifact.
---

# ssot-doc-pipeline

The most common way an agent quietly ruins a document: it opens the *artifact* — the HTML, the
slide, the generated PDF source — and edits the wording there, because that is where the problem
was visible. Ten edits later the artifact and the manuscript disagree, nobody knows which is
right, and the next regeneration silently destroys the corrections.

This skill makes that structurally impossible by separating three layers and fixing the direction
edits may travel.

## The three layers

| Layer | What it is | Rule |
|---|---|---|
| **Manuscript (SSOT)** | The content, in plain text/markdown: every fact, number, name, claim, and the order they appear in | The only place content is authored. Everything else derives from it |
| **Context file** | The production spec: audience, tone, settled terminology, forbidden expressions, visual structure, output paths, procedure | Exactly **one per document**. Rules live here, content does not |
| **Artifact** | The rendered output — HTML, PDF, slides, site | **Never edited directly.** It is a build product |

Naming is up to the consuming project; a workable default:

```
<docs-root>/<document-name>.md            # manuscript (SSOT)
<docs-root>/<document-name>.context.md    # context file (one per document)
<docs-root>/_drafts/<document-name>.html  # artifact, while in progress
<docs-root>/<document-name>.pdf           # artifact, after verification passes
```

Store the three paths in the context file itself so any session can find all layers from one.

### Why exactly one context file per document

Per-chapter or per-section context files are the beginning of the end: rules diverge chapter by
chapter, contradictions appear at the seams, and a verifier can no longer say which rule was in
force. One document, one rule set. If two chapters genuinely need different rules, they are two
documents.

## Edit order (the discipline)

Direction of travel is always **manuscript → context → artifact**, never backwards.

1. **Content change** (a fact, number, name, claim, phrasing that carries meaning) → edit the
   **manuscript** first.
2. **Rule or format change** (tone, terminology, layout, what a page may contain) → edit the
   **context file**.
3. **Re-render** the artifact from the manuscript under the current context.
4. **Regenerate** downstream outputs (PDF from HTML, images, exports) — do not hand-patch them.
5. **Re-verify** — page count, rendering, and whatever quantitative gate the medium has. See
   `produce-verify-pair` for who is allowed to make that call.
6. **Promote** to the canonical location only after verification passes. Until then the artifact
   stays in the drafts area.

Corollary: if you find yourself fixing wording inside an artifact, stop. The fix belongs upstream.
A wording problem visible only in the artifact is still a manuscript problem — unless it is a
rendering problem, in which case it is a context/template problem.

## Session-start drift check

At the start of any session that touches a document, before doing the requested work, check the
three layers against each other:

- Does the artifact contain any sentence, number or name that is not in the manuscript?
  (Present in artifact, absent from manuscript = an edit was made in the wrong layer.)
- Does the manuscript contain content the artifact never received? (A render was skipped.)
- Are there several context files where there should be one?
- Is the artifact older than the manuscript? Compare modification times.

```bash
# staleness signal — artifact older than manuscript means an un-rendered change
ls -lT <document>.md <document>.html <document>.pdf
```

Report drift before continuing. Do not fold the repair silently into the requested change — the
user needs to know which layer was authoritative and what was discarded.

## Freeze convention

Once a document has been delivered (reported, sent, presented), the manuscript, its context file,
and the shipped artifact are **frozen**: typo corrections only. Strategy, plans, and current
status move on — they get maintained in the living documents (standards, roadmaps, boards), not
by rewriting a document that was already delivered under its own date.

Reasons this matters more than it looks:

- A delivered document is a record of what was said on a date. Editing it destroys the record.
- Silently updated deliverables make two readers of the "same" file disagree.
- The urge to "just update it" is exactly how a delivered document becomes an unversioned
  living document nobody can cite.

If the content genuinely must change, produce a new dated document that supersedes the old one.

## Promotion rule

An artifact leaves the drafts area only when:

1. The manuscript and the artifact agree (no artifact-only content, no un-rendered content).
2. The context file's rules were applied — terminology, forbidden expressions, structure.
3. The medium's verification gate passed, judged by someone other than the producer.

Promotion is a copy, not a move: keeping the draft costs nothing, and it is what a later verifier
compares against.

## Absorbed convention — the open-items board

Documents produced this way usually generate decisions that are *not yet aligned*. Keep them on a
single open-items board rather than scattering them through manuscripts:

- Status vocabulary, fixed and small: `needs alignment` · `open` · `needs confirmation` ·
  `exploratory` · `in progress` · `closed`.
- **Never leave the stakeholder blank.** If the owner is unknown, write "owner undetermined" —
  the absence of an owner *is* the unaligned point, and blanking it hides the problem.
- **Do not close items unilaterally.** An item closes when the party who raised it agrees.
- Keep the board and the documents in sync in both directions: a document raising a decision
  references the item number; the item references the document.

## Relationship to other skills

- **`dual-altitude-brief`** — when a matter needs an executive page and a spec page, both are
  artifacts of this pipeline, and the item numbers live in the manuscript.
- **`produce-verify-pair`** — step 5 above. The producer runs the loop; the verdict is not the
  producer's to give.
- **`slide-craft` / `generate-presentation`** — the rendering step. Their quantitative gates are
  the "verify" in step 5 for slide-shaped artifacts.
