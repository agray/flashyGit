#!/usr/bin/env bash
# shrink-git-repo.sh
#
# Shrinks a Git repo on disk and reports BEFORE/AFTER deltas.
#
# Usage:
#   ./shrink-git-repo.sh                # run in current repo
#   ./shrink-git-repo.sh /path/to/repo  # run in that repo
#
# Optional env vars:
#   DEPTH=250 WINDOW=250
#   PRUNE_WHEN=now                      # or "2.weeks.ago", etc.
#   DRY_RUN=1                           # show what would run, do nothing
#   SKIP_AGGRESSIVE=1                   # don't pass --aggressive to git gc
#
set -euo pipefail

REPO_DIR="${1:-.}"
DEPTH="${DEPTH:-250}"
WINDOW="${WINDOW:-250}"
PRUNE_WHEN="${PRUNE_WHEN:-now}"
DRY_RUN="${DRY_RUN:-0}"
SKIP_AGGRESSIVE="${SKIP_AGGRESSIVE:-0}"

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "+ $*"
  else
    echo "+ $*"
    "$@"
  fi
}

die() { echo "ERROR: $*" >&2; exit 1; }

# Convert a "count-objects -vH" size string to integer bytes.
# Accepts: "0 bytes", "4.84 MiB", "123 KiB", "1.2 GiB"
to_bytes() {
  local s="${1//,/}"
  local num unit
  num="$(awk '{print $1}' <<<"$s")"
  unit="$(awk '{print $2}' <<<"$s")"
  case "$unit" in
    bytes|byte) printf "%.0f" "$num" ;;
    KiB) awk -v n="$num" 'BEGIN{printf "%.0f", n*1024}' ;;
    MiB) awk -v n="$num" 'BEGIN{printf "%.0f", n*1024*1024}' ;;
    GiB) awk -v n="$num" 'BEGIN{printf "%.0f", n*1024*1024*1024}' ;;
    *) echo "0" ;;
  esac
}

human_bytes() {
  local b="$1"
  awk -v b="$b" '
    function abs(x){return x<0?-x:x}
    BEGIN{
      sign = (b<0) ? "-" : ""
      b = abs(b)
      if (b < 1024) { printf "%s%.0f bytes", sign, b; exit }
      b = b/1024
      if (b < 1024) { printf "%s%.2f KiB", sign, b; exit }
      b = b/1024
      if (b < 1024) { printf "%s%.2f MiB", sign, b; exit }
      b = b/1024
      printf "%s%.2f GiB", sign, b
    }'
}

pct_change() {
  local before="$1" after="$2"
  if [[ "$before" -eq 0 ]]; then
    [[ "$after" -eq 0 ]] && echo "0.00%" || echo "N/A"
    return
  fi
  awk -v b="$before" -v a="$after" 'BEGIN{printf "%.2f%%", ((a-b)/b)*100}'
}

# Snapshot "git count-objects -vH" into a TSV line:
# count<TAB>size_bytes<TAB>in_pack<TAB>packs<TAB>size_pack_bytes<TAB>prune_packable<TAB>garbage<TAB>size_garbage_bytes
snapshot_tsv() {
  local out
  out="$(git count-objects -vH)"
  # print raw output for the user
  echo "$out" >&2

  local count size_raw in_pack packs size_pack_raw prune_packable garbage size_garbage_raw
  count="$(awk -F': ' '/^count:/{print $2}' <<<"$out")"
  size_raw="$(awk -F': ' '/^size:/{print $2}' <<<"$out")"
  in_pack="$(awk -F': ' '/^in-pack:/{print $2}' <<<"$out")"
  packs="$(awk -F': ' '/^packs:/{print $2}' <<<"$out")"
  size_pack_raw="$(awk -F': ' '/^size-pack:/{print $2}' <<<"$out")"
  prune_packable="$(awk -F': ' '/^prune-packable:/{print $2}' <<<"$out")"
  garbage="$(awk -F': ' '/^garbage:/{print $2}' <<<"$out")"
  size_garbage_raw="$(awk -F': ' '/^size-garbage:/{print $2}' <<<"$out")"

  local size_b size_pack_b size_garbage_b
  size_b="$(to_bytes "$size_raw")"
  size_pack_b="$(to_bytes "$size_pack_raw")"
  size_garbage_b="$(to_bytes "$size_garbage_raw")"

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$count" "$size_b" "$in_pack" "$packs" "$size_pack_b" "$prune_packable" "$garbage" "$size_garbage_b"
}

read_tsv() {
  # Reads TSV file into globals:
  # t_count t_size t_inpack t_packs t_sizepack t_prunepackable t_garbage t_sizegarbage
  local file="$1"
  IFS=$'\t' read -r t_count t_size t_inpack t_packs t_sizepack t_prunepackable t_garbage t_sizegarbage <"$file"
}

print_report() {
  local before_file="$1" after_file="$2"

  read_tsv "$before_file"
  local b_count="$t_count" b_size="$t_size" b_inpack="$t_inpack" b_packs="$t_packs" b_sizepack="$t_sizepack"
  local b_prunepackable="$t_prunepackable" b_garbage="$t_garbage" b_sizegarbage="$t_sizegarbage"
  local b_total=$(( b_size + b_sizepack + b_sizegarbage ))

  read_tsv "$after_file"
  local a_count="$t_count" a_size="$t_size" a_inpack="$t_inpack" a_packs="$t_packs" a_sizepack="$t_sizepack"
  local a_prunepackable="$t_prunepackable" a_garbage="$t_garbage" a_sizegarbage="$t_sizegarbage"
  local a_total=$(( a_size + a_sizepack + a_sizegarbage ))

  local saved=$(( b_total - a_total ))

  echo "== Improvement report (from git count-objects -vH):"
  echo
  printf "Total object storage: %s  ->  %s  (%s saved, %s)\n" \
    "$(human_bytes "$b_total")" \
    "$(human_bytes "$a_total")" \
    "$(human_bytes "$saved")" \
    "$(pct_change "$b_total" "$a_total")"
  printf "Packfiles:            %s  ->  %s\n" "$b_packs" "$a_packs"
  printf "Packed objects:       %s  ->  %s\n" "$b_inpack" "$a_inpack"
  printf "Loose objects:        %s  ->  %s\n" "$b_count" "$a_count"
  printf "Loose size:           %s  ->  %s  (%s)\n" \
    "$(human_bytes "$b_size")" \
    "$(human_bytes "$a_size")" \
    "$(pct_change "$b_size" "$a_size")"
  printf "Pack size:            %s  ->  %s  (%s)\n" \
    "$(human_bytes "$b_sizepack")" \
    "$(human_bytes "$a_sizepack")" \
    "$(pct_change "$b_sizepack" "$a_sizepack")"
  printf "Prune-packable:       %s  ->  %s\n" "$b_prunepackable" "$a_prunepackable"
  printf "Garbage objects:      %s  ->  %s\n" "$b_garbage" "$a_garbage"
  printf "Garbage size:         %s  ->  %s\n" \
    "$(human_bytes "$b_sizegarbage")" \
    "$(human_bytes "$a_sizegarbage")"
  echo
  if [[ "$saved" -lt 0 ]]; then
    echo "Note: total pack storage grew slightly. Consolidation/delta layout can do that; it's not necessarily worse."
  fi
}

# --- Preflight ---
command -v git >/dev/null 2>&1 || die "git not found in PATH."
[[ -d "$REPO_DIR" ]] || die "Repo directory does not exist: $REPO_DIR"

pushd "$REPO_DIR" >/dev/null
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { popd >/dev/null; die "Not a Git repository: $REPO_DIR"; }

git_dir="$(git rev-parse --git-dir)"
if [[ -e "$git_dir/rebase-apply" || -e "$git_dir/rebase-merge" || -e "$git_dir/MERGE_HEAD" || -e "$git_dir/CHERRY_PICK_HEAD" || -e "$git_dir/BISECT_LOG" ]]; then
  popd >/dev/null
  die "Repo has an in-progress operation (rebase/merge/cherry-pick/bisect). Finish it first."
fi

echo "== Shrinking Git repo at: $(pwd)"
echo "== Git version: $(git --version)"
echo "== Settings: DEPTH=$DEPTH WINDOW=$WINDOW PRUNE_WHEN=$PRUNE_WHEN DRY_RUN=$DRY_RUN SKIP_AGGRESSIVE=$SKIP_AGGRESSIVE"
echo

tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t shrinkgit)"
before_tsv="$tmpdir/before.tsv"
after_tsv="$tmpdir/after.tsv"
trap 'rm -rf "$tmpdir" >/dev/null 2>&1 || true' EXIT

echo "== Before:"
if [[ "$DRY_RUN" == "1" ]]; then
  echo "+ git count-objects -vH"
  printf "0\t0\t0\t0\t0\t0\t0\t0\n" >"$before_tsv"
else
  snapshot_tsv >"$before_tsv"
fi
echo

echo "== Step 1/5: Expire reflogs (all refs, including unreachable) ..."
run git reflog expire --expire="$PRUNE_WHEN" --expire-unreachable="$PRUNE_WHEN" --all
echo

echo "== Step 2/5: Prune unreachable objects ..."
run git prune --expire="$PRUNE_WHEN"
echo

echo "== Step 3/5: Repack objects (may take a while on big repos) ..."
run git repack -Ad -l --depth="$DEPTH" --window="$WINDOW"
echo

echo "== Step 4/5: Refresh MIDX + commit-graph (modern Git metadata) ..."
run git multi-pack-index expire || true
run git multi-pack-index repack || true
run git commit-graph write --reachable --changed-paths || true
echo

echo "== Step 5/5: Final garbage collection ..."
if [[ "$SKIP_AGGRESSIVE" == "1" ]]; then
  run git gc --prune="$PRUNE_WHEN"
else
  run git gc --prune="$PRUNE_WHEN" --aggressive
fi
echo

echo "== After:"
if [[ "$DRY_RUN" == "1" ]]; then
  echo "+ git count-objects -vH"
  printf "0\t0\t0\t0\t0\t0\t0\t0\n" >"$after_tsv"
else
  snapshot_tsv >"$after_tsv"
fi
echo

if [[ "$DRY_RUN" != "1" ]]; then
  print_report "$before_tsv" "$after_tsv"
fi

echo "== Done."
echo "Tip: If your repo still feels huge, it may be the working tree (bin/obj/.vs/node_modules) or .git/lfs/objects."
echo "     Biggest historical blobs:"
echo "       git verify-pack -v .git/objects/pack/*.idx | sort -k3 -n | tail -20"

popd >/dev/null
