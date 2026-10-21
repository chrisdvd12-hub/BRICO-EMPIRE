# Exports et test sur appareils

Version de référence : **Godot 4.6.3 stable standard**. Le projet n’utilise ni C#, ni plugin natif, ni backend.

## Ordinateur, source et pack de test

Lancer le projet avec F5 reste la méthode la plus simple sur Windows, macOS ou Linux.

Un preset Linux est fourni. Pour produire le pack de données, sans modèle d’export :

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --export-pack Linux build/brico-empire.pck
godot --main-pack build/brico-empire.pck
```

Le PCK contient les données et les scripts du jeu ; il nécessite un runtime Godot compatible. Ce n’est ni un APK, ni un export iOS. Les tests/docs sont exclus du contenu exporté. Pour un exécutable Linux normal, installer les modèles d’export **4.6.3** via l’éditeur, puis utiliser le preset Linux. Les versions Windows/macOS se créent avec leurs presets correspondants.

## Android

1. Installer Godot 4.6.3 et ses modèles d’export 4.6.3 : **Éditeur → Gérer les modèles d’export**.
2. Installer OpenJDK 17 et Android SDK. La configuration recommandée pour Godot 4.6 utilise Platform-Tools, Build-Tools 35.0.1, Platform 35, Command-line Tools ; vérifier les éventuelles mises à jour dans la [documentation Godot 4.6](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html).
3. Renseigner les chemins Java SDK et Android SDK dans les paramètres de l’éditeur. Aucun NDK ou build Gradle personnalisé n’est nécessaire au code GDScript de ce prototype.
4. **Projet → Exporter → Ajouter → Android**. Identifiant de test possible : `org.bricoempire.prototype`. Aucun accès Internet n’est nécessaire au jeu : ne pas ajouter de permission réseau.
5. Choisir arm64-v8a (et éventuellement armeabi-v7a), rendu Compatibility, orientation portrait. Créer ou sélectionner un keystore de débogage local selon le guide Godot ; ne pas le versionner.
6. Exporter un **APK de débogage**, l’installer avec `adb install -r chemin/jeu.apk` sur un appareil autorisé pour le débogage USB.
7. Tester petite résolution, multitouch, fermeture, réouverture, audio, stocks et toutes les étapes. Mesurer FPS et charge avec le profileur distant sur l’appareil.

L’environnement utilisé pour cette livraison possède Java mais pas de SDK Android ni de modèles Android installés. Aucun APK n’a été construit ni testé. Il n’a été effectué ni publication ni achat de service.

## iOS / iPad

1. Utiliser un **Mac avec Xcode**, les outils en ligne de commande et Godot 4.6.3 avec ses modèles d’export.
2. Ajouter un preset iOS, identifiant de bundle personnel et équipe de signature dans **Projet → Exporter**. Voir [le guide Godot 4.6](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_ios.html).
3. Exporter le projet Xcode, l’ouvrir dans Xcode, sélectionner son équipe et brancher l’iPad.
4. Compiler et installer depuis Xcode avec une signature de développement adaptée à votre compte existant. Ne pas créer de compte ou payer un abonnement sans décision explicite du propriétaire.
5. Vérifier l’orientation portrait, les zones de sécurité, le pincement réel, les interruptions, la mise en arrière-plan et les données après relance.

Cette livraison a été réalisée sous Linux, sans macOS/Xcode ni appareil Apple accessible. Aucun projet signé, IPA ou test iOS réel n’a été produit. Le ZIP GitHub ne peut pas être installé directement sur iPad.


## Navigateur / Safari sur iPad

Un export Web réel **Godot 4.6.3**, sans threads ni GDExtension, est fourni dans `web/`. Le rendu conserve le magasin animé. WebGL 2, WebAssembly, JavaScript et un contexte sécurisé sont nécessaires. Le transport gzip du moteur est décompressé avec `DecompressionStream` : viser **Safari 16.4+** ou Chrome/Edge récent. Cette configuration a été exécutée sous Chromium, pas sur iPad réel.

Pour lancer localement : `python3 tools/serve_web.py`, puis `http://localhost:8000`. Ne pas ouvrir le fichier HTML directement. Pour un iPad, servir ces fichiers en HTTPS sur un hébergement autorisé ; le HTTP sur une adresse de réseau local ne satisfait pas la vérification de sécurité du moteur.

Pour reproduire l’export :

1. Installer les modèles officiels **4.6.3**, notamment `web_nothreads_release.zip`.
2. Lancer `sh tools/build_web.sh` (ou exécuter ses trois commandes sous Windows).
3. `tools/prepare_web.py` compresse le WASM officiel et insère le chargeur de décompression. Le WASM brut est reproductible et ignoré par Git ; `game.wasm.gz` est versionné.
4. Servir le dossier `web/` avec un hébergement statique HTTPS. Aucun serveur de jeu, compte joueur ni API ne sont nécessaires.

Les fichiers `GODOT-LICENSE.txt` et `GODOT-COPYRIGHT.txt` accompagnent le runtime officiel dans `web/`. La distribution du moteur compressé ne change pas sa licence. Pas de SharedArrayBuffer ni d’en-têtes COOP/COEP requis pour cet export sans threads. Pas de service worker de cache pour ce prototype.

Les données sont stockées dans IndexedDB. Conserver la même origine pour les mises à jour ; effacer les données du site efface la partie. Le stockage web et les interruptions Safari doivent être vérifiés sur l’iPad avant de prétendre à la même fiabilité qu’une application native.
