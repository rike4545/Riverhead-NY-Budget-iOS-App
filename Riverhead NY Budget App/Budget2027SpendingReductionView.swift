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
    var confidence: String? = nil   // "firm" | "moderate" | "volatile" (supplement trims)
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

    // Itemized, ledger-sourced trims from the 2026 Budget Supplement: every
    // controllable, non-mandated line budgeted above its trailing run-rate.
    private var supplementItems: [SpendingReductionItem] {
        (SupplementData.reductions?.items ?? []).map { r in
            .init(
                id: "supp-\(r.account)",
                title: r.name,
                amount: r.target,
                source: "\(r.fundName) — 2026 tentative \(usd(r.tentative2026)) vs 2024 actual \(usd(r.actual2024)); trims to the trailing run-rate",
                rationale: Self.confidenceRationale(r.confidence),
                confidence: r.confidence
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    private var allItems: [SpendingReductionItem] {
        personnelPolicyItems + operationalItems + supplementItems
    }

    private func usd(_ v: Double?) -> String {
        (v ?? 0).formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private static func confidenceRationale(_ c: String) -> String {
        switch c {
        case "firm": return "Operating or professional-services line budgeted well above its own trailing actuals — the firmest kind of trim."
        case "moderate": return "Capital or maintenance line that fluctuates year to year; the trim depends on 2027 project timing."
        case "volatile": return "Price-driven (fuel, energy, utilities); the excess over trend is real but not guaranteed to recur."
        default: return ""
        }
    }

    private func isSelected(_ item: SpendingReductionItem) -> Bool {
        !deselectedItemIDs.contains(item.id)
    }

    private func selectedTotal(_ items: [SpendingReductionItem]) -> Double {
        items.filter { isSelected($0) }.reduce(0) { $0 + $1.amount }
    }

    private var personnelPolicySelectedTotal: Double { selectedTotal(personnelPolicyItems) }
    private var operationalSelectedTotal: Double { selectedTotal(operationalItems) }
    private var supplementSelectedTotal: Double { selectedTotal(supplementItems) }
    private var grandSelectedTotal: Double { personnelPolicySelectedTotal + operationalSelectedTotal + supplementSelectedTotal }

    private var personnelPolicyFullTotal: Double { Budget2027TaxCapOffsetModel.recurringSavingsPackageTotal }
    private var operationalFullTotal: Double { DepartmentBudgetLensData.operationalGrowthControlTotal }
    private var supplementFullTotal: Double { SupplementData.reductions?.total ?? 0 }
    private var grandFullTotal: Double { personnelPolicyFullTotal + operationalFullTotal + supplementFullTotal }

    private var payrollPressureGap: Double { Budget2027ScenarioModel.modeledAutomaticPayrollPressure }

    // Uncapped ratio — can (and now does) exceed 100%, which is the headline:
    // verified trims cover the gap several times over.
    private var rawGapCoverage: Double {
        guard payrollPressureGap > 0 else { return 0 }
        return grandSelectedTotal / payrollPressureGap
    }
    private var gapCoverage: Double { min(rawGapCoverage, 1.0) }

    // The real binding constraint: the cap-piercing gap, and the honest math
    // that closes it with only firm items + the unanimous buyout.
    private var capGap: Double { CloseTheGap2027.capPiercingGap }
    private var firmSupplementTotal: Double {
        supplementItems.filter { $0.confidence == "firm" }.reduce(0) { $0 + $1.amount }
    }
    private var firmRecurringTotal: Double {
        personnelPolicyFullTotal + operationalFullTotal + firmSupplementTotal
    }
    private var comboLowPct: Double { (CloseTheGap2027.RetirementIncentive.projectedSavingsLow + firmRecurringTotal) / capGap }
    private var comboHighPct: Double { (CloseTheGap2027.RetirementIncentive.projectedSavingsHigh + firmRecurringTotal) / capGap }

    var body: some View {
        List {
            Section {
                ModelVsAdoptedCard()
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            }

            // Answer first: the real cap gap and the plan that closes it.
            capGapSection
            personalServicesRateSection
            retirementLeverSection

            // Then the interactive tool to explore/build the package.
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

                ViewThatFits(in: .horizontal) {
                    HStack {
                        metricTile(title: "Personnel & policy", value: personnelPolicySelectedTotal, tint: RiverheadTheme.brandNavy)
                        metricTile(title: "Operational control", value: operationalSelectedTotal, tint: RiverheadTheme.brandCoral)
                        metricTile(title: "Line-item trims", value: supplementSelectedTotal, tint: RiverheadTheme.brandSky)
                    }
                    VStack {
                        metricTile(title: "Personnel & policy", value: personnelPolicySelectedTotal, tint: RiverheadTheme.brandNavy)
                        metricTile(title: "Operational control", value: operationalSelectedTotal, tint: RiverheadTheme.brandCoral)
                        metricTile(title: "Line-item trims", value: supplementSelectedTotal, tint: RiverheadTheme.brandSky)
                    }
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
            } header: {
                Text("Build your own package")
            } footer: {
                Text("Toggle any item to test a package that leaves it out. Totals update live against the payroll-pressure gap.")
            }

            Section {
                DisclosureGroup("About this package & scope") {
                    Text("Union wage growth ($907.9K of modeled PBA/SOA/CSEA pressure) is the single largest driver in the 2027 model, but it's contractually locked and cannot be treated as a spending-reduction lever without a successor labor agreement — it stays on the pressure side of the budget, not here. Every dollar below is traceable to either a named formula input or an actual 2025→2026 account-level change in the Town's own 2026 Budget Supplement.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)

                    Text("PBA and SOA’s 2023–2026 contracts expire 12/31/2026 (CSEA is locked through a ratified 2026–2029 agreement). They did not go to arbitration: on November 17, 2026 the Board approved 2027–2030 stipulations for both, 3.75% a year plus $500 in 2027 (Resolutions 2026-1020 and 2026-1021). The PBA/SOA rates above are the September model’s placeholders, kept as they were.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                }
                .font(.subheadline.weight(.semibold))
                .tint(RiverheadTheme.brandNavy)
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

            if !supplementItems.isEmpty {
                Section {
                    ForEach(supplementItems) { item in
                        itemRow(item)
                    }
                } header: {
                    Text("Line-Item Trims · 2026 Supplement — \(supplementSelectedTotal, format: .currency(code: "USD").precision(.fractionLength(0))) of \(supplementFullTotal, format: .currency(code: "USD").precision(.fractionLength(0)))")
                } footer: {
                    Text("Every controllable, non-mandated line the 2026 Budget Supplement budgets more than 30% above its own trailing actuals — trimmed back to that run-rate. Tagged FIRM (operating/professional services), MODERATE (capital/maintenance that fluctuates), or VOLATILE (price-driven fuel and energy). Mandated costs — pension, workers' comp, insurance, debt service — are excluded, since their growth is obligation, not waste.")
                }
            }

            splitBoardSection
        }
        .navigationTitle("2027 Spending Reduction")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - The real cap gap, and the path through a split board

    // Why the projected levy moved: Personal Services is no longer one flat
    // 3.5% for everyone but a payroll-weighted blend of each bargaining unit's
    // own 2027 terms. Mirrors the web edition's predict-2027 breakdown.
    @ViewBuilder private var personalServicesRateSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(CloseTheGap2027.unionBreakdownNote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(CloseTheGap2027.unionBreakdown) { group in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(group.union)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(RiverheadTheme.brandNavy)
                            Spacer(minLength: 8)
                            Text("+\(group.ratePct.formatted())%")
                                .font(.subheadline.weight(.heavy))
                                .foregroundStyle(RiverheadTheme.brandCoral)
                            if !group.known2027 {
                                Text("est.")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(RiverheadTheme.brandGold)
                            }
                        }
                        Text("\(group.payrollSharePct.formatted())% of payroll\(group.term.map { " · \($0)" } ?? "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(group.source)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 3)
                }

                Text(CloseTheGap2027.unionBreakdownEstimateNote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                Text("Pension costs are partly excluded from the cap")
                    .font(.subheadline.weight(.semibold))
                Text("New York lets a municipality exclude the part of a pension contribution-rate rise above 2 percentage points. For SFY 2026-27 only the police system clears that bar: PFRS rose \(CloseTheGap2027.PensionExclusion.pfrsRateIncreasePts.formatted()) points (\(CloseTheGap2027.PensionExclusion.pfrsExcessPts.formatted()) over the threshold), while ERS rose \(CloseTheGap2027.PensionExclusion.ersRateIncreasePts.formatted()) points and earns no exclusion. That is worth about \(CloseTheGap2027.PensionExclusion.totalEstimate, format: .currency(code: "USD").precision(.fractionLength(0))) of headroom against the gap above.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(CloseTheGap2027.PensionExclusion.source)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(CloseTheGap2027.capGapCaveat)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
        } header: {
            Text("How the Personal Services rate is built")
        }
    }

    @ViewBuilder private var capGapSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("What happened")
                    .font(.headline)
                Text(CloseTheGap2027.Outcome.summary)
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Everything below is this app’s September model, kept as it was made before the Tentative: a projection from recent cost trends and contract raises, not a Town figure and not what happened.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                Text("Two different “gaps” — and which one actually binds")
                    .font(.headline)
                Text("There are two numbers. The payroll-pressure gap (\(payrollPressureGap, format: .currency(code: "USD").precision(.fractionLength(0)))) is the recurring cost of standing still. The one that actually forces a decision is bigger: the projected 2027 levy overshoots New York's 2% property-tax cap by about \(capGap, format: .currency(code: "USD").precision(.fractionLength(0))) (a ~\(CloseTheGap2027.predictedLevyPct.formatted())% levy against a ~\(Int(CloseTheGap2027.capBasePct))% ceiling). That is the real overage to resolve.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                Text("Closing it without piercing the cap")
                    .font(.subheadline.weight(.semibold))
                Text("The unanimous retirement incentive plus only the firmest line trims — nothing volatile, no fund-balance raid, no override — already sum to roughly the whole gap:")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                gapTile("Retirement incentive", "\(CloseTheGap2027.RetirementIncentive.projectedSavingsLow.formatted(.currency(code: "USD").precision(.fractionLength(0))))–\(CloseTheGap2027.RetirementIncentive.projectedSavingsHigh.formatted(.currency(code: "USD").precision(.fractionLength(0))))", "Town projection · adopted 5–0", RiverheadTheme.brandMint)
                gapTile("Firm-confidence trims", firmRecurringTotal.formatted(.currency(code: "USD").precision(.fractionLength(0))), "Excludes volatile & capital-timing items", RiverheadTheme.brandSky)
                gapTile("Combined vs. the cap gap", "\(comboLowPct.formatted(.percent.precision(.fractionLength(0))))–\(comboHighPct.formatted(.percent.precision(.fractionLength(0))))", "of the \(capGap.formatted(.currency(code: "USD").precision(.fractionLength(0)))) overage", RiverheadTheme.brandNavy)
            }
            .padding(.vertical, 4)
        } header: {
            Text("2027 outcome and the September model")
        }
    }

    @ViewBuilder private var retirementLeverSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("The Town Board unanimously approved three voluntary retirement incentives on July 7, 2026 (\(CloseTheGap2027.RetirementIncentive.resolutions)). The Town projects \(CloseTheGap2027.RetirementIncentive.projectedSavingsLow, format: .currency(code: "USD").precision(.fractionLength(0)))–\(CloseTheGap2027.RetirementIncentive.projectedSavingsHigh, format: .currency(code: "USD").precision(.fractionLength(0))) in savings over \(CloseTheGap2027.RetirementIncentive.savingsWindow).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(CloseTheGap2027.RetirementIncentive.eligible) { u in
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(u.unit) · \(u.count) eligible")
                            .font(.caption.weight(.semibold))
                        Spacer(minLength: 8)
                        Text(u.benefit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Text(CloseTheGap2027.RetirementIncentive.note)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Retirement incentive · \(CloseTheGap2027.RetirementIncentive.eligibleTotal) eligible")
        }
    }

    @ViewBuilder private var splitBoardSection: some View {
        Section {
            DisclosureGroup("Will it pass a divided board? The politics") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Closing the gap had to pass a divided board: a Democratic Supervisor with a four-member Republican Council majority. Under NY Town Law the Supervisor prepares the tentative budget and the Council adopts it, so a durable plan needs both. These levers are ordered by how well each survives that split — least partisan first.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(Array(CloseTheGap2027.paths.enumerated()), id: \.element.id) { idx, p in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("\(idx + 1)").font(.caption.weight(.black)).foregroundStyle(.secondary)
                                Text(p.name).font(.subheadline.weight(.semibold))
                                Spacer(minLength: 6)
                            }
                            Text(p.standing.rawValue)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8).padding(.vertical, 2)
                                .background(standingTint(p.standing).opacity(0.16), in: Capsule())
                                .foregroundStyle(standingTint(p.standing))
                            Text("Closes: \(p.closes)").font(.caption.weight(.semibold)).foregroundStyle(RiverheadTheme.brandMint)
                            Text(p.politics).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 4)
                    }
                    Text(CloseTheGap2027.pragmaticReading)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                    Text("Board composition from the November 2025 results; budget roles per NY Town Law §§104–106. Cap-override mechanics per General Municipal Law §3-c (a 60% vote of the governing body).")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .font(.subheadline.weight(.semibold))
            .tint(RiverheadTheme.brandNavy)
        }
    }

    private func gapTile(_ label: String, _ value: String, _ note: String, _ tint: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Text(note).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(value).font(.headline.weight(.bold)).foregroundStyle(tint)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func standingTint(_ s: CloseTheGap2027.Standing) -> Color {
        switch s {
        case .agreed, .lowFriction: return RiverheadTheme.brandMint
        case .neutral: return RiverheadTheme.brandSky
        case .oneTime: return RiverheadTheme.brandGold
        case .deliberate: return RiverheadTheme.brandNavy
        case .blunt: return RiverheadTheme.brandCoral
        }
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

            Text("\(rawGapCoverage.formatted(.percent.precision(.fractionLength(0)))) of the \(payrollPressureGap, format: .currency(code: "USD").precision(.fractionLength(0))) modeled 2027 payroll-pressure gap\(rawGapCoverage >= 1 ? " — fully covered" : "") — the smaller of the two gaps; the ~$2.32M cap-piercing gap above, from the September model, was the one that would have bound. The adopted levy came in under the 2% line.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func confidenceBadge(_ c: String) -> some View {
        let (label, tint): (String, Color) = {
            switch c {
            case "firm": return ("FIRM", RiverheadTheme.brandMint)
            case "moderate": return ("MODERATE", RiverheadTheme.brandGold)
            case "volatile": return ("VOLATILE", RiverheadTheme.brandCoral)
            default: return (c.uppercased(), .secondary)
            }
        }()
        return Text(label)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tint.opacity(0.16), in: Capsule())
            .foregroundStyle(tint)
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
                        if let c = item.confidence {
                            confidenceBadge(c)
                        }
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
