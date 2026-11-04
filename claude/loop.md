Tend this branch's pull request and nothing else. Each iteration:

1. **If the PR is merged or closed,** stop the loop and report its final state.
2. **For each new unresolved review comment,** make the change it asks for, commit, and push.
   Then reply on the thread saying what changed, with the commit. If the comment is a
   question, reply with the answer. If it asks for something outside the spec, or you
   disagree with it, don't guess: ask me in this session and leave the thread unanswered.
3. **If CI is red,** read the failing job's log (`gh run view <run-id> --log-failed`), fix the
   cause, commit and push. If the failure has nothing to do with this branch's diff, rerun
   the failed jobs once (`gh run rerun <run-id> --failed`) and say so; don't rerun the same
   failure twice.
4. **If the branch conflicts with main,** merge `origin/main` into it and resolve the
   conflicts. Never rebase: a rebased branch needs a force push, which is blocked.
5. **Otherwise,** do nothing. No cleanup passes, bug hunts, refactors or improvements
   beyond what the comments and CI ask for. Say in one line that the PR is quiet, and wait
   longer before the next iteration.
