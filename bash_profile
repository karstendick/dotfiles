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

## AWS stuff for Augment
export AWS_DEFAULT_PROFILE=PowerUserAccess-908027377227

# Load the shell dotfiles, and then some:
for file in ~/.{bash_prompt,bash_aliases}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion

function proxy-set {
	export http_proxy=http://localhost:3333
	export https_proxy=$http_proxy
	export HTTP_PROXY=$http_proxy
	export HTTPS_PROXY=$http_proxy
	export FTP_PROXY=$http_proxy
	export SOCKS_PROXY=$http_proxy
	export NO_PROXY="localhost,127.0.0.1"
}

function proxy-clear {
	unset http_proxy
	unset https_proxy
	unset HTTP_PROXY
	unset HTTPS_PROXY
	unset FTP_PROXY
	unset SOCKS_PROXY
	unset NO_PROXY
}

source ~/bin/tmux.bash

# Use GNU versions of utilities, such as `sed`
PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"

# Put brew in the $PATH
eval "$(/opt/homebrew/bin/brew shellenv)"

# Suppress Apple's message trying to get me to use zsh
export BASH_SILENCE_DEPRECATION_WARNING=1

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export ENABLE_TEST_LOGS=true
export PIPENV_VERBOSITY=-1

export PATH="/opt/homebrew/opt/mysql-client@8.0/bin:$PATH"
# To put brew's python and pnpm on the $PATH
export PATH="/opt/homebrew/opt/python@3.12/libexec/bin:$PATH"
export PATH="/opt/homebrew/opt/pnpm@9/bin:$PATH"
# Needed for pipx
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/opt/mysql-client@8.0/bin:$PATH"
export PATH="/opt/homebrew/opt/pnpm@9/bin:$PATH"

export AWS_PROFILE=dev
export AWS_DEFAULT_PROFILE=dev

# Claude Code using AWS Bedrock
# See: https://builder.aws.com/content/2tXkZKrZzlrlu0KfH8gST5Dkppq/claude-code-on-amazon-bedrock-quick-setup-guide
export CLAUDE_CODE_USE_BEDROCK=1
export ANTHROPIC_MODEL='us.anthropic.claude-sonnet-4-5-20250929-v1:0'
# Recommended starting point for Claude 4 models on Bedrock
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=4096
export MAX_THINKING_TOKENS=1024
