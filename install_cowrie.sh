#!/bin/bash
# ============================================================
# Cowrie Installer Wrapper
# Repo: wazuh-soc-security-lab
# Installs Cowrie using:
# https://github.com/83uzzal/cowrie-auto-installer.git
# Tested on Ubuntu 24.04 LTS
# ============================================================

set -Eeuo pipefail

COWRIE_INSTALLER_REPO="https://github.com/83uzzal/cowrie-auto-installer.git"
INSTALL_DIR="/opt/cowrie-auto-installer"

# -----------------------------
# Root Check
# -----------------------------
if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] Run as root:"
  echo "sudo ./install_cowrie.sh"
  exit 1
fi

echo "[+] Starting Cowrie installation via auto-installer"

# -----------------------------
# Basic Dependencies
# -----------------------------
apt update -y
apt install -y git curl sudo

# -----------------------------
# Clone Auto Installer
# -----------------------------
if [[ -d "${INSTALL_DIR}" ]]; then
  echo "[!] Existing installer found, removing..."
  rm -rf ${INSTALL_DIR}
fi

echo "[+] Cloning cowrie-auto-installer"
git clone ${COWRIE_INSTALLER_REPO} ${INSTALL_DIR}

cd ${INSTALL_DIR}

# -----------------------------
# Make Executable
# -----------------------------
chmod +x install_cowrie.sh

# -----------------------------
# Run Installer
# -----------------------------
echo "[+] Running cowrie auto installer"
./install_cowrie.sh

# -----------------------------
# Final Status
# -----------------------------
echo "--------------------------------------"
echo "[+] Cowrie installation triggered"
echo "[+] Check status with:"
echo "systemctl status cowrie"
echo "journalctl -u cowrie -f"
echo "--------------------------------------"
