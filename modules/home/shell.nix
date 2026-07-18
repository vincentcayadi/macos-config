{ config, ... }: {
  # PATH additions — prepended in order
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "/opt/homebrew/opt/ncurses/bin"
  ];

  programs.zsh = {
    enable = true;

    history = {
      path = "${config.home.homeDirectory}/.histfile";
      size = 10000;
      save = 10000;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
    };

    # Plugins sourced automatically from nixpkgs
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Custom compinit to control zcompdump location
    completionInit = ''
      [[ -d "$HOME/.cache/zsh" ]] || mkdir -p "$HOME/.cache/zsh"
      autoload -Uz compinit
      compinit -d "$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"
    '';

    initContent = ''
      # History options not exposed as home-manager settings
      setopt HIST_FIND_NO_DUPS
      setopt HIST_REDUCE_BLANKS

      # Completion styles
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

      # Bun completions
      [[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

      # pay-respects: press f to fix last command (replaces thefuck)
      command -v pay-respects >/dev/null 2>&1 && eval "$(pay-respects zsh --alias)"

      sysclean() {
        echo "Updating Nix flake inputs..."
        (cd ~/nix-config && nix flake update) &&
        echo "Rebuilding macOS configuration..."
        sudo darwin-rebuild switch --flake ~/nix-config#amaterasu &&
        echo "Cleaning old Nix generations..."
        nix-collect-garbage -d &&
        echo "Done."
      }

      brewclean() {
        echo "Updating Homebrew..."
        brew update &&
        brew upgrade &&
        brew autoremove &&
        brew cleanup --prune=all -s &&
        rm -rf "$HOME/Library/Caches/Homebrew" &&
        echo "Done."
      }
    '';

    shellAliases = {
      # File management
      ls = "eza -alh --icons --group-directories-first";
      lt = "eza -aT --icons --group-directories-first";
      cat = "bat --paging=never";

      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      home = "cd ~";
      dev = "cd ~/developer";
      config = "cd ~/nix-config";

      # Media
      yt = "yt-dlp";
      yta = "yt-dlp -x --embed-metadata --audio-format m4a";
      ytv = "yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best'";

      # Git
      g = "git";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull --rebase";
      gd = "git diff";
      gb = "git checkout";
      lg = "lazygit";

      # Dev
      v = "nvim";
      zz = "source ~/.zshrc";
    };

  };

  # Tool integrations — each program module adds its own zsh init snippet
  programs.starship = {
    enable = true;
    # Config file is managed via dotfiles.nix (home.file)
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
