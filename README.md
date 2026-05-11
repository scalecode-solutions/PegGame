# PegGame

Triangle peg solitaire — the Cracker Barrel one — built as a Swift Package
for iOS 26 with SwiftUI 6 and a handful of Metal shaders for board, peg, hint,
and celebration effects.

> Leave only one peg and you're a genius. Leave two and you're purty smart.
> Leave three and you're just plain dumb. Leave four or more and you're an
> ee-quit.

The package is split into two products: a pure-Swift engine (`PegGameKit`) and
a SwiftUI view layer (`PegGameUI`). Use them together for a drop-in playable
game, or import just the engine and bring your own UI.

## Requirements

- iOS 26 (iPhone)
- Xcode 26 / Swift 6.2+

(The package also builds on macOS 26 so `swift test` works locally; the UI is
designed for iPhone.)

## Install

In your project's `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/scalecode-solutions/PegGame.git", from: "0.6.0"),
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "PegGameUI", package: "PegGame"),
            // Or, for engine-only:
            // .product(name: "PegGameKit", package: "PegGame"),
        ]
    )
]
```

In Xcode: **File → Add Package Dependencies…** → paste the repo URL.

## Quick start

### Standalone (one-liner game)

```swift
import SwiftUI
import PegGameUI

struct ContentView: View {
    var body: some View {
        PegGameView()
            .pegTheme(.crackerBarrel)
    }
}
```

That's the whole game. `PegGameView` owns the header, board, status strip,
captured-peg tray, control bar, score card, stats sheet, animations, haptics,
and the wood-grain Metal background.

### Embedded in a host

If you're slotting the game inside an existing `NavigationStack` or shell,
pass `embedded: true` to hide the internal header and provide your own:

```swift
struct PegGameDestination: View {
    @State private var showsStats = false

    var body: some View {
        PegGameView(embedded: true, isShowingStats: $showsStats)
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

Full integration guide: [EMBEDDING.md](EMBEDDING.md).

## Features

- **Pure-Swift engine** — `Board`, `Move`, `GameSession` with undo/redo,
  memoized solver that answers "is this position winnable?" and
  ranks/recommends moves
- **Multicolor pegs** — classic Cracker Barrel red / yellow / green / blue /
  white, purely aesthetic; rules are identical to standard triangle peg
  solitaire
- **Randomized start hole** — `GameSession.randomized()`; every starting hole
  is mathematically winnable
- **Arc-animated peg jumps** — `TimelineView`-driven parabolic trajectory
  with a tracking ground shadow
- **Wood-grain board** — procedural pine shader, compiled into the package's
  resource bundle via an SPM build-tool plugin (no `.metal` file wiring on
  the consumer side)
- **Glossy pegs** — domed Lambert + specular `colorEffect` shader
- **Hint system** — pulsing source-peg halo + radiating destination ring
- **Win celebration** — radial sunburst shader; score card with Cracker
  Barrel-faithful rating text
- **Captured-peg tray** — live timeline of removed pegs under the board
- **Pluggable persistence** — `StatsStore` protocol with two implementations
  shipped: `UserDefaultsStatsStore` (zero deps) and `SwiftDataStatsStore`
  (queryable, scales)
- **Theming** — `Theme` value type read from the environment via
  `\.pegTheme`; ships with `.crackerBarrel` and is open to custom themes
- **Haptics** — `SensoryFeedback` on peg select / move / win

## Architecture

```
PegGameKit  (pure Swift, zero UI deps)
├── Model       BoardPosition · Peg · Move · Board
├── Game        GameSession (@Observable) · GameStatus · Rating
├── Solver      memoized winnability + hint + grading
└── Persistence StatsStore protocol
                ├── UserDefaultsStatsStore
                └── SwiftDataStatsStore  (@ModelActor + @Model)

PegGameUI   (SwiftUI 6)
├── Theme       Theme value type + .crackerBarrel
├── Views       PegGameView (top-level) + BoardView · BoardStatusStrip
│               · CapturedPegsTray · ControlBar · ScoreCard · StatsSheet
│               · PegView · HoleView · WoodSurface · HintDestinationPulse
│               · FlyingPegOverlay
├── Shaders     WoodGrain · PegGloss · HintGlow · Celebration  (.metal)
└── Haptics     PegHaptic → SensoryFeedback
```

The Metal shaders are compiled by the
[scalecode-metal-plugin](https://github.com/scalecode-solutions/scalecode-metal-plugin)
build-tool plugin (declared as a SPM dependency, not in-tree). It picks
up every `.metal` in `Sources/PegGameUI/Shaders/` and links them into
a single `default.metallib` resource, so `ShaderLibrary.bundle(.module)`
resolves them at runtime with no consumer wiring. Extracting it lets
sibling game packages share the same toolchain shell-out instead of
copy-pasting it.

## Stats backends

The default backend is JSON-encoded into `UserDefaults` — zero dependencies,
fine for modest history.

For richer queries, pass a SwiftData-backed store at the call site:

```swift
let store = try SwiftDataStatsStore()
PegGameView(statsStore: store)
```

Same `StatsStore` protocol, faster aggregates, sortable history. The protocol
itself is `Sendable` and exposes async methods (`record(_:) async`,
`summary() async`, `history(limit:) async`, `reset() async`), so swap one for
the other and existing call sites keep working.

## Theming

Themes are plain value types. The bundled one is `.crackerBarrel`:

```swift
PegGameView()
    .pegTheme(.crackerBarrel)
```

Construct your own `Theme(...)` with any palette, then publish it via
`.pegTheme(myTheme)` at any level above `PegGameView`.

## Demo

`Demo/PegGameDemo.xcodeproj` is a single-target iPhone app wired to the local
SPM via a relative-path reference. Open it, build, run.

## Testing

`swift test` from the package root. The kit's 26 Swift Testing cases cover
the board geometry, move legality, undo/redo, the solver's winnability
proof for every starting hole, and round-tripping the SwiftData store
in-memory.

## Development setup

PegGameUI pulls in
[`scalecode-metal-plugin`](https://github.com/scalecode-solutions/scalecode-metal-plugin),
which ships an SPM build-tool plugin. Xcode prompts you to **Trust & Enable
Plugin** on first open of any project that depends on it. Clicking trust
once is fine — Xcode remembers per-plugin-fingerprint — but if you want
to skip all such prompts for your user account on this machine, set the
hidden defaults:

```sh
# Trust SPM build plugins (and Swift macros) without prompting
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidation -bool YES
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
```

Restart Xcode for the changes to take effect. To revert:

```sh
defaults delete com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidation
defaults delete com.apple.dt.Xcode IDESkipMacroFingerprintValidation
```

These settings are **per-user, per-machine** and bypass validation for
*every* package's build plugins and macros — same blast radius as clicking
"Trust & Enable" on whatever happens to show up. Reasonable for solo dev
machines; less appropriate for shared CI or someone else's Mac.

## License

[MIT](LICENSE). Use it freely.
