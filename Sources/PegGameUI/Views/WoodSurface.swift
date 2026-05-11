import SwiftUI

/// Triangle shape with softly rounded corners, used as the wood board outline.
public struct RoundedTriangle: Shape {

    public var cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = 28) {
        self.cornerRadius = cornerRadius
    }

    public func path(in rect: CGRect) -> Path {
        let r = min(cornerRadius, min(rect.width, rect.height) * 0.25)
        let top = CGPoint(x: rect.midX, y: rect.minY)
        let bl  = CGPoint(x: rect.minX, y: rect.maxY)
        let br  = CGPoint(x: rect.maxX, y: rect.maxY)

        var p = Path()
        // Start slightly past top corner, on the left edge.
        // We'll use addArc(tangent1End:tangent2End:radius:) to round corners.
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

/// Procedural wood-grain board surface. Renders the wood shader inside a
/// rounded triangle, with a tint controlled by the theme.
public struct WoodSurface: View {

    @Environment(\.pegTheme) private var theme

    public init() {}

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            GeometryReader { proxy in
                RoundedTriangle()
                    .fill(theme.boardSurfaceTint)
                    .colorEffect(
                        ShaderLibrary.default
                            .woodGrain(
                                .float2(proxy.size.width, proxy.size.height),
                                .float(Float(time))
                            )
                    )
                    .overlay(
                        RoundedTriangle()
                            .stroke(Color.black.opacity(0.35), lineWidth: 1.2)
                    )
                    .shadow(color: theme.boardShadow, radius: 18, x: 0, y: 12)
            }
        }
    }
}
