# -----------------------------------------------------------------------------
# 05-interface-lists.rsc                                    [incident]
#
# Cree les interface-lists "WAN", "LAN" et "bogons" (address-list).
# Indispensable : les autres scripts referencent ces listes au lieu de
# cibler des interfaces specifiques (angle mort, voir postmortem 2026-04-16).
#
# Usage :
#   /import 05-interface-lists.rsc
#
# A ADAPTER : remplace les noms d'interfaces par les tiens
#   - ether1, sfp-sfpplus1 : WAN physique
#   - bridge-lan, vlan-*  : LAN
#   - l2tp-*, wg-*, ovpn-* : tunnels (a ajouter a WAN selon le role)
# -----------------------------------------------------------------------------

/interface list
add name=WAN comment="Toutes les interfaces face a Internet (physique + tunnels)"
add name=LAN comment="Reseaux internes de confiance"

/interface list member
# --- WAN : a adapter ---
add list=WAN interface=ether1 comment="WAN principal"
# add list=WAN interface=sfp-sfpplus1 comment="WAN fibre"
# add list=WAN interface=ether2 comment="WAN failover 4G"
#
# Tunnels qui emergent cote WAN (ex: peer L2TP, WireGuard public).
# Decommente et adapte :
# add list=WAN interface=l2tp-out1 comment="Tunnel L2TP"
# add list=WAN interface=wg-public comment="WireGuard listener public"

# --- LAN : a adapter ---
add list=LAN interface=bridge comment="LAN principal"
# add list=LAN interface=vlan-mgmt
# add list=LAN interface=vlan-users

# --- Address-list "bogons" (IPs non routables sur Internet) ---
# Source : RFC 6890 / IANA special-purpose addresses.
# A ne pas accepter en provenance du WAN (chain=forward).
/ip firewall address-list
add list=bogons address=0.0.0.0/8          comment="This network (bogon)"
add list=bogons address=10.0.0.0/8         comment="RFC1918 private (bogon from WAN)"
add list=bogons address=100.64.0.0/10      comment="CGN (bogon from WAN)"
add list=bogons address=127.0.0.0/8        comment="Loopback (bogon)"
add list=bogons address=169.254.0.0/16     comment="Link-local (bogon)"
add list=bogons address=172.16.0.0/12      comment="RFC1918 private (bogon from WAN)"
add list=bogons address=192.0.0.0/24       comment="IETF Protocol (bogon)"
add list=bogons address=192.0.2.0/24       comment="TEST-NET-1 (bogon)"
add list=bogons address=192.168.0.0/16     comment="RFC1918 private (bogon from WAN)"
add list=bogons address=198.18.0.0/15      comment="Benchmarking (bogon)"
add list=bogons address=198.51.100.0/24    comment="TEST-NET-2 (bogon)"
add list=bogons address=203.0.113.0/24     comment="TEST-NET-3 (bogon)"
add list=bogons address=224.0.0.0/4        comment="Multicast (bogon)"
add list=bogons address=240.0.0.0/4        comment="Reserved (bogon)"

:put "[+] Interface-lists WAN/LAN et address-list bogons crees."
:put "    Verifier :"
:put "    /interface list print"
:put "    /interface list member print"
:put "    /ip firewall address-list print where list=bogons"
:put ""
:put "    !! ADAPTE les noms d'interfaces avant d'importer sur ton routeur !!"
