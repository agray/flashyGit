#!/usr/bin/env bash
set -euo pipefail

remote="${1:-origin}"

# Current branch
branch_name="$(git rev-parse --abbrev-ref HEAD)"

# Determine remote default branch (e.g., main/master)
default_branch="$(git remote show "$remote" | sed -n '/HEAD branch/s/.*: //p')"
if [[ -z "$default_branch" ]]; then
  echo "❌ Could not determine default branch for remote '$remote'." >&2
  exit 2
fi

# Require clean working tree
if [[ -n "$(git status --porcelain)" ]]; then
  echo "❌ You have pending changes locally; commit or stash them first." >&2
  exit 1
fi

# Refresh refs
git fetch "$remote" --prune

# If on the default branch, just update it with rebase and stop (no push)
if [[ "$branch_name" == "$default_branch" ]]; then
  echo "ℹ️ On '$default_branch'. Replaying local commits on top of '$remote/$default_branch'..."
  git pull --rebase --ff-only "$remote" "$default_branch"
  echo
  echo "✅ Default branch updated. Next step (if you want to publish):"
  echo "   git push"
  exit 0
fi

# Figure out upstream (if any) before rebase
upstream_ref=""
if upstream_ref="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)"; then
  : # has upstream
else
  upstream_ref=""
fi

echo "ℹ️ Rebasing '$branch_name' onto '$remote/$default_branch'..."
git rebase "$remote/$default_branch"

echo
echo "✅ Rebase complete for '$branch_name'."
echo

# Decide what the *next* push should be, but do NOT push automatically
if [[ -z "$upstream_ref" ]]; then
  # No upstream set yet
  echo "Next step (first push for this branch):"
  echo "  git push -u $remote $branch_name"
else
  # Has upstream; determine if a force push is required
  if git merge-base --is-ancestor "$upstream_ref" HEAD; then
    # Upstream is ancestor of HEAD => fast-forward push OK
    echo "Next step:"
    echo "  git push"
  else
    # History rewritten relative to upstream (typical after rebase) => force-with-lease needed
    echo "Next step (rebase rewrote history):"
    echo "  git push --force-with-lease"
  fi
fi

echo
echo "Tips if conflicts occurred:"
echo "  # after resolving files:"
echo "  git add <files> && git rebase --continue"
echo "  # to abort:"
echo "  git rebase --abort"
