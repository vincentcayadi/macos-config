#!/bin/bash
set -u

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
MISE_CONFIG="$ROOT/dotfiles/.config/mise/config.toml"
OMP_CONFIG_SOURCE="$ROOT/dotfiles/.omp/agent/config.yml"
OMP_CONFIG_TARGET="$HOME/.omp/agent/config.yml"
MODE="plan"

usage() {
  cat <<'EOF'
Usage: scripts/bootstrap.sh [--plan|--apply]

--plan   Show what would run (default).
--apply  Install Brewfile packages and mise tools. Does not install Homebrew,
         alter dotfiles, remove packages, clean caches, or uninstall Nix.
EOF
}

case "${1:---plan}" in
  --plan) MODE="plan" ;;
  --apply) MODE="apply" ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
  echo "This setup supports Apple Silicon macOS only." >&2
  exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools are required. Run: xcode-select --install" >&2
  exit 1
fi

if [[ ! -x /opt/homebrew/bin/brew ]]; then
  cat >&2 <<'EOF'
Homebrew is not installed at /opt/homebrew.
Review and install it manually from https://brew.sh, then rerun this script.
Homebrew installation remains manual. Bootstrap later runs OMP's official installer.
EOF
  exit 1
fi

cat <<EOF
Repository: $ROOT
Planned commands:
  HOMEBREW_BUNDLE_NO_UPGRADE=1 /opt/homebrew/bin/brew bundle --file "$ROOT/Brewfile"
  MISE_GLOBAL_CONFIG_FILE="$MISE_CONFIG" /opt/homebrew/bin/mise install
  /opt/homebrew/bin/bun add --global @anthropic-ai/claude-code
  curl -fsSL https://omp.sh/install | PI_INSTALL_DIR="$HOME/.local/bin" sh -s -- --binary
  install -m 600 "$OMP_CONFIG_SOURCE" "$OMP_CONFIG_TARGET"  # only when target is absent

Dotfiles, shared agent skills, and macOS settings are separate, explicit steps.
The dotfile installer links the versioned ~/.agents skill store for OMP, Codex,
and Claude Code. Nothing here removes packages or uninstalls Nix.
EOF

[[ "$MODE" == "plan" ]] && exit 0

cd "$ROOT" || exit 1
HOMEBREW_BUNDLE_NO_UPGRADE=1 /opt/homebrew/bin/brew bundle --file "$ROOT/Brewfile" || exit 1
# Point mise at the repository copy so this works before the dotfile symlinks
# exist; install-dotfiles.sh links it to ~/.config/mise/config.toml afterwards.
MISE_GLOBAL_CONFIG_FILE="$MISE_CONFIG" /opt/homebrew/bin/mise install || exit 1

# Claude Code remains a Bun global package. OMP 18+ uses its signed standalone
# binary installer and reads the shared ~/.agents/skills directory.
/opt/homebrew/bin/bun add --global @anthropic-ai/claude-code || exit 1
curl -fsSL https://omp.sh/install | PI_INSTALL_DIR="$HOME/.local/bin" sh -s -- --binary || exit 1

# Restore the sanitized OMP configuration only on a fresh machine. Never
# overwrite a live config because OMP owns it and writes it atomically.
if [[ ! -e "$OMP_CONFIG_TARGET" ]]; then
  mkdir -p "$(dirname "$OMP_CONFIG_TARGET")" || exit 1
  install -m 600 "$OMP_CONFIG_SOURCE" "$OMP_CONFIG_TARGET" || exit 1
  echo "Restored OMP config from $OMP_CONFIG_SOURCE"
else
  echo "Preserved existing OMP config at $OMP_CONFIG_TARGET"
fi

cat <<'EOF'
Package installation complete.
Next, inspect dotfile conflicts with:
  ./scripts/install-dotfiles.sh --dry-run
EOF
