import Foundation

/// A single jump: peg at `from` leaps over `over` (removing it) into the empty `to`.
public struct Move: Hashable, Sendable, Codable, CustomStringConvertible {

    public let from: BoardPosition
    public let over: BoardPosition
    public let to: BoardPosition

    public init(from: BoardPosition, over: BoardPosition, to: BoardPosition) {
        self.from = from
        self.over = over
        self.to = to
    }

    /// All 36 geometrically valid (from, over, to) triples on a 15-hole triangle.
    ///
    /// A move is geometrically valid when `from` has a neighbor `over` in some
    /// direction, and `over` has a neighbor `to` in the same direction. Whether
    /// the move is currently *legal* depends on the board state.
    public static let allTemplates: [Move] = {
        var moves: [Move] = []
        for from in BoardPosition.all {
            for dir in BoardDirection.allCases {
                guard let over = from.neighbor(dir),
                      let to = over.neighbor(dir) else { continue }
                moves.append(Move(from: from, over: over, to: to))
            }
        }
        return moves
    }()

    public var description: String { "\(from)→\(to) (×\(over))" }
}
