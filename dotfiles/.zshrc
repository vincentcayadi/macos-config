# History
HISTFILE="$HOME/.histfile"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_FCNTL_LOCK HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY
setopt HIST_FIND_NO_DUPS HIST_REDUCE_BLANKS
unsetopt APPEND_HISTORY EXTENDED_HISTORY

# Completion
[[ -d "$HOME/.cache/zsh" ]] || mkdir -p "$HOME/.cache/zsh"
autoload -Uz compinit
compinit -d "$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Homebrew-installed shell plugins.
if [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  ZSH_AUTOSUGGEST_STRATEGY=(history)
fi

# Tool integrations.
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh)
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"
command -v pay-respects >/dev/null 2>&1 && eval "$(pay-respects zsh --alias)"
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# Update installed tools without uninstalling packages or deleting caches.
brewclean() {
  brew update &&
  brew upgrade &&
  mise upgrade
}

# File management
alias ls='eza -alh --icons --group-directories-first'
alias lt='eza -aT --icons --group-directories-first'
alias cat='bat --paging=never'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias home='cd ~'
alias dev='cd ~/developer'
alias config='cd ~/nix-config'

# Media
alias yt='yt-dlp'
alias yta='yt-dlp -x --embed-metadata --audio-format m4a'
alias ytv="yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best'"

# Git
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull --rebase'
alias gd='git diff'
alias gb='git checkout'
alias lg='lazygit'

# Development
alias v='nvim'
alias zz='source ~/.zshrc'

# Syntax highlighting must be sourced near the end of .zshrc.
if [[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
