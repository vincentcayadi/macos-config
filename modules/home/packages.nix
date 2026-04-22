{ pkgs, ... }: {
  # CLI packages from nixpkgs.
  # Packages managed by programs.* modules (git, neovim, fzf, zoxide,
  # direnv, starship, zsh) are intentionally omitted here.
  home.packages = with pkgs; [
    # Terminal tools
    bat
    btop
    cloc
    eza
    fastfetch
    lazygit
    tmux

    # Search & dev utilities
    ripgrep
    tree-sitter
    git-filter-repo

    # Media
    ffmpeg
    yt-dlp
    typst

    # Language runtimes & package managers
    bun
    deno
    nodejs        # current LTS; pin to nodejs_22 if you need a specific version
    pnpm
    go
    python312
    python313
    # python314  # uncomment once available in nixpkgs-unstable

    # Cloud & infrastructure
    cloudflared
    gh            # GitHub CLI
    glab          # GitLab CLI

    # Build tools
    cmake
    ninja
    pkg-config

    # Hardware / embedded libraries
    libusb1
    portaudio
    SDL2

    # Databases (CLI tools only; migrate data separately from brew's postgres)
    postgresql_17

    # AI / ML
    ollama        # darwin: uses Metal via nixpkgs; verify with `ollama list`

    # Misc
    p7zip
    curl
    ruff
    mas           # Mac App Store CLI (used by nix-darwin homebrew module too)
    thefuck

    # HPC (openmpi replaces brew open-mpi)
    openmpi
  ];
}
