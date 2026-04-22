{ ... }: {
  programs.git = {
    enable = true;
    userName = "Vincent Cayadi";
    userEmail = "57314503+vincentcayadi@users.noreply.github.com";

    lfs.enable = true;

    extraConfig = {
      # git-credential-manager is installed as a Homebrew cask;
      # the empty string first entry clears any system-level helper.
      credential.helper = [
        ""
        "/usr/local/share/gcm-core/git-credential-manager"
      ];

      # Codeberg uses the generic credential provider (not GCM's OAuth flow)
      "credential \"https://codeberg.org\"".provider = "generic";

      # Azure DevOps needs the full path in the credential key
      "credential \"https://dev.azure.com\"".useHttpPath = true;
    };
  };
}
