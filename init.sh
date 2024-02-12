#!/bin/bash

echo "Creating symbolic links..."

# Create symbolic links for folders
ln -s "/Users/vincent/developer/macos-config/kitty" "/Users/vincent/.config/kitty" || echo "Failed to create symlink for kitty folder"
ln -s "/Users/vincent/developer/macos-config/cava" "/Users/vincent/.config/cava" || echo "Failed to create symlink for cava folder"
ln -s "/Users/vincent/developer/macos-config/neofetch" "/Users/vincent/.config/neofetch" || echo "Failed to create symlink for neofetch folder"
ln -s "/Users/vincent/developer/macos-config/nvim" "/Users/vincent/.config/nvim" || echo "Failed to create symlink for nvim folder"
ln -s "/Users/vincent/developer/macos-config/skhd" "/Users/vincent/.config/skhd" || echo "Failed to create symlink for skhd folder"
ln -s "/Users/vincent/developer/macos-config/spicetify" "/Users/vincent/.config/spicetify" || echo "Failed to create symlink for spicetify folder"
ln -s "/Users/vincent/developer/macos-config/thefuck" "/Users/vincent/.config/thefuck" || echo "Failed to create symlink for thefuck folder"
ln -s "/Users/vincent/developer/macos-config/yarn" "/Users/vincent/.config/yarn" || echo "Failed to create symlink for yarn folder"

# Create symbolic link for files
ln -s "/Users/vincent/developer/macos-config/starship.toml" "/Users/vincent/.config/starship.toml" || echo "Failed to create symlink for starship.toml"
ln -s "/Users/vincent/developer/macos-config/.zshrc" "/Users/vincent/.zshrc" || echo "Failed to create symlink for .zshrc"

echo "Symbolic links created."

# Source the .zshrc file
source "/Users/vincent/.zshrc"