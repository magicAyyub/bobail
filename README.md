# Bobail — Jeu africain de plateau pour iOS

Application iOS deux joueurs du jeu de plateau africain **Bobail**, développée en **SwiftUI**.

---

## Règles du jeu

| Élément | Description |
|---|---|
| Plateau | Grille 5×5 |
| Joueur 1 | 5 pions bleus sur la ligne 1 (haut) |
| Joueur 2 | 5 pions rouges sur la ligne 5 (bas) |
| Bobail | Pion neutre doré au centre (C3) |

**Déroulement d'un tour :**
1. *1er tour uniquement :* Joueur 1 bouge seulement un pion.
2. Tous les autres tours : bouger le Bobail (1 case), puis bouger un de ses propres pions.

**Déplacement des pions :** glisse en ligne droite (8 directions) jusqu'à la dernière case libre avant un obstacle.

**Victoire :**
- **Par le camp** — amener le Bobail sur sa propre ligne de départ.
- **Par blocage** — entourer le Bobail de sorte que l'adversaire ne puisse plus le bouger.

---

## Installation

### Prérequis
- macOS 13+ avec **Xcode 15+**
- iOS 16+ (simulateur ou iPhone physique)
- Package Swift : **ConfettiSwiftUI** (ajouté via SPM, voir ci-dessous)

### Étapes

1. **Créer un nouveau projet Xcode**
   - *File > New > Project* → iOS → App
   - Nom : **`Bobail`** — Interface : SwiftUI — Language : Swift

2. **Ajouter le package ConfettiSwiftUI**
   - *File > Add Package Dependencies…*
   - URL : `https://github.com/simibac/ConfettiSwiftUI.git`
   - Branche : `master`

3. **Ajouter les fichiers sources**
   
   Supprimez `ContentView.swift` et `BobailApp.swift` générés par Xcode, puis ajoutez :

   ```
   Bobail/
   ├── BobailApp.swift
   ├── Models/
   │   └── GameModel.swift
   └── Views/
       ├── ContentView.swift
       ├── BoardView.swift
       ├── GameView.swift
       ├── TutorialView.swift
       └── InteractiveTutorialGameView.swift
   ```

   Dans Xcode : *File > Add Files to "Bobail"* et sélectionnez les dossiers `Models/` et `Views/`.

4. **Lancer**
   - Sélectionnez un simulateur ou votre iPhone
   - `Cmd+R`

---

## Architecture

```
GameModel (ObservableObject)
    board: [[CellContent]]          — État de toutes les cases
    currentPlayer: Int              — 1 ou 2
    phase: TurnPhase                — firstTurnMovePawn | moveBobail | moveOwnPawn
    selectedCell, validMoves        — Sélection et mouvements valides
    gameResult: GameResult          — ongoing | player1Wins(reason) | player2Wins(reason)
    moveHistory                     — Historique des coups

GameView
    ├── CampBar ×2                  — Indicateurs de joueur (haut/bas)
    ├── BoardView                   — Grille 5×5 cliquable
    │   └── CellView ×25           — Chaque case (damier, pièces, points verts)
    ├── StatusBar                   — Message de phase courant
    ├── WinOverlay                  — Écran de victoire + confettis
    ├── HistoryView (sheet)         — Historique des coups
    └── TutorialFlowView (fullScreenCover)
            ├── TutorialView        — Tutoriel lecture 5 pages (swipe)
            └── InteractiveTutorialGameView
                    └── TutorialController (ObservableObject)
                            — 5 actes interactifs guidés
```

---

## Fonctionnalités

**Jeu**
- Logique complète (déplacements, victoire par camp et par blocage)
- Affichage des destinations valides (points verts)
- Indicateur de phase de tour (Bobail → Pion)
- Écran de victoire avec confettis (ConfettiSwiftUI)
- Historique des coups
- Bouton de réinitialisation avec confirmation
- Interface adaptative portrait et paysage
- Mode sombre natif

**Didacticiel**
- Affiché automatiquement au premier lancement (`@AppStorage`)
- Accessible à tout moment via le bouton `?`
- 5 pages de lecture (swipe pour naviguer)
- Enchaîne vers un tutoriel interactif en 5 actes :
  1. **Premier tour** — déplacer un pion bleu
  2. **Déplacer le Bobail** — 1 case obligatoire
  3. **Déplacer un pion** — glissement jusqu'à l'obstacle
  4. **Victoire par le camp** — amener le Bobail sur sa ligne
  5. **Victoire par blocage** — enfermer le Bobail
