import SwiftUI

/// Expanding-ring pulse rendered over the destination hole of the current
/// hint. Two staggered rings make the pulse feel continuous; each ring
/// scales outward and fades over a fixed cycle.
struct HintDestinationPulse: View {

    let diameter: CGFloat
    let color: Color

    /// Cycle length in seconds (one ring's full expand+fade).
    private let cycle: Double = 1.35
    /// How many rings overlap at once. 2 gives a smooth "radar" pulse.
    private let ringCount = 2
    /// Final scale of each ring at the end of its cycle.
    private let maxScale: Double = 1.85
    /// Starting scale of each ring.
    private let minScale: Double = 0.55

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
            let now = context.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<ringCount, id: \.self) { index in
                    let offset = Double(index) * cycle / Double(ringCount)
                    let phase = ((now + offset).truncatingRemainder(dividingBy: cycle)) / cycle
                    Circle()
                        .stroke(color, lineWidth: max(2, diameter * 0.06))
                        .frame(width: diameter, height: diameter)
                        .scaleEffect(minScale + (maxScale - minScale) * phase)
                        .opacity((1.0 - phase) * 0.85)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
