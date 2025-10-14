# ===== ZSH HISTORY =====
HISTFILE=~/.histfile
HISTSIZE=10000  # increased from 1000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS  # don't save duplicate commands
setopt HIST_IGNORE_SPACE  # don't save commands starting with space

# ===== PATH =====
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/opt/ncurses/bin:$PATH"
export PATH="$HOME/.spicetify:$PATH"
export PATH="$BUN_INSTALL/bin:$PATH"

# ===== ENVIRONMENT VARIABLES =====
export NVM_DIR="$HOME/.nvm"
export BUN_INSTALL="$HOME/.bun"

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

# Kitty specific
alias icat="kitten icat"

# Custom scripts
alias lrcpy="$HOME/scripts/lrcput.py"

# System maintenance
alias sysclean='echo "Initiating Upgrades 🚀" && brew upgrade && brew update && echo "Cleaning 🧹" && brew autoremove && brew cleanup --prune=all && yarn cache clean && echo "Completed"'

# Media
alias bestaudio="yt-dlp -x --embed-metadata --audio-format m4a"

# ===== STARTUP =====
fastfetch -l ~/.config/fastfetch/ascii.txt
