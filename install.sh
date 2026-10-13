#!/bin/bash

# Node version --brew installs. Matches `nvm alias default` on the machine this was written on;
# bump it when projects move. Individual projects can still override with their own .nvmrc.
NODE_VERSION=22

usage() {
    echo "Usage: $0 [--brew]" >&2
    echo "  --brew  bootstrap a new machine before symlinking: everything in ./Brewfile, then" >&2
    echo "          Node $NODE_VERSION via nvm, the pnpm shim via corepack, and the VS Code" >&2
    echo "          extension in ./vscode. Needs the network, takes a while, and upgrades" >&2
    echo "          already-installed packages." >&2
    exit 1
}

WORKTREE_LAYOUT_ID=joshua.worktree-layout

# Package vscode/worktree-layout and install it into VS Code. Under --brew because packaging
# downloads vsce, and because it needs the code CLI and the Claude Code extension it depends on,
# both of which come from the Brewfile. Re-run --brew after editing the extension to reinstall it.
install_worktree_layout() {
    if ! command -v code > /dev/null || ! command -v pnpm > /dev/null; then
        echo "code or pnpm not on PATH -- skipping $WORKTREE_LAYOUT_ID" >&2
        return
    fi
    local vsix
    vsix=$(mktemp -d)/worktree-layout.vsix
    (cd vscode/worktree-layout \
        && pnpm dlx @vscode/vsce package --allow-missing-repository --skip-license -o "$vsix") \
        && code --install-extension "$vsix" --force
}

case "$1" in
    --brew) INSTALL_BREW=yes ;;
    "")     INSTALL_BREW=no  ;;
    *)      usage            ;;
esac

# Tools before config, so the dotfiles below have something to point at.
if [ "$INSTALL_BREW" = yes ]; then
    BREW=$(command -v brew || echo /opt/homebrew/bin/brew)
    if [ ! -x "$BREW" ]; then
        echo "--brew was given but Homebrew isn't installed. See https://brew.sh" >&2
        exit 1
    fi
    # Some casks install as root: session-manager-plugin is a .pkg, and docker-desktop replaces
    # privileged helpers under /Library plus binaries in /usr/local/bin. Homebrew warns about that
    # with "...which may request your password" on *stdout* -- which is exactly what `brew bundle`
    # hides (see --verbose below) -- so the sudo prompt used to arrive as a bare "Password:" after
    # minutes of silence, or not visibly at all. Ask once here, where it's obvious what it's for.
    # Not fatal if it fails: the individual cask steps will still prompt for themselves.
    echo "Priming sudo -- some casks install as root, and prompting mid-download is easy to miss."
    sudo -v || echo "  sudo failed -- casks needing root will prompt individually" >&2

    # --verbose, because without it `brew bundle` runs every `brew install` under IO.popen with
    # stderr folded into stdout, buffers the lot, and prints it *only if the command fails*
    # (Homebrew/Library/Homebrew/bundle.rb). A multi-gigabyte docker-desktop download therefore
    # produces zero output for minutes and looks like a hang. --verbose only switches that capture
    # off; it does not pass --verbose down to brew itself, so the output is normal brew output.
    #
    # The Brewfile is piped in minus the worktree-layout extension: `brew bundle dump` records it
    # like any other VS Code extension, but it isn't on the Marketplace, so brew can't fetch it and
    # the whole install would fail. install_worktree_layout builds it from ./vscode instead.
    grep -vxF "vscode \"$WORKTREE_LAYOUT_ID\"" Brewfile \
        | "$BREW" bundle install --verbose --file=- || exit 1

    # Node comes from the nvm installed just above, and Node ships corepack. corepack reads each
    # project's "packageManager" field and fetches that exact pnpm version, which is why pnpm is
    # deliberately neither a brew formula nor a global npm install.
    NVM_SH="$("$BREW" --prefix)/opt/nvm/nvm.sh"
    if [ -s "$NVM_SH" ]; then
        export NVM_DIR="$HOME/.nvm"
        mkdir -p "$NVM_DIR"
        # shellcheck source=/dev/null
        . "$NVM_SH"
        nvm install "$NODE_VERSION" \
            && nvm alias default "$NODE_VERSION" \
            && corepack enable pnpm
    else
        echo "nvm not found at $NVM_SH -- skipping Node setup" >&2
    fi

    install_worktree_layout
fi

LINK_FLAGS="-s"
DIR_LINK_FLAGS="${LINK_FLAGS} -n"

mymkdir() {
    mkdir -p $1 2> /dev/null || true
}

backup() {
    mv $1 $BK_DIR/ 2> /dev/null
}

BK_DIR=$(pwd)/.bk/$(date '+%FT%T')
mymkdir $BK_DIR

# arguments:
# 1 flags to the ln command
# 2 the local file in this directory that will be linked
# 3 (optional) the destination. If no argument given, the destination will
#   be the same as the source, but prepended with a dot and put in ~
_create_link() {
    local flags=$1
    local source_rel=$2
    local source_abs=$(pwd)/$2
    local link=$3

    [ $link ] || link=~/.$source_rel
    backup $link
    ln $flags $source_abs $link && echo "$link -> $source_abs"
}
symlink() {
    _create_link "$LINK_FLAGS" $1 $2
}
dirlink() {
    _create_link "$DIR_LINK_FLAGS" $1 $2
}

# Make Homebrew's bash 5.x the login shell. Apple's /bin/bash is 3.2, which is too old for
# bash-completion@2 (needs >= 4.1) and nags about zsh on every login.
#
# This is not a one-time new-machine step, which is why it isn't behind a flag: macOS updates
# reset it. 26.6.2 restored the stock /etc/shells *and* put UserShell back to /bin/bash, silently
# undoing the switch and taking all 153 completions with it. Re-running install.sh repairs it.
#
# Idempotent, and quiet when there's nothing to do -- no sudo is invoked unless /etc/shells is
# actually missing the entry, so the common case doesn't prompt for a password.
switch_login_shell() {
    local brew brew_bash current
    brew=$(command -v brew || echo /opt/homebrew/bin/brew)
    if [ ! -x "$brew" ]; then
        echo "Homebrew not found -- leaving login shell as $(basename "$SHELL")" >&2
        return
    fi
    brew_bash="$("$brew" --prefix)/bin/bash"
    if [ ! -x "$brew_bash" ]; then
        echo "$brew_bash not installed -- run 'brew install bash' to switch off Apple's 3.2" >&2
        return
    fi

    current=$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}')
    [ "$current" = "$brew_bash" ] && return 0

    echo "Login shell is $current -- switching to $brew_bash"
    # grep -qxF, because an unguarded append duplicated this line last time.
    if ! grep -qxF "$brew_bash" /etc/shells; then
        echo "  adding $brew_bash to /etc/shells (needs sudo)"
        echo "$brew_bash" | sudo tee -a /etc/shells > /dev/null || return 1
    fi
    chsh -s "$brew_bash" && echo "  done -- open a new terminal to pick it up"
}

mymkdir ~/bin

symlink bash_prompt
symlink bash_aliases
symlink bash_profile

symlink tmux.conf

symlink gitconfig
symlink gitignore

for file in $(ls bin); do
    symlink bin/$file ~/bin/$file
done

symlink editrc

mymkdir ~/.config/
mymkdir ~/.config/pip/
symlink pip.conf ~/.config/pip/pip.conf

mymkdir ~/.claude
symlink claude/settings.json ~/.claude/settings.json
symlink claude/CLAUDE.md ~/.claude/CLAUDE.md
dirlink claude/commands ~/.claude/commands
dirlink claude/skills ~/.claude/skills

# Suppress "Last login" in new terminal windows
symlink hushlogin

echo Backed up files to $BK_DIR

switch_login_shell
