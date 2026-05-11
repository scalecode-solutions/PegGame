import SwiftUI
import PegGameKit

/// Animates a peg arcing from `move.from` to `move.to`. Driven by a
/// `TimelineView` so the arc updates every display frame.
struct FlyingPegOverlay: View {

    let inFlight: PegGameViewModel.InFlightMove
    let layout: BoardLayout

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 120.0)) { context in
            let elapsed = max(0, context.date.timeIntervalSince(inFlight.startedAt))
            let progress = min(1.0, elapsed / inFlight.duration)
            let eased = easeInOutCubic(progress)
            let liftCurve = sin(eased * .pi)

            let from = layout.point(for: inFlight.move.from)
            let to = layout.point(for: inFlight.move.to)
            let diameter = layout.pegDiameter
            let arcHeight = diameter * 1.6

            let x = from.x + (to.x - from.x) * eased
            let yStraight = from.y + (to.y - from.y) * eased
            let y = yStraight - liftCurve * arcHeight

            // The peg appears to swell slightly as it crests, suggesting altitude.
            let scale = 1.0 + 0.10 * liftCurve

            // Cast shadow on the board below, tracking the straight-line position
            // and growing softer as the peg rises.
            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.35 - 0.22 * liftCurve))
                    .frame(width: diameter * (0.72 + 0.18 * liftCurve),
                           height: diameter * 0.22)
                    .blur(radius: 2 + 4 * liftCurve)
                    .offset(x: x - diameter / 2,
                            y: yStraight - diameter * 0.05)

                PegView(
                    peg: inFlight.peg,
                    diameter: diameter,
                    isSelected: false,
                    isHinted: false
                )
                .scaleEffect(scale)
                .shadow(color: .black.opacity(0.35 * liftCurve),
                        radius: 4 + 6 * liftCurve,
                        x: 0,
                        y: 2 + 6 * liftCurve)
                .offset(x: x - diameter / 2, y: y - diameter / 2)
            }
        }
        .allowsHitTesting(false)
    }

    private func easeInOutCubic(_ t: Double) -> Double {
        t < 0.5
            ? 4 * t * t * t
            : 1 - pow(-2 * t + 2, 3) / 2
    }
}
