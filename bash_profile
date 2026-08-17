################
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
HISTSIZE=1000
HISTFILESIZE=2000

#####################################
## Other options and configurations #
#####################################

export EDITOR=emacs
export EMAIL=joshdick@gmail.com

## Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:$PATH";

## Add go stuff
export GOPATH="$HOME/go";
export GOBIN="$GOPATH/bin";
export PATH="$GOBIN:$PATH";

# Load the shell dotfiles, and then some:
for file in ~/.{bash_prompt,bash_aliases}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

source ~/bin/tmux.bash

# Put brew in the $PATH
eval "$(/opt/homebrew/bin/brew shellenv)"

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

export PATH="/opt/homebrew/opt/mysql-client@8.0/bin:$PATH"
# To put brew's python and pnpm on the $PATH
export PATH="/opt/homebrew/opt/python@3.12/libexec/bin:$PATH"
export PATH="/opt/homebrew/opt/pnpm@9/bin:$PATH"
# Needed for pipx
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/opt/mysql-client@8.0/bin:$PATH"
export PATH="/opt/homebrew/opt/pnpm@9/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH="/opt/homebrew/share/google-cloud-sdk/bin:$PATH"
