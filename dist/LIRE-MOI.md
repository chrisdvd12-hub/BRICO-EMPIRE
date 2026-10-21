# Pack de test ordinateur

`brico-empire.pck` contient les données et les scripts compilés du projet, exportés avec Godot 4.6.3. Il faut le moteur Godot 4.6.3 standard pour le lancer :

```sh
godot --main-pack dist/brico-empire.pck
```

Sur Mac ou Windows, utiliser le chemin de l’exécutable Godot téléchargé si la commande `godot` n’est pas installée dans le PATH. Le lancement des sources depuis l’éditeur reste plus simple pour débuter.

Ce pack n’est pas un exécutable autonome, un APK ou une application iPadOS. La version navigateur se trouve dans `web/` et se lance avec `python3 tools/serve_web.py`.
