#!/bin/bash

# Master Setup Script for New Mac
# Run this after cloning macos-config repo

set -e

DOTFILES_DIR="$HOME/developer/macos-config"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo "╔════════════════════════════════════════════════╗"
echo "║   macOS Setup Script - Vincent's Config       ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

# Check if we're in the right directory
if [ ! -f "$DOTFILES_DIR/Brewfile" ]; then
    echo "✗ Error: Run this from ~/developer/macos-config"
    echo "  or make sure Brewfile exists"
    exit 1
fi

cd "$DOTFILES_DIR"

# ===== STEP 1: XCODE CLI TOOLS =====
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 1: XCode Command Line Tools"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if ! xcode-select -p &> /dev/null; then
    echo "Installing XCode CLI Tools..."
    xcode-select --install
    echo ""
    echo "⚠️  Please wait for XCode CLI tools to finish installing"
    echo "   Then run this script again."
    echo ""
    read -p "Press Enter when installation is complete..."
else
    echo "✓ XCode CLI Tools already installed"
fi

echo ""

# ===== STEP 2: HOMEBREW =====
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 2: Homebrew"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [ -f "/opt/homebrew/bin/brew" ]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    
    brew analytics off
    echo "✓ Homebrew installed"
else
    echo "✓ Homebrew already installed"
    brew analytics off
fi

echo ""

# ===== STEP 3: INSTALL PACKAGES =====
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 3: Installing Packages"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f "$DOTFILES_DIR/Brewfile" ]; then
    echo "Installing from Brewfile..."
    brew bundle --file="$DOTFILES_DIR/Brewfile"
    echo "✓ Packages installed"
else
    echo "⚠️  Brewfile not found, skipping package installation"
fi

echo ""

# ===== STEP 4: CREATE SYMLINKS =====
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 4: Creating Symlinks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to create symlink with backup
create_symlink() {
    local source="$1"
    local target="$2"
    local name="$3"
    
    # Skip if source doesn't exist
    if [ ! -e "$source" ]; then
        return
    fi
    
    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"
    
    # Backup existing file/directory if it exists and is not a symlink
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "  Backing up existing: $target"
        cp -r "$target" "$BACKUP_DIR/"
        rm -rf "$target"
    fi
    
    # Remove existing symlink if it exists
    if [ -L "$target" ]; then
        rm "$target"
    fi
    
    # Create symlink
    ln -sf "$source" "$target"
    echo "  ✓ $name"
}

echo "Creating symlinks..."
echo ""

# ZSH
create_symlink "$DOTFILES_DIR/zshrc" "$HOME/.zshrc" "ZSH config"

# Git
create_symlink "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig" "Git config"
create_symlink "$DOTFILES_DIR/.gitignore" "$HOME/.gitignore_global" "Git ignore"

# Starship
create_symlink "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml" "Starship prompt"

# Tmux
create_symlink "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf" "Tmux config"

# AeroSpace
create_symlink "$DOTFILES_DIR/.aerospace.toml" "$HOME/.aerospace.toml" "AeroSpace config"

# Neovim
create_symlink "$DOTFILES_DIR/nvim" "$HOME/.config/nvim" "Neovim config"

# Zed
create_symlink "$DOTFILES_DIR/zed" "$HOME/.config/zed" "Zed config"

# btop
create_symlink "$DOTFILES_DIR/btop" "$HOME/.config/btop" "btop config"

# fastfetch
create_symlink "$DOTFILES_DIR/fastfetch" "$HOME/.config/fastfetch" "fastfetch config"

# thefuck
create_symlink "$DOTFILES_DIR/thefuck" "$HOME/.config/thefuck" "thefuck config"

# Newsboat
if [ -d "$DOTFILES_DIR/.newsboat" ]; then
    create_symlink "$DOTFILES_DIR/.newsboat" "$HOME/.newsboat" "Newsboat config"
elif [ -d "$DOTFILES_DIR/newsboat" ]; then
    create_symlink "$DOTFILES_DIR/newsboat" "$HOME/.config/newsboat" "Newsboat config"
fi

# Claude folder
create_symlink "$DOTFILES_DIR/claude" "$HOME/claude" "Claude folder"

echo ""

# ===== STEP 5: POST-INSTALL =====
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 5: Post-Install Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Set git global excludesfile
if [ -f "$HOME/.gitignore_global" ]; then
    git config --global core.excludesfile "$HOME/.gitignore_global"
    echo "✓ Git global ignore configured"
fi

# Install FZF key bindings
if command -v fzf &> /dev/null; then
    echo "Setting up FZF key bindings..."
    $(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish
    echo "✓ FZF configured"
fi

# Source zsh config
echo "✓ Sourcing .zshrc..."
source "$HOME/.zshrc" 2>/dev/null || true

echo ""

# ===== SUMMARY =====
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ SETUP COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if backup directory is empty
if [ -z "$(ls -A "$BACKUP_DIR")" ]; then
    rmdir "$BACKUP_DIR"
    echo "No files were backed up (fresh setup)"
else
    echo "Original files backed up to: $BACKUP_DIR"
fi

echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: source ~/.zshrc)"
echo "  2. Check symlinks: ls -la ~/ | grep '@'"
echo "  3. Verify configs work"
echo ""
echo "Optional:"
echo "  - Install TPM for tmux plugins:"
echo "    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
echo ""
echo "You're all set! 🚀"
echo ""
