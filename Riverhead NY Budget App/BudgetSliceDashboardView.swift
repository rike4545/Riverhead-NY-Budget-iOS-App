//
//  BudgetSliceDashboardView.swift
//  Riverhead NY Budget App
//
//  Visual breakdown for an array of BudgetSlice items.
//  - Compile-safe, iOS 17+
//  - Avoids recreating NumberFormatter repeatedly
//  - Adds clearer sign semantics (net, and per-slice annotation)
//

import SwiftUI
import Charts

@MainActor
struct BudgetSliceDashboardView: View {
    let title: String
    let slices: [BudgetSlice]

    private var total: Double { slices.totalAmount }
    private var categoryTotals: [(BudgetCategory, Double)] { slices.totalsByCategory }
    private var topSlices: [BudgetSlice] { Array(slices.sortedByMagnitude().prefix(8)) }
    private var inflowTotal: Double { slices.reduce(0) { $0 + max($1.amount, 0) } }
    private var outflowTotal: Double { slices.reduce(0) { $0 + abs(min($1.amount, 0)) } }
    private var largestShare: Double {
        guard let largest = topSlices.first, max(inflowTotal, outflowTotal) > 0 else { return 0 }
        return abs(largest.amount) / max(inflowTotal, outflowTotal)
    }

    private var totalColor: Color { total >= 0 ? .green : .red }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            totalSummary
            cashflowInfographic
            categoryChips
            categoryDonut
            barChart
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08))
        )
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
            Text("\(slices.count) items")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var totalSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Net position")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(Formatters.currency0(total))
                .font(.title2.weight(.bold))
                .foregroundStyle(totalColor)
                .monospacedDigit()

            Text(totalExplanation)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var totalExplanation: String {
        if total > 0 { return "Overall surplus (inflows exceed outflows)." }
        if total < 0 { return "Overall deficit (outflows exceed inflows)." }
        return "Roughly break-even."
    }

    private var cashflowInfographic: some View {
        HStack(spacing: 10) {
            budgetMetricTile(
                title: "Inflow",
                value: Formatters.currency0Short(inflowTotal),
                systemImage: "arrow.down.forward.circle.fill",
                tint: .green
            )

            budgetMetricTile(
                title: "Outflow",
                value: Formatters.currency0Short(outflowTotal),
                systemImage: "arrow.up.forward.circle.fill",
                tint: .red
            )

            budgetMetricTile(
                title: "Largest slice",
                value: largestShare.formatted(.percent.precision(.fractionLength(0))),
                systemImage: "target",
                tint: RiverheadTheme.brandGold
            )
        }
    }

    private func budgetMetricTile(title: String, value: String, systemImage: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 28, height: 28, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(0.20), lineWidth: 0.8)
        )
        .accessibilityElement(children: .combine)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categoryTotals, id: \.0.id) { (category, total) in
                    let color: Color = total >= 0 ? .green : .red
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.displayName)
                                .font(.caption2.weight(.semibold))
                            Text(Formatters.currency0(total))
                                .font(.caption2)
                                .monospacedDigit()
                        }
                    } icon: {
                        Circle()
                            .fill(color.opacity(0.35))
                            .frame(width: 8, height: 8)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.secondary.opacity(0.08))
                    )
                    .accessibilityLabel("\(category.displayName), \(Formatters.currency0(total))")
                }
            }
        }
    }

    private var barChart: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Largest slices by magnitude")
                .font(.caption)
                .foregroundStyle(.secondary)

            if topSlices.isEmpty {
                Text("No data to display.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart(topSlices, id: \.id) { slice in
                    BarMark(
                        x: .value("Magnitude", abs(slice.amount)),
                        y: .value("Label", slice.label)
                    )
                    .annotation(position: .trailing) {
                        Text(Formatters.currency0Short(slice.amount))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .accessibilityLabel("\(slice.label), \(Formatters.currency0(slice.amount))")
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(24 * max(topSlices.count, 3)))
                .accessibilityElement(children: .contain)
            }
        }
    }

    private var categoryDonut: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category shape")
                .font(.caption)
                .foregroundStyle(.secondary)

            if categoryTotals.isEmpty {
                EmptyView()
            } else {
                HStack(alignment: .center, spacing: 14) {
                    Chart(categoryTotals, id: \.0.id) { category, total in
                        SectorMark(
                            angle: .value("Amount", abs(total)),
                            innerRadius: .ratio(0.58),
                            angularInset: 1.8
                        )
                        .foregroundStyle(color(for: category))
                        .accessibilityLabel("\(category.displayName), \(Formatters.currency0(total))")
                    }
                    .chartLegend(.hidden)
                    .frame(width: 118, height: 118)

                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(categoryTotals.prefix(5), id: \.0.id) { category, total in
                            HStack(spacing: 7) {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(color(for: category))
                                    .frame(width: 10, height: 10)
                                Text(category.displayName)
                                    .font(.caption2.weight(.semibold))
                                    .lineLimit(1)
                                Spacer(minLength: 4)
                                Text(Formatters.currency0Short(total))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                .accessibilityElement(children: .contain)
            }
        }
    }

    private func color(for category: BudgetCategory) -> Color {
        switch category {
        case .revenue: return .green
        case .expense: return .red
        case .fundBalanceAdjustment: return RiverheadTheme.brandGold
        case .capital: return .orange
        case .debtService: return .purple
        case .grants: return .teal
        case .other: return RiverheadTheme.brandSky
        }
    }
}

// MARK: - Shared Formatters (main-thread use)

@MainActor
private enum Formatters {
    private static let currency0Formatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.maximumFractionDigits = 0
        return nf
    }()

    static func currency0(_ value: Double) -> String {
        currency0Formatter.string(from: value as NSNumber) ?? String(format: "%.0f", value)
    }

    /// Short currency like "$12.3M" and preserves sign.
    static func currency0Short(_ value: Double) -> String {
        let sign = value < 0 ? "-" : ""
        let v = abs(value)

        let (scaled, suffix): (Double, String) = {
            if v >= 1_000_000_000 { return (v / 1_000_000_000, "B") }
            if v >= 1_000_000 { return (v / 1_000_000, "M") }
            if v >= 1_000 { return (v / 1_000, "K") }
            return (v, "")
        }()

        let number = scaled >= 100 ? String(format: "%.0f", scaled) : String(format: "%.1f", scaled)
        let symbol = currency0Formatter.currencySymbol ?? "$"
        return "\(sign)\(symbol)\(number)\(suffix)"
    }
}
