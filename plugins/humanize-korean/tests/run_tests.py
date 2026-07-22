#!/usr/bin/env python3
"""Regression harness for the humanize-korean plugin.

One command, non-zero exit on any failure:

    python3 plugins/humanize-korean/tests/run_tests.py

Covers four groups:

  A. Structure     — manifests, frontmatter, name/version coherence
  B. Wiring        — every referenced agent and reference file actually exists
  C. Path anchoring — the defect class that made agents silently skip the
                      rulebooks. These assertions LOCK IN the fixes; if someone
                      reintroduces a cwd-relative reference path or renames a
                      baseline without updating its resolver, this fails.
  D. Metrics       — metrics_v2 runs against baseline_v2 and separates an
                      AI-tell-dense Korean fixture from a human-written one.

Standard library only, to match the metric modules' own constraint.
"""

from __future__ import annotations

import importlib.util
import json
import os
import re
import subprocess
import sys
import tempfile

PLUGIN = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILLS = os.path.join(PLUGIN, "skills")
AGENTS = os.path.join(PLUGIN, "agents")
REFS = os.path.join(SKILLS, "humanize-korean", "references")
FIXTURES = os.path.join(PLUGIN, "tests", "fixtures")

VERSION = "2.0.0"

SHIPPED_SKILLS = ["humanize-korean", "humanize", "humanize-redo"]
SHIPPED_AGENTS = [
    "humanize-monolith",
    "ai-tell-detector",
    "korean-style-rewriter",
    "content-fidelity-auditor",
    "naturalness-reviewer",
    "korean-ai-tell-taxonomist",
]
# Build-time scaffolding and out-of-scope agents. These must never reappear.
DROPPED_AGENTS = [
    "humanize-web-architect",
    "korean-translation-scholar",
    "taxonomy-gap-analyzer",
    "translationese-research-distiller",
    "post-editese-metric-engineer",
    "quick-rules-integrator",
]
SHIPPED_REFS = [
    "ai-tell-taxonomy.md",
    "quick-rules.md",
    "rewriting-playbook.md",
    "scholarship.md",
    "metrics.py",
    "metrics_v2.py",
    "baseline.json",
    "baseline_v2.json",
]

PASS = 0
FAIL = 0
FAILURES: list[str] = []


def check(label: str, condition: bool, detail: str = "") -> bool:
    global PASS, FAIL
    if condition:
        PASS += 1
        print(f"  ok   {label}")
    else:
        FAIL += 1
        FAILURES.append(f"{label}{(' — ' + detail) if detail else ''}")
        print(f"  FAIL {label}" + (f"  ({detail})" if detail else ""))
    return bool(condition)


def head(title: str) -> None:
    print(f"\n=== {title} ===")


def read(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def frontmatter(path: str) -> dict[str, str] | None:
    """Minimal YAML frontmatter parser — top-level `key: value` pairs only."""
    text = read(path)
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---", 3)
    if end == -1:
        return None
    out: dict[str, str] = {}
    for line in text[4:end].split("\n"):
        if not line.strip() or line.startswith((" ", "\t", "#")):
            continue
        if ":" not in line:
            continue
        k, v = line.split(":", 1)
        out[k.strip()] = v.strip().strip('"').strip("'")
    return out


def all_shipped_files() -> list[str]:
    out = []
    for root, dirs, files in os.walk(PLUGIN):
        dirs[:] = [d for d in dirs if d not in {"__pycache__", ".git"}]
        for fn in files:
            if fn.endswith((".pyc",)):
                continue
            out.append(os.path.join(root, fn))
    return out


# ---------------------------------------------------------------------------
# A. Structure
# ---------------------------------------------------------------------------
head("A. Structure — manifest, frontmatter, version coherence")

manifest_path = os.path.join(PLUGIN, ".claude-plugin", "plugin.json")
check("plugin.json exists", os.path.isfile(manifest_path))

manifest = {}
try:
    manifest = json.loads(read(manifest_path))
    check("plugin.json is valid JSON", True)
except Exception as e:  # noqa: BLE001
    check("plugin.json is valid JSON", False, str(e))

for key in ("name", "version", "description", "author", "license"):
    check(f"plugin.json has '{key}'", key in manifest)

check("plugin.json name == humanize-korean", manifest.get("name") == "humanize-korean")
check(
    f"plugin.json version == {VERSION}",
    manifest.get("version") == VERSION,
    f"got {manifest.get('version')!r}",
)

for name in SHIPPED_SKILLS:
    p = os.path.join(SKILLS, name, "SKILL.md")
    if not check(f"skill '{name}' SKILL.md exists", os.path.isfile(p)):
        continue
    fm = frontmatter(p)
    if not check(f"skill '{name}' has parseable frontmatter", fm is not None):
        continue
    assert fm is not None
    check(f"skill '{name}' frontmatter name matches directory", fm.get("name") == name,
          f"got {fm.get('name')!r}")
    check(f"skill '{name}' declares version {VERSION}", fm.get("version") == VERSION,
          f"got {fm.get('version')!r}")
    check(f"skill '{name}' has a description", bool(fm.get("description")))

# The Korean trigger phrases are the skill's activation surface. Translating
# them away would silently break every user-facing invocation path.
hk_fm = frontmatter(os.path.join(SKILLS, "humanize-korean", "SKILL.md")) or {}
hk_desc = hk_fm.get("description", "")
for trigger in ["AI 티 없애줘", "번역투 제거", "휴머나이저", "2차 윤문"]:
    check(f"Korean trigger preserved: {trigger!r}", trigger in hk_desc)

for name in SHIPPED_AGENTS:
    p = os.path.join(AGENTS, f"{name}.md")
    if not check(f"agent '{name}' exists", os.path.isfile(p)):
        continue
    fm = frontmatter(p)
    if not check(f"agent '{name}' has parseable frontmatter", fm is not None):
        continue
    assert fm is not None
    check(f"agent '{name}' frontmatter name matches filename", fm.get("name") == name,
          f"got {fm.get('name')!r}")
    check(f"agent '{name}' is model: opus", fm.get("model") == "opus",
          f"got {fm.get('model')!r}")

present_agents = sorted(
    f[:-3] for f in os.listdir(AGENTS) if f.endswith(".md")
) if os.path.isdir(AGENTS) else []
check("exactly 6 agents ship", len(present_agents) == 6, f"got {len(present_agents)}")
for name in DROPPED_AGENTS:
    check(f"dropped agent absent: {name}", name not in present_agents)

for ref in SHIPPED_REFS:
    check(f"reference ships: {ref}", os.path.isfile(os.path.join(REFS, ref)))

check(
    "web-service-spec.md was dropped",
    not os.path.exists(os.path.join(REFS, "web-service-spec.md")),
)
check("NOTICE exists", os.path.isfile(os.path.join(PLUGIN, "NOTICE")))
check(
    "NOTICE credits the upstream origin",
    "epoko77-ai/im-not-ai" in read(os.path.join(PLUGIN, "NOTICE")),
)
check("README exists", os.path.isfile(os.path.join(PLUGIN, "README.md")))

# ---------------------------------------------------------------------------
# B. Wiring — nothing points at a file that does not exist
# ---------------------------------------------------------------------------
head("B. Wiring — every reference resolves")

skill_text = read(os.path.join(SKILLS, "humanize-korean", "SKILL.md"))

for name in SHIPPED_AGENTS:
    check(f"SKILL.md names shipped agent '{name}'", f"`{name}`" in skill_text)

for name in DROPPED_AGENTS:
    check(f"SKILL.md does not name dropped agent '{name}'", name not in skill_text)

linked = set(re.findall(r"references/([A-Za-z0-9_.-]+)", skill_text))
for ref in sorted(linked):
    check(f"SKILL.md link resolves: references/{ref}",
          os.path.isfile(os.path.join(REFS, ref)))

agent_blob = "\n".join(read(os.path.join(AGENTS, f"{n}.md")) for n in SHIPPED_AGENTS)
for name in DROPPED_AGENTS:
    check(f"no agent references dropped '{name}'", name not in agent_blob)

# Reference files must not point at siblings that were retired. The v1.2/v1.3
# discovery scaffolding (candidate pool, sample collection, promotion checklist,
# voice-profile schema) was removed in v1.5 but the taxonomy kept citing it.
RETIRED_SIBLINGS = [
    "pattern-candidates.md",
    "sample-collection.md",
    "promotion-checklist.md",
    "author-context-schema.md",
    "web-service-spec.md",
]
ref_blob = "\n".join(
    read(os.path.join(REFS, r)) for r in SHIPPED_REFS if r.endswith(".md")
)
for name in RETIRED_SIBLINGS:
    check(f"no reference cites retired file '{name}'", name not in ref_blob)

# The taxonomy is the SSOT. A drop in pattern count is the exact regression that
# the 2026-07 English conversion introduced and nobody noticed.
taxonomy = read(os.path.join(REFS, "ai-tell-taxonomy.md"))
pattern_ids = re.findall(r"^### ([A-J]-\d+)\.", taxonomy, re.M)
check("taxonomy carries 71 pattern entries", len(pattern_ids) == 71,
      f"got {len(pattern_ids)}")
check("taxonomy pattern IDs are unique", len(pattern_ids) == len(set(pattern_ids)),
      str([p for p in pattern_ids if pattern_ids.count(p) > 1]))
for cat, hi in [("A", 19), ("B", 4), ("C", 12), ("D", 7), ("E", 7),
                ("F", 5), ("G", 3), ("H", 4), ("I", 6), ("J", 4)]:
    got = sorted(int(p.split("-")[1]) for p in pattern_ids if p.startswith(f"{cat}-"))
    check(f"category {cat} is complete 1..{hi}", got == list(range(1, hi + 1)),
          f"got {got}")

# ---------------------------------------------------------------------------
# C. Path anchoring — the defect class this harness exists to prevent
# ---------------------------------------------------------------------------
head("C. Path anchoring — locked-in fixes")

shipped = all_shipped_files()

# C1. Absolute developer paths must never ship.
abs_path_hits = []
for p in shipped:
    if p.endswith(("run_tests.py",)):
        continue
    try:
        if "/Users/" in read(p):
            abs_path_hits.append(os.path.relpath(p, PLUGIN))
    except (UnicodeDecodeError, IsADirectoryError):
        pass
check("no /Users/ absolute paths in shipped files", not abs_path_hits,
      ", ".join(abs_path_hits))

# C2. The stale env token must be gone everywhere.
skill_token_hits = [
    os.path.relpath(p, PLUGIN)
    for p in shipped
    if not p.endswith("run_tests.py") and "CLAUDE_SKILL_DIR" in read(p)
]
check("no ${CLAUDE_SKILL_DIR} token remains", not skill_token_hits,
      ", ".join(skill_token_hits))

# C3. THE BUG. An agent's cwd is the user's project, not the skill directory,
# so an instruction to read `references/foo.md` resolves to <user-cwd>/references
# and fails — silently, leaving the agent to work without its rulebook.
bare_ref_re = re.compile(r"(?<![/`])`references/[A-Za-z0-9_.…-]+`")
for name in SHIPPED_AGENTS:
    offenders = []
    for lineno, line in enumerate(
        read(os.path.join(AGENTS, f"{name}.md")).split("\n"), 1
    ):
        if not bare_ref_re.search(line):
            continue
        # A line that *prohibits* the bad form necessarily quotes it. Allow that.
        if re.search(r"\bNever\b|\bbare relative\b|\bdo not\b", line, re.I):
            continue
        offenders.append(f"L{lineno}")
    check(f"agent '{name}' has no bare relative reference read", not offenders,
          ", ".join(offenders))

# C4. Agents that consume a rulebook must document the resolution ladder.
RULEBOOK_CONSUMERS = [
    "humanize-monolith",
    "ai-tell-detector",
    "korean-style-rewriter",
    "naturalness-reviewer",
    "korean-ai-tell-taxonomist",
]
for name in RULEBOOK_CONSUMERS:
    text = read(os.path.join(AGENTS, f"{name}.md"))
    check(f"agent '{name}' documents CLAUDE_PLUGIN_ROOT fallback",
          "CLAUDE_PLUGIN_ROOT" in text)
    check(f"agent '{name}' documents a Glob last-resort fallback", "Glob(" in text)

check("SKILL.md documents the reference-resolution ladder",
      "CLAUDE_PLUGIN_ROOT" in skill_text and "Glob(" in skill_text)
check("SKILL.md warns against bare relative reference paths",
      "bare relative path" in skill_text)

# C5. metrics_v2 must import from an unrelated cwd. Before the fix this raised
# ModuleNotFoundError: the sibling-import walked three levels up and re-appended
# ".claude/skills/humanize-korean/references", yielding ".claude/.claude/...".
metrics_v2 = None
with tempfile.TemporaryDirectory() as td:
    cwd = os.getcwd()
    try:
        os.chdir(td)
        spec = importlib.util.spec_from_file_location(
            "hk_metrics_v2", os.path.join(REFS, "metrics_v2.py")
        )
        assert spec and spec.loader
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        metrics_v2 = mod
        check("metrics_v2 imports from an unrelated working directory", True)
    except Exception as e:  # noqa: BLE001
        check("metrics_v2 imports from an unrelated working directory", False, repr(e))
    finally:
        os.chdir(cwd)

if metrics_v2 is not None:
    check(f"metrics_v2.VERSION == {VERSION}",
          metrics_v2.VERSION == f"v{VERSION}", f"got {metrics_v2.VERSION!r}")
    # C6. The resolver must name a file that is actually here. It previously
    # pointed at "baseline_v2_diff.json", which never shipped — so the baseline
    # loaded as {} and every z-score came back None. A silent no-op that read
    # as a pass.
    bpath = metrics_v2._default_baseline_v2_path()
    check("default baseline_v2 path resolves to a real file", os.path.isfile(bpath),
          bpath)
    check("default baseline_v2 path is anchored beside metrics_v2.py",
          os.path.dirname(os.path.abspath(bpath)) == os.path.abspath(REFS))

# ---------------------------------------------------------------------------
# D. Metrics regression
# ---------------------------------------------------------------------------
head("D. Metrics — baseline wiring and behavioural separation")

for base in ("baseline.json", "baseline_v2.json"):
    try:
        data = json.loads(read(os.path.join(REFS, base)))
        check(f"{base} is valid JSON", True)
        check(f"{base} has a 'genres' map", isinstance(data.get("genres"), dict))
    except Exception as e:  # noqa: BLE001
        check(f"{base} is valid JSON", False, str(e))

if metrics_v2 is not None:
    ai_text = read(os.path.join(FIXTURES, "ai_dense.txt"))
    human_text = read(os.path.join(FIXTURES, "human_clean.txt"))

    ai = metrics_v2.compute_all_v2(ai_text, genre="essay")
    human = metrics_v2.compute_all_v2(human_text, genre="essay")

    check("compute_all_v2 returns v2_metrics", isinstance(ai.get("v2_metrics"), dict))
    check("compute_all_v2 returns a risk_band", "risk_band" in ai)
    check("v1 payload is preserved (superset contract)", "z_scores" in ai)

    # The regression that mattered: every v2 metric must actually score against
    # the baseline. All-None was the pre-fix state.
    z = ai.get("v2_z_scores", {})
    scored = [k for k, v in z.items() if v is not None]
    check("all 14 v2 metrics score against baseline_v2",
          len(z) == 14 and len(scored) == 14,
          f"{len(scored)}/{len(z)} scored")

    # Code and baseline must not drift apart.
    b2 = json.loads(read(os.path.join(REFS, "baseline_v2.json")))
    essay_cells = set(b2["genres"]["essay"].keys())
    metric_keys = set(ai["v2_metrics"].keys())
    check("every v2 metric has a baseline_v2 essay cell",
          metric_keys <= essay_cells, str(sorted(metric_keys - essay_cells)))
    check("every baseline_v2 essay cell backs a real metric",
          essay_cells <= metric_keys, str(sorted(essay_cells - metric_keys)))

    # Honesty check: uncalibrated cells must surface, not hide.
    check("placeholder baseline cells are reported as warnings",
          len(ai.get("v2_baseline_warnings", [])) == 14,
          f"got {len(ai.get('v2_baseline_warnings', []))}")

    # Behavioural separation. If these invert, a detector change has regressed.
    am, hm = ai["v2_metrics"], human["v2_metrics"]
    check("AI fixture shows more ~에 의해 passives than human fixture",
          am["by_passive_count"] > hm["by_passive_count"],
          f"{am['by_passive_count']} vs {hm['by_passive_count']}")
    check("AI fixture shows more double passives (되어진다 류)",
          am["double_passive_count"] > hm["double_passive_count"],
          f"{am['double_passive_count']} vs {hm['double_passive_count']}")
    check("AI fixture shows higher pronoun density (그/그녀/그들 직역)",
          am["pronoun_density"] > hm["pronoun_density"],
          f"{am['pronoun_density']:.4f} vs {hm['pronoun_density']:.4f}")
    check("AI fixture shows more -들 over-use",
          am["deul_overuse_rate"] > hm["deul_overuse_rate"],
          f"{am['deul_overuse_rate']:.4f} vs {hm['deul_overuse_rate']:.4f}")
    check("AI fixture shows more have/make literal renderings",
          am["have_make_literal_count"] > hm["have_make_literal_count"],
          f"{am['have_make_literal_count']} vs {hm['have_make_literal_count']}")
    check("AI fixture shows more double-particle forms (-에서의 류)",
          am["double_particle_count"] > hm["double_particle_count"],
          f"{am['double_particle_count']} vs {hm['double_particle_count']}")
    ai_ii, hu_ii = ai["v2_interference_index"], human["v2_interference_index"]
    check("interference index exposes weighted_total + components",
          "weighted_total" in ai_ii and isinstance(ai_ii.get("components"), dict))
    check("interference index covers all 8 translationese types",
          len(ai_ii["components"]) == 9,
          f"got {len(ai_ii.get('components', {}))}")
    check("AI fixture has a higher interference index",
          ai_ii["weighted_total"] > hu_ii["weighted_total"],
          f"{ai_ii['weighted_total']:.3f} vs {hu_ii['weighted_total']:.3f}")

    # The 8 baseline callables must stay byte-identical re-exports.
    spec1 = importlib.util.spec_from_file_location(
        "hk_metrics_v1", os.path.join(REFS, "metrics.py")
    )
    assert spec1 and spec1.loader
    m1 = importlib.util.module_from_spec(spec1)
    spec1.loader.exec_module(m1)
    for fn in (
        "comma_inclusion_rate", "comma_usage_rate", "ending_comma_rate",
        "comma_segment_length", "conclusion_pivot_count", "safe_balance_count",
        "hanja_nominalizer_density", "lexical_diversity",
    ):
        check(f"baseline metric re-exported unchanged: {fn}",
              getattr(metrics_v2, fn)(ai_text) == getattr(m1, fn)(ai_text))

    # CLI contract — SKILL.md Phase 2 shells out to this exact form.
    with tempfile.TemporaryDirectory() as td:
        outp = os.path.join(td, "m.json")
        r = subprocess.run(
            [sys.executable, os.path.join(REFS, "metrics_v2.py"),
             "--input", os.path.join(FIXTURES, "ai_dense.txt"),
             "--genre", "essay", "--output", outp],
            capture_output=True, text=True, cwd=td,
        )
        check("metrics_v2.py CLI exits 0", r.returncode == 0, r.stderr[-200:])
        check("metrics_v2.py CLI writes its output JSON", os.path.isfile(outp))

# ---------------------------------------------------------------------------
head("Result")
total = PASS + FAIL
print(f"\n{PASS}/{total} assertions passed.")
if FAIL:
    print(f"\n{FAIL} FAILURE(S):")
    for f in FAILURES:
        print(f"  - {f}")
    sys.exit(1)
print("All assertions passed.")
sys.exit(0)
