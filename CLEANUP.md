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

- [ ] **tmux.** `tmux` is not installed, but `tmux.conf`, `bin/tmux.bash`, and the `t` / `tl`
      aliases remain. If you keep them, two latent bugs to fix first:
  - `tmux.conf:62` — `set -g status-utf8 on` was **removed in tmux 2.2** and errors on modern versions
  - `tmux.conf:65` — status line calls `loadavg`, which isn't installed
  - (`reattach-to-user-namespace`, used in `tmux.conf:10` and `bin/tmux.bash:12`, is also not
    installed — though both call sites already guard for its absence)

---

## 4. `claude/settings.json`

- [ ] **~70% duplication.** The same ~40-entry AWS allowlist block appears three times — bare,
      `--profile agi-prod`, `--profile agi-dev` — roughly 120 of 174 lines. Collapsible with
      wildcard patterns.

- [ ] **Review the permission posture** (deliberate choice, just worth a conscious look).
      `defaultMode: "acceptEdits"` combined with blanket `Edit` / `Write` and:
  - `Bash(sed*)` — matches `sed -i`, i.e. unprompted in-place file rewriting
  - `Bash(find:*)` — `find` supports `-delete` and `-exec`

  This applies globally, in every project you use Claude Code in.

---

## 5. Small stuff

- [ ] `.gitmodules` is empty (0 bytes) but tracked — delete it.
- [ ] `gitignore:3` still has `Replication/src/scripts/test.php`, inherited from Buck's 2013
      upstream commit. Not yours.
- [ ] `README.md` typo — "overwrte" → "overwrite".
- [ ] `bash_prompt:121` — `aws_role_name()` is defined at lines 9–16 but its `PS1` use is
      commented out. Intentional? Same for the commented-out hostname on lines 116–117.

---

## Appendix: verified environment facts

Recorded so these don't need re-deriving.

| Check | Result |
|---|---|
| Homebrew prefix | `/opt/homebrew` (Apple Silicon); `/usr/local` exists but has no `etc/` |
| Installed formulae (relevant) | `libpq`, `nvm`, `python@3.14` |
| Not installed | `tmux`, `gsed`, `mysql-client`, `postgresql@16`, `pnpm@9` (formula), `reattach-to-user-namespace`, `loadavg`, `cntlm` (`lein` / `go` also absent — both cleaned up in §3) |
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
