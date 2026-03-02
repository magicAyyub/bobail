import SwiftUI
import Combine

// MARK: - Tutorial Controller

final class TutorialController: ObservableObject {

    // MARK: - Types

    enum ActPhase: Equatable {
        case waitingForPiece
        case waitingForDestination(from: Position)
        case opponentPlaying
    }

    enum WinKind { case camp, block }

    struct Act {
        let badge: String
        let badgeColor: Color
        let title: String
        let primaryInstruction: String
        let secondaryInstruction: String
    }

    // MARK: - Published State

    @Published var board: [[CellContent]] = []
    @Published var selectedCell: Position?          = nil
    @Published var validMoves: [Position]           = []
    @Published var highlightedPieces: Set<Position> = []
    @Published var actIndex: Int                    = 0
    @Published var phase: ActPhase                  = .waitingForPiece
    @Published var isOpponentPlaying: Bool          = false
    @Published var opponentHint: String             = ""
    @Published var isComplete: Bool                 = false
    @Published var showCampSuccess: Bool            = false
    @Published var winKind: WinKind                 = .camp

    // MARK: - Acts Metadata

    let acts: [Act] = [
        Act(
            badge: "Tour spécial", badgeColor: .purple,
            title: "Premier tour",
            primaryInstruction:   "Votre premier tour est spécial : déplacez uniquement un pion bleu.\nAppuyez dessus, puis choisissez la case verte.",
            secondaryInstruction: ""
        ),
        Act(
            badge: "Tour normal ①/2", badgeColor: .orange,
            title: "Déplacez le Bobail",
            primaryInstruction:   "Chaque tour commence par bouger le Bobail doré (B) d'une seule case.\nAppuyez dessus, puis choisissez une case verte.",
            secondaryInstruction: ""
        ),
        Act(
            badge: "Tour normal ②/2", badgeColor: .blue,
            title: "Déplacez un pion",
            primaryInstruction:   "Bien ! Maintenant faites glisser l'un de vos pions bleus.\nIl s'arrête sur la dernière case libre avant un obstacle.",
            secondaryInstruction: ""
        ),
        Act(
            badge: "Mise en situation", badgeColor: Color(hex: "#f0b429"),
            title: "Victoire par le camp",
            primaryInstruction:   "Le Bobail est à une case de votre ligne de départ !\nAmenez-le là-bas pour remporter la partie.",
            secondaryInstruction: ""
        ),
        Act(
            badge: "Mise en situation", badgeColor: Color(hex: "#e03131"),
            title: "Victoire par blocage",
            primaryInstruction:   "Le Bobail n'a plus qu'une seule case libre !\nDéplacez votre pion bleu pour la bloquer et gagner.",
            secondaryInstruction: ""
        ),
    ]

    var currentAct: Act { acts[min(actIndex, acts.count - 1)] }

    var currentInstruction: String { currentAct.primaryInstruction }

    // MARK: - Init

    init() { setupAct(0) }

    // MARK: - Tap Handler

    func handleTap(_ pos: Position) {
        guard !isOpponentPlaying, !isComplete else { return }

        switch phase {

        case .waitingForPiece:
            guard highlightedPieces.contains(pos) else { return }
            selectedCell = pos
            let content  = board[pos.row][pos.col]
            validMoves   = content == .bobail ? computeBobailMoves(from: pos) : computePawnMoves(from: pos)
            phase        = .waitingForDestination(from: pos)

        case .waitingForDestination(let from):
            if pos == from {
                selectedCell = nil; validMoves = []; phase = .waitingForPiece; return
            }
            if highlightedPieces.contains(pos) {
                selectedCell = pos
                let content  = board[pos.row][pos.col]
                validMoves   = content == .bobail ? computeBobailMoves(from: pos) : computePawnMoves(from: pos)
                phase        = .waitingForDestination(from: pos)
                return
            }
            guard validMoves.contains(pos) else { return }

            let movedContent = board[from.row][from.col]
            board[from.row][from.col] = .empty
            board[pos.row][pos.col]   = movedContent
            selectedCell = nil; validMoves = []

            afterMove(movedContent: movedContent, to: pos)

        case .opponentPlaying:
            break
        }
    }

    // MARK: - After Each Move

    private func afterMove(movedContent: CellContent, to dest: Position) {
        switch actIndex {

        case 0:
            // First-turn pawn moved → opponent plays full turn → act 1
            autoPlayOpponent { DispatchQueue.main.async { self.setupAct(1) } }

        case 1:
            // Bobail moved → now move a pawn (act 2)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { self.setupAct(2, keepBoard: true) }

        case 2:
            // Pawn moved → opponent plays → camp win scenario (act 3)
            autoPlayOpponent { DispatchQueue.main.async { self.setupAct(3) } }

        case 3:
            // Camp win: bobail must reach row 0 → show brief celebration, then advance to act 4
            if movedContent == .bobail && dest.row == 0 {
                withAnimation(.spring(response: 0.45)) { showCampSuccess = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    withAnimation { self.showCampSuccess = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        self.setupAct(4)
                    }
                }
            } else {
                highlightedPieces = findBobail().map { [$0] } ?? []
                phase = .waitingForPiece
            }

        case 4:
            // Block win: after pawn move, bobail must be surrounded
            if let bobailPos = findBobail(), computeBobailMoves(from: bobailPos).isEmpty {
                winKind = .block
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.spring(response: 0.45)) { self.isComplete = true }
                }
            } else {
                highlightedPieces = findPawns(of: .player1)
                phase = .waitingForPiece
            }

        default: break
        }
    }

    // MARK: - Act Setup

    func setupAct(_ index: Int, keepBoard: Bool = false) {
        actIndex                 = index
        selectedCell             = nil
        validMoves               = []
        phase                    = .waitingForPiece

        switch index {
        case 0:
            board             = makeStartBoard()
            highlightedPieces = Set((0..<5).map { Position(row: 0, col: $0) })
        case 1:
            if !keepBoard { board = makeStartBoard() }
            highlightedPieces = findBobail().map { [$0] } ?? []
        case 2:
            // Keep board as-is (same turn, just switched from Bobail to pawn)
            highlightedPieces = findPawns(of: .player1)
        case 3:
            board             = makeWinScenarioBoard()
            highlightedPieces = findBobail().map { [$0] } ?? []
        case 4:
            board             = makeBlockingBoard()
            highlightedPieces = findPawns(of: .player1)
        default:
            highlightedPieces = []
        }
    }

    // MARK: - Opponent Auto-Play

    private func autoPlayOpponent(completion: @escaping () -> Void) {
        phase             = .opponentPlaying
        isOpponentPlaying = true
        opponentHint      = "L'adversaire déplace le Bobail…"

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
            guard let self else { return }
            if let bobailPos = self.findBobail() {
                let moves = self.computeBobailMoves(from: bobailPos)
                if let dest = moves.randomElement() {
                    self.board[bobailPos.row][bobailPos.col] = .empty
                    self.board[dest.row][dest.col] = .bobail
                }
            }
            self.opponentHint = "L'adversaire déplace un pion…"

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) { [weak self] in
                guard let self else { return }
                let pawns = Array(self.findPawns(of: .player2))
                if let pawn = pawns.randomElement() {
                    let moves = self.computePawnMoves(from: pawn)
                    if let dest = moves.randomElement() {
                        self.board[pawn.row][pawn.col] = .empty
                        self.board[dest.row][dest.col] = .player2
                    }
                }
                self.isOpponentPlaying = false
                self.opponentHint      = ""
                self.phase             = .waitingForPiece
                completion()
            }
        }
    }

    // MARK: - Board Presets

    private func makeStartBoard() -> [[CellContent]] {
        var b = Array(repeating: Array(repeating: CellContent.empty, count: 5), count: 5)
        for c in 0..<5 { b[0][c] = .player1 }
        for c in 0..<5 { b[4][c] = .player2 }
        b[2][2] = .bobail
        return b
    }

    /// Bobail at [2][2], surrounded on 7/8 neighbors.
    /// Only escape: [1][2] (up).
    /// Player1 has a pawn at [0][2] — slides down to [1][2] → Bobail trapped → win by block.
    private func makeBlockingBoard() -> [[CellContent]] {
        var b = Array(repeating: Array(repeating: CellContent.empty, count: 5), count: 5)
        b[2][2] = .bobail
        // 7 blockers (all neighbors of [2][2] except [1][2])
        b[1][1] = .player2; b[1][3] = .player2
        b[2][1] = .player2; b[2][3] = .player2
        b[3][1] = .player2; b[3][2] = .player2; b[3][3] = .player2
        // [1][2] is intentionally empty — the last escape
        // Player1 pawn that slides from [0][2] down to [1][2]
        b[0][2] = .player1
        // Extra pieces for realism
        b[0][0] = .player1; b[0][4] = .player1; b[1][4] = .player1
        b[4][0] = .player2; b[4][4] = .player2
        return b
    }

    /// Bobail at [1][2] — one step from player1 camp row (row 0).
    private func makeWinScenarioBoard() -> [[CellContent]] {
        var b = Array(repeating: Array(repeating: CellContent.empty, count: 5), count: 5)
        b[1][2] = .bobail
        b[0][0] = .player1; b[0][1] = .player1; b[0][3] = .player1; b[0][4] = .player1
        b[3][0] = .player1
        b[4][1] = .player2; b[4][2] = .player2; b[4][3] = .player2; b[4][4] = .player2
        b[2][4] = .player2
        return b
    }

    // MARK: - Movement Computation

    func computePawnMoves(from pos: Position) -> [Position] {
        var result: [Position] = []
        for (dr, dc) in [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)] as [(Int,Int)] {
            var r = pos.row + dr, c = pos.col + dc
            var last: Position?
            while r >= 0, r < 5, c >= 0, c < 5 {
                guard board[r][c] == .empty else { break }
                last = Position(row: r, col: c); r += dr; c += dc
            }
            if let l = last { result.append(l) }
        }
        return result
    }

    func computeBobailMoves(from pos: Position) -> [Position] {
        ([(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)] as [(Int,Int)]).compactMap { (dr, dc) in
            let r = pos.row + dr, c = pos.col + dc
            guard r >= 0, r < 5, c >= 0, c < 5, board[r][c] == .empty else { return nil }
            return Position(row: r, col: c)
        }
    }

    func findBobail() -> Position? {
        for r in 0..<5 { for c in 0..<5 { if board[r][c] == .bobail { return Position(row: r, col: c) } } }
        return nil
    }

    private func findPawns(of kind: CellContent) -> Set<Position> {
        var s = Set<Position>()
        for r in 0..<5 { for c in 0..<5 { if board[r][c] == kind { s.insert(Position(row: r, col: c)) } } }
        return s
    }
}

// MARK: - Interactive Tutorial Game View

struct InteractiveTutorialGameView: View {
    var onDismiss: () -> Void

    @StateObject private var tutorial = TutorialController()
    @State private var pulse: Bool    = false
    @State private var showSkipAlert  = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0f0c29"), Color(hex: "#302b63"), Color(hex: "#24243e")]),
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar.padding(.horizontal, 20).padding(.top, 16)
                progressSteps.padding(.horizontal, 20).padding(.top, 14)
                actHeader.padding(.horizontal, 24).padding(.top, 18)
                Spacer(minLength: 8)
                boardSection.padding(.horizontal, 16)
                Spacer(minLength: 8)
                instructionBubble.padding(.horizontal, 24).padding(.bottom, 32)
            }

            if tutorial.isOpponentPlaying {
                opponentOverlay.transition(.opacity)
            }

            if tutorial.showCampSuccess {
                campSuccessOverlay.transition(.opacity.combined(with: .scale(scale: 0.94)))
            }

            if tutorial.isComplete {
                victoryOverlay.transition(.opacity.combined(with: .scale(scale: 0.94)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: tutorial.isOpponentPlaying)
        .animation(.easeInOut(duration: 0.35), value: tutorial.showCampSuccess)
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: tutorial.isComplete)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) { pulse.toggle() }
        }
        .alert("Quitter le didacticiel ?", isPresented: $showSkipAlert) {
            Button("Continuer", role: .cancel) { }
            Button("Quitter", role: .destructive) { onDismiss() }
        } message: {
            Text("Relance-le à tout moment avec le bouton ⓘ en haut de l'écran.")
        }
    }

    // MARK: Top Bar

    private var topBar: some View {
        HStack {
            Button { showSkipAlert = true } label: {
                Label("Passer", systemImage: "xmark")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            Text("DIDACTICIEL INTERACTIF")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.white.opacity(0.25))
        }
    }

    // MARK: Progress

    private var progressSteps: some View {
        HStack(spacing: 0) {
            ForEach(tutorial.acts.indices, id: \.self) { i in
                HStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(i < tutorial.actIndex
                                  ? Color.green
                                  : i == tutorial.actIndex
                                    ? tutorial.acts[i].badgeColor
                                    : Color.white.opacity(0.12))
                            .frame(width: 28, height: 28)
                        if i < tutorial.actIndex {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                        } else {
                            Text("\(i + 1)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(i == tutorial.actIndex ? .white : .white.opacity(0.3))
                        }
                    }
                    if i < tutorial.acts.count - 1 {
                        Rectangle()
                            .fill(i < tutorial.actIndex ? Color.green.opacity(0.6) : Color.white.opacity(0.1))
                            .frame(height: 2).frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: tutorial.actIndex)
    }

    // MARK: Act Header

    private var actHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(tutorial.currentAct.badge.uppercased())
                    .font(.system(size: 10, weight: .bold)).tracking(2)
                    .foregroundColor(tutorial.currentAct.badgeColor)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(tutorial.currentAct.badgeColor.opacity(0.15)))
                Spacer()
            }
            Text(tutorial.currentAct.title)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
        .animation(.easeInOut(duration: 0.3), value: tutorial.actIndex)
    }

    // MARK: Board

    private var boardSection: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let cell = (size - 8) / 5

            VStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { r in
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { c in
                            let pos = Position(row: r, col: c)
                            TutorialBoardCell(
                                content:       tutorial.board[r][c],
                                isHighlighted: tutorial.highlightedPieces.contains(pos),
                                isSelected:    tutorial.selectedCell == pos,
                                isValidMove:   tutorial.validMoves.contains(pos),
                                pulse: pulse, row: r, col: c, size: cell
                            )
                            .onTapGesture { tutorial.handleTap(pos) }
                        }
                    }
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "#3a1f05").opacity(0.85))
                    .shadow(color: .black.opacity(0.5), radius: 12, y: 6)
            )
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: Instruction Bubble

    private var instructionBubble: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(tutorial.currentAct.badgeColor.opacity(pulse ? 0.4 : 0.12))
                    .frame(width: 38, height: 38)
                    .animation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true), value: pulse)
                Image(systemName: phaseIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(tutorial.currentAct.badgeColor)
            }
            Text(tutorial.currentInstruction)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.82))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(tutorial.currentAct.badgeColor.opacity(0.28), lineWidth: 1))
        )
        .animation(.easeInOut(duration: 0.3), value: tutorial.currentInstruction)
    }

    private var phaseIcon: String {
        switch tutorial.phase {
        case .waitingForPiece:       return "hand.tap.fill"
        case .waitingForDestination: return "target"
        case .opponentPlaying:       return "ellipsis"
        }
    }

    // MARK: Opponent Overlay

    private var opponentOverlay: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.red.opacity(0.15)).frame(width: 60, height: 60)
                Image(systemName: "circle.fill").font(.system(size: 28)).foregroundColor(.red.opacity(0.8))
            }
            Text(tutorial.opponentHint).font(.headline).foregroundColor(.white).multilineTextAlignment(.center)
            ProgressView().progressViewStyle(.circular).tint(.white.opacity(0.5)).scaleEffect(0.9)
        }
        .padding(32)
        .background(RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
        .padding(40)
    }

    // MARK: Camp Success Overlay (intermediate — advances to act 4)

    private var campSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color.yellow.opacity(0.4), .clear],
                            center: .center, startRadius: 10, endRadius: 70))
                        .frame(width: 120, height: 120)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(
                            LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: Color.yellow.opacity(0.6), radius: 16)
                }
                VStack(spacing: 4) {
                    Text("Victoire par le camp !")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("Le Bobail est sur votre ligne de départ.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.orange)
                    Text("Prochain scénario dans un instant…")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.yellow.opacity(0.35), lineWidth: 1.5))
            )
            .environment(\.colorScheme, .dark)
            .padding(32)
        }
    }

    // MARK: Victory Overlay

    private var victoryOverlay: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [winGlow.opacity(0.4), .clear],
                            center: .center, startRadius: 20, endRadius: 80))
                        .frame(width: 140, height: 140)
                    Image(systemName: tutorial.winKind == .camp ? "trophy.fill" : "lock.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(LinearGradient(
                            colors: tutorial.winKind == .camp ? [.yellow, .orange] : [.red, .pink],
                            startPoint: .top, endPoint: .bottom))
                        .shadow(color: winGlow.opacity(0.6), radius: 18)
                }

                VStack(spacing: 6) {
                    Text(tutorial.winKind == .camp ? "Victoire par le camp !" : "Victoire par blocage !")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text(winSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 10) {
                    recapRow(icon: "1.circle.fill",  color: .purple, text: "1er tour : un pion uniquement")
                    recapRow(icon: "2.circle.fill",  color: .orange, text: "Chaque tour : Bobail en premier, puis un pion")
                    recapRow(icon: "trophy.fill",    color: .yellow, text: "Victoire par camp : Bobail sur ta ligne !")
                    recapRow(icon: "lock.fill",      color: .red,    text: "Victoire par blocage : entourer le Bobail !")
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08)))

                Button(action: onDismiss) {
                    HStack(spacing: 10) {
                        Image(systemName: "gamecontroller.fill")
                        Text("Commencer une vraie partie !").fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 28).padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                            .shadow(color: .green.opacity(0.55), radius: 12, y: 5)
                    )
                }
            }
            .padding(24)
        }
    }

    private var winGlow: Color { tutorial.winKind == .camp ? .yellow : .red }
    private var winSubtitle: String {
        tutorial.winKind == .camp
            ? "Le Bobail est entré dans votre camp."
            : "Le Bobail était cerné — il ne pouvait plus bouger."
    }

    private func recapRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(color).font(.subheadline).frame(width: 22)
            Text(text).font(.caption).foregroundColor(.white.opacity(0.75))
        }
    }
}

// MARK: - Tutorial Board Cell

private struct TutorialBoardCell: View {
    let content:       CellContent
    let isHighlighted: Bool
    let isSelected:    Bool
    let isValidMove:   Bool
    let pulse:         Bool
    let row:           Int
    let col:           Int
    let size:          CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(tileColor)

            if isHighlighted {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.orange, lineWidth: pulse ? 2.5 : 1.5)
                    .opacity(pulse ? 1 : 0.5)
                    .animation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true), value: pulse)
            }
            if isSelected {
                RoundedRectangle(cornerRadius: 4).stroke(Color.white, lineWidth: 2.5)
            }

            switch content {
            case .player1:
                pieceView(color1: .blue,   color2: Color(hex: "#4facfe"), glow: isHighlighted ? .blue   : .clear, letter: nil)
            case .player2:
                pieceView(color1: .red,    color2: Color(hex: "#f93154"), glow: .clear,                           letter: nil)
            case .bobail:
                pieceView(color1: .yellow, color2: .orange,               glow: isHighlighted ? .yellow : .clear, letter: "B")
            case .empty:
                if isValidMove {
                    Circle().fill(Color.green.opacity(0.55)).frame(width: size * 0.28, height: size * 0.28)
                }
            }

            if isValidMove && content != .empty {
                RoundedRectangle(cornerRadius: 4).stroke(Color.green, lineWidth: 2)
            }

            if isHighlighted && !isSelected {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "hand.tap")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.orange.opacity(pulse ? 0.9 : 0.4))
                            .offset(x: -2, y: 3)
                    }
                    Spacer()
                }
            }
        }
        .frame(width: size, height: size)
    }

    private func pieceView(color1: Color, color2: Color, glow: Color, letter: String?) -> some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [color1, color2], startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(size * 0.1)
                .shadow(color: glow.opacity(0.65), radius: 6)
            if let letter {
                Text(letter).font(.system(size: size * 0.22, weight: .black)).foregroundColor(.black.opacity(0.55))
            }
        }
    }

    private var tileColor: Color {
        if isSelected    { return Color.white.opacity(0.18) }
        if isHighlighted { return Color.orange.opacity(pulse ? 0.18 : 0.10) }
        if isValidMove   { return Color.green.opacity(0.12) }
        return (row + col) % 2 == 0
            ? Color(hex: "#c8a06a").opacity(0.65)
            : Color(hex: "#7a4a2a").opacity(0.55)
    }
}