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

export EDITOR=vim
export EMAIL=jkarstendick@rjmetrics.com

## Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:$PATH";
export PATH="$PATH:/usr/lib/hadoop/bin";

[ -r ~/.dircolors ] && DIRCOLORS=~/.dircolors
eval "$(dircolors -b $DIRCOLORS)"

bind '"\C-p": history-search-backward'
bind '"\C-n": history-search-forward'

## enable programmable completion features (you don't need to enable
## this, if it's already enabled in /etc/bash.bashrc and /etc/profile
## sources /etc/bash.bashrc).
if [ -z "$BASH_COMPLETION" ] && [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

export VIMCLOJURE_SERVER_JAR=~/lib/vimclojure/server-2.3.6.jar

export GPG_AGENT_INFO_FILE=$HOME/.gpg-agent-info
gpg-agent --daemon --write-env-file "${GPG_AGENT_INFO_FILE}"

if [ -f "${GPG_AGENT_INFO_FILE}" ]; then
    . "${GPG_AGENT_INFO_FILE}"
    export GPG_AGENT_INFO
    export SSH_AUTH_SOCK
    export SSH_AGENT_PID
fi
export GPG_TTY=$(tty)

source ~/.lein/aws_creds.sh
export PATH=$PATH:/opt/code/blackbox/bin

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,bash_aliases,functions,extra}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

