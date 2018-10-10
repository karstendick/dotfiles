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

source ~/bin/tmux.bash
export PATH="/usr/local/opt/postgresql@9.6/bin:$PATH"
export PATH="/usr/local/opt/mongodb@3.4/bin:$PATH"

eval "$(pyenv init -)"
