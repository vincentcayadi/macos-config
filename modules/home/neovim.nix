{ ... }: {
  programs.neovim = {
    enable = true;
		sideloadInitLua = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    withRuby = false;
    withPython3 = false;
    # Plugin management and full config live in configs/nvim/ (lazy.nvim).
    # Managed via home.file in dotfiles.nix — no config generated here.
  };
}
