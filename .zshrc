# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
# End of lines configured by zsh-newuser-install
eval $(thefuck --alias)
eval $(thefuck --alias FUCK)

# ZSH Plugins
source $(brew --prefix nvm)/nvm.sh

#ALIAS
alias ls="eza -alh --icons"
alias lt='eza -aT --color=always --group-directories-first --icons' # tree listing
alias cat="bat"
alias home="cd ~"
alias icat="kitten icat"
export PATH=$PATH:"$HOME/.local/bin"
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# system clean
alias sysclean='echo "Initiating Upgrades 🚀" && brew upgrade && brew update && echo "Cleaning 🧹" && brew autoremove && brew cleanup --prune=all && yarn cache clean && echo "Completed" '

# yt-dlp
alias bestaudio="yt-dlp -x --audio-format m4a"


export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"
[ -s "/usr/local/opt/nvm/etc/bash_completion" ] && \. "/usr/local/opt/nvm/etc/bash_completion"

#starship
eval "$(starship init zsh)"

PATH=~/.console-ninja/.bin:$PATH
