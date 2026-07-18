#!/bin/bash
set -u

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
DOTFILES="$ROOT/dotfiles"
MODE="dry-run"

usage() {
  cat <<'EOF'
Usage: scripts/install-dotfiles.sh [--dry-run|--apply|--backup]

--dry-run  Report planned links and conflicts without changing anything (default).
--apply    Create missing links only; abort before changes if conflicts exist.
--backup   After interactive approval, move conflicts to a timestamped backup
           directory and create links. Nothing is deleted.
EOF
}

case "${1:---dry-run}" in
  --dry-run) MODE="dry-run" ;;
  --apply) MODE="apply" ;;
  --backup) MODE="backup" ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

MAPPINGS=(
  ".zprofile|$HOME/.zprofile"
  ".zshrc|$HOME/.zshrc"
  ".gitconfig|$HOME/.gitconfig"
  ".tmux.conf|$HOME/.tmux.conf"
  ".aerospace.toml|$HOME/.aerospace.toml"
  ".config/nvim|$HOME/.config/nvim"
  ".config/btop|$HOME/.config/btop"
  ".config/fastfetch|$HOME/.config/fastfetch"
  ".config/starship.toml|$HOME/.config/starship.toml"
  ".config/mise/config.toml|$HOME/.config/mise/config.toml"
  ".local/bin/tmux-sessionizer|$HOME/.local/bin/tmux-sessionizer"
)

conflicts=0
for mapping in "${MAPPINGS[@]}"; do
  source_rel=${mapping%%|*}
  target=${mapping#*|}
  source="$DOTFILES/$source_rel"

  if [[ ! -e "$source" ]]; then
    echo "ERROR: missing source $source" >&2
    exit 1
  elif [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    echo "OK       $target -> $source"
  elif [[ -e "$target" || -L "$target" ]]; then
    echo "CONFLICT $target"
    conflicts=$((conflicts + 1))
  else
    echo "NEW LINK $target -> $source"
  fi
done

if [[ "$MODE" == "dry-run" ]]; then
  echo "Dry run complete: $conflicts conflict(s); no changes made."
  exit 0
fi

if [[ "$MODE" == "apply" && "$conflicts" -gt 0 ]]; then
  echo "Aborting before changes because conflicts exist. Use --backup only after review." >&2
  exit 1
fi

BACKUP_ROOT=""
if [[ "$MODE" == "backup" && "$conflicts" -gt 0 ]]; then
  BACKUP_ROOT="$HOME/.dotfiles-backups/$(date +%Y%m%d-%H%M%S)"
  echo
  echo "$conflicts existing path(s) will be moved under:"
  echo "  $BACKUP_ROOT"
  echo "No files will be deleted. Continue? [y/N]"
  read -r reply
  [[ "$reply" == "y" || "$reply" == "Y" ]] || { echo "Cancelled; no changes made."; exit 1; }
fi

for mapping in "${MAPPINGS[@]}"; do
  source_rel=${mapping%%|*}
  target=${mapping#*|}
  source="$DOTFILES/$source_rel"

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    continue
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    relative=${target#"$HOME"/}
    backup="$BACKUP_ROOT/$relative"
    mkdir -p "$(dirname "$backup")" || exit 1
    if [[ -e "$backup" || -L "$backup" ]]; then
      echo "Backup destination already exists: $backup" >&2
      exit 1
    fi
    mv "$target" "$backup" || exit 1
    echo "BACKED UP $target -> $backup"
  fi

  mkdir -p "$(dirname "$target")" || exit 1
  ln -s "$source" "$target" || exit 1
  echo "LINKED    $target -> $source"
done

echo "Dotfile installation complete. Backups were not deleted."
