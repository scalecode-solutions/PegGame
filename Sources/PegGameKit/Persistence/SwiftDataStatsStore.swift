import Foundation
import SwiftData

/// SwiftData-backed entity for a completed game. Stored separately from the
/// public ``CompletedGame`` value type so the persistence schema can evolve
/// without breaking the API surface.
@Model
public final class CompletedGameEntity {

    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var pegsRemaining: Int
    public var moves: Int
    public var initialEmptyIndex: Int
    public var duration: TimeInterval

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        pegsRemaining: Int,
        moves: Int,
        initialEmptyIndex: Int,
        duration: TimeInterval
    ) {
        self.id = id
        self.date = date
        self.pegsRemaining = pegsRemaining
        self.moves = moves
        self.initialEmptyIndex = initialEmptyIndex
        self.duration = duration
    }

    convenience init(_ game: CompletedGame) {
        self.init(
            id: game.id,
            date: game.date,
            pegsRemaining: game.pegsRemaining,
            moves: game.moves,
            initialEmptyIndex: game.initialEmpty.index,
            duration: game.duration
        )
    }

    func toValue() -> CompletedGame? {
        guard let position = BoardPosition(index: initialEmptyIndex) else { return nil }
        return CompletedGame(
            id: id,
            date: date,
            pegsRemaining: pegsRemaining,
            moves: moves,
            initialEmpty: position,
            duration: duration
        )
    }
}

/// `StatsStore` implementation backed by SwiftData. Use this when you need
/// queryable history with growth potential beyond a few hundred games — it
/// indexes records, supports limited fetches, and scales better than the
/// blob-encode pattern in ``UserDefaultsStatsStore``.
///
/// `@ModelActor` gives the store its own isolated `ModelContext` so all
/// access is serialized; the actor itself satisfies `StatsStore`'s
/// `Sendable` requirement.
@ModelActor
public actor SwiftDataStatsStore: StatsStore {

    /// Convenience initializer that builds the store's `ModelContainer`
    /// internally. Pass `inMemory: true` for tests / ephemeral runs.
    ///
    /// On iOS, `Library/Application Support` is not auto-created, so this
    /// initializer ensures the directory exists and points the SwiftData
    /// store at an explicit URL inside it. This avoids the noisy
    /// "Sandbox access to file-write-create denied" errors SwiftData
    /// emits when it tries to seed its default location on first launch.
    public init(inMemory: Bool = false) throws {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        } else {
            let fm = FileManager.default
            let appSupport = try fm.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let storeURL = appSupport.appendingPathComponent("PegGameStats.store")
            configuration = ModelConfiguration(url: storeURL)
        }
        let container = try ModelContainer(
            for: CompletedGameEntity.self,
            configurations: configuration
        )
        self.modelContainer = container
        let context = ModelContext(container)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    }

    // MARK: - StatsStore

    public func record(_ game: CompletedGame) async {
        modelContext.insert(CompletedGameEntity(game))
        try? modelContext.save()
    }

    public func summary() async -> StatsSummary {
        let descriptor = FetchDescriptor<CompletedGameEntity>()
        let games = (try? modelContext.fetch(descriptor)) ?? []
        guard !games.isEmpty else { return .empty }
        let pegs = games.map(\.pegsRemaining)
        let best = pegs.min() ?? 0
        let genius = games.filter { $0.pegsRemaining <= 1 }.count
        let average = Double(pegs.reduce(0, +)) / Double(games.count)
        return StatsSummary(
            gamesPlayed: games.count,
            bestScore: best,
            geniusCount: genius,
            averagePegsRemaining: average
        )
    }

    public func history(limit: Int) async -> [CompletedGame] {
        var descriptor = FetchDescriptor<CompletedGameEntity>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = max(0, limit)
        let entities = (try? modelContext.fetch(descriptor)) ?? []
        return entities.compactMap { $0.toValue() }
    }

    public func reset() async {
        try? modelContext.delete(model: CompletedGameEntity.self)
        try? modelContext.save()
    }
}
