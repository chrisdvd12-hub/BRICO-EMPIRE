# Hébergement de la version enrichie

URL active : https://brico-empire-jeu.vividmug7.chatgpt.site

Publication confirmée le 2026-10-21T11:46:30.321916+00:00. Le même lien Safari sert désormais les améliorations du collègue. L’accès reste privé au compte propriétaire ; utiliser le même compte ChatGPT si une connexion est demandée.

- Projet Sites : `appgprj_6ad8797c89fc8191b5a9c46ab9f3401d`
- Version publiée : `appgprj_6ad8797c89fc8191b5a9c46ab9f3401d~appgver_3b6808a816fc819190092361e5d780f1`
- Déploiement : `appgdep_6ad8a60875048191add52121a5e496e9`
- Commit du dépôt d’hébergement : `4759a55d67a7aba4c79529490173318e6ddf775c`
- Commit du jeu intégré sur GitHub : `0fe0c67cc73782cb462631f21ffe4947e14faef3`

Le dossier publié est une copie de `web/`, sans le WASM brut reproductible ni les fichiers `.import`, placé dans `dist/` du dépôt d’hébergement. Le pack vérifié fait 128 032 octets, SHA-256 `2b5414867a492b9505b299b44e6e2de1391a58261f86c3b5953907e113d5c104`. Il inclut les cinq familles, clients VIP/artisans, satisfaction, objectifs du jour, décoration, statistiques, franchise et transfert de sauvegarde.

La configuration d’hébergement conservée est :

```json
{
  "project_id": "appgprj_6ad8797c89fc8191b5a9c46ab9f3401d",
  "static": {
    "directory": "dist"
  }
}
```

Tests avant publication : 6 196 assertions sans échec ; UI sans échec ; Chromium 360 × 640 : 200 → 210 → 220 pièces avec progression conservée au rechargement. Aucun test sur appareil iPad/Android réel n’est revendiqué. Voir [INTEGRATION.md](INTEGRATION.md) et les données brutes dans ce dépôt.

Les helpers Sites n’étaient pas installés dans cet environnement. Le dépôt d’hébergement existant a été ouvert et actualisé par Git, avec les credentials éphémères transmis par stdin et conservés en mémoire uniquement. L’archive statique a été construite depuis le commit poussé exact, puis publiée par l’outil natif Sites. Aucun jeton n’est versionné.

Les sauvegardes restent propres à cette origine. Le futur passage à Vercel nécessite un transfert par le code disponible dans Options si le joueur veut conserver sa partie. Le dépôt est préparé pour Vercel ; à cette livraison, l’API Vercel refusait encore l’accès à l’espace de projets (403), donc aucun déploiement Vercel n’est annoncé.
