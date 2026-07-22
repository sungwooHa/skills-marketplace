#!/usr/bin/env node
// project-init deterministic scaffold generator.
//
//   node scaffold.mjs <spec.json> <targetDir> [--force]
//
// Reads a spec (see references/spec-schema.md) and stamps out a self-contained
// project scaffold: a tight always-loaded CLAUDE.md core, an advisor gate, one
// domain-named agent per spec entry, a feedback-capture file, and the frozen spec.
//
// DETERMINISTIC: no Date.now(), no Math.random(), stable ordering from the spec
// arrays. Same spec + same templates => byte-identical tree every run. The CANON
// 4-principle block and the operating-discipline block are copied BYTE-EXACT from
// core.template.md — only the placeholder tokens change.
//
// ZERO npm deps — node: builtins only.

import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const REF = resolve(HERE, '..', 'references');
const TPL = join(REF, 'agent-templates');

const ROLE_TEMPLATE = { execute: 'executor.md', review: 'reviewer.md', research: 'researcher.md' };

function die(msg, code = 1) {
  process.stderr.write(`project-init: ${msg}\n`);
  process.exit(code);
}

// Literal (non-pattern) replace-all: no $-interpretation, no regex escaping needed.
function subst(text, token, value) {
  return text.split(token).join(String(value));
}

// Filesystem-safe slug. Keeps Unicode letters/numbers (so Korean names survive),
// replaces everything else with '-', collapses/trims, lowercases ASCII.
function slugify(name) {
  return String(name)
    .normalize('NFC')
    .replace(/[^\p{L}\p{N}]+/gu, '-')
    .replace(/^-+|-+$/g, '')
    .toLowerCase();
}

function parseArgs(argv) {
  const rest = [];
  let force = false;
  for (const a of argv) {
    if (a === '--force') force = true;
    else rest.push(a);
  }
  if (rest.length < 2) die('usage: node scaffold.mjs <spec.json> <targetDir> [--force]', 2);
  return { specPath: rest[0], targetDir: rest[1], force };
}

function loadSpec(specPath) {
  let raw;
  try {
    raw = readFileSync(specPath, 'utf8');
  } catch {
    die(`cannot read spec: ${specPath}`);
  }
  let spec;
  try {
    spec = JSON.parse(raw);
  } catch (e) {
    die(`spec is not valid JSON: ${e.message}`);
  }
  // Defensive defaults + validation.
  if (spec.chassisVersion == null || !Number.isInteger(spec.chassisVersion))
    die('spec.chassisVersion must be an integer');
  if (typeof spec.mission !== 'string' || !spec.mission.trim())
    die('spec.mission must be a non-empty string');
  spec.responseStyle = (typeof spec.responseStyle === 'string' && spec.responseStyle.trim())
    ? spec.responseStyle : '개조식 한국어';
  spec.gates = Array.isArray(spec.gates) ? spec.gates : [];
  if (!Array.isArray(spec.agents) || spec.agents.length === 0)
    die('spec.agents must be a non-empty array');
  for (const a of spec.agents) {
    if (typeof a.name !== 'string' || !a.name.trim()) die('every agent needs a name');
    if (!ROLE_TEMPLATE[a.role]) die(`agent "${a.name}": role must be execute|review|research`);
    if (!Array.isArray(a.triggers) || a.triggers.length === 0)
      die(`agent "${a.name}": triggers must be a non-empty array`);
    if (typeof a.focus !== 'string' || !a.focus.trim()) die(`agent "${a.name}": focus must be a string`);
  }
  return spec;
}

function buildCoreMd(spec) {
  const template = readFileSync(join(REF, 'core.template.md'), 'utf8');
  const routing = spec.agents
    .map((a) => `「${a.name}」 — ${a.triggers.join(', ')}`)
    .join('\n');
  const gates = spec.gates.length
    ? spec.gates.map((g) => `  - ${g}`).join('\n')
    : '  - (없음)';
  let out = template;
  out = subst(out, '{{MISSION}}', spec.mission);
  out = subst(out, '{{RESPONSE_STYLE}}', spec.responseStyle);
  out = subst(out, '{{CHASSIS_VERSION}}', spec.chassisVersion);
  out = subst(out, '{{ROUTING_INDEX}}', routing);
  out = subst(out, '{{GATES}}', gates);
  return out;
}

function buildAgentMd(agent) {
  const tplName = ROLE_TEMPLATE[agent.role];
  const tpl = readFileSync(join(TPL, tplName), 'utf8');
  const slug = slugify(agent.name);
  let out = tpl;
  out = subst(out, '{{AGENT_SLUG}}', slug);
  out = subst(out, '{{AGENT_NAME}}', agent.name);
  out = subst(out, '{{TRIGGERS}}', agent.triggers.join(', '));
  out = subst(out, '{{FOCUS}}', agent.focus);
  return { slug, body: out };
}

function frozenSpec(spec) {
  // Deterministic key order.
  return JSON.stringify(
    {
      chassisVersion: spec.chassisVersion,
      mission: spec.mission,
      workType: spec.workType,
      responseStyle: spec.responseStyle,
      gates: spec.gates,
      agents: spec.agents.map((a) => ({
        name: a.name,
        role: a.role,
        triggers: a.triggers,
        focus: a.focus,
      })),
    },
    null,
    2,
  ) + '\n';
}

function main() {
  const { specPath, targetDir, force } = parseArgs(process.argv.slice(2));
  const spec = loadSpec(specPath);

  const claudeMdPath = join(targetDir, 'CLAUDE.md');
  if (existsSync(claudeMdPath) && !force)
    die(`refusing to overwrite existing ${claudeMdPath} (pass --force to re-sync)`);

  const agentsDir = join(targetDir, '.claude', 'agents');
  mkdirSync(agentsDir, { recursive: true });

  // 1. CLAUDE.md core.
  writeFileSync(claudeMdPath, buildCoreMd(spec));

  // 2. advisor.md — byte-exact copy.
  writeFileSync(join(agentsDir, 'advisor.md'), readFileSync(join(TPL, 'advisor.md'), 'utf8'));

  // 3. one agent per spec entry (stable order; guard slug collisions deterministically).
  const used = new Set(['advisor']);
  const written = [];
  for (const agent of spec.agents) {
    let { slug, body } = buildAgentMd(agent);
    if (used.has(slug)) {
      let n = 2;
      while (used.has(`${slug}-${n}`)) n += 1;
      slug = `${slug}-${n}`;
      body = subst(readFileSync(join(TPL, ROLE_TEMPLATE[agent.role]), 'utf8'), '{{AGENT_SLUG}}', slug);
      body = subst(body, '{{AGENT_NAME}}', agent.name);
      body = subst(body, '{{TRIGGERS}}', agent.triggers.join(', '));
      body = subst(body, '{{FOCUS}}', agent.focus);
    }
    used.add(slug);
    writeFileSync(join(agentsDir, `${slug}.md`), body);
    written.push({ name: agent.name, slug, role: agent.role });
  }

  // 4. skill-feedback.md — byte-exact copy of the seed.
  writeFileSync(
    join(targetDir, '.claude', 'skill-feedback.md'),
    readFileSync(join(REF, 'skill-feedback.seed.md'), 'utf8'),
  );

  // 5. frozen spec.
  writeFileSync(join(targetDir, '.claude', 'project-init.spec.json'), frozenSpec(spec));

  process.stdout.write(
    `project-init: scaffolded ${targetDir}\n` +
      `  CLAUDE.md\n` +
      `  .claude/agents/advisor.md\n` +
      written.map((w) => `  .claude/agents/${w.slug}.md  (${w.name}, ${w.role})\n`).join('') +
      `  .claude/skill-feedback.md\n` +
      `  .claude/project-init.spec.json\n`,
  );
}

main();
