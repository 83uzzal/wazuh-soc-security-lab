🛡️ Wazuh SOC SIEM Lab

Suricata | YARA | ClamAV | Osquery | Cowrie | MITRE CALDERA

A complete blue-team SOC & SIEM home lab for threat detection, malware analysis, host monitoring, and attack simulation using open-source tools.

🏗️ Architecture Overview

                  🌐 𝐈𝐧𝐭𝐞𝐫𝐧𝐞𝐭 / 𝐀𝐭𝐭𝐚𝐜𝐤𝐞𝐫
                             │
                             ▼
   ┌─────────────────────────────────────┐
   │ 🟢 𝐒𝐮𝐫𝐢𝐜𝐚𝐭𝐚 𝐍𝐞𝐭𝐰𝐨𝐫𝐤 𝐈𝐃𝐒         │
   │  Network Traffic Inspection         │
   │  Signature & Anomaly Detection      │
   └─────────────────────────────────────┘
                             │
                             ▼
   ┌─────────────────────────────────────┐
   │ 🟡 𝐂𝐨𝐰𝐫𝐢𝐞 𝐇𝐨𝐧𝐞𝐲𝐩𝐨𝐭             │
   │  SSH / Telnet Attack Capture        │
   │  Credential & Command Logging       │
   └─────────────────────────────────────┘
                             │
                             ▼
   ┌─────────────────────────────────────┐
   │ 🟠 𝐘𝐀𝐑𝐀 / 𝐂𝐥𝐚𝐦𝐀𝐕                 │
   │  Malware Signature Scanning         │
   │  Payload & File Analysis            │
   └─────────────────────────────────────┘
                             │
                             ▼
   ┌─────────────────────────────────────┐
   │ 🔵 𝐎𝐬𝐪𝐮𝐞𝐫𝐲 𝐀𝐠𝐞𝐧𝐭             │
   │  Host Behavior & System Events      │
   │  Process, File & User Monitoring    │
   └─────────────────────────────────────┘
                             │
                             ▼
   ┌─────────────────────────────────────┐
   │ 🟣 𝐖𝐚𝐳𝐮𝐡 𝐌𝐚𝐧𝐚𝐠𝐞𝐫             │
   │  SIEM, Log Correlation & Alerts     │
   │  Threat Detection & Compliance      │
   └─────────────────────────────────────┘
                             │
                             ▼
   ┌─────────────────────────────────────┐
   │ 🔴 𝐃𝐚𝐬𝐡𝐛𝐨𝐚𝐫𝐝                   │
   │  Real-time Alerts & Visualization   │
   │  Incident Monitoring & Analysis     │
   └─────────────────────────────────────┘




📂 Repository Structure


<img width="655" height="322" alt="image" src="https://github.com/user-attachments/assets/2fdb5c47-651a-4797-a874-981b0b840774" />



🚀 One-Command Installation
✅ Supported OS

Ubuntu Server 22.04 / 24.04

🔹 Install everything


git clone https://github.com/83uzzal/wazuh-soc-siem-suricata-yara-osquery-caldera-honeypot.git
cd wazuh-soc-siem-suricata-yara-osquery-caldera-honeypot
sudo chmod +x install_all.sh
sudo ./install_all.sh

⚙️ What install_all.sh Does

✔ Installs Wazuh 4.14 (All-in-One)
✔ Installs & configures Suricata IDS
✔ Integrates Suricata → Wazuh (EVE JSON)
✔ Installs YARA + ClamAV
✔ Installs Osquery
✔ Deploys Cowrie SSH Honeypot
✔ Enables services & logging
✔ Prints Dashboard URL & credentials


🔎 Important Log Locations
Wazuh

/var/ossec/logs/alerts/alerts.json
/var/ossec/logs/ossec.log

Suricata

/var/log/suricata/eve.json
/var/log/suricata/fast.log

Cowrie

/opt/cowrie/var/log/cowrie/


Osquery

/var/log/osquery/osqueryd.results.log


🧪 Use Cases

🔐 SSH brute-force detection (Cowrie + Wazuh)

🌐 Network attack detection (Suricata)

🦠 Malware detection (YARA + ClamAV)

🖥️ Host behavior monitoring (Osquery)

📊 SOC alert correlation & dashboards

🎯 MITRE ATT&CK attack simulation (CALDERA ready)


🔄 Suricata Rules Handling (Security-Safe)

Suricata rules are NOT stored in GitHub (to avoid secrets).

Rules are updated automatically during install:
sudo suricata-update

Runtime rules location:
/var/lib/suricata/rules/


⭐ Star the Repo

If this project helps you, please ⭐ star the repository!

📌 Disclaimer

This lab is for education & defensive security research only.
Do NOT deploy on production systems.



👨‍💻 Author

Md. Alamgir Hasan
Cyber Security | SOC | SIEM | Blue Team
🇧🇩 Bangladesh

🔗 GitHub: https://github.com/83uzzal
🔗 LinkedIn: https://www.linkedin.com/in/md-alamgir-hasan











