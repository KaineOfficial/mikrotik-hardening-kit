#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# check-open-resolver.sh
#
# Teste depuis Internet si une IP publique repond aux requetes DNS recursives.
# Un routeur MikroTik qui repond = open resolver = risque d'attaque
# DNS amplification (voir docs/incident-postmortem.md).
#
# Usage :
#   ./check-open-resolver.sh <IP_PUBLIQUE> [<IP_PUBLIQUE_2> ...]
#
# A executer depuis un VPS externe, PAS depuis le LAN (sinon resultat biaise).
#
# Exit code :
#   0 = aucun open resolver detecte
#   1 = au moins un open resolver detecte (ACTION REQUISE)
#   2 = erreur d'usage
# -----------------------------------------------------------------------------
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <public_ip> [<public_ip2> ...]" >&2
    exit 2
fi

# Domaine neutre pour le test (pas d'amplification notable)
TEST_DOMAIN="example.com"
TIMEOUT=3
FOUND_OPEN=0

for IP in "$@"; do
    printf "[*] Test %s ... " "$IP"

    # On interroge l'IP pour un domaine externe qu'elle ne devrait pas resoudre
    # recursivement si elle n'est pas configuree comme open resolver.
    if RESULT=$(dig +short +time=$TIMEOUT +tries=1 "@${IP}" "${TEST_DOMAIN}" A 2>/dev/null) && [[ -n "$RESULT" ]]; then
        echo "OPEN RESOLVER DETECTE (a repondu: ${RESULT})"
        FOUND_OPEN=1
    else
        echo "OK (aucune reponse recursive)"
    fi
done

echo
if [[ $FOUND_OPEN -eq 1 ]]; then
    cat <<'EOF'
[!] AU MOINS UN OPEN RESOLVER DETECTE.

Remediation MikroTik :
    /ip dns set allow-remote-requests=no

Ou (si vous devez garder le DNS recursif pour le LAN) :
    /ip firewall filter add chain=input protocol=udp dst-port=53 \
        in-interface-list=WAN action=drop comment="Block DNS from WAN"
    /ip firewall filter add chain=input protocol=tcp dst-port=53 \
        in-interface-list=WAN action=drop comment="Block DNS from WAN"

Voir scripts/hardening/01-disable-dns-recursion.rsc
EOF
    exit 1
fi

echo "[+] Aucun open resolver detecte sur les IPs testees."
exit 0
