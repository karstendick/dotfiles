# Dotfiles cleanup backlog

Findings from a full read of the repo on 2026-08-17. Working checklist — tick items off as
they're done. Nothing here has been applied yet except where noted.

**Note:** line numbers below were accurate at the time of writing and will drift as edits land.
Re-grep rather than trusting them blindly.

---

## 1. Proxy-era residue

Background: `cntlm.conf` was a corporate NTLM proxy config for a former employer, committed
2018-07-23 in `cc8841b "proxy stuff"`. A later commit `82e64dd "cleanup old config"` removed most
of that era's references but missed several. The credentials in it were confirmed disabled.

- [x] **Delete `cntlm.conf` and its `install.sh` line** — done, staged but not yet committed.
      Also fixed the `ln: /usr/local/etc/cntlm.conf: No such file or directory` error on install,
      which was caused by `/usr/local/etc` not existing on Apple Silicon.

- [x] **Remove the `trusted-host` block from `pip.conf`** — done. `pip config list` now reports
      only `global.break-system-packages='true'`; TLS verification is restored.
      Created in `d956643 "make pip work on proxy"`, the **same day** as the cntlm commit. The
      original commit was exactly this block and nothing else:
      ```
      [global]
      trusted-host = pypi.python.org
                     pypi.org
                     files.pythonhosted.org
      ```
      `trusted-host` **disables TLS certificate verification** for those hosts. It existed to work
      around the corporate proxy's TLS interception. That proxy is gone, so this now weakens every
      `pip install` for no benefit.

      Keep `break-system-packages = true` — unrelated, added 2024-12-26 / 2025-10-06, deliberate.

- [x] **Drop `proxy-set` / `proxy-clear` from `bash_profile`** (was lines 43–61) — done.
      `bash -n` passes and a fresh login shell loads clean with no proxy vars set.
      They export `http_proxy=http://localhost:3333`; port 3333 was the `Listen 3333` value in the
      deleted cntlm config. Dead functions pointing at a proxy that no longer runs.

- [x] **No remaining hostname references.** Grepped the working tree for GSK / `corpnet2` /
      internal hosts and IPs — clean. Only `localhost:3333` above.

**Not doing:** history rewrite. The file was public for ~8 years; since the credentials are
disabled, rotating/rewriting adds nothing. `HEAD` going forward is clean.

---

## 2. Stale paths in `bash_profile`

All verified missing on this machine (Homebrew prefix is `/opt/homebrew`).

- [x] **Intel Homebrew leftovers** — both dead lines removed. Rather than just deleting the
      completion line, bash completion is now actually working:
  - Installed `bash-completion@2` (2.18.0).
  - Sourced from `$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh`, placed **after** the
    `brew shellenv` eval — the old line ran before it, so `$HOMEBREW_PREFIX` wasn't set yet.
  - Added Apple's `git-completion.bash` explicitly: git comes from Xcode, not Homebrew, so
    `bash-completion` can't auto-discover it. This was the one gap after install.
  - Verified: 153 completions registered; `git`, `gh`, `aws`, `brew`, `terraform`, `docker`,
    `nvm`, `ruff` all work. There were already 14 unused completion scripts sitting in
    `/opt/homebrew/etc/bash_completion.d`.

- [x] **Shell switch — done** (by you; needed a password). Login shell is now
      `/opt/homebrew/bin/bash`, bash 5.3.15 instead of Apple's 3.2.57. Verified in a clean
      `env -i` login shell: bash-completion 2.18.0 loads, 153 completions registered.
      Revert with `chsh -s /bin/bash` if ever needed.
  - Minor: `/etc/shells` ended up with `/opt/homebrew/bin/bash` listed twice (lines 12 and 13) —
    the append ran twice. Cosmetic; `chsh` doesn't care. Tidy with `sudo sed -i '' '13d' /etc/shells`.

- [x] **Removed `BASH_SILENCE_DEPRECATION_WARNING=1`** — done. It only silenced bash 3.2's zsh
      nag, which can't fire under 5.3. (If you ever `chsh` back to `/bin/bash`, the nag returns;
      re-add the line then.)

- [x] **GNU utils — decided: leave as-is.** The deleted `gnu-sed` line's comment was "use GNU
      versions of utilities". Current state stays: `coreutils` installed, providing GNU tools as
      `g`-prefixed commands (`gls`, `gdate`, `greadlink`), and **no** `gnubin` on `PATH`.
      Rationale: adding `$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin` to `PATH` would shadow
      100+ system binaries (`ls`, `cp`, `rm`, `ln`, `date`, `stat`, `install`, …), which risks
      scripts silently depending on GNU behavior and then breaking on stock macOS. The `g`-prefix
      approach gives GNU when explicitly asked for, with nothing shadowed.
      If this ever comes up again: `brew install gnu-sed grep` for `gsed`/`ggrep` (the two where
      BSD diverges most — `sed -i` needs an empty arg, no `grep -P`), and prefer aliases in
      `bash_aliases` over a `PATH` change, since aliases don't affect scripts.

- [x] **PATH entries for formulae that aren't installed — all removed.** Six lines gone, four
      dead paths (two were duplicated). Installed formulae are only `libpq`, `nvm`, `python@3.14`.
  - `mysql-client@8.0` (×2) — not used in current development
  - `pnpm@9` (×2) — real `pnpm` comes from nvm/node
  - `postgresql@16` — real `psql` comes from `libpq`, already on `PATH` one line below
  - `python@3.12` — superseded by `python@3.14`

  Also dropped the now-stale comment "To put brew's python and pnpm on the `$PATH`" and added one
  noting that `libpq` needs an explicit path because it's keg-only.

  Verified in a clean `env -i` login shell — everything real still resolves, 153 completions:
  `psql`/`pg_dump` → `libpq`, `pnpm`/`node` → nvm (node v22.22.2), `python3`/`pip3` → 3.14.

  Note: unversioned `python` and `pip` are not on `PATH`. That was already true before this
  cleanup (the `python@3.12` path was dead), so nothing regressed. If you want them, add
  `$HOMEBREW_PREFIX/opt/python@3.14/libexec/bin` — that directory does exist.

---

## 3. Possibly-unused toolchains — judgment calls

These are "do you still use this?" questions, not defects. Left alone pending a decision.

- [x] **Go — removed.** No longer writing Go. Dropped the `## Add go stuff` block from
      `bash_profile` (`GOPATH="$HOME/go"`, `GOBIN`, and `$GOBIN` on `PATH`). `~/go` didn't exist,
      so this was a fourth dead `PATH` entry. `go` was confirmed not installed and not a Homebrew
      formula.

- [x] **Clojure — removed.** No longer writing Clojure; `lein` was not installed. Removed:
  - `lein/profiles.clj` (`git rm`) — the whole `lein/` directory is gone. Pinned `lein-pprint`,
    `lein-kibit`, `eastwood 0.2.0`, `cider-nrepl 0.8.1`, `slamhound 1.3.1`, `midje 1.7.0`,
    `humane-test-output 0.8.1` — all 2014–15 vintage.
  - `midje.clj` (`git rm`) — one line: `(change-defaults :print-level :print-facts)`.
  - Three `install.sh` lines: `mymkdir ~/.lein`, and the two `symlink` lines for the above.
  - The symlinks those had created, which would otherwise dangle: `~/.midje.clj` and
    `~/.lein/profiles.clj`. `~/.lein` was then empty, so it's removed too.

  Verified: `bash -n` passes on `bash_profile` and `install.sh`; a repo-wide grep for
  `gopath|gobin|golang|clojure|lein|midje|nrepl|cider|eastwood|slamhound` returns nothing outside
  this file; `./install.sh` runs clean (exit 0, no errors); a clean `env -i` login shell has
  `GOPATH`/`GOBIN` unset, 153 completions, and **no** nonexistent `PATH` entries from this repo —
  the only ones left are Apple's own `cryptexd` bootstrap paths.

- [x] **tmux — keeping it; installed and config modernized.** `brew install tmux` → 3.7b. The
      config dated from tmux 1.x and had accumulated five problems, all now fixed:
  - **`status-utf8` removed.** `set -g status-utf8 on` was deleted from tmux in 2.2 and errors on
    load. UTF-8 is unconditional now.
  - **`loadavg` replaced.** The status line called `#(loadavg)`, a command that doesn't exist here
    and isn't in Homebrew. Now `#(uptime | sed 's/.*load averages*: //')` — the `s*` makes it match
    both macOS ("load averages:") and Linux ("load average:").
  - **`reattach-to-user-namespace` dropped** from `tmux.conf` and `bin/tmux.bash`. tmux has handled
    pasteboard access natively since 2.6 (2017). Note `bind y` called it **unguarded**, so
    prefix-y would have silently failed to copy; it's now a plain `pbcopy` pipe.
  - **`default-command` removed entirely, not just unwrapped.** Setting it at all makes tmux run a
    **non-login** shell, which skips `~/.bash_profile` — no aliases, no completions in panes.
    Unset means tmux runs `$SHELL` as a login shell. Same fix applied in `bin/tmux.bash`, which was
    both passing it to `new-session` and re-setting it globally.
  - **Keybinding conflict fixed.** `bind ] send-prefix` (line 7) was overridden by
    `bind ] paste-buffer` (line 34), so send-prefix didn't work at all — you couldn't type a
    literal `C-]`. Moved to `bind a send-prefix`, matching screen's `C-a a`. This was a
    long-standing bug, unrelated to tmux versions.
  - Also modernized `default-terminal` from `screen-256color` to `tmux-256color` (better color and
    italics support; verified present in terminfo).

  Verified by starting a throwaway tmux server on its own socket with this config: loads with
  **zero errors**, `default-terminal` resolves to `tmux-256color`, bindings are as intended
  (`a` → send-prefix, `]` → paste-buffer, `C-]` → last-window), and a pane shell reports
  `login_shell` **yes** with `alias t` present — i.e. `bash_profile` is being sourced.

  Not verified mechanically: the rendered load average in the status line. tmux only runs `#()`
  jobs for an attached client, and a detached test server returns empty even for `#(echo HELLO)`,
  so this harness can't exercise it. The underlying pipeline was checked directly —
  `sh -c "uptime | sed 's/.*load averages*: //'"` → `4.05 4.58 4.47`. Worth an eyeball next time
  you start a session.

  No `install.sh` change needed — it already links `tmux.conf` and `bin/tmux.bash`.

---

## 4. `claude/settings.json`

- [x] **AWS duplication collapsed — 118 lines → 45, file 175 → 101, allow entries 166 → 93.**
      The same 39 read-only operations were written out three times (bare, `--profile agi-prod`,
      `--profile agi-dev`), plus `aws configure list-profiles` in the bare block only.

      Now two patterns per service+verb-family — a bare one and a `--profile *` twin:

      ```json
      "Bash(aws ecs describe-*)",
      "Bash(aws --profile * ecs describe-*)",
      ```

      **Services stay explicitly enumerated on purpose.** The tempting further collapse to six
      entries (`Bash(aws * describe-*)`, `list-*`, `get-*`, ± profile) was rejected: it would reach
      services never listed, where "read-only" stops meaning "harmless" —
      `aws secretsmanager get-secret-value`, `aws ssm get-parameter --with-decryption`,
      `aws iam list-access-keys` all hand over credential material, and unprompted under
      `agi-prod`. The verbosity was doing real work as a service allowlist.

      Uniform trailing-`*` glob form, no `:*`, throughout the block. The first attempt mixed the
      two — `Bash(aws --profile * logs tail:*)` — which under prefix semantics never matches
      `agi-prod`, silently dropping 12 operations. Caught by a coverage check that replayed all 118
      old entries as representative commands against the 45 new patterns and asserted every one
      still matched; it also asserted no non-AWS entry moved. Verified after writing: valid JSON,
      `defaultMode` intact, `~/.claude/settings.json` resolving to the edited file, and a diff
      confirming the only non-AWS change is the typo below.

      The `--profile agi-dev` block was redundant in the common case anyway —
      [`bash_profile:79`](bash_profile) sets `export AWS_PROFILE=agi-dev` — but `--profile *`
      keeps it working when a project `.envrc` overrides `AWS_PROFILE` under direnv.

- [x] **Typo fixed:** `Bash(gh api repos/AGIHoldings/monorepo/actions/ *)` had a stray space after
      `actions/`, so it matched nothing real (`gh api repos/.../actions/runs` has no space there).
      Now `actions/*`.

- [x] **Permission posture — reviewed and kept as-is.** `defaultMode: "acceptEdits"` with blanket
      `Edit`/`Write`, `Bash(sed*)` (matches `sed -i`), `Bash(find:*)` (`find` supports `-delete`
      and `-exec`), `mcp__linear-server__*` (includes `save_issue`, `delete_comment`, `merge_diff`
      — writes to a shared team workspace), and `Bash(gh pr edit:*)` (mutates PRs on GitHub). All
      global, in every project. Deliberate and comfortable; not revisiting. There is no `deny` or
      `ask` list.

---

## 5. Small stuff

- [x] **`.gitmodules` deleted** (`git rm`). It was the empty blob `e69de29` — 0 bytes but tracked,
      so functionally inert: no gitlink entries (mode `160000`) in the index, `git submodule status`
      silent, no `submodule.*` keys in `.git/config`.
      Origin: added 2013-06-09 in Buck's `d0a03a4 "vim-fish and config.fish"` with 99 bytes
      declaring `vim/bundle/fish` → `aliva/vim-fish`, the pathogen-era convention of one git
      submodule per Vim plugin. This repo had four over its life (`fish`, `markdown`, `MatchTag`,
      `nginx-vim-syntax`). Your `72142d9 "removed tons of unused files"` (2016-03-02) stripped the
      3 lines of content but left the file tracked, and it sat empty for ten years.
- [x] `gitignore:3` still has `Replication/src/scripts/test.php`, inherited from Buck's 2013
      upstream commit. Not yours.
- [x] `README.md` typo fixed — "overwrte" → "overwrite" (line 20).
- [x] **`bash_prompt` dead prompt segments removed — 17 lines.** Both halves were "defined but its
      `PS1` line is commented out", so neither had rendered in years.
  - `aws_role_name()` (8 lines) plus its commented `PS1` line — removed by you. It used
    `tput setaf 1` directly rather than the colour palette, so it had no coupling to anything.
  - The SSH hostname (8 lines): the `hostStyle` if/else keyed on `SSH_TTY`, plus the commented
    `PS1` lines for `at` and `\h`. `hostStyle` was assigned in both branches and referenced
    nowhere live. Removed rather than restored — no longer ssh'ing into servers, so the
    "am I on a remote box?" cue isn't needed.

  Note the `at` separator was **also** commented out; had it been left live the prompt would have
  read `joshua at  in ~/dir` with a dangling "at".

  Verified: no `aws_role_name`/`AWS_ROLE_NAME`/`hostStyle`/`SSH_TTY` left in the repo; `bash -n`
  passes; sourcing with `SSH_TTY` set still succeeds; and rendered in a clean `env -i` shell the
  prompt is unchanged — `joshua in ~/git/dotfiles on master [+!]`, `PS2` (`→`) intact. Palette
  check: `red` down to `userStyle`, `yellow` to `PS2`, `bold` to the leading newline — nothing
  orphaned. `black`, `cyan`, `purple` are unused but already were.

- [x] **`prompt_git` shellcheck warnings fixed** — SC2046 at `bash_prompt:14`, SC2091 at 23, 28, 38.
      Four conditions wrapped their `git` call in a command substitution:

      ```bash
      if [ $(git rev-parse --is-inside-work-tree &>/dev/null; echo "${?}") == '0' ]; then
      if ! $(git diff --quiet --ignore-submodules --cached); then
      if ! $(git diff-files --quiet --ignore-submodules --); then
      if $(git rev-parse --verify refs/stash &>/dev/null); then
      ```

      Now each tests the command directly (`if ! git diff --quiet ...; then`).

      **These were not broken.** First read suggested "runs the command's output, works by
      accident" — wrong. When a command substitution expands to no words, bash uses *the
      substitution's* exit status; verified with `f() { return 1; }; if ! $(f); then ...`, which
      does enter the branch. Since `--quiet` guarantees no output, the old code was correct, just
      relying on an obscure rule. Had output ever appeared it would have been executed as a
      command — noisily (`command not found`), not silently.

      So this is a readability/lint fix, not a bug fix. Verified as a **behaviour-preserving**
      refactor by diffing old vs. new `prompt_git` output across ten synthetic repos — not a repo,
      clean, staged (`+`), unstaged (`!`), untracked (`?`), stashed (`$`), all four combined,
      detached HEAD (short SHA), a repo with no commits, and cwd inside `.git`. **All ten
      byte-identical.** `shellcheck` now reports nothing for `prompt_git`.

- [x] `shellcheck` SC2034 on `black`, `purple` (`bash_prompt:111,116`) — defined but never
      used. Deliberately kept as a full palette; noted so the warnings aren't mistaken for new.
      (`cyan` was on this list until the ahead/behind segment in §7 started using it.)

---

## 6. Brewfile — package installs are now version-controlled

Added 2026-08-17. Closes the biggest gap in the "clone and be productive" story: `install.sh` gave
you config but none of the tools it points at, and several dotfiles hard-depend on brew packages
(`bash_profile` sources `bash-completion@2` and references `libpq`/`nvm`; `tmux.conf` needs tmux).

- [x] **`Brewfile` at repo root**, generated with `brew bundle dump`. 16 formulae, 5 casks, 1 tap,
      11 VS Code extensions, no npm globals (see the Node item below). It records only packages
      installed **on request**, not all ~90 including dependencies, so deps resolve fresh on a new
      machine instead of being pinned. Kept **byte-identical to a fresh dump** — no hand-edited
      lines — so regenerating it can't silently lose anything.

- [x] **`install.sh --brew`** bootstraps a new machine before symlinking: `brew bundle install`,
      then Node via nvm and the pnpm shim via corepack. Opt-in on purpose — bare `./install.sh`
      stays fast, offline and idempotent. Falls back to `/opt/homebrew/bin/brew` when brew isn't on
      `PATH` (the usual case in a non-login shell on a fresh machine), and errors out clearly if
      Homebrew is absent. Unknown flags print usage and exit 1 rather than being silently ignored.

- [x] **Node / TypeScript, via corepack rather than brew or npm.** The chain is Homebrew → `nvm` →
      `node` → `corepack` → `pnpm`. The load-bearing detail: **`pnpm` is a corepack shim**
      (`bin/pnpm` → `corepack/dist/pnpm.js`), and corepack reads each project's `packageManager`
      field and fetches that exact version — the monorepo pins `pnpm@11.15.1` and that's precisely
      what was installed. So:
  - **Not** `brew install pnpm` (would pin 11.22.0 globally and ignore those fields).
  - **Not** a global `npm i -g pnpm` (tied to one Node version, breaks on `nvm use`).
  - Removing corepack would remove pnpm — it isn't dead weight despite never being used directly.
  - `yarn@1.22.22` **was** a real npm global and genuinely unused: `npm uninstall -g yarn`.
    Verified pnpm still resolves afterwards.
  - `NODE_VERSION=22` at the top of `install.sh` is the version `--brew` installs; projects can
    still override with their own `.nvmrc`.
  - TypeScript stays a per-project devDependency (`pnpm exec tsc`), matching what the
    `claude/settings.json` permissions already assume. Nothing global.

- [x] **Global npm packages excluded from the `Brewfile` permanently.** They install into whichever
      Node version nvm has active, so they aren't part of brew's state — and they can't install on a
      fresh machine, where `brew bundle install` runs before any Node exists. `bash_profile` now
      exports `HOMEBREW_BUNDLE_DUMP_NO_NPM=1`, so a plain `brew bundle dump --force` excludes them
      with no flag to remember. Verified: a clean login shell dump produces 0 `npm` lines.

- [x] **README** gained "New machine", "Node and TypeScript", and "Brewfile" sections, plus the one
      step that still isn't automated: the `chsh` to Homebrew bash, which needs a password.

- [x] **VS Code is now brew-managed — done** (by you, from Terminal.app, since it needed VS Code
      quit and couldn't be done from a session running inside it):

      ```bash
      brew uninstall --cask visual-studio-code
      brew install --cask visual-studio-code
      ```

      Verified afterwards: `/Applications/Visual Studio Code.app` is 1.133.0 matching the cask
      (was the self-installed 1.128.0), all 11 extensions intact, and
      `brew bundle check --no-upgrade` reports the Brewfile fully satisfied.

      This also let the hand-added comment come out of the `Brewfile`, which is now **byte-identical
      to a fresh `brew bundle dump`** — no hand edits, so regenerating it can't silently lose
      anything.

      Why it was needed: an interrupted `brew bundle install` (see below) staged cask 1.133.0 into
      the Caskroom and wrote a receipt, but never moved it into `/Applications`, so brew believed it
      managed VS Code while the app on disk wasn't brew's copy.

**Incident note, for the record.** While testing the `--brew` flag with a stubbed `brew`, one test
case ran under `env -i` with a minimal `PATH` — precisely the condition that triggers the script's
`/opt/homebrew/bin/brew` fallback — so it invoked the **real** `brew bundle install` for ~2 minutes
before being killed. Effects: ~17 formulae upgraded and their new deps pulled in (78 → 105
formulae; outdated 19 → 2), plus the half-registered VS Code cask above. Checked afterwards: no
half-installed kegs, all 15 home symlinks intact, and `tmux`/`git`/`aws`/`gh`/`jq`/`terraform`/
`emacs`/`psql`/`ruff` all working. `fontconfig` and `unbound` were left one version behind by the
interruption — deliberately not chased, they're pure dependencies.

Useful commands:

| Task | Command |
|---|---|
| Restore packages on a new machine | `./install.sh --brew` |
| Refresh the snapshot after installing something | `brew bundle dump --force` |
| See what's genuinely missing | `brew bundle check --verbose --no-upgrade` |
| Install without upgrading existing packages | `brew bundle install --no-upgrade` |

`brew bundle check` without `--no-upgrade` reports every installed-but-**outdated** package as
unsatisfied, which buries the genuinely missing ones — 23 lines of noise vs. 1 real finding when
tested here. Avoid `brew bundle cleanup --force`: it uninstalls anything not in the `Brewfile`.

---

## 7. PS1 — additional segments

Added 2026-08-18, from a "what else would be useful in the prompt?" pass. The prompt is otherwise
liked as-is; these are optional additions, not defects. Current shape:

```
joshua in ~/git/dotfiles on master [!]
$
```

- [x] **Exit status of the last command — done.** Shows ` ✘42` at the end of the info line only
      when the last command failed, in `red`, gone again on the next success. Replaces manually
      running `echo $?`.

      Two non-obvious details, both silent failures rather than errors if got wrong:
  - **`$?` cannot be read directly in PS1.** The `$(prompt_git ...)` substitution expands first and
    overwrites `$?` with its own status, which is always 0. Hence `prompt_save_status` in
    `PROMPT_COMMAND`, which snapshots it into `lastExitStatus` before PS1 is expanded. A segment
    placed *before* `$(prompt_git ...)` could read `$?` directly, but then it renders mid-line
    (`~/git/dotfiles✘1 on master`), so the saved-variable approach is what allows end-of-line
    placement.
  - **The double-registration guard is load-bearing.** Without it, re-sourcing `~/.bash_profile`
    after editing dotfiles leaves `PROMPT_COMMAND=prompt_save_status;prompt_save_status`, and the
    second copy reads the *first copy's* status — always 0 — so no failure would ever display
    again. Same idiom as the direnv guard at `bash_profile:67`.

      Depends on [`bash_profile:65`](bash_profile) doing `return $previous_exit_status`: the chain
      resolves to `_direnv_hook;prompt_save_status`, so the real status only survives because that
      hook preserves it. A future `PROMPT_COMMAND` entry prepended ahead of this one that *isn't*
      careful would make the prompt show that entry's status instead.

      Verified in real interactive shells (not simulated PS1 expansion), with both a bare
      `bash_prompt` and the full `bash_profile`: `true` → nothing, `false` → `✘1`, `true` after a
      failure → nothing (doesn't go stale), `(exit 42)` → `✘42`, SIGINT → `✘130`; correct spacing
      outside a git repo; the **success-case prompt is byte-identical** to the pre-change version
      (same md5 of an `od -c` dump), so nothing shifts when commands succeed.

      Note `✘130` appears on every Ctrl-C, e.g. killing a dev server. Accurate but arguably noise —
      suppress 130 specifically if it grates.

### Not done — candidates, cheapest first

- [ ] **`$AWS_PROFILE`.** Free: a plain env-var expansion, no subprocess. Worth it because
      [`bash_profile:79`](bash_profile) hard-exports `agi-dev` *and* direnv is in `PROMPT_COMMAND`,
      so a project `.envrc` can silently repoint the shell at another account. Getting `agi-prod`
      wrong is the expensive mistake this would prevent.

      **This is not what was deleted in §5.** That segment read `AWS_ROLE_NAME` (a 2016 assume-role
      workflow, variable now unset everywhere) and was written `PS1+=" $(aws_role_name)"` —
      unescaped, so it evaluated **once at shell startup** and never updated. It also emitted raw
      `tput` escapes outside `\[ \]`. A fresh `$AWS_PROFILE` segment is a different thing.

- [ ] **Background jobs and/or a timestamp.** `\j` and `\D{%H:%M}` — bash prompt escapes, zero
      subprocess, no helper function. The timestamp earns its keep when reconstructing from
      scrollback what was run when; `\j` matters if suspended jobs get forgotten.

- [ ] **Active Node version, when a `.nvmrc` is nearby.** Verified `$NVM_BIN` is exported and
      contains the version (`/Users/joshua/.nvm/versions/node/v22.22.2/bin`), so this is a parameter
      expansion — **no `node -v` subprocess**. Relevant with per-project pins; and version drift
      between shells is invisible today — while checking this, the session shell had v22.22.2 while
      a fresh login shell had v22.23.2.

### Done since writing this list

- [x] **Duration of the last command, when it's slow — done.** Renders `on main ↑3 [+!?] 1.3s ✘1`:
      the elapsed time in `yellow`, before the exit status so the failure marker stays rightmost.
      Threshold is `PROMPT_DURATION_THRESHOLD_MS` at the top of [`bash_prompt`](bash_prompt),
      defaulting to 1000 — low enough that most builds, test runs and `git push`es report a time.

      Formatting is compound units, truncated rather than rounded so the prompt never claims more
      time than the command took: `1.4s` / `9.9s` below 10 s, `12s` / `59s` to a minute, `1m30s` /
      `12m05s` to an hour, then `1h02m` / `13h45m` with hours unbounded (`36h00m`, no day unit).

      Implementation notes:
  - **`PS0`, not a `DEBUG` trap.** This was scoped above as needing a `DEBUG` trap; it doesn't. `PS0`
    is expanded after a command is read and before it runs — a preexec hook with no subprocess, and
    one nothing else competes for (VS Code's shell integration has no `PS0` reference at all).
  - **A `DEBUG` trap actively does not work here.** VS Code's shell integration claims the trap, and
    its branch for chaining a pre-existing one never fires for us: it reads the trap from inside
    `__vsc_get_trap()`, and **a `DEBUG` trap is invisible from inside a function unless `functrace`
    is on**. Verified — a trap installed in `bash_prompt` was silently replaced by
    `__vsc_preexec_only "$_"` and durations stopped appearing in VS Code terminals.
  - **`set -T` would fix that and isn't worth it.** With `functrace` on, VS Code does wrap ours
    (`__vsc_preexec_all`) and timing survives — but the trap then dispatches on every command inside
    every function. Measured **~6x slower** on function-heavy work (1.9 ms → 13 ms per 400 calls), a
    tax paid by bash-completion, git-completion and nvm for a cosmetic segment.
  - **`PS0` output is printed, so the stamp hides in an array subscript.**
    `${promptTimerVoid[$((promptTimerStart=${EPOCHREALTIME/./}))]}` — `promptTimerVoid` is never
    assigned, so the expansion runs the arithmetic and yields nothing. Parameter and arithmetic
    expansion in `PS0` happen in the *current* shell, so the assignment persists; a command
    substitution would have forked and lost it.
  - **`$EPOCHREALTIME` with the decimal point deleted is plain microseconds** — bash has no floating
    point, so all the maths is integer. `$SECONDS`/`$EPOCHSECONDS` are too coarse: at a 1 s
    threshold a fast command straddling a second tick would false-positive. `date +%s%N` is out —
    BSD `date` has no `%N`.
  - **No stale duration on an empty line.** `prompt_timer_stop` unsets the stamp after each prompt
    and only `PS0` re-stamps it, so pressing Enter with no command reports nothing. This needed a
    first-stamp-wins guard under the `DEBUG` design and needs nothing under `PS0`.

      Verified in both a plain login shell and one with VS Code's shell integration sourced:
      `sleep 0.3` silent, `sleep 1.4` → `1.4s`, repeated empty Enters silent, `sleep 1.2; false` →
      `1.2s ✘1`, comment-only lines silent, a `\`-continued line timed once for the whole line, all
      four compound rungs (`1m30s`, `12m05s`, `1h02m`, `13h45m`), and the threshold suppressing
      1.5 s at 5000 while showing 0.4 s at 100. Fast commands — prompt *and* command output — are
      **byte-identical** to before the change.

      Cost: 19 µs per prompt below the threshold, 538 µs when the segment renders (one fork to
      format), against `prompt_git`'s ~93 ms. Noise.

- [x] **Ahead/behind upstream — done.** Renders `on master ↑1↓2 [!]`: `↑n` for unpushed commits,
      `↓n` for unpulled ones, each shown only when non-zero, in `cyan` to separate them from the
      `blue` `[+!?$]` flags. Fills the gap that `[+!?$]` deliberately left — it describes the
      working tree and says nothing about the remote, so "needs pushing" wasn't visible.

      Lives inside `prompt_git`, in the same `is-inside-git-dir == false` block as the dirty checks,
      so the deliberately-lean prompt when cwd is inside `.git` is unchanged.

      Implementation notes:
  - **One `git` call covers both directions.** `git rev-list --count --left-right '@{upstream}...HEAD'`
    prints `<behind>\t<ahead>` — verified that **left is behind** (commits only the upstream has),
    cross-checked against `git status -sb` reporting `[ahead 2]`.
  - **The no-upstream guard is the `if` itself.** `@{upstream}` makes `rev-list` exit 128 with no
    output on a branch that isn't tracking anything, and also on a detached HEAD, so both fall
    through to an empty segment with no special-casing.
  - **The colour is folded into the value** (`u=" ${cyan}${u}"`), not emitted inline in the `echo`.
    That keeps the output *byte-identical* to before when a branch is in sync — otherwise a stray
    `${cyan}` would be written on every prompt in every repo.

      Verified across ten scenarios: in sync (nothing), 2 ahead (`↑2`), 2 behind (`↓2`), 1 ahead +
      2 behind (`↑1↓2`), that plus a dirty tree (`↑1↓2 [!]`), no-upstream branch, detached HEAD, cwd
      inside `.git`, a repo with no commits, and not-a-repo. The four no-divergence cases are
      **byte-identical** to the previous version. Also confirmed the arrows render `cyan`
      (`38;5;37`) followed by `blue` for the flags, and that the segment coexists with the exit
      status (`on master ↑1 [$] ✘1`).

      Cost: ~110 ms per render in `~/git/monorepo`, against a ~119 ms baseline — the extra call is
      ~9 ms, i.e. inside the noise.

### Rejected, so they don't get re-proposed

- **In-progress rebase / merge state.** Verified as a genuine blind spot: mid-conflicted-rebase the
  prompt renders `on 02b5113 [+!]` while git reports `## HEAD (no branch)` / `UU f`.
  `symbolic-ref` fails on detached HEAD, so it falls through to the short SHA — indistinguishable
  from a deliberate `git checkout <sha>`, and the `[+!]` reads as ordinary dirt. Detectable with no
  subprocess via `.git/rebase-merge`, `.git/rebase-apply`, `.git/MERGE_HEAD`,
  `.git/CHERRY_PICK_HEAD`, with a `2/5` step counter from `rebase-merge/msgnum` and `end`.
  **Declined:** merge conflicts are handled through Claude Code now, so the prompt cue has no
  audience.
- **Kubernetes context.** Deployment is ECS; no `kubectl` in the `Brewfile`.
- **A direnv-active indicator.** direnv already announces itself on stderr when it loads.

### Prompt mechanics worth not re-deriving

- **`\[ \]` is processed by PS1 expansion only** — *not* inside the output of a command substitution,
  nor inside a variable's value. So `prompt_git` and `prompt_exit_status` emit raw, unwrapped colour
  escapes.
- **That's safe here only because both live on line 1.** readline measures just the portion of a
  multi-line prompt after the final newline, so unwrapped escapes before the `\n` can't corrupt
  wrap width. Anything added to **line 2**, before the `$`, must instead wrap its colour in `\[ \]`
  in PS1 itself and have the helper emit plain text — otherwise long command lines wrap wrong.
- **Render cost budget.** `prompt_git` measured at ~119 ms per render in `~/git/monorepo`
  (655 tracked files), of which `git update-index --really-refresh` is only 14 ms. Room for another
  git call or two before it would be noticeable.

---

## Appendix: verified environment facts

Recorded so these don't need re-deriving.

| Check | Result |
|---|---|
| Homebrew prefix | `/opt/homebrew` (Apple Silicon); `/usr/local` exists but has no `etc/` |
| Installed formulae (relevant) | `libpq`, `nvm`, `python@3.14` |
| Not installed | `gsed`, `mysql-client`, `postgresql@16`, `pnpm@9` (formula), `reattach-to-user-namespace`, `loadavg`, `cntlm` (`lein` / `go` also absent — both cleaned up in §3) |
| Installed since | `tmux` 3.7b, `bash-completion@2` 2.18.0 |
| Present | `emacs`, `direnv`, `terraform`, `pnpm` (via nvm/node), `psql` (via `libpq`), `python3` (3.14) |
| Repo remote | `github.com/karstendick/dotfiles` — **public**, fork |
| Credential scan | No tokens/keys/passwords in `claude/` |

### Claude Code symlinks — all confirmed working

```
~/.claude/settings.json -> dotfiles/claude/settings.json
~/.claude/CLAUDE.md     -> dotfiles/claude/CLAUDE.md
~/.claude/commands      -> dotfiles/claude/commands
~/.claude/skills        -> dotfiles/claude/skills
```

Directory symlinks for `commands` / `skills` mean new skills added from any session land in the
repo automatically — no copy step, so no drift. `.claude/settings.local.json` is untracked and
ignored (needed `git rm --cached`; gitignore alone has no effect on already-tracked files).
