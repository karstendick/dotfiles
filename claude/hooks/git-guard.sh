#!/usr/bin/env bash
# PreToolUse hook for Bash: Claude commits and pushes feature branches on its own, so refuse
# the git operations that must never happen without me: committing or pushing on main, any
# force push, and skipping hooks. Exit 2 blocks the tool call and shows stderr to Claude.
set -euo pipefail

input=$(cat)
cwd=$(jq -r '.cwd // ""' <<<"$input")
# Drop quoted strings, so a commit message that mentions --no-verify or main can't trigger a
# block. -0 lets a quoted heredoc message span lines.
cmd=$(jq -r '.tool_input.command // ""' <<<"$input" | perl -0pe "s/'[^']*'//g; s/\"[^\"]*\"//g")

# Only commands that run git commit or git push, including `git -C <dir> …` and `git -c k=v …`.
git_op='(^|[;&|(]|\s)git(\s+-[Cc]\s+\S+)*\s+(commit|push)\b'
grep -qE "$git_op" <<<"$cmd" || exit 0

block() {
  echo "Blocked by git-guard: $1" >&2
  exit 2
}

grep -qE '(^|\s)--no-verify\b' <<<"$cmd" && block "--no-verify skips the pre-commit hook. Fix what the hook reports instead."
grep -qE 'git(\s+-[Cc]\s+\S+)*\s+commit\b[^;&|]*\s-[a-zA-Z]*n' <<<"$cmd" &&
  block "git commit -n skips the pre-commit hook. Fix what the hook reports instead."

if grep -qE 'git(\s+-[Cc]\s+\S+)*\s+push\b' <<<"$cmd"; then
  grep -qE '\s(--force|--force-with-lease|--force-if-includes|-[a-zA-Z]*f)\b|\s\+[^[:space:]]+' <<<"$cmd" &&
    block "force pushes are never allowed. Push a new commit instead."
  grep -qE '\spush\b[^;&|]*\s(\S+:)?(refs/heads/)?main(\s|$)' <<<"$cmd" &&
    block "pushing to main. Push the feature branch and open a PR."
fi

# The branch the command runs on: the -C directory if given, else the session's cwd.
dir=$(grep -oE 'git\s+-C\s+\S+' <<<"$cmd" | head -1 | awk '{print $3}' || true)
dir=${dir:-$cwd}
dir=${dir/#\~/$HOME}
branch=$(git -C "${dir:-.}" branch --show-current 2>/dev/null || true)
[[ $branch == main ]] && block "the checkout at ${dir:-.} is on main. Work on the ticket's feature branch in its worktree."

exit 0
