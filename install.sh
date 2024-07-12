#!/bin/zsh

# Install XCode CLI Tools
xcode-select --install

# Homebrew Install
echo "Installing Homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew analytics off

echo "Installing Apps"

# Essentials
brew install neovim
brew install starship
brew install zsh-autosuggestions
brew install zsh-syntax-highlighting
brew install thefuck
brew install eza
brew install ffmpeg
brew install git
brew install nvm
brew install pnpm
brew install --cask git-credential-manager
brew install supabase/tap/supabase
brew install --cask zed


# Terminals & Browsers
brew install --cask arc
brew install --cask kitty

# Office/School
brew install --cask zoom
brew install --cask figma
brew install --cask google-drive
brew install --cask microsoft-auto-update
brew install --cask microsoft-office

# Nice to have
brew install --cask raycast
brew install --cask balenaetcher
brew install --cask orcaslicer
brew install --cask playcover-community-beta
brew install --cask transmission
brew install --cask handbrake

# Fonts
brew install --cask font-victor-mono

# Socials
brew install --cask discord
brew install --cask telegram
brew install --cask whatsapp

# Clean up
brew cleanup

echo "Installation completed."
