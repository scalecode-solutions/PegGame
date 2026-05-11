import Foundation

/// A position on the 15-hole triangular peg board.
///
/// Positions are indexed 0...14, laid out as five rows of length 1, 2, 3, 4, 5:
/// ```
///         0
///        1 2
///       3 4 5
///      6 7 8 9
///    10 11 12 13 14
/// ```
public struct BoardPosition: Hashable, Sendable, Codable, CustomStringConvertible {

    /// The total number of positions on the board.
    public static let count = 15

    /// All board positions in index order.
    public static let all: [BoardPosition] = (0..<count).compactMap(BoardPosition.init(index:))

    /// Zero-based index 0...14.
    public let index: Int

    public init?(index: Int) {
        guard (0..<Self.count).contains(index) else { return nil }
        self.index = index
    }

    public init?(row: Int, col: Int) {
        guard (0..<5).contains(row), (0...row).contains(col) else { return nil }
        self.init(index: row * (row + 1) / 2 + col)
    }

    /// Row of this position (0 = apex, 4 = base).
    public var row: Int {
        var r = 0
        while (r + 1) * (r + 2) / 2 <= index { r += 1 }
        return r
    }

    /// Column within the row (0 = leftmost).
    public var col: Int { index - row * (row + 1) / 2 }

    /// The position one step in `direction`, or `nil` if off-board.
    public func neighbor(_ direction: BoardDirection) -> BoardPosition? {
        BoardPosition(row: row + direction.deltaRow, col: col + direction.deltaCol)
    }

    public var description: String { "P\(index)" }
}

/// The six directions one can travel between adjacent positions on the triangle.
public enum BoardDirection: CaseIterable, Sendable, Hashable {
    case left, right, upLeft, upRight, downLeft, downRight

    var deltaRow: Int {
        switch self {
        case .left, .right: 0
        case .upLeft, .upRight: -1
        case .downLeft, .downRight: 1
        }
    }

    var deltaCol: Int {
        switch self {
        case .left: -1
        case .right: 1
        case .upLeft: -1
        case .upRight: 0
        case .downLeft: 0
        case .downRight: 1
        }
    }
}
