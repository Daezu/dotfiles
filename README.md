# dotfiles

Niklas Böer's personal dotfiles and machine setup for a Hyprland-based Linux desktop, provisioned with Ansible.

## What's in here

| App/Tool | Config |
| --- | --- |
| [Hyprland](https://hyprland.org/) | `.config/hypr` — window manager config (Lua), lock screen, wallpaper daemon, helper scripts |
| [Waybar](https://github.com/Alexays/Waybar) | `.config/waybar` |
| [Kitty](https://sw.kovidgoyal.net/kitty/) | `.config/kitty` |
| [Neovim](https://neovim.io/) | `.config/nvim` |
| Zsh | `.config/zsh` — aliases, keybindings, [fzf](https://github.com/junegunn/fzf), plugin loader, [Starship](https://starship.rs/) prompt |
| [Yazi](https://yazi-rs.github.io/) | `.config/yazi` |
| [Matugen](https://github.com/InioX/matugen) | `.config/matugen` — Material You theming/templating across apps |
| GTK 3/4 | `.config/gtk-3.0`, `.config/gtk-4.0`, `.config/nwg-look` |
| WirePlumber | `.config/wireplumber` |

Zsh is configured via `ZDOTDIR`, so `~/.zshrc`/`~/.zshenv` stay out of `$HOME` and live under `.config/zsh` like everything else.

## Installing

Everything is driven by a small Ansible playbook under `install/`; `install.sh` is a thin CLI wrapper around it.

```sh
./install.sh
```

This symlinks every top-level entry in this repo (and every CLI app folder under `.config/`) into the right place under `$HOME`, installing any missing CLI dependencies (`eza`, `bat`, `fd`, `starship`, `yazi`, `nvim`, `rustup`, `nvm`/Node, …) along the way. Anything already present at a destination gets backed up first, under `~/.dotfiles_backup/<timestamp>/`.

Shared tools are installed with sudo through apt/pacman. Missing Yazi, Tree-sitter, uv, and Devsy executables use upstream releases installed as root under `/usr/local/bin`. Downloads are staged in a private temporary directory and removed afterward. Existing installations under `~/.local/bin` are preserved and can still take precedence in your PATH.

NVM, Node, pnpm, Zsh plugins, and optional Rust toolchains are set up separately for the target user. Editor plugins, caches, credentials, Podman storage, and Devsy configuration remain in that user's home. An existing `NVM_DIR` is respected, including in devcontainers.

After installing the system tools from your main account, install the configuration and user tools for `dev` without sudo:

```sh
sudo -iu dev
/srv/dotfiles/install.sh --skip-packages --skip-env
```

This still installs the per-user tools and can download Node and plugins. With both skip flags, the installer does not ask for a sudo password.

By default only CLI-relevant stuff is set up, so the same command works on servers and devcontainers. On a desktop, add `--gui` to also set up the graphical side (Hyprland, Waybar, Kitty, GTK, ...):

```sh
./install.sh --gui
```

GUI-only work is flagged with the Ansible tag `gui`; without `--gui`, `install.sh` runs the playbook with `--skip-tags gui`. To make something GUI-only, add `tags: [gui]` to its task, or — for a config folder under `.config/` — add its name to `dotfiles_gui_names` in `install/roles/dotfiles/defaults/main.yml`.

### Options

```
./install.sh [--symlink|--copy] [--gui] [--rust] [--skip-packages] [--skip-env] [-i HOST] [-p PORT] [-u USER] [--local-file=PATH]
             [--pnpm-version VERSION]

  --symlink        Symlink dotfiles into $HOME (default)
  --copy           Copy dotfiles into $HOME instead of symlinking
  --gui            Also set up GUI stuff (tasks tagged 'gui'); default is CLI-only
  --rust           Also download the stable rust toolchain via rustup
  --skip-packages  Skip system tools; still set up per-user Node, pnpm and plugins
  --skip-env       Skip loading and applying system environment variables
  -i HOST          Target host to install on over SSH (default: localhost)
  -p PORT          SSH port to use with -i (default: 22)
  -u USER          SSH user to use with -i
  --local-file=PATH  YAML file of vars to write into /etc/environment
                    (default: environment.yml at the repo root)
  --pnpm-version VERSION
                    Pin the pnpm version npm installs, e.g. 12.4.0
                    (default: whatever npm resolves on its own)
```

Running against a remote host (`-i HOST`) stages this repo on that host over SSH and installs there — no shared filesystem needed.

### Pinning pnpm

By default the playbook lets npm pick the pnpm version (`npm install -g pnpm`).
A host behind a custom npm registry that doesn't carry that version needs a
specific one instead, which is per-host and so never committed here:

```sh
./install.sh -i myhost --pnpm-version 12.4.0
```

That runs `npm install -g pnpm@12.4.0` on the target (only when that version isn't already installed). Per-machine
`environment.yml` files can also set `pnpm_version: "12.4.0"` at the top level
to get the same effect without passing the flag every time; the flag wins over
the file.

### Per-machine environment variables

The first thing the playbook does, before anything else, is write custom key/value
pairs into `/etc/environment`. Those values are machine-specific and never committed:
copy `environment.yml.example` to `environment.yml` (gitignored) and fill in whatever
vars this machine needs, e.g.:

```yaml
system_environment_vars:
  EDITOR: nvim
```

To keep the values somewhere else entirely, point at any file with
`--local-file=PATH` instead of using `environment.yml`.

### Requirements

- `ansible-playbook` on the machine you run `install.sh` from (bootstrap with `sudo apt install ansible-core` or `sudo pacman -S ansible-core`)
- `sudo` access on the target for package installation (skip with `--skip-packages`)
- Supported package managers: `apt`, `pacman`

## WSL: Windows Terminal font

`install/roles/wsl` configures the Windows Terminal font from inside WSL (installs a Nerd Font via Chocolatey and patches `settings.json` on the Windows side). Add `--wsl=WIN_USER` to run it on top of the regular install:

```sh
./install.sh --wsl=WIN_USER
```

`WIN_USER` is your Windows username (used to locate `settings.json` under `/mnt/c/Users/WIN_USER/...`). The regular dotfiles install still runs first; the WSL font setup runs afterwards, once it succeeds.

## Structure

```
.
├── .config/            # app configs, symlinked into ~/.config/<app>
├── environment.yml.example  # template for machine-specific /etc/environment vars
├── environment.yml      # your copy of the above, gitignored (not committed)
├── install/
│   ├── playbook.yml     # entry point: environment + dotfiles + dependencies roles
│   └── roles/
│       ├── environment/  # writes environment.yml's vars into /etc/environment first
│       ├── dotfiles/     # discovers + links/copies repo contents into $HOME
│       ├── dependencies/ # installs CLI tools these configs assume are present
│       └── wsl/          # Windows Terminal font setup (WSL only, run manually)
└── install.sh           # CLI wrapper around the playbook
```
