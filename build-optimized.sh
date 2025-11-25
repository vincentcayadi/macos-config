#!/bin/bash
# Build optimized versions of ripgrep and Neovim from source
# These are compiled with CPU-specific optimizations for better performance

set -e

echo "Building optimized software from source..."

# Ripgrep
echo "\n[1/2] Building ripgrep..."
cd ~/developer/ripgrep
git pull
RUSTFLAGS="-C opt-level=3 -C target-cpu=native" cargo build --release --jobs 8
cp target/release/rg ~/.local/bin/rg
echo "ripgrep installed to ~/.local/bin/rg"

# Neovim
echo "\n[2/2] Building Neovim..."
cd ~/developer/neovim
git pull
make distclean 2>/dev/null || true
make CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$HOME/.local -DCMAKE_C_FLAGS=-march=native" -j8
make install
echo "Neovim installed to ~/.local/bin/nvim"

echo "\nAll done! Optimized binaries:"
echo "  - ripgrep: $(which rg)"
echo "  - neovim: $(which nvim)"
