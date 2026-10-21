# Source de la police

Fredoka variable provient de https://github.com/google/fonts/tree/main/ofl/fredoka (auteurs et licence OFL 1.1 dans ../../assets/fonts/OFL.txt).

Les deux fichiers distribués au jeu sont des instances statiques, largeur 100, poids 450 et 600. fontTools n’est requis que pour les reconstruire, pas pour jouer :

```python
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
font = TTFont("tools/font_sources/Fredoka.ttf")
instantiateVariableFont(font, {"wght": 450, "wdth": 100}, inplace=True).save("assets/fonts/Fredoka-Regular.ttf")
# Recharger la source variable pour générer de même le poids 600, Fredoka-Semibold.ttf.
```
