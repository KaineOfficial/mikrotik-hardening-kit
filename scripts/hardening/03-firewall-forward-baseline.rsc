# -----------------------------------------------------------------------------
# 03-firewall-forward-baseline.rsc
#
# Regles firewall chain=forward : trafic qui transite A TRAVERS le routeur
# (LAN <-> Internet principalement). Baseline stricte.
#
# Prerequis :
#   - interface-list "WAN" et "LAN" definies
#   - fasttrack active uniquement si tu n'as pas besoin de queues/mangle
#     avance (sinon skip les 2 premieres lignes)
#
# Usage :
#   /import 03-firewall-forward-baseline.rsc
# -----------------------------------------------------------------------------

/ip firewall filter

# --- 1. Fasttrack established/related (performance) ---
# Commenter si tu utilises du mangle/QoS qui doit inspecter ce trafic
add chain=forward connection-state=established,related \
    action=fasttrack-connection comment="Fasttrack established/related"

# --- 2. Accept established/related (requis meme avec fasttrack) ---
add chain=forward connection-state=established,related \
    action=accept comment="Accept established/related"

# --- 3. Drop invalid ---
add chain=forward connection-state=invalid \
    action=drop comment="Drop invalid (forward)"

# --- 4. Drop bogons entrants (IPs non routables depuis Internet) ---
# Liste "bogons" a creer avec 05-interface-lists.rsc ou en l'importing
# depuis Team Cymru. Les plages RFC1918 ne devraient JAMAIS arriver du WAN.
add chain=forward src-address-list=bogons in-interface-list=WAN \
    action=drop comment="Drop bogons from WAN"

# --- 5. Accept LAN -> WAN (internet sortant) ---
add chain=forward in-interface-list=LAN out-interface-list=WAN \
    action=accept comment="Accept LAN -> WAN"

# --- 6. Accept LAN -> LAN (inter-VLAN si applicable) ---
# A adapter selon ta segmentation. Commente si tu veux isoler les VLANs.
add chain=forward in-interface-list=LAN out-interface-list=LAN \
    action=accept comment="Accept LAN -> LAN"

# --- 7. DNAT (port forwards) : accept uniquement les connexions dstnat-ed ---
add chain=forward connection-nat-state=dstnat in-interface-list=WAN \
    action=accept comment="Accept DNATted connections"

# --- 8. Drop le reste ---
add chain=forward \
    action=drop comment="Drop everything else (forward)"

:put "[+] Chain forward : baseline appliquee."
:put "    Verifier : /ip firewall filter print chain=forward"
