# État pour reprise — 21 octobre 2026

## Livré

Projet Godot 4.6.3 standard, une scène principale portrait, sources séparées, graphismes et sons originaux. Boucle économique complète, machines à états clients/employés, inventaire auditable, trois familles, trois employés maximum, deux caisses, deux agrandissements, améliorations cinq niveaux, tutoriel, sauvegarde locale et estimation hors ligne. Interface française, glisser/pincer, souris, feuilles contextuelles et mode développeur masqué par défaut.

Dépôt de destination autorisé par le propriétaire : `chrisdvd12-hub/BRICO-EMPIRE`, branche `main`. Le dépôt initial contenait un README uniquement. Les premières sources ont été enregistrées dans le commit `8cbd8a5835ec1d1e4a4d5e936664094dc040b75d` ; documentation, captures et dernières corrections sont ajoutées ensuite. Aucun compte créé, achat, publication de site ou store.

## Décisions

- Rendu Compatibility et dessin vectoriel procédural : pas de pack tiers à récupérer, agents plafonnés.
- Pas fixe 30 Hz ; temps rattrapé borné au retour ; suspension effective en arrière-plan.
- Empreintes des meubles réservées avant construction pour conserver les allées ouvertes ; recalcul de grille à l’achat.
- Transferts synchrones, une tâche par famille. Marchandises non encaissées récupérées en réserve au chargement, avec débordement temporaire autorisé.
- Format de sauvegarde v2 ; v1 migré sans estimation hors ligne basée sur des données absentes.
- Prix du premier agrandissement ajusté de 900 à 1 200 après mesure ; dix simulations finales : 10,19–10,68 minutes pour la première aile, 25,01–26,29 minutes pour le dépôt avec la politique documentée.
- Les améliorations d’employés sont collectives. Pas de musique dans le périmètre réalisé.

## Reprendre

1. Lire README, VERIFICATION et EXPORT.
2. Importer avec Godot 4.6.3, lancer les tests documentés ; ne pas travailler avec la sauvegarde d’un joueur pour les scénarios développeur.
3. Pour l’économie, modifier `data/balance.json`, puis relancer `test_suite.gd` et `balance_sim.gd`. Les contrôles d’interface et la palette se trouvent dans `src/ui` et `src/view`.
4. Refaire les captures avec `ui_smoke.gd` dans une session graphique ; les images de docs sont produites par ce test.

## Priorités suivantes

1. Installer le SDK Android et les modèles Godot correspondants sur une machine de test, exporter et tester sur un téléphone modeste réel.
2. Export iOS depuis un Mac/Xcode existant et test sur l’iPad du propriétaire ; aucune création de compte ou dépense autorisée.
3. Vérifier densités, encoches, gestes croisés interface/caméra, pause système et fermeture forcée.
4. Profiler rendu et simulation sur appareil avant toute promesse de 60 FPS ; réduire les allocations du dessin si nécessaire.
5. Ajuster les tailles des étiquettes et l’évitement des agents après observation sur appareil ; enrichir les animations sans modifier la conservation des stocks.
6. Faire une session manuelle de 30 minutes et ajuster le conseil/tutoriel après retour utilisateur. Ajouter un autre magasin uniquement après validation du premier.

Les limitations précises et le périmètre des tests exécutés sont dans VERIFICATION.md. Ne pas annoncer d’APK/IPA ou de disponibilité App Store/Play Store sans production et validation effectives.


## Demande ajoutée : export iPadOS ou web

Le propriétaire a demandé ensuite une version iPadOS testable **ou** un site web, avec tous les codes sur le dépôt GitHub. L’alternative choisie est l’export WebAssembly officiel du projet Godot, sans réécrire le jeu. Les modèles web officiels ont été récupérés, l’export est fourni dans `web/` et les scripts de reproduction/serveur de test dans `tools/`. Le moteur WASM est compressé (environ 9,4 Mo), avec ses licences.

Le test navigateur utilise Playwright/Chromium et des captures OCR pour vérifier argent initial → ventes réelles → rechargement, et un panneau ouvert. Aucun test Safari réel ni export iPadOS signé. Une publication HTTPS reste distincte de la fabrication de l’export ; respecter la consigne initiale du propriétaire de ne pas publier sans accord.


## Améliorations — 21 octobre 2026

- Familles **Électricité** (2 600 pièces, 40/vente) et **Plomberie** (4 200 pièces, 55/vente) dans l’espace du grand dépôt ; dictionnaires de rayons générés depuis `balance.json`, anciennes sauvegardes compatibles (rayons fermés).
- Événements temporaires (`events` dans `balance.json`), non sauvegardés : un rechargement ne prolonge jamais un bonus. Les revenus restent uniquement des encaissements.
- Succès (`achievements`) : récompense versée une fois, identifiants sauvegardés et filtrés au chargement ; `achievement_rewards` comptabilise l’argent hors ventes.
- Cycle jour/nuit (`CanvasModulate`, 5 min par jour), horloge dans l’en-tête, panneau Succès, bouton Options, toasts sur fond sombre, musique d’ambiance générée au démarrage.
- Tests : 6 145 assertions, 0 échec ; `ui_smoke.gd` 0 échec ; équilibrage relancé : agrandissement 1 vers 8,1–8,5 min (contre 10,2–10,7), grand dépôt vers 18,8–19,4 min (contre 25–26,3), grâce aux récompenses et événements.
- Export web reconstruit avec Godot 4.6.3 officiel (macOS) et modèles `web_nothreads` 4.6.3.
- Quartier autour du magasin (`src/view/world_view.gd`) : calque statique dessiné une seule fois derrière le magasin (sol, parking, route, maisons, parc, commerces, arbres déterministes), calque animé au-dessus (voitures qui ralentissent au passage piéton, passants, ombres de nuages, éclairage nocturne). Limites de caméra élargies pour explorer.
- Textures procédurales : carrelage varié mis en cache (`src/view/store_floor.gd`, redessiné seulement après un achat), murs à panneaux et fenêtres, ombres de contact, liseré de lumière sur les volumes ; herbe, fleurs, grain d’asphalte, fissures, dalles, tuiles et bardage regroupés en quelques `draw_multiline`. Environ 58 images/s mesurées dans Chromium.
- Grande mise à jour : profils de clients (VIP, artisans à 2 articles, conservation du stock vérifiée), satisfaction et note bayésienne sur 40 visites (influence les arrivées), objectifs du jour, statistiques, décoration, franchise (prestige +15 %/niveau), employés nommés à spécialité, camion sur la route, volume, musique de nuit, ambiance, astuces uniques, export/import de sauvegarde par code (horodatage remis à zéro : aucun gain hors ligne par transfert).
- Équilibrage relancé après correction d’un succès trop précoce : grand dépôt vers 14–16 min ; suite : 6 182 assertions, 0 échec ; UI smoke 0 échec. Workflows GitHub Actions ajoutés (tests, Pages).
- Non vérifié : appareil iPad/Android réel (seulement émulation mobile dans Chromium), CI non encore exécutée sur GitHub.


## Intégration des améliorations du collègue — 21 octobre 2026

Les six commits de `ameliorations-contenu-evenements-succes` (jusqu’à `e4ea284`) sont repris en conservant leur historique. Vérification locale complémentaire : 6 196 assertions, zéro échec ; reprise d’une vraie sauvegarde v2 issue de la première version (trois familles), conservation des stocks et nouvelles familles verrouillées par défaut. Test UI sans échec, y compris six ouvertures/fermetures de Statistiques sans croissance des nœuds orphelins.

Corrections d’intégration : le pilote de rafraîchissement du graphe est désormais un enfant du panneau ; les callbacks des tests ne retiennent plus leur propre simulation ; une franchise réinitialise la fenêtre récente de revenus pour ne pas créditer hors ligne le rendement du précédent atelier ; la lecture des boucles audio est arrêtée explicitement à la fermeture. Le test navigateur lit uniquement la zone monétaire, attend un véritable encaissement et contrôle également les erreurs de console.

L’export web est reconstruit avec le moteur officiel Godot 4.6.3. `tools/check_web_export.py` vérifie les signatures, les tailles HTML/pack/WASM, le chargeur gzip et la configuration Vercel. Les fichiers `vercel.json`, `.vercelignore` et `docs/VERCEL.md` préparent l’hébergement statique du dossier web/. Le compte Vercel est connecté ; au premier contrôle, Vercel a refusé l’accès à son espace de projets (403, autorisation de l’espace à compléter). Ne pas annoncer de déploiement Vercel tant qu’un état READY n’est pas reçu.

Les durées et performances de la première version ne décrivent plus automatiquement cette version enrichie. Aucun nouveau résultat sur appareil iPad/Android réel n’est revendiqué. Les workflows GitHub Actions évoqués par le collègue n’étaient pas inclus dans la branche ; le README a été corrigé pour ne pas annoncer une CI absente.
