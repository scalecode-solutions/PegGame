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
        // 5 pegs across the bottom; leave a half-peg margin on each side.
        let horizontalUnits: CGFloat = 5
        let unitFromWidth = containerSize.width / horizontalUnits
        // Vertically we need 4 row-gaps of √3/2·unit plus a half-peg margin top/bottom.
        let verticalGap: CGFloat = sqrt(3) / 2
        let unitFromHeight = containerSize.height / (4 * verticalGap + 1)
        let unit = min(unitFromWidth, unitFromHeight)
        self.pegDiameter = unit * 0.78

        let actualWidth = unit * horizontalUnits
        let actualHeight = unit * (4 * verticalGap + 1)
        let xOffset = (containerSize.width - actualWidth) / 2
        let yOffset = (containerSize.height - actualHeight) / 2
        let topY = yOffset + unit * 0.5

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
