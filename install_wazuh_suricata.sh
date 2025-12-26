#!/bin/bash
# ============================================================
# Wazuh 4.14 All-in-One + Suricata Server Installation Script
# Ubuntu 22.04 / 24.04
# Manager + Indexer + Dashboard
# Suricata with EVE JSON integrated into Wazuh
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
# System update
# ---------------------------
log "Updating system"
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y curl gnupg apt-transport-https software-properties-common

# ---------------------------
# Install Wazuh 4.14 (All-in-One)
# ---------------------------
log "Downloading Wazuh installer"
curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh

log "Installing Wazuh (All-in-One)"
sudo bash wazuh-install.sh -a | tee /tmp/wazuh-install.log

# Extract Dashboard credentials from log
DASH_USER=$(grep -m1 "User:" /tmp/wazuh-install.log | awk '{print $2}')
DASH_PASS=$(grep -m1 "Password:" /tmp/wazuh-install.log | awk '{print $2}')

# ---------------------------
# Install Suricata
# ---------------------------
log "Installing Suricata"
sudo apt install -y suricata libpcap0.8

# Configure Suricata interface & fanout
sudo sed -i "s|interface: .*|interface: $PRIMARY_IF|" /etc/suricata/suricata.yaml
sudo sed -i "/af-packet:/,+5 s/cluster-type:.*/cluster-type: cluster_none/" /etc/suricata/suricata.yaml
sudo sed -i "/af-packet:/,+5 s/cluster-id:.*/cluster-id: 99/" /etc/suricata/suricata.yaml

# Update Suricata rules
log "Updating Suricata rules"
sudo suricata-update

# Ensure rule paths
sudo sed -i 's|^default-rule-path:.*|default-rule-path: /var/lib/suricata/rules|' /etc/suricata/suricata.yaml
sudo sed -i '/^rule-files:/,$d' /etc/suricata/suricata.yaml

sudo tee -a /etc/suricata/suricata.yaml > /dev/null <<'EOF'

rule-files:
  - local.rules
  - suricata.rules
EOF

# ---------------------------
# Start Suricata
# ---------------------------
sudo systemctl daemon-reload
sudo systemctl enable suricata
sudo systemctl restart suricata

# ---------------------------
# Function: Integrate Suricata with Wazuh
# ---------------------------
add_wazuh_suricata_config() {

    OSSEC_CONF="/var/ossec/etc/ossec.conf"

    log "Adding Wazuh + Suricata configuration"

    # Backup once
    if [ ! -f "${OSSEC_CONF}.bak_suricata" ]; then
        sudo cp "$OSSEC_CONF" "${OSSEC_CONF}.bak_suricata"
    fi

    # Remove old injected block (safe re-run)
    sudo sed -i '/<!-- WAZUH_SURICATA_BEGIN -->/,/<!-- WAZUH_SURICATA_END -->/d' "$OSSEC_CONF"

    sudo tee -a "$OSSEC_CONF" > /dev/null <<'EOF'

<!-- WAZUH_SURICATA_BEGIN -->
<ossec_config>

  <!-- Suricata EVE JSON -->
  <localfile>
    <log_format>json</log_format>
    <location>/var/log/suricata/eve.json</location>
  </localfile>

  <!-- Journald -->
  <localfile>
    <log_format>journald</log_format>
    <location>journald</location>
  </localfile>

  <!-- Active response logs -->
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/ossec/logs/active-responses.log</location>
  </localfile>

  <!-- Package logs -->
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/dpkg.log</location>
  </localfile>

</ossec_config>
<!-- WAZUH_SURICATA_END -->

EOF
}

# ---------------------------
# Integrate Suricata into Wazuh
# ---------------------------
log "Integrating Suricata with Wazuh"
add_wazuh_suricata_config

log "Restarting Wazuh Manager"
sudo systemctl restart wazuh-manager

# ---------------------------
# Final Output
# ---------------------------
log "INSTALLATION COMPLETED SUCCESSFULLY"
echo "==========================================="
echo "        WAZUH DASHBOARD ACCESS INFORMATION"
echo "==========================================="
echo " URL      : https://$SERVER_IP:443"
echo " Username : $DASH_USER"
echo " Password : $DASH_PASS"
echo "==========================================="
echo " Suricata Interface : $PRIMARY_IF"
echo " Suricata rules updated and running"
