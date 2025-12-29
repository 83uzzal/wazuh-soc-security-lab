🛡️ Wazuh SOC SIEM Lab

Suricata | YARA | ClamAV | Osquery | Cowrie | MITRE CALDERA

A complete blue-team SOC & SIEM home lab for threat detection, malware analysis, host monitoring, and attack simulation using open-source tools.

🏗️ Architecture Overview

<img width="915" height="1052" alt="image" src="https://github.com/user-attachments/assets/8b2a7f1d-156b-44fb-b246-63f37217ed64" />



📂 Repository Structure


<img width="800" height="1200" alt="image" src="https://github.com/user-attachments/assets/f8eabb1a-fa80-4cab-b7e2-a50e210ed1b6" />






🚀 One-Command Installation

✅ Supported OS

Ubuntu Server 22.04 / 24.04

🔹 Install everything


git clone https://github.com/83uzzal/wazuh-soc-security-lab.git

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











