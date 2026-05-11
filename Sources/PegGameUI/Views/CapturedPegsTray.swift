import SwiftUI
import PegGameKit

/// Horizontal-grid display of every peg that's been captured this game.
///
/// 5-column LazyVGrid; pegs fill left-to-right, top-to-bottom in capture
/// order. At the win state (13 captures) the layout is 5 + 5 + 3, leading
/// aligned, so the bottom row sits flush left with no "hollow" placeholders
/// on the right.
struct CapturedPegsTray: View {

    let history: [GameSession.HistoryEntry]

    private let columns: Int = 5
    private let pegSize: CGFloat = 22
    private let spacing: CGFloat = 6

    private var gridColumns: [GridItem] {
        Array(
            repeating: GridItem(.fixed(pegSize), spacing: spacing, alignment: .center),
            count: columns
        )
    }

    var body: some View {
        LazyVGrid(columns: gridColumns, alignment: .leading, spacing: spacing) {
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
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Captured pegs: \(history.count)")
    }
}
