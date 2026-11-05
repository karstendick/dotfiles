Tend this branch's pull request and nothing else. Only I merge, approve or enable auto-merge
on a PR. Never do any of them; when the PR is ready, tell me. Each iteration:

1. **Read the PR's state first:** `gh pr view --json state,mergeStateStatus,autoMergeRequest`,
   and the review threads.
2. **Stop the loop when there's nothing left to do on the PR,** and say why:
   - **It's merged or closed:** report its final state.
   - **It's done for this round:** `mergeStateStatus` is `CLEAN` (CI green, up to date with
     `main`), every review comment is addressed and replied to on its thread, and no comment
     is held waiting for my answer. Report that the PR is ready for my review or merge. I'll
     run `/loop` again after my next review.

   Stopping means ending the loop for good: cancel the wakeup and stop any Monitor you
   started. A held comment keeps the loop running, since there's work to do once I answer.
3. **For each new unresolved review comment,** make the change it asks for, commit, and push.
   Then reply on the thread saying what changed, with the commit. If the comment is a
   question, reply with the answer. Replies post under my GitHub account, so write them as
   I would, with no mention of Claude or AI.
   - **If a comment asks for something outside the spec, or you disagree with it, hold it.**
     Reply on the thread right away so I can see it's being held, for example "Holding
     this one: it changes a decision we made earlier, so I'll follow up", then ask me in
     the session.
   - **While any comment is held, push nothing**, including the `main` update in step 5. A
     push can make the PR mergeable, and an armed auto-merge would then merge it with my
     comment unaddressed.
4. **If CI is red,** read the failing job's log (`gh run view <run-id> --log-failed`), fix the
   cause, commit and push. If the failure has nothing to do with this branch's diff, rerun
   the failed jobs once (`gh run rerun <run-id> --failed`) and say so; don't rerun the same
   failure twice.
5. **If the branch is behind main or conflicts with it** (`mergeStateStatus` is `BEHIND` or
   `DIRTY`), update the branch with main: `git fetch origin main`, then
   `git merge --no-edit origin/main` on this branch, resolving any conflicts, then push.
   `main` requires branches to be up to date before they merge. Never rebase: a rebased
   branch needs a force push, which is blocked.
   - **If auto-merge is armed** (`autoMergeRequest` isn't null) and any review thread is
     unresolved, don't update. Tell me in the session, since the update would let it merge.
6. **Otherwise, wait.** That's while CI is still running on the latest push, or while a
   comment is held for me. Do nothing else: no cleanup passes, bug hunts, refactors or
   improvements beyond what the comments and CI ask for. Say in one line what you're
   waiting on.
