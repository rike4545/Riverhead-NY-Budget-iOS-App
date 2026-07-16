//
//  Budget2027SpendingReductionView.swift
//  Riverhead NY Budget App
//
//  A dedicated, sourced view of every real recurring spending-reduction candidate identified for the
//  2027 budget cycle. Replaces three previously-inconsistent "recurring savings package" figures
//  (BudgetRecommendations2027, Budget2027ScenarioModel, and Budget2027ExecutiveWhiteboardView all used
//  to disagree with each other) with one reconciled total, then adds real, account-level growth flagged
//  in the 2026 Budget Supplement on top of it.
//

import SwiftUI

private struct SpendingReductionItem: Identifiable {
    let title: String
    let amount: Double
    let source: String
    let rationale: String

    var id: String { title }
}

@MainActor
struct Budget2027SpendingReductionView: View {
    private var personnelPolicyItems: [SpendingReductionItem] {
        [
            .init(
                title: "20% healthcare premium contribution",
                amount: Budget2027TaxCapOffsetModel.healthcareContributionSavings,
                source: "22 eligible senior-staff/elected positions × NYSHIP Empire Plan participating-agency individual premium ($\(String(format: "%.2f", Budget2027TaxCapOffsetModel.nyshipPlanPrimeIndividualMonthlyPremium))/mo) × 20%",
                rationale: "Requires a policy adoption for exempt and elected positions; represented staff would need successor bargaining."
            ),
            .init(
                title: "Police Uniform OT recovery target",
                amount: Budget2027TaxCapOffsetModel.overtimeControlSavings,
                source: "2024 actual ($\(Int(Budget2027TaxCapOffsetModel.policeUniformOTActual2024).formatted())) vs. $\(Int(Budget2027TaxCapOffsetModel.policeUniformOTBudget2024).formatted()) budget — a $\(Int(Budget2027TaxCapOffsetModel.policeUniformOTVariance).formatted()) variance",
                rationale: "Only credible with published monthly OT-by-cause reporting and a scheduling plan — not a booked cut."
            ),
            .init(
                title: "Targeted retirement + refill control",
                amount: Budget2027TaxCapOffsetModel.targetedRetirementRefillSavings,
                source: "Three modeled senior departures, two lower-cost backfills",
                rationale: "Depends on which positions actually turn over in 2027; not guaranteed."
            ),
            .init(
                title: "1% civilian vacancy factor",
                amount: Budget2027TaxCapOffsetModel.civilianVacancyFactorSavings,
                source: "1% applied to the 2026 civilian/CSEA payroll base",
                rationale: "Assumes normal turnover timing, not a headcount reduction."
            ),
            .init(
                title: "Hold exempt discretionary raises",
                amount: Budget2027TaxCapOffsetModel.exemptRaiseHoldSavings,
                source: "2026 exempt discretionary raise baseline",
                rationale: "A Board choice each budget cycle, not a structural change."
            ),
            .init(
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
                    title: rec.account,
                    amount: rec.change,
                    source: "\(rec.fundFunction) — $\(Int(rec.adopted2025).formatted()) (2025) → $\(Int(rec.adopted2026).formatted()) (2026), \(rec.changeLabel ?? "")",
                    rationale: rec.rationale
                )
            }
            .sorted { $0.amount > $1.amount }
    }

    private var personnelPolicySubtotal: Double {
        Budget2027TaxCapOffsetModel.recurringSavingsPackageTotal
    }

    private var operationalSubtotal: Double {
        DepartmentBudgetLensData.operationalGrowthControlTotal
    }

    private var grandTotal: Double {
        Budget2027TaxCapOffsetModel.recurringSavingsPackageTotal + DepartmentBudgetLensData.operationalGrowthControlTotal
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(grandTotal, format: .currency(code: "USD"))
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(RiverheadTheme.brandMint)

                    Text("Total real, individually-sourced recurring spending-reduction candidates identified for the 2027 budget.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)

                HStack {
                    metricTile(title: "Personnel & policy", value: personnelPolicySubtotal, tint: RiverheadTheme.brandNavy)
                    metricTile(title: "Operational growth control", value: operationalSubtotal, tint: RiverheadTheme.brandCoral)
                }
            }

            Section {
                Text("This is not $2.75M. Union wage growth ($907.9K of modeled PBA/SOA/CSEA pressure) is the single largest driver in the 2027 model, but it's contractually locked and cannot be treated as a spending-reduction lever without a successor labor agreement — it stays on the pressure side of the budget, not here. Every dollar below is traceable to either a named formula input or an actual 2025→2026 account-level change in the Town's own 2026 Budget Supplement.")
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
                Text("Personnel & Policy Savings — $\(Int(personnelPolicySubtotal).formatted())")
            } footer: {
                Text("Six categories reconciled across the app's three 2027 planning models (RiverheadBudgetHubView, Budget2027 simulator, and executive whiteboard), which previously disagreed on this total by up to $12K.")
            }

            Section {
                ForEach(operationalItems) { item in
                    itemRow(item)
                }
            } header: {
                Text("Operational Growth Controls — $\(Int(operationalSubtotal).formatted())")
            } footer: {
                Text("Real account-level growth from the 2026 Budget Supplement, flagged for Board scrutiny before being carried forward as a permanent baseline. Excludes the new Peconic Hockey electricity line ($167,742), which is a same-fund reclassification, not net-new spending — the general Town Hall electricity line drops by the same amount.")
            }
        }
        .navigationTitle("2027 Spending Reduction")
        .navigationBarTitleDisplayMode(.inline)
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
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func itemRow(_ item: SpendingReductionItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.title)
                    .font(.headline)
                Spacer(minLength: 12)
                Text(item.amount, format: .currency(code: "USD"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RiverheadTheme.brandMint)
            }
            Text(item.source)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(item.rationale)
                .font(.caption)
                .foregroundStyle(.secondary)
                .italic()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        Budget2027SpendingReductionView()
    }
}
