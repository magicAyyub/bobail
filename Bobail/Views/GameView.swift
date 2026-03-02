import SwiftUI

// MARK: - Game View

struct GameView: View {
    @StateObject private var model = GameModel()
    @State private var showingRules = false
    @State private var showingHistory = false
    @State private var showResetConfirm = false
    @State private var winAlertShown = false

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
            }
        }
        .sheet(isPresented: $showingRules) { RulesView() }
        .sheet(isPresented: $showingHistory) { HistoryView(moves: model.moveHistory) }
        .alert(winMessage, isPresented: $winAlertShown, actions: {
            Button("Rejouer") { model.resetGame(); winAlertShown = false }
            Button("OK", role: .cancel) { winAlertShown = false }
        })
        .onChange(of: model.gameResult) { newResult in
            if newResult != .ongoing { winAlertShown = true }
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
                Label("Règles", systemImage: "questionmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.7))
            }

            Button { showResetConfirm = true } label: {
                Label("Rejouer", systemImage: "arrow.counterclockwise.circle.fill")
                    .font(.caption.bold())
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
            phaseStep(number: 1,
                      label: "Bobail",
                      active: model.phase == .moveBobail,
                      done: model.phase == .moveOwnPawn,
                      isFirst: model.phase == .firstTurnMovePawn)

            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
                .frame(maxWidth: .infinity)

            phaseStep(number: 2,
                      label: "Pion",
                      active: model.phase == .moveOwnPawn || model.phase == .firstTurnMovePawn,
                      done: false,
                      isFirst: false)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func phaseStep(number: Int, label: String, active: Bool, done: Bool, isFirst: Bool) -> some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(active ? Color.orange : (done ? Color.green : Color.white.opacity(0.15)))
                    .frame(width: 28, height: 28)
                if done {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(.caption.bold())
                        .foregroundColor(active ? .white : .white.opacity(0.5))
                }
            }
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(active ? .orange : .white.opacity(0.4))
        }
    }

    private var statusBar: some View {
        Text(model.statusMessage)
            .font(.subheadline.bold())
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(
                Capsule()
                    .fill(statusBarColor.opacity(0.25))
                    .overlay(Capsule().stroke(statusBarColor.opacity(0.5), lineWidth: 1))
            )
            .animation(.easeInOut, value: model.statusMessage)
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

    private var winMessage: String {
        switch model.gameResult {
        case .player1Wins(let r): return r
        case .player2Wins(let r): return r
        case .ongoing: return ""
        }
    }
}

// MARK: - Legend View

struct Legend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Légende")
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.5))

            legendRow(color: .blue, symbol: "1", label: "Joueur 1 (camp ligne 1)")
            legendRow(color: .red, symbol: "2", label: "Joueur 2 (camp ligne 5)")
            legendRow(color: .yellow, symbol: "B", label: "Bobail")
            HStack(spacing: 6) {
                Circle().fill(Color.green.opacity(0.55)).frame(width: 14, height: 14)
                Text("Déplacement possible")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.65))
            }
        }
    }

    private func legendRow(color: Color, symbol: String, label: String) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle().fill(color).frame(width: 16, height: 16)
                Text(symbol).font(.system(size: 9, weight: .bold)).foregroundColor(.white)
            }
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
                    ruleSection(title: "🎯 Objectif") {
                        Text("Ramenez le **Bobail (B)** dans votre camp (votre ligne de départ), OU bloquez-le de sorte que l'adversaire ne puisse plus le bouger.")
                    }

                    ruleSection(title: "🔢 Plateau") {
                        Text("Grille **5×5** — Joueur 1 commence sur la ligne 1 (bleu), Joueur 2 sur la ligne 5 (rouge). Le Bobail part au centre (C3).")
                    }

                    ruleSection(title: "🔁 Déroulement d'un tour") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("**1er tour uniquement :** Joueur 1 bouge seulement un de ses pions.")
                            Text("**Tour normal (étape 1) :** Déplacez le Bobail d'**une seule case** dans n'importe quelle direction.")
                            Text("**Tour normal (étape 2) :** Déplacez un de vos pions.")
                        }
                    }

                    ruleSection(title: "♟️ Déplacement des pions") {
                        Text("Un pion glisse dans la direction choisie sur toute la ligne droite, et s'arrête sur la **dernière case libre avant un obstacle** (pion ami, pion ennemi ou Bobail).")
                    }

                    ruleSection(title: "🟡 Déplacement du Bobail") {
                        Text("Le Bobail se déplace d'exactement **une case** dans n'importe quelle direction (8 directions), vers une case vide uniquement.")
                    }

                    ruleSection(title: "🏆 Victoire") {
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
    private func ruleSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
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
