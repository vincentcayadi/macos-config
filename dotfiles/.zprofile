# Homebrew on Apple Silicon.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Keg-only tools and personal scripts. zsh keeps duplicate PATH entries out.
typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "/opt/homebrew/opt/postgresql@17/bin"
  "/opt/homebrew/opt/curl/bin"
  "/opt/homebrew/opt/ncurses/bin"
  $path
)
export PATH

export EDITOR="nvim"
export VISUAL="nvim"
