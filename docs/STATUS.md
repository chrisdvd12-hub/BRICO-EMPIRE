# État actuel — cartoon et profils locaux

Lire [CARTOON.md](CARTOON.md) pour les fonctionnalités, commandes de lancement, vérifications et limites. Moteur Godot 4.6.3, scène 3D avec simulation conservée. Direction : couleurs franches, silhouettes exagérées, enseigne physique et environnement accueillant, avec les jeux de gestion de parcs comme référence générale. Aucun asset de Theme Park ou de marque tierce.

Branche de travail : cartoon-v2, issue de migration-3d ; ancien checkpoint 2D conservé sur refonte-visuelle-2d. La production reste issue de main. Sources et export web doivent être livrés ensemble : Vercel sert web/, il ne compile pas Godot.

## Commandes de reprise

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script tests/test_suite.gd
godot --headless --path . --script tests/profiles.gd
python3 tools/rebuild_web_pack.py
python3 tools/serve_web.py
```

En environnement sans dossier utilisateur inscriptible, définir XDG_DATA_HOME, XDG_CONFIG_HOME et XDG_CACHE_HOME sur des dossiers de travail accessibles.

## Priorités après cette livraison

Tester sur iPad/Safari et Android : clavier virtuel, gestes multiples, cycle de vie et lisibilité. Mesurer les performances sur appareil ; aucune promesse de 60 FPS validée. Affiner les mains et les interactions produits, les transitions des panneaux et la cohérence entre le rendu procédural et l’illustration du chargement C.

Avant toute annonce de publication : confirmer le commit GitHub, le déploiement Vercel READY et le hash du pack public dans VERCEL.md. Les résultats navigateur finaux sont dans docs/cartoon/browser-results.json ; ne pas interpréter une ancienne capture comme la livraison actuelle.
