# Embedding PegGame in a Host App

This doc covers the friction points and recommended API tweaks for
hosting `PegGameView` inside an existing app — typically a tab-based or
navigation-based shell — rather than running it as the root of its own
window (as `Demo/PegGameDemo` does).

The library works as-is for "I own the whole screen" use cases. The
notes below are about making the embed case feel clean instead of
double-chromed.

---

## Why embedding bites you out of the box

`PegGameView` is currently designed as a standalone scene:

- It owns its own header — `Sources/PegGameUI/Views/PegGameView.swift:71`
  draws "Peg Game" + "N pegs · N moves" + the stats button as a custom
  `HStack`, not as nav-bar items.
- The body fills the screen edge-to-edge via
  `theme.pageBackground.ignoresSafeArea()` (line 22-23).
- Stats sheet is locked to `.preferredColorScheme(.dark)` (line 66).
- The control bar at the bottom uses a hardcoded
  `.padding(.bottom, 8)` (`PegGameView.swift:39`) rather than safe-area
  insets.

When you drop `PegGameView` into a host that already provides
`NavigationStack` + nav bar + tab bar, those choices stack badly:

- **Double header.** The host's nav bar appears above PegGame's
  internal header. Two title-shaped things, two action-shaped things,
  both eating vertical space.
- **Conflicting action surfaces.** Host wants to put toolbar items in
  the trailing position; PegGame's stats button competes from inside
  the view.
- **Color-scheme override.** The hardcoded dark stats sheet ignores the
  host's user-selected appearance.
- **Tight bottom inset.** When the host hides its tab bar on push, the
  control bar can land too close to the home indicator.

None of these are bugs in the library — they're just consequences of
designing for standalone use. The library can grow a small,
backward-compatible embed mode that fixes all four.

---

## Recommended API additions

All changes preserve existing call sites (`PegGameView(session:)` and
`PegGameView(session:statsStore:)` still work as today). The new
parameters are opt-in.

### 1. `embedded: Bool = false` init parameter

```swift
public init(
    session: GameSession? = nil,
    statsStore: any StatsStore = UserDefaultsStatsStore(),
    embedded: Bool = false
)
```

When `embedded == true`, omit the internal `Header` view from the body.
The host is responsible for providing title, subtitle, and the stats
trigger via its own nav-bar chrome.

Implementation sketch in `PegGameView.swift`:

```swift
public var body: some View {
    ZStack {
        theme.pageBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            if !embedded {
                Header(model: model, showStats: { isShowingStats = true })
                    .padding(.horizontal)
            }

            BoardView(model: model)
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)

            Spacer(minLength: 0)

            ControlBar(model: model)
                .padding(.horizontal)
        }
        // …
    }
}
```

### 2. Optional `isShowingStats: Binding<Bool>?`

```swift
public init(
    session: GameSession? = nil,
    statsStore: any StatsStore = UserDefaultsStatsStore(),
    embedded: Bool = false,
    isShowingStats: Binding<Bool>? = nil
)
```

When `isShowingStats` is provided, the view uses the external binding
to drive its `.sheet(isPresented:)`. When `nil`, it falls back to the
internal `@State` (today's behavior).

This lets the host wire a toolbar button to the same stats sheet
without duplicating the sheet's contents:

```swift
@State private var showsStats = false

PegGameView(session: session, embedded: true, isShowingStats: $showsStats)
    .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { showsStats = true } label: {
                Image(systemName: "chart.bar.fill")
            }
        }
    }
```

Implementation note: pick the source-of-truth binding at init time —
something like

```swift
private var statsBinding: Binding<Bool> {
    externalStatsBinding ?? $internalStatsState
}
```

…and pass `statsBinding` to `.sheet(isPresented:)`.

### 3. Drop the hardcoded `.preferredColorScheme(.dark)` on the stats sheet

`Sources/PegGameUI/Views/PegGameView.swift:62-67`:

```swift
.sheet(isPresented: $isShowingStats) {
    StatsSheet(store: model.statsStore)
        .pegTheme(theme)
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)   // ← drop this
}
```

The page background is dark-amber-themed regardless of the system
appearance, so the stats sheet inherits that visual identity from
`theme` and `presentationDetents`. Force-dark on top forces the entire
sheet's typography and controls into dark mode even when the host is
in light. Let the host (or `pegTheme`) make that call.

If a hard-locked dark stats sheet matters, expose it as a per-call
option:

```swift
public init(
    …,
    statsSheetColorScheme: ColorScheme? = nil
)
```

Default `nil` → inherit. Apps that want it locked pass `.dark`.

### 4. Safe-area-aware bottom inset on `ControlBar`

`Sources/PegGameUI/Views/PegGameView.swift:38-39`:

```swift
ControlBar(model: model)
    .padding(.horizontal)
    .padding(.bottom, 8)   // ← assumes no tab bar / no home indicator
```

Replace the hardcoded `.padding(.bottom, 8)` with a safe-area-aware
form, e.g. apply the bottom padding through `safeAreaInset` or read
`safeAreaInsets` from the geometry:

```swift
ControlBar(model: model)
    .padding(.horizontal)
    .safeAreaPadding(.bottom, 8)
```

This way the buttons keep their 8pt gap above whatever the host's
effective bottom inset is — home indicator on phones without a tab
bar, tab bar on hosts that keep it visible during the game, nothing
on macOS.

---

## Example host integration

After the above changes, a typical embedded use looks like:

```swift
struct PegGameDestination: View {
    @State private var session = GameSession.randomized()
    @State private var showsStats = false

    var body: some View {
        PegGameView(
            session: session,
            embedded: true,
            isShowingStats: $showsStats
        )
        .pegTheme(.crackerBarrel)
        .navigationTitle("Peg Game")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showsStats = true } label: {
                    Image(systemName: "chart.bar.fill")
                }
            }
        }
    }
}
```

Pushed into via `NavigationLink`, this gives you:

- Host's system back chevron + nav-bar title for navigation chrome
- Host's toolbar trailing button for the stats sheet
- Game's wood-grain board + control bar wearing the chosen theme
- No double header, no chrome conflicts

For full-screen / non-embedded use, nothing changes — the existing
`PegGameView(session:)` initializer keeps working exactly as today.

---

## What to preserve

The visual identity is the point. Don't dilute these to "match" a
host:

- **The chosen `PegTheme`.** Wood grain, serif headline, amber palette
  — that's what makes the game feel like a *game* you opened, not a
  styled view of the host. Pick a theme, commit to it.
- **The page background extending edge-to-edge.** With the embedded
  header removed, the host's nav bar sits on top of the themed
  background, which reads as "the game is the entire surface below
  the chrome." Right effect.
- **Control bar's `.ultraThinMaterial` chrome.** Material backgrounds
  read well over wood grain and are already idiomatic across modern
  SwiftUI hosts. Don't try to swap them for the host's exact button
  style — a small visual delta reinforces "I'm in the game now."
- **Sensory feedback hooks.** The `.sensoryFeedback(...)` modifiers
  on lines 59-61 are tightly coupled to the gameplay state machine.
  Keep them; they're the difference between a game and a glorified
  form.

---

## Summary of the diff

Net change to `PegGameView`:

- Two optional init parameters (`embedded`, `isShowingStats`),
  defaults preserve current behavior
- One `if !embedded` guard around the `Header` instantiation
- One binding indirection for the stats sheet's `isPresented:`
- One removed `.preferredColorScheme(.dark)` modifier
- One `.padding(.bottom, 8)` → `.safeAreaPadding(.bottom, 8)` swap on
  `ControlBar`

All existing call sites — including `Demo/PegGameDemo` — keep working
without modification. The library gains a clean embed story without
losing its standalone one.
