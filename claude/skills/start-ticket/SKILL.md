---
name: start-ticket
description: Start work on a Linear ticket — read it, check for open blockers, create a git worktree on the ticket's branch, and move it to In Progress. Use when asked to start, pick up, or kick off work on a ticket.
---

# Start Ticket Skill

1. Read the ticket fully with `get_issue`, passing `includeRelations: true`. Read the real
   project field, and extract and view any images or attachments — the text description
   alone is often incomplete.
2. **Check `blockedBy` before touching git.** Report any blocker that is not already Done,
   and stop for a decision rather than starting work on a blocked ticket. Blockers listed
   on the ticket may themselves be Cancelled or Done — say which, since a stale relation
   reads like a blocker and isn't one.
3. **Do not analyze the codebase.** This skill sets up the workspace; it does not scope the
   work. Do not read source files, grep, trace call sites, inspect the files the ticket
   names, or check whether the ticket's claims still hold against `HEAD`. That analysis
   belongs to the `spec` skill, which the user runs next in the new worktree — doing it
   here burns context on the wrong side of the handoff and gets redone anyway. Linear reads
   (step 1) and the blocker check (step 2) are the only investigation this skill does.
4. Take the branch name from the ticket's `gitBranchName` field, verbatim. Never construct
   or retype it.
5. Choose the worktree directory: a **sibling of the repo root**, named
   `<repo-dir>-<slug>`, where `<slug>` is two to four descriptive words taken from the
   branch name with the `<user>/` prefix and the ticket ID removed. So
   `joshua/agi-415-let-the-response-schema-decide-what-goes-on-the-wire` in `~/git/monorepo`
   gives `~/git/monorepo-response-schema-wire`, matching the existing
   `monorepo-parallel-playwright` and `monorepo-vulnerability-tracking`. Never use the full
   branch slug as the directory name.

   **Pick the slug yourself and say what you picked. Do not ask the user to choose or
   confirm it.** It is a `cd` target, not a design decision — asking costs more of the
   user's attention than the name is worth, and a worktree is cheap to `git worktree move`
   if it ever actually grates. The only case that needs more than a mechanical choice is a
   **collision**: if that path already exists, or an existing sibling worktree is close
   enough in topic to be confusing, silently pick a more specific slug that distinguishes
   them and note the near-miss in your report. Still do not ask.
6. Create it in one step, branching off **`origin/main`** — never the current `HEAD`, since
   the user may be sitting in another worktree, and never local `main`, which is usually
   behind:
   `git worktree add -b <gitBranchName> <path> origin/main`.
   **`origin/main` is the answer every time. Do not ask which base to use.** Starting from a
   stale local `main` surfaces later as unrelated commits in the PR diff, which is why the
   answer never varies. Note that this reads the `origin/main` ref already on disk: do not
   `fetch` or `pull` on the user's behalf, and do not touch local `main` at all. If local
   `main` is behind, that is now irrelevant rather than a question — mention it only if the
   user needs it for something else.
7. Move the ticket to **In Progress** with `save_issue` — unless it is already there, in
   which case say so instead of writing a no-op update.
8. **Stop there, and stop quickly.** Do not install dependencies, build packages, or create
   any env file — the user handles setup himself with `direnv allow` and `pnpm dev`, and it
   works in a fresh worktree. A finished run of this skill is a handful of tool calls: read
   the ticket, check the siblings, `git worktree add`, set the status.
9. Report the worktree path, the branch, the Linear status, and any unresolved blocker —
   nothing else. No scope summary, no implementation sketch, no file list, no plan. The
   user runs the `spec` skill from the new worktree next; leave the thinking to it, and do
   not begin implementing.
