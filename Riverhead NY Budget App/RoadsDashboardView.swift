//
//  RoadsDashboardView.swift
//  Riverhead NY Budget App
//
//  Highway & roads spending dashboard, with a per-maintained-mile comparison
//  against every other town in Suffolk County. Peer figures come from
//  RoadSpendingPeers (State Comptroller filings + NYSDOT mileage), not from
//  separately-scoped town budget documents.
//
//  Swift 6 · iOS 17+
//

import SwiftUI
import Charts

@MainActor
struct RoadsDashboardView: View {

    @Environment(RBBudgetStore.self) private var store
    @Environment(\.colorScheme) private var scheme

    // MARK: - Riverhead road facts

    // NYSDOT's locally maintained centerline mileage — the same basis used for
    // every peer town, so the per-mile figures on this screen are comparable.
    // The Town's own Highway Department page says "approximately 230 miles";
    // that count is not on a stated basis and would make Riverhead look cheaper
    // per mile than a like-for-like comparison supports.
    private var riverheadRoadMiles: Double { RoadSpendingPeers.riverhead.roadMiles }
    private let riverheadLandSqMi:   Double = 67.43

    private struct YearPoint: Identifiable {
        let year: Int
        let value: Double
        var id: Int { year }
    }

    // MARK: - Peer comparison data

    // Peer comparison now comes from RoadSpendingPeers — all ten Suffolk towns on
    // one consistent basis (OSC "Highways" expenditures over NYSDOT locally
    // maintained centerline miles). The previous version compared three towns'
    // adopted-budget appropriations over estimated mileage, which is not
    // like-for-like: adopted highway lines bundle benefits, debt and capital
    // differently by town, and the budget years did not match. It reported
    // Southold near $56,000 per mile against a comparable figure of ~$24,000.
    private struct PeerTown: Identifiable {
        let id = UUID()
        let name: String
        let highwayFundTotal: Double
        let roadMiles: Double
        var color: Color

        var spendPerMile: Double { highwayFundTotal / roadMiles }
    }

    /// Riverhead plus the two nearest East End peers, for the compact card list.
    private var peers: [PeerTown] {
        let featured = ["Riverhead", "Southold", "Southampton"]
        let palette: [String: Color] = [
            "Riverhead": RiverheadTheme.accent,
            "Southold": RiverheadTheme.brandTeal,
            "Southampton": RiverheadTheme.brandGold,
        ]
        return featured.compactMap { name in
            guard let p = RoadSpendingPeers.all.first(where: { $0.name == name }) else { return nil }
            return PeerTown(
                name: p.name,
                highwayFundTotal: p.highwaySpending,
                roadMiles: p.roadMiles,
                color: palette[name] ?? RiverheadTheme.brandTeal
            )
        }
    }

    // MARK: - Store-derived series

    private var highwayFundName: String? {
        store.funds.first(where: {
            $0.localizedCaseInsensitiveContains("DA1") ||
            $0.localizedCaseInsensitiveContains("Highway Fund")
        })
    }

    private var appropriationSeries: [YearPoint] {
        guard let name = highwayFundName else { return [] }
        return store.valueSeries(for: name, metric: .appropriations)
            .map { YearPoint(year: $0.year, value: $0.value) }
    }

    private var levySeries: [YearPoint] {
        guard let name = highwayFundName else { return [] }
        return store.valueSeries(for: name, metric: .taxLevy)
            .map { YearPoint(year: $0.year, value: $0.value) }
    }

    private var latestAppropriation: YearPoint? { appropriationSeries.last }
    private var previousAppropriation: YearPoint? {
        appropriationSeries.dropLast().last
    }

    private var yoyChange: Double? {
        guard let latest = latestAppropriation, let prior = previousAppropriation, prior.value > 0 else { return nil }
        return (latest.value - prior.value) / prior.value * 100
    }

    private var spendPerMile: Double? {
        guard let v = latestAppropriation?.value else { return nil }
        return v / riverheadRoadMiles
    }

    private var highwayShareOfBudget: Double {
        guard let v = latestAppropriation?.value, v > 0 else { return 0 }
        // Highway appropriations as a share of the same year's General Fund appropriations.
        let year = latestAppropriation?.year
        let gf = year.flatMap { BudgetStages.doc($0, .adopted)?.generalFund?.appropriations } ?? 69_113_159
        return v / gf * 100
    }

    // MARK: - Body

    var body: some View {
        List {
            snapshotSection
            trendSection
            peerComparisonSection
            spendPerMileChartSection
            suffolkRankingSection
            roadCaveatsSection
            chipsSection
            notesSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Roads Dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Snapshot section

    private var snapshotSection: some View {
        Section {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                metricTile(
                    title: "Maintained Road Miles",
                    value: String(format: "%.0f", RoadSpendingPeers.riverhead.roadMiles),
                    symbol: "road.lanes",
                    tint: RiverheadTheme.accent
                )
                metricTile(
                    title: "Land Area",
                    value: "67.4 sq mi",
                    symbol: "map.fill",
                    tint: RiverheadTheme.brandTeal
                )
                if let latest = latestAppropriation {
                    metricTile(
                        title: "Highway Fund \(latest.year)",
                        value: shortMoney(latest.value),
                        symbol: "banknote.fill",
                        tint: RiverheadTheme.brandNavy
                    )
                }
                if let perMile = spendPerMile {
                    metricTile(
                        title: "Per Road Mile",
                        value: shortMoney(perMile),
                        symbol: "dollarsign.circle.fill",
                        tint: RiverheadTheme.brandGold
                    )
                }
                if let change = yoyChange {
                    metricTile(
                        title: "YoY Change",
                        value: String(format: "%+.1f%%", change),
                        symbol: change >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                        tint: change >= 0 ? RiverheadTheme.brandCoral : RiverheadTheme.brandMint
                    )
                }
                metricTile(
                    title: "% of Budget",
                    value: String(format: "%.1f%%", highwayShareOfBudget),
                    symbol: "chart.pie.fill",
                    tint: RiverheadTheme.brandSky
                )
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .listRowBackground(Color.clear)
        } header: {
            Label("Riverhead Road Snapshot", systemImage: "road.lanes.curved.right")
        }
    }

    // MARK: - Trend section

    private var trendSection: some View {
        Section {
            if appropriationSeries.isEmpty {
                Text("No Highway Fund series loaded. Open the Budget tab and let data warm up.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Appropriations Trend")
                        .font(.subheadline.weight(.semibold))

                    Chart(appropriationSeries) { point in
                        LineMark(
                            x: .value("Year", point.year),
                            y: .value("Appropriation", point.value)
                        )
                        .foregroundStyle(RiverheadTheme.accent)
                        .symbol(Circle().strokeBorder(lineWidth: 1.5))
                        .symbolSize(30)

                        AreaMark(
                            x: .value("Year", point.year),
                            y: .value("Appropriation", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [RiverheadTheme.accent.opacity(0.22), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .chartYAxis {
                        AxisMarks(format: .currency(code: "USD").precision(.fractionLength(0)).scale(1))
                    }
                    .frame(height: 180)
                    .accessibilityLabel("Highway fund appropriations trend chart")
                }

                if !levySeries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Levy Trend")
                            .font(.subheadline.weight(.semibold))

                        Chart(levySeries) { point in
                            BarMark(
                                x: .value("Year", point.year),
                                y: .value("Levy", point.value)
                            )
                            .foregroundStyle(RiverheadTheme.brandTeal.gradient)
                            .cornerRadius(4)
                        }
                        .chartYAxis {
                            AxisMarks(format: .currency(code: "USD").precision(.fractionLength(0)).scale(1))
                        }
                        .frame(height: 150)
                        .accessibilityLabel("Highway fund tax levy trend chart")
                    }
                }
            }
        } header: {
            Label("Historical Trend", systemImage: "chart.line.uptrend.xyaxis")
        }
    }

    // MARK: - Peer comparison table

    private var peerComparisonSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 0) {
                // Header row
                HStack(spacing: 0) {
                    Text("Town")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Highway $")
                        .frame(width: 84, alignment: .trailing)
                    Text("Road mi")
                        .frame(width: 64, alignment: .trailing)
                    Text("$/mile")
                        .frame(width: 72, alignment: .trailing)
                }
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.vertical, 6)
                .padding(.horizontal, 4)

                Divider()

                ForEach(peers) { town in
                    HStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(town.color)
                                .frame(width: 8, height: 8)
                            Text(town.name)
                                .font(.subheadline.weight(town.name == "Riverhead" ? .semibold : .regular))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(shortMoney(town.highwayFundTotal))
                            .font(.subheadline)
                            .frame(width: 84, alignment: .trailing)

                        Text(String(format: "%.0f", town.roadMiles))
                            .font(.subheadline)
                            .frame(width: 64, alignment: .trailing)

                        Text(shortMoney(town.spendPerMile))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(town.color)
                            .frame(width: 72, alignment: .trailing)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(town.name): highway fund \(shortMoney(town.highwayFundTotal)), \(Int(town.roadMiles)) road miles, \(shortMoney(town.spendPerMile)) per mile")

                    if town.name != peers.last?.name {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            // Source note
            Text(RoadSpendingPeers.sourceNote)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        } header: {
            Label("Peer Comparison", systemImage: "chart.bar.xaxis.ascending")
        } footer: {
            Text("Every Suffolk town files the same annual report to the State Comptroller on the same chart of accounts, so \"Highways\" means the same thing in each. Towns still differ in terrain, road mix and how much work is contracted out, so treat this as context rather than a unit-cost standard.")
        }
    }

    // MARK: - Spend per mile bar chart

    private var spendPerMileChartSection: some View {
        Section {
            Chart(peers) { town in
                BarMark(
                    x: .value("Town", town.name),
                    y: .value("$ per mile", town.spendPerMile)
                )
                .foregroundStyle(town.color.gradient)
                .cornerRadius(6)
                .annotation(position: .top, alignment: .center) {
                    Text(shortMoney(town.spendPerMile))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(format: .currency(code: "USD").precision(.fractionLength(0)).scale(1))
            }
            .frame(height: 200)
            .padding(.vertical, 6)
            .accessibilityLabel("Bar chart comparing highway spending per road mile across Riverhead, Southold and Southampton")
        } header: {
            Label("Highway Spending per Road Mile", systemImage: "dollarsign.lane")
        }
    }

    // MARK: - All ten Suffolk towns, ranked

    // Replaces a "highway fund as % of total budget" chart that compared each
    // town's highway line against its own total budget. Those totals differ
    // wildly in scope (enterprise funds, districts), so the percentages were not
    // comparable. Spend per maintained mile is, and showing all ten towns puts
    // Riverhead's position in context rather than against two hand-picked peers.
    private var suffolkRankingSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(RoadSpendingPeers.all.sorted { $0.spendPerMile > $1.spendPerMile }) { town in
                    let isRiverhead = town.name == RoadSpendingPeers.riverheadName
                    HStack(spacing: 8) {
                        Text(town.name)
                            .font(.caption.weight(isRiverhead ? .bold : .regular))
                            .foregroundStyle(isRiverhead ? RiverheadTheme.accent : .primary)
                            .frame(width: 92, alignment: .leading)

                        GeometryReader { geo in
                            let frac = town.spendPerMile / RoadSpendingPeers.maxSpendPerMile
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isRiverhead ? RiverheadTheme.accent : Color.secondary.opacity(0.35))
                                .frame(width: max(2, geo.size.width * frac), height: 14)
                                .frame(maxHeight: .infinity, alignment: .center)
                        }
                        .frame(height: 16)

                        Text(shortMoney(town.spendPerMile))
                            .font(.caption.weight(isRiverhead ? .bold : .regular))
                            .monospacedDigit()
                            .frame(width: 60, alignment: .trailing)

                        Text("\(Int(town.roadMiles)) mi")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 52, alignment: .trailing)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(town.name): \(shortMoney(town.spendPerMile)) per mile across \(Int(town.roadMiles)) maintained miles")
                }

                Divider().padding(.vertical, 2)

                Text("Median across the ten towns: \(shortMoney(RoadSpendingPeers.medianSpendPerMile)) per mile. Riverhead ranks \(RoadSpendingPeers.riverheadRank) of 10, about \(Int((RoadSpendingPeers.riverheadVsMedian * 100).rounded()))% below it — spending at the median rate across its \(Int(RoadSpendingPeers.riverhead.roadMiles)) miles would cost roughly \(shortMoney(RoadSpendingPeers.gapToMedianAnnual)) more a year.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Label("Every Suffolk Town, FY\(RoadSpendingPeers.fiscalYear)", systemImage: "list.number")
        } footer: {
            Text("Spending less per mile than your neighbours is a question, not a result: it can mean an efficient operation or roads being allowed to degrade. Neither dataset measures pavement condition, and the Town publishes no pavement-condition rating.")
        }
    }

    // MARK: - Limits of the comparison

    private var roadCaveatsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(RoadSpendingPeers.caveats, id: \.self) { c in
                    HStack(alignment: .top, spacing: 6) {
                        Text("\u{2022}").foregroundStyle(.secondary)
                        Text(c).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 2)
        } header: {
            Label("Limits of This Comparison", systemImage: "exclamationmark.triangle")
        }
    }

    // MARK: - CHIPS section

    private var chipsSection: some View {
        Section {
            infoRow(
                symbol: "road.lanes",
                title: "What is CHIPS?",
                detail: "The Consolidated Highway Improvement Program (CHIPS) provides annual state aid to municipalities for highway maintenance. In 2026, the base CHIPS allocation for Suffolk County towns is roughly $750K–$1.5M depending on road miles and a formula factor."
            )
            infoRow(
                symbol: "arrow.up.right.circle",
                title: "CHIPS + PAVE-NY",
                detail: "PAVE-NY provides additional aid above CHIPS for paving. Together they offset a meaningful share of Riverhead's highway operating costs. Residents should ask the Town to publish CHIPS and PAVE-NY receipts alongside the highway fund budget each year."
            )
            infoRow(
                symbol: "exclamationmark.triangle.fill",
                title: "What to watch",
                detail: "Deferred maintenance shows up as rising per-mile cost once roads deteriorate. A healthy highway fund stays structurally balanced — recurring state aid + levy covers recurring maintenance without leaning on fund balance. Check whether the levy trend is outpacing CHIPS growth."
            )
            infoRow(
                symbol: "person.2.wave.2.fill",
                title: "Questions to ask",
                detail: "What was Riverhead's CHIPS and PAVE-NY receipts in the last 3 years? Is the highway fund structurally balanced, or does it rely on appropriated fund balance? How many road miles were paved or repaved last year, and what is the backlog?"
            )
        } header: {
            Label("State Aid & What to Watch", systemImage: "info.circle.fill")
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        Section {
            Text("Highway Fund (DA1) data is sourced from the app's parsed Riverhead adopted budget series. Peer figures are from each town's published adopted budget documents and are used for directional comparison only. Road-mile figures are approximate and based on published highway department and town records. CHIPS and PAVE-NY allocations vary annually.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Sources & Methodology")
        }
    }

    // MARK: - Helpers

    private func metricTile(title: String, value: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(RiverheadTheme.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(RiverheadTheme.Surface.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(tint.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: RiverheadTheme.cardShadow(scheme), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    private func infoRow(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.subheadline)
                .foregroundStyle(RiverheadTheme.accent)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(detail)")
    }

    private func shortMoney(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.0fK", value / 1_000)
        }
        let f = SharedFormatters.currency0
        return f.string(from: NSNumber(value: value)) ?? "$0"
    }
}
