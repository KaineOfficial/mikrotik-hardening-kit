#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# audit-exposed-services.sh                                 [generique]
#
# Scan un MikroTik depuis l'exterieur pour detecter les services
# administratifs exposes publiquement (Winbox 8291, API 8728/8729,
# SSH 22, Telnet 23, HTTP 80, HTTPS 443, FTP 21, SNMP 161).
#
# Un service admin expose = surface d'attaque inutile (bruteforce, CVE,
# leak d'info). A fermer sauf usage explicite.
#
# Usage :
#   ./audit-exposed-services.sh <IP_PUBLIQUE>
#
# Dependance : nmap
#
# A executer depuis un VPS externe.
# -----------------------------------------------------------------------------
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <public_ip>" >&2
    exit 2
fi

IP="$1"

if ! command -v nmap >/dev/null 2>&1; then
    echo "[!] nmap est requis. Install : apt install nmap | brew install nmap" >&2
    exit 2
fi

# Ports admin MikroTik courants
PORTS="21,22,23,53,80,443,161,2000,8291,8728,8729"

echo "[*] Scan des ports admin sur ${IP} (ports: ${PORTS})"
echo

# -Pn : ne pas ping (certains firewalls droppent ICMP)
# -sT : TCP connect (ne requiert pas root)
# -sU : UDP (pour SNMP, DNS)
nmap -Pn -sT -p "${PORTS}" --open "${IP}" 2>/dev/null | grep -E "^[0-9]+/" || echo "Aucun port TCP ouvert detecte."

echo
echo "[*] Scan UDP (SNMP, DNS) :"
nmap -Pn -sU -p 53,161 --open "${IP}" 2>/dev/null | grep -E "^[0-9]+/" || echo "Aucun port UDP ouvert detecte."

cat <<'EOF'

---
Services qui ne devraient JAMAIS etre exposes sur WAN :
  - 21 (FTP)       : protocole en clair, a desactiver
  - 23 (Telnet)    : protocole en clair, a desactiver
  - 80 (HTTP)      : admin web en clair
  - 161 (SNMP)     : leak d'info + ampli DDoS
  - 2000 (Bandwidth-Test) : leak d'info
  - 8291 (Winbox)  : tolerable si autorise par IP source uniquement
  - 8728 (API)     : protocole en clair
  - 8729 (API-SSL) : tolerable si autorise par IP source uniquement

Remediation : voir scripts/hardening/04-disable-services.rsc
EOF
