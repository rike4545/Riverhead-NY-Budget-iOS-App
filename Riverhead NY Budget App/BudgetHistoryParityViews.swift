//
//  BudgetHistoryParityViews.swift
//  Riverhead NY Budget App
//
//  Native SwiftUI counterparts for two Riverhead Budget Live history routes:
//    • /compare/       — adopted fund appropriations, 2020–2026
//    • /general-fund/  — long-run General Fund adopted-budget history
//
//  The web app's normalized JSON is the canonical source. These views fetch the
//  same published files used by Next.js rather than re-implementing the ETL in
//  Swift. URLCache is allowed to retain successful responses for repeat/offline
//  use; Compare also has a best-effort fallback to the app's existing store.
//

import SwiftUI
import Charts
import Foundation

// MARK: - Canonical web data contracts

private struct BudgetHistoryParityDocument: Decodable, Sendable {
    struct Source: Decodable, Sendable {
        let title: String
        let url: String
    }

    struct TownTotal: Decodable, Sendable {
        let appropriations: Double
        let fundCount: Int
    }

    struct FundYearValue: Decodable, Sendable {
        let appropriations: Double
    }

    struct Fund: Decodable, Identifiable, Sendable {
        let code: String
        let name: String
        let years: [String: FundYearValue]
        let firstYear: Int
        let lastYear: Int
        let totalChange: Double
        let totalChangePct: Double?

        var id: String { code }
    }

    let source: Source
    let note: String
    let years: [Int]
    let townTotals: [String: TownTotal]
    let funds: [Fund]
}

private struct GeneralFundParityDocument: Decodable, Sendable {
    struct Source: Decodable, Sendable {
        let title: String
        let url: String
    }

    struct Growth: Decodable, Sendable {
        let firstYear: Int
        let lastYear: Int
        let appropriationsChangePct: Double?
        let taxLevyChangePct: Double?
    }

    struct Row: Decodable, Identifiable, Sendable {
        let year: Int
        let appropriations: Double?
        let estimatedRevenues: Double?
        let appropriatedFundBalance: Double?
        let taxLevy: Double?
        let source: String
        let status: String

        var id: Int { year }
    }

    let source: Source
    let note: String
    let growth: Growth
    let rows: [Row]
}

private enum BudgetHistoryParityClient {
    private static let pagesRoot = "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/data/history"
    private static let rawRoot = "https://raw.githubusercontent.com/rike4545/Riverhead-NY-Budget-Web-App/main/web/public/data/history"

    static func loadBudgetHistory() async throws -> BudgetHistoryParityDocument {
        try await load(BudgetHistoryParityDocument.self, filename: "fund-appropriations.json")
    }

    static func loadGeneralFund() async throws -> GeneralFundParityDocument {
        try await load(GeneralFundParityDocument.self, filename: "general-fund.json")
    }

    private static func load<T: Decodable & Sendable>(_ type: T.Type, filename: String) async throws -> T {
        let candidates = [pagesRoot, rawRoot].compactMap { URL(string: "\($0)/\(filename)") }
        var lastError: Error?

        for url in candidates {
            do {
                var request = URLRequest(url: url)
                request.cachePolicy = .returnCacheDataElseLoad
                request.timeoutInterval = 20

                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      (200..<300).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }

                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                lastError = error
            }
        }

        throw lastError ?? URLError(.cannotLoadFromNetwork)
    }
}

// MARK: - Budget Compare

private enum BudgetCompareSort: String, CaseIterable, Identifiable {
    case dollars = "Biggest $ change"
    case percent = "Biggest % change"
    case name = "Fund name"

    var id: String { rawValue }
}

private struct BudgetCompareParityRow: Identifiable {
    let fund: BudgetHistoryParityDocument.Fund
    let fromValue: Double?
    let toValue: Double?

    var id: String { fund.code }

    var delta: Double? {
        guard let fromValue, let toValue else { return nil }
        return toValue - fromValue
    }

    var percent: Double? {
        guard let fromValue, let delta, abs(fromValue) > 0.001 else { return nil }
        return (delta / fromValue) * 100
    }
}

@MainActor
struct NativeBudgetCompareView: View {
    @Environment(RBBudgetStore.self) private var store

    @State private var document: BudgetHistoryParityDocument?
    @State private var fromYear = 2025
    @State private var toYear = 2026
    @State private var sortMode: BudgetCompareSort = .dollars
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var didLoad = false

    var body: some View {
        Group {
            if let document {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        summaryCard(document)
                        controlsCard(document)
                        comparisonRows(document)
                        sourceCard(document)
                    }
                    .padding(16)
                }
                .background(RiverheadTheme.Surface.page.ignoresSafeArea())
            } else if isLoading {
                ProgressView("Loading budget history…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "Budget history unavailable",
                    systemImage: "chart.bar.doc.horizontal",
                    description: Text(loadError ?? "The canonical budget-history dataset could not be loaded.")
                )
            }
        }
        .navigationTitle("Budget Compare")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search funds")
        .task { await loadIfNeeded() }
        .refreshable { await load(force: true) }
    }

    private func summaryCard(_ document: BudgetHistoryParityDocument) -> some View {
        let from = document.townTotals[String(fromYear)]?.appropriations
        let to = document.townTotals[String(toYear)]?.appropriations
        let delta = pairedDelta(from: from, to: to)
        let pct = pairedPercent(from: from, to: to)

        return VStack(alignment: .leading, spacing: 10) {
            Text("What changed in Riverhead's budget?")
                .font(.title2.bold())
                .foregroundStyle(RiverheadTheme.textPrimary)

            Text("Compare adopted appropriations across every Town fund using the same 2020–2026 history dataset as Riverhead Budget Live.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let delta {
                Text("Town-wide planned spending \(delta >= 0 ? "increased" : "decreased") \(money(delta)) from \(fromYear) to \(toYear).")
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.textPrimary)

                if let pct {
                    Text("\(signedPercent(pct)) overall. Appropriations are planned spending; this is not the same thing as a property-tax increase.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .parityCard()
    }

    private func controlsCard(_ document: BudgetHistoryParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comparison")
                .font(.headline)

            HStack(spacing: 12) {
                yearPicker("From", selection: $fromYear, years: document.years)
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                yearPicker("To", selection: $toYear, years: document.years)
            }

            Picker("Sort", selection: $sortMode) {
                ForEach(BudgetCompareSort.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .parityCard()
    }

    private func yearPicker(_ label: String, selection: Binding<Int>, years: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Picker(label, selection: selection) {
                ForEach(years, id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func comparisonRows(_ document: BudgetHistoryParityDocument) -> some View {
        let rows = sortedRows(document)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Funds")
                    .font(.headline)
                Spacer()
                Text("\(rows.count) shown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if rows.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                ForEach(rows) { row in
                    NavigationLink {
                        FundDetailView(fund: "\(row.fund.code) • \(row.fund.name)")
                    } label: {
                        comparisonRow(row)
                    }
                    .buttonStyle(.plain)

                    if row.id != rows.last?.id {
                        Divider().opacity(0.35)
                    }
                }
            }
        }
        .parityCard()
    }

    private func comparisonRow(_ row: BudgetCompareParityRow) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(row.fund.code) • \(row.fund.name)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 12) {
                valueBlock(label: String(fromYear), value: row.fromValue)
                valueBlock(label: String(toYear), value: row.toValue)
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(row.delta.map(signedMoney) ?? "—")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(deltaColor(row.delta))
                    Text(row.percent.map(signedPercent) ?? "—")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }

    private func valueBlock(label: String, value: Double?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value.map(moneyShort) ?? "—")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(RiverheadTheme.textPrimary)
        }
    }

    private func sourceCard(_ document: BudgetHistoryParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Source", systemImage: "checkmark.seal.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(RiverheadTheme.accent)
            Text(document.source.title)
                .font(.caption.weight(.semibold))
            Text(document.note)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("The native view reads the same normalized JSON consumed by the web app. Pull to refresh for the newest published version.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .parityCard()
    }

    /// Orders by descending magnitude, keeping funds with no comparable value
    /// last. Coalescing a missing value to `-.infinity` and then taking `abs`
    /// turns it into `+.infinity`, which sorted every incomplete row — the ones
    /// that render "—" — ahead of the largest real change under both magnitude
    /// sorts. A fund with only part of its history is not the biggest mover.
    private func byDescendingMagnitude(_ lhs: Double?, _ rhs: Double?) -> Bool {
        switch (lhs, rhs) {
        case let (lhs?, rhs?): return abs(lhs) > abs(rhs)
        case (_?, nil): return true
        case (nil, _?), (nil, nil): return false
        }
    }

    private func sortedRows(_ document: BudgetHistoryParityDocument) -> [BudgetCompareParityRow] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        var rows = document.funds.map { fund in
            BudgetCompareParityRow(
                fund: fund,
                fromValue: fund.years[String(fromYear)]?.appropriations,
                toValue: fund.years[String(toYear)]?.appropriations
            )
        }

        if !q.isEmpty {
            rows = rows.filter {
                $0.fund.code.localizedCaseInsensitiveContains(q)
                || $0.fund.name.localizedCaseInsensitiveContains(q)
            }
        }

        switch sortMode {
        case .dollars:
            rows.sort { byDescendingMagnitude($0.delta, $1.delta) }
        case .percent:
            rows.sort { byDescendingMagnitude($0.percent, $1.percent) }
        case .name:
            rows.sort { $0.fund.name.localizedCaseInsensitiveCompare($1.fund.name) == .orderedAscending }
        }

        return rows
    }

    private func loadIfNeeded() async {
        guard !didLoad else { return }
        await load(force: false)
    }

    private func load(force: Bool) async {
        if isLoading { return }
        if didLoad && !force { return }

        isLoading = true
        loadError = nil

        do {
            let loaded = try await BudgetHistoryParityClient.loadBudgetHistory()
            document = loaded
            let years = loaded.years.sorted()
            if let latest = years.last {
                toYear = latest
                fromYear = years.dropLast().last ?? latest
            }
            didLoad = true
        } catch {
            if let fallback = localFallbackDocument() {
                document = fallback
                let years = fallback.years.sorted()
                if let latest = years.last {
                    toYear = latest
                    fromYear = years.dropLast().last ?? latest
                }
                loadError = "Live web history could not be refreshed; showing the app's bundled historical series."
                didLoad = true
            } else {
                loadError = error.localizedDescription
            }
        }

        isLoading = false
    }

    private func localFallbackDocument() -> BudgetHistoryParityDocument? {
        let funds: [BudgetHistoryParityDocument.Fund] = store.funds.compactMap { display in
            let parts = display.components(separatedBy: " • ")
            guard parts.count >= 2 else { return nil }
            let code = parts[0]
            let name = parts.dropFirst().joined(separator: " • ")
            let series = store.valueSeries(for: display, metric: .appropriations)
            guard !series.isEmpty else { return nil }

            let values = Dictionary(uniqueKeysWithValues: series.map {
                (String($0.year), BudgetHistoryParityDocument.FundYearValue(appropriations: $0.value))
            })
            let years = series.map(\.year).sorted()
            guard let first = years.first, let last = years.last,
                  let firstValue = values[String(first)]?.appropriations,
                  let lastValue = values[String(last)]?.appropriations else { return nil }
            let delta = lastValue - firstValue
            let pct = abs(firstValue) > 0.001 ? (delta / firstValue) * 100 : nil

            return .init(
                code: code,
                name: name,
                years: values,
                firstYear: first,
                lastYear: last,
                totalChange: delta,
                totalChangePct: pct
            )
        }

        guard !funds.isEmpty else { return nil }
        let years = Array(Set(funds.flatMap { $0.years.keys.compactMap(Int.init) })).sorted()
        let totals = Dictionary(uniqueKeysWithValues: years.map { year in
            let total = funds.compactMap { $0.years[String(year)]?.appropriations }.reduce(0, +)
            let count = funds.filter { $0.years[String(year)] != nil }.count
            return (String(year), BudgetHistoryParityDocument.TownTotal(appropriations: total, fundCount: count))
        })

        return .init(
            source: .init(title: "Bundled iOS budget history", url: ""),
            note: "Best-effort offline fallback from the app's existing fund series. Refresh when online for the canonical web ETL dataset.",
            years: years,
            townTotals: totals,
            funds: funds
        )
    }

    private func pairedDelta(from: Double?, to: Double?) -> Double? {
        guard let from, let to else { return nil }
        return to - from
    }

    private func pairedPercent(from: Double?, to: Double?) -> Double? {
        guard let from, let delta = pairedDelta(from: from, to: to), abs(from) > 0.001 else { return nil }
        return (delta / from) * 100
    }
}

// MARK: - General Fund long-run history

@MainActor
struct NativeGeneralFundHistoryView: View {
    @State private var document: GeneralFundParityDocument?
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var didLoad = false

    var body: some View {
        Group {
            if let document {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        generalFundSummary(document)
                        generalFundChart(document)
                        generalFundRows(document)
                        generalFundSource(document)
                    }
                    .padding(16)
                }
                .background(RiverheadTheme.Surface.page.ignoresSafeArea())
            } else if isLoading {
                ProgressView("Loading General Fund history…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "General Fund history unavailable",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text(loadError ?? "The canonical General Fund dataset could not be loaded.")
                )
            }
        }
        .navigationTitle("General Fund")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadIfNeeded() }
        .refreshable { await load(force: true) }
    }

    private func generalFundSummary(_ document: GeneralFundParityDocument) -> some View {
        let rows = document.rows
        let first = rows.first
        let last = rows.last

        return VStack(alignment: .leading, spacing: 12) {
            Text("General Fund — 20-Year History")
                .font(.title2.bold())
                .foregroundStyle(RiverheadTheme.textPrimary)

            Text("Adopted spending, tax levy, estimated revenues, and reserve use from the Town's principal operating fund.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 10)], spacing: 10) {
                parityStat("Appropriations \(document.growth.firstYear)", first?.appropriations.map(money) ?? "—")
                parityStat("Appropriations \(document.growth.lastYear)", last?.appropriations.map(money) ?? "—")
                parityStat("Appropriations Growth", document.growth.appropriationsChangePct.map { "+\(String(format: "%.1f", $0))%" } ?? "—")
                parityStat("Tax Levy Growth", document.growth.taxLevyChangePct.map { "+\(String(format: "%.1f", $0))%" } ?? "—")
            }
        }
        .parityCard()
    }

    private func generalFundChart(_ document: GeneralFundParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("General Fund, \(document.growth.firstYear)–\(document.growth.lastYear)")
                .font(.headline)

            Text("Where the tax-levy line climbs faster than appropriations, a larger share of the budget is being carried by property taxes rather than fees, aid, and other revenue.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart {
                ForEach(document.rows) { row in
                    if let value = row.appropriations {
                        LineMark(x: .value("Year", row.year), y: .value("Appropriations", value))
                            .foregroundStyle(RiverheadTheme.accent)
                            .interpolationMethod(.monotone)
                    }
                    if let value = row.taxLevy {
                        LineMark(x: .value("Year", row.year), y: .value("Tax Levy", value))
                            .foregroundStyle(RiverheadTheme.brandGold)
                            .interpolationMethod(.monotone)
                    }
                    if let value = row.estimatedRevenues {
                        LineMark(x: .value("Year", row.year), y: .value("Estimated Revenues", value))
                            .foregroundStyle(RiverheadTheme.brandTeal)
                            .interpolationMethod(.monotone)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let number = value.as(Double.self) {
                            Text(moneyShort(number))
                        }
                    }
                }
            }
            .frame(height: 290)

            HStack(spacing: 14) {
                parityLegend(RiverheadTheme.accent, "Appropriations")
                parityLegend(RiverheadTheme.brandGold, "Tax levy")
                parityLegend(RiverheadTheme.brandTeal, "Revenues")
            }
        }
        .parityCard()
    }

    private func generalFundRows(_ document: GeneralFundParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Year-by-year detail")
                .font(.headline)

            ForEach(Array(document.rows.enumerated()), id: \.element.id) { index, row in
                DisclosureGroup {
                    VStack(spacing: 7) {
                        parityKeyValue("Estimated revenues", row.estimatedRevenues.map(money) ?? "—")
                        parityKeyValue("Fund balance used", row.appropriatedFundBalance.map(money) ?? "—")
                        parityKeyValue("Source", row.source)
                        parityKeyValue("Status", row.status)
                    }
                    .padding(.top, 8)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(String(row.year))
                            .font(.subheadline.bold())
                            .frame(width: 46, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Appropriations \(row.appropriations.map(moneyShort) ?? "—")")
                                .font(.caption.weight(.semibold))
                            Text("Tax levy \(row.taxLevy.map(moneyShort) ?? "—")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(levyYoYText(rows: document.rows, index: index))
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(levyYoYColor(rows: document.rows, index: index))
                    }
                }

                if index != document.rows.indices.last {
                    Divider().opacity(0.35)
                }
            }
        }
        .parityCard()
    }

    private func generalFundSource(_ document: GeneralFundParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Source", systemImage: "doc.text.magnifyingglass")
                .font(.caption.weight(.bold))
                .foregroundStyle(RiverheadTheme.accent)
            Text(document.source.title)
                .font(.caption.weight(.semibold))
            Text(document.note)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("These are adopted budget figures, not year-end actuals. Gap years reflect years not exposed in the current parsed web dataset.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .parityCard()
    }

    private func parityStat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(RiverheadTheme.textPrimary)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .padding(10)
        .background(RiverheadTheme.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func parityLegend(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption2)
        }
        .foregroundStyle(.secondary)
    }

    private func parityKeyValue(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(key)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(RiverheadTheme.textPrimary)
        }
        .font(.caption)
    }

    private func levyYoYText(rows: [GeneralFundParityDocument.Row], index: Int) -> String {
        guard index > 0,
              let current = rows[index].taxLevy,
              let previous = rows[index - 1].taxLevy,
              abs(previous) > 0.001 else { return "—" }
        return signedPercent(((current - previous) / previous) * 100)
    }

    private func levyYoYColor(rows: [GeneralFundParityDocument.Row], index: Int) -> Color {
        guard index > 0,
              let current = rows[index].taxLevy,
              let previous = rows[index - 1].taxLevy else { return .secondary }
        return current > previous ? .orange : (current < previous ? .green : .secondary)
    }

    private func loadIfNeeded() async {
        guard !didLoad else { return }
        await load(force: false)
    }

    private func load(force: Bool) async {
        if isLoading { return }
        if didLoad && !force { return }

        isLoading = true
        loadError = nil

        do {
            document = try await BudgetHistoryParityClient.loadGeneralFund()
            didLoad = true
        } catch {
            loadError = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Shared native parity styling / formatting

private extension View {
    func parityCard() -> some View {
        self
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(RiverheadTheme.border.opacity(0.35), lineWidth: 0.8)
            )
    }
}

private func money(_ value: Double) -> String {
    value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
}

private func moneyShort(_ value: Double) -> String {
    let sign = value < 0 ? "-" : ""
    let amount = abs(value)
    if amount >= 1_000_000_000 {
        return "\(sign)$\(String(format: "%.1f", amount / 1_000_000_000))B"
    }
    if amount >= 1_000_000 {
        return "\(sign)$\(String(format: amount < 10_000_000 ? "%.2f" : "%.1f", amount / 1_000_000))M"
    }
    if amount >= 10_000 {
        return "\(sign)$\(String(format: "%.0f", amount / 1_000))K"
    }
    return money(value)
}

private func signedMoney(_ value: Double) -> String {
    let prefix = value > 0 ? "+" : ""
    return prefix + moneyShort(value)
}

private func signedPercent(_ value: Double) -> String {
    let prefix = value > 0 ? "+" : ""
    return prefix + String(format: "%.1f%%", value)
}

private func deltaColor(_ value: Double?) -> Color {
    guard let value else { return .secondary }
    if value > 0 { return .orange }
    if value < 0 { return .green }
    return .secondary
}
