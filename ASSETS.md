# Ressources et licences

| Ressource | Provenance | Licence |
| --- | --- | --- |
| Mobilier, produits, personnages, sol, façade, véhicule, effets | Dessin procédural original dans `src/view/store_view.gd`, créé pour Brico Empire | MIT, voir LICENSE |
| Icône `assets/icon.svg` | Création originale vectorielle pour ce projet | MIT |
| Sons de vente et d’amélioration | Ondes synthétisées par `src/audio/game_audio.gd` ; aucun échantillon tiers | MIT |
| Captures dans `docs/` | Captures du jeu exécuté dans Godot | MIT pour le contenu original du jeu |
| Police de secours à l’exécution | Police Noto Sans intégrée à Godot, distribuée par le moteur | SIL Open Font License 1.1 ; [licences tierces Godot](https://github.com/godotengine/godot/blob/4.6.3-stable/COPYRIGHT.txt) |
| Moteur Godot 4.6.3 si redistribué avec un build | Godot Engine | MIT, [texte des licences Godot](https://godotengine.org/license/) |

Aucun asset de Lumber Inc ou d’une enseigne réelle, aucun emoji utilisé comme ressource graphique. Aucun téléchargement de packs d’assets, police externe ou dépendance supplémentaire pour jouer. Les outils de vérification Linux (Xvfb/Mesa) ne sont pas des dépendances du jeu.

Le projet source n’embarque pas le binaire de Godot. Si vous distribuez un export avec le moteur, joindre les avis de licence du moteur et de ses composants ; les modèles officiels contiennent ces composants. Le bundle Linux de test conserve le texte de licence fourni par le moteur.

Le dossier `web/` redistribue désormais le runtime web officiel Godot 4.6.3 (WASM gzip, JavaScript et worklets). Les textes intégraux des licences accompagnent cet export : `web/GODOT-LICENSE.txt` et `web/GODOT-COPYRIGHT.txt`. Le chargeur de décompression, le cadre portrait et les outils Python sont des créations du projet sous MIT.
