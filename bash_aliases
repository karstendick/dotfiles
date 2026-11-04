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

# human-readable output
alias df='df -h'
alias du='du -h'

alias t=tmux
alias tl='t ls'

alias emacs='emacs -nw'

alias tf='terraform'

alias psqllocal='psql "${DATABASE_URL%%\?*}"'

# Bare `claude` opens agent view with dispatch defaults: sessions start in plan mode on
# opusplan (Opus while planning, Sonnet once a plan is approved). Agent view has no settings
# key for these, only flags. Anything with arguments runs claude unchanged.
# Agent view's /resume refuses a view opened with these flags; run `command claude agents`.
claude() {
  if [ $# -eq 0 ]; then
    command claude agents --model opusplan --permission-mode plan
  else
    command claude "$@"
  fi
}
