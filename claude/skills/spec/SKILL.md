---
name: spec
description: Write an implementation spec for a feature or fix — from a confirmed /grill-me summary, a ticket, or a discussion — and wait for approval before implementing. Pass --handoff for a self-contained spec that a fresh session will implement. Use when asked to spec something out, write a spec, or turn an idea or ticket into a plan.
---

# Spec Writing Skill

1. **Start from what's already decided.** If the conversation holds a confirmed `/grill-me`
   summary, build the spec from it: read code only to fill in `path:line` references and the
   verification commands, and don't reopen settled decisions. Otherwise, if the work has a
   ticket (Linear or otherwise), read it fully — including images, attachments, and the
   actual project field rather than inferring from the title. If there is neither, write the
   spec from the conversation and note at the top of the file that it came from a discussion.
2. Use this structure: Context → Requirements → Design Decisions → Implementation Plan → Test Plan → Open Questions
3. **Choose the depth from the arguments.**
   - **Default — a decision record.** The session that wrote the spec implements it, so it
     already holds the research. Record each decision with its reason, what's in and out of
     scope, the files to change as `path:line`, and the exact commands that verify the
     result. Don't restate the investigation or explain code the conversation already
     covered.
   - **`--handoff` — self-contained.** A fresh session, often a cheaper model in a
     background session, implements it from the file alone. Name the files to change and
     the existing code they touch as `path:line`, state the conclusions the investigation
     reached rather than pointing back at the research, and give the exact commands that
     verify the result. Do not rely on anything that only exists in the conversation that
     produced the spec.
4. Never add content the user hasn't discussed. Anything that isn't in the confirmed summary
   or the conversation goes under Open Questions, not into the spec.
5. Mark deferred items clearly and do not implement them
6. When an Open Question gets answered, append the answer to the question (e.g. `_Resolved: ..._`).
   Never delete the question — the spec is a record of what was considered, not just what was decided.
7. Write the spec to `docs/specs/`, named:
   - If that directory already has specs, follow their existing naming and format — that convention
     wins over the rules below.
   - With a ticket: `<ticket-id>-<short-slug>.md`, lowercased (e.g. `agi-123-retry-backoff.md`).
   - Without a ticket: `<short-slug>.md` (e.g. `solve-replay-animation.md`). Do not invent a ticket
     ID or a placeholder number.
8. **Publish the spec for review on GitHub.** The user reviews it there, as they review code,
   not in an editor.
   - The session must be in a worktree of its own on a branch that isn't `main`. Writing the
     spec is normally the first edit, which moves the session into one. If it's still in the
     primary checkout, move into a new worktree and write the spec there.
   - Commit only the spec (`git add <spec path>`, never `-A`) and push with
     `git push -u origin HEAD`.
   - Open a draft PR with `gh pr create --draft`. Title it the way the repo titles its PRs
     (check `gh pr list --state merged --limit 5`), e.g. `[AGI-123] <ticket title>`. In the
     body, say that the PR holds only the spec for now and that the implementation follows
     once the spec is approved, then link the spec.
   - Give the user two links: the spec in the PR's **Files changed** tab
     (`<PR URL>/files`), where they leave inline comments, and the rendered file
     (`<repo URL>/blob/<branch>/<spec path>`).
9. Then stop and wait. If the user leaves review comments on the spec, update it, commit,
   push to the same branch, and reply on each thread. Never resolve a thread; the reviewer
   does that. The user approves the spec by running `/implement`, which builds the
   implementation on this branch and PR and gets CI green. Don't start implementing before then.
