import Foundation
import Observation

/// One peg-solitaire game in progress. Drives the UI via `@Observable`.
///
/// `GameSession` is intended to be used from the main actor (UI). It is not
/// `Sendable`; do not share instances across isolation boundaries.
@Observable
public final class GameSession {

    /// Single entry in the undo/redo history.
    public struct HistoryEntry: Hashable, Sendable, Codable {
        public let move: Move
        public let capturedPeg: Peg
    }

    /// Live board state.
    public private(set) var board: Board

    /// Moves applied so far, oldest first.
    public private(set) var history: [HistoryEntry] = []

    /// Undone moves available to redo, most-recently-undone last.
    public private(set) var redoStack: [HistoryEntry] = []

    /// The starting empty hole for this game (restart returns here).
    public let initialEmpty: BoardPosition

    /// The peg palette used at game start.
    public let palette: [PegColor]

    /// Timestamp when the current game began (resets on `restart()`).
    public private(set) var startedAt: Date

    public init(emptyAt: BoardPosition = BoardPosition(index: 0)!,
                palette: [PegColor] = PegColor.allCases) {
        self.initialEmpty = emptyAt
        self.palette = palette
        self.board = Board(emptyAt: emptyAt, colors: palette)
        self.startedAt = Date()
    }

    /// Start a game with the empty hole chosen uniformly at random.
    public static func randomized(
        using rng: inout some RandomNumberGenerator,
        palette: [PegColor] = PegColor.allCases
    ) -> GameSession {
        let index = Int.random(in: 0..<BoardPosition.count, using: &rng)
        return GameSession(emptyAt: BoardPosition(index: index)!, palette: palette)
    }

    /// Start a game with the empty hole chosen uniformly at random.
    public static func randomized(palette: [PegColor] = PegColor.allCases) -> GameSession {
        var rng = SystemRandomNumberGenerator()
        return randomized(using: &rng, palette: palette)
    }

    /// All legal moves from the current board.
    public var legalMoves: [Move] { board.legalMoves() }

    /// Legal moves originating from a specific peg position.
    public func legalMoves(from position: BoardPosition) -> [Move] {
        legalMoves.filter { $0.from == position }
    }

    /// Pegs still on the board.
    public var pegCount: Int { board.pegCount }

    /// Number of moves the player has made.
    public var moveCount: Int { history.count }

    public var canUndo: Bool { !history.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    /// Whether the game can still be played, or its final status.
    public var status: GameStatus {
        if legalMoves.isEmpty {
            let count = pegCount
            return .complete(pegsRemaining: count, rating: Rating(pegsRemaining: count))
        }
        return .active
    }

    /// Apply a move. Clears the redo stack.
    public func apply(_ move: Move) {
        let captured = board.apply(move)
        history.append(HistoryEntry(move: move, capturedPeg: captured))
        redoStack.removeAll(keepingCapacity: true)
    }

    /// Reverse the most recent move.
    public func undo() {
        guard let last = history.popLast() else { return }
        board.unapply(last.move, capturedPeg: last.capturedPeg)
        redoStack.append(last)
    }

    /// Re-apply the most recently undone move.
    public func redo() {
        guard let last = redoStack.popLast() else { return }
        _ = board.apply(last.move)
        history.append(last)
    }

    /// Reset to the initial state with the same starting empty hole.
    public func restart() {
        board = Board(emptyAt: initialEmpty, colors: palette)
        history.removeAll(keepingCapacity: true)
        redoStack.removeAll(keepingCapacity: true)
        startedAt = Date()
    }

    /// Reset with a new starting empty hole.
    public func restart(emptyAt: BoardPosition) {
        // initialEmpty is `let`; this method creates a new state via the initializer pattern.
        board = Board(emptyAt: emptyAt, colors: palette)
        history.removeAll(keepingCapacity: true)
        redoStack.removeAll(keepingCapacity: true)
        startedAt = Date()
    }
}
