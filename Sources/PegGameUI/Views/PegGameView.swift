import SwiftUI
import PegGameKit

/// Top-level peg game scene. Drop into a SwiftUI hierarchy and you're playing.
///
/// ### Standalone
/// ```swift
/// PegGameView()                       // owns the whole screen, internal header
/// PegGameView(session: customSession) // bring your own starting board
/// ```
///
/// ### Embedded in a host
/// Pass `embedded: true` to hide the internal title row (the host's nav bar
/// supplies the title). Pass `isShowingStats: $yourBinding` and add your own
/// toolbar button that flips it, and the same stats sheet pops up.
///
/// ```swift
/// @State private var showsStats = false
///
/// PegGameView(embedded: true, isShowingStats: $showsStats)
///     .navigationTitle("Peg Game")
///     .toolbar {
///         ToolbarItem(placement: .topBarTrailing) {
///             Button { showsStats = true } label: { Image(systemName: "chart.bar.fill") }
///         }
///     }
/// ```
public struct PegGameView: View {

    @State private var model: PegGameViewModel
    @State private var internalIsShowingStats = false
    @Environment(\.pegTheme) private var theme

    private let embedded: Bool
    private let externalStatsBinding: Binding<Bool>?

    public init(
        session: GameSession? = nil,
        statsStore: any StatsStore = UserDefaultsStatsStore(),
        embedded: Bool = false,
        isShowingStats: Binding<Bool>? = nil
    ) {
        let initialSession = session ?? GameSession.randomized()
        _model = State(initialValue: PegGameViewModel(
            session: initialSession,
            statsStore: statsStore
        ))
        self.embedded = embedded
        self.externalStatsBinding = isShowingStats
    }

    /// Drives the stats sheet's `isPresented:`. External binding wins when
    /// supplied; otherwise the view manages its own state.
    private var statsBinding: Binding<Bool> {
        externalStatsBinding ?? Binding(
            get: { internalIsShowingStats },
            set: { internalIsShowingStats = $0 }
        )
    }

    public var body: some View {
        ZStack {
            theme.pageBackground
                .ignoresSafeArea()

            VStack(spacing: 18) {
                if !embedded {
                    Header(showStats: { statsBinding.wrappedValue = true })
                        .padding(.horizontal)
                }

                BoardView(model: model)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)

                BoardStatusStrip(model: model)
                    .padding(.horizontal)

                Spacer(minLength: 0)

                ControlBar(model: model)
                    .padding(.horizontal)
                    .safeAreaPadding(.bottom, 8)
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
        .sheet(isPresented: statsBinding) {
            StatsSheet(store: model.statsStore)
                .pegTheme(theme)
                .presentationDetents([.medium, .large])
        }
    }
}

private struct Header: View {
    @Environment(\.pegTheme) private var theme
    var showStats: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Text("Peg Game")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(theme.headlineColor)
            Spacer()
            Button(action: showStats) {
                Image(systemName: "chart.bar.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(theme.headlineColor)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle().stroke(theme.bodyColor.opacity(0.18), lineWidth: 1)
                            )
                    )
            }
            .accessibilityLabel("Stats")
        }
    }
}
