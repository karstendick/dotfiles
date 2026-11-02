---
name: weekly-summary
description: Summarize what the team shipped over a period (default: last 7 days) by cross-referencing merged GitHub PRs and completed Linear issues, plus the security findings addressed by severity from the daily Security Report runs. Use when asked to summarize shipped work, write a weekly recap, or report on team accomplishments.
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

Main is protected against direct pushes, so merged PRs are the only way code ships. There is no commit-log step.

## 4. Cross-reference both directions

Ticket↔PR linkage is lossy, and getting it wrong misattributes or drops work. Verified failure modes: a PR whose title omitted the `[AGI-xxx]` prefix despite mapping to a real ticket (#252 → AGI-249); a ticket with no assignee whose PR had one (AGI-231 → #249); one PR closing several tickets (#259 → AGI-242 + AGI-237). Reconcile the two lists against each other; don't infer linkage from titles alone.

Tickets closed with no PR are still real (configuration, evidence documents, decisions, old tickets closed out). List them, and say they had no PR rather than guessing one.

## 5. Security findings addressed, by severity

Leadership wants the Compliance work reported as "X Critical, Y High, Z Medium, W Low addressed", not as a description of the fixes. Get the numbers from the monorepo's Security Report workflow, which runs daily plus on manual dispatch. Each run's job log prints that day's table of open findings, one row per finding, with its severity and exposure tier.

```bash
gh run list --repo AGIHoldings/monorepo --workflow security-report.yml --limit 60 \
  --json databaseId,createdAt,conclusion,event
gh run view <id> --repo AGIHoldings/monorepo --log
```

Read every run in `[START, END)`, plus the last run before `START` for the starting state. A finding was addressed if it is in one run's table and gone from the next run's. Add those up by severity for the whole week.

- **Read every run, not just the first and last.** A finding can open and close between two daily runs. The two Next.js criticals on 2026-10-15 did exactly that, and a start-versus-end comparison would have missed them.
- **Use the tables, not the "Movement since" section.** That section stops listing after ten entries, gives no severity totals, and compares only two snapshots a week apart.
- **Count only findings in the "current" tier.** That tier covers running images, the cloud and the repo. A finding seen only on "old" (retired) images that drops off was not fixed this week.
- **Count each advisory once.** The same CVE often appears twice, once against the package and once against `pnpm-lock.yaml`, from two scanners. Count it once, at the higher severity.
- **Match each addressed finding to a Compliance ticket or PR from the week.** If a finding has no fix behind it, it was probably ignored or snoozed in Aikido. Leave it out, or footnote it if the fix shipped and Aikido closed it without a retest, as happened with the login rate-limit finding after AGI-598.
- **Report the state at the end of the week too:** open findings by severity in the last run before `END`, and whether the report held at zero. It has been at zero since 2026-10-20, so "found and fixed the same day" is the notable thing to say.

Put this in the Compliance section as one line, for example: "**Security findings addressed: 0 Critical, 5 High, 3 Medium, 2 Low.** Open at end of week: none."

## 6. Output

```markdown
## Week of <START> – <END, exclusive>

**Summary** — 2–4 sentences: what changed for users, in outcome terms, no ticket numbers.

---

**<N> PRs merged (#A–#B) · <N> Linear issues closed**
Line counts, contributors with per-author PR counts.

### <Project name> (<N> PRs, <N> tickets)
- **[AGI-xxx]** What shipped and why it matters (#PR)

### Compliance (<N> PRs, <N> tickets)
**Security findings addressed: <N> Critical, <N> High, <N> Medium, <N> Low.**
Open at end of week: <counts by severity, or none>.
- **[AGI-xxx]** …

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
