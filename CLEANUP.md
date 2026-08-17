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

- [ ] **Finish the shell switch — needs your password, so not done.** Completion requires
      bash >= 4.1 and your login shell is still Apple's `/bin/bash` 3.2.57, so the new config is
      currently a no-op at login. Two commands:
      ```bash
      sudo sh -c 'echo /opt/homebrew/bin/bash >> /etc/shells'
      chsh -s /opt/homebrew/bin/bash
      ```
      Then open a new terminal. Revert with `chsh -s /bin/bash`. `bash_profile` was verified to
      load cleanly under 5.3 (`bash -n` passes, `bash -li` runs clean), so login won't break.

- [ ] **After the switch:** `BASH_SILENCE_DEPRECATION_WARNING=1` becomes unnecessary — it only
      silences bash 3.2's zsh nag. Left in place for now so reverting stays clean.

- [ ] **Optional — GNU utils.** The deleted `gnu-sed` line's comment was "use GNU versions of
      utilities". `gnu-sed` isn't installed, but `coreutils` **is**, providing GNU `ls`/`cat`/etc.
      as `g`-prefixed commands. For unprefixed versions, add
      `$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin` to `PATH`. For GNU `sed` specifically you'd
      need `brew install gnu-sed`.

- [ ] **PATH entries for formulae that aren't installed.** Installed formulae are only
      `libpq`, `nvm`, `python@3.14`:
  - `mysql-client@8.0` — lines 100 **and** 106 (duplicated)
  - `pnpm@9` — lines 103 **and** 107 (duplicated; real `pnpm` comes from nvm/node)
  - `postgresql@16` — line 108 (real `psql` comes from `libpq`)
  - `python@3.12` — line 102 (you have `python@3.14`)

  Harmless but clutter. If you want any of these tools back, install the formula rather than
  keeping a path to nothing.

---

## 3. Possibly-unused toolchains — judgment calls

These are "do you still use this?" questions, not defects. Left alone pending a decision.

- [ ] **Clojure.** `lein` is not installed. `lein/profiles.clj` pins `cider-nrepl 0.8.1`,
      `midje 1.7.0`, `eastwood 0.2.0`, `slamhound 1.3.1` — all 2014–15 vintage. Affects
      `lein/profiles.clj`, `midje.clj`, and two `install.sh` lines.

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
| Not installed | `tmux`, `lein`, `gsed`, `mysql-client`, `postgresql@16`, `pnpm@9` (formula), `reattach-to-user-namespace`, `loadavg`, `cntlm` |
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
