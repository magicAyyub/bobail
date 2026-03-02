import Foundation
import Combine
import SwiftUI

// MARK: - Data Types

enum CellContent: Equatable {
    case empty
    case player1   // Row 0 — blue
    case player2   // Row 4 — red
    case bobail    // Center — neutral gold pawn
}

struct Position: Equatable, Hashable {
    let row: Int
    let col: Int
}

/// Phases within a single player's turn.
enum TurnPhase {
    /// Very first half-turn of the game: current player only moves a pawn.
    case firstTurnMovePawn
    /// Normal turn, step 1: move the Bobail one square.
    case moveBobail
    /// Normal turn, step 2: move one of current player's own pawns.
    case moveOwnPawn
}

enum GameResult: Equatable {
    case ongoing
    case player1Wins(reason: String)
    case player2Wins(reason: String)

    static func == (lhs: GameResult, rhs: GameResult) -> Bool {
        switch (lhs, rhs) {
        case (.ongoing, .ongoing): return true
        case (.player1Wins, .player1Wins): return true
        case (.player2Wins, .player2Wins): return true
        default: return false
        }
    }
}

// MARK: - Game Model

class GameModel: ObservableObject {

    // Board: board[row][col]
    @Published var board: [[CellContent]]
    @Published var currentPlayer: Int = 1           // 1 or 2
    @Published var phase: TurnPhase = .firstTurnMovePawn
    @Published var selectedCell: Position? = nil
    @Published var validMoves: [Position] = []
    @Published var gameResult: GameResult = .ongoing
    @Published var statusMessage: String = ""
    @Published var moveHistory: [(player: Int, description: String)] = []

    // Track whether the very first half-turn of the game has been played.
    private var isFirstTurnOfGame: Bool = true

    // MARK: Init

    init() {
        board = Array(repeating: Array(repeating: .empty, count: 5), count: 5)
        resetGame()
    }

    // MARK: Setup

    func resetGame() {
        board = Array(repeating: Array(repeating: .empty, count: 5), count: 5)
        for col in 0..<5 { board[0][col] = .player1 }
        for col in 0..<5 { board[4][col] = .player2 }
        board[2][2] = .bobail
        currentPlayer = 1
        phase = .firstTurnMovePawn
        isFirstTurnOfGame = true
        selectedCell = nil
        validMoves = []
        gameResult = .ongoing
        moveHistory = []
        updateStatusMessage()
    }

    // MARK: Tap Handling

    /// Called when the user taps cell at (row, col).
    func handleTap(row: Int, col: Int) {
        guard gameResult == .ongoing else { return }

        let tapped = Position(row: row, col: col)
        let content = board[row][col]

        switch phase {

        case .firstTurnMovePawn, .moveOwnPawn:
            // Expect the player to select then move one of their own pawns.
            let ownPiece: CellContent = currentPlayer == 1 ? .player1 : .player2

            if let selected = selectedCell {
                // If tapping a valid move destination → execute move
                if validMoves.contains(tapped) {
                    movePiece(from: selected, to: tapped)
                    let desc = "Pion \(positionName(selected)) → \(positionName(tapped))"
                    recordMove(description: desc)
                    selectedCell = nil
                    validMoves = []
                    finishPawnMove()
                } else if content == ownPiece {
                    // Re-select another own pawn
                    selectedCell = tapped
                    validMoves = computePawnMoves(from: tapped)
                } else {
                    // Tap elsewhere — deselect
                    selectedCell = nil
                    validMoves = []
                }
            } else {
                // No selection yet — select own pawn
                if content == ownPiece {
                    selectedCell = tapped
                    validMoves = computePawnMoves(from: tapped)
                }
            }

        case .moveBobail:
            // Expect the player to move the Bobail.
            if let selected = selectedCell {
                if validMoves.contains(tapped) {
                    movePiece(from: selected, to: tapped)
                    let desc = "Bobail \(positionName(selected)) → \(positionName(tapped))"
                    recordMove(description: desc)
                    selectedCell = nil
                    validMoves = []
                    checkWinAfterBobailMove(landedOn: tapped)
                } else if content == .bobail {
                    // Re-select bobail (same piece)
                    selectedCell = tapped
                    validMoves = computeBobailMoves(from: tapped)
                } else {
                    selectedCell = nil
                    validMoves = []
                }
            } else {
                if content == .bobail {
                    selectedCell = tapped
                    validMoves = computeBobailMoves(from: tapped)
                }
            }
        }

        updateStatusMessage()
    }

    // MARK: Movement Logic

    /// Slide a pawn from `from` in a direction as far as possible, stopping before an obstacle.
    func computePawnMoves(from pos: Position) -> [Position] {
        var moves: [Position] = []
        let directions: [(Int, Int)] = [
            (-1,-1), (-1, 0), (-1, 1),
            ( 0,-1),           ( 0, 1),
            ( 1,-1), ( 1, 0), ( 1, 1)
        ]
        for (dr, dc) in directions {
            var r = pos.row + dr
            var c = pos.col + dc
            var lastFree: Position? = nil
            while r >= 0 && r < 5 && c >= 0 && c < 5 {
                if board[r][c] == .empty {
                    lastFree = Position(row: r, col: c)
                    r += dr
                    c += dc
                } else {
                    // Hit an obstacle — stop before it
                    break
                }
            }
            if let dest = lastFree {
                moves.append(dest)
            }
        }
        return moves
    }

    /// Bobail moves exactly one square in any of the 8 directions onto an empty cell.
    func computeBobailMoves(from pos: Position) -> [Position] {
        var moves: [Position] = []
        let directions: [(Int, Int)] = [
            (-1,-1), (-1, 0), (-1, 1),
            ( 0,-1),           ( 0, 1),
            ( 1,-1), ( 1, 0), ( 1, 1)
        ]
        for (dr, dc) in directions {
            let r = pos.row + dr
            let c = pos.col + dc
            if r >= 0 && r < 5 && c >= 0 && c < 5 && board[r][c] == .empty {
                moves.append(Position(row: r, col: c))
            }
        }
        return moves
    }

    private func movePiece(from: Position, to: Position) {
        board[to.row][to.col] = board[from.row][from.col]
        board[from.row][from.col] = .empty
    }

    // MARK: Turn Transitions

    private func finishPawnMove() {
        if isFirstTurnOfGame {
            // End of special first turn → give turn to player 2, start normal turns
            isFirstTurnOfGame = false
            currentPlayer = currentPlayer == 1 ? 2 : 1
            phase = .moveBobail
            // Check if the new current player can move the Bobail at all
            checkBobailBlocked()
        } else {
            // End of step 2 → switch player, start new turn (moveBobail)
            currentPlayer = currentPlayer == 1 ? 2 : 1
            phase = .moveBobail
            checkBobailBlocked()
        }
    }

    /// After moving the Bobail, check win and advance phase.
    private func checkWinAfterBobailMove(landedOn pos: Position) {
        guard gameResult == .ongoing else { return }

        // Whoever moved it, if the Bobail lands on row 0 → Player 1 wins
        if pos.row == 0 {
            gameResult = .player1Wins(reason: "Le Bobail est arrivé dans le camp du Joueur 1 !")
            return
        }
        // Whoever moved it, if the Bobail lands on row 4 → Player 2 wins
        if pos.row == 4 {
            gameResult = .player2Wins(reason: "Le Bobail est arrivé dans le camp du Joueur 2 !")
            return
        }

        // Move to pawn step
        phase = .moveOwnPawn
    }

    /// Called after switching current player to moveBobail: if Bobail is blocked, current player loses.
    private func checkBobailBlocked() {
        guard gameResult == .ongoing else { return }
        guard let bobailPos = findBobail() else { return }

        let moves = computeBobailMoves(from: bobailPos)
        if moves.isEmpty {
            // Bobail is blocked — the player whose turn it is to move it loses.
            // The OTHER player (who surrounded it) wins.
            if currentPlayer == 1 {
                gameResult = .player2Wins(reason: "Le Bobail est bloqué ! Le Joueur 2 gagne !")
            } else {
                gameResult = .player1Wins(reason: "Le Bobail est bloqué ! Le Joueur 1 gagne !")
            }
        }
    }

    // MARK: Win Condition Helpers

    func findBobail() -> Position? {
        for r in 0..<5 {
            for c in 0..<5 {
                if board[r][c] == .bobail { return Position(row: r, col: c) }
            }
        }
        return nil
    }

    // MARK: Status

    private func updateStatusMessage() {
        switch gameResult {
        case .player1Wins:
            statusMessage = "Joueur 1 gagne !"
        case .player2Wins:
            statusMessage = "Joueur 2 gagne !"
        case .ongoing:
            switch phase {
            case .firstTurnMovePawn:
                statusMessage = "Joueur \(currentPlayer) : déplacez un de vos pions"
            case .moveBobail:
                statusMessage = "Joueur \(currentPlayer) : déplacez le Bobail"
            case .moveOwnPawn:
                statusMessage = "Joueur \(currentPlayer) : déplacez un de vos pions"
            }
        }
    }

    private func positionName(_ pos: Position) -> String {
        let cols = ["A","B","C","D","E"]
        return "\(cols[pos.col])\(pos.row + 1)"
    }

    private func recordMove(description: String) {
        moveHistory.append((player: currentPlayer, description: description))
    }
}
