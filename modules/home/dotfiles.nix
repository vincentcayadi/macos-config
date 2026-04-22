{ config, ... }:
let
  # mkOutOfStoreSymlink creates a regular symlink to a path on disk
  # (not through the read-only nix store). Required for any config
  # directory that the tool itself writes state into at runtime.
  link = path:
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/configs/${path}";
in {
  # Mutable configs — tools write state into these dirs, so they must
  # be live symlinks into the working nix-config tree, not nix store copies.
  home.file.".config/nvim".source = link "nvim";
  home.file.".config/btop".source = link "btop";
  home.file.".config/thefuck".source = link "thefuck";

  # Immutable configs — read-only at runtime, safe to copy into nix store.
  home.file.".config/fastfetch".source = ../../configs/fastfetch;
  home.file.".config/starship.toml".source = ../../configs/starship.toml;
  home.file.".tmux.conf".source = ../../configs/.tmux.conf;
  home.file.".aerospace.toml".source = ../../configs/.aerospace.toml;
}
