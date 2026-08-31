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

This symlinks every top-level entry in this repo (and every app folder under `.config/`) into the right place under `$HOME`, installing any missing CLI dependencies (`eza`, `bat`, `fd`, `starship`, `yazi`, `nvim`, `rustup`, `nvm`/Node, …) along the way. Anything already present at a destination gets backed up first, under `~/.dotfiles_backup/<timestamp>/`.

### Options

```
./install.sh [--symlink|--copy] [--skip-packages] [-i HOST] [-p PORT] [-u USER]

  --symlink        Symlink dotfiles into $HOME (default)
  --copy           Copy dotfiles into $HOME instead of symlinking
  --skip-packages  Don't install missing CLI tool dependencies
  -i HOST          Target host to install on over SSH (default: localhost)
  -p PORT          SSH port to use with -i (default: 22)
  -u USER          SSH user to use with -i
```

Running against a remote host (`-i HOST`) stages this repo on that host over SSH and installs there — no shared filesystem needed.

### Requirements

- `ansible-playbook` on the machine you run `install.sh` from
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
├── install/
│   ├── playbook.yml     # entry point: dotfiles + dependencies roles
│   └── roles/
│       ├── dotfiles/     # discovers + links/copies repo contents into $HOME
│       ├── dependencies/ # installs CLI tools these configs assume are present
│       └── wsl/          # Windows Terminal font setup (WSL only, run manually)
└── install.sh           # CLI wrapper around the playbook
```
