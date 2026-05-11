import SwiftUI
import PegGameKit

/// Horizontal strip of every peg captured this game, in capture order.
///
/// Single row — max 13 captures fits comfortably across an iPhone screen at
/// the chosen peg size. Each cell uses the same glossy `PegView` shader the
/// board pegs use, just shrunk down.
struct CapturedPegsTray: View {

    let history: [GameSession.HistoryEntry]

    private let pegSize: CGFloat = 22
    private let spacing: CGFloat = 5

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(history.enumerated()), id: \.offset) { _, entry in
                PegView(
                    peg: entry.capturedPeg,
                    diameter: pegSize,
                    isSelected: false,
                    isHinted: false
                )
                .frame(width: pegSize, height: pegSize)
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.2).combined(with: .opacity),
                        removal: .scale(scale: 0.4).combined(with: .opacity)
                    )
                )
            }
        }
        .frame(height: pegSize)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Captured pegs: \(history.count)")
    }
}
