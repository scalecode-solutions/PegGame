import Foundation

/// A finished game, suitable for stats aggregation.
public struct CompletedGame: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public let date: Date
    public let pegsRemaining: Int
    public let moves: Int
    public let initialEmpty: BoardPosition
    public let duration: TimeInterval

    public init(id: UUID = UUID(),
                date: Date = Date(),
                pegsRemaining: Int,
                moves: Int,
                initialEmpty: BoardPosition,
                duration: TimeInterval) {
        self.id = id
        self.date = date
        self.pegsRemaining = pegsRemaining
        self.moves = moves
        self.initialEmpty = initialEmpty
        self.duration = duration
    }

    public var rating: Rating { Rating(pegsRemaining: pegsRemaining) }
}

/// Aggregate stats over many `CompletedGame`s.
public struct StatsSummary: Sendable, Hashable, Codable {
    public let gamesPlayed: Int
    public let bestScore: Int          // lowest pegsRemaining; 0 if no games yet
    public let geniusCount: Int        // games rated `genius`
    public let averagePegsRemaining: Double

    public static let empty = StatsSummary(
        gamesPlayed: 0,
        bestScore: 0,
        geniusCount: 0,
        averagePegsRemaining: 0
    )

    public init(gamesPlayed: Int, bestScore: Int, geniusCount: Int, averagePegsRemaining: Double) {
        self.gamesPlayed = gamesPlayed
        self.bestScore = bestScore
        self.geniusCount = geniusCount
        self.averagePegsRemaining = averagePegsRemaining
    }
}

/// Persistence backend for game results.
public protocol StatsStore: Sendable {
    func record(_ game: CompletedGame) async
    func summary() async -> StatsSummary
    func history(limit: Int) async -> [CompletedGame]
    func reset() async
}
