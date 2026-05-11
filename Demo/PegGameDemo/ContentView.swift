import SwiftUI
import PegGameKit
import PegGameUI

struct ContentView: View {
    var body: some View {
        PegGameView(session: GameSession.randomized())
    }
}

#Preview {
    ContentView()
        .pegTheme(.crackerBarrel)
        .preferredColorScheme(.dark)
}
