#!/bin/bash
# ============================================================
# SOC Home Lab - One Command Installer (Production Grade)
# Components: Wazuh 4.14 + Suricata + Cowrie + YARA + ClamAV + Osquery
# OS: Ubuntu 22.04 / 24.04
# ============================================================

set -Eeuo pipefail

# ------------------------------------------------------------
# Root check
# ------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo -e "\n[ERROR] Run as root: sudo ./install_all.sh"
    exit 1
fi

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------
LOG_FILE="/var/log/soc_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

log() { echo -e "\n[INFO] $(date '+%F %T') - $1"; }
fail() { echo -e "\n[ERROR] $1"; exit 1; }
trap 'fail "Installation failed at line $LINENO"' ERR

log "SOC Home Lab installer started"

# ------------------------------------------------------------
# System preparation
# ------------------------------------------------------------
log "Updating system and installing basic packages"
apt update -y
apt install -y curl gnupg apt-transport-https \
               software-properties-common \
               ca-certificates jq git python3 python3-venv python3-pip libssl-dev libffi-dev build-essential authbind dos2unix

# --- Fix line endings and permissions for install_cowrie.sh if present ---
if [[ -f ./install_cowrie.sh ]]; then
    log "Fixing line endings and permissions for install_cowrie.sh"
    dos2unix ./install_cowrie.sh
    chmod +x ./install_cowrie.sh
fi

# ------------------------------------------------------------
# Wazuh 4.14
# ------------------------------------------------------------
install_wazuh() {
    if systemctl list-units --type=service | grep -q wazuh-manager; then
        log "Wazuh already installed, skipping"
        return
    fi

    log "Installing Wazuh 4.14"
    curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh
    bash wazuh-install.sh -a | tee /tmp/wazuh-install.log

    DASH_USER=$(grep -m1 "User:" /tmp/wazuh-install.log | awk '{print $2}')
    DASH_PASS=$(grep -m1 "Password:" /tmp/wazuh-install.log | awk '{print $2}')
    echo "$DASH_USER:$DASH_PASS" > /root/wazuh_dashboard_creds.txt
    chmod 600 /root/wazuh_dashboard_creds.txt
}

# ------------------------------------------------------------
# Suricata IDS
# ------------------------------------------------------------
install_suricata() {
    if command -v suricata &>/dev/null; then
        log "Suricata already installed, skipping"
        return
    fi

    log "Installing Suricata IDS"
    apt install -y suricata suricata-update libpcap0.8
    PRIMARY_IF=$(ip route | awk '/default/ {print $5; exit}')
    sed -i "s|interface: .*|interface: $PRIMARY_IF|" /etc/suricata/suricata.yaml
    suricata-update
    systemctl enable suricata
    systemctl restart suricata
}

# ------------------------------------------------------------
# YARA + ClamAV
# ------------------------------------------------------------
install_yara_clamav() {
    log "Installing YARA & ClamAV"
    apt install -y yara clamav clamav-daemon
    systemctl stop clamav-freshclam || true
    freshclam
    systemctl enable clamav-daemon
    systemctl start clamav-daemon
}

# ------------------------------------------------------------
# Osquery
# ------------------------------------------------------------
install_osquery() {
    if command -v osqueryd &>/dev/null; then
        log "Osquery already installed, skipping"
        return
    fi

    log "Installing Osquery"
    curl -L https://pkg.osquery.io/deb/osquery_5.20.0-1.linux_amd64.deb -o /tmp/osquery.deb
    dpkg -i /tmp/osquery.deb || apt -f install -y

    mkdir -p /etc/osquery
    cat <<EOF > /etc/osquery/osquery.conf
{
  "options": {
    "logger_plugin": "filesystem",
    "logger_path": "/var/log/osquery",
    "utc": "true"
  },
  "schedule": {
    "system_info": {
      "query": "SELECT hostname, cpu_brand, physical_memory FROM system_info;",
      "interval": 3600
    }
  }
}
EOF

    systemctl enable osqueryd
    systemctl restart osqueryd
}

# ------------------------------------------------------------
# Cowrie SSH/Telnet Honeypot
# ------------------------------------------------------------
install_cowrie() {
    if [[ -d /opt/cowrie ]]; then
        log "Cowrie already installed, skipping"
        return
    fi

    log "Installing Cowrie honeypot"
    apt install -y git python3-venv libssl-dev libffi-dev build-essential authbind

    git clone https://github.com/cowrie/cowrie.git /opt/cowrie
    cd /opt/cowrie
    python3 -m venv cowrie-env
    source cowrie-env/bin/activate
    pip install --upgrade pip setuptools wheel
    pip install -r requirements.txt
    deactivate

    # symlink cowrie binary
    mkdir -p /opt/cowrie/bin
    ln -sf /opt/cowrie/cowrie-env/bin/cowrie /opt/cowrie/bin/cowrie

    cp /opt/cowrie/etc/cowrie.cfg.dist /opt/cowrie/etc/cowrie.cfg

    # Create cowrie user
    adduser --disabled-password --gecos "" cowrie || true
    chown -R cowrie:cowrie /opt/cowrie

    # Authbind for low ports
    touch /etc/authbind/byport/23
    chown cowrie:cowrie /etc/authbind/byport/23
    chmod 500 /etc/authbind/byport/23

    # Systemd service


    systemctl daemon-reload
    systemctl enable cowrie
    systemctl restart cowrie
}

# ------------------------------------------------------------
# MAIN INSTALLATION
# ------------------------------------------------------------
log "Starting full SOC Home Lab installation"

install_wazuh
install_suricata
install_yara_clamav
install_osquery
install_cowrie

log "INSTALLATION COMPLETED SUCCESSFULLY"
echo "================================================="
echo " Wazuh Dashboard: https://$(hostname -I | awk '{print $1}')"
echo " Credentials    : /root/wazuh_dashboard_creds.txt"
echo " Logs           : $LOG_FILE"
echo "================================================="
