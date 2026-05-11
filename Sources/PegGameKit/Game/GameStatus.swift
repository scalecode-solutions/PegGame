import Foundation

/// The current state of a game.
public enum GameStatus: Sendable, Hashable {
    /// At least one legal move remains.
    case active
    /// No legal moves remain.
    case complete(pegsRemaining: Int, rating: Rating)

    public var isActive: Bool {
        if case .active = self { return true }
        return false
    }

    public var isComplete: Bool { !isActive }

    public var rating: Rating? {
        if case .complete(_, let rating) = self { return rating }
        return nil
    }

    public var pegsRemaining: Int? {
        if case .complete(let pegs, _) = self { return pegs }
        return nil
    }
}
