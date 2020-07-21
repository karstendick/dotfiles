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

## AWS stuff
#export AWS_REGION=us-east-1
#export AWS_ACCESS_KEY_ID=`aws configure get default.aws_access_key_id`
#export AWS_SECRET_ACCESS_KEY=`aws configure get default.aws_secret_access_key`

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
export PATH="/usr/local/opt/postgresql@9.6/bin:$PATH"
export PATH="/usr/local/opt/mongodb@3.4/bin:$PATH"

# Use GNU versions of utilities, such as `sed`
PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"

# To use python tools like virtualenv
PATH="$HOME/Library/Python/2.7/bin:$PATH"
eval "$(pyenv init -)"

# Suppress Apple's message trying to get me to use zsh
export BASH_SILENCE_DEPRECATION_WARNING=1

# From Deliverr's dev-setup
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
export ENABLE_TEST_LOGS=true
