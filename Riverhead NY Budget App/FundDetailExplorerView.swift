//
//  FundDetailExplorerView.swift
//  Riverhead NY Budget App
//
//  FIX: Adds a real entry point for FundDetailView by letting users pick a fund.
//  - Uses RBBudgetStore.funds (display names like "A01 • General Fund").
//  - Shows quick 2026 snapshots (Tax Levy + Appropriations) when available.
//  - Supports search + favorites.
//
//  SwiftUI • iOS 17+
//

import SwiftUI

@MainActor
struct FundDetailExplorerView: View {

    @Environment(RBBudgetStore.self) private var store
    @Environment(\.colorScheme) private var scheme

    @State private var query: String = ""
    @State private var showFavoritesOnly: Bool = false

    /// Stored as "A01 • General Fund|ES1 • Riverhead Sewer District|..."
    @AppStorage("rb_fund_favorites_v1") private var favoritesCSV: String = ""

    var body: some View {
        List {
            Section {
                Toggle("Favorites only", isOn: $showFavoritesOnly)
            }

            if filteredFunds.isEmpty {
                ContentUnavailableView(
                    "No matching funds",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different search or turn off Favorites only.")
                )
                .listRowBackground(Color.clear)
            } else {
                Section("Funds") {
                    ForEach(filteredFunds, id: \.self) { fund in
                        NavigationLink {
                            FundDetailView(fund: fund)
                        } label: {
                            FundExplorerRow(
                                fund: fund,
                                levy2026: valueFor2026(fund: fund, metric: .taxLevy),
                                app2026: valueFor2026(fund: fund, metric: .appropriations),
                                isFavorite: favoriteSet().contains(fund),
                                toggleFavorite: { toggleFavorite(fund) }
                            )
                        }
                    }
                }
            }

            Section {
                Text("Tip: The detailed view anchors 2026 to the Town’s summary table (CSV) and pulls prior years from the historical shift dataset.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search funds")
        .navigationTitle("Fund Detail Explorer")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await warmUpIfNeeded()
        }
        .background(
            (scheme == .dark ? Color.black : RiverheadTheme.Surface.page)
                .ignoresSafeArea()
        )
    }

    // MARK: - Filtering

    private var filteredFunds: [String] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let favs = favoriteSet()

        let base = store.funds.filter { fund in
            guard !showFavoritesOnly || favs.contains(fund) else { return false }
            guard !q.isEmpty else { return true }
            return fund.lowercased().contains(q)
        }

        return base
    }

    // MARK: - Favorites

    private func favoriteSet() -> Set<String> {
        let parts = favoritesCSV
            .split(separator: "|")
            .map { String($0) }
            .filter { !$0.isEmpty }
        return Set(parts)
    }

    private func saveFavoriteSet(_ set: Set<String>) {
        favoritesCSV = set.sorted().joined(separator: "|")
    }

    private func toggleFavorite(_ fund: String) {
        var set = favoriteSet()
        if set.contains(fund) { set.remove(fund) }
        else { set.insert(fund) }
        saveFavoriteSet(set)
    }

    // MARK: - 2026 Snapshot Helpers

    private func valueFor2026(fund: String, metric: RBBudgetMetric) -> Double? {
        let series = store.valueSeries(for: fund, metric: metric)
        return series.first(where: { $0.year == 2026 })?.value
    }

    // MARK: - Warm-up

    private func warmUpIfNeeded() async {
        // If the app already warmed up in MainTabView, this will be a quick no-op.
        await Task(priority: .utility) {
            _ = BudgetHistoryShift.ensureLoaded()
            if Riverhead2026BudgetShift.lastLoadCount == 0 {
                _ = try? Riverhead2026BudgetShift.load()
            }
        }.value
    }
}

// MARK: - Row

private struct FundExplorerRow: View {

    let fund: String
    let levy2026: Double?
    let app2026: Double?
    let isFavorite: Bool
    let toggleFavorite: () -> Void

    @Environment(\.colorScheme) private var scheme

    private let nfMoney0: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.maximumFractionDigits = 0
        return nf
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(fund)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)

                HStack(spacing: 12) {
                    snapshot(label: "Levy 2026", value: levy2026)
                    snapshot(label: "App 2026", value: app2026)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: toggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? RiverheadTheme.accent : .secondary)
                    .imageScale(.medium)
                    .padding(.top, 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func snapshot(label: String, value: Double?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(valueString(value))
                .font(.caption.monospacedDigit())
                .foregroundStyle(RiverheadTheme.textSecondary)
        }
    }

    private func valueString(_ v: Double?) -> String {
        guard let v else { return "—" }
        return nfMoney0.string(from: v as NSNumber) ?? String(format: "%.0f", v)
    }
}

#Preview {
    NavigationStack {
        FundDetailExplorerView()
            .environment(RBBudgetStore())
    }
}
