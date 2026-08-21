#!/bin/bash
# Install custom git hooks into the local repository
# This script copies pre-configured hooks from .git-hooks/ to .git/hooks/
# ensuring all developers use the same commit message validation rules.
#
# Usage:
#   ./scripts/install-githooks.sh

set -euo pipefail

# ── Locate the git repository root ──────────────────────────────────
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "Error: Not inside a git repository."
    exit 1
}

HOOKS_SRC="$GIT_ROOT/.git-hooks"
GIT_HOOKS_DIR="$GIT_ROOT/.git/hooks"

if [ ! -d "$HOOKS_SRC" ]; then
    echo "Error: Could not find .git-hooks directory."
    echo "Expected at: $HOOKS_SRC"
    exit 1
fi

# ── Install hooks ───────────────────────────────────────────────────
mkdir -p "$GIT_HOOKS_DIR"

if [ -f "$HOOKS_SRC/commit-msg" ]; then
    cp "$HOOKS_SRC/commit-msg" "$GIT_HOOKS_DIR/commit-msg"
    chmod +x "$GIT_HOOKS_DIR/commit-msg"
    echo "Successfully installed commit-msg hook"
else
    echo "Warning: commit-msg hook not found in $HOOKS_SRC"
    exit 1
fi

echo "Git hooks installation complete"
echo "  Source:  $HOOKS_SRC/commit-msg"
echo "  Target:  $GIT_HOOKS_DIR/commit-msg"
echo "Commit messages will now be validated for conventional commits format"
exit 0
