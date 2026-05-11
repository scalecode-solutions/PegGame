import SwiftUI
import PegGameKit

/// Resolved on-screen positions for every hole in the triangle, given the
/// available container size. Equilateral spacing; bottom row touches the
/// outer board horizontally.
public struct BoardLayout: Equatable {

    public let containerSize: CGSize
    public let pegDiameter: CGFloat
    public let positions: [CGPoint]   // indexed by BoardPosition.index

    public init(containerSize: CGSize) {
        self.containerSize = containerSize
        // 5 pegs across the bottom row.
        let horizontalUnits: CGFloat = 5
        // Extra wood reserved above the top peg and below the bottom row so
        // every peg has visual breathing room from the triangle silhouette.
        // Padding is intentionally asymmetric — slightly more above the
        // apex than below the base — which seats the peg cluster a few
        // points below the triangle's vertical center and visually feels
        // like the pegs are resting *in* the board rather than floating.
        let apexPadding: CGFloat = 0.50
        let basePadding: CGFloat = 0.30
        let verticalGap: CGFloat = sqrt(3) / 2
        let verticalUnits = 4 * verticalGap + 1 + apexPadding + basePadding

        let unitFromWidth = containerSize.width / horizontalUnits
        let unitFromHeight = containerSize.height / verticalUnits
        let unit = min(unitFromWidth, unitFromHeight)
        self.pegDiameter = unit * 0.78

        let actualWidth = unit * horizontalUnits
        let actualHeight = unit * verticalUnits
        let xOffset = (containerSize.width - actualWidth) / 2
        let yOffset = (containerSize.height - actualHeight) / 2
        let topY = yOffset + unit * (0.5 + apexPadding)

        var pts: [CGPoint] = []
        pts.reserveCapacity(BoardPosition.count)
        for position in BoardPosition.all {
            let r = CGFloat(position.row)
            let c = CGFloat(position.col)
            // Row r has r+1 pegs, leftmost at index 0; we center the row.
            let rowStartX = xOffset + (5 - (r + 1)) * unit * 0.5 + unit * 0.5
            let x = rowStartX + c * unit
            let y = topY + r * unit * verticalGap
            pts.append(CGPoint(x: x, y: y))
        }
        self.positions = pts
    }

    public func point(for position: BoardPosition) -> CGPoint {
        positions[position.index]
    }
}
