# -----------------------------------------------------------------------------
# 02-firewall-input-baseline.rsc                            [generique]
#
# Regles firewall chain=input de base pour proteger le routeur lui-meme.
# Bonne pratique generique, pas specifique a l'incident du 2026-04-16.
# Ordre : accept established/related > LAN > services autorises > DROP all.
#
# ATTENTION : si tu appliques ces regles a distance SANS avoir deja
# ajoute une regle pour ton IP admin, tu vas te lockout. Teste depuis la
# console Winbox/SSH en LAN.
#
# Prerequis :
#   - interface-list "WAN" definie (voir 05-interface-lists.rsc)
#   - interface-list "LAN" definie
#
# Usage :
#   /import 02-firewall-input-baseline.rsc
# -----------------------------------------------------------------------------

/ip firewall filter

# --- 1. Accept established & related (obligatoire, haut de liste) ---
add chain=input connection-state=established,related \
    action=accept comment="Accept established/related"

# --- 2. Drop invalid ---
add chain=input connection-state=invalid \
    action=drop comment="Drop invalid"

# --- 3. Accept ICMP (avec rate-limit pour eviter ping flood) ---
add chain=input protocol=icmp limit=50/1s,10 \
    action=accept comment="Accept ICMP (rate-limited 50/s)"
add chain=input protocol=icmp \
    action=drop comment="Drop excess ICMP"

# --- 4. Accept tout depuis LAN ---
add chain=input in-interface-list=LAN \
    action=accept comment="Accept all from LAN"

# --- 5. Services admin : decommente selon tes besoins ---
# SSH depuis WAN (ATTENTION : prefer VPN. Si tu l'ouvres, restreins par IP source).
# add chain=input protocol=tcp dst-port=22 src-address-list=admins \
#     action=accept comment="Allow SSH from admins list"
#
# Winbox depuis WAN (MEME REMARQUE).
# add chain=input protocol=tcp dst-port=8291 src-address-list=admins \
#     action=accept comment="Allow Winbox from admins list"
#
# WireGuard listener (port a adapter)
# add chain=input protocol=udp dst-port=51820 \
#     action=accept comment="Allow WireGuard"

# --- 6. Drop tout ce qui vient du WAN et n'a pas matche au-dessus ---
add chain=input in-interface-list=WAN \
    action=drop comment="Drop everything else from WAN"

:put "[+] Chain input : baseline appliquee."
:put "    Verifier : /ip firewall filter print chain=input"
:put "    NB: les services admin (SSH/Winbox depuis WAN) sont commentes par defaut."
