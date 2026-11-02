#!/usr/bin/env bash
# Resolves the "after" and "before" Flutter refs to full commit SHAs and prints
# them as `after=<sha>` and `before=<sha>` lines.
#
# usage: tool/resolve_refs.sh <after> [before]
#
# A ref is any of:
#   192664, #192664, or a PR URL   a flutter/flutter pull request
#   owner:branch                   a branch on a fork, as shown on a PR page
#   anything else                  a SHA, branch, or tag in flutter/flutter
#
# A merged PR resolves to its merge commit and an open one to its head commit.
# With no <before>, the baseline is the commit <after> forked from master, or
# its parent if <after> is itself on master.
set -euo pipefail

resolve() {
  local ref=${1#\#}
  if [[ $ref =~ ^([0-9]{1,6})$ || $ref =~ pull/([0-9]+) ]]; then
    gh api "repos/flutter/flutter/pulls/${BASH_REMATCH[1]}" \
      --jq 'if .merged then .merge_commit_sha else .head.sha end'
  elif [[ $ref =~ ^([^/:]+):(.+)$ ]]; then
    gh api "repos/${BASH_REMATCH[1]}/flutter/commits/${BASH_REMATCH[2]}" --jq .sha
  else
    gh api "repos/flutter/flutter/commits/$ref" --jq .sha
  fi
}

die() {
  echo "error: $*" >&2
  exit 1
}

[[ $# -ge 1 && -n $1 ]] || die "usage: $0 <after> [before]"

after=$(resolve "$1") || die "cannot resolve Flutter ref '$1'"
if [[ -n ${2:-} ]]; then
  before=$(resolve "$2") || die "cannot resolve Flutter ref '$2'"
else
  before=$(gh api "repos/flutter/flutter/compare/master...$after" --jq .merge_base_commit.sha)
  if [[ $before == "$after" ]]; then
    before=$(gh api "repos/flutter/flutter/commits/$after" --jq '.parents[0].sha')
  fi
fi

echo "after=$after"
echo "before=$before"
