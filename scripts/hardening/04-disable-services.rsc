# -----------------------------------------------------------------------------
# 04-disable-services.rsc                                   [generique]
#
# Desactive les services admin en clair et ceux qu'on n'utilise pas.
# Bonne pratique generique, pas specifique a l'incident du 2026-04-16.
# Restreint les services gardes a des IPs source specifiques.
#
# Services MikroTik par defaut :
#   telnet      (23)   - CLAIR, toujours desactiver
#   ftp         (21)   - CLAIR, toujours desactiver
#   www         (80)   - admin web CLAIR, desactiver
#   ssh         (22)   - garder, restreindre
#   www-ssl     (443)  - admin web HTTPS, garder ou desactiver
#   api         (8728) - CLAIR, desactiver
#   winbox      (8291) - garder, restreindre
#   api-ssl     (8729) - garder si utilise, restreindre
#
# Usage :
#   /import 04-disable-services.rsc
# -----------------------------------------------------------------------------

/ip service

# --- Desactivation des services en clair ---
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set api disabled=yes

# --- Restriction des services gardes ---
# Remplacer "10.0.0.0/24" par ton subnet LAN admin reel.
# Tu peux mettre plusieurs subnets : "10.0.0.0/24,192.168.88.0/24"

set ssh address=10.0.0.0/24
set winbox address=10.0.0.0/24
set api-ssl address=10.0.0.0/24 disabled=no
set www-ssl address=10.0.0.0/24

:put "[+] Services admin hardened."
:put "    - Desactives : telnet, ftp, www (HTTP), api (non-SSL)"
:put "    - Restreints (address=) : ssh, winbox, api-ssl, www-ssl"
:put ""
:put "    !!! Verifier que tu peux toujours te connecter avant de fermer la session !!!"
:put "    Verifier : /ip service print"

# --- Snmp : desactive par defaut sauf si tu monitores ---
/snmp set enabled=no
:put "    - SNMP : desactive (reactiver seulement si monitoring, avec community custom)"

# --- Discovery : LAN uniquement ---
/ip neighbor discovery-settings set discover-interface-list=LAN
:put "    - Discovery : restreint a interface-list=LAN"
