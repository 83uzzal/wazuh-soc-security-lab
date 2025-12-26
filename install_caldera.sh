#!/bin/bash
# ============================================================
# MITRE Caldera Full Installation + systemd Service
# Ubuntu 22.04 / 24.04
# VMware / SOC Lab Ready
# ============================================================

set -euo pipefail
log() { echo -e "\n[INFO] $1"; }

CALDERA_DIR="/opt/caldera"
CALDERA_USER="$USER"

# ------------------------------------------------------------
# 1. System dependencies
# ------------------------------------------------------------
log "Installing system dependencies"
sudo apt update
sudo apt install -y git python3 python3-venv python3-pip curl build-essential ufw

# ------------------------------------------------------------
# 2. Node.js (for Magma UI)
# ------------------------------------------------------------
log "Installing Node.js LTS"
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt install -y nodejs
node -v
npm -v

# ------------------------------------------------------------
# 3. Clone Caldera
# ------------------------------------------------------------
log "Cloning MITRE Caldera"
if [ ! -d "$CALDERA_DIR" ]; then
  sudo git clone --recursive https://github.com/mitre/caldera.git "$CALDERA_DIR"
fi
sudo chown -R "$CALDERA_USER:$CALDERA_USER" "$CALDERA_DIR"

cd "$CALDERA_DIR"

# ------------------------------------------------------------
# 4. Python virtual environment
# ------------------------------------------------------------
log "Creating Python virtual environment"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip setuptools wheel

log "Installing Python requirements"
pip install -r requirements.txt

# ------------------------------------------------------------
# 5. Build Magma frontend (FIXES assets error)
# ------------------------------------------------------------
log "Building Magma frontend"
cd plugins/magma
npm install
npm run build

# ------------------------------------------------------------
# 6. Configure Caldera binding (CRITICAL)
# ------------------------------------------------------------
log "Configuring Caldera server.yml"
cd "$CALDERA_DIR/conf"

cat > server.yml <<EOF
server:
  host: 0.0.0.0
  port: 8888
EOF

# ------------------------------------------------------------
# 7. systemd service (NO MORE STOPPING)
# ------------------------------------------------------------
log "Creating Caldera systemd service"

sudo tee /etc/systemd/system/caldera.service > /dev/null <<EOF
[Unit]
Description=MITRE Caldera Adversary Emulation Platform
After=network.target

[Service]
Type=simple
User=$CALDERA_USER
WorkingDirectory=$CALDERA_DIR
ExecStart=$CALDERA_DIR/venv/bin/python server.py --insecure
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable caldera
sudo systemctl restart caldera

# ------------------------------------------------------------
# 8. Firewall
# ------------------------------------------------------------
log "Opening firewall port 8888"
sudo ufw allow 8888/tcp || true

# ------------------------------------------------------------
# 9. Status + info
# ------------------------------------------------------------
log "Checking service status"
sudo systemctl status caldera --no-pager

IP_ADDR=$(hostname -I | awk '{print $1}')

log "INSTALLATION COMPLETE"
echo "--------------------------------------------------"
echo "✅ Caldera URL : http://$IP_ADDR:8888"
echo "✅ Service    : systemctl status caldera"
echo "✅ Logs       : journalctl -u caldera -f"
echo "--------------------------------------------------"

