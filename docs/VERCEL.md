# Déploiement Vercel

Le dépôt contient les fichiers du jeu déjà exportés dans `web/` et une configuration `vercel.json`. Vercel doit servir ces fichiers statiques ; Godot n’a pas à être installé dans son environnement de build.

Paramètres :

- dépôt : `chrisdvd12-hub/BRICO-EMPIRE` ; branche de production : `main` ;
- Framework Preset : **Other** ; Root Directory : racine du dépôt ;
- pas de commande de build ni d’installation ; Output Directory : **web** ;
- aucun secret, base de données, serveur de jeu ou nom de domaine payant requis.

L’intégration GitHub de Vercel doit avoir accès au dépôt. Les pushes suivants sur `main` pourront alors mettre le jeu à jour automatiquement. Après modification du GDScript ou des données, reconstruire d’abord l’export avec Godot 4.6.3 et `python3 tools/rebuild_web_pack.py` (ou export complet puis `tools/prepare_web.py`), puis enregistrer les fichiers `web/` reconstruits sur GitHub. Un push des sources seuls ne reconstruit pas Godot sur Vercel.

Le runtime `game.wasm.gz` doit être envoyé comme un fichier gzip ordinaire, sans règle manuelle `Content-Encoding: gzip` : le chargeur le décompresse lui-même. Ne pas ajouter de règle SPA qui renverrait `index.html` pour les fichiers du moteur.

Les fichiers sont revalidés à chaque chargement pour éviter de mélanger un nouveau pack de jeu avec un ancien lanceur. Les profils et sauvegardes utilisent le stockage local du navigateur, propre à chaque domaine ; l’ancienne sauvegarde IndexedDB est migrée au premier lancement. Le passage depuis le lien ChatGPT vers un nouveau lien Vercel ne transfère donc pas automatiquement la partie : utiliser **Options → Copier ma sauvegarde**, puis charger ce code sur le nouveau site. Ne pas effacer l’ancienne sauvegarde avant d’avoir vérifié le transfert.

Un déploiement ne doit être annoncé comme réussi qu’après retour READY de Vercel et vérification des fichiers du jeu. Aucun abonnement, domaine ou service payant n’est nécessaire pour cette préparation.


## État du déploiement de cette livraison

Production cartoon et profils confirmée **READY le 24 octobre 2026** : **https://brico-empire.vercel.app**.

- Projet : `prj_JrKLmaMxBd1evW0nbyAsTh9Mdigl`.
- Déploiement du jeu : `dpl_EMdcK3U73Zm5GhBzMgAZqc9hr6Mf`.
- Commit du jeu : `6038e0aa09db2816e814e26a3743abb0406d9fcc` sur `main` et `cartoon-v2` ; les commits de documentation suivants conservent le même export.
- Alias de production attribué par Vercel, aucun échec d’alias.
- Pack public téléchargé en HTTP 200 : **2 164 908 octets**, SHA-256 `800ee62387b100c19e0613045417893fc236d1dcc456b3a09b145ab5cb009926`, identique au pack de cette livraison.
- 6 279 assertions de simulation, zéro échec ; tests natifs des profils, zéro échec.
- Chromium exécute le véritable WebAssembly : vente, sélection de rayon, glissement tactile, zoom souris, changement de joueur, rechargement et reprise d’Alice validés. Résultats : `docs/cartoon/browser-results.json`.

Les anciens liens immuables de prévisualisation ne se mettent pas à jour. Utiliser le lien public ci-dessus ; recharger l’onglet Safari si une ancienne session du jeu est encore ouverte. Il n’est pas nécessaire d’effacer les données du site. Les profils sont locaux au navigateur, sans compte ni synchronisation entre appareils.

Aucun test sur iPad ou Android physique ni mesure de FPS mobile revendiqué. Le pincement et le clavier virtuel restent à contrôler sur appareil réel. Aucune application iOS signée n’a été produite dans cette livraison.
