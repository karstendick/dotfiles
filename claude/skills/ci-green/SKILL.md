---
name: ci-green
description: Get an open draft PR mergeable — watch CI and fix failures, bring the branch up to date with main, mark it ready, and finish only when GitHub reports it CLEAN. Runs as a Sonnet subagent. Invoked by /implement with the PR number and the spec's path.
context: fork
agent: general-purpose
model: sonnet
background: false
---

# CI Green Skill

Arguments: `$ARGUMENTS`, the PR number and then the absolute path of the spec the PR
implements. You're a subagent and can't see the conversation that produced the PR. Read the
spec for intent, work in the current directory (the PR's worktree, on its branch), and
report back when you finish or stop.

**Only the user merges, approves or enables auto-merge on a PR. Never do any of them.**
`git-guard.sh` blocks all three, and force pushes. Updating the branch with `main` (step 2)
merges `main` into this branch and leaves the PR open.

1. **Get CI green.** Watch the checks in chunks, since a single command times out after 10
   minutes and CI can take longer: run `timeout 540 gh pr checks <number> --watch
   --interval 30` and repeat it until the checks finish. On a failure:
   - Read the failing job's log (`gh run view <run-id> --log-failed`) and fix the cause.
     Commit (stage the paths you changed, never `git add -A`), push, and watch again.
   - If the failure has nothing to do with this diff, such as a known-flaky e2e test or a
     registry timeout, rerun the failed jobs once (`gh run rerun <run-id> --failed`) and
     record the flake for the report. Don't rerun the same failure twice.
   - If a fix would change a decision in the spec, or needs one the spec doesn't make, stop
     and report it instead of choosing.
   - After three fix cycles, stop and report what is still failing and what you tried.
2. **Bring the branch up to date with `main`.** `main` requires branches to be up to date
   before they merge, and `ci-gate` has to pass on the updated head. Once CI is green,
   `git fetch origin main`. If `git merge-base --is-ancestor origin/main HEAD` fails, run
   `git merge --no-edit origin/main`, resolve any conflicts, push, and go back to step 1.
   Never rebase. If `main` moves again during three update rounds in a row, stop and report
   it rather than chasing it.
   - Before pushing, check `gh pr view <number> --json autoMergeRequest,reviews` and the
     review threads. If auto-merge is armed or anyone has left a review comment, don't
     push; report it, since a push could let the PR merge past that review.
3. **Finish only when the PR is mergeable.** Mark it ready (`gh pr ready <number>`), then
   check `gh pr view <number> --json mergeStateStatus`. `CLEAN` means up to date with every
   required check passing, and only then are you done. `BEHIND` means `main` moved again: go
   back to step 2. For anything else (`BLOCKED`, `DIRTY`, `UNSTABLE`), work out why and fix
   it, or report it.
4. **Report** in a few lines: the PR URL and its final `mergeStateStatus`, each CI fix you
   made, any flake you reran, and anything you stopped on and why.
