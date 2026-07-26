# UI Copy Rules — removing the AI accent from user-facing strings

Check L (redundant UX copy) and check M (terminology leakage) in detail. These rules were distilled from repeated live-product feedback: the single most recognizable AI-tell in generated UI is **text that explains what the interface already shows**.

## The principle

A screen earns clarity through layout, labels, and hierarchy — not through sentences about itself. Every explanatory string must pass one question: **does the user lose anything real if this line is deleted?** If not, delete it. Deletion is the default verdict, not the exception.

## Remove list (violations)

| Pattern | Example (violation) | Why it fails |
|---|---|---|
| Button-behavior narration | "Pressing Clock-out records the current time." | The button label already says it; the tap teaches the rest |
| Next-step preview | "You will pick the start time on the next screen." | Navigation reveals itself; previewing it doubles the reading cost |
| Self-evident operation instructions | "Tap [+ Add] below to add an employee." | The button is visible and labeled; the instruction is noise |
| Subtitle restating the title or layout | Title "Team members" + subtitle "A list of your team members" | Zero-information line consuming prime vertical space |
| Footnote-style hedging | "Note: results may vary depending on settings." | Hedge with no actionable content — classic generated-UI filler |
| Empty-state operation coaching | "No records yet. Press the button below to create one." | Empty states state the *state*; the CTA is its own instruction |

Empty-state rule: keep the status line ("No records yet"), cut the coaching line.

## Keep list (legitimate copy — never flag these)

Information the user **loses something by not reading**:

- Warnings and destructive/irreversible-action notices ("This permanently deletes 12 records")
- Money/payroll/settlement rules that change what the user is owed or billed
- Autosave / data-persistence notices
- "You won't see this again" disclosures (one-time codes, recovery keys)
- Genuine domain knowledge the UI cannot show structurally (policy, legal, safety)

When in doubt: coaching about the *interface* is removable; facts about the *consequences* are not.

## Terminology leakage (check M)

User-facing strings must never contain:

1. **Internal domain jargon** — implementation vocabulary that leaked into labels (maintain the project's forbidden-terms list in `.claude/ui-review.local.md` under `forbidden-terms:`; grow it every time a new leak is found).
2. **Debug placeholders** — bare literals like `tail`, `test`, `TODO`, lorem fragments. Always Critical.
3. **State-relative phrasing that assumes hidden context** — copy like "reverted" when the user never saw the original state.
4. **Format drift** — the same quantity rendered differently across screens (with/without thousands separators, different date formats). All money/time display goes through one shared formatter; a new screen reusing a different format is a violation.

Mechanical guard: when the project has a string-scanning convention test, route new forbidden terms there instead of duplicating the list here. This file owns the judgment rules; the project owns the term list.

## Review procedure for strings

1. Collect every user-facing string in the target file (hardcoded literals and resource references).
2. Read each aloud in context: is it interface coaching (remove list) or consequence information (keep list)?
3. Check against the forbidden-terms list and debug-placeholder patterns.
4. Emit one card per violating string, grade by table: debug leakage → Critical; jargon leakage → Critical; redundant coaching → Recommended; borderline hedging → Nit with the deletion question quoted.
