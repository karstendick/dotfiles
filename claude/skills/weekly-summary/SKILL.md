---
name: weekly-summary
description: Summarize what the team shipped over a period (default: last 7 days) by cross-referencing merged GitHub PRs, completed Linear issues, and direct commits to main. Use when asked to summarize shipped work, write a weekly recap, or report on team accomplishments.
---

# Weekly Shipped-Work Summary

A progress report for the company. Serves both leadership and engineers in one pass. Default window is the last 7 days; honor any window the user names instead.

This is a report on **what shipped**, not a review of how the team works. No process or hygiene commentary.

## 1. Establish the window — half-open `[START, END)`

`START` inclusive, `END` **exclusive**. Default `START = today − 7`, `END = today`. Compute both as explicit dates and state them in the output.

**The exclusive end is what stops week-to-week double-counting.** This skill is run weekly to report upward, so consecutive windows must tile exactly rather than overlap. Every filter below is bounded on *both* ends and re-checked against these dates — never rely on a tool's own relative-date filter (see step 3), and never leave an upper bound off (see step 2).

## 2. Merged PRs

```bash
gh pr list --state merged --limit 100 \
  --json number,title,author,mergedAt,additions,deletions,labels \
  --search "merged:>=<START> merged:<<END>"
```

**Both bounds are required.** An open-ended `merged:>=<START>` sweeps up to the moment of the run, so anything merged on the boundary day appears in this report *and* next week's — a run on Aug 31 and a run on Aug 24 both claimed #278 / AGI-287 (merged Aug 24 14:55 UTC) this way.

Record author, ticket prefix, and line counts per PR. Count PRs per author and re-verify the tally before publishing it — miscounting contributors is the easiest way to embarrass yourself in a summary someone forwards.

## 3. Completed Linear issues

```
mcp__linear-server__list_issues
  state: Done
  updatedAt: -P14D          # deliberately wider than the window
  fields: [title, status, assignee, project, completedAt, labels, priority, url]
  limit: 100
```

**`updatedAt` is not a completion filter.** It returns issues touched recently but completed long before — a run on Aug 17 surfaced AGI-178 (completed Jul 22) and AGI-212 (Aug 7); a run on Aug 31 returned 29 issues of which only 10 were in window. Query wide, then filter yourself on `START <= completedAt < END`, exclusive at the top.

A reopened-and-recompleted ticket gets a new `completedAt` and will legitimately appear in a second week. If you spot one already reported, note that it was re-completed rather than listing it as new.

## 4. Direct commits to main — do not skip this

Real product work lands outside PRs and would otherwise go unreported. A run on Aug 17 found `02697a4`, a stale-credential fix in the auth context and API client, invisible in both the PR list and Linear.

```bash
git log --since='<START minus 1 day>' \
  --pretty=format:'%h|%an|%ad|%s' --date=iso origin/main | grep -v '(#[0-9]*)$'
```

- The repo squash-merges, so PR commits end in `(#123)`. `grep -v` on that leaves direct commits, merge commits, and anything else unaccounted for.
- **Widen `--since` by a day, then discard the overshoot — both halves are mandatory.** `--since=YYYY-MM-DD` has silently dropped commits that were inside the window (it dropped `bec41c1`/#247 on a same-day boundary), so over-fetching is necessary. But keeping the overshoot re-reports the prior day, which is exactly the double-count the half-open window exists to prevent. After the `grep`, drop every commit outside `[START, END)` before triaging.
- Run `git show --stat <sha>` on each hit and triage:
  - **Product code** → shipped work. Fold it into the relevant project section, cited by SHA instead of PR number.
  - **Docs and specs** → mention only if they're a deliverable someone asked for.
  - **Local tooling and config** (`.envrc`, editor settings) → omit.
  - **Merge commits** → not new work; omit.
- **Verify local history is current, or work around it.** Compare `git rev-parse origin/main` against the remote tip:

  ```bash
  gh api repos/AGIHoldings/monorepo/commits/main --jq '.sha + "  " + .commit.committer.date'
  ```

  If local is behind, read the window's history from the API instead of `git log` — don't fetch unless asked:

  ```bash
  gh api "repos/AGIHoldings/monorepo/commits?sha=main&since=<START>T00:00:00Z&per_page=100" \
    --jq '.[] | [.sha[0:7], .commit.author.name, .commit.author.date,
                 (.commit.message | split("\n")[0])] | @tsv' | grep -vE '\(#[0-9]+\)$'
  ```

  A stale ref was 4 days behind on Aug 31. This failure mode *under*-reports rather than double-counts: work missed here falls outside next week's window too, so it is dropped permanently and never shows up again. Say in the output which source you used.

## 5. Cross-reference both directions

Ticket↔PR linkage is lossy, and getting it wrong misattributes or drops work. Verified failure modes: a PR whose title omitted the `[AGI-xxx]` prefix despite mapping to a real ticket (#252 → AGI-249); a ticket with no assignee whose PR had one (AGI-231 → #249); one PR closing several tickets (#259 → AGI-242 + AGI-237). Reconcile the two lists against each other; don't infer linkage from titles alone.

## 6. Output

```markdown
## Week of <START> – <END, exclusive>

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
- **Don't re-report continuing work as new.** Since this runs weekly, multi-week threads recur: a theme restated verbatim, or a document amended across several weeks (the Aug 2026 incident report landed over four commits in one week and could easily gain sections in the next). Frame these as continuations — "the editable-review work continued with…" — so a reader tracking week over week sees progress, not repetition.
