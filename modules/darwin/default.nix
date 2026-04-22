{ pkgs, ... }: {
  imports = [ ./homebrew.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  # Nix daemon settings
  nix.settings = {
    experimental-features = "nix-command flakes";
    trusted-users = [ "root" "@admin" "vincent" ];
  };

  # Minimal system packages — most packages live in home-manager
  environment.systemPackages = [ pkgs.git ];

  # Set zsh as the default shell system-wide
  programs.zsh.enable = true;

  users.users.vincent = {
    home = "/Users/vincent";
    shell = pkgs.zsh;
  };

  # Required: tracks state version across darwin-rebuild generations
  system.stateVersion = 5;
}
