---
name: research
description: Fast parallel web research with cited sources. Use for market/competitor/industry research, fact-checking claims against public sources, or any "조사해줘 / 리서치 / 시장 조사 / 보강해" request that needs more than one or two searches.
---

# Research — parallel fan-out, one synthesis

Speed comes from the fan-out: independent sub-questions run as parallel `researcher` agents, then one `research-analyst` merges them. Two stages, never a single agent working through every question in sequence.

## Steps

1. **Frame.** Write down, before dispatching anything:
   - the question and who the answer is for;
   - the **claims to test**: figures or statements the user, a meeting, or an internal doc already asserted, quoted verbatim with their origin (these get a supported / contradicted / unverifiable verdict);
   - the output language (the user's language unless told otherwise) and the run folder: the project's output area if it has one (e.g. `output/research/<YYMMDD>-<slug>/`), else `./research/<YYMMDD>-<slug>/`.
   Done when all four are fixed. Ask the user only if the question itself is ambiguous; pick defaults for the rest.

2. **Split** into 3–6 sub-questions. Each is answerable on its own, overlaps no other, and names the evidence it wants (official dates, survey numbers, vendor statements, local-market data). Assign every claim to test to exactly one sub-question. Done when the sub-questions cover the whole question and every claim has an owner.

3. **Fan out.** Dispatch one `research-harness:researcher` per sub-question, **all in a single message** so they run in parallel. Each prompt carries: the sub-question, its claims to test, the context line from step 1, and its notes path `<run>/r<N>-<slug>.md`. Done when every researcher has returned its path.

4. **Synthesize.** Dispatch one `research-harness:research-analyst` with the question, the full claims-to-test list, the output language, all notes paths, and the report path `<run>/report.md`. Done when the analyst returns the report path and its summary.

5. **Report** to the user in their language: the report path, the analyst's summary bullets, the verdict on each claim to test, and any gap the researchers could not close. Present Claude-gathered web facts as research, never as the user's own sources (a project with a "raw sources only" rule keeps these out of its canonical records unless the user says otherwise).

## Sizing

- One narrow fact (a single date, a single number) needs no harness: search it inline.
- More than 6 sub-questions: split the question into two runs rather than overloading one analyst.
