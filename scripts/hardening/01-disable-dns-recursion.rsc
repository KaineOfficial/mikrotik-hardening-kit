# -----------------------------------------------------------------------------
# 01-disable-dns-recursion.rsc
#
# Desactive la resolution DNS recursive depuis l'exterieur.
# C'est LA regle #1 contre les attaques DNS amplification.
#
# Deux approches :
#   A. DESACTIVER completement le DNS recursif (simple, recommande si le
#      routeur ne sert pas de resolveur au LAN).
#   B. GARDER le DNS recursif pour le LAN mais BLOQUER les requetes venant
#      du WAN via firewall (si tu utilises le MikroTik comme DNS interne).
#
# Dans les DEUX cas, le firewall bloque les requetes DNS du WAN en defense
# in depth (ceinture + bretelles).
#
# IMPORTANT : utiliser interface-list=WAN, pas in-interface=X, pour eviter
# l'angle mort sur les tunnels (leçon postmortem 2026-04-16).
#
# Usage :
#   /import 01-disable-dns-recursion.rsc
# -----------------------------------------------------------------------------

# --- Option A : desactivation complete ---
# Decommente la ligne suivante si tu ne veux PAS que le MikroTik serve
# de DNS recursif (meme au LAN). Configure alors tes clients LAN sur
# un autre resolveur (Pi-hole, Unbound, Cloudflare...).
#
# /ip dns set allow-remote-requests=no

# --- Option B : DNS recursif autorise, mais bloque sur WAN (firewall) ---
#
# Prerequis : avoir une interface-list nommee "WAN" regroupant toutes
# les interfaces connectees a Internet (physique + tunnels L2TP/WG/OVPN).
# Voir 05-interface-lists.rsc pour la creation de WAN.

/ip firewall filter
add chain=input protocol=udp dst-port=53 in-interface-list=WAN \
    action=drop comment="Block DNS/UDP from WAN (anti-amplification)"
add chain=input protocol=tcp dst-port=53 in-interface-list=WAN \
    action=drop comment="Block DNS/TCP from WAN (anti-amplification)"

# Verification finale
:put "[+] Regles anti-DNS-amplification ajoutees."
:put "    Verifier : /ip firewall filter print where comment~\"anti-amplification\""
:put ""
:put "    Tester depuis l'exterieur avec :"
:put "    dig @<IP_PUBLIQUE> example.com  # doit timeout"
