import Foundation

/// Default `StatsStore` backed by `UserDefaults`. Zero dependencies; fine for
/// modest stat volumes (hundreds of games). For richer history queries, swap
/// in a SwiftData-backed store.
public actor UserDefaultsStatsStore: StatsStore {

    private let defaults: UserDefaults
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(suiteName: String? = nil, key: String = "dev.scalecode.PegGame.completedGames") {
        if let suiteName, let suite = UserDefaults(suiteName: suiteName) {
            self.defaults = suite
        } else {
            self.defaults = .standard
        }
        self.key = key
    }

    public func record(_ game: CompletedGame) async {
        var games = load()
        games.append(game)
        save(games)
    }

    public func summary() async -> StatsSummary {
        let games = load()
        guard !games.isEmpty else { return .empty }
        let best = games.map(\.pegsRemaining).min() ?? 0
        let geniusCount = games.filter { $0.rating == .genius }.count
        let avg = Double(games.map(\.pegsRemaining).reduce(0, +)) / Double(games.count)
        return StatsSummary(
            gamesPlayed: games.count,
            bestScore: best,
            geniusCount: geniusCount,
            averagePegsRemaining: avg
        )
    }

    public func history(limit: Int) async -> [CompletedGame] {
        let games = load().sorted { $0.date > $1.date }
        return Array(games.prefix(max(0, limit)))
    }

    public func reset() async {
        defaults.removeObject(forKey: key)
    }

    // MARK: - Helpers

    private func load() -> [CompletedGame] {
        guard let data = defaults.data(forKey: key),
              let games = try? decoder.decode([CompletedGame].self, from: data) else {
            return []
        }
        return games
    }

    private func save(_ games: [CompletedGame]) {
        guard let data = try? encoder.encode(games) else { return }
        defaults.set(data, forKey: key)
    }
}
