# MikroTik Hardening Kit

> Scripts d'audit + config de durcissement pour RouterOS, nés d'un vrai incident de production.
> Audit scripts + hardening config for RouterOS, born from a real production incident.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![RouterOS](https://img.shields.io/badge/RouterOS-6.x%20%7C%207.x-blue.svg)](https://mikrotik.com/)

---

## FR

### Pourquoi ce kit

Le 16 avril 2026, un MikroTik de production a été exploité comme **open resolver DNS pendant 19 heures** à cause d'une règle firewall qui ciblait une interface spécifique au lieu d'une interface-list. Résultat : **1,78 million de requêtes amplifiées, 5,3 GB de trafic sortant vers des IPs spoofées**. [Post-mortem complet](docs/incident-postmortem.md).

Ce kit existe pour que **la même erreur ne puisse pas se reproduire** — ni sur mon infra, ni sur la tienne. Chaque script ici pointe vers une leçon concrète apprise ce jour-là.

### Ce que contient le kit

```
mikrotik-hardening-kit/
├── scripts/
│   ├── audit/                      # Detection des problemes
│   │   ├── check-open-resolver.sh      # Test DNS recursif depuis externe
│   │   ├── audit-exposed-services.sh   # Nmap des ports admin
│   │   └── routeros-self-audit.rsc     # Audit interne (sur le routeur)
│   └── hardening/                  # Corrections
│       ├── 01-disable-dns-recursion.rsc
│       ├── 02-firewall-input-baseline.rsc
│       ├── 03-firewall-forward-baseline.rsc
│       ├── 04-disable-services.rsc
│       └── 05-interface-lists.rsc
└── docs/
    ├── incident-postmortem.md      # Ce qui est arrive le 16/04
    └── checklist.md                # Checklist complete d'audit
```

### Démarrage rapide

**1. Audit depuis l'extérieur** (VPS, pas le LAN)

```bash
# Test open resolver
./scripts/audit/check-open-resolver.sh <TON_IP_PUBLIQUE>

# Scan des services admin exposes
./scripts/audit/audit-exposed-services.sh <TON_IP_PUBLIQUE>
```

**2. Audit interne** (terminal du MikroTik)

```
/tool fetch url=https://raw.githubusercontent.com/KaineOfficial/mikrotik-hardening-kit/main/scripts/audit/routeros-self-audit.rsc
/import routeros-self-audit.rsc
```

**3. Appliquer le hardening** — **dans cet ordre** :

```
/import 05-interface-lists.rsc      # Crée WAN/LAN et bogons (a adapter avant import !)
/import 01-disable-dns-recursion.rsc
/import 02-firewall-input-baseline.rsc
/import 03-firewall-forward-baseline.rsc
/import 04-disable-services.rsc
```

### Avertissements

- **Ne jamais importer ces scripts à l'aveugle en production**. Lis-les, adapte-les à ton environnement (noms d'interfaces, subnets LAN), teste dans un lab.
- **Risque de lockout** : les scripts `02-firewall-input-baseline` et `04-disable-services` peuvent te couper l'accès si mal configurés. Teste depuis la console locale, pas en SSH distant.
- **Backup obligatoire avant import** :
  ```
  /export file=before-hardening-$(date +%Y%m%d)
  /system backup save name=before-hardening-$(date +%Y%m%d) encryption=aes-sha256
  ```

### Compatibilité

- RouterOS 6.x et 7.x
- Testé sur hAP ac², CCR2004

### Contribuer

Issues et MR bienvenues, surtout si :
- Tu as vécu un incident similaire et veux partager une règle manquante
- Tu as un retour sur la compatibilité RouterOS 7.x
- Tu veux ajouter un script d'audit (ex: MNDP leak, WireGuard check)

### Licence

[MIT](LICENSE) — fais-en ce que tu veux, mais ne me blame pas si tu te lockout.

---

## EN

### Why this kit

On April 16, 2026, a production MikroTik was abused as a **DNS open resolver for 19 hours** because of a firewall rule targeting a specific interface instead of an interface-list. Result: **1.78M amplified queries, 5.3 GB of outbound traffic to spoofed IPs**. [Full post-mortem](docs/incident-postmortem.md).

This kit exists so **the same mistake can't happen again** — not on my infra, not on yours. Every script here points to a concrete lesson learned that day.

### What's inside

```
mikrotik-hardening-kit/
├── scripts/
│   ├── audit/                      # Detect issues
│   │   ├── check-open-resolver.sh      # External recursive DNS test
│   │   ├── audit-exposed-services.sh   # Nmap admin ports
│   │   └── routeros-self-audit.rsc     # In-box audit (on router)
│   └── hardening/                  # Fixes
│       ├── 01-disable-dns-recursion.rsc
│       ├── 02-firewall-input-baseline.rsc
│       ├── 03-firewall-forward-baseline.rsc
│       ├── 04-disable-services.rsc
│       └── 05-interface-lists.rsc
└── docs/
    ├── incident-postmortem.md      # What happened on 04-16
    └── checklist.md                # Full audit checklist
```

### Quick start

**1. External audit** (from a VPS, not the LAN)

```bash
# Open resolver test
./scripts/audit/check-open-resolver.sh <YOUR_PUBLIC_IP>

# Exposed admin services scan
./scripts/audit/audit-exposed-services.sh <YOUR_PUBLIC_IP>
```

**2. Internal audit** (MikroTik terminal)

```
/tool fetch url=https://raw.githubusercontent.com/KaineOfficial/mikrotik-hardening-kit/main/scripts/audit/routeros-self-audit.rsc
/import routeros-self-audit.rsc
```

**3. Apply hardening** — **in this order**:

```
/import 05-interface-lists.rsc      # Creates WAN/LAN and bogons (adapt before importing!)
/import 01-disable-dns-recursion.rsc
/import 02-firewall-input-baseline.rsc
/import 03-firewall-forward-baseline.rsc
/import 04-disable-services.rsc
```

### Warnings

- **Never import blindly in production**. Read the scripts, adapt to your environment (interface names, LAN subnets), test in a lab.
- **Lockout risk**: `02-firewall-input-baseline` and `04-disable-services` can cut your access if misconfigured. Test from the local console, not remote SSH.
- **Mandatory backup before import**:
  ```
  /export file=before-hardening-$(date +%Y%m%d)
  /system backup save name=before-hardening-$(date +%Y%m%d) encryption=aes-sha256
  ```

### Compatibility

- RouterOS 6.x and 7.x
- Tested on hAP ac², CCR2004

### Contributing

Issues and MRs welcome, especially if:
- You've lived a similar incident and want to share a missing rule
- You have feedback on RouterOS 7.x compatibility
- You want to add an audit script (e.g., MNDP leak, WireGuard check)

### License

[MIT](LICENSE) — do what you want with it, but don't blame me if you lock yourself out.
