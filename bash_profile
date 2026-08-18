##################
## Shell options #
##################

## For an explanation of any of the following options, see
## http://wiki.bash-hackers.org/internals/shell_options

shopt -s checkwinsize
shopt -s histappend
shopt -s lithist

#########################################################
## History configuration (See bash(1) for more options) #
#########################################################

HISTCONTROL=ignoredups:ignorespace
HISTSIZE=100000
HISTFILESIZE=200000

# Share history live across concurrent shells (multiple iTerm2 windows), so Ctrl+R in one window
# finds commands run in another. `histappend` alone only flushes at shell exit, and a shell only
# reads the file at startup, so without this a command isn't visible elsewhere until you close the
# window that ran it *and* open a fresh one.
#
# `history -a` appends this shell's new entries to the file after every command; `history -n` reads
# back only the lines added since this shell last read it. Deliberately *not* the widespread
# `history -a; history -c; history -r` recipe — that wipes the in-memory list and reloads the whole
# file every prompt, which interleaves every window's commands into up-arrow recall. With `-n`, your
# own commands stay at the bottom of the stack and other windows' merge in behind them.
#
# HISTTIMEFORMAT is load-bearing, not cosmetic: `lithist` (set above) stores multi-line commands
# with literal embedded newlines, and concurrent appends from several shells would be impossible to
# split back apart. Setting it makes bash write a `#<epoch>` marker before each entry, which
# delimits them unambiguously. Side effect: `history` output is now timestamped.
HISTTIMEFORMAT='%F %T '

# Guarded so re-sourcing this file doesn't stack duplicate entries. This lands *after*
# `prompt_save_status` in the final chain (bash_prompt is sourced below and prepends itself), so the
# exit status is snapshotted before these builtins overwrite $?.
if [[ ";${PROMPT_COMMAND:-};" != *";history -a;"* ]]; then
	PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
fi

#####################################
## Other options and configurations #
#####################################

export EDITOR=emacs
export EMAIL=joshdick@gmail.com

## Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:$PATH";

# Load the shell dotfiles, and then some:
for file in ~/.{bash_prompt,bash_aliases}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

source ~/bin/tmux.bash

# Put brew in the $PATH
eval "$(/opt/homebrew/bin/brew shellenv)"

# Keep global npm packages out of the Brewfile. They install into whichever Node version nvm has
# active, so they don't belong in a snapshot of brew's state — and they can't install on a fresh
# machine, where `brew bundle install` runs before any Node exists. pnpm comes from corepack.
export HOMEBREW_BUNDLE_DUMP_NO_NPM=1

# Bash completion. Must come after brew shellenv, which sets $HOMEBREW_PREFIX.
# bash-completion@2 needs bash >= 4.1, so this is a no-op under Apple's /bin/bash 3.2.
[[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]] && . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"

# git comes from Xcode rather than Homebrew, so bash-completion can't auto-load its completion.
_git_completion=/Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash
[[ -r "$_git_completion" ]] && . "$_git_completion"
unset _git_completion

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# direnv hook
_direnv_hook() {
  local previous_exit_status=$?;
  trap -- '' SIGINT;
  eval "$("/opt/homebrew/bin/direnv" export bash)";
  trap - SIGINT;
  return $previous_exit_status;
};
if [[ ";${PROMPT_COMMAND[*]:-};" != *";_direnv_hook;"* ]]; then
  if [[ "$(declare -p PROMPT_COMMAND 2>&1)" == "declare -a"* ]]; then
    PROMPT_COMMAND=(_direnv_hook "${PROMPT_COMMAND[@]}")
  else
    PROMPT_COMMAND="_direnv_hook${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
  fi
fi

# other env vars
export ENABLE_TEST_LOGS=true
export PIPENV_VERBOSITY=-1

export AWS_PROFILE=agi-dev

# Needed for pipx
export PATH="$HOME/.local/bin:$PATH"
# psql, pg_dump etc. — libpq is keg-only so it needs an explicit path
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH="/opt/homebrew/share/google-cloud-sdk/bin:$PATH"
