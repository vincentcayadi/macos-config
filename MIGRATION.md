# Nix to conventional macOS migration

This repository now contains a parallel Homebrew, mise, and dotfiles setup. The
existing Nix files and `configs/` tree remain untouched so the migration can be
tested before changing the live system.

## Safety rules

- No included script uninstalls Nix or deletes `/nix`.
- No included script runs `brew cleanup`, `brew autoremove`, or removes caches.
- Dotfile installation defaults to a dry run.
- Existing dotfiles are never overwritten. `--backup` requires interactive
  approval and moves conflicts into `~/.dotfiles-backups/<timestamp>/`.
- Homebrew itself is never installed through an unattended remote script.
- PostgreSQL data, Ollama models, credentials, and application data are not
  modified.

## What is managed

- `Brewfile`: Homebrew formulae, casks, fonts, and Mac App Store applications.
- `mise.toml`: Bun, Go, Node LTS, Python, and stable pay-respects.
- `dotfiles/`: zsh, Git, Neovim, tmux, AeroSpace, btop, fastfetch, and Starship.
- `scripts/setup-macos.sh`: intentionally makes no changes because the audited
  Nix repository contained no macOS defaults.

Deno and pnpm are intentionally on demand:

```sh
mise x deno@latest -- deno --version
mise x pnpm@latest -- pnpm --version
```

`nix-index`, `nix-locate`, and `nix-direnv` have no role in the final setup.
Normal Homebrew `direnv` replaces the shell integration. Nix-specific project
`.envrc` files must be migrated separately.

## Clean Mac bootstrap

1. Install the Xcode Command Line Tools:

   ```sh
   xcode-select --install
   ```

2. Review and install Homebrew manually from <https://brew.sh>.
3. Sign in to the Mac App Store if MAS applications are wanted.
4. Clone this repository.
5. Preview package installation:

   ```sh
   ./scripts/bootstrap.sh --plan
   ```

6. Install packages and mise tools:

   ```sh
   ./scripts/bootstrap.sh --apply
   ```

The bootstrap installs missing software but does not remove packages, alter
live dotfiles, apply preferences, or touch Nix.

## Dotfile migration

First inspect every destination:

```sh
./scripts/install-dotfiles.sh --dry-run
```

Create links only if no conflicts exist:

```sh
./scripts/install-dotfiles.sh --apply
```

On the existing Nix-managed Mac, conflicts are expected because Home Manager
owns the current links. After reviewing the list, explicitly back them up:

```sh
./scripts/install-dotfiles.sh --backup
```

The script asks for confirmation and moves conflicts to a timestamped backup.
It does not delete the backups.

Open a new terminal and confirm that commands resolve through `/opt/homebrew`
or mise rather than `/nix` or `/etc/profiles`.

## Verification

```sh
./scripts/verify-migration.sh
brew outdated
mise current
mise outdated
```

Neovim plugins and language servers are managed by Neovim and Mason. Open
Neovim and review:

```vim
:checkhealth
:Mason
```

Also verify manually:

- Git Credential Manager can authenticate.
- PostgreSQL 17 data is backed up before any service or major-version change.
- `ollama list` shows the expected models, if models were restored separately.
- AeroSpace monitor assignments match the current hardware.
- App Store and cask applications launch successfully.
- Project `.envrc` files no longer depend on `nix-direnv`.

## Update policy

Homebrew packages track current stable Homebrew versions. mise uses `latest`
for Bun, Go, and Python, and `lts` for Node. `pay-respects` is pinned to stable
`0.8.8`; update that version deliberately after reviewing a stable release.

Run updates explicitly:

```sh
brew update
brew upgrade
mise upgrade
```

No automatic cleanup is performed.

## Final Nix retirement

The intended final state contains no Nix. Retirement is deliberately not
automated here.

Only after the verification script passes and the Brew setup has worked for
several days:

1. Confirm no command resolves through `/nix` or `/etc/profiles`.
2. Confirm no projects still require `nix-direnv`, `nix develop`, or Nix shells.
3. Confirm dotfile backups exist and the new links work after reboot.
4. Back up any Nix-only data or configuration still needed.
5. Review the official uninstallation procedure for the installed Nix
   distribution, especially Determinate Nix.
6. Perform uninstallation only with explicit human approval.

There is intentionally no Nix-uninstall or `/nix` deletion command in this
repository.
