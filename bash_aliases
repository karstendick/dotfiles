#!/bin/bash

# grep aliases
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ls aliases
alias ls='ls -G' # color!
alias l='ls -CF' # show in columns and add file indicators
alias ll='ls -la' # show all files in long format
alias la='ls -A' # show almost all entries (exclude . and ..)
alias lh='ls -a | egrep "^\."' # ONLY show hidden files

alias ping="ping -c 4" # stop after 4 packets

# this is the opposite of `workon`
alias workoff=deactivate

alias t=tmux
alias tl='t ls'
