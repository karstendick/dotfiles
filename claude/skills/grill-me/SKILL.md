---
name: grill-me
description: Interview me about a ticket, plan or design until we share an understanding of it, before any spec or code. Use when asked to grill me, stress-test a plan, or work through a design together, and when `start-ticket` hands over a ticket.
---

# Grill Me Skill

Interview me relentlessly about every aspect of this plan until we reach a shared
understanding. Walk down each branch of the design tree, resolving dependencies between
decisions one by one. If a question can be answered by exploring the codebase, explore the
codebase instead. For each question, provide your recommended answer.

1. **Start from the source.** If there is a ticket, read it fully: images, attachments and
   the actual project field, not just the title. Then read the code it touches. If there is
   no ticket, start from what I've said.
2. **Ask in rounds.** Each round, ask every question that can be decided now, as one
   numbered list, so I can answer `1 yes, 2 no — …, 3 …`. Hold back questions that depend on
   an answer still open; they belong to a later round. Ask in plain text, not through a
   question tool.
3. **Only ask about decisions.** Look facts up yourself, using subagents when the search is
   broad, and state what you found rather than asking me to confirm it. A question is worth
   asking only if its answer changes what gets built. Don't ask about logistics, scheduling
   or communication, or about hypotheticals I haven't raised.
4. **Make each question stand alone.** Name what it's about and why it matters, and give the
   mechanism behind each option. Don't refer back to "option B above" or to your earlier
   research. End with your recommendation and the reason for it; when the options differ in
   what they break, say what each one breaks.
5. **Take answers as given.** When I answer, that branch is settled. Don't re-argue it
   unless something you find later contradicts it, and then say what you found.
6. **Change nothing.** This is a conversation. Don't edit files, create branches, commit, or
   run anything that changes state outside reading and searching. A question from me during
   grilling is a question, not a request to act.
7. **Finish with the shared understanding.** When no branch is open, write a short summary:
   each decision and its reason, what is explicitly out of scope, and any question I chose to
   leave open.
   - **In plan mode,** present the summary as the plan, through the plan-approval step. My
     approving it is the confirmation, and it takes the session out of plan mode.
   - **Otherwise,** ask me to confirm it in conversation.

   Then stop. The plan is the summary, not "write the spec and implement it". The `spec` skill
   turns the confirmed summary into the spec; don't write the spec here, and don't start
   implementing.
