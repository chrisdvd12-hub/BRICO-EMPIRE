# Hébergement de la version de test

URL confirmée après déploiement réussi : https://brico-empire-jeu.vividmug7.chatgpt.site

Le site est privé au compte propriétaire. Le passage du dépôt GitHub en public ne change pas cette audience. Utiliser le même compte ChatGPT pour accéder au site si une connexion est demandée.

- Projet Sites : `appgprj_6ad8797c89fc8191b5a9c46ab9f3401d`
- Version publiée : `appgprj_6ad8797c89fc8191b5a9c46ab9f3401d~appgver_20d307b01790819188c5bf9d498f2e70`
- Déploiement : `appgdep_6ad879e09cb08191bddf03fd3ad64da4`
- Source hébergée : `8802997f305b9987bf32bf21c67aafbf5862fed4`
- Déploiement confirmé le 2026-10-21T08:38:11.759352+00:00.

Le contenu publié est une copie exacte du dossier web/ (hors WASM brut reproductible et métadonnées .import), placé dans dist/. Le fichier .openai/hosting.json du dépôt d’hébergement contient :

```json
{
  "project_id": "appgprj_6ad8797c89fc8191b5a9c46ab9f3401d",
  "static": {
    "directory": "dist"
  }
}
```

Tous les sources du jeu et les scripts de reproduction de l’export restent dans ce dépôt GitHub. Aucun jeton d’hébergement n’est versionné. Les helpers Sites habituels n’étaient pas installés dans l’environnement ; les sources ont été poussées par Git avec les credentials éphémères transmis par stdin et conservés en mémoire uniquement. Le paquet statique a été construit depuis ce commit exact avec git archive, puis publié par l’outil natif Sites.

La publication HTTPS est confirmée par Sites. Le jeu avait été exécuté et testé sous Chromium avant cette publication ; aucun test sur Safari/iPad réel n’est revendiqué. Les sauvegardes restent locales à cette origine et ne reprennent pas automatiquement celles d’un serveur localhost ou de Godot sur ordinateur.
