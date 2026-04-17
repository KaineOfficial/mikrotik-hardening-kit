# -----------------------------------------------------------------------------
# routeros-self-audit.rsc                                   [incident + generique]
#
# A executer DIRECTEMENT sur le routeur MikroTik (terminal Winbox ou SSH).
# Verifie les points les plus couramment oublies apres un deploiement
# "standard" et qui sont la cause #1 d'incidents :
#
#   - DNS allow-remote-requests (open resolver)
#   - Services admin actifs (ip service print)
#   - Firewall avec regles in-interface= specifiques (angle mort sur
#     l'ajout d'une nouvelle interface/tunnel, voir postmortem 2026-04-16)
#   - SNMP community "public"
#   - Discovery protocoles (MNDP, LLDP, CDP)
#
# Usage (sur le routeur) :
#   /import routeros-self-audit.rsc
#
# Aucune modification n'est appliquee : le script affiche des warnings.
# -----------------------------------------------------------------------------

:log info "[audit] === Debut audit MikroTik ==="
:put "=== MikroTik Self-Audit ==="

# --- 1. DNS open resolver ---
:local dnsRemote [/ip dns get allow-remote-requests]
:if ($dnsRemote = true) do={
    :put "[!] DNS: allow-remote-requests=yes (OPEN RESOLVER POTENTIEL)"
    :put "    Fix: /ip dns set allow-remote-requests=no"
    :put "    Ou bloquer DNS depuis WAN avec firewall (voir hardening/01)"
} else={
    :put "[+] DNS: allow-remote-requests=no (OK)"
}

# --- 2. Services admin ---
:put ""
:put "[*] Services admin actifs :"
:foreach svc in=[/ip service find disabled=no] do={
    :local svcName [/ip service get $svc name]
    :local svcPort [/ip service get $svc port]
    :local svcAddr [/ip service get $svc address]
    :if ($svcAddr = "") do={
        :put ("    [!] " . $svcName . " (port " . $svcPort . ") : ECOUTE SUR TOUTES IPS (pas de restriction address=)")
    } else={
        :put ("    [+] " . $svcName . " (port " . $svcPort . ") : restreint a " . $svcAddr)
    }
}
:put "    -> Desactiver les services non utilises : /ip service disable <name>"
:put "    -> Telnet/FTP/HTTP/API (non-SSL) : toujours a desactiver"

# --- 3. Firewall avec in-interface= specifique (angle mort) ---
:put ""
:put "[*] Rules firewall avec in-interface= specifique (risque angle mort) :"
:local specificCount 0
:foreach rule in=[/ip firewall filter find where in-interface!=""] do={
    :local ruleIface [/ip firewall filter get $rule in-interface]
    :local ruleComment [/ip firewall filter get $rule comment]
    :put ("    [!] Rule sur interface '" . $ruleIface . "' (" . $ruleComment . ")")
    :set specificCount ($specificCount + 1)
}
:if ($specificCount > 0) do={
    :put ("    -> " . $specificCount . " rules ciblent une interface precise.")
    :put "    -> Prefere interface-list= (ex: WAN) pour couvrir toutes les WAN,"
    :put "       y compris les tunnels L2TP/WireGuard/OpenVPN ajoutes plus tard."
    :put "    -> Leçon postmortem 2026-04-16 : un tunnel L2TP ajoute plus tard"
    :put "       a contourne une rule 'Block DNS from WAN' ciblant l'interface"
    :put "       principale uniquement. 19h d'attaque DNS amplification."
} else={
    :put "    [+] Aucune rule avec in-interface= specifique trouvee."
}

# --- 4. SNMP community "public" ---
:put ""
:local snmpEnabled [/snmp get enabled]
:if ($snmpEnabled = true) do={
    :put "[*] SNMP actif. Verification communities :"
    :foreach com in=[/snmp community find] do={
        :local comName [/snmp community get $com name]
        :if ($comName = "public") do={
            :put "    [!] Community 'public' presente (defaut, scannee massivement)"
            :put "        Fix: /snmp community set public name=<custom> ou la supprimer"
        }
    }
} else={
    :put "[+] SNMP desactive (OK)"
}

# --- 5. Discovery ---
:put ""
:local discoveryIfaces [:len [/ip neighbor discovery-settings get discover-interface-list]]
:put ("[*] Discovery protocol actif sur interface-list : " . [/ip neighbor discovery-settings get discover-interface-list])
:put "    -> Doit etre sur LAN uniquement, jamais WAN (leak MAC/identity/version)"

:put ""
:put "=== Fin audit ==="
:log info "[audit] === Fin audit MikroTik ==="
