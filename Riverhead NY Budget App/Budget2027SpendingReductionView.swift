//
//  Budget2027SpendingReductionView.swift
//  Riverhead NY Budget App
//
//  A dedicated, sourced, and interactive view of every real recurring spending-reduction candidate
//  identified for the 2027 budget cycle. Replaces three previously-inconsistent "recurring savings
//  package" figures (BudgetRecommendations2027, Budget2027ScenarioModel, and
//  Budget2027ExecutiveWhiteboardView all used to disagree with each other) with one reconciled total,
//  then adds real, account-level growth flagged in the 2026 Budget Supplement on top of it.
//
//  Every item is toggleable so residents can build their own package and watch the running total move
//  against the $936.7K modeled 2027 payroll-pressure gap in real time.
//

import SwiftUI

private struct SpendingReductionItem: Identifiable {
    let id: String
    let title: String
    let amount: Double
    let source: String
    let rationale: String
}

@MainActor
struct Budget2027SpendingReductionView: View {
    @State private var deselectedItemIDs: Set<String> = []

    private var personnelPolicyItems: [SpendingReductionItem] {
        [
            .init(
                id: "healthcare",
                title: "20% healthcare premium contribution",
                amount: Budget2027TaxCapOffsetModel.healthcareContributionSavings,
                source: "22 eligible senior-staff/elected positions × NYSHIP Empire Plan participating-agency individual premium ($\(String(format: "%.2f", Budget2027TaxCapOffsetModel.nyshipPlanPrimeIndividualMonthlyPremium))/mo) × 20%",
                rationale: "Requires a policy adoption for exempt and elected positions; represented staff would need successor bargaining."
            ),
            .init(
                id: "overtime",
                title: "Police Uniform OT recovery target",
                amount: Budget2027TaxCapOffsetModel.overtimeControlSavings,
                source: "2024 actual ($\(Int(Budget2027TaxCapOffsetModel.policeUniformOTActual2024).formatted())) vs. $\(Int(Budget2027TaxCapOffsetModel.policeUniformOTBudget2024).formatted()) budget — a $\(Int(Budget2027TaxCapOffsetModel.policeUniformOTVariance).formatted()) variance",
                rationale: "Southampton's 2026 adopted Police OT is $13,069.50/officer for 113 officers; at that regional rate Riverhead's ~100 officers would need about $1,306,950 — meaning most of the variance is likely real coverage need, not scheduling waste. Zero OT isn't realistic, so this targets only the residual above that peer benchmark."
            ),
            .init(
                id: "retirementRefill",
                title: "Targeted retirement + refill control",
                amount: Budget2027TaxCapOffsetModel.targetedRetirementRefillSavings,
                source: "Three modeled senior departures, two lower-cost backfills",
                rationale: "Depends on which positions actually turn over in 2027; not guaranteed."
            ),
            .init(
                id: "vacancyFactor",
                title: "1% civilian vacancy factor",
                amount: Budget2027TaxCapOffsetModel.civilianVacancyFactorSavings,
                source: "1% applied to the 2026 civilian/CSEA payroll base",
                rationale: "Assumes normal turnover timing, not a headcount reduction."
            ),
            .init(
                id: "exemptRaiseHold",
                title: "Hold exempt discretionary raises",
                amount: Budget2027TaxCapOffsetModel.exemptRaiseHoldSavings,
                source: "2026 exempt discretionary raise baseline",
                rationale: "A Board choice each budget cycle, not a structural change."
            ),
            .init(
                id: "electedRaiseHold",
                title: "Hold elected salary growth",
                amount: Budget2027TaxCapOffsetModel.electedRaiseHoldSavings,
                source: "2026 elected-official raise baseline",
                rationale: "Separately stated Board action, not embedded in the baseline."
            )
        ]
    }

    private var operationalItems: [SpendingReductionItem] {
        DepartmentBudgetLensData.rebalancedSpending
            .filter { $0.direction == .tighten && !$0.isFundNeutralReclassification }
            .map { rec in
                .init(
                    id: rec.id,
                    title: rec.account,
                    amount: rec.change,
                    source: "\(rec.fundFunction) — $\(Int(rec.adopted2025).formatted()) (2025) → $\(Int(rec.adopted2026).formatted()) (2026), \(rec.changeLabel ?? "")",
                    rationale: rec.rationale
                )
            }
            .sorted { $0.amount > $1.amount }
    }

    private var allItems: [SpendingReductionItem] {
        personnelPolicyItems + operationalItems
    }

    private func isSelected(_ item: SpendingReductionItem) -> Bool {
        !deselectedItemIDs.contains(item.id)
    }

    private func selectedTotal(_ items: [SpendingReductionItem]) -> Double {
        items.filter { isSelected($0) }.reduce(0) { $0 + $1.amount }
    }

    private var personnelPolicySelectedTotal: Double { selectedTotal(personnelPolicyItems) }
    private var operationalSelectedTotal: Double { selectedTotal(operationalItems) }
    private var grandSelectedTotal: Double { personnelPolicySelectedTotal + operationalSelectedTotal }

    private var personnelPolicyFullTotal: Double { Budget2027TaxCapOffsetModel.recurringSavingsPackageTotal }
    private var operationalFullTotal: Double { DepartmentBudgetLensData.operationalGrowthControlTotal }
    private var grandFullTotal: Double { personnelPolicyFullTotal + operationalFullTotal }

    private var payrollPressureGap: Double { Budget2027ScenarioModel.modeledAutomaticPayrollPressure }

    private var gapCoverage: Double {
        guard payrollPressureGap > 0 else { return 0 }
        return min(grandSelectedTotal / payrollPressureGap, 1.0)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(grandSelectedTotal, format: .currency(code: "USD"))
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(RiverheadTheme.brandMint)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: grandSelectedTotal)

                    Text("Your selected package, out of \(grandFullTotal, format: .currency(code: "USD")) available.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    coverageBar
                }
                .padding(.vertical, 6)

                HStack {
                    metricTile(title: "Personnel & policy", value: personnelPolicySelectedTotal, tint: RiverheadTheme.brandNavy)
                    metricTile(title: "Operational growth control", value: operationalSelectedTotal, tint: RiverheadTheme.brandCoral)
                }

                HStack {
                    Button {
                        withAnimation(.snappy) { deselectedItemIDs.removeAll() }
                    } label: {
                        Label("Select all", systemImage: "checkmark.circle")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        withAnimation(.snappy) { deselectedItemIDs = Set(allItems.map(\.id)) }
                    } label: {
                        Label("Clear all", systemImage: "circle")
                    }
                    .buttonStyle(.bordered)
                }
                .font(.subheadline)
            }

            Section {
                Text("Union wage growth ($907.9K of modeled PBA/SOA/CSEA pressure) is the single largest driver in the 2027 model, but it's contractually locked and cannot be treated as a spending-reduction lever without a successor labor agreement — it stays on the pressure side of the budget, not here. Every dollar below is traceable to either a named formula input or an actual 2025→2026 account-level change in the Town's own 2026 Budget Supplement. Tap any item to test a package that leaves it out.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("PBA and SOA contracts both expire 12/31/2026 (CSEA is already locked through a ratified 2026-2029 agreement). New York law routes police/fire bargaining impasses to binding arbitration rather than legislative resolution, and comparable Long Island police contracts have taken 1-3+ years past expiration to settle — so the PBA/SOA figures above will likely remain placeholder estimates through the 2027 budget cycle, with any successor terms applied retroactively once reached.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Scope")
            }

            Section {
                ForEach(personnelPolicyItems) { item in
                    itemRow(item)
                }
            } header: {
                Text("Personnel & Policy Savings — \(personnelPolicySelectedTotal, format: .currency(code: "USD").precision(.fractionLength(0))) of \(personnelPolicyFullTotal, format: .currency(code: "USD").precision(.fractionLength(0)))")
            } footer: {
                Text("Six categories: policy or formula-driven savings that would require Board or contract action to actually capture.")
            }

            Section {
                ForEach(operationalItems) { item in
                    itemRow(item)
                }
            } header: {
                Text("Operational Growth Controls — \(operationalSelectedTotal, format: .currency(code: "USD").precision(.fractionLength(0))) of \(operationalFullTotal, format: .currency(code: "USD").precision(.fractionLength(0)))")
            } footer: {
                Text("Real account-level growth from the 2026 Budget Supplement, flagged for Board scrutiny before being carried forward as a permanent baseline. Excludes the new Peconic Hockey electricity line ($167,742), which is a same-fund reclassification, not net-new spending — the general Town Hall electricity line drops by the same amount.")
            }
        }
        .navigationTitle("2027 Spending Reduction")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var coverageBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(RiverheadTheme.softBorder.opacity(0.4))
                    Capsule()
                        .fill(RiverheadTheme.brandMint)
                        .frame(width: geo.size.width * gapCoverage)
                        .animation(.snappy, value: gapCoverage)
                }
            }
            .frame(height: 8)

            Text("\(gapCoverage.formatted(.percent.precision(.fractionLength(0)))) of the \(payrollPressureGap, format: .currency(code: "USD").precision(.fractionLength(0))) modeled 2027 payroll-pressure gap")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func metricTile(title: String, value: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: "USD"))
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func itemRow(_ item: SpendingReductionItem) -> some View {
        let selected = isSelected(item)
        return Button {
            withAnimation(.snappy) {
                if selected {
                    deselectedItemIDs.insert(item.id)
                } else {
                    deselectedItemIDs.remove(item.id)
                }
            }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? RiverheadTheme.brandMint : .secondary)
                    .font(.title3)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(item.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer(minLength: 12)
                        Text(item.amount, format: .currency(code: "USD"))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(selected ? RiverheadTheme.brandMint : .secondary)
                    }
                    Text(item.source)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.rationale)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }
                .opacity(selected ? 1.0 : 0.55)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        Budget2027SpendingReductionView()
    }
}
