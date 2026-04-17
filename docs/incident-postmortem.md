# Post-mortem : DNS amplification via tunnel L2TP (2026-04-16)

> Ce kit est né de cet incident. Tous les scripts ici partent des erreurs faites ce jour-là.
> This kit was born from this incident. Every script here is rooted in the mistakes made that day.

---

## FR

### Résumé

Le 2026-04-16, un routeur MikroTik de production a été exploité comme **open resolver DNS** pendant **19 heures** via une interface tunnel L2TP (`NOBGP_L2TP`). Volume : **1,78M requêtes `ANY`** réfléchies vers **9 021 IPs spoofées** (cible principale : un bloc `/29` en Israël), **~5,3 GB sortants sur 19h** (~77 kB/s moyenne).

**Le volume en lui-même est modeste** (un vrai DDoS se mesure en centaines de Gbps). Ce qui rend l'incident grave :

- Le routeur a **participé à une attaque contre des tiers** : responsabilité engagée, risque de notice d'abuse du FAI upstream.
- L'attaque a tourné **19h sans alerte** : l'attaquant pouvait intensifier ou passer le routeur à un botnet pour cibles plus grosses à tout moment.
- La cause racine (angle mort firewall) est **trivialement reproductible** sur n'importe quelle infra qui ajoute un tunnel après coup.

### Cause racine

La règle firewall « Block DNS from WAN » ciblait l'interface principale via `in-interface=sfp-sfpplus1`. Quand un tunnel L2TP a été ajouté plus tard, il **n'était pas couvert** par cette règle. Le DNS du routeur était `allow-remote-requests=yes` pour servir le LAN → les attaquants ont exploité le tunnel L2TP comme point d'entrée pour des requêtes DNS récursives.

### Ce qui a amplifié les dégâts

- **Pi-hole a crashé** (log de 369 MB → SIGSEGV loop) car logrotate en `daily` sans cap de taille.
- **Pi-hole voit le MikroTik comme un seul client** : son rate-limit (désactivé ici, mais même activé à 1000 req/min, inefficace face à une amplification qui passe par le routeur).
- **Aucune alerte** : l'attaque a tourné 19h avant détection via un pic de trafic sortant.

### Leçons (directement intégrées dans ce kit)

1. **Toujours utiliser `interface-list=WAN`**, jamais `in-interface=X`. Un tunnel ajouté plus tard doit juste être ajouté à la liste, pas dupliquer 20 règles.
   → `scripts/hardening/05-interface-lists.rsc`

2. **Bloquer DNS sur WAN en défense in depth**, même si `allow-remote-requests=no`.
   → `scripts/hardening/01-disable-dns-recursion.rsc`

3. **Tester depuis l'extérieur régulièrement** si le routeur répond aux requêtes DNS récursives. Les open resolvers sont scannés en quelques heures.
   → `scripts/audit/check-open-resolver.sh`

4. **Logrotate agressif** sur tous les services DNS (50 MB/h, rotation horaire). Sinon un flood fait exploser le log et crash le service.
   → pas dans ce kit (concerne Pi-hole/Unbound, pas le MikroTik)

5. **Blocage en amont, pas en aval**. Un rate-limit DNS côté Pi-hole ne protège pas contre une amplification qui passe par le routeur en tant que resolver.

### Détails techniques (pour référence)

- Top domaines utilisés pour amplification : domaines avec gros enregistrements DNSSEC/TXT/MX (facteur d'amplification 30-50x sur `query[ANY]`).
- Pattern : `query[ANY]` → réponse 30-50x la taille de la requête.
- Attribution : impossible (IPs source = victimes, pas les attaquants).

---

## EN

### Summary

On 2026-04-16, a production MikroTik router was abused as a **DNS open resolver** for **19 hours** via an L2TP tunnel interface (`NOBGP_L2TP`). Volume: **1.78M `ANY` queries** reflected to **9,021 spoofed IPs** (main target: a `/29` block in Israel), **~5.3 GB outbound over 19h** (~77 kB/s average).

**The raw volume is modest** (a real DDoS is measured in hundreds of Gbps). What makes the incident serious:

- The router **took part in an attack against third parties**: legal exposure, risk of upstream ISP abuse notice.
- The attack ran **19 hours with no alert**: the attacker could have scaled up, or handed the router to a botnet for bigger targets, at any time.
- The root cause (firewall blind spot) is **trivially reproducible** on any infra that adds a tunnel later.

### Root cause

The firewall rule "Block DNS from WAN" targeted the main interface via `in-interface=sfp-sfpplus1`. When an L2TP tunnel was later added, it was **not covered** by that rule. The router's DNS had `allow-remote-requests=yes` to serve the LAN → attackers used the L2TP tunnel as an entry point for recursive DNS queries.

### What amplified the damage

- **Pi-hole crashed** (369 MB log → SIGSEGV loop) because logrotate was `daily` with no size cap.
- **Pi-hole sees the MikroTik as a single client**: its rate-limit (disabled here, but even enabled at 1000 req/min, ineffective against an amplification going through the router).
- **No alert**: the attack ran for 19 hours before detection via an outbound traffic spike.

### Lessons (directly baked into this kit)

1. **Always use `interface-list=WAN`**, never `in-interface=X`. A tunnel added later just has to be added to the list, not duplicate 20 rules.
   → `scripts/hardening/05-interface-lists.rsc`

2. **Block DNS on WAN as defense in depth**, even if `allow-remote-requests=no`.
   → `scripts/hardening/01-disable-dns-recursion.rsc`

3. **Test from the outside regularly** whether your router answers recursive DNS. Open resolvers are scanned within hours.
   → `scripts/audit/check-open-resolver.sh`

4. **Aggressive logrotate** on all DNS services (50 MB/h, hourly rotation). Otherwise a flood blows up the log and crashes the service.
   → not in this kit (relates to Pi-hole/Unbound, not the MikroTik)

5. **Block upstream, not downstream**. A DNS rate-limit on Pi-hole doesn't protect against amplification going through the router as a resolver.

### Technical details (for reference)

- Top domains used for amplification: domains with large DNSSEC/TXT/MX records (30-50x amplification factor on `query[ANY]`).
- Pattern: `query[ANY]` → response 30-50x request size.
- Attribution: impossible (source IPs = victims, not attackers).
