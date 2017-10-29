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

source ~/aws_creds.sh

# Load the shell dotfiles, and then some:
for file in ~/.{bash_prompt,bash_aliases}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
# Load the stitchdata/ide goodies:
for file in ~/git/ide/bash/functions/*; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
for file in ~/git/ide/bash/aliases/*; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
for file in ~/git/ide/bash/bin/*; do
    ln -s "$file" ~/bin;
done;
ln -s ~/git/ide/bash/tmux.conf ~/tmux.conf
unset file;

source ~/bin/tmux.bash
