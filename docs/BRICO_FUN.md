# Brico Fun — direction choisie

Le propriétaire a choisi la première proposition graphique : magasin cartoon aux volumes arrondis, couleurs franches, façade avec auvent rayé et enseigne montée, produits reconnaissables et personnages expressifs. La cible est une vraie scène Godot 3D, pas une illustration posée sur la simulation.

## Reprise du 16 novembre 2026

Le workspace a été recréé. La base publiée est le commit 70c4c2b. La branche brico-fun conserve la reprise du chantier ; elle ne représente pas encore une publication en production.

Modèles restaurés : arrondis à normales analytiques, perceuses détaillées, mallettes, marteaux, pots à anses, sacs de terreau, plantes et cartons ; personnages à tête expressive, coudes articulés, tabliers et paniers ouverts. Géométrie et matériaux partagés, ombres portées désactivées.

Scène, façade, signalétique et HUD compact réintégrés. Les tests natifs de visibilité des stocks, agrandissements, sélection 3D et limites de caméra passent sans échec. Contrôle dans le vrai WebAssembly en cours ; reste à confirmer les flux de vente/profils et les captures puis publier ensemble sources et export testé. Les sauvegardes et l’économie de la version publiée sont conservées.

Moteur : Godot 4.6.3 stable. Ne pas confondre une planche générée de direction artistique et une capture du jeu. Le résultat réellement exécuté sera fourni dans docs/brico-fun/ après validation.
