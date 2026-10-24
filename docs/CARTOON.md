# Cartoon, chargement C et profils — 24 octobre 2026

Godot 4.6.3 stable, scène 3D existante conservée. Sources sur la branche cartoon-v2, destinées à main après validation.

## Changements

Inspiration générale des jeux de gestion de parcs comme Theme Park : volumes de jouets, silhouettes expressives, couleurs franches et signalétique lisible, sans reprendre leurs ressources.

Palette saturée, lumière blanche plus vive et matériaux mats de type toon ; ombres portées désactivées pour la lumière, les meubles, les acteurs instanciés et les billets ; ombres des panneaux retirées. Personnages élargis de 15 %, corps rehaussé de 22 %, tête/yeux/casquettes redimensionnés. Le plan de navigation et les empreintes des meubles restent identiques pour préserver les passages.

Enseigne sur aile gauche pour dégager entrée et caisses, grand marteau 3D, porche rayé, encadrement orange/blanc et support 3D, plaque vectorielle, emblème maison/marteau et lettres tracées ; aucune superposition de noms flottants sur la façade. Compteur distinct en haut à gauche avec billet dessiné. Les billets apparaissent seulement sur le signal de vente encaissée, avec un effet réduit si demandé ; ils ne créent aucun revenu.

Abords de 16 × 23 m avec parking, route, bâtiments et plantations. Déplacement et zoom restent bornés : le joueur ne peut pas prolonger la carte indéfiniment.

Interface compactée : navigation à icônes cohérentes, en-tête réduit, tutoriel et conseil plus courts pour laisser le magasin visible.

Chargement C : illustration originale choisie par le propriétaire, version WebP, progression fournie par le chargement du moteur, fin du chargement signalée par le véritable écran de profils. Le clavier virtuel web est activé pour la saisie tactile.

## Profils

Six profils nommés, identifiants stables indépendants du nom. Index version 1, parties version 2 dans user://players/. Chaque profil possède un fichier atomique et sa copie de secours. Copier l’ancienne partie dans p_legacy sans supprimer le fichier original ; aucun reset silencieux. Changement de joueur : sauvegarder le joueur sortant, puis charger le nouveau et reconstruire ses agents. Réinitialiser ou importer affecte uniquement le profil actif.

Sur le web, les nouvelles sauvegardes et l’index utilisent le stockage local synchrone du navigateur avec copie de secours : un rechargement rapide ne dépend plus d’un transfert différé vers IndexedDB. L’ancienne partie sur le système de fichiers IndexedDB est lue pour la migration initiale. Si l’index est illisible : secours, puis récupération des fichiers de parties valides. Pas de compte, serveur, mot de passe ou synchronisation entre appareils. Les données restent liées au navigateur et à l’origine ; conserver un code d’export avant de changer de domaine ou d’effacer les données.

## Reconstruire et tester

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script tests/test_suite.gd
godot --headless --path . --script tests/profiles.gd
python3 tools/rebuild_web_pack.py
python3 tools/serve_web.py
BRICO_TEST_URL=http://127.0.0.1:8000/ python3 tests/cartoon_web.py
```

Le runtime officiel 4.6.3 déjà versionné est conservé ; le pack de ressources est réellement reconstruit, son poids est mis à jour dans game.html et vérifié. Aucun nouvel export Android/iOS signé.

## Validation

6 279 assertions économiques sans échec. Tests de profils : migration, argent distinct, reset isolé, chemins invalides, rechargement, index corrompu et limite de six profils. Chromium système exécute le véritable jeu WebAssembly ; captures dans docs/cartoon/. Les résultats finaux du navigateur et le hash du pack sont stockés dans ce dossier.

Safari/iPad et Android réels restent à valider : clavier virtuel, taille des textes, fluidité et cycle de vie. Le rendu du jeu reste une scène 3D procédurale, plus simple que l’illustration détaillée du chargement.
