#!/bin/bash
# ============================================================
# Cowrie Honeypot Installer (FINAL / SYSTEMD SAFE)
# Author: 83uzzal based workflow
# ============================================================

set -Eeuo pipefail

COWRIE_USER="cowrie"
COWRIE_HOME="/home/$COWRIE_USER"
COWRIE_DIR="$COWRIE_HOME/cowrie"

echo "[+] Starting Cowrie installation..."

# Root check
[[ $EUID -eq 0 ]] || { echo "[ERROR] Run as root"; exit 1; }

# Dependencies
apt update -y
apt install -y git curl python3 python3-venv python3-pip \
               libssl-dev libffi-dev build-essential authbind

# Create user
if ! id cowrie &>/dev/null; then
    adduser --disabled-password --gecos "" cowrie
fi

# Install Cowrie as cowrie user
if [[ ! -d "$COWRIE_DIR" ]]; then
    sudo -u cowrie bash <<EOF
cd ~
git clone https://github.com/cowrie/cowrie.git
cd cowrie
python3 -m venv cowrie-env
source cowrie-env/bin/activate
pip install --upgrade pip wheel setuptools
pip install -r requirements.txt
deactivate
cp etc/cowrie.cfg.dist etc/cowrie.cfg
EOF
fi

# Authbind for telnet
touch /etc/authbind/byport/23
chown cowrie:cowrie /etc/authbind/byport/23
chmod 500 /etc/authbind/byport/23

# Systemd service
cat <<EOF >/etc/systemd/system/cowrie.service
[Unit]
Description=Cowrie SSH/Telnet Honeypot
After=network.target

[Service]
Type=simple
User=cowrie
Group=cowrie
WorkingDirectory=$COWRIE_DIR
Environment="PATH=$COWRIE_DIR/cowrie-env/bin:/usr/bin:/bin"
ExecStart=$COWRIE_DIR/cowrie-env/bin/cowrie start -n
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable cowrie
systemctl restart cowrie

echo "[+] Cowrie installed successfully"
systemctl status cowrie --no-pager
