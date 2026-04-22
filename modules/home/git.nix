{ ... }: {
  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = "Vincent Cayadi";
    userEmail = "57314503+vincentcayadi@users.noreply.github.com";

    extraConfig = {
      # git-credential-manager installed as a Homebrew cask.
      # Empty string first entry clears any system-level helper.
      credential.helper = [
        ""
        "/usr/local/share/gcm-core/git-credential-manager"
      ];

      # Azure DevOps needs the full path in the credential key
      "credential \"https://dev.azure.com\"".useHttpPath = true;
    };
  };
}
