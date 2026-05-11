import SwiftUI

/// Discrete haptic events the game emits. Mapped to `SensoryFeedback` so views
/// can subscribe via `.sensoryFeedback(_:trigger:)`.
public enum PegHaptic: Hashable, Sendable {
    case pegSelected
    case pegMoved
    case illegalTap
    case undo
    case win
}

extension SensoryFeedback {
    public static func from(_ haptic: PegHaptic) -> SensoryFeedback {
        switch haptic {
        case .pegSelected: .selection
        case .pegMoved: .impact(weight: .medium)
        case .illegalTap: .error
        case .undo: .impact(weight: .light)
        case .win: .success
        }
    }
}
