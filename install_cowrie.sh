#!/bin/bash
# ============================================================
# Cowrie Honeypot Installer using 83uzzal's Auto-Installer
# - SYSTEMD SAFE
# - No PID issues
# - No port binding issues
# - Survives reboot
# ============================================================

set -Eeuo pipefail

COWRIE_USER="cowrie"
COWRIE_HOME="/home/$COWRIE_USER"

echo "[+] Starting Cowrie installation via 83uzzal installer..."

# Root check
if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] Run as root"
    exit 1
fi

# Install dependencies
apt update -y --fix-missing
apt install -y git curl wget python3 python3-venv python3-pip \
               libssl-dev libffi-dev build-essential libpython3-dev net-tools

# Create cowrie user if not exists
if ! id cowrie &>/dev/null; then
    adduser --disabled-password --gecos "" cowrie
fi

# Download and run 83uzzal installer
INSTALLER_URL="https://raw.githubusercontent.com/83uzzal/cowrie-auto-installer/main/install_cowrie.sh"
TMP_INSTALLER="/tmp/install_cowrie.sh"

curl -fsSL "$INSTALLER_URL" -o "$TMP_INSTALLER"
chmod +x "$TMP_INSTALLER"

# Run installer as cowrie user
sudo -u cowrie bash "$TMP_INSTALLER"

# Systemd service (ensures safe start/stop)
cat <<EOF >/etc/systemd/system/cowrie.service
[Unit]
Description=Cowrie SSH/Telnet Honeypot
After=network.target

[Service]
Type=forking
User=$COWRIE_USER
WorkingDirectory=$COWRIE_HOME/cowrie
Environment="PATH=$COWRIE_HOME/cowrie/cowrie-env/bin:/usr/bin:/bin"
ExecStart=$COWRIE_HOME/cowrie/cowrie-env/bin/cowrie start
ExecStop=$COWRIE_HOME/cowrie/cowrie-env/bin/cowrie stop
PIDFile=$COWRIE_HOME/cowrie/var/run/cowrie.pid
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Enable & start service
systemctl daemon-reload
systemctl enable cowrie
systemctl restart cowrie

echo "[+] Cowrie installation complete!"
systemctl status cowrie --no-pager
