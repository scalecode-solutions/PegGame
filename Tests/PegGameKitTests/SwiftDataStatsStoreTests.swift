import Testing
import Foundation
@testable import PegGameKit

@Suite("SwiftDataStatsStore")
struct SwiftDataStatsStoreTests {

    private func makeStore() throws -> SwiftDataStatsStore {
        try SwiftDataStatsStore(inMemory: true)
    }

    @Test func emptyStoreReturnsEmptySummary() async throws {
        let store = try makeStore()
        let summary = await store.summary()
        #expect(summary.gamesPlayed == 0)
        #expect(summary.bestScore == 0)
        #expect(summary.geniusCount == 0)
        #expect(summary.averagePegsRemaining == 0)
    }

    @Test func emptyStoreReturnsNoHistory() async throws {
        let store = try makeStore()
        let history = await store.history(limit: 10)
        #expect(history.isEmpty)
    }

    @Test func recordsAndAggregatesGames() async throws {
        let store = try makeStore()
        let pos = BoardPosition(index: 0)!

        await store.record(CompletedGame(pegsRemaining: 1, moves: 13, initialEmpty: pos, duration: 60))
        await store.record(CompletedGame(pegsRemaining: 3, moves: 11, initialEmpty: pos, duration: 80))
        await store.record(CompletedGame(pegsRemaining: 2, moves: 12, initialEmpty: pos, duration: 70))

        let summary = await store.summary()
        #expect(summary.gamesPlayed == 3)
        #expect(summary.bestScore == 1)
        #expect(summary.geniusCount == 1)
        #expect(abs(summary.averagePegsRemaining - 2.0) < 0.001)
    }

    @Test func historySortsByDateDescending() async throws {
        let store = try makeStore()
        let pos = BoardPosition(index: 0)!
        let now = Date()

        await store.record(CompletedGame(
            date: now.addingTimeInterval(-300),
            pegsRemaining: 5,
            moves: 9,
            initialEmpty: pos,
            duration: 90
        ))
        await store.record(CompletedGame(
            date: now,
            pegsRemaining: 1,
            moves: 13,
            initialEmpty: pos,
            duration: 60
        ))
        await store.record(CompletedGame(
            date: now.addingTimeInterval(-120),
            pegsRemaining: 2,
            moves: 12,
            initialEmpty: pos,
            duration: 70
        ))

        let history = await store.history(limit: 10)
        #expect(history.count == 3)
        #expect(history[0].pegsRemaining == 1)
        #expect(history[1].pegsRemaining == 2)
        #expect(history[2].pegsRemaining == 5)
    }

    @Test func historyLimitIsRespected() async throws {
        let store = try makeStore()
        let pos = BoardPosition(index: 0)!
        for i in 0..<5 {
            await store.record(CompletedGame(
                date: Date().addingTimeInterval(-Double(i) * 60),
                pegsRemaining: i + 1,
                moves: 10,
                initialEmpty: pos,
                duration: 60
            ))
        }
        let history = await store.history(limit: 3)
        #expect(history.count == 3)
    }

    @Test func resetClearsAllGames() async throws {
        let store = try makeStore()
        let pos = BoardPosition(index: 0)!
        await store.record(CompletedGame(pegsRemaining: 2, moves: 12, initialEmpty: pos, duration: 70))
        await store.record(CompletedGame(pegsRemaining: 3, moves: 11, initialEmpty: pos, duration: 80))

        await store.reset()

        let summary = await store.summary()
        let history = await store.history(limit: 100)
        #expect(summary.gamesPlayed == 0)
        #expect(history.isEmpty)
    }

    @Test func roundTripPreservesInitialEmptyPosition() async throws {
        let store = try makeStore()
        let pos = BoardPosition(index: 7)!
        await store.record(CompletedGame(pegsRemaining: 1, moves: 13, initialEmpty: pos, duration: 60))
        let history = await store.history(limit: 1)
        #expect(history.first?.initialEmpty == pos)
    }
}
