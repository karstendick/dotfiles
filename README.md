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

It needs the network, takes a while, and may prompt for your password when
installing casks. Without the flag, `install.sh` behaves exactly as it always has:
symlinks only, fast and offline.

One step isn't automated, because it needs your password and changes your login
shell — make Homebrew's bash the login shell, so you get bash 5.x instead of
Apple's 3.2 (and with it, working completions):

```bash
echo /opt/homebrew/bin/bash | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/bash
```

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
