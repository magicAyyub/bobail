import SwiftUI

// MARK: - Cell View

struct CellView: View {
    let content: CellContent
    let isSelected: Bool
    let isValidMove: Bool
    let isBobailRow: Bool   // Center row hint
    let row: Int
    let col: Int

    var body: some View {
        ZStack {
            // Board tile background
            RoundedRectangle(cornerRadius: 4)
                .fill(tileColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor, lineWidth: isSelected ? 3 : 1)
                )

            // Valid-move indicator (empty cell dot)
            if isValidMove && content == .empty {
                Circle()
                    .fill(Color.green.opacity(0.55))
                    .padding(10)
            }

            // Piece
            if content != .empty {
                pieceView
                    .padding(6)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: Piece Rendering

    @ViewBuilder
    private var pieceView: some View {
        switch content {
        case .player1:
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.blue.opacity(0.55)]),
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 3, x: 1, y: 2)
                Text("1")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

        case .player2:
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.red.opacity(0.9), Color.red.opacity(0.55)]),
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 3, x: 1, y: 2)
                Text("2")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

        case .bobail:
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.yellow, Color.orange]),
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: .black.opacity(0.45), radius: 4, x: 1, y: 2)
                Text("B")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.black.opacity(0.75))
            }

        case .empty:
            EmptyView()
        }
    }

    // MARK: Colors

    private var tileColor: Color {
        if isSelected { return Color.yellow.opacity(0.45) }
        if isValidMove { return Color.green.opacity(0.15) }
        // Checkerboard pattern
        return (row + col) % 2 == 0 ? Color(hex: "#DEB887") : Color(hex: "#8B4513").opacity(0.75)
    }

    private var borderColor: Color {
        if isSelected { return .yellow }
        if isValidMove { return .green }
        return .black.opacity(0.25)
    }
}

// MARK: - Board View

struct BoardView: View {
    @ObservedObject var model: GameModel
    let cellSize: CGFloat

    var body: some View {
        VStack(spacing: 2) {
            // Column labels A-E
            HStack(spacing: 2) {
                Text("").frame(width: 20)
                ForEach(["A","B","C","D","E"], id: \.self) { label in
                    Text(label)
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                        .frame(width: cellSize)
                }
            }

            ForEach(0..<5, id: \.self) { row in
                HStack(spacing: 2) {
                    // Row labels 1-5
                    Text("\(row + 1)")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                        .frame(width: 20)

                    ForEach(0..<5, id: \.self) { col in
                        let pos = Position(row: row, col: col)
                        let content = model.board[row][col]
                        let isSelected = model.selectedCell == pos
                        let isValid = model.validMoves.contains(pos)

                        CellView(
                            content: content,
                            isSelected: isSelected,
                            isValidMove: isValid,
                            isBobailRow: row == 2,
                            row: row,
                            col: col
                        )
                        .frame(width: cellSize, height: cellSize)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                model.handleTap(row: row, col: col)
                            }
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#5C3317"))
                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Camp Indicator Bar

struct CampBar: View {
    let player: Int
    let isCurrent: Bool
    let phase: TurnPhase

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(player == 1 ? Color.blue : Color.red)
                .frame(width: 20, height: 20)
                .shadow(color: isCurrent ? (player == 1 ? .blue : .red) : .clear, radius: 6)

            Text("Joueur \(player)")
                .font(.headline)
                .foregroundColor(player == 1 ? .blue : .red)

            Spacer()

            if isCurrent {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(player == 1 ? .blue : .red)
                    Text(turnLabel)
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isCurrent
                      ? (player == 1 ? Color.blue.opacity(0.12) : Color.red.opacity(0.12))
                      : Color.secondary.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isCurrent
                                ? (player == 1 ? Color.blue.opacity(0.4) : Color.red.opacity(0.4))
                                : Color.clear,
                                lineWidth: 1.5)
                )
        )
    }

    private var turnLabel: String {
        switch phase {
        case .firstTurnMovePawn: return "Bougez un pion"
        case .moveBobail:        return "Bougez le Bobail"
        case .moveOwnPawn:       return "Bougez un pion"
        }
    }
}

// MARK: - Color Hex Helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
