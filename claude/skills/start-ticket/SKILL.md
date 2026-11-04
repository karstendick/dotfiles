---
name: start-ticket
description: Start work on a Linear ticket — read it, check for open blockers, move it to In Progress and assign it to me, then hand over to grill-me. Use when asked to start, pick up, or kick off work on a ticket.
---

# Start Ticket Skill

This skill does the Linear bookkeeping, then hands the ticket to `grill-me`. It doesn't touch
git: Claude moves the session into its own worktree at its first edit, so there is no worktree
or branch to create here.

1. Read the ticket fully with `get_issue`, passing `includeRelations: true`. Read the real
   project field, and extract and view any images or attachments — the text description
   alone is often incomplete.
2. **Check `blockedBy` first.** Report any blocker that is not already Done, and stop for a
   decision rather than starting work on a blocked ticket. Blockers listed on the ticket may
   themselves be Cancelled or Done — say which, since a stale relation reads like a blocker
   and isn't one.
3. **Don't analyze the codebase here.** Reading the code the ticket touches is `grill-me`'s
   first step. Linear reads (step 1) and the blocker check (step 2) are the only
   investigation this skill does.
4. Move the ticket to **In Progress** and assign it to the user (Joshua Karstendick) in a
   single `save_issue` call, passing `assignee: "me"`. Leave out whichever half is already
   true, and skip the call entirely if both are, saying so instead of writing a no-op
   update. If the ticket is assigned to someone else, do not reassign it: still set the
   status, and name the current assignee in your report so the user can decide.

   **Check the response, not just that the call succeeded.** `save_issue` can accept a state
   *name* and silently leave the status unchanged. If the returned `status` is not
   In Progress, look up the team's statuses with `list_issue_statuses` and retry with the
   In Progress status's `id`.
5. Report the Linear status, the assignee, and any blocker in two or three lines, then run
   the `grill-me` skill on this ticket. Don't write a scope summary or a plan first; that's
   what grilling produces.
