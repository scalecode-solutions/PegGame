import SwiftUI
import PegGameKit
import PegGameUI

struct ContentView: View {
    let statsStore: any StatsStore

    var body: some View {
        PegGameView(
            session: GameSession.randomized(),
            statsStore: statsStore
        )
    }
}

#Preview {
    ContentView(statsStore: UserDefaultsStatsStore())
        .pegTheme(.crackerBarrel)
        .preferredColorScheme(.dark)
}
