# Bobail — Jeu africain de plateau pour iOS

Application iOS deux joueurs du jeu de plateau africain **Bobail**, développée en **SwiftUI**.

---

## 🎮 Rappel des règles

| Élément | Description |
|---|---|
| Plateau | Grille 5×5 |
| Joueur 1 | 5 pions bleus sur la ligne 1 (haut) |
| Joueur 2 | 5 pions rouges sur la ligne 5 (bas) |
| Bobail | Pion neutre doré au centre (C3) |
| Victoire | Ramener le Bobail dans son camp **ou** le bloquer |

**Déroulement d'un tour :**
1. (1er tour uniquement) : Joueur 1 bouge seulement un pion.
2. Tous les autres tours : bouger le Bobail (1 case), puis bouger un pion.

**Déplacement des pions :** glisse en ligne droite jusqu'à la case précédant un obstacle.

---

## 🚀 Installation & exécution

### Prérequis
- macOS 13+ avec **Xcode 15+** installé
- Simulateur iOS 16+ ou un iPhone physique

### Étapes

1. **Créer un nouveau projet Xcode**
   - Ouvrez Xcode → *File > New > Project*
   - Choisissez **iOS → App**
   - Nommez-le **`Bobail`**
   - Interface : **SwiftUI**
   - Language : **Swift**
   - Décochez *Include Tests* (optionnel)

2. **Remplacer les fichiers sources**
   
   Supprimez les fichiers générés par Xcode (`ContentView.swift`, `BobailApp.swift`) et ajoutez les fichiers de ce projet :

   ```
   Bobail/
   ├── BobailApp.swift                 ← Point d'entrée de l'app
   ├── Models/
   │   └── GameModel.swift             ← Logique du jeu
   └── Views/
       ├── ContentView.swift           ← Vue racine
       ├── BoardView.swift             ← Plateau + cellules
       └── GameView.swift              ← Interface complète
   ```

   Dans Xcode : *File > Add Files to "Bobail"* et sélectionnez les dossiers `Models/` et `Views/`.

3. **Lancer**
   - Sélectionnez un simulateur iPhone (ex. iPhone 15)
   - Cmd+R pour compiler et lancer

---

## 🗺️ Architecture du code

```
GameModel (ObservableObject)
    board: [[CellContent]]          — État de toutes les cases
    currentPlayer: Int              — 1 ou 2
    phase: TurnPhase                — firstTurnMovePawn | moveBobail | moveOwnPawn
    selectedCell, validMoves        — Sélection et mouvements valides
    gameResult: GameResult          — ongoing | player1Wins | player2Wins

GameView
    ├── CampBar ×2                  — Indicateurs joueur (haut/bas)
    ├── BoardView                   — Grille cliquable
    │   └── CellView ×25           — Chaque case
    ├── StatusBar                   — Message de statut
    ├── RulesView (sheet)           — Popup des règles
    └── HistoryView (sheet)         — Historique des coups
```

---

## 📐 Fonctionnalités

- ✅ Logique complète du jeu (déplacements, victoire par camp, victoire par blocage)
- ✅ Affichage des cases de destination valides (points verts)
- ✅ Indicateur de phase de tour (Bobail → Pion)
- ✅ Interface adaptative portrait/paysage
- ✅ Fiche de règles intégrée
- ✅ Historique des coups
- ✅ Bouton de réinitialisation avec confirmation
- ✅ Alerte de fin de partie avec possibilité de rejouer
