# Intégration des améliorations — 21 octobre 2026

Les six commits de la branche `ameliorations-contenu-evenements-succes`, jusqu’à `e4ea2840039bdd9b1450748ea0d091ff79ae1fe4`, sont conservés dans l’historique de la version intégrée. Le contenu comprend cinq familles, des événements, des succès, un quartier animé, les profils VIP/artisans, la satisfaction, les objectifs du jour, les statistiques, la décoration, la franchise et le transfert de sauvegarde.

Vérifications exécutées avec Godot 4.6.3 stable sur Linux :

- **6 196 assertions, 0 échec**, avec audit de conservation et reprise d’une sauvegarde réelle au format de la première version.
- Test UI : **0 échec** ; sélection, gestes, pause/reprise et six ouvertures/fermetures de Statistiques sans accumulation de nœuds orphelins.
- Export web reconstruit et contrôlé : signatures et tailles PCK/WASM, lanceur gzip et configuration de l’hébergement statique. Résultat : `integration-artifacts.json`.
- Chromium 151, viewport **360 × 640** : **200 → 210 → 220 pièces**, panneau Équipe ouvert, stockage IndexedDB retrouvé et rechargement conservant la partie. Zéro erreur JavaScript et zéro erreur de console. Les avertissements de lecture audio avant un premier geste sont la restriction normale d’autoplay du navigateur.

Corrections complémentaires :

- Le pilote de rafraîchissement des graphiques est rattaché au panneau, pour être détruit à sa fermeture.
- Les callbacks des tests utilisent des références faibles, sans retenir leur propre simulation.
- Une nouvelle franchise repart avec une fenêtre de revenus récents vide ; le rendement de l’ancien atelier ne peut pas produire immédiatement une estimation hors ligne dans le nouveau.
- Arrêt explicite des lecteurs audio lors de la sortie. Le pilote audio Dummy de Godot affiche encore un avertissement de ressources à l’arrêt ; aucune disparition de cet avertissement n’est revendiquée.
- Le test navigateur attend une vente réelle et lit uniquement la zone du montant, afin de ne pas confondre l’argent disponible avec le prix d’un objectif.

Les exports web et ordinateur sont reconstruits dans `web/` et `dist/`. Les instructions Vercel sont dans `VERCEL.md` ; le runtime est précompilé, sans build Godot sur l’hébergeur.

Les résultats sur GPU logiciel Linux ne constituent pas un benchmark mobile. Aucun test sur iPad, iPhone ou Android réel n’est revendiqué. Les durées de progression de la première version ne sont pas les mesures de cette économie enrichie.
