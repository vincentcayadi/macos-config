#!/bin/bash

DIRS=(
 "$HOME/developer"
 "$HOME/developer/macos-config"
 "$HOME"
)

if [[ $# -eq 1 ]]; then
 selected=$1
else
 selected=$(find "${DIRS[@]}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
 | fzf --height=40% --border --prompt="Select project: ")
fi

[[ ! $selected ]] && exit 0

selected_name=$(basename "$selected" | tr . _)

if ! tmux has-session -t "$selected_name" 2>/dev/null; then
 tmux new-session -ds "$selected_name" -c "$selected"
fi

if [[ -z "$TMUX" ]]; then
 tmux attach-session -t "$selected_name"
else
 tmux switch-client -t "$selected_name"
fi
