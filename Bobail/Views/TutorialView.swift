import SwiftUI

// MARK: - Tutorial Step Model

private struct TutorialStep {
    let title: String
    let subtitle: String
    let description: String
    let illustration: AnyView
}

// MARK: - Tutorial View

struct TutorialView: View {
    var onDismiss: () -> Void

    @State private var currentStep = 0
    @GestureState private var dragOffset: CGFloat = 0

    private let steps: [TutorialStep] = Self.makeSteps()

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0f0c29"), Color(hex: "#302b63"), Color(hex: "#24243e")]),
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // --- Top skip ---
                HStack {
                    Spacer()
                    if currentStep < steps.count - 1 {
                        Button("Passer") { onDismiss() }
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.45))
                            .padding()
                    }
                }

                // --- Pages ---
                TabView(selection: $currentStep) {
                    ForEach(steps.indices, id: \.self) { index in
                        stepPage(steps[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: currentStep)

                // --- Dots + Navigation ---
                VStack(spacing: 20) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(steps.indices, id: \.self) { i in
                            Capsule()
                                .fill(i == currentStep ? Color.white : Color.white.opacity(0.25))
                                .frame(width: i == currentStep ? 22 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentStep)
                        }
                    }

                    // Buttons
                    HStack(spacing: 16) {
                        if currentStep > 0 {
                            Button {
                                withAnimation { currentStep -= 1 }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Circle().fill(Color.white.opacity(0.15)))
                            }
                        } else {
                            Spacer().frame(width: 50)
                        }

                        if currentStep < steps.count - 1 {
                            Button {
                                withAnimation { currentStep += 1 }
                            } label: {
                                HStack(spacing: 8) {
                                    Text("Suivant")
                                        .font(.headline.bold())
                                    Image(systemName: "chevron.right")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 36)
                                .padding(.vertical, 14)
                                .background(
                                    Capsule()
                                        .fill(Color.orange)
                                        .shadow(color: .orange.opacity(0.5), radius: 10, y: 4)
                                )
                            }
                        } else {
                            Button(action: onDismiss) {
                                HStack(spacing: 8) {
                                    Text("Jouer !")
                                        .font(.headline.bold())
                                    Image(systemName: "gamecontroller.fill")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 36)
                                .padding(.vertical, 14)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [.green, .mint],
                                                startPoint: .leading, endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: .green.opacity(0.5), radius: 10, y: 4)
                                )
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Page Layout

    @ViewBuilder
    private func stepPage(_ step: TutorialStep) -> some View {
        VStack(spacing: 24) {
            // Subtitle badge
            Text(step.subtitle.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(3)
                .foregroundColor(.orange.opacity(0.85))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.orange.opacity(0.15)))

            // Title
            Text(step.title)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Illustration
            step.illustration
                .frame(height: 220)
                .padding(.horizontal, 16)

            // Description
            Text(.init(step.description))
                .font(.body)
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 28)

            Spacer()
        }
        .padding(.top, 12)
    }
}

// MARK: - Tutorial Steps Factory

extension TutorialView {
    static private func makeSteps() -> [TutorialStep] {
        [
            // STEP 1 — Board overview
            TutorialStep(
                title: "Bienvenue dans Bobail",
                subtitle: "Le plateau",
                description: "Bobail est un **jeu africain** pour deux joueurs sur une grille **5×5**.\n\nChaque joueur a **5 pions** et il y a un pion spécial central : le **Bobail**.",
                illustration: AnyView(BoardIllustration(mode: .overview))
            ),

            // STEP 2 — The Bobail
            TutorialStep(
                title: "Le Bobail",
                subtitle: "La pièce centrale",
                description: "Le Bobail **(B)** est le pion doré au centre du plateau.\n\nIl peut se déplacer d'**exactement 1 case** dans n'importe quelle des 8 directions, mais uniquement sur une case **vide**.",
                illustration: AnyView(BoardIllustration(mode: .bobailMoves))
            ),

            // STEP 3 — Pawn movement
            TutorialStep(
                title: "Déplacer un pion",
                subtitle: "Tes pièces",
                description: "Tes pions glissent en ligne droite (horizontal, vertical ou diagonal).\n\nIls s'arrêtent sur la **dernière case libre avant un obstacle** : un pion ami, ennemi ou le Bobail.",
                illustration: AnyView(BoardIllustration(mode: .pawnSlide))
            ),

            // STEP 4 — Turn structure
            TutorialStep(
                title: "Déroulement d'un tour",
                subtitle: "Chaque tour",
                description: "**Exception : 1er tour**\nJoueur 1 déplace uniquement un pion.\n\n**Tous les autres tours :**\n① Déplace le Bobail d'1 case\n② Déplace un de tes pions",
                illustration: AnyView(TurnIllustration())
            ),

            // STEP 5 — Win conditions
            TutorialStep(
                title: "Comment gagner ?",
                subtitle: "Victoire",
                description: "Il existe **deux façons** de gagner :\n\n**① Par le camp** — Amène le Bobail sur ta propre ligne de départ.\n\n**② Par le blocage** — Entoure le Bobail pour qu'il ne puisse plus bouger. L'adversaire qui ne peut pas le déplacer **perd**.",
                illustration: AnyView(WinIllustration())
            ),
        ]
    }
}

// MARK: - Mini Board Illustrations

// Shared mini cell
private struct MiniCell: View {
    let content: MiniCellContent
    let highlighted: Bool
    let row: Int
    let col: Int

    enum MiniCellContent {
        case empty, player1, player2, bobail, validMove, blocked
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(tileFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(highlighted ? Color.orange : Color.clear, lineWidth: 2)
                )

            switch content {
            case .player1:
                Circle().fill(Color.blue).padding(4)
            case .player2:
                Circle().fill(Color.red).padding(4)
            case .bobail:
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .padding(3)
                    Text("B").font(.system(size: 9, weight: .black)).foregroundColor(.black.opacity(0.6))
                }
            case .validMove:
                Circle().fill(Color.green.opacity(0.6)).padding(7)
            case .blocked:
                RoundedRectangle(cornerRadius: 3).fill(Color.red.opacity(0.35)).padding(3)
            case .empty:
                EmptyView()
            }
        }
        .frame(width: 36, height: 36)
    }

    private var tileFill: Color {
        if highlighted { return Color.orange.opacity(0.15) }
        return (row + col) % 2 == 0 ? Color(hex: "#c8a06a").opacity(0.7) : Color(hex: "#7a4a2a").opacity(0.6)
    }
}

// MiniBoard — accepts a 5x5 grid
private struct MiniBoard: View {
    let grid: [[MiniCell.MiniCellContent]]
    var highlighted: Set<Position> = []
    var caption: String = ""

    var body: some View {
        VStack(spacing: 4) {
            VStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { r in
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { c in
                            MiniCell(
                                content: grid[r][c],
                                highlighted: highlighted.contains(Position(row: r, col: c)),
                                row: r, col: c
                            )
                        }
                    }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#4a2a0a").opacity(0.7))
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
            )

            if !caption.isEmpty {
                Text(caption)
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

// MARK: — Illustration: Overview

private struct BoardIllustration: View {
    enum Mode { case overview, bobailMoves, pawnSlide }
    let mode: Mode

    var body: some View {
        switch mode {
        case .overview:     overviewView
        case .bobailMoves:  bobailMovesView
        case .pawnSlide:    pawnSlideView
        }
    }

    // Full starting board
    private var overviewView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Circle().fill(Color.red).frame(width: 14, height: 14)
                    Text("Joueur 2").font(.caption2.bold()).foregroundColor(.red)
                }
                VStack(spacing: 4) {
                    Circle()
                        .fill(LinearGradient(colors: [.yellow,.orange], startPoint: .top, endPoint: .bottom))
                        .frame(width: 14, height: 14)
                    Text("Bobail").font(.caption2.bold()).foregroundColor(.orange)
                }
                VStack(spacing: 4) {
                    Circle().fill(Color.blue).frame(width: 14, height: 14)
                    Text("Joueur 1").font(.caption2.bold()).foregroundColor(.blue)
                }
            }

            MiniBoard(grid: startGrid, caption: "Position de départ")
        }
    }

    // Bobail in center, arrows showing its 8 possible moves
    private var bobailMovesView: some View {
        ZStack {
            MiniBoard(grid: bobailGrid, highlighted: [Position(row:2,col:2)], caption: "Cases accessibles au Bobail (B)")

            // Indicator circles for valid moves
            GeometryReader { geo in
                let cellSize: CGFloat = 38
                let padding: CGFloat = 8
                let gap: CGFloat = 2
                let cells: [(Int,Int)] = [
                    (1,1),(1,2),(1,3),
                    (2,1),     (2,3),
                    (3,1),(3,2),(3,3)
                ]
                ForEach(cells.indices, id: \.self) { i in
                    let (r,c) = cells[i]
                    let x = padding + CGFloat(c) * (cellSize + gap) + cellSize / 2
                    let y = padding + CGFloat(r) * (cellSize + gap) + cellSize / 2
                    Circle()
                        .fill(Color.green.opacity(0.55))
                        .frame(width: 10, height: 10)
                        .position(x: x + geo.size.width * 0 + 24, y: y + 8)
                }
            }
        }
    }

    // Show a pawn sliding to the right until blocked
    private var pawnSlideView: some View {
        VStack(spacing: 16) {
            MiniBoard(
                grid: slideGrid,
                highlighted: [Position(row:2, col:0)],
                caption: "Le pion bleu glisse jusqu'à la case verte"
            )

            HStack(spacing: 8) {
                Image(systemName: "circle.fill").foregroundColor(.blue).font(.caption)
                Text("→").font(.caption)
                Image(systemName: "circle.fill").foregroundColor(.green.opacity(0.7)).font(.caption)
                Text("s'arrête avant l'obstacle").font(.caption2).foregroundColor(.white.opacity(0.6))
                Image(systemName: "circle.fill").foregroundColor(.red).font(.caption)
            }
        }
    }

    // Grids
    private var startGrid: [[MiniCell.MiniCellContent]] {
        var g = Array(repeating: Array(repeating: MiniCell.MiniCellContent.empty, count: 5), count: 5)
        for c in 0..<5 { g[0][c] = .player2 }
        for c in 0..<5 { g[4][c] = .player1 }
        g[2][2] = .bobail
        return g
    }

    private var bobailGrid: [[MiniCell.MiniCellContent]] {
        var g = Array(repeating: Array(repeating: MiniCell.MiniCellContent.empty, count: 5), count: 5)
        g[2][2] = .bobail
        // Show valid moves as green dots
        let moves = [(1,1),(1,2),(1,3),(2,1),(2,3),(3,1),(3,2),(3,3)]
        for (r,c) in moves { g[r][c] = .validMove }
        return g
    }

    private var slideGrid: [[MiniCell.MiniCellContent]] {
        var g = Array(repeating: Array(repeating: MiniCell.MiniCellContent.empty, count: 5), count: 5)
        g[2][0] = .player1      // pawn to move
        g[2][3] = .player2      // obstacle (red pawn)
        g[2][2] = .validMove    // landing spot
        for c in 0..<5 { g[0][c] = .player2 }
        for c in 0..<5 { g[4][c] = .player1 }
        return g
    }
}

// MARK: — Illustration: Turn Steps

private struct TurnIllustration: View {
    var body: some View {
        VStack(spacing: 14) {
            // Step indicators
            HStack(spacing: 0) {
                stepBubble(number: "★", label: "1er tour", sublabel: "1 pion seulement", color: .purple)
                    .frame(maxWidth: .infinity)

                VStack {
                    Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1, height: 40)
                    Text("puis").font(.caption2).foregroundColor(.white.opacity(0.3))
                    Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1, height: 40)
                }

                VStack(spacing: 10) {
                    stepBubble(number: "1", label: "Bouge le Bobail", sublabel: "1 case max", color: .orange)
                    stepBubble(number: "2", label: "Bouge un pion", sublabel: "le plus loin", color: .blue)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 8)
        }
    }

    private func stepBubble(number: String, label: String, sublabel: String, color: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(color.opacity(0.85)).frame(width: 34, height: 34)
                Text(number).font(.system(size: 14, weight: .black)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption.bold()).foregroundColor(.white)
                Text(sublabel).font(.system(size: 10)).foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.12)))
    }
}

// MARK: — Illustration: Win conditions

private struct WinIllustration: View {
    var body: some View {
        HStack(spacing: 16) {
            // Win by camp
            VStack(spacing: 8) {
                Text("Par le camp")
                    .font(.caption.bold())
                    .foregroundColor(.blue)

                MiniBoard(grid: winByCamp, highlighted: [Position(row:0, col:2)], caption: "Bobail sur ta ligne !")
            }

            VStack {
                Text("OU").font(.headline.bold()).foregroundColor(.white.opacity(0.4))
            }

            // Win by block
            VStack(spacing: 8) {
                Text("Par blocage")
                    .font(.caption.bold())
                    .foregroundColor(.red)

                MiniBoard(grid: winByBlock, caption: "Bobail cerné → bloqué !")
            }
        }
        .padding(.horizontal, 8)
    }

    private var winByCamp: [[MiniCell.MiniCellContent]] {
        var g = Array(repeating: Array(repeating: MiniCell.MiniCellContent.empty, count: 5), count: 5)
        for c in 0..<5 { g[0][c] = .player1 }
        g[0][2] = .bobail  // bobail on player 1's row
        for c in 0..<5 { g[4][c] = .player2 }
        return g
    }

    private var winByBlock: [[MiniCell.MiniCellContent]] {
        var g = Array(repeating: Array(repeating: MiniCell.MiniCellContent.empty, count: 5), count: 5)
        // Bobail in corner, surrounded
        g[0][0] = .bobail
        g[0][1] = .player1
        g[1][0] = .player2
        g[1][1] = .player1
        // Rest of pieces
        g[4][1] = .player2; g[4][2] = .player2; g[4][3] = .player2; g[4][4] = .player2
        g[0][2] = .player1; g[0][3] = .player1; g[0][4] = .player1
        return g
    }
}
