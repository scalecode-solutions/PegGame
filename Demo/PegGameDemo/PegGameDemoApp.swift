import SwiftUI
import PegGameKit
import PegGameUI

@main
struct PegGameDemoApp: App {

    /// SwiftData-backed stats store. Constructed once at app launch and
    /// passed down to the game view; the underlying ModelContainer lives
    /// for the app's lifetime.
    private let statsStore: any StatsStore

    init() {
        do {
            statsStore = try SwiftDataStatsStore()
        } catch {
            // If SwiftData fails to initialize (e.g. corrupted store on
            // upgrade), fall back to the zero-deps UserDefaults backend
            // so the user can still play.
            assertionFailure("SwiftDataStatsStore init failed: \(error)")
            statsStore = UserDefaultsStatsStore()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(statsStore: statsStore)
                .pegTheme(.crackerBarrel)
                .preferredColorScheme(.dark)
        }
    }
}
