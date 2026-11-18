---
description: "Write and upload a PR description for the current branch or a given PR number/URL"
---

# PR Description

Write a pull request description and upload it to GitHub.

## Input

The user may provide:
- A PR number (e.g., `148`)
- A PR URL (e.g., `https://github.com/org/repo/pull/148`)
- Nothing — in which case, infer the PR from the current branch using `gh pr view --json number`
- `--draft`, alongside any of the above: create a new PR as a draft

Use the argument as `$ARGUMENTS` if provided.

## Steps

1. **Identify the PR** — resolve the PR number from the argument or current branch.

   If `gh pr view` reports no PR for the branch, the PR does not exist yet: **create it** in step 6
   rather than stopping. A branch whose work is already committed but unopened is a normal path for
   this command, not an error, so don't ask for confirmation first.

2. **Gather context** — run these in parallel:
   - `gh pr view <num> --json title,body` to see the current title/body — skip this one when no PR
     exists yet
   - `git log main..HEAD --oneline` to list all commits on the branch
   - `git diff main..HEAD --stat` to get a summary of changed files and line counts

   If the diff is too large for GitHub's API, use local git commands instead.

   From the stat, note whether the branch changes a screen: in this monorepo, files under
   `apps/agi-os/src/app/` or `apps/agi-os/src/components/` other than tests.

3. **Screenshots, when the branch changes what a user sees.** If it adds or visibly changes a
   screen, dialog, form, navigation or what a user can do, and the PR has no Screenshots section
   yet (or the screens changed since its images were taken), invoke the repo's `pr-screenshots`
   skill (`.claude/skills/pr-screenshots/`). It captures the screens with made-up data, commits
   the images beside the spec, and says how to link them. Skip it for a change nobody can see,
   and say why in the Screenshots section. In a repo without that skill, write the section from
   what the user provides, or leave it out.

4. **Write the description** — produce a markdown body with these sections:

   ```
   ## Summary
   1-3 sentences explaining the motivation and what changed at a high level.

   ## What changed
   Grouped by theme/area. Use bold headers for groupings. Bullet points for specifics.

   ## Screenshots
   Only when the branch changes what a user sees (step 3): recordings inline, each screenshot
   in a <details> block. Or one line saying why there are none.

   ## Testing
   How to verify this works — commands to run, what to look for.

   ## Affected Areas
   Checklist of services/apps touched.

   ## Notes for Reviewers
   Call out anything that needs special attention: large mechanical diffs, breaking changes, things left for follow-up.
   ```

   Guidelines:
   - Be concise. Reviewers skim.
   - Group related changes; don't just list commits.
   - If the diff is mostly mechanical (formatting, renames), say so explicitly and point reviewers to the substantive changes.

5. **Derive the title** — a concise title from the ticket and commits:
   - Format: `[TICKET-ID] Short description` when the work has a Linear/Jira ticket. Look for
     the ID, in this order: the ticket the conversation is about, a spec on the branch named
     `docs/specs/<ticket-id>-….md`, then the branch name (e.g. `agi-69` → `AGI-69`). Branches
     Claude creates for its own worktrees are named `worktree-…` and usually carry no ID, so
     don't rely on the branch alone. The bracketed ID is also what links the PR to the ticket
     in Linear.
   - Otherwise: a plain short title (under 70 characters)

6. **Upload** — write the body to `/tmp/pr-<number>-body.md`, or `/tmp/pr-<branch>-body.md` when
   there is no number yet. Then, depending on what step 1 found:

   **PR exists** — edit it in place:
   ```
   gh pr edit <number> --title "<title>" --body-file <path>
   ```

   **No PR yet** — push the branch first if it has no upstream (`git push -u origin HEAD`), then
   open it against the default branch:
   ```
   gh pr create --base main --title "<title>" --body-file <path>
   ```

   If the arguments include `--draft`, as `/implement` passes them, add `--draft` to
   `gh pr create`.

   This command describes what is committed; it doesn't commit, apart from the screenshots
   step 3 commits on their own. `/implement` commits before it runs these steps. Uncommitted
   changes are not a reason to hold the PR: open it from what is already committed, and
   mention the uncommitted files in the report.

7. **Report** — show the user the PR URL when done, and say which path you took: created a new PR,
   or updated an existing one. If step 3 captured screenshots, say which, and ask the user to
   check the description renders them: they can't be checked from the command line.
