# MonitorBar

Petit moniteur flottant personnalisable pour macOS, écrit en C et Objective-C avec Cocoa, Mach et Metal.

## Compilation

Prérequis : macOS et les Xcode Command Line Tools (`xcode-select --install`). Depuis la racine :

```sh
./build.sh
open build/MonitorBar.app
```

Le script compile et signe localement l’app. Cette signature ad hoc ne remplace pas une signature Developer ID pour la distribution.

## Personnalisation

Faites un **clic droit sur la barre** pour ouvrir les réglages :

- Couleur commune ou couleur individuelle dans **Indicateurs → CPU / RAM / Metal → Couleur…**.
- Thèmes **Terminal**, **Discret** et **Néon**. Un thème remplace les couleurs et le fond ; chaque couleur reste modifiable ensuite.
- Fond optionnel avec curseur d’opacité. Déplacer le curseur active le fond.
- Couleurs selon la valeur : vert sous 60 %, orange à partir de 60 %, rouge à partir de 85 %. Choisir une couleur manuellement désactive cette option.
- Libellés ou symboles : ⚙ CPU, ▤ RAM, ◇ Metal.
- **Espacement des indicateurs** : curseur au clic droit pour resserrer ou écarter les indicateurs en disposition horizontale ou capsules ; réglage sauvegardé et bouton de retour à l’espacement normal.
- Disposition horizontale, verticale ou capsules séparées dans une même fenêtre.
- Indicateurs masquables, avec au moins un indicateur toujours visible. **Placer en premier / dernier** permet de choisir leur ordre.
- Mini-courbe activable par indicateur, sur les 60 derniers échantillons (environ une minute hors veille).
- Alignement aux bords de l’écran et verrouillage de la position et de la taille.

**Déplacer** : glissez la barre. À moins de 20 points d’un bord intérieur, elle s’aligne avec une marge de 10 points si l’option est activée.

**Redimensionner** : la zone invisible de 24 points au bord droit permet de régler la taille quand la barre est déverrouillée. Le curseur change au survol. Tirez ce bord pour agrandir ou réduire proportionnellement le texte, les marges et les courbes (60 % à 250 %). Les commandes **Agrandir la barre**, **Réduire la barre** et **Taille normale** sont également accessibles directement en haut du clic droit. Le verrouillage masque ces repères et bloque le déplacement et le redimensionnement à la souris.

Les réglages et la position sont restaurés au prochain lancement. Les anciennes préférences de couleur, de taille et de fond sont reprises automatiquement. Les courbes repartent à zéro.

## Mesures

- **CPU** : proportion de ticks actifs entre deux relevés Mach.
- **RAM** : estimation basée sur les pages actives, câblées et compressées ; elle peut différer du Moniteur d’activité.
- **Metal** : `currentAllocatedSize / recommendedMaxWorkingSetSize` du périphérique Metal utilisé par **cette app**. Ce n’est ni la charge GPU ni la mémoire GPU totale du système. Une valeur proche de zéro est normale ici ; l’indicateur peut être masqué.
- Une mesure indisponible est affichée par un tiret et crée une interruption dans la courbe.

## Vérification

```sh
clang -fobjc-arc -Wall -Wextra -Isrc tests/OverlayTests.m src/OverlayView.m -framework Cocoa -o /tmp/monitorbar-overlay-tests
/tmp/monitorbar-overlay-tests
```

Vérification manuelle : essayer les trois dispositions et les thèmes, tirer la poignée aux deux limites, masquer/réordonner les indicateurs, afficher les courbes, verrouiller/déverrouiller, tester l’alignement sur plusieurs écrans et relancer pour vérifier la sauvegarde.

## Structure

- `src/AppDelegate.m` : fenêtre, menu, préférences et rafraîchissement.
- `src/OverlayView.m` : rendu, courbes, déplacement et redimensionnement.
- `src/cpu.c`, `src/ram.c`, `src/gpu.m` : collecte des mesures.
- `build.sh` : construction de `build/MonitorBar.app`.
- `tests/OverlayTests.m` : dimensions des dispositions et historique.

Les autres fichiers C et scripts historiques sont conservés pour les expérimentations ; le script de référence est `build.sh` à la racine.

## Commande terminal

`monitorbar` lance l’app depuis n’importe quel dossier une fois le lanceur installé dans `~/.local/bin` (présent dans le PATH). Depuis la racine du projet, `./monitorbar` fonctionne aussi. Les flèches de redimensionnement sont masquées ; le bord droit reste actif.
