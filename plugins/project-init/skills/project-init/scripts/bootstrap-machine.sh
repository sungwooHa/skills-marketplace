#!/usr/bin/env bash
#
# project-init machine-bootstrap — make the skill available on a fresh machine.
#
#   bash bootstrap-machine.sh
#
# Idempotent · non-destructive · lays down NO global chassis. Generated projects
# carry their own operating contract, so there is nothing global to install beyond
# the plugin itself. Re-running is a no-op / tolerated.
#
set -u

MARKET="sungwooHa/skills-marketplace"
PLUGIN="project-init@skills-marketplace"

say() { printf '%s\n' "$*"; }

if ! command -v claude >/dev/null 2>&1; then
  say "! 'claude' CLI not found on PATH. Install Claude Code first, then re-run."
  exit 1
fi

# 1. Register the marketplace (tolerate "already added").
say "→ marketplace: $MARKET"
if claude plugin marketplace add "$MARKET" 2>/dev/null; then
  say "  added."
else
  say "  already present (or add tolerated) — continuing."
fi

# 2. Install the plugin (tolerate "already installed").
say "→ plugin: $PLUGIN"
if claude plugin install "$PLUGIN" 2>/dev/null; then
  say "  installed."
else
  say "  already installed (or install tolerated) — continuing."
fi

say "done. project-init is available."
say "note: no global chassis was written — generated projects are self-contained."
