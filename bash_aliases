#!/bin/bash
alias ls='ls -G' #-color=auto'

# grep aliases
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

echo-do() {
  # Print a command and then run it.
    local cmd

    echo "$@" 1>&2
    "$@"
}

perg() {
  # Wrapper around grep. Excludes a bunch of files and
  # directories that don't need to be searched.
  # Also allows you to specify "+" as the last argument
  # which will cause the grep command to be printed to
  # the screen before it is executed.
    local args
    local pre

    args=( "$@" )
    pre=""

    [[ "${*:$#}" == "+" ]] && {
      args=( "${*:1:$#-1}" )
      pre="echo-do "
    }

    [[ ${#args[@]} -eq 1 ]] && {
        args=( "$1" '.' )
    }

    ${pre}egrep -Ir \
        --color=auto \
        --exclude=tags \
        --exclude-dir=.git \
        --exclude-dir=build \
        --exclude-dir=Framework \
        --exclude-dir=vendor \
        --exclude=*min.js \
        "${args[@]}"
}
alias gr=perg

gw() {
    perg "\<$1\>" "${*:2}"
}

# ls aliases
alias l='ls -CF' # show in columns and add file indicators
alias ll='ls -la' # show all files in long format
alias la='ls -A' # show almost all entries (exclude . and ..)
alias lh='ls -a | egrep "^\."' # ONLY show hidden files

# git aliases
alias gist="git status -s"
alias c-="git checkout -"
alias b="git for-each-ref --sort=-committerdate refs/heads/"
alias giff="git diff --color-words --ignore-space-change"
short() { N=${1:-1}; git log -n $N --first-parent; }
long() { git log --first-parent; }

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

alias ping="ping -c 4"

# Goofing around
alias dc="echo \"dc? I think you meant cd.  Here, let me take care of that for you.
Oh I'm wrong?  Just \\\"cd -\\\" and use the real dc (/usr/bin/dc).\" ; cd"
alias cd..="echo \"I think you meant 'cd ..'.  Here, let me take care of that for you.\"; cd .."

rmswp() {
    ext=swp
    [ $1 ] && ext=$1
    for x in $(find . -name *.$ext); do
        rm -f $x
    done
}

alias unit='phpunit --bootstrap=test/bootstrap.php'

do-ctags() {
    ctags -R --fields=+S --languages=php "$@"
}

ant() {
    /usr/bin/time -o ~/ant-times --append /usr/bin/ant -Denv=box-test "$@"
}

gvim() {
    /usr/bin/gvim -f "$@" &
}

alias g=gvim

alias gpg=gpg2

# this is the opposite of `workon`
alias workoff=deactivate

alias e='ssh -A jkarstendick@echo.rjmetrics.com'
