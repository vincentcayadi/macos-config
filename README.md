# macos-config

Apple Silicon macOS setup: Homebrew for packages and applications, mise for
Python and a few standalone binaries, and plain symlinks for dotfiles.

## Layout

| Path | Purpose |
| --- | --- |
| `Brewfile` | Formulae, casks, fonts, and Mac App Store apps. |
| `dotfiles/` | Everything symlinked into `$HOME`. |
| `dotfiles/.config/mise/config.toml` | Global mise tools. Always active. |
| `scripts/bootstrap.sh` | Installs Brewfile packages, mise tools, and the pi agent. |
| `scripts/install-dotfiles.sh` | Creates the `$HOME` symlinks. |
| `scripts/setup-macos.sh` | Intentionally a no-op; no macOS defaults are managed. |
| `scripts/verify-migration.sh` | Asserts nothing resolves through Nix and links are correct. |

## Tool ownership

Exactly one source per tool, so nothing shadows anything else:

- **Homebrew** owns `node`, `bun`, `go`, and every other CLI, cask, and font.
- **mise** owns `python` and `pay-respects` (the latter has no Homebrew formula
  and is evaluated by `.zshrc` on every shell start, so it must be global).
- **Claude Code** installs its own standalone binary into `~/.local/bin` and is
  not managed here.
- **pi** is a global npm package in Homebrew's node prefix. A major `node`
  upgrade can orphan it; rerunning `bootstrap.sh --apply` reinstalls it.

Rarely used runtimes stay on demand rather than on PATH:

```sh
mise x deno@latest -- deno --version
mise x pnpm@latest -- pnpm --version
```

## Fresh machine

1. `xcode-select --install`
2. Install Homebrew manually from <https://brew.sh>.
3. Sign in to the Mac App Store if MAS apps are wanted.
4. Clone this repository to `~/macos-config`.
5. `./scripts/bootstrap.sh --plan` then `./scripts/bootstrap.sh --apply`
6. `./scripts/install-dotfiles.sh --dry-run` then `--apply`
7. `./scripts/verify-migration.sh`

`--apply` refuses to run if any destination already exists. Use `--backup` to
move conflicts into `~/.dotfiles-backups/<timestamp>/` after confirming; nothing
is ever deleted.

## Updating

No automatic cleanup runs anywhere. Update deliberately:

```sh
brew update && brew upgrade && mise upgrade
```

The `brewclean` shell function wraps the same three commands.

## Verifying

```sh
./scripts/verify-migration.sh
brew bundle check --file Brewfile
mise current
```

Neovim plugins and language servers are managed by Neovim and Mason, not here:
run `:checkhealth` and `:Mason`.

Also confirm manually after any large change:

- Git Credential Manager authenticates.
- PostgreSQL 17 data is backed up before any service or major-version change.
- `ollama list` shows the expected models.
- AeroSpace monitor assignments match the current hardware.

## Remaining Nix retirement

This machine still has Determinate Nix and nix-darwin installed. They no longer
provide any tool on PATH, but nix-darwin still owns `/etc/zshrc`, `/etc/zprofile`,
`/etc/zshenv`, and `/etc/bashrc`, which are symlinks into `/etc/static` and then
into the Nix store.

**Order matters.** Removing `/nix` before releasing those files leaves every
login shell pointing at dangling symlinks.

1. Confirm `verify-migration.sh` passes and `brew bundle check` succeeds.
2. Confirm no project needs `nix develop` or `nix-direnv`: grep `~/developer`
   for `.envrc` files referencing `use nix` or `use flake`.
3. Run `darwin-uninstaller`. This restores the `/etc` files from their
   `.before-nix-darwin` backups.
4. Open a new terminal and confirm it works. Reboot and confirm again.
5. Remove the home-manager generations under `~/.local/state/nix/profiles/`.
6. Run the **Determinate Nix** uninstaller — Determinate's own documented
   procedure, not the upstream one.
7. Confirm `/etc/synthetic.conf` and `/etc/fstab` no longer reference the Nix
   volume, then reboot.

There is deliberately no automated Nix-uninstall command in this repository.
