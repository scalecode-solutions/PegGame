import SwiftUI

/// An empty peg socket. Dark recess with subtle inner-shadow rim.
public struct HoleView: View {

    @Environment(\.pegTheme) private var theme

    public let diameter: CGFloat
    public let isLegalDestination: Bool
    public let isHintDestination: Bool

    public init(diameter: CGFloat,
                isLegalDestination: Bool = false,
                isHintDestination: Bool = false) {
        self.diameter = diameter
        self.isLegalDestination = isLegalDestination
        self.isHintDestination = isHintDestination
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(theme.holeFill)
                .shadow(color: theme.holeShadow, radius: diameter * 0.08, x: 0, y: diameter * 0.04)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.black.opacity(0.55), Color.white.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: max(1, diameter * 0.06)
                        )
                        .blur(radius: diameter * 0.02)
                )

            if isLegalDestination {
                Circle()
                    .fill(theme.legalMoveTint)
                    .frame(width: diameter * 0.32, height: diameter * 0.32)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: diameter, height: diameter)
    }
}
