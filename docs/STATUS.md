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
