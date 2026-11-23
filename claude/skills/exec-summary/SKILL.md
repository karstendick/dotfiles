---
name: exec-summary
description: Draft the weekly executive update — one short, plain-English post per Linear project, in the voice of Joshua's own Linear project updates — from the week's completed Linear issues, merged PRs and Security Report runs. Use when asked for an executive summary, an update to report up, or the project updates for the week. Shows drafts only; never posts to Linear.
---

# Weekly Executive Summary

Every week Joshua reports up to the executive team on what engineering shipped. The
deliverable is **one draft per Linear project**, ready to paste into that project's
update. It is not a list of tickets — `weekly-summary` is the detailed, engineer-facing
version, and this skill borrows its data gathering but not its output.

**Show the drafts in chat. Never post a status update to Linear.** Joshua posts them himself.

## 1. Gather the week's data

Follow `weekly-summary` (`../weekly-summary/SKILL.md`) steps 1–5 exactly: the half-open
`[START, END)` window (default: the last 7 days, today exclusive), merged PRs bounded on
both ends, Done Linear issues filtered by `completedAt` yourself, the two-way PR↔ticket
cross-reference, and the security-finding counts from every Security Report run in the
window. Those rules exist because each one was once gotten wrong; don't shortcut them.

Read PR bodies for the "why" of each change — the summary lines need outcomes, and titles
alone rarely say what got better for whom.

## 2. Calibrate on Joshua's recent updates

```
mcp__linear-server__get_status_updates  type: project  createdAt: -P42D  orderBy: createdAt
```

Read the last several weeks of his updates and match them: length, tone, what gets a
number, what gets left out. As of 2026-11 they look like this:

> We closed 14 tickets this week. We shipped several improvements to how clients are linked
> to HubSpot data. We also shipped improvements to tasks and cross-sell opportunities.

> We maintained zero security vulnerabilities by the end of every day, fixing new findings
> same day. We addressed 5 high, 3 medium, and 2 low-severity findings.

If his recent style has drifted from the rules below, follow his updates.

## 3. Make sure every completed ticket has a project

Ticket counts come from each ticket's Linear **project field** — that's what his updates
count. Before drafting, list every ticket completed in the window whose project is null,
with a link and a suggested project for each, grouped by suggestion. Alarm-labeled tickets
filed by the alarm investigation usually belong in Foundational engineering; Aikido
dependency-upgrade tickets usually belong in Compliance.

**Ask before assigning.** Joshua decides where a ticket goes. Once he confirms, set them with
`save_issue` (`project: <name>`), then re-read each with `get_issue` — the `save_issue`
echo can omit the project even when the write succeeded.

Count tickets per project only after this step, so the counts cover all of the week's work.

## 4. Draft one update per project

One section per project that had work this week. Skip projects with none — don't write
"no updates."

Each update:

- Opens with **"We closed N tickets this week."** using the project-field count.
- Follows with 1–3 outcomes, as short sentences or bullets, in plain English an executive
  can read without context: what users or the business can now do, what risk went away,
  what got faster or cheaper. Say *what* changed, not how it was built.
- Has **no ticket numbers, PR numbers, line counts, author counts, file names, or
  library/package names**. Name a vendor or person only where an executive would know them
  (Redbird, Betsy, Epic, HubSpot, AWS).
- Says **"started"** or "began" for work whose ticket is still In Progress, even if PRs merged.
- Treats a production incident as a story about the fix: what monitoring caught, that it
  was fixed (same day, if so), and what now prevents it.
- Describes continuing multi-week work as progress on it, not as new work.

### Compliance

Lead with the Security Report numbers from `weekly-summary` step 5, in his phrasing:
"We addressed 1 critical, 2 high, 1 medium, and 2 low-severity vulnerabilities." Say
whether each was fixed the same day it was found, and whether the report held at zero at
the end of every day.

- **Never call a finding fixed unless a merged change fixed it.** A finding that drops out
  of the report with no PR behind it was probably dismissed in Aikido — state that it
  opened, not that it closed, and flag it in the notes (step 5).
- **Report auditor findings separately** from the scanner counts — e.g. "We also closed 6
  findings from our auditor's AWS review (4 high, 2 medium)" — then bullet the
  meaningful ones as outcomes. Their severities come from the ticket titles
  (`Security (high) …`). Audit tickets closed with evidence rather than a change still count.
- A deferred finding (no patched release, formally excepted) is not "addressed."

## 5. Notes for Joshua, after the drafts

Below the drafts, a short list of anything he should decide before posting, such as:

- A duplicate ticket inflating a count (and the count without it).
- A security finding that vanished without a fix.
- Projects skipped for having no work.
- Ticket counts that changed because of step 3.

Keep it to what changes what he posts. No process commentary.

## Output

```markdown
**<Project>**

We closed <N> tickets this week. <Outcome sentence.>

* <Outcome bullet, if the update needs a list.>

---

**<Next project>**
…

---

<Notes for Joshua>
```

End with a `result:` line naming the week and the per-project ticket counts.
