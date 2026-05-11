import SwiftUI
import PegGameKit

/// Modal sheet showing aggregate stats and recent-game history from a
/// ``StatsStore``. Reloads each time it's presented.
public struct StatsSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.pegTheme) private var theme

    public let store: any StatsStore

    @State private var summary: StatsSummary = .empty
    @State private var recent: [CompletedGame] = []
    @State private var isLoading = true

    public init(store: any StatsStore) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    summarySection
                    historySection
                }
                .padding(20)
            }
            .background(theme.pageBackground.ignoresSafeArea())
            .navigationTitle("Stats")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.pageBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(theme.headlineColor)
                }
            }
            #endif
        }
        .task { await load() }
    }

    // MARK: - Sections

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Summary")
            HStack(spacing: 10) {
                statCard(value: "\(summary.gamesPlayed)", label: "Games")
                statCard(value: bestLabel, label: "Best")
                statCard(value: "\(summary.geniusCount)", label: "Genius")
                statCard(
                    value: summary.gamesPlayed > 0
                        ? String(format: "%.1f", summary.averagePegsRemaining)
                        : "—",
                    label: "Avg"
                )
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Recent Games")

            if isLoading && recent.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else if recent.isEmpty {
                ContentUnavailableView(
                    "No games yet",
                    systemImage: "tray",
                    description: Text("Play a game to start tracking stats.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                VStack(spacing: 8) {
                    ForEach(recent) { game in
                        gameRow(game)
                    }
                }
            }
        }
    }

    // MARK: - Cells

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .textCase(.uppercase)
            .tracking(0.8)
            .foregroundStyle(theme.bodyColor.opacity(0.9))
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title2, design: .serif).weight(.heavy))
                .foregroundStyle(theme.headlineColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .tracking(0.6)
                .foregroundStyle(theme.bodyColor.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(theme.bodyColor.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func gameRow(_ game: CompletedGame) -> some View {
        HStack(alignment: .center, spacing: 14) {
            ratingBadge(for: game.rating)
            VStack(alignment: .leading, spacing: 3) {
                Text(game.rating.label)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(theme.headlineColor)
                Text("\(game.pegsRemaining) peg\(game.pegsRemaining == 1 ? "" : "s") · \(game.moves) moves")
                    .font(.caption)
                    .foregroundStyle(theme.bodyColor.opacity(0.75))
            }
            Spacer()
            Text(game.date, format: .relative(presentation: .named))
                .font(.caption)
                .foregroundStyle(theme.bodyColor.opacity(0.55))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    private func ratingBadge(for rating: Rating) -> some View {
        let symbol: String = switch rating {
        case .genius: "star.fill"
        case .purtySmart: "checkmark.circle.fill"
        case .justPlainDumb: "minus.circle.fill"
        case .eeQuit: "xmark.circle.fill"
        }
        let tint: Color = switch rating {
        case .genius: theme.hintTint
        case .purtySmart: theme.headlineColor.opacity(0.8)
        case .justPlainDumb: theme.bodyColor.opacity(0.55)
        case .eeQuit: theme.bodyColor.opacity(0.40)
        }
        return Image(systemName: symbol)
            .font(.title2)
            .foregroundStyle(tint)
            .frame(width: 32, height: 32)
    }

    // MARK: - Helpers

    private var bestLabel: String {
        guard summary.gamesPlayed > 0 else { return "—" }
        return "\(summary.bestScore)"
    }

    private func load() async {
        async let summaryFetch = store.summary()
        async let recentFetch = store.history(limit: 25)
        self.summary = await summaryFetch
        self.recent = await recentFetch
        self.isLoading = false
    }
}
