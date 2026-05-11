import SwiftUI
import PegGameKit

/// Renders the 15-hole triangle: wood backing, holes, pegs, selection / hint
/// indicators, and the win celebration overlay. Routes taps through the
/// supplied ``PegGameViewModel``.
public struct BoardView: View {

    @Bindable public var model: PegGameViewModel
    @Environment(\.pegTheme) private var theme

    public init(model: PegGameViewModel) {
        self.model = model
    }

    public var body: some View {
        GeometryReader { proxy in
            let layout = BoardLayout(containerSize: proxy.size)
            ZStack(alignment: .topLeading) {
                Color.clear
                WoodSurface()

                ForEach(BoardPosition.all, id: \.index) { position in
                    cell(at: position, layout: layout)
                }

                if let inFlight = model.inFlightMove {
                    FlyingPegOverlay(inFlight: inFlight, layout: layout)
                        .transition(.opacity)
                }

                if model.isShowingCelebration {
                    CelebrationOverlay(progress: model.celebrationProgress,
                                       seed: model.celebrationSeed)
                        .allowsHitTesting(false)
                }
            }
            .onChange(of: model.isShowingCelebration) { _, showing in
                guard showing else { return }
                withAnimation(.easeOut(duration: 1.6)) {
                    model.celebrationProgress = 1
                }
            }
        }
        // Aspect ≈ 1.20 — slightly wider than equilateral (1.155). The peg
        // cluster's slope is 60° (rows offset by half a unit); a wider
        // container makes the triangle silhouette less steep than the peg
        // cluster, so the middle-row corner pegs end up with consistent
        // wood margin instead of being kissed by the silhouette.
        .aspectRatio(1.20, contentMode: .fit)
    }

    @ViewBuilder
    private func cell(at position: BoardPosition, layout: BoardLayout) -> some View {
        let center = layout.point(for: position)
        let diameter = layout.pegDiameter
        let isLegalDest = model.legalDestinationsFromSelection.contains(position)
        let isHintDest = model.isHintDestination(position)

        // Hide pegs participating in the current in-flight move; the flying
        // overlay owns the source peg's render, and the captured peg
        // visually "vanishes" the moment the arc begins.
        let inFlight = model.inFlightMove
        let isFlyingSource = inFlight?.move.from == position
        let isFlyingCaptured = inFlight?.move.over == position

        ZStack {
            HoleView(
                diameter: diameter,
                isLegalDestination: isLegalDest,
                isHintDestination: isHintDest
            )

            if !isFlyingSource, !isFlyingCaptured,
               let peg = model.session.board.peg(at: position) {
                PegView(
                    peg: peg,
                    diameter: diameter,
                    isSelected: model.selectedPosition == position,
                    isHinted: model.isHintSource(position)
                )
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.4).combined(with: .opacity),
                        removal: .scale(scale: 0.3).combined(with: .opacity)
                    )
                )
            }
        }
        .frame(width: diameter, height: diameter)
        .contentShape(Circle())
        .onTapGesture {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                model.tap(position)
            }
        }
        .offset(x: center.x - diameter / 2, y: center.y - diameter / 2)
        .animation(.easeInOut(duration: 0.18), value: isLegalDest)
    }
}

/// Transparent radial-burst overlay using the Celebration Metal shader.
private struct CelebrationOverlay: View {
    let progress: Double
    let seed: Double

    var body: some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(Color.white.opacity(0.001))
                .colorEffect(
                    ShaderLibrary.default.celebration(
                        .float2(proxy.size.width, proxy.size.height),
                        .float(Float(progress)),
                        .float(Float(seed))
                    )
                )
                .blendMode(.screen)
                .compositingGroup()
        }
    }
}
