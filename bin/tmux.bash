#!/usr/bin/env bash

function new_tmux_session {
    local session_name="$1"

    if tmux has-session -t "$session_name" > /dev/null 2>&1
    then
        echo "# Attempted to create new tmux session $session_name when it already exists!" 1>&2
        return 1
    fi

    (
        cd $HOME

        # No command argument: tmux runs $SHELL as a login shell, so ~/.bash_profile is sourced.
        # tmux -vvvv new-session -d -s $session_name -n editor # for debugging
        tmux new-session -d -s $session_name -n editor
        if [[ Darwin = $(uname) ]]
        then
            tmux send-keys 'emacs' 'C-m'
        else
            tmux send-keys 'TERM=xterm-256color emacs' 'C-m'
        fi
        tmux new-window -t $session_name -n admin
        tmux new-window -t $session_name -n services
        tmux new-window -t $session_name -n db
        tmux new-window -t $session_name -n tests
        tmux select-window -t 1
        tmux select-window -t 0
    )

    tmux attach -t $session_name
}

function ntmux {
    local session_name="$1"

    if [[ -z $session_name ]]
    then
        echo 'Usage: ntmux session_name'
        return 1
    fi

    # Used properly

    if tmux has-session -t "$session_name" >/dev/null 2>&1
    then
        # Attach to Existing Session
        tmux attach -t "$session_name"
    else
        new_tmux_session "$session_name"
    fi
}

alias nt=ntmux
