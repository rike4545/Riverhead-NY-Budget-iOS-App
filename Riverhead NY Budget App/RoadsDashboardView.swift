import SwiftUI
import Charts

@MainActor
struct RoadsDashboardView: View {
    @Environment(RBBudgetStore.self) private var store

    private let maintainedRoadMiles: Double = 230
    private let landAreaSquareMiles: Double = 67.43

    private struct YearPoint: Identifiable {
        let year: Int
        let value: Double
        var id: Int { year }
    }

    private var highwayFundName: String? {
        store.funds.first(where: { $0.localizedCaseInsensitiveContains("DA1") || $0.localizedCaseInsensitiveContains("Highway Fund") })
    }

    private var appropriationSeries: [YearPoint] {
        guard let highwayFundName else { return [] }
        return store.valueSeries(for: highwayFundName, metric: .appropriations).map { YearPoint(year: $0.year, value: $0.value) }
    }

    private var levySeries: [YearPoint] {
        guard let highwayFundName else { return [] }
        return store.valueSeries(for: highwayFundName, metric: .taxLevy).map { YearPoint(year: $0.year, value: $0.value) }
    }

    private var latestAppropriation: YearPoint? { appropriationSeries.last }

    private var spendPerRoadMile: Double? {
        guard let latest = latestAppropriation else { return nil }
        return latest.value / maintainedRoadMiles
    }

    private var spendPerLandSqMile: Double? {
        guard let latest = latestAppropriation else { return nil }
        return latest.value / landAreaSquareMiles
    }

    var body: some View {
        List {
            Section("Road System Snapshot") {
                statRow("Maintained Road Miles", value: "230")
                statRow("Land Area", value: "67.43 sq mi")

                if let latest = latestAppropriation,
                   let perMile = spendPerRoadMile,
                   let perLand = spendPerLandSqMile {
                    statRow("Highway Fund Appropriation (\(latest.year))", value: formatCurrency(latest.value))
                    statRow("Approx Spend per Road Mile", value: formatCurrency(perMile))
                    statRow("Approx Spend per Land Sq Mi", value: formatCurrency(perLand))
                }
            }

            Section("Highway Appropriations Trend") {
                if appropriationSeries.isEmpty {
                    Text("No Highway Fund series available.")
                        .foregroundStyle(.secondary)
                } else {
                    Chart(appropriationSeries) { point in
                        LineMark(
                            x: .value("Year", point.year),
                            y: .value("Appropriation", point.value)
                        )
                        .foregroundStyle(RiverheadTheme.accent)

                        AreaMark(
                            x: .value("Year", point.year),
                            y: .value("Appropriation", point.value)
                        )
                        .foregroundStyle(RiverheadTheme.accent.opacity(0.15))
                    }
                    .frame(height: 190)
                }
            }

            Section("Highway Levy Trend") {
                if levySeries.isEmpty {
                    Text("No Highway levy series available.")
                        .foregroundStyle(.secondary)
                } else {
                    Chart(levySeries) { point in
                        BarMark(
                            x: .value("Year", point.year),
                            y: .value("Levy", point.value)
                        )
                        .foregroundStyle(.teal)
                    }
                    .frame(height: 190)
                }
            }

            Section("Interpretation") {
                Text("Spend per road mile is a rough directional metric. It combines plowing, paving, drainage, equipment, labor, and overhead in the Highway Fund. Use it to spot trend shifts year-over-year, not as a unit-cost bid price.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Roads Dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer(minLength: 8)
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(RiverheadTheme.accent)
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "$0"
    }
}
