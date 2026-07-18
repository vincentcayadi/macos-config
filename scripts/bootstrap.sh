#!/bin/bash
set -u

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
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
  cd "$ROOT" && /opt/homebrew/bin/mise install

Dotfiles and macOS settings are separate, explicit steps.
Nothing in this script uninstalls packages or removes Nix.
EOF

[[ "$MODE" == "plan" ]] && exit 0

cd "$ROOT" || exit 1
HOMEBREW_BUNDLE_NO_UPGRADE=1 /opt/homebrew/bin/brew bundle --file "$ROOT/Brewfile" || exit 1
/opt/homebrew/bin/mise install || exit 1

cat <<'EOF'
Package installation complete.
Next, inspect dotfile conflicts with:
  ./scripts/install-dotfiles.sh --dry-run
EOF
