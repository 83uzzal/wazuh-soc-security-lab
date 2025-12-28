#!/bin/bash
# ============================================================
# Cowrie Honeypot Installer
# Repo: https://github.com/83uzzal/wazuh-soc-siem-suricata-yara-osquery-caldera-honeypot
# OS  : Ubuntu 22.04 / 24.04
# Author: Md. Alamgir Hasan
# ============================================================

set -Eeuo pipefail

COWRIE_USER="cowrie"
COWRIE_HOME="/home/${COWRIE_USER}"
COWRIE_DIR="${COWRIE_HOME}/cowrie"
VENV_DIR="${COWRIE_DIR}/cowrie-env"

log() {
    echo -e "[INFO] $1"
}

error() {
    echo -e "[ERROR] $1" >&2
    exit 1
}

# ------------------------------------------------------------
# Root check
# ------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    error "Run this script as root (sudo ./install_cowrie.sh)"
fi

log "Starting Cowrie Honeypot installation..."

# ------------------------------------------------------------
# System update
# ------------------------------------------------------------
log "Updating system packages"
apt update -y
apt upgrade -y

# ------------------------------------------------------------
# Install dependencies
# ------------------------------------------------------------
log "Installing dependencies"
apt install -y \
    git \
    python3 \
    python3-pip \
    python3-venv \
    python3-minimal \
    libssl-dev \
    libffi-dev \
    libpython3-dev \
    build-essential \
    authbind

# ------------------------------------------------------------
# Create Cowrie user
# ------------------------------------------------------------
if id "${COWRIE_USER}" &>/dev/null; then
    log "User '${COWRIE_USER}' already exists"
else
    log "Creating Cowrie user"
    adduser --disabled-password --gecos "" "${COWRIE_USER}"
fi

# ------------------------------------------------------------
# Switch to Cowrie user for installation
# ------------------------------------------------------------
log "Installing Cowrie as ${COWRIE_USER}"

sudo -u "${COWRIE_USER}" bash <<EOF
set -Eeuo pipefail

log() {
    echo -e "[COWRIE] \$1"
}

cd "${COWRIE_HOME}"

# ------------------------------------------------------------
# Clone Cowrie
# ------------------------------------------------------------
if [[ -d "${COWRIE_DIR}" ]]; then
    log "Cowrie repository already exists"
else
    log "Cloning Cowrie repository"
    git clone https://github.com/cowrie/cowrie.git
fi

cd cowrie

# ------------------------------------------------------------
# Python virtual environment
# ------------------------------------------------------------
if [[ ! -d "${VENV_DIR}" ]]; then
    log "Creating Python virtual environment"
    python3 -m venv cowrie-env
fi

source cowrie-env/bin/activate

# ------------------------------------------------------------
# Install Python dependencies
# ------------------------------------------------------------
log "Upgrading pip"
python -m pip install --upgrade pip

log "Installing Cowrie"
python -m pip install -e .

# ------------------------------------------------------------
# Configure Cowrie
# ------------------------------------------------------------
if [[ ! -f etc/cowrie.cfg ]]; then
    log "Creating cowrie.cfg"
    cp etc/cowrie.cfg.dist etc/cowrie.cfg
fi

log "Enabling Telnet support"
sed -i '/^\[telnet\]/,/^\[/{s/^enabled *=.*/enabled = true/}' etc/cowrie.cfg

# ------------------------------------------------------------
# Start Cowrie
# ------------------------------------------------------------
log "Starting Cowrie"
source cowrie-env/bin/activate
cowrie start

log "Checking Cowrie status"
cowrie status
EOF

log "Cowrie installation completed successfully"
log "SSH Honeypot  : Port 2222"
log "Telnet Honeypot: Port 2223"
