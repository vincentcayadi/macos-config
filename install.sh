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
brew install --cask zed
brew install --cask appcleaner
brew install --cask keycastr
brew install --cask insomnia
brew install --cask kicad
brew install aerospace
brew install borders

# Terminals & Browsers
brew install --cask arc
brew install --cask ghostty

# Office/School
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
brew install --cask iina

# Socials
brew install --cask legcord
brew install --cask telegram
brew install --cask whatsapp

# Clean up
brew cleanup

echo "Installation completed."
