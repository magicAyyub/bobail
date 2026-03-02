import SwiftUI
import ConfettiSwiftUI

// MARK: - Game View

struct GameView: View {
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @StateObject private var model = GameModel()
    @State private var showingTutorial = false
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
        .fullScreenCover(isPresented: $showingTutorial) {
            TutorialView { showingTutorial = false }
        }
        .onAppear {
            if !hasSeenTutorial {
                hasSeenTutorial = true
                showingTutorial = true
            }
        }
        .confettiCannon(
            trigger: $confettiTrigger,
            num: 60,
            openingAngle: Angle(degrees: 0),
            closingAngle: Angle(degrees: 360),
            radius: 350,
            repetitions: 2,
            repetitionInterval: 0.8
        )
        .onChange(of: model.gameResult) { _, newResult in
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
                Image(systemName: "book.closed.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }

            Button { showingTutorial = true } label: {
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

            Button {
                showingTutorial = true
            } label: {
                Label("Revoir le tutoriel", systemImage: "questionmark.circle")
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

// MARK: - Rules View (quick reference)

struct RulesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {

                    // ── Objectif ───────────────────────────────────────
                    RefCard(color: .orange, icon: "target", title: "Objectif") {
                        AnyView(
                            VStack(alignment: .leading, spacing: 6) {
                                RefRow(icon: "house.fill", tint: .blue,
                                       text: "Amène le Bobail sur **ta propre ligne** (ta ligne de départ).")
                                RefRow(icon: "lock.fill", tint: .red,
                                       text: "Entoure le Bobail pour qu'à son tour l'adversaire **ne puisse pas le bouger**.")
                            }
                        )
                    }

                    // ── Plateau ─────────────────────────────────────────
                    RefCard(color: .cyan, icon: "square.grid.3x3.fill", title: "Plateau") {
                        AnyView(
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    RefPiece(color: .blue,   label: "Joueur 1", detail: "ligne 1  (haut)")
                                    RefPiece(color: .red,    label: "Joueur 2", detail: "ligne 5  (bas)")
                                    RefPiece(isGold: true,   label: "Bobail",   detail: "centre  (C3)")
                                }
                                Spacer()
                                MiniStartBoard()
                            }
                        )
                    }

                    // ── Un tour ─────────────────────────────────────────
                    RefCard(color: .green, icon: "arrow.triangle.2.circlepath", title: "Déroulement d'un tour") {
                        AnyView(
                            VStack(alignment: .leading, spacing: 8) {
                                // First turn exception
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.purple)
                                        .font(.caption)
                                        .padding(.top, 2)
                                    Text("**1er tour :** Joueur 1 déplace uniquement un pion (pas le Bobail).")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.bottom, 2)

                                Divider()

                                // Normal turn
                                TurnStepRow(number: "1", color: .orange,
                                            title: "Bouge le Bobail",
                                            detail: "1 seule case, vers une case vide")
                                TurnStepRow(number: "2", color: .blue,
                                            title: "Bouge un de tes pions",
                                            detail: "glisse jusqu'avant l'obstacle")
                            }
                        )
                    }

                    // ── Déplacements ────────────────────────────────────
                    RefCard(color: .purple, icon: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left", title: "Déplacements") {
                        AnyView(
                            VStack(alignment: .leading, spacing: 10) {
                                Label("**Pion** — glisse en ligne droite (8 directions) et s'arrête sur la **dernière case libre avant un obstacle** (pion ami, ennemi ou Bobail).",
                                      systemImage: "circle.fill")
                                    .labelStyle(IconOnlyLabelStyle())
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                        .padding(.top, 2)
                                    Text("**Pion** — glisse en ligne droite (8 directions) et s'arrête sur la **dernière case libre juste avant un obstacle** (pion ami, ennemi ou Bobail).")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                HStack(alignment: .top, spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(colors: [.yellow,.orange], startPoint: .top, endPoint: .bottom))
                                            .frame(width: 14, height: 14)
                                        Text("B").font(.system(size: 7, weight: .black)).foregroundColor(.black.opacity(0.6))
                                    }
                                    .padding(.top, 2)
                                    Text("**Bobail** — se déplace d'**exactement 1 case** dans n'importe quelle des 8 directions, uniquement vers une case **vide**.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        )
                    }

                    // ── Victoire ─────────────────────────────────────────
                    RefCard(color: .yellow, icon: "trophy.fill", title: "Victoire") {
                        AnyView(
                            VStack(alignment: .leading, spacing: 6) {
                                RefRow(icon: "house.fill", tint: .blue,
                                       text: "**Par le camp** — le Bobail atterrit sur ta ligne de départ (peu importe qui l'y a amené).")
                                RefRow(icon: "lock.fill", tint: .red,
                                       text: "**Par blocage** — le Bobail est entouré. Le joueur qui doit le bouger et ne peut pas **perd**.")
                            }
                        )
                    }

                }
                .padding()
            }
            .navigationTitle("Règles rapides")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Rules Sub-components

private struct RefCard<Content: View>: View {
    let color: Color
    let icon: String
    let title: String
    let content: () -> Content

    init(color: Color, icon: String, title: String, @ViewBuilder content: @escaping () -> Content) {
        self.color = color; self.icon = icon; self.title = title; self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.bold())
                    .foregroundColor(color)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(color.opacity(0.15)))
                Text(title)
                    .font(.headline.bold())
            }
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

private struct RefRow: View {
    let icon: String
    let tint: Color
    let text: LocalizedStringKey

    init(icon: String, tint: Color, text: String) {
        self.icon = icon; self.tint = tint
        self.text = LocalizedStringKey(text)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(tint)
                .font(.caption)
                .padding(.top, 2)
            Text(text).font(.subheadline).foregroundColor(.secondary)
        }
    }
}

private struct RefPiece: View {
    var color: Color = .clear
    var isGold: Bool = false
    let label: String
    let detail: String

    var body: some View {
        HStack(spacing: 8) {
            if isGold {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.yellow,.orange], startPoint: .top, endPoint: .bottom))
                        .frame(width: 18, height: 18)
                    Text("B").font(.system(size: 9, weight: .black)).foregroundColor(.black.opacity(0.6))
                }
            } else {
                Circle().fill(color).frame(width: 18, height: 18)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption.bold())
                Text(detail).font(.system(size: 10)).foregroundColor(.secondary)
            }
        }
    }
}

private struct TurnStepRow: View {
    let number: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(color.opacity(0.85)).frame(width: 26, height: 26)
                Text(number).font(.caption.bold()).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(detail).font(.caption).foregroundColor(.secondary)
            }
        }
    }
}

// Mini starting-board for rules card
private struct MiniStartBoard: View {
    var body: some View {
        VStack(spacing: 1) {
            ForEach(0..<5, id: \.self) { r in
                HStack(spacing: 1) {
                    ForEach(0..<5, id: \.self) { c in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(cellColor(r: r, c: c))
                            .frame(width: 14, height: 14)
                    }
                }
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: "#4a2a0a").opacity(0.5)))
    }

    private func cellColor(r: Int, c: Int) -> Color {
        if r == 0 { return .red.opacity(0.7) }
        if r == 4 { return .blue.opacity(0.7) }
        if r == 2 && c == 2 { return .yellow }
        return (r + c) % 2 == 0 ? Color(hex: "#c8a06a").opacity(0.5) : Color(hex: "#7a4a2a").opacity(0.5)
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
