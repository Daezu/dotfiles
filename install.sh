#!/usr/bin/env bash
# Generic dotfiles installer — thin wrapper around the Ansible playbook.
#
# Provisioning logic lives in playbook.yml/roles/; this script only translates
# the familiar CLI flags into an ansible-playbook invocation, so existing
# callers (e.g. devpod's DOTFILES_SCRIPT: install.sh) keep working unchanged.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="symlink"
SKIP_PACKAGES=false
TARGET_HOST=""
SSH_PORT=""
SSH_USER=""
WSL_USER=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [--symlink|--copy] [--skip-packages] [-i HOST] [-p PORT] [-u USER]
       $(basename "$0") --wsl=WIN_USER

  --symlink        Symlink dotfiles into \$HOME (default)
  --copy           Copy dotfiles into \$HOME instead of symlinking
  --skip-packages  Don't install missing CLI tool dependencies (eza, bat, fd, ...)
  -i HOST          Target host to install on over SSH (default: localhost, no SSH)
  -p PORT          SSH port to use with -i (default: 22)
  -u USER          SSH user to use with -i (default: your ssh client's own default)
  --wsl=WIN_USER   Also configure the Windows Terminal font for WSL, as
                    Windows user WIN_USER, after the regular dotfiles install
  -h, --help       Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --symlink) MODE="symlink" ;;
    --copy) MODE="copy" ;;
    --skip-packages) SKIP_PACKAGES=true ;;
    --wsl=*)
      WSL_USER="${1#--wsl=}"
      ;;
    -i)
      shift
      [[ $# -gt 0 ]] || { echo "-i requires a host argument" >&2; usage >&2; exit 1; }
      TARGET_HOST="$1"
      ;;
    -p)
      shift
      [[ $# -gt 0 ]] || { echo "-p requires a port argument" >&2; usage >&2; exit 1; }
      SSH_PORT="$1"
      ;;
    -u)
      shift
      [[ $# -gt 0 ]] || { echo "-u requires a user argument" >&2; usage >&2; exit 1; }
      SSH_USER="$1"
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

# install/ansible.cfg (host_key_checking, roles_path) is only auto-discovered
# when ansible-playbook runs from install/; we invoke it from the repo root,
# so point at it explicitly.
export ANSIBLE_CONFIG="$SCRIPT_DIR/install/ansible.cfg"

EXTRA_VARS="{\"dotfiles_mode\": \"$MODE\", \"skip_packages\": $SKIP_PACKAGES"
if [[ -z "$TARGET_HOST" ]]; then
  # No explicit remote host: install directly here, never over SSH (avoids
  # surprises from an ssh_config alias redefining what "localhost" means).
  TARGET_HOST="localhost"
  EXTRA_VARS+=", \"ansible_connection\": \"local\""
fi
[[ -n "$SSH_PORT" ]] && EXTRA_VARS+=", \"ansible_port\": $SSH_PORT"
[[ -n "$SSH_USER" ]] && EXTRA_VARS+=", \"ansible_user\": \"$SSH_USER\""
EXTRA_VARS+="}"

PROMPT_TARGET="$TARGET_HOST"
[[ -n "$SSH_PORT" ]] && PROMPT_TARGET+=":$SSH_PORT"
[[ -n "$SSH_USER" ]] && PROMPT_TARGET="$SSH_USER@$PROMPT_TARGET"

read -p "Run installation on $PROMPT_TARGET? (y/n)" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    ansible-playbook -i "$TARGET_HOST," "$SCRIPT_DIR/install/playbook.yml" -e "$EXTRA_VARS"
    if [[ -n "$WSL_USER" ]]; then
        ansible-playbook "$SCRIPT_DIR/install/roles/wsl/tasks/main.yml" -e "windows_user=$WSL_USER"
    fi
else
    echo "aborted"
fi
