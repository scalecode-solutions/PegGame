import SwiftUI
import PegGameKit

/// Bottom action row: undo, hint, restart, randomize.
public struct ControlBar: View {

    @Bindable public var model: PegGameViewModel
    @Environment(\.pegTheme) private var theme

    public init(model: PegGameViewModel) {
        self.model = model
    }

    public var body: some View {
        HStack(spacing: 14) {
            controlButton(systemImage: "arrow.uturn.backward",
                          label: "Undo",
                          isEnabled: model.session.canUndo) {
                model.undo()
            }

            controlButton(systemImage: "lightbulb",
                          label: "Hint",
                          isEnabled: model.session.status.isActive) {
                model.requestHint()
            }

            controlButton(systemImage: "arrow.counterclockwise",
                          label: "Restart",
                          isEnabled: true) {
                model.restart()
            }

            controlButton(systemImage: "shuffle",
                          label: "Random",
                          isEnabled: true) {
                let idx = Int.random(in: 0..<BoardPosition.count)
                model.restart(emptyAt: BoardPosition(index: idx)!)
            }
        }
    }

    private func controlButton(systemImage: String,
                               label: String,
                               isEnabled: Bool,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(0.6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isEnabled ? theme.headlineColor : theme.bodyColor.opacity(0.35))
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(theme.bodyColor.opacity(0.18), lineWidth: 1)
                )
        )
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.6)
    }
}
