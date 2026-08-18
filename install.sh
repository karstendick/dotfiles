#!/bin/bash

# Node version --brew installs. Matches `nvm alias default` on the machine this was written on;
# bump it when projects move. Individual projects can still override with their own .nvmrc.
NODE_VERSION=22

usage() {
    echo "Usage: $0 [--brew]" >&2
    echo "  --brew  bootstrap a new machine before symlinking: everything in ./Brewfile, then" >&2
    echo "          Node $NODE_VERSION via nvm and the pnpm shim via corepack. Needs the network," >&2
    echo "          takes a while, and upgrades already-installed packages." >&2
    exit 1
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
    "$BREW" bundle install --file="$(pwd)/Brewfile" || exit 1

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
