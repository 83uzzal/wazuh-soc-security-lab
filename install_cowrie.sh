#!/bin/bash
set -Eeuo pipefail

echo "[+] Cowrie Honeypot Installation Started"

# -------------------------------------------------
# Root check
# -------------------------------------------------
if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] Run as root: sudo ./install_cowrie.sh"
  exit 1
fi

# -------------------------------------------------
# System update & dependencies
# -------------------------------------------------
echo "[+] Updating system and installing dependencies..."
apt update -y
apt install -y git python3 python3-venv python3-pip \
               libssl-dev libffi-dev build-essential authbind

# -------------------------------------------------
# Create cowrie user (no shell, no sudo)
# -------------------------------------------------
echo "[+] Creating cowrie user..."
id cowrie &>/dev/null || adduser --disabled-password --gecos "" cowrie

# -------------------------------------------------
# Clone Cowrie
# -------------------------------------------------
echo "[+] Installing Cowrie..."
cd /opt
if [[ -d cowrie ]]; then
  echo "[i] Cowrie already exists, skipping clone"
else
  git clone https://github.com/cowrie/cowrie.git
fi

chown -R cowrie:cowrie /opt/cowrie

# -------------------------------------------------
# Python virtual environment
# -------------------------------------------------
echo "[+] Setting up Python virtual environment..."
sudo -u cowrie python3 -m venv /opt/cowrie/cowrie-env
sudo -u cowrie /opt/cowrie/cowrie-env/bin/pip install --upgrade pip setuptools wheel
sudo -u cowrie /opt/cowrie/cowrie-env/bin/pip install -r /opt/cowrie/requirements.txt

# -------------------------------------------------
# Cowrie configuration
# -------------------------------------------------
echo "[+] Configuring Cowrie..."
sudo -u cowrie cp -n /opt/cowrie/etc/cowrie.cfg.dist /opt/cowrie/etc/cowrie.cfg

sudo -u cowrie sed -i \
  's|#listen_endpoints = tcp:2222:interface=0.0.0.0|listen_endpoints = tcp:2225:interface=0.0.0.0|' \
  /opt/cowrie/etc/cowrie.cfg

sudo -u cowrie sed -i 's|#enabled = true|enabled = true|' /opt/cowrie/etc/cowrie.cfg

cat <<EOF | sudo -u cowrie tee -a /opt/cowrie/etc/cowrie.cfg
[telnet]
enabled = true
guest_telnet_port = 23
backend_telnet_port = 2023
EOF

# -------------------------------------------------
# Authbind for port 23
# -------------------------------------------------
echo "[+] Configuring authbind..."
touch /etc/authbind/byport/23
chown cowrie:cowrie /etc/authbind/byport/23
chmod 500 /etc/authbind/byport/23

# -------------------------------------------------
# Systemd service (CORRECT EXEC PATH)
# -------------------------------------------------
echo "[+] Creating systemd service..."
cat <<EOF > /etc/systemd/system/cowrie.service
[Unit]
Description=Cowrie SSH/Telnet Honeypot
After=network.target

[Service]
User=cowrie
Group=cowrie
WorkingDirectory=/opt/cowrie
ExecStart=/usr/bin/authbind --deep /opt/cowrie/bin/cowrie start -n
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# -------------------------------------------------
# Start service
# -------------------------------------------------
echo "[+] Starting Cowrie..."
systemctl daemon-reload
systemctl enable cowrie
systemctl restart cowrie

# -------------------------------------------------
# Status
# -------------------------------------------------
systemctl status cowrie --no-pager

echo "================================================="
echo "✅ Cowrie installation completed successfully!"
echo " SSH Honeypot Port : 2225"
echo " Telnet Port      : 23"
echo " Cowrie Path      : /opt/cowrie"
echo "================================================="
