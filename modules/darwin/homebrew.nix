{ ... }: {
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;  # run brew update manually via brewclean
      upgrade = false;
      # Set to "uninstall" once migration is stable to enforce declarative state
      cleanup = "none";
    };

    taps = [
      "nikitabobko/tap"
    ];

    # Formulas not available in nixpkgs
    brews = [
      "mlx"      # Apple MLX framework — not in nixpkgs
      "mlx-c"    # C bindings for MLX — not in nixpkgs
      "mongosh"  # MongoDB shell — not in nixpkgs (proprietary)
    ];

    # GUI apps and drivers — kept in Homebrew since nixpkgs lacks darwin GUI support
    casks = [
      "aerospace"
      "affinity"
      "appcleaner"
      "arc"
      "balenaetcher"
      "battery-toolkit"
      "betterdisplay"
      "dorion"
      "font-lora"
      "font-monaspace"
      "ghostty"
      "git-credential-manager"
      "google-drive"
      "handbrake-app"
      "iina"
      "keycastr"
      "kicad"
      "microsoft-auto-update"
      "microsoft-office"
      "obsidian"
      "orbstack"
      "orcaslicer"
      "raycast"
      "shottr"
      "transmission"
      "wireshark-app"
      "zed"
    ];

    masApps = {
      "AdGuard for Safari" = 1440147259;
      "Fonts Ninja" = 1480227114;
      "TestFlight" = 899247664;
      "The Unarchiver" = 425424353;
      "WhatsApp" = 310633997;
    };
  };
}
