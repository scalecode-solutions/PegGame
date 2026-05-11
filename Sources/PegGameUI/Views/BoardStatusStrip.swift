import SwiftUI
import PegGameKit

/// The status line under the board: pegs/moves count and the captured-peg tray.
///
/// Lives outside the Header so it remains visible when ``PegGameView`` is
/// embedded (host owns the nav-bar title; the status strip travels with the
/// gameplay surface).
struct BoardStatusStrip: View {

    @Bindable var model: PegGameViewModel
    @Environment(\.pegTheme) private var theme

    var body: some View {
        VStack(spacing: 10) {
            Text("\(model.session.pegCount) pegs · \(model.session.moveCount) moves")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.bodyColor.opacity(0.9))
                .monospacedDigit()

            if !model.session.history.isEmpty {
                CapturedPegsTray(history: model.session.history)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
