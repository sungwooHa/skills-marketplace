---
name: project-init
description: Interview-driven project bootstrapper. Runs a shallow intent-first interview (≤4 questions), authors a small spec (JSON), then a deterministic generator stamps out a self-contained project scaffold — a tight always-loaded CLAUDE.md core, domain-named seed agents, and an advisor gate. Same spec = same project. Generated projects depend on NO global chassis. Triggers — "새 프로젝트 세팅", "프로젝트 초기화", "부트스트랩", "프로젝트 부트스트랩", "project-init", "이 프로젝트 초기 세팅해줘", "operating contract 만들어줘". Also — making the skill available on a fresh machine (machine-bootstrap) and regenerating only the core when canon advances (re-sync).
---

# project-init — interview-driven project bootstrapper

## Principles (why it's built this way)

- **The chassis is embedded, not referenced.** Every generated project carries its own operating
  contract inside its repo. Clone it onto a machine with no global config and it still works — zero
  dependency on any global chassis. Never point a generated file at a global path.
- **The core is tight and always-loaded — it must not grow.** The generated `CLAUDE.md` is a bounded,
  cached core (principles + operating discipline + a routing index). Big/rare detail rides native
  progressive loading (agent bodies load on spawn), NOT a new lazy-load layer bolted onto the core.
- **Spec → deterministic generator.** The interview produces a spec; a script injects the core
  byte-exact. The LLM never hand-assembles the core — same spec + same templates = byte-identical tree.
- **Minimal seed.** Ship only what a fresh project needs on day one: the four base principles, the
  operating discipline, an `advisor` gate, the interview's domain-named agents, and a feedback-capture
  file. No speculative scaffolding.
- **`model: opus` is a fixed invariant.** Execution agents are opus; a generated project cannot
  downgrade it.

## Three modes

1. **project-init** [default] — bootstrap a fresh project via interview → spec → generate.
2. **machine-bootstrap** — make this skill installable/available on a fresh machine (no project scaffold).
3. **re-sync** — regenerate ONLY the core block of an already-initialized project when the canon advances.

## Workflow: project-init

Let `SKILL_DIR` be the directory this SKILL.md sits in (`${CLAUDE_PLUGIN_ROOT}/skills/project-init`
when run as an installed plugin skill).

1. **Detect if already initialized.** If `<target>/CLAUDE.md` or `<target>/.claude/project-init.spec.json`
   already exists, do NOT re-scaffold — offer **re-sync** instead (below). Never silently overwrite.
2. **Run the interview.** Follow `references/interview.md` exactly — ≤4 intent-first questions (Q5 is
   conditional). Ask the questions in the user's language; keep it shallow ("what are you trying to do",
   not "what do you need").
3. **Author the spec.** Write a spec JSON matching `references/spec-schema.md` (validate every field and
   the key order). Agent names are PROJECT-DOMAIN Korean nouns derived from Q3 — never generic
   "executor"/"reviewer" in the output.
4. **Generate.** Run the deterministic generator:
   ```bash
   node "$SKILL_DIR/scripts/scaffold.mjs" <spec-path> <target-dir>
   ```
   Add `--force` only to intentionally overwrite an existing scaffold. It emits `CLAUDE.md`,
   `.claude/agents/advisor.md`, one `.claude/agents/<slug>.md` per spec agent, `.claude/skill-feedback.md`,
   and the frozen `.claude/project-init.spec.json`.
5. **Report.** List what was written (paths), the mission line, and the routing index. Point the user at
   `.claude/skill-feedback.md` for the day-1 enhancement loop.

## Workflow: machine-bootstrap

Make the skill available on a fresh machine. Lays down NO global chassis (projects are self-contained).

```bash
bash "$SKILL_DIR/scripts/bootstrap-machine.sh"
```

Idempotent and non-destructive: it registers the marketplace and installs the plugin, tolerating
"already present". It prints what was added vs already there.

## Workflow: re-sync

When the canon (base principles / operating discipline / core template) advances, regenerate ONLY the
core block of an existing project — without disturbing project-authored content.

1. Read the project's frozen `.claude/project-init.spec.json`.
2. Bump its `chassisVersion` to the current canon version.
3. Re-run the generator with `--force` into the SAME target, then diff `CLAUDE.md` so the user reviews the
   core delta before keeping it. Seed agents are re-stamped from templates; project-specific edits to
   agent bodies should be re-applied by the user if they diverged.

## Constraints

- **Don't restate the chassis in prose.** The core template is the single source of the operating
  contract; the skill orchestrates, it does not paraphrase the principles into the conversation.
- **Never hand-write the core.** The script injects it. If the core looks wrong, fix `core.template.md`
  and regenerate — do not edit a generated `CLAUDE.md` by hand to patch the core.
- **Seed agents get PROJECT-DOMAIN names** from the interview (e.g. "코드리뷰어", "스펙조사가"). Generic
  role words ("executor") are the template's internal role key, never the emitted agent name.
- **`model: opus` stays fixed** in every execution/agent template — a project cannot downgrade it.
- **Self-contained output.** No generated file may reference a global path. If you need machine-level
  setup, that is machine-bootstrap, kept out of the project scaffold.

## Troubleshooting

- `refusing to overwrite … CLAUDE.md (pass --force)` → the target is already initialized. Use re-sync
  (deliberate `--force`) rather than a blind re-scaffold.
- Generator emits nothing / crashes → check the spec parses as JSON and every `agents[].role` is one of
  `execute|review|research`. The generator is ESM Node with zero npm deps; any modern `node` runs it.
- Regression check: `bash tests/init-test.sh` from the skill dir must be green (FAIL=0) after ANY edit to
  `scaffold.mjs` or the templates — it also proves determinism and the scrub.
- Two runs differ → something non-deterministic leaked in (a timestamp, a map over an unordered set). The
  generator must stay pure: no `Date.now()`, no `Math.random()`, stable ordering from the spec arrays.
