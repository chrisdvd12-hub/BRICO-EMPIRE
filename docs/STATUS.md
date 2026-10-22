# État actuel — migration 3D

Lire [3D.md](3D.md) pour les fonctionnalités, commandes exactes, vérifications et limites. Moteur Godot 4.6.3 ; rendu 3D par défaut, ancien rendu accessible avec --legacy-2d. La simulation et les sauvegardes restent compatibles.

Branches : refonte-visuelle-2d pour le checkpoint, migration-3d pour la version courante. Ne pas remplacer un export web par les seuls scripts : reconstruire avec Godot puis tools/prepare_web.py, vérifier le pack et enregistrer sources ET web/game.pck et dist/brico-empire.pck.

Tests et captures déjà exécutés sous Linux ; validation navigateur et déploiement à suivre dans VERCEL.md. Pas de résultat 60 FPS mobile ou de test Safari réel revendiqué.

Priorités restantes : validation appareils et profilage, finitions des mains/visages et de l’encaissement, transition des panneaux, éclairage jour/nuit 3D et quartier plus riche. Ne pas modifier l’économie pendant ces finitions sans relancer balance_sim.gd.
