# ~/.config/zsh/.zshenv

skip_global_compinit=1

export DOTDIR=${ZDOTDIR:A:h:h} # :A resolve symlink | :h go back on folder

# ---------- XDG base directories ----------
# Centralizes config/cache/data locations
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# ---------- Editor ----------
# Default editor used by git, crontab, etc.
export EDITOR="nvim"
export VISUAL="nvim"

# ---------- Pager ----------
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="bat -l man -p"
elif command -v batcat >/dev/null 2>&1; then
  export MANPAGER="batcat -l man -p"
fi

# ---------- GPG ----------
export GPG_TTY=$(tty)

# ---------- Starship ----------
export STARSHIP_CONFIG="$ZDOTDIR/starship.toml"

# ---------- PNPM ----------
export PNPM_HOME="$HOME/.local/share/pnpm"

# Personal binaries and command-line tools must be available before the
# optional Devsy setup below runs.
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PNPM_HOME/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# Per-machine values are written here by the macOS installer. This file is
# intentionally local and is not tracked in the dotfiles repository.
[[ -r "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"

# ---------- DEVSY ----------
export DEVSY_IDE="none"
export DEVSY_PROVIDER="podman"
export DEVSY_SSH_CONFIG_INCLUDE_PATH="$HOME/.ssh/config.d/devsy"
if command -v devsy >/dev/null 2>&1; then
  devsy ide use "$DEVSY_IDE"
  devsy context set -o SSH_CONFIG_INCLUDE_PATH="$DEVSY_SSH_CONFIG_INCLUDE_PATH"
  devsy context set -o TELEMETRY=false
fi
#export DEVSY_DEBUG=true

# Podman exposes a VM socket on macOS and a runtime-dir socket on Linux.
if [[ "$OSTYPE" == darwin* ]]; then
  unset DOCKER_HOST
  _podman_bin=""
  for _candidate in /opt/homebrew/bin/podman /usr/local/bin/podman; do
    if [[ -x "$_candidate" ]]; then
      _podman_bin="$_candidate"
      break
    fi
  done
  [[ -z "$_podman_bin" ]] && _podman_bin=$(command -v podman 2>/dev/null)
  if [[ -n "$_podman_bin" ]]; then
    _podman_socket=$("$_podman_bin" machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)
    [[ -n "$_podman_socket" ]] && export DOCKER_HOST="unix://$_podman_socket"
  fi
  unset _podman_bin _podman_socket _candidate
else
  export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
fi

# ---------- SECRETS ----------
if [ -f $HOME/.secrets ]; then
  set -a
  source $HOME/.secrets
  set +a
fi
