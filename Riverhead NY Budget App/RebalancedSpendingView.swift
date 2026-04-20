import SwiftUI

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
                                Text(item.change, format: .currency(code: "USD"))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(item.change >= 0 ? .orange : .green)
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
