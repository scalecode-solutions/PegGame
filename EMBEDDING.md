# Embedding PegGameView in a Host App

PegGameView ships in two modes. The default (`embedded: false`) owns the
whole screen and draws its own title row — that's what `Demo/PegGameDemo`
uses. The other mode is for when you're dropping the game *inside* an
existing app shell (NavigationStack, TabView, sheet, anywhere with its
own chrome).

## Standalone

```swift
import PegGameUI

struct ContentView: View {
    var body: some View {
        PegGameView()
            .pegTheme(.crackerBarrel)
    }
}
```

That's it — runs as today, with the internal header and stats button.

## Embedded

Two opt-in parameters:

```swift
public init(
    session: GameSession? = nil,
    statsStore: any StatsStore = UserDefaultsStatsStore(),
    embedded: Bool = false,
    isShowingStats: Binding<Bool>? = nil
)
```

- **`embedded: true`** hides the internal title row so the host's nav
  bar is the only chrome on screen. The wood-grain page background
  still extends edge-to-edge underneath.
- **`isShowingStats:`** is an optional external binding for the stats
  sheet. When you hide the internal header you also lose its chart
  button — pass a binding in and wire your own toolbar button to it,
  and the same sheet opens.

```swift
import PegGameUI

struct PegGameDestination: View {
    @State private var showsStats = false

    var body: some View {
        PegGameView(
            embedded: true,
            isShowingStats: $showsStats
        )
        .pegTheme(.crackerBarrel)
        .navigationTitle("Peg Game")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showsStats = true } label: {
                    Image(systemName: "chart.bar.fill")
                }
            }
        }
    }
}
```

Push that from any `NavigationStack` and you get:

- Host's system back chevron + nav-bar title
- Host's trailing toolbar button driving the stats sheet
- Wood-grain board with the chosen theme
- Status strip + captured-peg tray under the board (live counts +
  visual progress, always shown)
- Control bar at the bottom

Tab bars and bottom safe areas are handled — `ControlBar` uses
`.safeAreaPadding(.bottom, 8)`, so the buttons keep their 8pt gap above
whatever inset is in effect (home indicator with the tab bar hidden,
the tab bar itself when the host keeps it visible, nothing on macOS).

## What to keep

- **The theme.** `.pegTheme(.crackerBarrel)` is the visual identity —
  wood-grain, serif headline, amber palette. Pick a theme and commit
  to it; don't try to harmonize with the host's button style or
  background.
- **The page background extending edge-to-edge.** Lets the host's nav
  bar sit on top of the wood, which reads as "the game is the entire
  surface below the chrome." Right effect.
- **`.sensoryFeedback(...)` hooks.** They're built into PegGameView and
  tied to the gameplay state machine. Just let them run.

## Picking a theme per host

The theme is read from the environment via `\.pegTheme`. Apply it at
any level above PegGameView:

```swift
PegGameView(embedded: true, isShowingStats: $showsStats)
    .pegTheme(.crackerBarrel)
```

Custom themes work too — `Theme` is a value type with public
initializers, so you can build your own with whichever palette and
substitute it for `.crackerBarrel`.

## What's not in the public API

Intentionally not exposed:

- The view-model is internal. Push state in via `session:` and read
  state out by holding your own reference to that `GameSession` (it's
  `@Observable`).
- Stat aggregation. Use `StatsStore` from `PegGameKit` directly if you
  want to surface stats outside the bundled sheet.
- The `Header` view. If you want a Peg Game–branded title inside your
  host, render it yourself with the theme's `headlineColor` and a
  serif font; it's three lines.

## Compatibility note

All four embed-mode parameters default to "standalone" behavior, so
existing call sites continue to work without modification:

```swift
PegGameView()                                    // unchanged
PegGameView(session: customSession)              // unchanged
PegGameView(session: s, statsStore: customStore) // unchanged
```
