# Checklist hardening MikroTik / MikroTik hardening checklist

## FR — A faire sur tout MikroTik mis en prod

### DNS (priorité max — vecteur n°1 d'amplification)
- [ ] `/ip dns get allow-remote-requests` = `no` (sauf besoin explicite)
- [ ] Règles firewall `input` qui droppent UDP/TCP 53 depuis `interface-list=WAN`
- [ ] Test depuis l'extérieur : `dig @<IP_PUBLIQUE> example.com` doit timeout

### Services admin
- [ ] `telnet`, `ftp`, `www` (HTTP), `api` (non-SSL) désactivés
- [ ] `ssh`, `winbox`, `api-ssl`, `www-ssl` : `address=` restreint à LAN admin
- [ ] SSH : clé uniquement, password-auth désactivé côté serveur
- [ ] Port Winbox changé (8291 → autre) si exposé

### Firewall
- [ ] `interface-list=WAN` contient **toutes** les interfaces face à Internet (physique + tunnels)
- [ ] **Aucune** règle avec `in-interface=X` spécifique (sauf cas exceptionnel)
- [ ] Chain `input` : accept established/related → LAN → services → **drop all**
- [ ] Chain `forward` : fasttrack + accept established/related → drop invalid → bogons drop → drop all
- [ ] `address-list=bogons` chargée et appliquée sur WAN forward

### SNMP
- [ ] SNMP désactivé (sauf monitoring explicite)
- [ ] Si activé : community ≠ `public`, restreinte par IP source

### Discovery / Leak d'info
- [ ] `/ip neighbor discovery-settings discover-interface-list=LAN`
- [ ] `/tool mac-server` et `/tool mac-server mac-winbox` : LAN uniquement
- [ ] `/tool bandwidth-server` : désactivé (port 2000)

### Utilisateurs
- [ ] Utilisateur `admin` renommé ou supprimé
- [ ] Mot de passe fort (≥20 caractères, aléatoire)
- [ ] Groupes : `full` uniquement pour l'admin, `read` pour le monitoring

### Backup & RouterOS
- [ ] Backup chiffré régulier (`/export` + `/system backup save encryption=aes-sha256`)
- [ ] RouterOS à jour (stable, pas testing/dev)
- [ ] RouterBOOT à jour

### Monitoring / alerting
- [ ] Trafic sortant monitoré (seuil d'alerte défini)
- [ ] Logs firewall exportés (syslog distant ou Prometheus)
- [ ] Alerte si `allow-remote-requests` change

### Audit récurrent
- [ ] Exécuter `scripts/audit/routeros-self-audit.rsc` **tous les mois**
- [ ] Exécuter `scripts/audit/check-open-resolver.sh` depuis un VPS externe **tous les mois**
- [ ] Vérifier les règles firewall lors de chaque ajout d'interface/tunnel

---

## EN — To do on every production MikroTik

### DNS (top priority — #1 amplification vector)
- [ ] `/ip dns get allow-remote-requests` = `no` (unless explicitly needed)
- [ ] Firewall `input` rules dropping UDP/TCP 53 from `interface-list=WAN`
- [ ] Test from outside: `dig @<PUBLIC_IP> example.com` must time out

### Admin services
- [ ] `telnet`, `ftp`, `www` (HTTP), `api` (non-SSL) disabled
- [ ] `ssh`, `winbox`, `api-ssl`, `www-ssl`: `address=` restricted to admin LAN
- [ ] SSH: key-only, password-auth disabled server-side
- [ ] Winbox port changed (8291 → other) if exposed

### Firewall
- [ ] `interface-list=WAN` contains **all** internet-facing interfaces (physical + tunnels)
- [ ] **No** rule with specific `in-interface=X` (except edge cases)
- [ ] Chain `input`: accept established/related → LAN → services → **drop all**
- [ ] Chain `forward`: fasttrack + accept established/related → drop invalid → bogons drop → drop all
- [ ] `address-list=bogons` loaded and applied to WAN forward

### SNMP
- [ ] SNMP disabled (unless explicit monitoring)
- [ ] If enabled: community ≠ `public`, restricted by source IP

### Discovery / Info leak
- [ ] `/ip neighbor discovery-settings discover-interface-list=LAN`
- [ ] `/tool mac-server` and `/tool mac-server mac-winbox`: LAN only
- [ ] `/tool bandwidth-server`: disabled (port 2000)

### Users
- [ ] `admin` user renamed or deleted
- [ ] Strong password (≥20 chars, random)
- [ ] Groups: `full` for admin only, `read` for monitoring

### Backup & RouterOS
- [ ] Regular encrypted backup (`/export` + `/system backup save encryption=aes-sha256`)
- [ ] RouterOS up to date (stable, not testing/dev)
- [ ] RouterBOOT up to date

### Monitoring / alerting
- [ ] Outbound traffic monitored (alert threshold defined)
- [ ] Firewall logs exported (remote syslog or Prometheus)
- [ ] Alert if `allow-remote-requests` changes

### Recurring audit
- [ ] Run `scripts/audit/routeros-self-audit.rsc` **every month**
- [ ] Run `scripts/audit/check-open-resolver.sh` from an external VPS **every month**
- [ ] Re-check firewall rules on every new interface/tunnel
