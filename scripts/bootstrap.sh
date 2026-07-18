#!/bin/bash
set -u

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
MISE_CONFIG="$ROOT/dotfiles/.config/mise/config.toml"
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
No remote installer will be executed automatically.
EOF
  exit 1
fi

cat <<EOF
Repository: $ROOT
Planned commands:
  HOMEBREW_BUNDLE_NO_UPGRADE=1 /opt/homebrew/bin/brew bundle --file "$ROOT/Brewfile"
  MISE_GLOBAL_CONFIG_FILE="$MISE_CONFIG" /opt/homebrew/bin/mise install
  /opt/homebrew/bin/npm install -g @earendil-works/pi-coding-agent

Dotfiles and macOS settings are separate, explicit steps.
Claude Code ships its own standalone installer into ~/.local/bin and is not
managed here. Nothing in this script uninstalls packages or removes Nix.
EOF

[[ "$MODE" == "plan" ]] && exit 0

cd "$ROOT" || exit 1
HOMEBREW_BUNDLE_NO_UPGRADE=1 /opt/homebrew/bin/brew bundle --file "$ROOT/Brewfile" || exit 1
# Point mise at the repository copy so this works before the dotfile symlinks
# exist; install-dotfiles.sh links it to ~/.config/mise/config.toml afterwards.
MISE_GLOBAL_CONFIG_FILE="$MISE_CONFIG" /opt/homebrew/bin/mise install || exit 1

# The pi coding agent is a global npm package living in Homebrew's node prefix,
# so a `brew upgrade node` across a major version can orphan it. Reinstalling
# here is idempotent and is the documented recovery if `pi` stops launching.
/opt/homebrew/bin/npm install -g @earendil-works/pi-coding-agent || exit 1

cat <<'EOF'
Package installation complete.
Next, inspect dotfile conflicts with:
  ./scripts/install-dotfiles.sh --dry-run
EOF
