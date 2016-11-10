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
export INSTALL_ENV=box
export USERNAME=jkarstendick

## Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:$PATH";
export PATH="$PATH:/usr/lib/hadoop/bin";
export PATH=$PATH:/opt/code/blackbox/bin


export GPG_AGENT_INFO_FILE=$HOME/.gpg-agent-info
gpg-agent --daemon --write-env-file "${GPG_AGENT_INFO_FILE}" > /dev/null

if [ -f "${GPG_AGENT_INFO_FILE}" ]; then
    . "${GPG_AGENT_INFO_FILE}"
    export GPG_AGENT_INFO
    export SSH_AUTH_SOCK
    export SSH_AGENT_PID
fi
export GPG_TTY=$(tty)

export RJM_VM_MEMORY=8192
source ~/aws_creds.sh

# Load the shell dotfiles, and then some:
for file in ~/.{bash_prompt,bash_aliases}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

source ~/bin/tmux.bash
