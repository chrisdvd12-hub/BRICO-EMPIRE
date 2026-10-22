# Ressources et licences

| Ressource | Provenance | Licence |
| --- | --- | --- |
| Modèles 3D, mobilier, produits, personnages articulés, bâtiment et décor | Géométrie originale générée par `src/view3d/models.gd`, `agent_view.gd` et `store_3d.gd`, matériaux mats partagés ; aucune texture photographique | MIT |
| Mobilier, produits, personnages, sol, façade, véhicule, effets 2D conservés | Dessin procédural original dans `src/view/store_view.gd`, créé pour Brico Empire | MIT, voir LICENSE |
| Pictogrammes `assets/ui/*.svg` | Dessins vectoriels originaux créés pour cette refonte | MIT |
| Police Fredoka `assets/fonts/Fredoka-Regular.ttf` et `Fredoka-Semibold.ttf` | [Google Fonts, Fredoka](https://github.com/google/fonts/tree/main/ofl/fredoka), instances statiques 450 et 600 obtenues avec fontTools depuis la source variable conservée dans `tools/font_sources/Fredoka.ttf` ; auteurs dans le fichier de licence | SIL Open Font License 1.1, texte complet : `assets/fonts/OFL.txt` |
| Icône `assets/icon.svg` | Création originale vectorielle pour ce projet | MIT |
| Sons de vente et d’amélioration | Ondes synthétisées par `src/audio/game_audio.gd` ; aucun échantillon tiers | MIT |
| Captures dans `docs/` | Captures du jeu exécuté dans Godot | MIT pour le contenu original du jeu |
| Police de secours à l’exécution | Police Noto Sans intégrée à Godot, distribuée par le moteur | SIL Open Font License 1.1 ; [licences tierces Godot](https://github.com/godotengine/godot/blob/4.6.3-stable/COPYRIGHT.txt) |
| Moteur Godot 4.6.3 si redistribué avec un build | Godot Engine | MIT, [texte des licences Godot](https://godotengine.org/license/) |

Aucun asset de Lumber Inc ou d’une enseigne réelle, aucun emoji utilisé comme ressource graphique. Aucun téléchargement de packs d’assets, dépendance supplémentaire pour jouer ; la police Fredoka est incluse localement. Les outils de vérification Linux (Xvfb/Mesa) ne sont pas des dépendances du jeu.

Le projet source n’embarque pas le binaire de Godot. Si vous distribuez un export avec le moteur, joindre les avis de licence du moteur et de ses composants ; les modèles officiels contiennent ces composants. Le bundle Linux de test conserve le texte de licence fourni par le moteur.

Le dossier `web/` redistribue désormais le runtime web officiel Godot 4.6.3 (WASM gzip, JavaScript et worklets). Les textes intégraux des licences accompagnent cet export : `web/GODOT-LICENSE.txt` et `web/GODOT-COPYRIGHT.txt`. Le chargeur de décompression, le cadre portrait et les outils Python sont des créations du projet sous MIT.
