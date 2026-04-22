{ ... }: {
  imports = [
    ./shell.nix
    ./packages.nix
    ./git.nix
    ./neovim.nix
    ./dotfiles.nix
  ];

  home.username = "vincent";
  home.homeDirectory = "/Users/vincent";

  # Must match the home-manager release used — bump after reading migration notes
  home.stateVersion = "24.11";
}
