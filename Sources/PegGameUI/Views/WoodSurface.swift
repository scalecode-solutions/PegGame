import SwiftUI

/// Triangle shape with uniform rounded corners.
///
/// Built from three `addArc(tangent1End:tangent2End:radius:)` calls. Each one
/// rounds the corner at its `tangent1End` by replacing the sharp join between
/// the incoming and outgoing edges with a circular arc of `cornerRadius`. The
/// current point at the start of each arc is *along* the incoming edge — not
/// at the corner — which is what the tangent-arc API expects. Starting the
/// path at the midpoint of one edge guarantees that.
public struct RoundedTriangle: Shape {

    public var cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = 12) {
        self.cornerRadius = cornerRadius
    }

    public func path(in rect: CGRect) -> Path {
        let r = min(cornerRadius, min(rect.width, rect.height) * 0.22)
        let top = CGPoint(x: rect.midX, y: rect.minY)
        let bl  = CGPoint(x: rect.minX, y: rect.maxY)
        let br  = CGPoint(x: rect.maxX, y: rect.maxY)
        // Midpoint of the right edge (top → br). Anywhere on an edge works;
        // this just gives us a clean starting "current point" along an
        // incoming line for the first tangent arc.
        let start = CGPoint(x: (top.x + br.x) / 2,
                            y: (top.y + br.y) / 2)

        var p = Path()
        p.move(to: start)
        p.addArc(tangent1End: br,  tangent2End: bl,  radius: r)
        p.addArc(tangent1End: bl,  tangent2End: top, radius: r)
        p.addArc(tangent1End: top, tangent2End: br,  radius: r)
        p.closeSubpath()
        return p
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
            let triangle = RoundedTriangle()
            let w = proxy.size.width
            let h = proxy.size.height

            ZStack {
                // 1. Wood grain painted across the full bounding rect, then
                //    clipped to the triangle.
                Rectangle()
                    .fill(theme.boardSurfaceTint)
                    .colorEffect(
                        ShaderLibrary.bundle(.module).woodGrain(
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
