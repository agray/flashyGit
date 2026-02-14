#!/usr/bin/env bash
# shrink-repos.sh
#
# Runs shrink-repo.sh against every immediate subdirectory of the current
# directory that appears to be a Git repository.
#
# Intended usage (Git Bash on Windows):
#   cd /c/gitrepos
#   ./shrink-repos.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SHRINK_ONE="$SCRIPT_DIR/shrink-repo.sh"

if [[ ! -x "$SHRINK_ONE" ]]; then
  if [[ -f "$SHRINK_ONE" ]]; then
    echo "ERROR: $SHRINK_ONE exists but is not executable."
    echo "Fix: chmod +x \"$SHRINK_ONE\""
  else
    echo "ERROR: shrink-repo.sh not found next to this script."
    echo "Expected: $SHRINK_ONE"
  fi
  exit 1
fi

ROOT="$(pwd)"
echo "== Root: $ROOT"
echo "== Using: $SHRINK_ONE"
echo

is_git_repo_dir() {
  local dir="$1"
  # Covers normal repos (.git dir) and linked worktrees/submodules (.git file)
  [[ -d "$dir/.git" || -f "$dir/.git" ]] || return 1
  git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

found_any=0
failed_any=0

shopt -s nullglob
for d in "$ROOT"/*/; do
  # strip trailing slash
  d="${d%/}"

  if is_git_repo_dir "$d"; then
    found_any=1
    echo "================================================================================"
    echo "== Shrinking: $d"
    echo "================================================================================"
    # Run shrink-repo.sh with repo path argument
    if ! "$SHRINK_ONE" "$d"; then
      failed_any=1
      echo "!! FAILED: $d" >&2
    fi
    echo
  fi
done
shopt -u nullglob

if [[ "$found_any" -eq 0 ]]; then
  echo "No Git repositories found as immediate subdirectories of:"
  echo "  $ROOT"
  exit 0
fi

if [[ "$failed_any" -eq 1 ]]; then
  echo "Done, but one or more repositories failed. See logs above." >&2
  exit 2
fi

echo "All repositories processed successfully."
