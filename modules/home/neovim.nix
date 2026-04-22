{ ... }: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    # Plugin management and full config live in configs/nvim/ (lazy.nvim).
    # Managed via home.file in dotfiles.nix — no config generated here.
  };
}
