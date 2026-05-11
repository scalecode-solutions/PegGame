import Foundation

/// Result of grading a candidate move against perfect play.
public enum MoveGrade: Sendable, Hashable {
    /// The move keeps the position winnable (1-peg solution still reachable).
    case keepsWinnable
    /// Before the move the position was winnable; after the move it is not.
    case breaksWinnable
    /// The position was already unwinnable; this move can't make it worse.
    case unrecoverable
}

/// Memoized winnability/hint engine for the 15-hole triangular peg board.
///
/// Reuse one instance across many queries to amortize cache fills. Not
/// `Sendable`; intended for single-actor use (typically the main actor).
public final class Solver {

    /// Precomputed bitmask form of every geometrically valid move template.
    private struct MoveMask {
        let from: UInt16
        let over: UInt16
        let to: UInt16
        let move: Move
    }

    private static let moveMasks: [MoveMask] = Move.allTemplates.map { move in
        MoveMask(
            from: UInt16(1) << move.from.index,
            over: UInt16(1) << move.over.index,
            to: UInt16(1) << move.to.index,
            move: move
        )
    }

    private var cache: [UInt16: Bool] = [:]

    public init() {}

    /// Whether some sequence of moves from this state ends with exactly one peg.
    public func isWinnable(from mask: UInt16) -> Bool {
        if mask.nonzeroBitCount <= 1 { return true }
        if let cached = cache[mask] { return cached }
        for m in Self.moveMasks {
            if (mask & m.from) != 0,
               (mask & m.over) != 0,
               (mask & m.to) == 0 {
                let next = (mask & ~m.from & ~m.over) | m.to
                if isWinnable(from: next) {
                    cache[mask] = true
                    return true
                }
            }
        }
        cache[mask] = false
        return false
    }

    public func isWinnable(_ board: Board) -> Bool {
        isWinnable(from: board.occupancyMask)
    }

    /// Suggest a move from `board` that keeps the position winnable when possible.
    /// Falls back to any legal move if no winning continuation exists.
    public func hint(for board: Board) -> Move? {
        let legal = board.legalMoves()
        guard !legal.isEmpty else { return nil }
        let mask = board.occupancyMask
        for move in legal {
            let next = apply(move, to: mask)
            if isWinnable(from: next) {
                return move
            }
        }
        return legal.first
    }

    /// Grade a move on `board` against perfect play.
    public func grade(_ move: Move, on board: Board) -> MoveGrade {
        let before = board.occupancyMask
        guard isWinnable(from: before) else { return .unrecoverable }
        let after = apply(move, to: before)
        return isWinnable(from: after) ? .keepsWinnable : .breaksWinnable
    }

    private func apply(_ move: Move, to mask: UInt16) -> UInt16 {
        let fb = UInt16(1) << move.from.index
        let ob = UInt16(1) << move.over.index
        let tb = UInt16(1) << move.to.index
        return (mask & ~fb & ~ob) | tb
    }
}
