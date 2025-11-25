# ===== ZSH HISTORY =====
HISTFILE=~/.histfile
HISTSIZE=10000  
SAVEHIST=10000
setopt HIST_IGNORE_DUPS  
setopt HIST_IGNORE_SPACE  

# ===== PATH =====
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/opt/ncurses/bin:$PATH"
export PATH="$HOME/.spicetify:$PATH"
export PATH="$BUN_INSTALL/bin:$PATH"

# ===== ENVIRONMENT VARIABLES =====
export NVM_DIR="$HOME/.nvm"
export BUN_INSTALL="$HOME/.bun"

# ===== STARTUP =====
# fastfetch -l ~/.config/fastfetch/ascii.txt

# ===== TOOL INITIALIZATION =====
# NVM (Node Version Manager)
[ -s "$(brew --prefix nvm)/nvm.sh" ] && source "$(brew --prefix nvm)/nvm.sh"
[ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && source "$(brew --prefix nvm)/etc/bash_completion.d/nvm"

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# FZF
eval "$(fzf --zsh)"

# thefuck
eval $(thefuck --alias)

# Starship prompt
eval "$(starship init zsh)"

# ===== ZSH PLUGINS =====
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# ===== ALIASES =====
# File management
alias ls="eza -alh --icons"
alias lt='eza -aT --color=always --group-directories-first'
alias cat="bat"

# Navigation
alias home="cd ~"

# System maintenance
alias sysclean='echo "🚀 Starting cleanup..." && \
  brew upgrade && brew update && \
  brew autoremove && brew cleanup --prune=all -s && \
  rm -rf ~/Library/Caches/Homebrew && \
  echo "✅ Done - $(du -sh ~/Library/Caches 2>/dev/null | cut -f1) cache remaining"'

# Media
alias bestaudio="yt-dlp -x --embed-metadata --audio-format m4a"
export PATH="$HOME/.local/bin:$PATH"
