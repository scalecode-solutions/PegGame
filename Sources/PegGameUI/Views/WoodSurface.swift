import SwiftUI

/// Triangle shape with softly rounded corners, used as the wood board outline.
public struct RoundedTriangle: Shape {

    public var cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = 32) {
        self.cornerRadius = cornerRadius
    }

    public func path(in rect: CGRect) -> Path {
        let r = min(cornerRadius, min(rect.width, rect.height) * 0.22)
        let top = CGPoint(x: rect.midX, y: rect.minY)
        let bl  = CGPoint(x: rect.minX, y: rect.maxY)
        let br  = CGPoint(x: rect.maxX, y: rect.maxY)

        var p = Path()
        // Start just past the top vertex, on the left edge.
        let start = midpoint(top, bl, fraction: 0.02)
        p.move(to: start)
        p.addLine(to: top)
        p.addArc(tangent1End: top, tangent2End: br, radius: r)
        p.addLine(to: br)
        p.addArc(tangent1End: br, tangent2End: bl, radius: r)
        p.addLine(to: bl)
        p.addArc(tangent1End: bl, tangent2End: top, radius: r)
        p.closeSubpath()
        return p
    }

    private func midpoint(_ a: CGPoint, _ b: CGPoint, fraction: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * fraction,
                y: a.y + (b.y - a.y) * fraction)
    }
}

/// Pine-plank board surface. The procedural grain shader paints a Rectangle,
/// which is then clipped to the triangle silhouette. A gradient bevel stroke
/// implies the wood's thickness; an inner shadow adds depth at the edges; a
/// drop shadow lifts the whole board off the page background.
public struct WoodSurface: View {

    @Environment(\.pegTheme) private var theme

    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            let triangle = RoundedTriangle(cornerRadius: 34)
            let w = proxy.size.width
            let h = proxy.size.height

            ZStack {
                // 1. Wood grain painted across the full bounding rect, then
                //    clipped to the triangle.
                Rectangle()
                    .fill(theme.boardSurfaceTint)
                    .colorEffect(
                        ShaderLibrary.default.woodGrain(
                            .float2(w, h)
                        )
                    )
                    .clipShape(triangle)

                // 2. Inner darkening around the inside of the triangle —
                //    suggests the wood is recessed slightly from the bevel.
                triangle
                    .stroke(Color.black.opacity(0.55), lineWidth: 10)
                    .blur(radius: 6)
                    .clipShape(triangle)
                    .blendMode(.multiply)

                // 3. Beveled outline: top-down gradient stroke. Light at the
                //    top edges (where light would hit the wood), dark at the
                //    bottom edges (where the wood thickness casts shadow).
                triangle
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.55),
                                Color.white.opacity(0.18),
                                Color.black.opacity(0.18),
                                Color.black.opacity(0.55),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2.5
                    )
            }
            .shadow(color: theme.boardShadow, radius: 20, x: 0, y: 14)
        }
    }
}
