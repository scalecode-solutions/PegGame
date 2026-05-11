import SwiftUI
import PegGameUI

@main
struct PegGameDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .pegTheme(.crackerBarrel)
                .preferredColorScheme(.dark)
        }
    }
}
