#!/usr/bin/env bash
#
# merge-renovate-prs.sh
#
# Drain the open Renovate dependency PRs on this repository: merge the ones that
# are clean, rebase the ones whose branch fell behind `main` and retry, and skip
# the ones with real conflicts. Merging advances `main`, which makes Renovate
# rebase and regenerate follow-up PRs, so the script loops until no mergeable
# Renovate PRs remain (or a safety cap is hit).
#
# Requires: gh (authenticated), jq.
#
# Usage:
#   ./merge-renovate-prs.sh [options]
#
# Options:
#   -a, --author <login>   PR author to match (default: app/renovate)
#   -m, --method <method>  Merge method: squash | merge | rebase (default: squash)
#   -r, --rounds <n>       Max drain rounds (default: 10)
#   -n, --dry-run          Show what would be merged; make no changes
#   -y, --yes              Skip the confirmation prompt
#   -h, --help             Show this help
#
set -euo pipefail

AUTHOR="app/renovate"
METHOD="squash"
MAX_ROUNDS=10
DRY_RUN=false
ASSUME_YES=false

# ---- argument parsing -------------------------------------------------------
while [ "$#" -gt 0 ]; do
  case "$1" in
    -a|--author)  AUTHOR="${2:?missing value for $1}"; shift 2 ;;
    -m|--method)  METHOD="${2:?missing value for $1}"; shift 2 ;;
    -r|--rounds)  MAX_ROUNDS="${2:?missing value for $1}"; shift 2 ;;
    -n|--dry-run) DRY_RUN=true; shift ;;
    -y|--yes)     ASSUME_YES=true; shift ;;
    -h|--help)
      sed -n '/^# merge-renovate-prs.sh/,/^#   -h, --help/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "[ERROR] unknown option: $1" >&2; exit 2 ;;
  esac
done

case "$METHOD" in
  squash|merge|rebase) ;;
  *) echo "[ERROR] --method must be squash, merge, or rebase (got: $METHOD)" >&2; exit 2 ;;
esac

# ---- prerequisites ----------------------------------------------------------
for cmd in gh jq; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "[ERROR] '$cmd' is required but not installed." >&2; exit 1; }
done

# Confirm gh is authenticated and we are inside a repo gh can resolve.
if ! gh repo view --json nameWithOwner -q .nameWithOwner >/tmp/.mrp_repo 2>/dev/null; then
  echo "[ERROR] 'gh' cannot resolve this repository. Run from inside the repo and ensure 'gh auth login' is done." >&2
  exit 1
fi
REPO="$(cat /tmp/.mrp_repo)"; rm -f /tmp/.mrp_repo

echo "Repository : $REPO"
echo "Author     : $AUTHOR"
echo "Merge via  : $METHOD"
echo "Max rounds : $MAX_ROUNDS"
$DRY_RUN && echo "Mode       : DRY RUN (no changes will be made)"
echo

# Confirmation gate (skipped for dry runs and when --yes is given).
if ! $DRY_RUN && ! $ASSUME_YES; then
  printf 'Merge all mergeable %s PRs via %s? [y/N] ' "$AUTHOR" "$METHOD"
  read -r reply
  case "$reply" in
    y|Y|yes|YES) ;;
    *) echo "Aborted."; exit 0 ;;
  esac
  echo
fi

# ---- helpers ----------------------------------------------------------------

# List open PR numbers for the target author, oldest first (stable order).
list_pr_numbers() {
  gh pr list --state open --limit 200 \
    --json number,author \
    --jq "[.[] | select(.author.login == \"$AUTHOR\") | .number] | sort | .[]"
}

# Fetch mergeability for a PR, retrying while GitHub reports UNKNOWN (it computes
# merge state asynchronously). Prints "<mergeable>\t<mergeStateStatus>".
pr_state() {
  local num="$1" tries=0 out mergeable status
  while [ "$tries" -lt 8 ]; do
    out="$(gh pr view "$num" --json mergeable,mergeStateStatus \
             --jq '"\(.mergeable)\t\(.mergeStateStatus)"' 2>/dev/null || printf 'ERROR\tERROR')"
    mergeable="${out%%$'\t'*}"
    status="${out##*$'\t'}"
    if [ "$mergeable" != "UNKNOWN" ] && [ "$status" != "UNKNOWN" ]; then
      printf '%s\t%s\n' "$mergeable" "$status"
      return 0
    fi
    tries=$((tries + 1))
    sleep 3
  done
  printf '%s\t%s\n' "$mergeable" "$status"
}

# ---- main drain loop --------------------------------------------------------
total_merged=0
total_skipped=0

round=1
while [ "$round" -le "$MAX_ROUNDS" ]; do
  mapfile -t prs < <(list_pr_numbers)
  if [ "${#prs[@]}" -eq 0 ]; then
    echo "No open PRs by $AUTHOR remain."
    break
  fi

  echo "===== Round $round/$MAX_ROUNDS: ${#prs[@]} open PR(s) by $AUTHOR ====="

  progressed=false
  for num in "${prs[@]}"; do
    title="$(gh pr view "$num" --json title --jq .title 2>/dev/null || echo '?')"
    IFS=$'\t' read -r mergeable status < <(pr_state "$num")
    printf 'PR #%s  [%s/%s]  %s\n' "$num" "$mergeable" "$status" "$title"

    if $DRY_RUN; then
      case "$status" in
        CLEAN|UNSTABLE|HAS_HOOKS) echo "   would merge (--$METHOD)" ;;
        BEHIND)                   echo "   would update branch, then merge" ;;
        DIRTY)                    echo "   would SKIP (merge conflict)" ;;
        BLOCKED)                  echo "   would SKIP (blocked: checks/review required)" ;;
        *)                        echo "   would SKIP (state: $status)" ;;
      esac
      continue
    fi

    case "$status" in
      CLEAN|UNSTABLE|HAS_HOOKS)
        # UNSTABLE = non-required checks pending/failing; still mergeable.
        if gh pr merge "$num" --"$METHOD" >/dev/null 2>&1; then
          echo "   merged."
          total_merged=$((total_merged + 1))
          progressed=true
          sleep 3
        else
          echo "   merge attempt failed; will retry next round."
        fi
        ;;
      BEHIND)
        echo "   branch behind main -> updating..."
        if gh pr update-branch "$num" >/dev/null 2>&1; then
          echo "   branch updated; will merge after recompute (next round)."
          progressed=true
          sleep 4
        else
          echo "   update failed (likely a conflict surfaced) -> SKIP."
          total_skipped=$((total_skipped + 1))
        fi
        ;;
      DIRTY)
        echo "   SKIP: merge conflict, needs manual resolution."
        total_skipped=$((total_skipped + 1))
        ;;
      BLOCKED)
        echo "   SKIP: blocked by required checks or review."
        total_skipped=$((total_skipped + 1))
        ;;
      *)
        echo "   SKIP: unhandled state '$status'."
        total_skipped=$((total_skipped + 1))
        ;;
    esac
  done

  $DRY_RUN && break

  if ! $progressed; then
    echo "No PR could be merged or advanced this round; stopping."
    break
  fi

  round=$((round + 1))
  echo
done

if [ "$round" -gt "$MAX_ROUNDS" ] && ! $DRY_RUN; then
  echo "Reached max rounds ($MAX_ROUNDS). Re-run to continue if PRs remain."
fi

echo
echo "Done. Merged: $total_merged  Skipped: $total_skipped"
if ! $DRY_RUN; then
  remaining="$(list_pr_numbers | wc -l | tr -d ' ')"
  echo "Open PRs by $AUTHOR still remaining: $remaining"
fi
