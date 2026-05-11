import SwiftUI
import PegGameKit

/// End-of-game summary with the Cracker Barrel rating, peg count, and
/// quick actions for restart / new-random-start.
public struct ScoreCard: View {

    @Environment(\.pegTheme) private var theme

    public let rating: Rating
    public let pegsRemaining: Int
    public let moves: Int
    public let onRestartSame: () -> Void
    public let onRestartRandom: () -> Void

    public init(rating: Rating,
                pegsRemaining: Int,
                moves: Int,
                onRestartSame: @escaping () -> Void,
                onRestartRandom: @escaping () -> Void) {
        self.rating = rating
        self.pegsRemaining = pegsRemaining
        self.moves = moves
        self.onRestartSame = onRestartSame
        self.onRestartRandom = onRestartRandom
    }

    public var body: some View {
        VStack(spacing: 18) {
            Text(rating.label.uppercased())
                .font(.system(size: 40, weight: .black, design: .serif))
                .tracking(2)
                .foregroundStyle(theme.headlineColor)
                .shadow(color: .black.opacity(0.45), radius: 6, x: 0, y: 3)

            Text(rating.blurb)
                .font(.system(.headline, design: .serif))
                .foregroundStyle(theme.bodyColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 28) {
                statBlock(value: "\(pegsRemaining)", label: "peg\(pegsRemaining == 1 ? "" : "s") left")
                Divider().frame(height: 36).overlay(theme.bodyColor.opacity(0.4))
                statBlock(value: "\(moves)", label: "moves")
            }
            .padding(.vertical, 8)

            HStack(spacing: 12) {
                Button(action: onRestartSame) {
                    Label("Replay", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.headlineColor.opacity(0.85))
                .foregroundStyle(theme.pageBackground)

                Button(action: onRestartRandom) {
                    Label("New Start", systemImage: "shuffle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(theme.bodyColor)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(theme.bodyColor.opacity(0.25), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 22, x: 0, y: 14)
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 28, weight: .heavy, design: .serif))
                .foregroundStyle(theme.headlineColor)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(theme.bodyColor.opacity(0.85))
                .textCase(.uppercase)
                .tracking(0.8)
        }
    }
}
