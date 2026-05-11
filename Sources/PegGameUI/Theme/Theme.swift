import SwiftUI
import PegGameKit

/// Color/style palette for the peg game UI. Themes are value types so they
/// drop straight into a SwiftUI Environment without isolation concerns.
public struct Theme: Sendable {

    /// Behind everything on the game screen.
    public var pageBackground: Color
    /// Tint applied beneath the wood-grain shader (controls warmth).
    public var boardSurfaceTint: Color
    /// Drop shadow color under the board.
    public var boardShadow: Color
    /// Fill for empty holes (dark recess).
    public var holeFill: Color
    /// Inner shadow color used to imply hole depth.
    public var holeShadow: Color
    /// Ring drawn around the user's selected peg.
    public var selectionTint: Color
    /// Marker drawn over hole indicating a legal destination.
    public var legalMoveTint: Color
    /// Marker drawn under a hint glow.
    public var hintTint: Color
    /// Per-color peg fill.
    public var pegColors: [PegColor: Color]
    /// Text color used by the score card / rating headline.
    public var headlineColor: Color
    /// Secondary text (blurbs, counts).
    public var bodyColor: Color

    public init(pageBackground: Color,
                boardSurfaceTint: Color,
                boardShadow: Color,
                holeFill: Color,
                holeShadow: Color,
                selectionTint: Color,
                legalMoveTint: Color,
                hintTint: Color,
                pegColors: [PegColor: Color],
                headlineColor: Color,
                bodyColor: Color) {
        self.pageBackground = pageBackground
        self.boardSurfaceTint = boardSurfaceTint
        self.boardShadow = boardShadow
        self.holeFill = holeFill
        self.holeShadow = holeShadow
        self.selectionTint = selectionTint
        self.legalMoveTint = legalMoveTint
        self.hintTint = hintTint
        self.pegColors = pegColors
        self.headlineColor = headlineColor
        self.bodyColor = bodyColor
    }

    public func color(for peg: PegColor) -> Color {
        pegColors[peg] ?? .gray
    }
}

extension Theme {
    /// Faithful Cracker Barrel look: deep brown room, warm wood triangle,
    /// classic peg colors, cream rating text.
    public static let crackerBarrel = Theme(
        pageBackground: Color(red: 0.12, green: 0.08, blue: 0.05),
        boardSurfaceTint: Color(red: 0.82, green: 0.65, blue: 0.40),
        boardShadow: Color.black.opacity(0.6),
        holeFill: Color(red: 0.10, green: 0.05, blue: 0.02),
        holeShadow: Color.black.opacity(0.65),
        selectionTint: Color(red: 1.00, green: 0.95, blue: 0.78),
        legalMoveTint: Color(red: 1.00, green: 0.95, blue: 0.78).opacity(0.55),
        hintTint: Color(red: 1.00, green: 0.85, blue: 0.40),
        pegColors: [
            .red:    Color(red: 0.82, green: 0.17, blue: 0.17),
            .yellow: Color(red: 0.96, green: 0.78, blue: 0.18),
            .green:  Color(red: 0.22, green: 0.62, blue: 0.32),
            .blue:   Color(red: 0.18, green: 0.42, blue: 0.78),
            .white:  Color(red: 0.96, green: 0.96, blue: 0.92),
        ],
        headlineColor: Color(red: 0.99, green: 0.92, blue: 0.78),
        bodyColor: Color(red: 0.90, green: 0.83, blue: 0.68)
    )
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .crackerBarrel
}

extension EnvironmentValues {
    public var pegTheme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    public func pegTheme(_ theme: Theme) -> some View {
        environment(\.pegTheme, theme)
    }
}
