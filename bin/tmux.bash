#!/usr/bin/env bash

function new_tmux_session {
    local session_name="$1"

    if tmux has-session -t "$session_name" > /dev/null 2>&1
    then
        echo "# Attempted to create new tmux session $session_name when it already exists!" 2>&1
        return 1
    fi

    local default_command="which reattach-to-user-namespace > /dev/null 2>&1 && reattach-to-user-namespace -l bash || bash"

    (
        cd $HOME

        # tmux -vvvv new-session -d -s $session_name -n editor "$default_command" # for debugging
        tmux new-session -d -s $session_name -n editor "$default_command"
        if [[ Darwin = $(uname) ]]
        then
            tmux send-keys 'emacs' 'C-m'
        else
            tmux send-keys 'TERM=xterm-256color emacs' 'C-m'
        fi
        tmux set-option -g default-command "$default_command"
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
