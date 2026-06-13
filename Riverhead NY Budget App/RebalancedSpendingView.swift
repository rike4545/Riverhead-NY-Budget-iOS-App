import SwiftUI
import Charts

@MainActor
struct RebalancedSpendingView: View {
    @State private var selectedDirection: RebalancedFilter = .all

    private var items: [RebalanceRecommendation] {
        DepartmentBudgetLensData.rebalancedSpending
            .filter { selectedDirection.matches($0.direction) }
            .sorted { abs($0.change) > abs($1.change) }
    }

    private var tightenCount: Int {
        DepartmentBudgetLensData.rebalancedSpending.filter { $0.direction == .tighten }.count
    }

    private var strengthenCount: Int {
        DepartmentBudgetLensData.rebalancedSpending.filter { $0.direction == .strengthen }.count
    }

    private var tightenShift: Double {
        DepartmentBudgetLensData.rebalancedSpending
            .filter { $0.direction == .tighten }
            .reduce(0) { $0 + max($1.change, 0) }
    }

    private var strengthenShift: Double {
        abs(
            DepartmentBudgetLensData.rebalancedSpending
                .filter { $0.direction == .strengthen }
                .reduce(0) { $0 + min($1.change, 0) }
        )
    }

    private var directionChartData: [RebalanceDirectionSlice] {
        [
            .init(direction: .tighten, count: tightenCount),
            .init(direction: .strengthen, count: strengthenCount)
        ]
    }

    private var topMovers: [RebalanceRecommendation] {
        Array(items.prefix(6))
    }

    var body: some View {
        List {
            Section {
                Picker("Direction", selection: $selectedDirection) {
                    ForEach(RebalancedFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)

                Text("This view is a practical rebalancing lens, not an audit accusation. It surfaces the accounts that moved the most, look unusually stretched, or appear too lean for the service goals the Town is describing.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Quick Read") {
                quickReadRow("Tighten list", value: "\(tightenCount) accounts", tint: .orange)
                quickReadRow("Strengthen list", value: "\(strengthenCount) accounts", tint: .teal)
                quickReadRow("Largest upward watch list", value: tightenShift.formatted(.currency(code: "USD")), tint: .red)
            }

            Section("Visual Summary") {
                rebalanceInfographic
                topMoverChart
            }

            Section("Rebalanced Spending Accounts") {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.account)
                                    .font(.headline)
                                Text(item.fundFunction)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 12)
                            Text(item.direction.rawValue)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(color(for: item.direction))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(color(for: item.direction).opacity(0.12))
                                .clipShape(Capsule())
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("2025")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(item.adopted2025, format: .currency(code: "USD"))
                                    .font(.subheadline.weight(.semibold))
                            }
                            Spacer()
                            VStack(alignment: .center, spacing: 2) {
                                Text("Change")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(primaryChangeText(for: item))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(item.change >= 0 ? .orange : .green)
                                if let changeLabel = item.changeLabel, abs(item.change) >= 0.5 {
                                    Text(changeLabel)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(color(for: item.direction))
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("2026")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(item.adopted2026, format: .currency(code: "USD"))
                                    .font(.subheadline.weight(.semibold))
                            }
                        }

                        Text(item.rationale)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Rebalanced Spending")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func quickReadRow(_ title: String, value: String, tint: Color) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(tint)
        }
    }

    private func color(for direction: RebalanceDirection) -> Color {
        switch direction {
        case .tighten: return .orange
        case .strengthen: return .teal
        }
    }

    private func primaryChangeText(for item: RebalanceRecommendation) -> String {
        if abs(item.change) < 0.5, let changeLabel = item.changeLabel {
            return changeLabel
        }

        return item.change.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private func chartAnnotation(for item: RebalanceRecommendation) -> String {
        if abs(item.change) < 0.5, let changeLabel = item.changeLabel {
            return changeLabel
        }

        return item.change.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private var rebalanceInfographic: some View {
        HStack(spacing: 14) {
            Chart(directionChartData) { slice in
                SectorMark(
                    angle: .value("Accounts", slice.count),
                    innerRadius: .ratio(0.56),
                    angularInset: 2
                )
                .foregroundStyle(color(for: slice.direction))
                .accessibilityLabel("\(slice.direction.rawValue), \(slice.count) accounts")
            }
            .chartLegend(.hidden)
            .frame(width: 112, height: 112)

            VStack(alignment: .leading, spacing: 10) {
                infographicRow(
                    title: "Tighten",
                    value: "\(tightenCount) accounts",
                    detail: tightenShift.formatted(.currency(code: "USD")),
                    tint: .orange,
                    systemImage: "slider.horizontal.3"
                )

                infographicRow(
                    title: "Strengthen",
                    value: "\(strengthenCount) accounts",
                    detail: strengthenShift.formatted(.currency(code: "USD")),
                    tint: .teal,
                    systemImage: "plus.forwardslash.minus"
                )
            }
        }
        .padding(.vertical, 4)
    }

    private var topMoverChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Largest 2026 movement")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(topMovers) { item in
                BarMark(
                    x: .value("Change", abs(item.change)),
                    y: .value("Account", item.account)
                )
                .foregroundStyle(color(for: item.direction))
                .annotation(position: .trailing) {
                    Text(chartAnnotation(for: item))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .accessibilityLabel("\(item.account), changed \(item.change.formatted(.currency(code: "USD")))")
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: CGFloat(max(topMovers.count, 3) * 28))
        }
    }

    private func infographicRow(title: String, value: String, detail: String, tint: Color, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct RebalanceDirectionSlice: Identifiable {
    let direction: RebalanceDirection
    let count: Int

    var id: RebalanceDirection { direction }
}

private enum RebalancedFilter: String, CaseIterable, Identifiable {
    case all
    case tighten
    case strengthen

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .tighten: return "Tighten"
        case .strengthen: return "Strengthen"
        }
    }

    func matches(_ direction: RebalanceDirection) -> Bool {
        switch self {
        case .all: return true
        case .tighten: return direction == .tighten
        case .strengthen: return direction == .strengthen
        }
    }
}
