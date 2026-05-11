import Foundation

/// One of the five classic Cracker Barrel peg colors.
///
/// Color is purely aesthetic and has no effect on rules or solver behavior.
public enum PegColor: String, CaseIterable, Sendable, Codable, Hashable {
    case red
    case yellow
    case green
    case blue
    case white
}

/// A single peg.
public struct Peg: Hashable, Sendable, Codable {
    public let color: PegColor

    public init(color: PegColor) {
        self.color = color
    }
}
