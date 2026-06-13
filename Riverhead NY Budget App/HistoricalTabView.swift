//
//  HistoricalTabView.swift
//  Riverhead NY Budget App
//
//  Swift 6 / iOS 17+
//
//  • Lists Tentative / Preliminary / Adopted / Audit (and Capital if you add it)
//  • Quick filters by type (multi-select menu)
//  • Search by title, type label, or year
//  • "This Year" quick links + grouped history by year
//  • Snapshot section with total docs + span of years
//

import SwiftUI
import Observation
import Charts
#if canImport(UIKit)
import UIKit
#endif

@MainActor
struct HistoricalTabView: View {
    @Environment(RBBudgetStore.self) private var store
    @Environment(\.colorScheme) private var scheme

    @State private var selectedDoc: RiverheadBudgetDoc?
    @State private var searchText: String = ""
    @State private var typeFilters: Set<RiverheadBudgetDoc.DocType> = [] // empty = all
    @State private var historyMetricsReady = false

    // Explicit ordering to avoid relying on allCases sort
    private let docTypesOrdered: [RiverheadBudgetDoc.DocType] = [
        .tentative,
        .preliminary,
        .adopted,
        .capital,
        .audit
    ]

    var body: some View {
        NavigationStack {
            List {
                let allDocs = store.documents
                let filteredDocs = filtered(allDocs)

                if !allDocs.isEmpty {
                    snapshotSection(allDocs: allDocs, filteredDocs: filteredDocs)
                    priorBudgetInsightsSection(allDocs: allDocs, filteredDocs: filteredDocs)
                }

                // This Year quick links (respects filters/search)
                if !store.quickLinks.isEmpty {
                    let quick = filtered(store.quickLinks)
                    if !quick.isEmpty {
                        Section("This Year") {
                            ForEach(quick) { doc in
                                DocRow(doc: doc) { selectedDoc = doc }
                            }
                        }
                    }
                }

                // Grouped history (respects filters/search)
                let groups = groupedByYear(filteredDocs)
                if groups.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No matching documents",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("Try clearing filters or changing your search.")
                        )
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                    }
                } else {
                    ForEach(groups) { group in
                        Section(String(group.year)) {
                            ForEach(group.docs) { doc in
                                DocRow(doc: doc) { selectedDoc = doc }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(RiverheadTheme.Surface.page.ignoresSafeArea())
            .navigationTitle("Budget History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RiverheadTheme.Surface.card, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    filterMenu
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search by title, type, or year"
            )
            .sheet(item: $selectedDoc) { doc in
                WebContentView(url: doc.url)
                    .ignoresSafeArea()
            }
            .task {
                await warmUpHistoryMetrics()
            }
        }
    }

    // MARK: - Snapshot

    private func snapshotSection(
        allDocs: [RiverheadBudgetDoc],
        filteredDocs: [RiverheadBudgetDoc]
    ) -> some View {
        let years = allDocs.map(\.year)
        let minYear = years.min()
        let maxYear = years.max()
        let totalCount = allDocs.count
        let filteredCount = filteredDocs.count

        return Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("Snapshot")
                    .font(.headline)

                if let minYear, let maxYear {
                    Text("Covers budgets from \(minYear)–\(maxYear).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Budget documents loaded.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Label {
                        Text("\(totalCount) total document\(totalCount == 1 ? "" : "s")")
                    } icon: {
                        Image(systemName: "doc.on.doc")
                    }
                    .font(.caption)

                    if filteredCount != totalCount {
                        Label {
                            Text("\(filteredCount) match current filters")
                        } icon: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private func priorBudgetInsightsSection(
        allDocs: [RiverheadBudgetDoc],
        filteredDocs: [RiverheadBudgetDoc]
    ) -> some View {
        Section("Prior Budget Insights") {
            VStack(alignment: .leading, spacing: 14) {
                if historyMetricsReady, !generalFundTrendRows.isEmpty {
                    budgetSignalSummary
                    generalFundTrendGraphic
                    if let latest = latestGeneralFundChange {
                        Divider().opacity(0.25)
                        latestChangeCard(latest)
                    }
                } else {
                    Label("Loading budget trend data...", systemImage: "chart.xyaxis.line")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider().opacity(0.25)
                sourceCoverageNote(allDocs: allDocs, filteredDocs: filteredDocs)
            }
            .padding(.vertical, 4)
        }
    }

    /// X-axis domain pinned to the real year span so the series doesn't collapse
    /// against an auto axis that anchors at 0. Pads a lone year by ±1.
    private var trendYearDomain: ClosedRange<Int> {
        let years = generalFundTrendRows.map(\.year)
        guard let lo = years.min(), let hi = years.max() else { return 2021...2026 }
        return lo == hi ? (lo - 1)...(hi + 1) : lo...hi
    }

    /// One tick per year that actually has data.
    private var trendYearValues: [Int] {
        generalFundTrendRows.map(\.year).sorted()
    }

    private var generalFundTrendGraphic: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("General Fund trend")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Prior budgets + 2026")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.gold)
            }

            Chart {
                ForEach(generalFundTrendRows) { row in
                    if let appropriations = row.appropriations {
                        LineMark(
                            x: .value("Year", row.year),
                            y: .value("Appropriations", appropriations)
                        )
                        .foregroundStyle(RiverheadTheme.accent)
                        .interpolationMethod(.monotone)

                        PointMark(
                            x: .value("Year", row.year),
                            y: .value("Appropriations", appropriations)
                        )
                        .foregroundStyle(RiverheadTheme.accent)
                    }

                    if let levy = row.levy {
                        LineMark(
                            x: .value("Year", row.year),
                            y: .value("Tax levy", levy)
                        )
                        .foregroundStyle(RiverheadTheme.gold)
                        .interpolationMethod(.monotone)

                        PointMark(
                            x: .value("Year", row.year),
                            y: .value("Tax levy", levy)
                        )
                        .foregroundStyle(RiverheadTheme.gold)
                    }
                }
            }
            .chartXScale(domain: trendYearDomain)
            .chartXAxis {
                AxisMarks(values: trendYearValues) { value in
                    AxisGridLine()
                    AxisTick()
                    if let year = value.as(Int.self) {
                        AxisValueLabel { Text(verbatim: String(year)) }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(shortCurrency(amount))
                        }
                    }
                }
            }
            .frame(height: 190)

            HStack(spacing: 12) {
                legendDot(color: RiverheadTheme.accent)
                Text("Appropriations")
                    .font(.caption2)
                legendDot(color: RiverheadTheme.gold)
                Text("Tax levy")
                    .font(.caption2)
                Spacer()
            }
            .foregroundStyle(.secondary)
        }
    }

    private var budgetSignalSummary: some View {
        let latest = latestGeneralFundChange
        let latestRow = generalFundTrendRows.last
        let firstRow = generalFundTrendRows.first

        return VStack(alignment: .leading, spacing: 10) {
            Text("What the history says")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RiverheadTheme.textPrimary)

            Text("This view uses the prior adopted-budget series to show money movement over time. The goal is not to count PDFs; it is to show whether spending and levy pressure are rising, flattening, or diverging.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                insightTile(
                    title: "Latest Spending",
                    value: latestRow?.appropriations.map(shortCurrency) ?? "Not loaded",
                    detail: latest?.appropriationPercent.map { percentText($0) + " YoY" } ?? "No comparison",
                    tint: RiverheadTheme.accent
                )
                insightTile(
                    title: "Latest Levy",
                    value: latestRow?.levy.map(shortCurrency) ?? "Not loaded",
                    detail: latest?.levyPercent.map { percentText($0) + " YoY" } ?? "No comparison",
                    tint: RiverheadTheme.brandGold
                )
                insightTile(
                    title: "Trend Window",
                    value: trendWindowText(first: firstRow, latest: latestRow),
                    detail: "General Fund series",
                    tint: RiverheadTheme.brandTeal
                )
            }
        }
    }

    private func latestChangeCard(_ change: HistoricalBudgetChange) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: "\(change.priorYear) to \(change.year)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            changeRow(
                label: "Appropriations",
                amount: change.appropriationDelta,
                percent: change.appropriationPercent,
                tint: RiverheadTheme.accent
            )
            changeRow(
                label: "Tax levy",
                amount: change.levyDelta,
                percent: change.levyPercent,
                tint: RiverheadTheme.brandGold
            )

            Text(changeInterpretation(change))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.035))
        )
    }

    private func sourceCoverageNote(
        allDocs: [RiverheadBudgetDoc],
        filteredDocs: [RiverheadBudgetDoc]
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Source Coverage", systemImage: "doc.text.magnifyingglass")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RiverheadTheme.accent)

            Text("The document list below remains the source drawer. Filters currently show \(filteredDocs.count) of \(allDocs.count) linked budget documents, but the chart above focuses on dollars instead of PDF counts.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func insightTile(title: String, value: String, detail: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(RiverheadTheme.textPrimary)
                .minimumScaleFactor(0.78)
                .lineLimit(1)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(tint)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
        .padding(10)
        .background(tint.opacity(scheme == .dark ? 0.16 : 0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(tint.opacity(0.22), lineWidth: 0.8)
        )
    }

    private func changeRow(label: String, amount: Double?, percent: Double?, tint: Color) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption.weight(.semibold))
            Spacer()
            Text(deltaText(amount: amount, percent: percent))
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(tint)
        }
    }

    // MARK: - Filter Menu

    private var filterMenu: some View {
        Menu {
            // Toggleable multi-select entries
            ForEach(docTypesOrdered, id: \.self) { t in
                let isOn = typeFilters.contains(t)
                Button {
                    if isOn {
                        typeFilters.remove(t)
                    } else {
                        typeFilters.insert(t)
                    }
                } label: {
                    Label(
                        t.displayName,
                        systemImage: isOn ? "checkmark.circle.fill" : "circle"
                    )
                }
            }

            if !typeFilters.isEmpty {
                Divider()
                Button(role: .destructive) {
                    typeFilters.removeAll()
                } label: {
                    Label("Clear Filters", systemImage: "xmark.circle")
                }
            }
        } label: {
            Image(systemName: typeFilters.isEmpty
                  ? "line.3.horizontal.decrease.circle"
                  : "line.3.horizontal.decrease.circle.fill")
        }
        .tint(RiverheadTheme.accent)
        .accessibilityLabel("Filter by document type")
    }

    // MARK: - Filtering & Grouping

    private func filtered(_ docs: [RiverheadBudgetDoc]) -> [RiverheadBudgetDoc] {
        var out = docs

        // Type filters
        if !typeFilters.isEmpty {
            out = out.filter { typeFilters.contains($0.type) }
        }

        // Search
        let raw = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty {
            let q = raw.lowercased()
            out = out.filter {
                $0.title.lowercased().contains(q) ||
                $0.type.displayName.lowercased().contains(q) ||
                String($0.year).contains(q)
            }
        }

        return out
    }

    private struct YearGroup: Identifiable {
        let year: Int
        let docs: [RiverheadBudgetDoc]
        var id: Int { year }
    }

    private func groupedByYear(_ docs: [RiverheadBudgetDoc]) -> [YearGroup] {
        let dict = Dictionary(grouping: docs, by: { $0.year })
        return dict.keys
            .sorted(by: >)
            .map { year in
                let list = (dict[year] ?? []).sorted { lhs, rhs in
                    if typeOrder(lhs.type) != typeOrder(rhs.type) {
                        return typeOrder(lhs.type) < typeOrder(rhs.type)
                    }
                    return lhs.title < rhs.title
                }
                return YearGroup(year: year, docs: list)
            }
    }

    private var generalFundTrendRows: [HistoricalBudgetTrendRow] {
        guard historyMetricsReady else { return [] }

        let generalFund = store.funds.first {
            $0.localizedCaseInsensitiveContains("General Fund")
        } ?? "A01 • General Fund"

        let levy = Dictionary(uniqueKeysWithValues: store.valueSeries(for: generalFund, metric: .taxLevy).map { ($0.year, $0.value) })
        let appropriations = Dictionary(uniqueKeysWithValues: store.valueSeries(for: generalFund, metric: .appropriations).map { ($0.year, $0.value) })
        let years = Array(Set(levy.keys).union(appropriations.keys)).sorted()

        return years.map { year in
            HistoricalBudgetTrendRow(
                year: year,
                levy: levy[year],
                appropriations: appropriations[year]
            )
        }
    }

    private var latestGeneralFundChange: HistoricalBudgetChange? {
        let rows = generalFundTrendRows
            .filter { $0.levy != nil || $0.appropriations != nil }
            .sorted { $0.year < $1.year }
        guard rows.count >= 2,
              let latest = rows.last,
              let prior = rows.dropLast().last else {
            return nil
        }

        return HistoricalBudgetChange(
            year: latest.year,
            priorYear: prior.year,
            levyDelta: delta(current: latest.levy, prior: prior.levy),
            levyPercent: percentChange(current: latest.levy, prior: prior.levy),
            appropriationDelta: delta(current: latest.appropriations, prior: prior.appropriations),
            appropriationPercent: percentChange(current: latest.appropriations, prior: prior.appropriations)
        )
    }

    private func docTypeCounts(_ docs: [RiverheadBudgetDoc]) -> [HistoricalDocTypeCount] {
        docTypesOrdered.compactMap { type in
            let count = docs.filter { $0.type == type }.count
            guard count > 0 else { return nil }
            return HistoricalDocTypeCount(type: type, count: count)
        }
    }

    private func docYearCounts(_ docs: [RiverheadBudgetDoc]) -> [HistoricalDocYearCount] {
        let grouped = Dictionary(grouping: docs, by: { $0.year })
        return grouped.keys.sorted().map { year in
            HistoricalDocYearCount(year: year, count: grouped[year]?.count ?? 0)
        }
    }

    private func typeOrder(_ t: RiverheadBudgetDoc.DocType) -> Int {
        switch t {
        case .tentative:   return 0
        case .preliminary: return 1
        case .adopted:     return 2
        case .capital:     return 3
        case .audit:       return 4
        }
    }

    private func warmUpHistoryMetrics() async {
        guard !historyMetricsReady else { return }
        await Task.detached(priority: .utility) {
            _ = BudgetHistoryShift.ensureLoaded()
            if Riverhead2026BudgetShift.lastLoadCount == 0 {
                _ = try? Riverhead2026BudgetShift.load()
            }
        }.value
        historyMetricsReady = true
    }

    private func legendDot(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }

    private func shortCurrency(_ value: Double) -> String {
        let sign = value < 0 ? "-" : ""
        let amount = abs(value)
        if amount >= 1_000_000 {
            return "\(sign)$\(String(format: "%.1f", amount / 1_000_000))M"
        }
        if amount >= 1_000 {
            return "\(sign)$\(String(format: "%.0f", amount / 1_000))K"
        }
        return value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private func delta(current: Double?, prior: Double?) -> Double? {
        guard let current, let prior else { return nil }
        return current - prior
    }

    private func percentChange(current: Double?, prior: Double?) -> Double? {
        guard let current, let prior, abs(prior) > 0.001 else { return nil }
        return (current - prior) / prior
    }

    private func percentText(_ value: Double) -> String {
        let sign = value > 0 ? "+" : ""
        return sign + value.formatted(.percent.precision(.fractionLength(1)))
    }

    private func deltaText(amount: Double?, percent: Double?) -> String {
        guard let amount else { return "No comparison" }
        let money = shortCurrency(amount)
        if let percent {
            return "\(money) (\(percentText(percent)))"
        }
        return money
    }

    private func trendWindowText(first: HistoricalBudgetTrendRow?, latest: HistoricalBudgetTrendRow?) -> String {
        guard let first, let latest, first.year != latest.year else { return "Not loaded" }
        return "\(first.year)-\(latest.year)"
    }

    private func changeInterpretation(_ change: HistoricalBudgetChange) -> String {
        guard let appPct = change.appropriationPercent,
              let levyPct = change.levyPercent else {
            return "The latest comparison is incomplete because one of the prior-year values is missing."
        }

        if appPct > levyPct + 0.01 {
            return "Spending grew faster than the levy in this comparison, so residents should ask what non-levy revenue, fund balance, or one-time source filled the gap."
        }
        if levyPct > appPct + 0.01 {
            return "The levy grew faster than spending in this comparison, so residents should ask whether reserves, revenue assumptions, or tax-cap strategy changed."
        }
        return "Spending and levy moved in roughly the same direction, which is easier to explain if the Town also shows service-level and recurring-cost drivers."
    }
}

private struct HistoricalDocTypeCount: Identifiable {
    let type: RiverheadBudgetDoc.DocType
    let count: Int

    var id: RiverheadBudgetDoc.DocType { type }
}

private struct HistoricalDocYearCount: Identifiable {
    let year: Int
    let count: Int

    var id: Int { year }
}

private struct HistoricalBudgetTrendRow: Identifiable {
    let year: Int
    let levy: Double?
    let appropriations: Double?

    var id: Int { year }
}

private struct HistoricalBudgetChange {
    let year: Int
    let priorYear: Int
    let levyDelta: Double?
    let levyPercent: Double?
    let appropriationDelta: Double?
    let appropriationPercent: Double?
}

// MARK: - Row

private struct DocRow: View {
    let doc: RiverheadBudgetDoc
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: doc.type.iconName)
                    .font(.title3)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(doc.title)
                            .font(.body.weight(.semibold))
                            .lineLimit(2)

                        TypeBadge(type: doc.type)
                    }

                    HStack(spacing: 10) {
                        if let p = doc.published {
                            Label {
                                Text(p, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } icon: {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let mb = doc.sizeMB {
                            Label {
                                Text(String(format: "%.1f MB", mb))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } icon: {
                                Image(systemName: "arrow.down.doc")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .foregroundStyle(.secondary)
            }
        }
        .contextMenu {
            ShareLink(item: doc.url) {
                Label("Share Link", systemImage: "square.and.arrow.up")
            }

            Button {
                #if canImport(UIKit)
                UIPasteboard.general.string = doc.url.absoluteString
                #endif
            } label: {
                Label("Copy Link", systemImage: "doc.on.doc")
            }
        }
    }
}

// MARK: - Type Badge

private struct TypeBadge: View {
    let type: RiverheadBudgetDoc.DocType

    var body: some View {
        Text(type.displayName)
            .font(.caption2.weight(.semibold))
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .background(type.badgeFill, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(type.badgeStroke, lineWidth: 0.6)
            )
            .foregroundStyle(type.badgeText)
    }
}

// MARK: - DocType helpers

private extension RiverheadBudgetDoc.DocType {
    var displayName: String {
        switch self {
        case .tentative:   return "Tentative"
        case .preliminary: return "Preliminary"
        case .adopted:     return "Adopted"
        case .capital:     return "Capital"
        case .audit:       return "Audit"
        }
    }

    var iconName: String {
        switch self {
        case .tentative:   return "doc.text"
        case .preliminary: return "doc.text.magnifyingglass"
        case .adopted:     return "checkmark.seal"
        case .capital:     return "building.columns"
        case .audit:       return "doc.text.fill"
        }
    }

    var badgeFill: Color {
        switch self {
        case .tentative:   return .blue.opacity(0.14)
        case .preliminary: return .teal.opacity(0.14)
        case .adopted:     return .green.opacity(0.16)
        case .capital:     return .orange.opacity(0.16)
        case .audit:       return .purple.opacity(0.14)
        }
    }

    var badgeStroke: Color {
        switch self {
        case .tentative:   return .blue.opacity(0.35)
        case .preliminary: return .teal.opacity(0.35)
        case .adopted:     return .green.opacity(0.40)
        case .capital:     return .orange.opacity(0.38)
        case .audit:       return .purple.opacity(0.35)
        }
    }

    var badgeText: Color {
        switch self {
        case .tentative:   return .blue
        case .preliminary: return .teal
        case .adopted:     return .green
        case .capital:     return .orange
        case .audit:       return .purple
        }
    }
}

// MARK: - Preview

#Preview {
    HistoricalTabView()
        .environment(RBBudgetStore())
}
