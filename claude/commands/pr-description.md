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

Use the argument as `$ARGUMENTS` if provided.

## Steps

1. **Identify the PR** — resolve the PR number from the argument or current branch.

   If `gh pr view` reports no PR for the branch, the PR does not exist yet: **create it** in step 5
   rather than stopping. A branch whose work is already committed but unopened is a normal path for
   this command, not an error, so don't ask for confirmation first.

2. **Gather context** — run these in parallel:
   - `gh pr view <num> --json title,body` to see the current title/body — skip this one when no PR
     exists yet
   - `git log main..HEAD --oneline` to list all commits on the branch
   - `git diff main..HEAD --stat` to get a summary of changed files and line counts

   If the diff is too large for GitHub's API, use local git commands instead.

3. **Write the description** — produce a markdown body with these sections:

   ```
   ## Summary
   1-3 sentences explaining the motivation and what changed at a high level.

   ## What changed
   Grouped by theme/area. Use bold headers for groupings. Bullet points for specifics.

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
   - Do NOT include a "Generated with Claude Code" footer.

4. **Derive the title** — a concise title from the branch name and commits:
   - Format: `[TICKET-ID] Short description` if a Linear/Jira ticket ID is detectable in the branch name (e.g. `agi-69` → `AGI-69`)
   - Otherwise: a plain short title (under 70 characters)

5. **Upload** — write the body to `/tmp/pr-<number>-body.md`, or `/tmp/pr-<branch>-body.md` when
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

   Never commit or stage on the user's behalf to make a PR possible. If the working tree still has
   uncommitted changes that belong in this PR, say so and let the user commit them before you
   create it.

6. **Report** — show the user the PR URL when done, and say which path you took: created a new PR,
   or updated an existing one.
