#!/bin/bash
set -u

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
failures=0

check_command() {
  name=$1
  # Resolve through a fresh login shell so .zprofile, .zshrc, and mise activation
  # are tested instead of this script's inherited pre-migration PATH.
  path=$(/bin/zsh -lic "command -v -- '$name'" 2>/dev/null | tail -n 1)
  if [[ -z "$path" ]]; then
    echo "MISSING  $name"
    failures=$((failures + 1))
  elif [[ "$path" == /nix/* || "$path" == /etc/profiles/* ]]; then
    echo "NIX PATH $name -> $path"
    failures=$((failures + 1))
  else
    echo "OK       $name -> $path"
  fi
}

echo "== Architecture =="
if [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]]; then
  echo "OK       Apple Silicon macOS"
else
  echo "FAIL     expected Apple Silicon macOS"
  failures=$((failures + 1))
fi

echo
echo "== Brewfile =="
if /opt/homebrew/bin/brew bundle check --file "$ROOT/Brewfile"; then
  echo "OK       Brewfile dependencies installed"
else
  failures=$((failures + 1))
fi

echo
echo "== Commands must not resolve through Nix =="
for command_name in git git-lfs nvim mise bun node python3 go pay-respects \
  starship zoxide fzf direnv tmux btop rg ruff psql ollama; do
  check_command "$command_name"
done

echo
echo "== Dotfile links =="
for relative in .zprofile .zshrc .gitconfig .tmux.conf .aerospace.toml \
  .config/nvim .config/btop .config/fastfetch .config/starship.toml \
  .config/mise/config.toml .local/bin/tmux-sessionizer; do
  target="$HOME/$relative"
  expected="$ROOT/dotfiles/$relative"
  if [[ -L "$target" && "$(readlink "$target")" == "$expected" ]]; then
    echo "OK       $target"
  else
    echo "MISMATCH $target"
    failures=$((failures + 1))
  fi
done

echo
echo "== Tool checks =="
/bin/zsh -lic 'mise doctor' 2>/dev/null || true
/bin/zsh -lic 'git-credential-manager --version' 2>/dev/null || true
/bin/zsh -lic 'pay-respects --version' 2>/dev/null || true
/bin/zsh -lic 'psql --version' 2>/dev/null || true

echo
if [[ "$failures" -eq 0 ]]; then
  echo "Migration verification passed. This does not remove Nix."
else
  echo "Migration verification found $failures issue(s). Nix should remain untouched." >&2
fi

exit "$failures"
