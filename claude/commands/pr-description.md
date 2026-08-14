---
description: "Write and upload a PR description for the current branch or a given PR number/URL"
---

# PR Description

Write a pull request description and upload it to GitHub.

## Input

The user may provide:
- A PR number (e.g., `148`)
- A PR URL (e.g., `https://github.com/org/repo/pulls/148`)
- Nothing — in which case, infer the PR from the current branch using `gh pr view --json number`

Use the argument as `$ARGUMENTS` if provided.

## Steps

1. **Identify the PR** — resolve the PR number from the argument or current branch.

2. **Gather context** — run these in parallel:
   - `gh pr view <num> --json title,body` to see the current title/body
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

4. **Update the title** — derive a concise title from the branch name and commits:
   - Format: `[TICKET-ID] Short description` if a Linear/Jira ticket ID is detectable in the branch name (e.g. `agi-69` → `AGI-69`)
   - Otherwise: a plain short title (under 70 characters)
   - Run: `gh pr edit <number> --title "<title>"`

5. **Upload the body** — write it to `/tmp/pr-<number>-body.md`, then run:
   ```
   gh pr edit <number> --body-file /tmp/pr-<number>-body.md
   ```

6. **Report** — show the user the PR URL when done.
