#!/bin/bash
# Update and rebuild optimized software
# Run this periodically to get latest versions

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Updating optimized software...${NC}"

# Source cargo if not in PATH
if ! command -v cargo &> /dev/null; then
    source "$HOME/.cargo/env"
fi

# Ripgrep
echo ""
echo -e "${YELLOW}[1/2] Updating ripgrep...${NC}"
cd ~/developer/ripgrep
if git pull | grep -q "Already up to date"; then
    echo -e "${GREEN}ripgrep already up to date, skipping build${NC}"
else
    RUSTFLAGS="-C opt-level=3 -C target-cpu=native" cargo build --release --jobs 8
    cp target/release/rg ~/.local/bin/rg
    cargo clean
    echo -e "${GREEN}ripgrep rebuilt and cleaned${NC}"
fi

# Neovim
echo ""
echo -e "${YELLOW}[2/2] Updating Neovim...${NC}"
cd ~/developer/neovim
if git pull | grep -q "Already up to date"; then
    echo -e "${GREEN}Neovim already up to date, skipping build${NC}"
else
    make distclean 2>/dev/null || true
    make CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$HOME/.local -DCMAKE_C_FLAGS=-march=native" -j8
    make install
    make distclean 2>/dev/null || true
    echo -e "${GREEN}Neovim rebuilt and cleaned${NC}"
fi

# System cleanup
echo ""
echo -e "${YELLOW}[3/3] Cleaning up...${NC}"
brew upgrade && brew update
brew autoremove && brew cleanup --prune=all -s
rm -rf ~/Library/Caches/Homebrew
echo -e "${GREEN}System cleaned${NC}"

echo ""
echo -e "${BLUE}All done! Optimized binaries updated:${NC}"
echo "  - ripgrep: $(~/.local/bin/rg --version | head -1)"
echo "  - neovim: $(~/.local/bin/nvim --version | head -1)"
echo "  - cache: $(du -sh ~/Library/Caches 2>/dev/null | cut -f1) remaining"
