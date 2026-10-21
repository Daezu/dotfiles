#!/usr/bin/env bash
# Sets up a separate unprivileged user that runs rootless Podman for devcontainers.
# Your own user drives that Podman over SSH (podman system connection), and the
# devcontainers get that user's socket mounted - not yours.
#
# Usage:  sudo ./setup-devcontainer-user.sh [--user dev] [--group devshare] [--dir /srv/dev]
# Safe to re-run.

set -euo pipefail

DEV_USER="dev"
SHARE_GROUP="devshare"
PROJECT_DIR="/srv/dev"
SUBID_COUNT=65536

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)  DEV_USER="$2"; shift 2 ;;
    --group) SHARE_GROUP="$2"; shift 2 ;;
    --dir)   PROJECT_DIR="$2"; shift 2 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*"; }
die()  { printf '\033[1;31mxx\033[0m  %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run with sudo."
MAIN_USER="${SUDO_USER:-}"
[[ -n "$MAIN_USER" && "$MAIN_USER" != "root" ]] || die "Run via sudo from your normal user account."
MAIN_HOME="$(getent passwd "$MAIN_USER" | cut -d: -f6)"

for cmd in podman setfacl loginctl ssh-keygen ssh-keyscan; do
  command -v "$cmd" >/dev/null || die "Missing '$cmd'. Install podman, acl, openssh (client+server) first."
done

# ---------------------------------------------------------------- user + group
log "Creating group '$SHARE_GROUP' and user '$DEV_USER'"
getent group "$SHARE_GROUP" >/dev/null || groupadd "$SHARE_GROUP"
if ! id "$DEV_USER" &>/dev/null; then
  useradd -m -s /bin/bash -G "$SHARE_GROUP" "$DEV_USER"
  passwd -l "$DEV_USER" >/dev/null   # no password login, SSH key only
fi
usermod -aG "$SHARE_GROUP" "$DEV_USER"
usermod -aG "$SHARE_GROUP" "$MAIN_USER"

DEV_UID="$(id -u "$DEV_USER")"
DEV_HOME="$(getent passwd "$DEV_USER" | cut -d: -f6)"
chmod 700 "$DEV_HOME"

# ---------------------------------------------------------------- subuid/subgid
ensure_subids() {
  local file="$1" flag="$2"
  touch "$file"
  if ! grep -q "^${DEV_USER}:" "$file"; then
    local start
    start=$(awk -F: 'BEGIN{m=100000} {e=$2+$3; if(e>m)m=e} END{print m}' "$file")
    usermod "$flag" "${start}-$((start + SUBID_COUNT - 1))" "$DEV_USER"
    log "Added $file range starting at $start"
  fi
}
ensure_subids /etc/subuid --add-subuids
ensure_subids /etc/subgid --add-subgids

# ---------------------------------------------------------------- project dir
log "Preparing shared project directory $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
chown "$DEV_USER:$SHARE_GROUP" "$PROJECT_DIR"
chmod 2770 "$PROJECT_DIR"                       # setgid: new files keep the group
setfacl -m  "g:${SHARE_GROUP}:rwX,u:${MAIN_USER}:rwX,u:${DEV_USER}:rwX" "$PROJECT_DIR"
setfacl -dm "g:${SHARE_GROUP}:rwX,u:${MAIN_USER}:rwX,u:${DEV_USER}:rwX" "$PROJECT_DIR"
# Apply to anything already inside
if [[ -n "$(ls -A "$PROJECT_DIR")" ]]; then
  chgrp -R "$SHARE_GROUP" "$PROJECT_DIR"
  find "$PROJECT_DIR" -type d -exec chmod g+s {} +
  setfacl -R  -m "g:${SHARE_GROUP}:rwX,u:${MAIN_USER}:rwX,u:${DEV_USER}:rwX" "$PROJECT_DIR"
  find "$PROJECT_DIR" -type d -exec setfacl -dm "g:${SHARE_GROUP}:rwX,u:${MAIN_USER}:rwX,u:${DEV_USER}:rwX" {} +
fi

# ---------------------------------------------------------------- rootless podman
log "Enabling lingering and the rootless podman socket for $DEV_USER"
loginctl enable-linger "$DEV_USER"
for _ in $(seq 1 50); do [[ -S "/run/user/${DEV_UID}/bus" ]] && break; sleep 0.2; done
[[ -S "/run/user/${DEV_UID}/bus" ]] || die "User manager for $DEV_USER did not start."

as_dev() {
  sudo -u "$DEV_USER" XDG_RUNTIME_DIR="/run/user/${DEV_UID}" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${DEV_UID}/bus" "$@"
}
as_dev podman system migrate >/dev/null 2>&1 || true   # picks up new subuid ranges
as_dev systemctl --user enable --now podman.socket
DEV_SOCK="/run/user/${DEV_UID}/podman/podman.sock"

# ---------------------------------------------------------------- sshd
log "Checking sshd"
if ! systemctl is-active --quiet sshd && ! systemctl is-active --quiet ssh; then
  if systemctl list-unit-files | grep -q '^sshd\.service'; then
    systemctl enable --now sshd
  elif systemctl list-unit-files | grep -q '^ssh\.service'; then
    systemctl enable --now ssh
  else
    die "No sshd found. Install openssh-server and re-run."
  fi
fi

# ---------------------------------------------------------------- ssh key
log "Setting up SSH key for $MAIN_USER -> $DEV_USER (localhost only)"
KEY="$MAIN_HOME/.ssh/${DEV_USER}_podman"
sudo -u "$MAIN_USER" mkdir -p "$MAIN_HOME/.ssh"
chmod 700 "$MAIN_HOME/.ssh"
[[ -f "$KEY" ]] || sudo -u "$MAIN_USER" ssh-keygen -q -t ed25519 -N "" -C "${MAIN_USER}->${DEV_USER} podman" -f "$KEY"

install -d -m 700 -o "$DEV_USER" -g "$DEV_USER" "$DEV_HOME/.ssh"
AUTH="$DEV_HOME/.ssh/authorized_keys"
touch "$AUTH"
PUB="$(cat "${KEY}.pub")"
# Key only usable from this machine, no tty/X11/agent forwarding
grep -qF "$PUB" "$AUTH" || \
  echo "from=\"127.0.0.1,::1\",no-pty,no-X11-forwarding,no-agent-forwarding $PUB" >> "$AUTH"
chown "$DEV_USER:$DEV_USER" "$AUTH"
chmod 600 "$AUTH"

KNOWN="$MAIN_HOME/.ssh/known_hosts"
sudo -u "$MAIN_USER" touch "$KNOWN"
if ! sudo -u "$MAIN_USER" ssh-keygen -F localhost -f "$KNOWN" >/dev/null; then
  ssh-keyscan -H localhost 2>/dev/null >> "$KNOWN"
  chown "$MAIN_USER:" "$KNOWN"
fi

# ---------------------------------------------------------------- podman connection
log "Adding podman connection '$DEV_USER' for $MAIN_USER (set as default)"
as_main() { sudo -u "$MAIN_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$MAIN_USER")" "$@"; }
as_main podman system connection rm "$DEV_USER" >/dev/null 2>&1 || true
as_main podman system connection add --default "$DEV_USER" \
  --identity "$KEY" "ssh://${DEV_USER}@localhost${DEV_SOCK}"

if as_main podman --connection "$DEV_USER" info --format '{{.Host.Security.Rootless}}' 2>/dev/null | grep -q true; then
  log "Connection works: rootless podman as $DEV_USER"
else
  warn "Connection test failed. Try: podman --connection $DEV_USER info"
fi

# ---------------------------------------------------------------- devcontainer template
TEMPLATE_DIR="$PROJECT_DIR/.devcontainer-template"
log "Writing devcontainer template to $TEMPLATE_DIR"
mkdir -p "$TEMPLATE_DIR"
cat > "$TEMPLATE_DIR/devcontainer.json" <<EOF
{
  "name": "dev",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",

  // Root in the container == '${DEV_USER}' on the host (rootless podman)
  "remoteUser": "root",

  // Same path inside and outside so compose bind mounts resolve correctly
  "workspaceMount": "source=\${localWorkspaceFolder},target=\${localWorkspaceFolder},type=bind",
  "workspaceFolder": "\${localWorkspaceFolder}",

  "mounts": [
    "source=${DEV_SOCK},target=/run/podman/podman.sock,type=bind"
  ],
  "containerEnv": {
    "DOCKER_HOST": "unix:///run/podman/podman.sock"
  },

  "features": {
    "ghcr.io/devcontainers/features/docker-outside-of-docker:1": { "moby": false },
    "ghcr.io/devcontainers/features/node:1": {}
  },
  "postCreateCommand": "npm install -g @openai/codex"
}
EOF
chown -R "$DEV_USER:$SHARE_GROUP" "$TEMPLATE_DIR"

# ---------------------------------------------------------------- checks + summary
HOME_MODE="$(stat -c '%a' "$MAIN_HOME")"
if [[ "${HOME_MODE: -1}" != "0" ]]; then
  warn "Your home $MAIN_HOME is mode $HOME_MODE ($DEV_USER can read into it). Consider: chmod 700 $MAIN_HOME"
fi

cat <<EOF

Done.

  Dev user:        $DEV_USER (uid $DEV_UID)
  Podman socket:   $DEV_SOCK
  Projects:        $PROJECT_DIR   (group $SHARE_GROUP, setgid + default ACLs)
  Template:        $TEMPLATE_DIR/devcontainer.json

Next steps:
  1. Log out and back in so '$MAIN_USER' picks up the '$SHARE_GROUP' group.
  2. In VS Code user settings:  "dev.containers.dockerPath": "podman"
  3. Move/clone projects into $PROJECT_DIR and copy the template into
     <project>/.devcontainer/devcontainer.json
  4. 'podman ps' now talks to $DEV_USER. Switch back to your own podman with:
       podman system connection default <your-connection>   (see: podman system connection ls)
EOF
