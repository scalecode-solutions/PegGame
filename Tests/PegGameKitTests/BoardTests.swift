import Testing
@testable import PegGameKit

@Suite("BoardPosition / Move geometry")
struct BoardGeometryTests {

    @Test func boardHas15Positions() {
        #expect(BoardPosition.all.count == 15)
        #expect(BoardPosition.count == 15)
    }

    @Test func indexRowColRoundTrip() {
        for position in BoardPosition.all {
            let recomputed = BoardPosition(row: position.row, col: position.col)
            #expect(recomputed == position)
        }
    }

    @Test func rowAndColForKnownIndices() {
        #expect(BoardPosition(index: 0)!.row == 0)
        #expect(BoardPosition(index: 0)!.col == 0)
        #expect(BoardPosition(index: 4)!.row == 2)
        #expect(BoardPosition(index: 4)!.col == 1)
        #expect(BoardPosition(index: 14)!.row == 4)
        #expect(BoardPosition(index: 14)!.col == 4)
    }

    @Test func neighborsOfApexAreOnlyDownward() {
        let apex = BoardPosition(index: 0)!
        #expect(apex.neighbor(.left) == nil)
        #expect(apex.neighbor(.right) == nil)
        #expect(apex.neighbor(.upLeft) == nil)
        #expect(apex.neighbor(.upRight) == nil)
        #expect(apex.neighbor(.downLeft) == BoardPosition(index: 1))
        #expect(apex.neighbor(.downRight) == BoardPosition(index: 2))
    }

    @Test func thereAreExactly36MoveTemplates() {
        #expect(Move.allTemplates.count == 36)
    }

    @Test func moveTemplatesAreSymmetricInBothDirections() {
        // For every (A → C × B), there should be a (C → A × B) reversing it.
        let templates = Set(Move.allTemplates)
        for move in Move.allTemplates {
            let reverse = Move(from: move.to, over: move.over, to: move.from)
            #expect(templates.contains(reverse), "Missing reverse of \(move)")
        }
    }
}
