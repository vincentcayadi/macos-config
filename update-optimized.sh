#!/bin/bash
# Update and rebuild optimized software
# Run this periodically to get latest versions

set -e

echo "Updating optimized software..."

# Ripgrep
echo "\n[1/2] Updating ripgrep..."
cd ~/developer/ripgrep
git pull
RUSTFLAGS="-C opt-level=3 -C target-cpu=native" cargo build --release --jobs 8
cp target/release/rg ~/.local/bin/rg
cargo clean
echo "ripgrep updated and cleaned"

# Neovim
echo "\n[2/2] Updating Neovim..."
cd ~/developer/neovim
git pull
make distclean 2>/dev/null || true
make CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$HOME/.local -DCMAKE_C_FLAGS=-march=native" -j8
make install
make distclean 2>/dev/null || true
echo "Neovim updated and cleaned"

echo "\nAll done! Optimized binaries updated:"
echo "  - ripgrep: $(~/.local/bin/rg --version | head -1)"
echo "  - neovim: $(~/.local/bin/nvim --version | head -1)"
