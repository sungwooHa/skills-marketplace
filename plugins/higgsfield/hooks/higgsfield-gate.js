#!/usr/bin/env node
/**
 * Higgsfield spend gate — PreToolUse(Bash) hook.
 *
 * Makes the plugin's prose gate chain binding: a paid `higgsfield` CLI call only
 * runs when higgsfield-estimate (G3) has written a valid approval token.
 *
 * Contract with Claude Code:
 *   - stdin  : PreToolUse payload JSON ({ tool_name, tool_input: { command }, cwd, ... })
 *   - exit 0 + no stdout : no decision, tool proceeds through normal permissions
 *   - exit 2 + stderr    : BLOCK the tool call, stderr is fed back to the model
 * Exit 1 (and every other code) is treated as non-blocking by Claude Code, so every
 * failure path in this file must land on exit 2.
 *
 * Fail-closed policy: any parse error, unreadable/spent/expired token, or
 * unrecognized `higgsfield` subcommand blocks. Commands that do not mention
 * `higgsfield` at all, and the explicit free/read-only allowlist, are decided
 * BEFORE any token logic runs, so an error on the token path can never block
 * free usage.
 */

'use strict';

const fs = require('fs');
const path = require('path');

const TOKEN_REL = path.join('.claude', '.higgsfield-gate-approval.json');

let raw = '';

/** exit 2 = block. Never use exit 1 — Claude Code lets that through. */
function deny(message) {
  process.stderr.write(message + '\n');
  process.exit(2);
}

/** exit 0 with no stdout = no decision, normal permission flow continues. */
function pass() {
  process.exit(0);
}

/** Crash landing: block only if the command looked Higgsfield-related at all. */
function bail(err) {
  if (/higgsfield/i.test(raw)) {
    deny(
      '[higgsfield-gate] BLOCKED — the spend gate could not evaluate this command ' +
        '(' + (err && err.message ? err.message : String(err)) + ').\n' +
        'Failing closed on a money path. Re-run the higgsfield-estimate gate (G3) and retry.'
    );
  }
  process.exit(0);
}

process.on('uncaughtException', bail);

// ---------------------------------------------------------------------------
// 1. Read + parse the payload
// ---------------------------------------------------------------------------

try {
  raw = fs.readFileSync(0, 'utf8');
} catch (e) {
  bail(e);
}

let payload;
try {
  payload = JSON.parse(raw);
} catch (e) {
  bail(new Error('unparseable hook payload'));
}

if (payload.tool_name !== 'Bash') pass();

const command = payload.tool_input && payload.tool_input.command;
if (typeof command !== 'string' || command.length === 0) {
  if (/higgsfield/i.test(raw)) bail(new Error('Bash payload had no command string'));
  pass();
}

// Fast path: nothing Higgsfield-related. Deliberately over-inclusive (a path like
// /usr/local/bin/higgsfield must still reach the classifier).
if (!/higgsfield/i.test(command)) pass();

// ---------------------------------------------------------------------------
// 2. Classify every `higgsfield` invocation in the command string
// ---------------------------------------------------------------------------

// Shell separators, command substitution and grouping all start a new segment.
const SEGMENT_SPLIT = /\|\||&&|\$\(|[;|&\n(){}`]/;

// Flags that mean "this call does not create a job", regardless of subcommand.
// `-h` is deliberately NOT here: if some subcommand ever uses -h for something
// other than help, treating it as free would be a money bypass.
const FREE_FLAGS = new Set(['--help', '--version', '--cost-only']);

// Verb paths that never bill. Matched as a prefix of the verb path.
const FREE_PREFIXES = [
  ['auth'],                      // login / logout / status / whoami
  ['account'],                   // account status
  ['cost'],
  ['upload'],                    // upload create — plain media upload, no job
  ['model'],                     // model list / get
  ['workflow'],                  // workflow list / get (catalog lookup)
  ['generate', 'cost'],          // incl. `generate cost workflow <name>`
  ['generate', 'list'],
  ['generate', 'get'],
  ['generate', 'wait'],
  ['generate', 'cancel'],
  ['generate', 'workflow', 'cost'],
  ['soul-id', 'list'],
  ['soul-id', 'get'],
  ['soul-id', 'wait'],
];

// Verb paths that bill. Matched as a prefix of the verb path.
const PAID_PREFIXES = [
  ['generate', 'create'],
  ['generate', 'workflow'],      // `generate workflow cost` already matched FREE above
  ['soul-id', 'create'],
  ['marketing-studio', 'dtc-ads', 'generate'],
  ['product-photoshoot'],
  ['marketplace-cards'],
];

// marketing-studio setup/discovery verbs that do not bill (documented as
// registration/listing, no credit cost). Anything else under marketing-studio
// is unrecognized and therefore blocked. `dtc-ads` is excluded — it is the
// billing group, so only its explicitly-listed paid form is recognized there.
const MS_FREE_LEAF = new Set(['list', 'get', 'fetch', 'create']);
const MS_BILLING_GROUPS = new Set(['dtc-ads']);

function startsWith(verbs, prefix) {
  if (verbs.length < prefix.length) return false;
  for (let i = 0; i < prefix.length; i++) {
    if (verbs[i] !== prefix[i]) return false;
  }
  return true;
}

/**
 * @returns {'free'|'paid'|'unknown'|null} null = segment is not a higgsfield call
 */
function classify(segment) {
  const tokens = segment.trim().split(/\s+/).filter(Boolean);
  const idx = tokens.findIndex((t) => t === 'higgsfield' || /(^|\/)higgsfield$/.test(t));
  if (idx === -1) return null;

  const rest = tokens.slice(idx + 1);
  if (rest.some((t) => FREE_FLAGS.has(t))) return 'free';

  // Verb path = leading non-flag tokens. Stops at the first flag so that a flag
  // VALUE (e.g. `--prompt create`) can never be read as a subcommand.
  const verbs = [];
  for (const t of rest) {
    if (t.startsWith('-')) break;
    verbs.push(t);
  }
  if (verbs.length === 0) return 'free'; // bare `higgsfield`

  // FREE is checked before PAID on purpose: the specific free path
  // `generate workflow cost` must win over the general paid `generate workflow`.
  for (const p of FREE_PREFIXES) if (startsWith(verbs, p)) return 'free';
  for (const p of PAID_PREFIXES) if (startsWith(verbs, p)) return 'paid';

  if (verbs[0] === 'marketing-studio') {
    // e.g. ['marketing-studio','products','create'] -> group 'products', leaf 'create'
    const group = verbs[1];
    const leaf = verbs[verbs.length - 1];
    if (verbs.length >= 2 && !MS_BILLING_GROUPS.has(group) && MS_FREE_LEAF.has(leaf)) return 'free';
    return 'unknown';
  }

  return 'unknown';
}

// Quoted spans are argument VALUES, never CLI structure. Blanking them first stops
// `--prompt 'run --help please'` from reading as a free `--help` call, and stops a
// `&&` inside a prompt from confusing segmentation.
const structure = command.replace(/'[^']*'|"[^"]*"/g, ' ');

const segments = structure.split(SEGMENT_SPLIT);
const paidSegments = [];
const unknownSegments = [];

for (const seg of segments) {
  const verdict = classify(seg);
  if (verdict === 'paid') paidSegments.push(seg.trim());
  else if (verdict === 'unknown') unknownSegments.push(seg.trim());
}

if (unknownSegments.length > 0) {
  deny(
    '[higgsfield-gate] BLOCKED — unrecognized `higgsfield` subcommand: `' +
      unknownSegments[0] +
      '`\nThe spend gate cannot prove this call is free, so it fails closed.\n' +
      'If it bills: run the higgsfield-estimate gate (G3) and get explicit user approval (무견적 생성 금지).\n' +
      'If it is genuinely read-only: it belongs in FREE_PREFIXES in this plugin\'s hooks/higgsfield-gate.js.'
  );
}

// FREE passthrough — decided before any token logic touches the disk.
if (paidSegments.length === 0) pass();

// ---------------------------------------------------------------------------
// 3. Paid path — require a valid approval token
// ---------------------------------------------------------------------------

const NO_TOKEN =
  '[higgsfield-gate] BLOCKED — 무견적 생성 금지 (no generation without an estimate).\n' +
  'Paid call: `' + paidSegments[0] + '`\n' +
  'Run the `higgsfield-estimate` skill (G3): present model·settings·run count·expected credits ' +
  'against the budget cap, then wait for the user to say the approval keyword (default "진행").\n' +
  'That gate writes ' + TOKEN_REL + ', which is what unblocks this command. ' +
  'Do not hand-write the token; approval must come from the user.\n' +
  '(Video work must clear the `higgsfield-conti` 콘티 gate (G1) before the estimate gate.)';

function resolveTokenPath() {
  const bases = [];
  if (process.env.CLAUDE_PROJECT_DIR) bases.push(process.env.CLAUDE_PROJECT_DIR);
  if (typeof payload.cwd === 'string' && payload.cwd) bases.push(payload.cwd);
  bases.push(process.cwd());

  const seen = new Set();
  for (const b of bases) {
    const p = path.resolve(b, TOKEN_REL);
    if (seen.has(p)) continue;
    seen.add(p);
    if (fs.existsSync(p)) return p;
  }
  return null;
}

let tokenPath;
let token;
try {
  tokenPath = resolveTokenPath();
  if (!tokenPath) deny(NO_TOKEN + '\nReason: no approval token found.');
  token = JSON.parse(fs.readFileSync(tokenPath, 'utf8'));
} catch (e) {
  deny(NO_TOKEN + '\nReason: the approval token could not be read or parsed (' + e.message + ').');
}

function fail(reason) {
  deny(NO_TOKEN + '\nReason: ' + reason);
}

const expiresAt = Date.parse(token.expires_at);
if (!Number.isFinite(expiresAt)) fail('token has no valid `expires_at`.');
if (Date.now() > expiresAt) fail('the approval expired at ' + token.expires_at + '. Re-run the estimate gate.');

const allowed = Number(token.runs_allowed);
const used = Number(token.runs_used);
if (!Number.isInteger(allowed) || allowed <= 0) fail('token has no valid `runs_allowed`.');
if (!Number.isInteger(used) || used < 0) fail('token has no valid `runs_used`.');

const requested = paidSegments.length;
if (used + requested > allowed) {
  fail(
    'the approval covers ' + allowed + ' run(s) and ' + used + ' are already used; this command needs ' +
      requested + '. The regeneration cap is reached — stop and re-estimate rather than re-running.'
  );
}

const scope = token.scope;
if (typeof scope !== 'string' || scope.trim() === '') fail('token has no `scope`.');
if (scope.trim() !== '*') {
  const needle = scope.trim().toLowerCase();
  const offender = paidSegments.find((s) => !s.toLowerCase().includes(needle));
  if (offender) {
    fail('the approval scope is `' + scope + '`, which does not match `' + offender + '`. Re-estimate for this job.');
  }
}

// Consume the run(s). A write failure must not let an unaccounted run through.
try {
  token.runs_used = used + requested;
  const tmp = tokenPath + '.tmp';
  fs.writeFileSync(tmp, JSON.stringify(token, null, 2) + '\n');
  fs.renameSync(tmp, tokenPath);
} catch (e) {
  fail('the run counter could not be updated (' + e.message + '), so the run cannot be authorized.');
}

pass();
