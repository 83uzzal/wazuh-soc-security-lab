#!/bin/bash
# ============================================================
# Standalone OSQuery Installation & Logging Configuration
# Ubuntu 22.04 / 24.04
# Installs OSQuery from official .deb package and sets up logging
# ============================================================

set -euo pipefail

log() { echo -e "\n[INFO] $1"; }

# ---------------------------
# Detect server IP and interface
# ---------------------------
SERVER_IP=$(hostname -I | awk '{print $1}')
PRIMARY_IF=$(ip route | awk '/default/ {print $5; exit}')
log "Detected Server IP: $SERVER_IP"
log "Detected Network Interface: $PRIMARY_IF"

# ---------------------------
# Update system
# ---------------------------
log "Updating system packages"
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y curl gnupg lsb-release software-properties-common

# ---------------------------
# Install OSQuery .deb
# ---------------------------
OSQUERY_DEB_URL="https://pkg.osquery.io/deb/osquery_5.20.0-1.linux_amd64.deb"
log "Downloading OSQuery package"
curl -LO "$OSQUERY_DEB_URL"

log "Installing OSQuery"
sudo apt install -y ./osquery_5.20.0-1.linux_amd64.deb

# ---------------------------
# Verify OSQuery installation
# ---------------------------
log "Verifying OSQuery installation"
osqueryi --version

# ---------------------------
# Create osquery user if missing
# ---------------------------
if ! id -u osquery &>/dev/null; then
    log "Creating osquery user and group"
    sudo groupadd -f osquery
    sudo useradd -r -g osquery -d /var/lib/osquery -s /usr/sbin/nologin osquery
fi

# ---------------------------
# Configure OSQuery logging
# ---------------------------
OSQUERY_CONF="/etc/osquery/osquery.conf"
log "Creating OSQuery configuration for JSON logging"

sudo mkdir -p /var/log/osquery
sudo chown -R osquery:osquery /var/log/osquery

sudo tee "$OSQUERY_CONF" > /dev/null <<EOF
{
  "options": {
    "logger_plugin": "filesystem",
    "logger_path": "/var/log/osquery",
    "disable_logging": "false",
    "utc": "true",
    "verbose": "false"
  },
  "schedule": {
    "system_info": {
      "query": "SELECT hostname, cpu_brand, physical_memory FROM system_info;",
      "interval": 3600
    }
  }
}
EOF

log "OSQuery installed and logging configured at /var/log/osquery"
log "OSQuery service can be started with: sudo systemctl start osqueryd"
log "OSQuery service status: sudo systemctl status osqueryd"

echo -e "\n[SUMMARY]"
echo "OSQuery installed: $(osqueryi --version)"
echo "Logging directory: /var/log/osquery"
echo "Network interface detected: $PRIMARY_IF"
echo "Server IP: $SERVER_IP"
