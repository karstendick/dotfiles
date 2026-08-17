---
name: weekly-summary
description: Summarize what the team shipped over a period (default: last 7 days) by cross-referencing merged GitHub PRs, completed Linear issues, and direct commits to main. Use when asked to summarize shipped work, write a weekly recap, or report on team accomplishments.
---

# Weekly Shipped-Work Summary

A progress report for the company. Serves both leadership and engineers in one pass. Default window is the last 7 days; honor any window the user names instead.

This is a report on **what shipped**, not a review of how the team works. No process or hygiene commentary.

## 1. Establish the window

Compute explicit start/end dates and state them in the output. Every filter below must be checked against these dates — do not trust a tool's own relative-date filter to mean what it says (see step 3).

## 2. Merged PRs

```bash
gh pr list --state merged --limit 100 \
  --json number,title,author,mergedAt,additions,deletions,labels \
  --search "merged:>=<START>"
```

Record author, ticket prefix, and line counts per PR. Count PRs per author and re-verify the tally before publishing it — miscounting contributors is the easiest way to embarrass yourself in a summary someone forwards.

## 3. Completed Linear issues

```
mcp__linear-server__list_issues
  state: Done
  updatedAt: -P14D          # deliberately wider than the window
  fields: [title, status, assignee, project, completedAt, labels, priority, url]
  limit: 100
```

**`updatedAt` is not a completion filter.** It returns issues touched recently but completed long before — a run on Aug 17 surfaced AGI-178 (completed Jul 22) and AGI-212 (Aug 7). Query wide, then filter on `completedAt` inside the window yourself.

## 4. Direct commits to main — do not skip this

Real product work lands outside PRs and would otherwise go unreported. A run on Aug 17 found `02697a4`, a stale-credential fix in the auth context and API client, invisible in both the PR list and Linear.

```bash
git log --since='<START minus 1 day>' \
  --pretty=format:'%h|%an|%ad|%s' --date=iso origin/main | grep -v '(#[0-9]*)$'
```

- The repo squash-merges, so PR commits end in `(#123)`. `grep -v` on that leaves direct commits, merge commits, and anything else unaccounted for.
- **Widen the `--since` boundary by a day.** `--since=YYYY-MM-DD` has silently dropped commits that were inside the window (it dropped `bec41c1`/#247 on a same-day boundary). Over-fetch, then filter by date yourself.
- Run `git show --stat <sha>` on each hit and triage:
  - **Product code** → shipped work. Fold it into the relevant project section, cited by SHA instead of PR number.
  - **Docs and specs** → mention only if they're a deliverable someone asked for.
  - **Local tooling and config** (`.envrc`, editor settings) → omit.
  - **Merge commits** → not new work; omit.
- Check `git rev-parse HEAD origin/main`. If local `origin/main` is behind, say so rather than silently reporting partial history; don't fetch unless asked.

## 5. Cross-reference both directions

Ticket↔PR linkage is lossy, and getting it wrong misattributes or drops work. Verified failure modes: a PR whose title omitted the `[AGI-xxx]` prefix despite mapping to a real ticket (#252 → AGI-249); a ticket with no assignee whose PR had one (AGI-231 → #249); one PR closing several tickets (#259 → AGI-242 + AGI-237). Reconcile the two lists against each other; don't infer linkage from titles alone.

## 6. Output

```markdown
## Week of <START>–<END>

**Summary** — 2–4 sentences: what changed for users, in outcome terms, no ticket numbers.

---

**<N> PRs merged (#A–#B) · <N> Linear issues closed**
Line counts, contributors with per-author PR counts.

### <Project name> (<N> PRs, <N> tickets)
- **[AGI-xxx]** What shipped and why it matters (#PR)

### Themes
2–4 numbered observations that only emerge from seeing the whole week — cross-project
convergence, a direction the work implies. Not a restatement of the list.
```

## Rules

- Group by project, not by author or chronology. Projects are how the work is actually understood.
- Lead with user-visible impact. A ticket number is a reference, not an accomplishment.
- Describe what shipped, not how it was built or tracked.
- If work can't be attributed to a project, put it under a plain "Other" heading rather than inventing one.
