---
name: implement
description: Implement an approved spec end to end — commit, push, open a draft PR with a description, and fix CI until every check is green — then mark the PR ready. Use when the user approves a spec and asks to implement it.
disable-model-invocation: true
---

# Implement Skill

Implement an approved spec, open its PR, and get CI green. The user reviews the finished PR
on GitHub; this skill is not done until every check passes.

1. **Check the starting point, and stop if any check fails.**
   - The spec is named in the arguments, or is the one in `docs/specs/` this session wrote.
     Being run is the user's approval of that spec; don't ask for it again.
   - The session is in a worktree of its own on a branch that isn't `main`. That's normally
     the one Claude moved into when `/spec` wrote the spec. If it's still in the primary
     checkout, move into a new worktree before editing anything. The `git-guard.sh` hook
     refuses commits on `main`; don't work around it.
   - `git status` is clean apart from the spec itself. If other uncommitted changes are there,
     ask before touching them.
   - Dependencies are installed. A fresh worktree has no `node_modules`, so run `pnpm install`
     at the worktree root before building or testing anything.
2. **Implement the spec and nothing else.** Leave deferred items and Open Questions alone.
   Fill small mechanical gaps yourself and list them in the report. If the code contradicts a
   decision in the spec, or the work needs a decision the spec doesn't make, stop and ask
   rather than choosing.
3. **Commit as the work progresses.** Make logical commits that each build, staging the paths
   you changed (`git add <paths>`, never `-A`). Commit the spec with the first commit if it
   isn't committed yet. Let the pre-commit hook run; if it fails, fix what it reports.
   Commits get squash-merged, so they exist to make review easier, not for history.
4. **Verify locally before pushing.** For code changes, run `pnpm lint:full` and the affected
   packages' tests (`pnpm --filter <pkg> test`). Doc-only changes need neither.
   **Don't run `pnpm e2e` locally.** Playwright uses fixed ports (3000 and 8080) and reuses
   any server already listening there, so in a worktree it can test another session's code,
   or the user's own `pnpm dev`, and pass. CI's `e2e` job is the check; step 6 waits for it.
5. **Open the PR as a draft.** Push with `git push -u origin HEAD`, then run `/pr-description
   --draft`. If the change can't deploy with zero downtime, the description must say so and
   give the plan, per the repo's CLAUDE.md.
6. **Get CI green.** Run `gh pr checks <number> --watch` in the background, since CI can
   outlast a foreground command's limit, and wait for it to finish. On a failure:
   - Read the failing job's log (`gh run view <run-id> --log-failed`) and fix the cause.
     Commit, push, and watch again.
   - If the failure has nothing to do with this diff, such as a known-flaky e2e test or a
     registry timeout, rerun the failed jobs once (`gh run rerun <run-id> --failed`) and record
     the flake in the report. Don't rerun the same failure twice.
   - After three fix cycles, stop and report what is still failing and what you tried. Don't
     keep guessing.
7. **Finish only when every check passes.** Mark the PR ready (`gh pr ready <number>`). If
   the scope moved during the work, re-run `/pr-description` so the description matches the
   diff. Then report:
   - the PR URL and that CI is green,
   - anything that differs from the spec, and the gaps you filled,
   - any flake you reran.
