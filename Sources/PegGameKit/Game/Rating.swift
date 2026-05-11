import Foundation

/// The classic Cracker Barrel scoring tier based on how many pegs remain
/// when no moves are left.
public enum Rating: Sendable, Hashable, Codable, CaseIterable {

    /// 1 peg left — the win condition.
    case genius
    /// 2 pegs left.
    case purtySmart
    /// 3 pegs left.
    case justPlainDumb
    /// 4+ pegs left.
    case eeQuit

    public init(pegsRemaining: Int) {
        switch pegsRemaining {
        case ...1: self = .genius
        case 2: self = .purtySmart
        case 3: self = .justPlainDumb
        default: self = .eeQuit
        }
    }

    /// The verbatim Cracker Barrel label for this tier.
    public var label: String {
        switch self {
        case .genius: "Genius"
        case .purtySmart: "Purty Smart"
        case .justPlainDumb: "Just Plain Dumb"
        case .eeQuit: "Ee-Quit"
        }
    }

    /// One-line flavor description for the tier.
    public var blurb: String {
        switch self {
        case .genius: "Leave only one peg — you're a genius."
        case .purtySmart: "Leave two and you're purty smart."
        case .justPlainDumb: "Leave three and you're just plain dumb."
        case .eeQuit: "Leave four or more and you're an ee-quit."
        }
    }
}
