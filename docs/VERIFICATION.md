# Bilan des vérifications — 21 octobre 2026

## Environnement réel

Godot **4.6.3.stable.official.7d41c59c4**, Linux x86_64. Simulation headless et fenêtre X11 via Xvfb, rendu OpenGL Compatibility avec Mesa llvmpipe (logiciel). Aucun téléphone, tablette, GPU mobile, macOS/Xcode ou SDK Android disponible. Java seul est présent. Le skill d’environnement cloud a été utilisé pour inspecter l’environnement et les accès réseau ; il ne fait pas partie des dépendances du jeu.

## Exécuté et vérifié

`tests/test_suite.gd` : **6 122 assertions, 0 échec**. Le compteur inclut les vérifications du plafond d’agents à chaque pas d’un scénario congestionné ; il ne représente pas 6 122 scénarios indépendants. Les audits de conservation sont exécutés pendant chaque scénario accéléré.

| Cas | Vérification réalisée |
| --- | --- |
| Vente complète | Clients arrivant, prenant une unité, attendant et payant ; l’argent final correspond exactement à la somme encaissée |
| Livraison et réassort | Réserve/shelf initialement vides, départs sans achats puis reprise après livraison gratuite |
| Conservation | Somme réserve + rayons + cartons + paniers + unités vendues = unités livrées, à chaque pas des scénarios |
| Deux employés sur un rayon | Une seule réservation possible ; exécution à plusieurs employés et familles sans famille oubliée |
| Caisse congestionnée | File de plusieurs clients, seul le premier paie, un identifiant ne paie qu’une fois, flux continu |
| Achat impossible et appuis rapides | Pas de modification sans argent ; 20 demandes répétées avec 100 pièces ne donnent qu’un achat |
| Progression | Conditions d’ouverture, peinture, jardinage, deux caisses, recrutements, deux agrandissements, bénéfices du dépôt, plafonds de niveaux |
| Navigation | Chemins valides entrée → points de chaque rayon et réserve → points des employés pour chaque surface ; récupération d’un départ hors grille |
| Sauvegarde | Absence de fichier, écriture atomique, relecture, stocks en transit récupérés, secours après corruption, double corruption, schéma imbriqué invalide, migration v1 → v2 |
| Hors ligne | Minimum d’observations, courte absence, horloge négative/aberrante, plafond 2 h et rechargement sans double crédit |
| Tutoriel | Première vente, première amélioration, réassort, état repris, état passé/terminé conservé |

`tests/ui_smoke.gd` : **0 échec**, rendu réel X11 et événements injectés dans Godot. Vérifie sélection souris et tactile, déplacement sans sélection, pincement à deux contacts, gestes bloqués par la feuille d’interface, puis pause/reprise et crédit unique. Ce test injecte les notifications de cycle de vie : il ne remplace pas le comportement d’un système mobile réel.

Captures produites par le moteur, inspectées visuellement :

- [Boutique initiale](01-boutique.png)
- [Panneau outillage](02-ameliorations.png)
- [Deux agrandissements ouverts](03-magasin-agrandi.png)
- [Équipe et améliorations](04-equipe.png)
- [Petit écran 360 × 640](05-petit-ecran.png)

La vue a été corrigée après inspection pour garder le dépôt entier visible au recentrage. Les boutons normaux ont une hauteur de 72 unités sur la référence 540 de large, soit 48 pixels à 360 pixels de large. La vérification physique en points/dp selon la densité, les lecteurs d’écran et les encoches reste à faire sur appareil. Les étiquettes du magasin sont petites en vue générale ; le zoom et les feuilles fournissent le détail lisible.

## Mesure de progression

`tests/balance_sim.gd` exécute **10 graines déterministes**. La politique achète dès que possible, dans cet ordre : valeur outillage niveau 2 → peinture → second employé → aile 1 → jardinage → caisse 2 → grand dépôt. Aucune injection d’argent, aucun hors ligne ; simulation à pas fixe 30 Hz. Cette politique ne mesure ni le temps de réflexion ni une expérience utilisateur réelle.

| Étape | Temps simulé observé, min |
| --- | --- |
| Première amélioration | Immédiatement finançable avec les 200 pièces initiales ; le tutoriel attend d’abord une vente |
| Peinture | 1,54–1,61 |
| Second employé | 3,97–4,10 |
| Premier agrandissement | **10,19–10,68** |
| Jardinage | 13,40–14,24 |
| Seconde caisse | 16,90–17,66 |
| Second agrandissement | **25,01–26,29** |

La première mesure, avec l’agrandissement à 900 pièces, donnait 8,59–9,05 minutes. Le prix a été porté à **1 200** pour rapprocher ce parcours de l’objectif de 10–15 minutes. Les données brutes finales sont dans [balance-results.json](balance-results.json). Les autres valeurs initiales ont été conservées. Ces résultats ne garantissent pas les mêmes durées pour d’autres décisions.

## Pack de test

Un pack de données Godot `.pck` est exporté avec le preset Linux et lancé dans le runtime 4.6.3. Il contient le jeu et nécessite Godot ; ce n’est pas un exécutable autonome ni un paquet mobile. Les tests, captures et sources documentaires sont exclus du pack. Aucun APK, AAB, IPA ou build iOS signé n’a été produit.

## Limites et validations restantes

- Vérification sur vrais Android/iPhone/iPad : densité, zones de sécurité, installation, suspension système, stockage et audio.
- Objectif **60 FPS sur téléphone de milieu de gamme**, simulation 30 Hz ; aucun chiffre de performance mobile mesuré. Le serveur graphique logiciel ne constitue pas un benchmark mobile.
- Pas de collision physique ni d’évitement dynamique complet : les emplacements de rayon et de file sont réservés ; des croisements ponctuels dans les allées sont possibles. Les caissiers demeurent à leur poste. Les meubles fermés réservent déjà leur empreinte de navigation ; une construction ne peut donc couper un trajet en cours.
- Plan fixe, graphismes procéduraux volontairement simples et une seule boutique. Les améliorations collectives des employés s’appliquent à toute l’équipe ; il n’y a pas de niveaux individuels indépendants.
- La valeur/capacité des rayons change le mobilier aux niveaux 3 et 5 ; le seul service accéléré ne change pas à lui seul son apparence.
- Horloge locale et fichiers non chiffrés, pas de protection complète contre la triche. La copie de secours peut restaurer un état antérieur à une corruption ; ce n’est pas une synchronisation distante.
- Pas de musique ; les deux sons synthétisés ont été chargés à l’exécution, mais le rendu audio utilisé pour les captures était désactivé. Une écoute sur appareil reste à faire.
- Tests automatiques des gestes et inspection de captures réalisés ; une session de jeu manuelle prolongée et des tests d’accessibilité restent nécessaires avant une diffusion large.

Cette version est jouable et vérifiée dans l’environnement décrit. **Elle n’est pas déclarée prête pour les stores.**


## Export navigateur ajouté

Export réel du projet Godot 4.6.3 vers WebAssembly sans threads ; runtime officiel, non réécriture JavaScript du jeu. Le WASM est transporté en gzip (9 382 282 octets) et décompressé par une API standard du navigateur. Chromium 151 / WebGL 2 a démarré le moteur, affiché le magasin et enregistré une base IndexedDB `/userfs`.

Le test `tests/test_web.py` ouvre une vraie page, capture les ventes et le panneau Équipe, puis recharge la page. L’OCR des captures vérifie les montants affichés au lieu de se limiter à la présence d’un canvas. Une inspection visuelle a détecté une superposition de chargement qui restait visible ; elle a été corrigée. Un autre passage a révélé la perte des ventes depuis la dernière sauvegarde périodique : la sauvegarde est désormais aussi déclenchée **après la fin du pas d’encaissement**, afin de ne pas enregistrer un panier déjà payé comme encore en transit.

Les flèches mal rendues par la police embarquée web ont été remplacées par le mot « à ». Les captures 06 à 09 montrent l’exécution navigateur et son rechargement. Le test ne couvre pas Safari réel ni la persistance après suppression des données du site. Le serveur Python fourni est local ; un accès sur iPad depuis un lien nécessite une publication HTTPS distincte.

Résultat final du test navigateur : **200 pièces au départ → 240 après ventes → 250 après rechargement, zéro erreur JavaScript**. Données brutes : [web-results.json](web-results.json). Le supplément après rechargement correspond à de nouvelles ventes automatiques pendant les six secondes de vérification, pas à un crédit hors ligne (absence trop courte).


## Version enrichie intégrée après le travail du collègue

Nouvelle suite exécutée : **6 196 assertions, 0 échec**, couvrant notamment les clients à deux articles, VIP, satisfaction, objectifs du jour, décorations, franchises et la reprise d’une sauvegarde de la première version. Les nouvelles familles sont Électricité et Plomberie. La sauvegarde d’origine conservait argent, marchandises, améliorations, agrandissements et tutoriel ; la simulation reprenait ensuite les ventes.

Le test UI exécute aussi six ouvertures/fermetures du panneau Statistiques sans accumulation de nœuds orphelins. Des corrections ciblées empêchent la réutilisation de l’ancien rendement hors ligne après une franchise et arrêtent explicitement les lecteurs audio à la sortie. Le paquet web est reconstruit et vérifié avec `tools/check_web_export.py`. Les résultats navigateur de cette intégration sont dans `web-results.json` ; les captures 06 à 09 représentent la nouvelle interface.

Les mesures de progression de la première version décrites plus haut restent des résultats historiques. L’économie, les récompenses et le périmètre ont évolué dans la branche du collègue : ne pas reprendre ces durées comme mesures de la version enrichie. Le rendu de test Linux utilise un GPU logiciel et n’est pas une mesure de fluidité sur iPad. Aucun appareil iOS/Android réel n’a été testé lors de cette intégration.

Le bilan de cette intégration, ses limites et les résultats bruts sont détaillés dans [INTEGRATION.md](INTEGRATION.md).
