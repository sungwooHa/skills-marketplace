---
name: strategy-report
description: Produce a Korean strategy/planning report as a self-contained print-ready A4 HTML plus a matching Word (.docx), from a single Markdown source. Use when the user wants a 전략 보고서 / 기획서 / 그라운드룰 / Word 보고서 / docx 보고서 / 개조식 보고서, or asks to turn strategy notes into a shareable report document. Triggers — "전략 보고서 만들어", "기획서 만들어", "그라운드룰 문서", "Word 보고서로", "docx로 보고서", "개조식 보고서", "strategy report", "planning doc to word". Follow-ups (섹션 추가, 톤 조정, HTML만/Word만, 표현 다듬기) belong here too.
---

# strategy-report

Turn strategy/planning content into **two paired deliverables from one Markdown source**:
a self-contained, print-ready **A4 HTML** and a matching **Word `.docx`**. The house style is
Korean **개조식** (terse bullet prose), each section opening with a one-line **declaration**,
plus reusable visual components (cycle / KPT / check / calendar / declaration boxes).

This is a **lightweight builder**, not a full multi-agent harness. The orchestrator locks the
frame, one writer produces the Markdown, two renderers emit HTML + docx, and a light verify pass
checks fit and phrasing. Deep interview and multi-agent verification are optional escalations.

## When to escalate vs. stay light

- **Stay light (default):** the user knows what the report should say and wants it produced well.
- **Escalate to interview:** the user is still discovering the message ("help me figure out what
  to say"). Run a short intent interview first, then return here.
- **Escalate verification:** high-stakes external report → add an independent alignment/AI-tell
  review pass (or hand the prose to the `humanize-korean` skill if installed).

## Workflow

### 1. LOCK THE FRAME (orchestrator, direct — keep it short)

Confirm four things. State what you can infer as a proposal; ask only what you cannot.

- **목적** — why this report exists / what decision or action it drives
- **청중** — who reads it (sets tone and how much context to spell out)
- **핵심 메시지** — the single sentence the report must land. This becomes the title-line
  **declaration**. If the user can't say it in one sentence, that's the first thing to solve.
- **구조** — the section list. Propose one from `references/report-structure.md` patterns; adjust.

Show the frame → get explicit approval → proceed. Do not write content before the frame is agreed.

### 2. WRITE THE MARKDOWN SOURCE (one writer)

Author the whole report as **one Markdown file** — the single source of truth for both outputs.
Follow `references/report-structure.md` exactly:

- Every `##` section opens with a **one-line declaration** (rendered as a highlight/declaration box),
  then 개조식 bullets that each start with a **bolded claim** followed by the supporting sentence.
- Use tables for comparisons/schedules. Mark visual components with the agreed HTML component
  (cycle, KPT, check, calendar) so the HTML renderer knows to promote them.
- **개조식 discipline:** short declarative sentences, no filler, no 번역투. Verbs end decisively
  (`…하겠다`, `…한다`), not softened (`…하고자 합니다`, `…라고 볼 수 있다`). Avoid the AI-tell
  patterns listed in `references/report-structure.md` §Writing rules.

Write the Markdown to `drafts/<name>.md` (or the project's drafts folder). Long reports: split the
writing by section across writers, then concatenate — but keep one final Markdown file.

### 3. RENDER TWO DELIVERABLES

Render both from the same Markdown so they stay consistent.

- **HTML** — wrap the content in `references/html-template.html` (the A4 print shell). Replace the
  `<h1>`/subtitle and the `<!-- BODY -->` region. Promote sections that map to a component into the
  matching block (`.cycle-row`, `.kpt-row`, `.check-row`, `.calendar`, `.declaration`) — plain
  Markdown can't express these, so hand-author them from the template's component gallery. Keep it
  **self-contained**: no external CSS/JS/fonts/images; everything inline. Verify it fits A4 print.
- **DOCX** — run the bundled script on the Markdown source:

  ```bash
  python3 "${CLAUDE_PLUGIN_ROOT}/skills/strategy-report/scripts/md_to_docx.py" "<path>/<name>.md"
  ```

  It emits `<name>.docx` beside the input (맑은 고딕, A4, styled headings/tables/lists/quotes,
  inline `**bold**`/`*italic*`). The docx carries the linear content; the HTML carries the rich
  components. If the user only wants one format, render only that one.

### 4. VERIFY (light) & DELIVER

Check, in one pass:

- **Fit** — HTML prints clean on A4 (no overflow, components don't break across pages awkwardly);
  docx opens and headings/tables render.
- **Alignment** — every section's declaration serves the §1 핵심 메시지; nothing drifts.
- **Phrasing** — no AI-tell / 번역투 (see references); 개조식 discipline held.

Copy the finalized files to `outputs/` with **clean names, no version suffix** (per project
convention if one exists). Report the two paths + a one-line summary. Keep drafts.

## Files

- `scripts/md_to_docx.py` — Markdown → styled A4 `.docx` (python-docx). Standalone, no config.
- `references/html-template.html` — self-contained A4 print HTML shell + component gallery.
- `references/report-structure.md` — section patterns, 개조식 writing rules, AI-tell avoidance list.

## Requirements

- `python3` with `python-docx` (`pip install python-docx`) for the DOCX renderer.
- The HTML deliverable needs nothing — it renders in any browser and prints to A4 as-is.
