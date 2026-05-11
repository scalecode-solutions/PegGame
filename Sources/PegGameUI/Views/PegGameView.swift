import SwiftUI
import PegGameKit

/// Top-level peg game scene. Drop into a SwiftUI hierarchy and you're playing.
public struct PegGameView: View {

    @State private var model: PegGameViewModel
    @Environment(\.pegTheme) private var theme

    public init(session: GameSession? = nil,
                statsStore: any StatsStore = UserDefaultsStatsStore()) {
        let initialSession = session ?? GameSession.randomized()
        _model = State(initialValue: PegGameViewModel(
            session: initialSession,
            statsStore: statsStore
        ))
    }

    public var body: some View {
        ZStack {
            theme.pageBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Header(model: model)
                    .padding(.horizontal)

                BoardView(model: model)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 0)

                ControlBar(model: model)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            if case .complete(let pegs, let rating) = model.session.status, model.isShowingCelebration {
                ScoreCard(
                    rating: rating,
                    pegsRemaining: pegs,
                    moves: model.session.moveCount,
                    onRestartSame: { model.restart() },
                    onRestartRandom: {
                        let idx = Int.random(in: 0..<BoardPosition.count)
                        model.restart(emptyAt: BoardPosition(index: idx)!)
                    }
                )
                .padding(.horizontal, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.78), value: model.isShowingCelebration)
        .sensoryFeedback(.from(.pegMoved), trigger: model.session.moveCount)
        .sensoryFeedback(.from(.win), trigger: model.isShowingCelebration) { _, new in new }
        .sensoryFeedback(.from(.pegSelected), trigger: model.selectedPosition)
    }
}

private struct Header: View {
    @Bindable var model: PegGameViewModel
    @Environment(\.pegTheme) private var theme

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Peg Game")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(theme.headlineColor)
                Text("\(model.session.pegCount) pegs · \(model.session.moveCount) moves")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.bodyColor.opacity(0.85))
            }
            Spacer()
        }
    }
}
