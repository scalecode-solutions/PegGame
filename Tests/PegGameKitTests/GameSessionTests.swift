import Testing
import Foundation
@testable import PegGameKit

@Suite("GameSession")
struct GameSessionTests {

    @Test func startingBoardHas14Pegs() {
        let session = GameSession(emptyAt: BoardPosition(index: 0)!)
        #expect(session.pegCount == 14)
        #expect(session.board.isEmpty(at: BoardPosition(index: 0)!))
        #expect(session.status == .active)
    }

    @Test func applyingAMoveUpdatesCounts() throws {
        let session = GameSession(emptyAt: BoardPosition(index: 0)!)
        let move = try #require(session.legalMoves.first)
        session.apply(move)
        #expect(session.pegCount == 13)
        #expect(session.moveCount == 1)
        #expect(session.canUndo)
        #expect(!session.canRedo)
    }

    @Test func undoRedoRestoresState() throws {
        let session = GameSession(emptyAt: BoardPosition(index: 0)!)
        let snapshot = session.board
        let move = try #require(session.legalMoves.first)
        session.apply(move)
        session.undo()
        #expect(session.board == snapshot)
        #expect(session.pegCount == 14)
        #expect(session.canRedo)
        session.redo()
        #expect(session.pegCount == 13)
    }

    @Test func applyClearsRedoStack() throws {
        let session = GameSession(emptyAt: BoardPosition(index: 0)!)
        let m1 = try #require(session.legalMoves.first)
        session.apply(m1)
        session.undo()
        #expect(session.canRedo)
        let m2 = try #require(session.legalMoves.first)
        session.apply(m2)
        #expect(!session.canRedo)
    }

    @Test func restartReturnsToInitialState() throws {
        let session = GameSession(emptyAt: BoardPosition(index: 4)!)
        let original = session.board
        for _ in 0..<3 {
            guard let move = session.legalMoves.first else { break }
            session.apply(move)
        }
        session.restart()
        #expect(session.board == original)
        #expect(session.moveCount == 0)
        #expect(!session.canUndo)
        #expect(!session.canRedo)
    }

    @Test func randomizedPicksAnEmptyHole() {
        let session = GameSession.randomized()
        #expect(session.pegCount == 14)
        #expect(session.board.emptyPositions.count == 1)
    }
}

@Suite("Rating")
struct RatingTests {

    @Test func ratingMapping() {
        #expect(Rating(pegsRemaining: 1) == .genius)
        #expect(Rating(pegsRemaining: 0) == .genius)   // also a "win" tier
        #expect(Rating(pegsRemaining: 2) == .purtySmart)
        #expect(Rating(pegsRemaining: 3) == .justPlainDumb)
        #expect(Rating(pegsRemaining: 4) == .eeQuit)
        #expect(Rating(pegsRemaining: 9) == .eeQuit)
    }
}
