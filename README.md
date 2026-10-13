# Joshua's dot-files

This repository contains all of my configuration files. You may notice
that none of the files are actually "dot" files in that they do not
start with a '.'. This is to make them non-hidden files.

Forked from Buck's dotfiles: https://github.com/b-ryan/dotfiles

Thanks also to: https://github.com/mathiasbynens/dotfiles and https://github.com/timvisher

## Installation

Just run

```bash
./install.sh
```

It will create symlinks for all the dot-files in your home directory. It will
overwrite files wherever it tries to install stuff, but will back everything
up into the .bk directory.

## New machine

Install [Homebrew](https://brew.sh) first, then:

```bash
./install.sh --brew
```

`--brew` does the whole tools-before-config bootstrap:

1. `brew bundle install` against the `Brewfile`, so the packages the dotfiles
   depend on (`bash-completion@2`, `nvm`, `libpq`, `tmux`, `emacs`, …) exist by the
   time the config lands.
2. `nvm install 22`, `nvm alias default 22`, and `corepack enable pnpm`, so
   Node/TypeScript work is ready too. The version is the `NODE_VERSION` variable at
   the top of `install.sh`.
3. Packaging `vscode/worktree-layout` and installing it into VS Code — see
   [VS Code worktree layout](#vs-code-worktree-layout).

It needs the network, takes a while, and may prompt for your password when
installing casks. Without the flag, `install.sh` is symlinks only — fast and
offline, apart from the login shell check below.

## Login shell

`install.sh` makes Homebrew's bash 5.x the login shell, so you get working
completions instead of Apple's `/bin/bash` 3.2 and its zsh nag. It runs on every
invocation, not behind a flag, because **this is not a one-time step — macOS
updates undo it.** macOS 26.6.2 restored the stock `/etc/shells` and reset the
login shell to `/bin/bash`, which silently turned the `bash-completion@2` setup in
`bash_profile` back into a no-op. When the zsh nag reappears in a new terminal,
that's the symptom; re-run `./install.sh` to repair it.

The check is idempotent and quiet when there's nothing to do. It only reaches for
`sudo` when `/etc/shells` is actually missing the entry, so a normal run doesn't
prompt for a password — but the repair run will, twice (`sudo tee`, then `chsh`).

Revert with `chsh -s /bin/bash`. `bash_profile` also sets
`BASH_SILENCE_DEPRECATION_WARNING=1` unconditionally: only bash 3.2 ever prints
that warning, so the line looks redundant under 5.x, but it's what keeps the nag
away in the window between a macOS update and the next `install.sh` run. Don't
prune it as dead code — it was removed once for exactly that reason.

## Node and TypeScript

The chain is: Homebrew installs `nvm` → nvm installs `node` → Node ships
`corepack` → corepack provides `pnpm`.

That last hop is the important one. `pnpm` is a corepack shim, not a brew formula
and not a global npm install. corepack reads the `packageManager` field in each
project's `package.json` and fetches *that exact* pnpm version, so different
projects can pin different versions and none of them drift. Installing pnpm from
Homebrew instead would pin one global version that ignores those fields.

For the same reason, global npm packages are deliberately kept out of the
`Brewfile` — they install into whichever Node version nvm has active, so they
aren't part of brew's state, and they can't install on a fresh machine where
`brew bundle install` runs before any Node exists. `bash_profile` sets
`HOMEBREW_BUNDLE_DUMP_NO_NPM=1` so `brew bundle dump` never picks them up.

TypeScript is a per-project devDependency, run with `pnpm exec tsc`. Nothing to
install globally.

## Brewfile

The `Brewfile` is a snapshot of what's installed via Homebrew — packages, casks,
one tap, and VS Code extensions. It records only what was installed *on request*
(16 formulae, not the ~90 installed once dependencies are counted), so
dependencies get resolved fresh rather than pinned.

Refresh it after installing or removing anything:

```bash
brew bundle dump --force
```

That regenerates the file from scratch, so check the diff before committing. The
file is kept byte-identical to a fresh dump — no hand-edited lines — so a
regeneration can't silently lose anything.

To see what's actually missing, without installing anything:

```bash
brew bundle check --verbose --no-upgrade
```

`--no-upgrade` matters here: without it, `check` also reports every installed-but-
outdated package as unsatisfied, which buries the genuinely missing ones.

Note that `brew bundle install` upgrades already-installed packages by default;
pass `--no-upgrade` if you don't want that. Avoid `brew bundle cleanup --force`
unless you mean it — it uninstalls anything *not* listed in the `Brewfile`.

## VS Code worktree layout

`vscode/worktree-layout` is a small personal VS Code extension. When a window opens
on a folder with nothing restored — a fresh git worktree, in practice — it hides
both sidebars, opens `README.md` on the left, and opens a Claude Code tab on the
right. A window you've used before restores its own tabs and is left alone. It also
sets `workbench.startupEditor` to `none` if you haven't set it, since the Welcome
page would otherwise count as an open tab and stop the layout.

It isn't on the Marketplace, so `install.sh --brew` packages it with `vsce` and
installs the `.vsix`. After editing it, bump `version` in its `package.json` and
re-run `./install.sh --brew`.

`brew bundle dump` still records it as `vscode "joshua.worktree-layout"`, and the
line stays, so the Brewfile remains a plain dump. `install.sh` filters that one line
out before `brew bundle install`, which would otherwise fail trying to fetch it.
`brew bundle check` reports it as satisfied once it's installed.
