{ pkgs, ... }: {
  imports = [ ./homebrew.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  # Determinate Nix manages its own daemon — disable nix-darwin's Nix management
  nix.enable = false;

  # Minimal system packages — most packages live in home-manager
  environment.systemPackages = [ pkgs.git ];

  # Set zsh as the default shell system-wide
  programs.zsh.enable = true;

  users.users.vincent = {
    home = "/Users/vincent";
    shell = pkgs.zsh;
  };

  # Required by nix-darwin for options that apply to a specific user (e.g. homebrew)
  system.primaryUser = "vincent";

  # Required: tracks state version across darwin-rebuild generations
  system.stateVersion = 5;
}
