//
//  RiverheadFundBalanceAuditView.swift
//  Riverhead NY Budget App
//

import SwiftUI
import Observation

public struct RiverheadFundBalanceAuditView: View {
    @Environment(RBBudgetStore.self) private var store
    @State private var year: Int = Calendar.current.component(.year, from: Date())

    // Funds included in the audit table
    private let funds: [String] = ["General Fund", "Highway Fund", "Sewer Fund"]

    // Formatters
    private let nfMoney: NumberFormatter = { let nf = NumberFormatter(); nf.numberStyle = .currency; nf.maximumFractionDigits = 0; return nf }()
    private let nfPct: NumberFormatter   = { let nf = NumberFormatter(); nf.numberStyle = .percent; nf.maximumFractionDigits = 2; return nf }()

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                header

                Section(header: tableHeader) {
                    ForEach(comparisons) { row in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.fund).font(.body.weight(.semibold))
                                Text("Year \(row.year)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 8)

                            MetricCell(
                                title: "% of Exp",
                                value: pctString(row.percentOfExpenditures),
                                tint: tintForPercent(row.percentOfExpenditures, target: row.targetPercent / 100.0)
                            )
                            MetricCell(title: "Target", value: String(format: "%.0f%%", row.targetPercent))

                            MetricCell(
                                title: "Gap (pp)",
                                value: row.gapPercentagePoints.map { String(format: "%.2f", $0) } ?? "—",
                                tint: row.gapPercentagePoints.map { $0 >= 0 ? .green : .orange }
                            )

                            MetricCell(
                                title: "$ Needed",
                                value: row.dollarsNeededToTarget.map { nfMoney.string(from: $0 as NSNumber) ?? "—" } ?? "—",
                                tint: (row.dollarsNeededToTarget ?? 0) == 0 ? .green : .orange
                            )
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Fund Balance Audit")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Text("Audit").font(.headline)
                        Divider().frame(height: 16)
                        YearPicker(year: $year, available: availableYears)
                    }
                }
            }
            .onAppear { if let maxY = availableYears.max() { year = maxY } }
        }
    }

    // MARK: - Computations

    private var availableYears: [Int] {
        store.valueSeries(for: "General Fund", metric: .appropriations).map(\.year).sorted()
    }

    /// Build comparison rows for each fund for the selected year.
    private var comparisons: [Comparison] {
        funds.compactMap { fund in
            let appSeries = store.valueSeries(for: fund, metric: .appropriations)
            guard let exp = appSeries.first(where: { $0.year == year })?.value else {
                return Comparison(fund: fund, year: year, targetPercent: targetPercent(for: fund), exp: nil, unassigned: nil)
            }

            // Use a simple rule for demo:
            // - For General Fund: use store.estimatedFundBalance only for the latest year in the series.
            // - For other funds or older years: no unassigned data (nil).
            let latestYear = appSeries.map(\.year).max()
            let unassigned: Double? = (fund == "General Fund" && year == latestYear) ? store.estimatedFundBalance : nil

            return Comparison(fund: fund, year: year, targetPercent: targetPercent(for: fund), exp: exp, unassigned: unassigned)
        }
    }

    private func targetPercent(for fund: String) -> Double {
        fund == "General Fund" ? 10.0 : 5.0
    }

    // MARK: - UI Bits

    private var header: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "shield.checkerboard").font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Riverhead — Policy vs Actuals").font(.headline)
                    Text("Policy: 10% GF • 5% Others • Replenish within 3 years")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(text: gfStatus)
            }
            HStack {
                LabeledContent("Total $ to target", value: nfMoney.string(from: totalNeeded as NSNumber) ?? "—")
                Spacer()
            }
        }
        .listRowBackground(Color.clear)
    }

    private var gfStatus: String {
        if let gf = comparisons.first(where: { $0.fund == "General Fund" }) {
            if let meets = gf.meetsPolicy {
                return meets ? "GF: Meets/Exceeds" : "GF: Below Target"
            }
        }
        return "GF: —"
    }

    private var totalNeeded: Double {
        comparisons.compactMap { $0.dollarsNeededToTarget }.reduce(0, +)
    }

    private var tableHeader: some View {
        HStack {
            Text("Fund").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            MetricHeader("% of Exp")
            MetricHeader("Target")
            MetricHeader("Gap (pp)")
            MetricHeader("$ Needed")
        }
        .textCase(nil)
    }

    private func pctString(_ fraction: Double?) -> String {
        guard let f = fraction else { return "—" }
        return nfPct.string(from: f as NSNumber) ?? "—"
    }

    private func tintForPercent(_ fraction: Double?, target: Double) -> Color? {
        guard let f = fraction else { return nil }
        return f >= target ? .green : .orange
    }
}

// MARK: - Comparison model

private struct Comparison: Identifiable {
    let id = UUID()
    let fund: String
    let year: Int
    let targetPercent: Double     // 10 or 5
    let exp: Double?              // expenditures (appropriations) for the year
    let unassigned: Double?       // unassigned fund balance (if known)

    // Derived
    var percentOfExpenditures: Double? {
        guard let exp, let unassigned, exp > 0 else { return nil }
        return unassigned / exp
    }

    /// Gap in percentage points to reach target (positive = above target)
    var gapPercentagePoints: Double? {
        guard let pct = percentOfExpenditures else { return nil }
        return (pct * 100.0) - targetPercent
    }

    /// Dollars needed to reach the target (0 if at/above target)
    var dollarsNeededToTarget: Double? {
        guard let exp, exp > 0 else { return nil }
        let target = targetPercent / 100.0 * exp
        let current = unassigned ?? 0
        return max(0, target - current)
    }

    /// Whether the fund meets or exceeds policy
    var meetsPolicy: Bool? {
        guard let pct = percentOfExpenditures else { return nil }
        return (pct * 100.0) >= targetPercent
    }
}

// MARK: - Small UI components (unchanged style)

private struct MetricHeader: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.caption2).foregroundStyle(.secondary)
            .frame(width: 86, alignment: .trailing)
    }
}

private struct MetricCell: View {
    let title: String
    let value: String
    var tint: Color? = nil
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.callout.monospacedDigit()).foregroundStyle(tint ?? .primary)
        }
        .frame(width: 86, alignment: .trailing)
    }
}

private struct StatusBadge: View {
    let text: String
    private var badgeColor: Color {
        if text.localizedCaseInsensitiveContains("Meets") { return Color.green.opacity(0.15) }
        if text.localizedCaseInsensitiveContains("Below") { return Color.orange.opacity(0.15) }
        return Color.gray.opacity(0.15)
    }
    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(badgeColor)
            .clipShape(Capsule())
    }
}

private struct YearPicker: View {
    @Binding var year: Int
    let available: [Int]
    var body: some View {
        Menu {
            ForEach(available.sorted(by: >), id: \.self) { y in Button("\(y)") { year = y } }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                Text("\(year)")
            }
            .font(.subheadline)
            .padding(6)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RiverheadFundBalanceAuditView()
            .environment(RBBudgetStore())   // Observation preview injection
    }
}
