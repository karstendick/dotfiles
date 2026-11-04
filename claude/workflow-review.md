# Claude Code workflow review — November 2026

A working document for updating my Claude Code workflow, which predates most of what
Claude Code (now v2.1.318) and iTerm2 (now 3.7.7) ship. Inputs: the `/insights` report of
2026-11-04 (149 sessions, 2026-09-16 → 11-04), my current skills (`spec`, `start-ticket`,
`pr-description`), and the official docs and changelogs. Items marked **(unverified)**
came from docs that didn't settle the point; each one is a spike in [Verify first](#verify-first).

## Where I am today

| Step | Today | Pain (from `/insights`) |
| --- | --- | --- |
| Start | `/start-ticket` in the primary checkout → Linear status + sibling `monorepo-<slug>` worktree | Works. Skill had to be told to stop analysing. |
| Workspace | One VS Code window per worktree (laid out by my worktree-layout extension) | Window juggling; no single view of who needs me |
| Design | `/spec` writes a long `docs/specs/*.md` (138 specs, **avg ~450 lines, largest ~1,800**) | Padded with out-of-scope content; I trim after the fact |
| Implement | Same session, auto mode | Classifier blocks; Bedrock 503s → silent sessions, "you there?" |
| Review | Mostly in VS Code / in-session | — |
| PR | `/pr-description` | Works |

The friction is mostly *Claude acting beyond the request* and *environment stalls*, not bad
code. Several features below address those directly; that's where I'd start.

## Recommendations at a glance

1. **Quick wins in `settings.json` (an hour):** fallback model chain, auto-mode environment,
   1-hour prompt cache. Fixes the 503 silences and most classifier blocks.
2. **One iTerm2 window:** install iTerm2's built-in Claude Code integration and run
   `claude agents` (agent view) as the hub. Drop VS Code from the loop.
3. **Grill, then spec:** do the design as a conversation, one question at a time
   (`/grill-me`), then write a *shorter* spec that records what we decided.
   Implementation runs on Sonnet.
4. **Review on GitHub, let Claude work the comments:** open a draft PR when implementation
   is green, have Claude's review comments land first (managed Code Review after a capped pilot, or
   the local `/code-review --comment`), review line by line on
   GitHub, and have bare `/loop` work through my comments and CI failures.
5. **Let Claude own the worktree:** agent view already isolates each background session in
   its own worktree. Since Claude pushes to GitHub itself, I never touch the worktree, so
   `/start-ticket` keeps only its Linear half.

The rest of this doc covers each one: options, tradeoffs, the pick. The
[typical workflow](#typical-workflow) at the end puts it together.

---

## 1. Quick wins (settings only)

All of these go in `~/git/dotfiles/claude/settings.json`.

| Setting | Fixes | Notes |
| --- | --- | --- |
| `"fallbackModel": ["sonnet"]` **(done 2026-11-04)** | Bedrock 503 silences | Switches models for the rest of a turn when the primary is overloaded, unavailable, or returns another non-retryable server error. Rate-limit, auth and transport errors never switch. The next message tries Opus again. Subagents use the chain too. `sonnet` resolves through `.envrc`'s pin to `us.anthropic.claude-sonnet-5-5`, which I tested on Bedrock. A switch shows **only an in-session notice**, with no desktop notification and nothing in `/status`. Wider option: `global.anthropic.claude-opus-5-5` (same model, global capacity pool) is ACTIVE on our account, but it can route inference outside US regions, so it's a data-residency call. [model-config](https://code.claude.com/docs/en/model-config.md) |
| `autoMode.environment` + `/auto-mode-setup` **(done 2026-11-04)** | Classifier blocks on routine commands | My allowlist is checked first: matching commands skip the classifier entirely. The environment list covers everything else by telling the classifier what's inside my boundary; by default that's only the working directory and the repo's remotes. `/auto-mode-setup` drafted it. I then moved `agi-documents-prod` from trusted buckets to sensitive data locations, added Aikido and Linear as trusted domains, and put HubSpot under key services, with the dev/prod credential split, because `api.hubapi.com` serves both portals. Source control stays monorepo-only. Still to do: run `claude auto-mode critique`, and re-run `/insights` later to see whether blocks dropped. Read **only** from user/managed settings. Keep `"$defaults"` in any list I override. `/permissions` → *Recently blocked* → `r` approves one after the fact. [auto-mode-config](https://code.claude.com/docs/en/auto-mode-config.md) |
| `"promptCacheTtl": "1h"` **(done 2026-11-04)** | Expensive, slow resumes after a 5–60 min break | Works on Bedrock with Opus 5.5 (measured: the same 38.5k-token write cost $0.19 at 5m, $0.31 at 1h). Writes cost 2x base instead of 1.25x; cache reads are 0.1x. **Break-even is about one 5–60 min break per session**: the extra cost is ~0.75x × final context, and each break it survives saves ~1.15x × context. Multi-session work makes those breaks the norm. Subagents stay on 5m. `idleCompaction` (on by default) compacts a 200k+ token conversation idle ~54 min before the cache expires. If a compacted spec session loses detail I needed, set it to `false`. |
| `"attribution": {"pr": ""}` **(done 2026-11-04)** | PR footer | Replaces the "no footer" rule that lived in `/pr-description` and memory. `commit` is unset, so commits keep the default `Co-Authored-By` trailer. |

Also worth knowing: `/insights` now estimates how many permission prompts auto mode could
have absorbed. Run it again after tuning to see whether it helped.

## 2. One iTerm2 window

### The pieces

- **iTerm2's Claude Code integration** **(done by 2026-11-04)** is a built-in iTerm2 3.7
  feature, not a marketplace plugin: *iTerm2 → Install Claude Code Integration*. It enables the Python API, writes a
  `cc-status` hook into `~/.claude/settings.json` (it follows the symlink into dotfiles as
  of 3.7.5), and adds:
  - **Session Status**: a colored dot and subtitle per tab (working / waiting / idle /
    done / error), and a Toolbelt list that sorts waiting sessions first.
  - **Cockpit** (⌥⇧⌘C): a floating status view across all windows, with per-session bells.
  - **Notify on Status Change** (⇧⌘X): a one-shot alert on the next change.
  - **Claude Code Workgroup**: Chat, a live **Diff**, and **Code Review** sharing one pane.
  [Docs](https://iterm2.com/claude-code-integration.html). (iTerm2's *AI Chat* is a
  separate, unrelated feature; ignore it.)
- **Plain `claude` in iTerm2** already sends desktop notifications. They worked in my setup
  before the integration added any hooks, so they come from Claude Code's built-in
  escape-sequence alert. If they ever stop, check *Profiles → Terminal → Notification Center Alerts* and
  *Filter Alerts → "Send escape sequence-generated alerts"*. Those notifications tell me
  *that* something happened; the integration tells me *which session* and ranks them.
- **Agent view (`claude agents`, research preview):** one pane listing every session,
  grouped *Needs input / Working / Ready for review / Completed*.
  - Type a prompt and press Enter to dispatch a new background session. `@<worktree>`
    targets a directory, `#1234` a PR.
  - `Space` peeks at a session; `Enter` attaches; `←` detaches without stopping it.
  - `Ctrl+R` renames, `Ctrl+T` pins.
  - From the shell: `claude --bg -n AGI-123 "…"`, `claude attach AGI-123`, `claude logs`,
    `claude stop`, `claude rm`.
  - Setting `defaultToAgentsView=true` makes bare `claude` open it.
  [Docs](https://code.claude.com/docs/en/agent-view.md)
- **`claude -w <name> --tmux`**: a session in its own iTerm2 native pane.
- **Cross-session messaging**: sessions on the same machine can message each other and
  ask for a one-shot notice when another goes idle ("tell me when the AGI-636 session
  finishes"). [Docs](https://code.claude.com/docs/en/cross-session-messaging.md)

### Options

**A. Tab per ticket.** One iTerm2 tab per worktree running `claude -n AGI-123`; iTerm2
Session Status and Cockpit show who needs me. Closest to today; just swaps VS Code
windows for tabs. Every session is a foreground process, so closing the tab ends it.

**B. Agent view as hub (recommended).** One tab running `claude agents`. Tickets run as
background sessions; I attach to the one I'm working with and detach when done.
- Sessions outlive the terminal.
- *Needs input* is a first-class group.
- Dispatch is one line.
- Deleting a session in agent view (`Ctrl+X` twice on its row) cleans up its worktree.
- Costs: it's a research preview, and **background sessions don't emit the per-tab OSC
  status**, so iTerm2's per-tab dots only describe the agent-view tab itself.
  Notifications for background sessions come from Claude Code: I already have
  `agentPushNotifEnabled`, plus the `Notification` hook's `agent_needs_input` /
  `agent_completed` matchers. **(unverified: how well these surface in iTerm2 for
  background sessions)**

**C. Hybrid.** B as the default. When I want a long pairing stretch on one ticket, I open
it in its own tab with `claude attach <name>` and get the iTerm2 Workgroup's Diff pane.

**Pick: B, with C as needed.** **(done 2026-11-04: agent view in iTerm2, integration enabled)** The iTerm2 integration is worth having either way (now
installed). It's reversible through an Uninstall menu item, and its Cockpit covers whatever
ends up in tabs.

### Opening agent view **(done 2026-11-04)**

`defaultToAgentsView: true` (in `~/.claude.json`, also settable with `/config`) makes a bare
`claude` open agent view. Dispatched sessions start like any new session: on Opus, my
`model` setting, in auto mode. Anything with arguments (`claude -p …`, `claude --resume …`)
runs as before.

Agent view does take dispatch defaults, but only as flags on `claude agents` (`--model`,
`--permission-mode`, `--effort`, `--agent`; there's no settings key for them). I briefly
used a `claude` shell function to pass `--model opusplan --permission-mode plan`, and
dropped it with plan mode (§3).

### What I lose by dropping VS Code **(done 2026-11-04)**

- My worktree-layout extension becomes obsolete.
- IDE selection context (`ide_selection`) and the diagnostics MCP go too. `pnpm lint:full`
  and `tsc` cover the latter.
- Clickable `file:line` links: iTerm2 ⌘-click opens them, configurable under
  *Profiles → Advanced → Semantic History*.

I'd keep VS Code installed for occasional browsing, not as part of the loop.

## 3. Design: grill, then a shorter spec

### What the new tools offer

- **Grill Me** (Matt Pocock, [repo](https://github.com/mattpocock/skills),
  [post](https://www.aihero.dev/my-grill-me-skill-has-gone-viral)). The core of the
  original is four sentences:
  > Interview me relentlessly about every aspect of this plan until we reach a shared
  > understanding. Walk down each branch of the design tree resolving dependencies between
  > decisions one by one. If a question can be answered by exploring the codebase, explore
  > the codebase instead. For each question, provide your recommended answer.

  His later version batches the answerable questions each round. I tried that and rejected
  it on the first real ticket (2026-11-04): six questions at once lose the one-by-one
  dependency walk, so my `/grill-me` asks one question per message. Like his, it looks facts
  up itself so it only asks about decisions. It takes no
  action until I confirm. His flow is *grill → `/to-spec` (synthesis only, no new
  questions) → tickets → implement*.
- **Plan mode** (`Shift+Tab`, `/plan`, `--permission-mode plan`). Claude can read and run
  exploration commands but **cannot edit files** until I approve the plan. `opusplan` is a
  *model* alias that runs Opus in plan mode and Sonnet otherwise.
  [Docs](https://code.claude.com/docs/en/permission-modes.md) I tried both and dropped them
  from the ticket workflow; see below.

### Why this matters for me

`/spec` is doing two jobs: finding the design *and* recording it. The first job is a
conversation and the second is a document, and doing both in one shot is where the padding
comes from. Claude writes 450 lines of conclusions before I've weighed in, and then I trim.

### Proposed flow

The session runs on Opus. `/implement` pins Sonnet for its own run.

1. `/grill-me` on Opus. Claude reads the ticket and code, then asks one question at a time,
   each with a recommendation. I answer, often just "yes", and the next question builds on
   that answer.
2. When no branch is open, Claude summarizes the shared understanding and I confirm it in
   conversation.
3. `/spec` writes a decision record to `docs/specs/<id>-<slug>.md` from the confirmed summary:
   decisions with reasons, scope, `path:line` files, verification commands, and any Open
   Questions I chose to leave open. No new content, mirroring Pocock's `/to-spec`. Writing it
   is the session's first edit, so this is when Claude moves into its own worktree (§5).
4. Review the spec, then `/implement`. It runs on Sonnet with the whole grilling conversation
   in context, so the spec doesn't have to restate it.

**Plan mode: tried and dropped (2026-11-04).** It was meant to do two things:
- **Make grilling read-only:** a "could we…?" couldn't become a branch and a commit.
- **Route models:** through `opusplan`, Opus for the thinking and Sonnet for the doing.

On the first real ticket it got in the way twice. It blocked `/start-ticket`'s In Progress
update, and then it blocked filing a follow-up ticket mid-grilling. It also forced the
grilling summary to pose as a "plan" to get through the approval step.

The read-only guarantee matters less than it did, because the harm it guarded against is now
contained:
- `git-guard.sh` blocks commits on `main`.
- A background session's edits land in its own worktree.
- Nothing ships except through a PR I review.

`/grill-me`'s "change nothing in the code" rule covers the rest, and it explicitly allows
Linear writes I ask for. For a read-only investigation, I still type `/plan <question>`
by hand.

**Opus for the thinking, Sonnet for the implementation (2026-11-04).**
- **Price:** I measured Opus 5.5 at exactly 2x Sonnet 5.5 on our Bedrock account: $0.193 vs
  $0.096 for the same prompt.
- **What we actually run:** October's `agi-dev` Claude usage was $1,703 on Opus and $24 on
  Sonnet. That's the whole team, and it's covered by AWS credits. So the planned split into
  an Opus plan and a Sonnet implementation from a self-contained spec almost never happened,
  and we paid for long self-contained specs without collecting the savings.
- **How:** `/implement` has `model: sonnet` in its frontmatter. A skill's model applies for
  the rest of the turn that invokes it ([docs](https://code.claude.com/docs/en/skills.md)),
  and `/implement` runs mostly as one long turn. Grilling and `/spec` stay on Opus.
- **Unverified:** once the background CI watch finishes, Claude may continue in a new turn,
  back on Opus. If Cost Explorer shows little Sonnet, that's why.
- **Costs:** each model has its own prompt cache, so the first Sonnet turn is uncached. And
  when implementation hits something the plan didn't foresee, Sonnet makes the call. Tests,
  CI and review on GitHub are the backstop.

**The handoff exception: `/spec --handoff`.** Use it when implementation should run as a
separate background session while I move on, for example
`claude --bg --model sonnet -n AGI-123 "implement docs/specs/agi-123-….md"`. That session
starts from nothing, so the spec has to stand alone. This is today's self-contained format,
kept for that case only.

**Check after two weeks:** the Opus/Sonnet split in Cost Explorer (`agi-dev`, October
baseline above). If Sonnet's share hasn't grown, the split still isn't happening.

### Choices inside this

- **My own `/grill-me` skill vs. installing Pocock's plugin.** **(done 2026-11-04: wrote my own, `skills/grill-me/SKILL.md`)** I'd write my own, about 20
  lines: his four sentences plus my existing question rules (blockers only,
  self-contained, a recommendation on every question). His plugin pulls in a whole skill
  family and a per-repo setup step I don't need.
- **Should `/spec` stay "self-contained for a fresh session"?** **(done 2026-11-04: a
  decision record by default, with `--handoff` for self-contained)** That rule is the main
  reason specs are long, since it has to restate everything the investigation learned. It
  existed so a cheaper model could implement from the spec alone; `/implement` running on
  Sonnet in the same session gets that split instead (see above). `/spec` also now builds
  from a confirmed `/grill-me` summary and sends anything not in it to Open Questions.
- **Plan file vs. `docs/specs/`.** Plan-mode plans aren't committed and have generated
  names; my specs are a committed record. Keep `docs/specs/` as the record and treat the
  plan as scratch. _Moot: plan mode left the ticket workflow on 2026-11-04._

## 4. Review on GitHub; let Claude work the comments

- **`/diff`** (in-session) shows uncommitted changes, per-turn views (T1, T2…), or the
  whole branch, cycled with `Ctrl+X B`. Fullscreen it's a live side panel, and `ask` on a
  file attaches that file's diff to my next prompt. **No line comments.** It's for glancing
  at the diff, not reviewing it.
- **GitHub PR review** is where line-by-line comments live, so I'd do the real review there.
- **Bare `/loop`** re-runs a default prompt in the session on a schedule Claude picks. Mine
  comes from `loop.md` (below) and tends the branch's PR: review comments, failed CI and merge
  conflicts. Loops expire after 7 days.
  [Docs](https://code.claude.com/docs/en/scheduled-tasks.md)
- **`/code-review <pr> --comment`** posts Claude's review as inline PR comments, so it can
  go first and I review its findings alongside the diff.
- **Agent view shows each session's PR** as a `#N` label on its row, so I find the session for a
  PR there. The session stays open until the PR merges, so I never need to resume one.
- **`/goal "<condition>"`** keeps a session working until an evaluator confirms the
  condition, for example `pnpm lint:full exits 0 and tests pass, or stop after 20 turns`.
  Good for the implement-until-green stretch. **(unverified: whether the evaluator works on
  Bedrock)**

**Claude commits, pushes and opens the PR; I review the finished PR (done 2026-11-04).**
Running `/implement <spec>` is how I approve a spec, and it ships it. It does the whole stretch:
1. Checks it's on the ticket's feature branch with a clean tree.
2. Implements the spec and nothing else.
3. Commits as it goes.
4. Runs `lint:full`, the tests and, for UI changes, `e2e` locally.
5. Pushes and runs `/pr-description --draft`.
6. Fixes CI until every check is green. A failure unrelated to the diff gets one rerun;
   it stops after three fix cycles.
7. Only then marks the PR ready.

A draft becoming ready is my signal that it's done. It's also when managed Code Review runs
on *Once after PR creation*, since that setting skips drafts. CI median is ~5 min, with the
slowest of the last 30 runs at 17 min, and 7 of those 30 needed a second attempt.

What changed:
- `skills/implement/SKILL.md` (new).
- `/pr-description` gained `--draft` and no longer says "never commit".
- `/spec` points to `/implement`.
- Memory `feedback_git_staging` now says I commit and push after spec approval.
- Guardrail: `hooks/git-guard.sh` is a `PreToolUse` hook on Bash. It blocks commits and pushes
  on `main`, any force push, and `--no-verify` / `commit -n`, ignoring anything inside quotes
  so commit messages can't trigger it. I tested it against 28 cases and live in this session.
  It reads the branch from `git -C <dir>` or the session's directory, not from a `cd` inside
  the command.

**After the PR:** I review on GitHub, then bare `/loop` in that session, which stays open in agent view until the
PR merges, works through my comments and CI. Optional extras: managed Code
Review or `/code-review --comment` before I look. `/goal` is an alternative to the skill's own
watch loop, but its evaluator is unverified on Bedrock.

**`loop.md` replaces the built-in maintenance prompt (done 2026-11-04).**
- **Why:** the built-in prompt runs "cleanup passes such as bug hunts or simplification" when
  nothing else is pending. On a PR waiting for my review, that's out-of-scope change.
- **What it does instead:** `claude/loop.md` in dotfiles, linked from `~/.claude/loop.md` and
  added to `install.sh`, tends the branch's PR and nothing else:
  1. Stop when the PR is merged or closed.
  2. Address each new review comment: commit, push, and **reply on the thread** with what
     changed, or with the answer to a question. If a comment asks for something outside the
     spec, or Claude disagrees, ask me instead.
  3. Fix red CI, rerunning a failure unrelated to the diff once.
  4. Merge `origin/main` on a conflict. Never rebase, which would need a blocked force push.
  5. Otherwise do nothing and wait longer.
- **Scope:** it only changes bare `/loop` (and `/loop 15m`). `/loop <prompt>` ignores it, and
  a project's own `.claude/loop.md` overrides it.

**A typical round.** PR #612 is ready with CI green.
1. I leave three comments on GitHub: "this should be a 400, not a 502", a rename, and "why
   not reuse `parseSearchError`?".
2. In agent view I attach to the row labelled `#612`, type `/loop`, and detach with `←`. The
   loop keeps running.
3. **Iteration 1:** Claude fixes the status code and the rename, commits, pushes, and replies
   on those two threads with the commit. It answers the question on its thread. CI starts,
   so it waits about 4 minutes.
4. **Iteration 2:** a Playwright test failed. If the diff caused it, Claude fixes it and
   pushes; if not, it reruns the job once. Once CI is green, it waits about 30 minutes.
5. I approve and merge. The next iteration sees the PR is merged, stops the loop, and
   reports. I delete the session from agent view with `Ctrl+X` twice.

**How it runs:**
- **Timing:** Claude picks the wait itself, from 1 minute to 1 hour, and prints each delay
  with its reason.
- **Stopping:** Esc stops it while it's waiting. Any loop expires after 7 days.
- **Pushing:** it only pushes because `/implement` already authorized that in the
  conversation.

**Managed GitHub Code Review works for us today.** We have a Team plan, and the service
doesn't care which provider the CLI uses. An org Owner turns it on. After that it reviews
every PR with several agents and posts inline comments; it never approves or blocks.
- Billing goes through usage credits charged to the org, separate from seat allowances, with
  a monthly spend limit at claude.ai/admin-settings/usage.
- **No published per-review price.** Cost scales with review level, PR size, the code around
  the change, and how many findings need verifying. The default setting, *After every push*,
  runs a review on every push, which multiplies the cost. Drafts and fork PRs are skipped
  automatically.
- **Data points.**
  - Official: Anthropic's only figure is the launch-era "generally average $15–25" per review
    ([blog](https://claude.com/blog/code-review), 2026-03-09). The Help Center still says
    so; the docs dropped it at GA (2026-10-15). GA added three review levels: Quick, Standard
    and Deep, described only as lowest, balanced and highest cost.
  - User reports are scarce. One small startup paid $8 for a few-hundred-line PR; one
    commenter paid $70 for a single PR, size not given. Nobody has published post-GA costs
    per level.
- **Our scale.** The monorepo opened ~165 human PRs in the last 30 days, 98 of them mine.
  At $15–25 each, one review per PR is **~$2,500–4,000 a month**. *After every push* would
  multiply that by the pushes per PR. Quick level is presumably cheaper but unpriced.
- **Compared with alternatives**, it's 10–20x per review:
  - Cursor Bugbot: ~$1–1.50 per review.
  - Copilot code review: ~$1.50 on Balanced, ~$10 on Max.
  - Greptile: $1–10.
  - CodeRabbit: $24–72 per seat per month, flat.
  - The cheapest Claude option: local `/code-review <pr> --comment`, which we already
    have, billed as ordinary Bedrock tokens.
- **Pilot first:**
  - Quick level, *Once after PR creation* (drafts are skipped, so the review runs when I
    mark a PR ready).
  - A few-hundred-dollar monthly cap.
  - After two weeks, read the per-repo **Average cost** column in Admin settings → Claude
    Code. That's the only reliable number.
  - GitHub issue
    [#39678](https://github.com/anthropics/claude-code/issues/39678) reports reviews
    skipped as "limit reached" at $0 spend on a Team plan, so watch for that.
- Unverified: whether it needs premium seats.
- [Docs](https://code.claude.com/docs/en/code-review.md),
  [costs](https://code.claude.com/docs/en/code-review-costs.md)

This would replace the optional `/code-review --comment` step, since Claude's review would
already be on the PR when I open it. It's the single best fit for "review line by line on
GitHub". Ultrareview and the other features that need a subscription are covered in
[§7](#7-bedrock-vs-the-team-plan).

## 5. Worktrees: an implementation detail

**Decision (2026-11-04): Claude owns the worktree.** Claude now pushes to GitHub and I review
on the PR, so I never `cd` into a worktree. Where it lives and what it's called stop
mattering, and I don't need the sibling `monorepo-<slug>` layout or the Linear branch names
that `/start-ticket` used to create.

**How it works.** I dispatch from the primary checkout. Before a background session's first
edit, Claude moves it into its own worktree under `.claude/worktrees/`, which is already
gitignored ([docs](https://code.claude.com/docs/en/agent-view.md#how-file-edits-are-isolated)).
- **When:** grilling only reads, so the worktree appears when `/spec` writes the spec.
- **Branch:** a generated `worktree-<name>`, created from `origin/main`.
- **Cleanup:** delete the session in agent view with `Ctrl+X` twice on its row, or with
  `Ctrl+X` on the *Completed* group header to clear every finished session at once. That
  removes its worktree too, including any uncommitted changes. Pushed commits don't block it;
  unpushed ones make it refuse once and name them. This replaces `git sweep` for these worktrees.
- **Built-in git behavior** for a worktree Claude created matches `/implement`: commit and
  push without asking, open a draft PR, never push to `main` or force-push.

**What the decision drops:**
- The `WorktreeCreate` / `WorktreeRemove` hooks I'd planned.
- The git half of `/start-ticket`.
- Spikes 4 and 5.

**Changes this needed (done 2026-11-04):**
- **`/start-ticket`:** keeps only its Linear half (read the ticket with images, check
  blockers, set In Progress, assign me), then hands over to `/grill-me`. No
  `git worktree add`. For that hand-off, `/grill-me` no longer sets
  `disable-model-invocation`; its description still limits it to explicit requests.
- **`/pr-description`:** takes the `[AGI-123]` title prefix from the ticket in the
  conversation or the spec's filename before falling back to the branch name, since
  `worktree-<name>` branches don't carry it. The title is also what links the PR in Linear.
- **`/implement`:**
  - Step 1 checks it's in a worktree of its own, not `main`. `git-guard.sh` reads the
    session's current directory, which follows Claude into the worktree.
  - It runs `pnpm install` first, because a fresh worktree has no `node_modules`.
  - It skips local `pnpm e2e`. Playwright's fixed ports (3000/8080) with
    `reuseExistingServer` mean that, in one worktree, it can test another session's servers
    and pass. CI's `e2e` job is the check.
- **Memory:** the notes on `/start-ticket` worktrees, local e2e, `git sweep`, the
  `origin/main` base and worktree naming now describe this flow.

**Remaining risk:** repo-wide tools might scan the nested `.claude/worktrees/` (Biome, knip,
`tsc`, Next.js watchers). That's spike 6.

## 6. Later: more parallelism

These matter once the basic loop works. Don't start here.

- **Dynamic workflows** (`ultracode:` in a prompt, `/workflows`). Claude writes a script
  that fans out subagents, each returning a schema-checked result. This fits the batch
  security triage that `/insights` flagged: verify each open Aikido/Trivy finding in
  parallel, then give me a ranked table before filing anything. Token-heavy; works on
  Bedrock. [Docs](https://code.claude.com/docs/en/workflows.md)
- **Agent teams** (experimental). Teammates in iTerm2 split panes with a shared task list.
  Token-heavy, and in-process teammates don't survive a resume. Skip for now.
- **Session-scoped cron / routines.** E.g. a morning session that reads the security report
  and dispatches tickets. Routines' Bedrock support is unverified.

**Know they exist:**
- `/btw` for side questions.
- `/doctor prompt-audit` flags outdated prompting patterns in skills; worth one run on
  `/spec`.
- `/skill-doctor`.
- Nested `.claude/skills` dirs that load only when working in that package.
- `claude respawn` restarts background sessions on a new Claude Code version.

## 7. Bedrock vs. the Team plan

Claude Code runs on Bedrock because the monorepo's checked-in `.envrc` sets
`CLAUDE_CODE_USE_BEDROCK=1`, `AWS_PROFILE=agi-dev` and `us.anthropic.*` model IDs for
everyone (AGI-595). Provider precedence puts cloud credentials first, so while that variable
is set, a claude.ai login is ignored.

**Need the CLI on the subscription** (not available on Bedrock):

| Feature | What it would give me |
| --- | --- |
| Ultrareview | Deep cloud review with verified findings; 3 free runs, then ~$5–25 each in usage credits |
| Remote Control | Drive a local session from claude.ai or my phone (Owner must enable on Team) |
| Cloud sessions (`--cloud`, `/teleport`) | Sessions running on Anthropic VMs, counted against plan usage |
| `/schedule` and routines | Cron or GitHub-triggered agents that run without my laptop; on Bedrock the command is hidden and the docs point to `/loop` |
| Channels | Push CI or chat events into a running session (Owner must enable) |

**Works regardless:** managed Code Review (§4), plus everything else in this doc.

### Options

**A. Stay on Bedrock (recommended for now).** Enable managed Code Review, which needs no
provider change, and use `/loop` where I'd have wanted routines. Inference stays in our AWS
account under the AWS agreement, which is presumably why AGI-595 chose it. Bedrock also
turns off telemetry, error reporting and `/feedback` uploads by default.

**B. A second config dir for occasional subscription use.** For example,
`alias claude-sub='env -u CLAUDE_CODE_USE_BEDROCK CLAUDE_CONFIG_DIR=~/.claude-sub claude'`,
for an ultrareview or Remote Control now and then. The separate config dir has its own login,
settings and history; I'd symlink `skills/` and `CLAUDE.md` into it. This sends code to
Anthropic's infrastructure rather than AWS, so it's a data-handling decision, not just a
convenience. Unverified: whether `env -u` is enough inside a direnv'd directory, since
direnv re-exports on `cd`. Check with `/status`.

**C. Move the team to the subscription.** This would unlock everything in the table and
probably avoid Bedrock's 503s. The cost is a team-wide `.envrc` change and new usage
limits: a per-seat allowance on rolling 5-hour and weekly windows, shared with claude.ai
chat, with overage billed in usage credits. It also reverses the data-path decision
AGI-595 made. Team is commercial terms (no training by default, 30-day retention), but
zero data retention is Enterprise-only. That's a call for the Part 500 / SOC 2 firm, not
something to change on my own.

## Rollout

Each phase is small and reversible, and I'd live with each for a few days before the next.

| Phase | Change | Done when |
| --- | --- | --- |
| 0 | Quick-win settings (§1) | Fewer classifier blocks; the next Bedrock outage falls back instead of going silent |
| 1 | iTerm2 integration + agent view, existing worktrees, no skill changes (§2) **(done 2026-11-04)** | A week without opening VS Code for Claude work |
| 2 | `/grill-me` skill (done 2026-11-04); `/spec` rewritten as a decision record with `--handoff` (done 2026-11-04); `/implement` on Sonnet (§3) (done 2026-11-04) | Next three specs arrive without trimming; Sonnet's share of Bedrock spend grows |
| 3 | `/implement` → draft PR → green CI → ready (done 2026-11-04); review on GitHub with `/loop` (§4) | One spec shipped by `/implement` to a green PR, reviewed on GitHub, and fixed by the loop |
| 4 | `defaultToAgentsView` so a bare `claude` opens agent view (§2); `/start-ticket` cut to its Linear half; `/pr-description` takes the ticket ID from the spec; `/implement` worktree check, `pnpm install`, no local e2e (§3, §5) **(done 2026-11-04)** | One `/start-ticket AGI-123` dispatched from agent view reaches a green, ready PR with no worktree commands from me |

## Verify first

Spikes to settle the **(unverified)** points, each a few minutes:

1. Do background sessions surface "needs input" in iTerm2, through Cockpit or Notification
   Center? (Phase 1)
2. Does `/grill-me` work in plan mode, i.e. is `AskUserQuestion` available there? _Resolved: moot. The skill asks its questions in plain text, so it does not depend on `AskUserQuestion`._ (Phase 2)
3. Does `/goal`'s evaluator run on Bedrock? (Phase 3)
4. Does `claude -w joshua/agi-1-test` with a `WorktreeCreate` hook get the name verbatim,
   slash included? _Resolved: moot. Claude names worktrees itself (§5)._
5. Can a skill's Bash tool launch `claude --bg …`? _Resolved: moot. I dispatch from agent
   view, and `/start-ticket` no longer launches a session (§5)._
6. Do Biome, knip, `tsc` and Next.js ignore `.claude/worktrees/`? Every background session
   now edits there (§5). (Phase 4)
8. Does a background session started in plan mode show its plan approval under *Needs input*,
   and does approving it from an attached session switch `opusplan` to Sonnet as it does in
   a foreground session? _Resolved: moot. Plan mode left the ticket workflow (§3)._
   Replaced by: does `/implement`'s `model: sonnet` cover the CI-fixing turns, or only the
   first one? Check the session's model use, or Cost Explorer. (Phase 3)
9. Does the session move into its worktree before `/spec` writes, so the spec lands on the
   PR branch rather than in the primary checkout? (Phase 4)
10. Does a background session see `.envrc`'s environment (Bedrock, AWS profile, app secrets)?
    It inherits the shell agent view started from, so start agent view in `~/git/monorepo`
    with direnv loaded. A test that can't find a secret points here. (Phase 4)
11. Do any unit tests use the shared local Postgres from `pnpm dev:infra`? If so, two
    sessions running them at once could collide. (Phase 4)
7. Does the org have a claude.ai Team or Enterprise plan? _Resolved: yes, Team. Managed
   Code Review is available (§4); the subscription-only features need option B or C in §7._

## Open questions

1. **How long should a spec be after grilling?** Option one: keep "self-contained for a
   fresh session". Specs stay long, but any session can pick one up. Option two: switch to
   a decision record of roughly 100 lines, which assumes the grilling session implements.
   *Recommendation:* the decision record, plus a `/spec --handoff` mode for the occasional
   ticket that another session picks up.
   _Resolved 2026-11-04: decision record by default, with `--handoff` for self-contained.
   The self-contained format existed so Sonnet could implement from the spec, but October
   spend was $1,703 Opus vs $24 Sonnet, so that rarely happened. `/implement` runs on
   Sonnet in the same session instead (§3)._
2. **Sibling vs. nested worktrees?** *Recommendation:* keep siblings via the hook (§5 C).
   Nested ones risk tooling surprises and gain nothing I need.
   _Resolved 2026-11-04: nested, wherever Claude puts them. I no longer interact with
   worktrees, so their location doesn't matter; the tooling risk is spike 6._
3. **Draft PRs earlier?** The review flow in §4 opens a draft PR as soon as tests pass, so I
   review on GitHub rather than locally. *Recommendation:* yes. The PR becomes the review
   surface and `/loop` works off it.
   _Resolved 2026-11-04: yes. `/implement` opens a draft and marks it ready when CI is
   green (§4)._
4. **Enable managed Code Review on the Team plan?** It's an Owner action that bills usage
   credits to the org, with a spend cap. At our volume it's likely **$2,500–4,000 a month**
   if every PR is reviewed, against ~$1 per review for competitors and plain Bedrock tokens
   for the local `/code-review --comment`. *Recommendation:* run the capped two-week pilot
   in §4 at Quick level. Then decide between keeping it on every ready-for-review PR,
   switching it to Manual (`@claude review` on PRs that warrant it), or dropping it for the
   local review.
5. **Bedrock or the subscription?** See §7. *Recommendation:* stay on Bedrock, and raise
   option C with the compliance firm only if a subscription-only feature turns out to be
   worth it.

## Typical workflow

How a ticket goes from now on.

1. **Open agent view:** type `claude` in `~/git/monorepo`.
2. **Dispatch the ticket:** `/start-ticket AGI-123`. It checks blockers, sets the ticket In
   Progress and assigned to me straight away, then goes into `/grill-me`.
3. **Get grilled:** answer the questions one at a time, often just "yes". This runs on Opus
   and changes no code; I can still ask for Linear writes, like filing a follow-up ticket.
   Agent view's *Needs input* group and the iTerm2 notification tell me when the next
   question is waiting, so I can work other tickets in between.
4. **Confirm the summary:** Claude summarizes what we decided, and I confirm it in
   conversation.
5. **Spec:** `/spec` writes the decision record, and Claude moves into its own worktree. I
   read it to check it matches what we decided. It should have no Open Questions beyond any I chose to leave open.
6. **Ship:** run `/implement`, which is my approval of the spec. Claude commits, opens a draft PR, and
   fixes CI until it's green, then marks the PR ready. I detach and move on.
7. **Review on GitHub:** when the PR is ready (with managed Code Review's comments, if the
   pilot is on), I review line by line and leave comments.
8. **Address feedback:** attach to the session from agent view (its row shows the PR's `#N`) and
   run bare `/loop`, then detach. It fixes what my comments ask for, replies on each thread,
   fixes CI, and stops itself once the PR merges. Repeat 7–8 until it's ready to merge.
9. **Merge and clean up:** merge on GitHub. In agent view, press `Ctrl+X` twice on the
   session's row, which deletes the session and its worktree. Or let finished sessions
   collect under *Completed* and clear them all at once with `Ctrl+X` on that group's header.

**Other sessions** (alarm triage, "could we…?" questions): dispatch the question from agent
view; it runs on Opus in auto mode. To make one read-only, prefix it with `/plan`, for
example `/plan why did the frontend-5xx alarm fire?`.
