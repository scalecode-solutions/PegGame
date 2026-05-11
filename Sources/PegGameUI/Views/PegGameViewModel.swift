import SwiftUI
import PegGameKit

/// View-model coordinating a ``GameSession``, transient UI state (selection,
/// hint glow, celebration), and an optional ``StatsStore`` for persistence.
@MainActor
@Observable
public final class PegGameViewModel {

    public let session: GameSession
    public let solver = Solver()
    public let statsStore: any StatsStore

    /// Position the player has tapped first; legal moves originate here.
    public var selectedPosition: BoardPosition?

    /// Move the solver currently suggests (set by `requestHint()`); cleared on apply.
    public var hintedMove: Move?

    /// 0...1 progress while the win celebration is playing.
    public var celebrationProgress: Double = 0
    public var celebrationSeed: Double = 0
    public var isShowingCelebration: Bool = false

    /// Set once when the current game has been recorded to stats (avoids dupes).
    public var didRecordCurrentGame = false

    public init(session: GameSession,
                statsStore: any StatsStore = UserDefaultsStatsStore()) {
        self.session = session
        self.statsStore = statsStore
    }

    // MARK: - Tap routing

    /// Handle a tap on `position`. Selects a peg, deselects, or applies a move.
    public func tap(_ position: BoardPosition) {
        guard session.status.isActive else { return }

        if let selected = selectedPosition {
            if selected == position {
                selectedPosition = nil
                return
            }
            if let move = session.legalMoves(from: selected).first(where: { $0.to == position }) {
                apply(move)
                return
            }
            // Tapping another peg switches selection if it has legal moves.
            if session.board.peg(at: position) != nil,
               !session.legalMoves(from: position).isEmpty {
                selectedPosition = position
                hintedMove = nil
                return
            }
            // Otherwise treat as deselect.
            selectedPosition = nil
            return
        }

        // No current selection.
        if session.board.peg(at: position) != nil,
           !session.legalMoves(from: position).isEmpty {
            selectedPosition = position
            hintedMove = nil
        }
    }

    // MARK: - Actions

    public func apply(_ move: Move) {
        session.apply(move)
        selectedPosition = nil
        hintedMove = nil
        checkForCompletion()
    }

    public func undo() {
        session.undo()
        selectedPosition = nil
        hintedMove = nil
        // Undoing past completion clears the celebration banner.
        if session.status.isActive {
            isShowingCelebration = false
            celebrationProgress = 0
        }
    }

    public func redo() {
        session.redo()
        selectedPosition = nil
        hintedMove = nil
        checkForCompletion()
    }

    public func restart() {
        session.restart()
        selectedPosition = nil
        hintedMove = nil
        isShowingCelebration = false
        celebrationProgress = 0
        didRecordCurrentGame = false
    }

    public func restart(emptyAt position: BoardPosition) {
        session.restart(emptyAt: position)
        selectedPosition = nil
        hintedMove = nil
        isShowingCelebration = false
        celebrationProgress = 0
        didRecordCurrentGame = false
    }

    public func requestHint() {
        guard session.status.isActive else { return }
        hintedMove = solver.hint(for: session.board)
        if let from = hintedMove?.from {
            selectedPosition = from
        }
    }

    // MARK: - Derived state

    public var legalDestinationsFromSelection: [BoardPosition] {
        guard let selected = selectedPosition else { return [] }
        return session.legalMoves(from: selected).map(\.to)
    }

    /// True when this position is the source `from` of the currently suggested hint.
    public func isHintSource(_ position: BoardPosition) -> Bool {
        hintedMove?.from == position
    }

    /// True when this position is the destination of the currently suggested hint.
    public func isHintDestination(_ position: BoardPosition) -> Bool {
        hintedMove?.to == position
    }

    // MARK: - Completion

    private func checkForCompletion() {
        guard case .complete(let pegs, _) = session.status else {
            isShowingCelebration = false
            return
        }
        isShowingCelebration = true
        celebrationSeed = Double.random(in: 0..<1)
        celebrationProgress = 0
        guard !didRecordCurrentGame else { return }
        didRecordCurrentGame = true

        let game = CompletedGame(
            pegsRemaining: pegs,
            moves: session.moveCount,
            initialEmpty: session.initialEmpty,
            duration: Date().timeIntervalSince(session.startedAt)
        )
        let store = statsStore
        Task { await store.record(game) }
    }
}
