import SwiftUI
import PegGameKit

/// A single glossy peg rendered with the peg-gloss Metal shader plus optional
/// selection ring and pulsing hint glow.
public struct PegView: View {

    @Environment(\.pegTheme) private var theme

    public let peg: Peg
    public let diameter: CGFloat
    public let isSelected: Bool
    public let isHinted: Bool

    public init(peg: Peg, diameter: CGFloat, isSelected: Bool = false, isHinted: Bool = false) {
        self.peg = peg
        self.diameter = diameter
        self.isSelected = isSelected
        self.isHinted = isHinted
    }

    public var body: some View {
        ZStack {
            // Dome via PegGloss shader.
            Circle()
                .fill(theme.color(for: peg.color))
                .frame(width: diameter, height: diameter)
                .colorEffect(
                    ShaderLibrary.default
                        .pegGloss(.float2(diameter, diameter))
                )
                .modifier(HintGlowEffect(isActive: isHinted, color: theme.hintTint, diameter: diameter))

            if isSelected {
                Circle()
                    .stroke(theme.selectionTint, lineWidth: max(2, diameter * 0.08))
                    .frame(width: diameter * 1.08, height: diameter * 1.08)
                    .shadow(color: theme.selectionTint.opacity(0.6), radius: diameter * 0.18)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(isSelected ? 1.06 : 1.0)
        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isSelected)
    }
}

/// Pulsing colored halo using the HintGlow Metal layerEffect.
private struct HintGlowEffect: ViewModifier {
    let isActive: Bool
    let color: Color
    let diameter: CGFloat

    func body(content: Content) -> some View {
        if isActive {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                let t = Float(context.date.timeIntervalSinceReferenceDate)
                content
                    .layerEffect(
                        ShaderLibrary.default.hintGlow(
                            .float(t),
                            .color(color)
                        ),
                        maxSampleOffset: CGSize(width: 14, height: 14)
                    )
            }
        } else {
            content
        }
    }
}
