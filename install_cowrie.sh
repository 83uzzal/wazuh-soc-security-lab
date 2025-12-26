#!/bin/bash
set -e

# --- Ensure script has correct Linux line endings ---

echo "[+] Updating system packages..."
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y git python3 python3-venv python3-pip libssl-dev libffi-dev build-essential authbind

echo "[+] Creating Cowrie user..."
sudo useradd -r -s /bin/false cowrie || true

echo "[+] Cloning Cowrie repository..."
cd /opt
if [ -d "/opt/cowrie" ]; then
    echo "[i] /opt/cowrie already exists. Skipping clone."
else
    sudo git clone https://github.com/cowrie/cowrie.git
    sudo chown -R cowrie:cowrie /opt/cowrie
fi

echo "[+] Setting up Python virtual environment..."
sudo -u cowrie python3 -m venv /opt/cowrie/cowrie-env
sudo -u cowrie /opt/cowrie/cowrie-env/bin/pip install --upgrade pip setuptools wheel
sudo -u cowrie /opt/cowrie/cowrie-env/bin/pip install -r /opt/cowrie/requirements.txt

echo "[+] Creating symlink for /opt/cowrie/bin/cowrie..."
sudo -u cowrie mkdir -p /opt/cowrie/bin
if [ ! -f /opt/cowrie/bin/cowrie ]; then
    sudo -u cowrie ln -sf /opt/cowrie/cowrie-env/bin/cowrie /opt/cowrie/bin/cowrie
fi

echo "[+] Configuring Cowrie..."
sudo -u cowrie cp -n /opt/cowrie/etc/cowrie.cfg.dist /opt/cowrie/etc/cowrie.cfg
sudo -u cowrie sed -i 's/^#listen_endpoints = tcp:2222:interface=0.0.0.0/listen_endpoints = tcp:2225:interface=0.0.0.0/' /opt/cowrie/etc/cowrie.cfg
sudo -u cowrie sed -i 's/^#enabled = true/enabled = true/' /opt/cowrie/etc/cowrie.cfg

cat <<EOF | sudo -u cowrie tee -a /opt/cowrie/etc/cowrie.cfg

[telnet]
enabled = true
guest_telnet_port = 23
backend_telnet_port = 2023
EOF

echo "[+] Enabling authbind for low ports..."
sudo touch /etc/authbind/byport/23
sudo chown cowrie:cowrie /etc/authbind/byport/23
sudo chmod 500 /etc/authbind/byport/23

echo "[+] Creating systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/cowrie.service
[Unit]
Description=Cowrie SSH/Telnet Honeypot
After=network.target

[Service]
User=cowrie
Group=cowrie
WorkingDirectory=/opt/cowrie
ExecStart=/usr/bin/authbind --deep /opt/cowrie/cowrie-env/bin/cowrie start -n
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "[+] Reloading systemd and starting Cowrie..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable cowrie
sudo systemctl restart cowrie

echo "[+] Cowrie Status:"
sudo systemctl status cowrie --no-pager

echo "[✓] Cowrie installation completed successfully!"
echo "[✓] SSH Honeypot Port  : 2225"
echo "[✓] Telnet Guest Port : 23"
echo "[✓] Telnet Backend    : 2023"

