import Foundation

/// A 15-hole peg board with optional pegs in each slot.
public struct Board: Hashable, Sendable, Codable {

    /// Pegs at each board position; `nil` means empty.
    public private(set) var pegs: [Peg?]

    /// Create a board with a peg in every position except `emptyAt`.
    /// Colors are assigned positionally from `colors` (cycling if shorter than 14).
    public init(emptyAt: BoardPosition, colors: [PegColor] = PegColor.allCases) {
        precondition(!colors.isEmpty, "Need at least one peg color")
        var pegs: [Peg?] = Array(repeating: nil, count: BoardPosition.count)
        var colorIndex = 0
        for position in BoardPosition.all where position != emptyAt {
            pegs[position.index] = Peg(color: colors[colorIndex % colors.count])
            colorIndex += 1
        }
        self.pegs = pegs
    }

    /// Create a board from raw peg data (e.g. when restoring state).
    public init(pegs: [Peg?]) {
        precondition(pegs.count == BoardPosition.count, "Board must have \(BoardPosition.count) slots")
        self.pegs = pegs
    }

    public func peg(at position: BoardPosition) -> Peg? {
        pegs[position.index]
    }

    public func isEmpty(at position: BoardPosition) -> Bool {
        pegs[position.index] == nil
    }

    public var pegCount: Int {
        pegs.lazy.filter { $0 != nil }.count
    }

    /// The empty positions on the board.
    public var emptyPositions: [BoardPosition] {
        BoardPosition.all.filter { isEmpty(at: $0) }
    }

    /// A `Move` is legal if `from` and `over` are occupied and `to` is empty.
    public func isLegal(_ move: Move) -> Bool {
        peg(at: move.from) != nil &&
        peg(at: move.over) != nil &&
        peg(at: move.to) == nil
    }

    /// All legal moves from the current state.
    public func legalMoves() -> [Move] {
        Move.allTemplates.filter(isLegal)
    }

    /// Apply `move`. Returns the captured peg (the one that was at `over`).
    @discardableResult
    public mutating func apply(_ move: Move) -> Peg {
        precondition(isLegal(move), "Illegal move: \(move)")
        let mover = pegs[move.from.index]!
        let captured = pegs[move.over.index]!
        pegs[move.from.index] = nil
        pegs[move.over.index] = nil
        pegs[move.to.index] = mover
        return captured
    }

    /// Reverse a previously-applied `move`, restoring `capturedPeg` at the jumped position.
    public mutating func unapply(_ move: Move, capturedPeg: Peg) {
        let mover = pegs[move.to.index]!
        pegs[move.to.index] = nil
        pegs[move.over.index] = capturedPeg
        pegs[move.from.index] = mover
    }

    /// 15-bit mask of occupied positions. Used by the solver for memoization.
    public var occupancyMask: UInt16 {
        var mask: UInt16 = 0
        for i in 0..<BoardPosition.count where pegs[i] != nil {
            mask |= (1 << i)
        }
        return mask
    }
}
