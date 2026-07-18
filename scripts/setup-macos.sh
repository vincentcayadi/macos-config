#!/bin/bash
set -u

# The Nix repository declares no macOS defaults. This intentionally makes no
# preference changes instead of inventing settings that were never configured.

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
  echo "This setup supports Apple Silicon macOS only." >&2
  exit 1
fi

cat <<'EOF'
No macOS defaults were present in the audited Nix configuration.
No settings changed. Add reviewed, idempotent defaults commands here later.
EOF
