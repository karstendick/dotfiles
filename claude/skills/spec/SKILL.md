---
name: spec
description: Write an implementation spec for a feature or fix — from a ticket or from a discussion — and wait for approval before implementing. Use when asked to spec something out, write a spec, or turn an idea or ticket into a plan.
---

# Spec Writing Skill

1. If the work has a ticket (Linear or otherwise), read it fully — including images, attachments,
   and the actual project field rather than inferring from the title. If there is no ticket, write
   the spec from the conversation and note at the top of the file that it came from a discussion.
2. Use this structure: Context → Requirements → Design Decisions → Implementation Plan → Test Plan → Open Questions
3. Make the spec self-contained: a fresh session with no prior context must be able to implement it
   from the file alone. Name the files to change and the existing code they touch as `path:line`,
   state the conclusions the investigation reached rather than pointing back at the research, and give
   the exact commands that verify the result. Do not rely on anything that only exists in the
   conversation that produced the spec.
4. Never add content the user hasn't discussed
5. Mark deferred items clearly and do not implement them
6. When an Open Question gets answered, append the answer to the question (e.g. `_Resolved: ..._`).
   Never delete the question — the spec is a record of what was considered, not just what was decided.
7. Write the spec to `docs/specs/`, named:
   - If that directory already has specs, follow their existing naming and format — that convention
     wins over the rules below.
   - With a ticket: `<ticket-id>-<short-slug>.md`, lowercased (e.g. `agi-123-retry-backoff.md`).
   - Without a ticket: `<short-slug>.md` (e.g. `solve-replay-animation.md`). Do not invent a ticket
     ID or a placeholder number.
8. After writing, wait for user approval before implementing
