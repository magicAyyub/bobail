import SwiftUI
import ConfettiSwiftUI

// MARK: - Game View

struct GameView: View {
    @StateObject private var model = GameModel()
    @State private var showingRules = false
    @State private var showingHistory = false
    @State private var showResetConfirm = false
    @State private var confettiTrigger = 0

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let boardWidth = isLandscape
                ? min(geo.size.height - 120, geo.size.width * 0.55)
                : geo.size.width - 40

            // Cell size: 5 cells + labels + gaps
            let cellSize = (boardWidth - 30) / 5

            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#1a1a2e"),
                        Color(hex: "#16213e")
                    ]),
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                if isLandscape {
                    HStack(alignment: .top, spacing: 16) {
                        leftPanel(cellSize: cellSize)
                        rightInfoPanel
                    }
                    .padding()
                } else {
                    VStack(spacing: 12) {
                        topBar
                        playerStrip(player: 2)
                        leftPanel(cellSize: cellSize)
                        playerStrip(player: 1)
                        phaseIndicator
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }

                // Win overlay — rendered on top of everything
                if model.gameResult != .ongoing {
                    winOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.93)))
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: model.gameResult)
        }
        .sheet(isPresented: $showingRules) { RulesView() }
        .sheet(isPresented: $showingHistory) { HistoryView(moves: model.moveHistory) }
        .confettiCannon(
            trigger: $confettiTrigger,
            num: 60,
            openingAngle: Angle(degrees: 0),
            closingAngle: Angle(degrees: 360),
            radius: 350,
            repetitions: 2,
            repetitionInterval: 0.8
        )
        .onChange(of: model.gameResult) { newResult in
            if newResult != .ongoing { confettiTrigger += 1 }
        }
    }

    // MARK: - Win Overlay

    private var winOverlay: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: .orange.opacity(0.7), radius: 16, x: 0, y: 4)

                VStack(spacing: 6) {
                    Text("Partie terminée")
                        .font(.subheadline.bold())
                        .foregroundColor(.white.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(2)

                    Text(winnerName)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(winnerColor)
                }

                Text(winReason)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                Button {
                    model.resetGame()
                } label: {
                    Label("Nouvelle partie", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [winnerColor, winnerColor.opacity(0.65)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                        )
                }
                .padding(.top, 4)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(winnerColor.opacity(0.35), lineWidth: 1.5)
                    )
            )
            .padding(32)
        }
    }

    private var winnerName: String {
        switch model.gameResult {
        case .player1Wins: return "Joueur 1 gagne !"
        case .player2Wins: return "Joueur 2 gagne !"
        case .ongoing: return ""
        }
    }

    private var winReason: String {
        switch model.gameResult {
        case .player1Wins(let r): return r
        case .player2Wins(let r): return r
        case .ongoing: return ""
        }
    }

    private var winnerColor: Color {
        switch model.gameResult {
        case .player1Wins: return .blue
        case .player2Wins: return .red
        case .ongoing: return .white
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func leftPanel(cellSize: CGFloat) -> some View {
        VStack(spacing: 10) {
            BoardView(model: model, cellSize: cellSize)
            statusBar
        }
    }

    private var topBar: some View {
        HStack {
            Text("BOBAIL")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .tracking(4)

            Spacer()

            Button { showingRules = true } label: {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }

            Button { showResetConfirm = true } label: {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
            .confirmationDialog("Recommencer la partie ?", isPresented: $showResetConfirm) {
                Button("Recommencer", role: .destructive) { model.resetGame() }
                Button("Annuler", role: .cancel) {}
            }
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func playerStrip(player: Int) -> some View {
        let isCurrent = model.currentPlayer == player && model.gameResult == .ongoing
        CampBar(player: player, isCurrent: isCurrent, phase: model.phase)
    }

    private var phaseIndicator: some View {
        HStack(spacing: 10) {
            phaseStep(
                icon: "circle.fill",
                label: "Bobail",
                active: model.phase == .moveBobail,
                done: model.phase == .moveOwnPawn
            )

            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
                .frame(maxWidth: .infinity)

            phaseStep(
                icon: "circle.grid.2x2.fill",
                label: "Pion",
                active: model.phase == .moveOwnPawn || model.phase == .firstTurnMovePawn,
                done: false
            )
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func phaseStep(icon: String, label: String, active: Bool, done: Bool) -> some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(active ? Color.orange : (done ? Color.green : Color.white.opacity(0.15)))
                    .frame(width: 30, height: 30)
                if done {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(active ? .white : .white.opacity(0.45))
                }
            }
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(active ? .orange : .white.opacity(0.4))
        }
    }

    private var statusBar: some View {
        HStack(spacing: 6) {
            Image(systemName: statusIcon)
                .font(.caption.bold())
                .foregroundColor(statusBarColor)
            Text(model.statusMessage)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(
            Capsule()
                .fill(statusBarColor.opacity(0.2))
                .overlay(Capsule().stroke(statusBarColor.opacity(0.45), lineWidth: 1))
        )
        .animation(.easeInOut, value: model.statusMessage)
    }

    private var statusIcon: String {
        switch model.phase {
        case .firstTurnMovePawn, .moveOwnPawn: return "circle.grid.2x2.fill"
        case .moveBobail: return "circle.fill"
        }
    }

    private var statusBarColor: Color {
        switch model.gameResult {
        case .player1Wins: return .blue
        case .player2Wins: return .red
        case .ongoing:
            return model.currentPlayer == 1 ? .blue : .red
        }
    }

    private var rightInfoPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            topBar
            playerStrip(player: 1)
            playerStrip(player: 2)
            phaseIndicator
            Divider().background(Color.white.opacity(0.2))
            Legend()
            Spacer()
            Button {
                showingHistory = true
            } label: {
                Label("Historique (\(model.moveHistory.count))", systemImage: "clock.arrow.circlepath")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: 210)
    }

}

// MARK: - Legend View

struct Legend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Légende")
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.5))

            legendRow(tint: .blue,   label: "Joueur 1 (ligne 1)")
            legendRow(tint: .red,    label: "Joueur 2 (ligne 5)")
            legendRow(tint: .yellow, label: "Bobail")
            HStack(spacing: 6) {
                Circle().fill(Color.green.opacity(0.55)).frame(width: 12, height: 12)
                Text("Déplacement possible")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.65))
            }
        }
    }

    private func legendRow(tint: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "circle.fill")
                .foregroundColor(tint)
                .font(.system(size: 12))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.65))
        }
    }
}

// MARK: - Rules View

struct RulesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ruleSection(icon: "target", iconColor: .orange, title: "Objectif") {
                        Text("Ramenez le **Bobail (B)** dans votre camp (votre ligne de départ), OU bloquez-le de sorte que l'adversaire ne puisse plus le bouger.")
                    }

                    ruleSection(icon: "square.grid.3x3.fill", iconColor: .blue, title: "Plateau") {
                        Text("Grille **5×5** — Joueur 1 commence sur la ligne 1 (bleu), Joueur 2 sur la ligne 5 (rouge). Le Bobail part au centre (C3).")
                    }

                    ruleSection(icon: "arrow.triangle.2.circlepath", iconColor: .green, title: "Déroulement d'un tour") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("**1er tour uniquement :** Joueur 1 bouge seulement un de ses pions.")
                            Text("**Tour normal (étape 1) :** Déplacez le Bobail d'**une seule case** dans n'importe quelle direction.")
                            Text("**Tour normal (étape 2) :** Déplacez un de vos pions.")
                        }
                    }

                    ruleSection(icon: "arrow.up.and.down.and.arrow.left.and.right", iconColor: .purple, title: "Déplacement des pions") {
                        Text("Un pion glisse dans la direction choisie sur toute la ligne droite, et s'arrête sur la **dernière case libre avant un obstacle** (pion ami, pion ennemi ou Bobail).")
                    }

                    ruleSection(icon: "circle.fill", iconColor: .yellow, title: "Déplacement du Bobail") {
                        Text("Le Bobail se déplace d'exactement **une case** dans n'importe quelle direction (8 directions), vers une case vide uniquement.")
                    }

                    ruleSection(icon: "trophy.fill", iconColor: .yellow, title: "Victoire") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Amener le Bobail sur **votre propre camp** (votre ligne de départ).")
                            Text("• Bloquer le Bobail : si à votre tour vous ne pouvez pas bouger le Bobail, l'adversaire gagne.")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Règles du Bobail")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func ruleSection<Content: View>(
        icon: String,
        iconColor: Color,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title).font(.headline)
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
            }
            content()
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(10)
    }
}

// MARK: - History View

struct HistoryView: View {
    let moves: [(player: Int, description: String)]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Group {
                if moves.isEmpty {
                    VStack {
                        Image(systemName: "clock")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Aucun coup joué")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(Array(moves.enumerated()), id: \.offset) { index, move in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                                .frame(width: 24)

                            Circle()
                                .fill(move.player == 1 ? Color.blue : Color.red)
                                .frame(width: 10, height: 10)

                            Text("J\(move.player) — \(move.description)")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Historique des coups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    GameView()
}
