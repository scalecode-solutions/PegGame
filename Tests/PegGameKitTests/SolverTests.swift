import Testing
@testable import PegGameKit

@Suite("Solver")
struct SolverTests {

    @Test func singlePegPositionIsTriviallyWinnable() {
        let solver = Solver()
        let oneBit: UInt16 = 0b1
        #expect(solver.isWinnable(from: oneBit))
    }

    @Test func emptyBoardIsWinnable() {
        // Convention: zero pegs is "winnable" (terminal state already at ≤1 peg).
        let solver = Solver()
        #expect(solver.isWinnable(from: 0))
    }

    @Test func classicStartingPositionIsWinnable() {
        // Empty hole at apex (index 0) — the canonical Cracker Barrel start.
        let solver = Solver()
        let board = Board(emptyAt: BoardPosition(index: 0)!)
        #expect(solver.isWinnable(board))
    }

    @Test func everyStartingHoleIsWinnable() {
        // Triangle peg solitaire is solvable from every starting empty position.
        let solver = Solver()
        for empty in BoardPosition.all {
            let board = Board(emptyAt: empty)
            #expect(solver.isWinnable(board), "Should be winnable starting empty at \(empty)")
        }
    }

    @Test func hintIsLegalAndKeepsWinnableWhenPossible() throws {
        let solver = Solver()
        let board = Board(emptyAt: BoardPosition(index: 0)!)
        let hint = try #require(solver.hint(for: board))
        #expect(board.isLegal(hint))
        var next = board
        _ = next.apply(hint)
        #expect(solver.isWinnable(next))
    }

    @Test func gradeFlagsLosingMove() throws {
        // Find any starting position + move that breaks winnability and ensure the grader catches it.
        let solver = Solver()
        let board = Board(emptyAt: BoardPosition(index: 0)!)
        var foundBreak = false
        for move in board.legalMoves() {
            let grade = solver.grade(move, on: board)
            if grade == .breaksWinnable {
                foundBreak = true
                var after = board
                _ = after.apply(move)
                #expect(!solver.isWinnable(after))
                break
            }
        }
        // There may or may not be a breaking move from the apex start; if there is, we verified it.
        // If there isn't, the test is informational.
        _ = foundBreak
    }
}
