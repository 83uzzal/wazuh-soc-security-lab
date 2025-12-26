#!/bin/bash
# ============================================================
# Install YARA + ClamAV for static malware scanning
# Safe version for Ubuntu/Debian systems
# ============================================================

set -euo pipefail
log() { echo -e "\n[INFO] $1"; }

# 1️⃣ Update system and install required packages
log "Updating system packages and installing YARA + ClamAV"
sudo apt update && sudo apt install -y yara clamav clamav-daemon clamav-freshclam

# 2️⃣ Ensure log file has correct ownership and permissions
log "Fixing ClamAV log permissions"
sudo mkdir -p /var/log/clamav
sudo touch /var/log/clamav/freshclam.log
sudo chown clamav:clamav /var/log/clamav/freshclam.log
sudo chmod 640 /var/log/clamav/freshclam.log

# 3️⃣ Enable and start ClamAV freshclam daemon
log "Enabling and starting ClamAV freshclam daemon"
sudo systemctl enable clamav-freshclam
sudo systemctl restart clamav-freshclam

# 4️⃣ Optional: Check service status
log "Checking ClamAV freshclam service status"
sudo systemctl status clamav-freshclam --no-pager

# 5️⃣ Completion message
log "YARA + ClamAV installation complete"
echo "✅ ClamAV daemon running and YARA installed."
