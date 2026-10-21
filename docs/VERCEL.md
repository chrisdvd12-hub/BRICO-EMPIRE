# Déploiement Vercel

Le dépôt contient les fichiers du jeu déjà exportés dans `web/` et une configuration `vercel.json`. Vercel doit servir ces fichiers statiques ; Godot n’a pas à être installé dans son environnement de build.

Paramètres :

- dépôt : `chrisdvd12-hub/BRICO-EMPIRE` ; branche de production : `main` ;
- Framework Preset : **Other** ; Root Directory : racine du dépôt ;
- pas de commande de build ni d’installation ; Output Directory : **web** ;
- aucun secret, base de données, serveur de jeu ou nom de domaine payant requis.

L’intégration GitHub de Vercel doit avoir accès au dépôt. Les pushes suivants sur `main` pourront alors mettre le jeu à jour automatiquement. Après modification du GDScript ou des données, reconstruire d’abord l’export avec Godot 4.6.3 et `tools/prepare_web.py`, puis enregistrer les fichiers `web/` reconstruits sur GitHub. Un push des sources seuls ne reconstruit pas Godot sur Vercel.

Le runtime `game.wasm.gz` doit être envoyé comme un fichier gzip ordinaire, sans règle manuelle `Content-Encoding: gzip` : le chargeur le décompresse lui-même. Ne pas ajouter de règle SPA qui renverrait `index.html` pour les fichiers du moteur.

Les fichiers sont revalidés à chaque chargement pour éviter de mélanger un nouveau pack de jeu avec un ancien lanceur. La sauvegarde IndexedDB reste propre à chaque domaine. Le passage depuis le lien ChatGPT vers un nouveau lien Vercel ne transfère donc pas automatiquement la partie : utiliser **Options → Copier ma sauvegarde**, puis charger ce code sur le nouveau site. Ne pas effacer l’ancienne sauvegarde avant d’avoir vérifié le transfert.

Un déploiement ne doit être annoncé comme réussi qu’après retour READY de Vercel et vérification des fichiers du jeu. Aucun abonnement, domaine ou service payant n’est nécessaire pour cette préparation.


## État du déploiement de cette livraison

Publication en production confirmée par Vercel (READY), vérifiée le 21 octobre 2026 : **https://brico-empire.vercel.app**.

- Projet : `prj_JrKLmaMxBd1evW0nbyAsTh9Mdigl`.
- Déploiement importé depuis GitHub : `dpl_GvD6LYdN7wbv4kQvkNnp7CDc4zVC`.
- Commit du jeu publié : `17c0af01c7447b30189ac9adf12450fcea7ae0bf` sur `main`.
- Page et pack accessibles publiquement en HTTP 200, sans connexion Vercel.
- Pack : 128 032 octets ; SHA-256 `2b5414867a492b9505b299b44e6e2de1391a58261f86c3b5953907e113d5c104`, identique au pack testé.

Les anciens refus de connexion sont résolus pour la publication. Le helper de consultation protégée renvoie encore 403 ; la vérification HTTP publique indépendante fonctionne. Aucun nouveau test sur iPad réel n’est revendiqué. Les sauvegardes du lien Sites doivent être transférées par code comme expliqué ci-dessus.
