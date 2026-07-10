//
//  EarlyRetirementIncentiveView.swift
//  Riverhead NY Budget App
//
//  Plain-language what-if model for early retirement incentive planning.
//

import SwiftUI

@MainActor
struct EarlyRetirementIncentiveView: View {
    @Environment(\.colorScheme) private var scheme

    @State private var selectedPreset: ERIScenarioPreset = .balanced
    @State private var participants: Double = 10
    @State private var averageSalary: Double = 95_000
    @State private var averageCurrentBenefitsRate: Double = 0.42
    @State private var replacementRate: Double = 0.75
    @State private var replacementSalaryFactor: Double = 0.72
    @State private var replacementBenefitsRate: Double = 0.34
    @State private var incentivePerParticipant: Double = 30_000
    @State private var accruedLeavePayoutPerParticipant: Double = 18_000

    private var annualCurrentCost: Double {
        participants * averageSalary * (1 + averageCurrentBenefitsRate)
    }

    private var replacementCount: Double {
        participants * replacementRate
    }

    private var replacementSalary: Double {
        averageSalary * replacementSalaryFactor
    }

    private var annualReplacementCost: Double {
        replacementCount * replacementSalary * (1 + replacementBenefitsRate)
    }

    private var annualGrossSavings: Double {
        max(annualCurrentCost - annualReplacementCost, 0)
    }

    private var totalUpfrontCost: Double {
        participants * (incentivePerParticipant + accruedLeavePayoutPerParticipant)
    }

    private var breakEvenYears: Double {
        guard annualGrossSavings > 0 else { return .infinity }
        return totalUpfrontCost / annualGrossSavings
    }

    private func netSavings(after years: Double) -> Double {
        (annualGrossSavings * years) - totalUpfrontCost
    }

    private var inputWarnings: [String] {
        var warnings: [String] = []
        if averageSalary <= 0 {
            warnings.append("Average salary must be greater than zero.")
        } else if averageSalary > 500_000 {
            warnings.append("Average salary seems unusually high — double-check the value.")
        }
        if incentivePerParticipant > averageSalary, averageSalary > 0 {
            warnings.append("Incentive per participant exceeds average salary, which is atypical.")
        }
        if annualCurrentCost > 0, annualReplacementCost >= annualCurrentCost {
            warnings.append("Replacement cost equals or exceeds current cost — verify refill rate and salary factor.")
        }
        return warnings
    }

    private var cardFill: Color {
        if scheme == .dark {
            return Color(red: 10/255, green: 14/255, blue: 20/255)
        }
        return RiverheadTheme.Surface.card
    }

    private var cardBorder: Color {
        if scheme == .dark {
            return Color.white.opacity(0.14)
        }
        return RiverheadTheme.border.opacity(0.22)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                headerCard

                panelCard(title: "Current Status: Ratified", systemImage: "checkmark.seal.fill") {
                    bullet("The Town Board voted unanimously on July 7, 2026 to ratify all three union agreements — CSEA, PBA, and SOA — for the 2026 Voluntary Retirement Incentive Program. These are executed, ratified terms, not a proposal.")
                    bullet("CSEA members receive a flat $12,500 cash incentive.")
                    bullet("PBA and SOA (police) members receive $1,000 per year of service, plus a payout for up to 30 accrued sick days beyond the contract maximum, at the average of 2024–2026 base salary.")
                    bullet("An eligible employee must commit in writing by September 1, 2026 and retire by October 1, 2026.")
                    bullet("Officially, 53 employees are eligible — 29 CSEA, 18 PBA, 6 SOA — per Financial Administrator Jeannette DiPaola (RiverheadLOCAL, 7/9/2026). The Town estimates $500,000–$800,000 in savings depending on uptake, and expects all vacated positions to be refilled. (Our own hire-date/union upper-bound model below, 78 eligible, was always a ceiling — the real number came in well under it, as expected, since payroll can't reveal true retirement eligibility like age.)")
                }

                panelCard(title: "CSEA Contract Context", systemImage: "person.3.fill") {
                    bullet("The 2026-2029 CSEA agreement adds scheduled wage actions of 2.0% in 2026, 2.5% in 2027, 3.0% in 2028, and 3.5% in 2029, plus supplemental annual payments of $1,500 in 2026, $1,000 in 2027, and $500 in 2028.")
                    bullet("The agreement increases longevity after 25 years of continuous service from 7% to 8% of annual salary, so long-tenured CSEA employees may carry higher recurring costs than base salary alone shows.")
                    bullet("The agreement increases retiree health-insurance buyback amounts for retirees who decline town-sponsored coverage, which can reduce future premium exposure but must be modeled separately from salary savings.")
                    bullet("For active CSEA employees, the premium-share structure remains important: depending on hire date and service threshold, the town may move from a 75% premium contribution to paying 100% of the premium amount.")
                }

                panelCard(title: "OSC Retirement Rules Context", systemImage: "building.columns.fill") {
                    bullet("OSC's publications page says NYSLRS administers two distinct systems: ERS and PFRS. The employee's system, tier, and retirement plan determine benefits.")
                    bullet("OSC Publication 1505 covers the ERS Tier 2 Basic Plan, not every retirement tier and not police PFRS plans. The Town should separate CSEA/ERS assumptions from PBA and SOA assumptions.")
                    bullet("The Town should use OSC's publication library or plan-publication lookup to match each eligible employee to the correct ERS or PFRS publication before estimating pension-related savings.")
                    bullet("For ERS Tier 2, OSC says final average salary is generally the highest 36 consecutive months of wages. Regular salary, overtime earned in the FAS period, holiday pay, noncompensatory overtime, and limited longevity payments may count.")
                    bullet("OSC also says unused sick leave, termination pay, payments made in anticipation of retirement, deferred-compensation lump sums, and payments for time not worked generally do not count toward FAS.")
                    bullet("For ERS Tier 2 Age 55 plan members, retirement before 62 with less than 30 years of service produces a permanent reduction. At age 55, the listed reduction is 27%; at age 60, 12%; at age 61, 6%.")
                    bullet("If the employer has adopted RSSL Section 41(j), unused unpaid sick leave may create additional service credit at retirement, but OSC says it cannot be used to qualify for vesting or a better benefit calculation.")
                    bullet("For PFRS Tier 3 Article 14 members, OSC says early retirement may be available with 20 years of service regardless of age. That benefit equals 42% of FAS for 20 years plus 4% of FAS for each additional year, capped at 50% of FAS, with a Social Security reduction at age 62 and no escalation.")
                }

                panelCard(title: "Why This Proposal Is Important", systemImage: "exclamationmark.bubble.fill") {
                    bullet("Personnel is usually the largest controllable operating cost, so workforce transition strategy directly affects future budgets.")
                    bullet("A one-time incentive can convert recurring cost pressure into a manageable near-term investment.")
                    bullet("Used carefully, it can avoid blunt measures like across-the-board cuts while still creating measurable savings.")
                    bullet("Used poorly, it can spend fund balance for a short-term tax claim without proving recurring savings, service continuity, or reserve stability.")
                }

                panelCard(title: "What It Does For The Town", systemImage: "building.2.crop.circle.fill") {
                    HStack(spacing: 8) {
                        kpiPill("Annual savings", value: annualGrossSavings, positive: true)
                        kpiPill(
                            "Break-even",
                            text: breakEvenYears.isFinite
                                ? "\(breakEvenYears.formatted(.number.precision(.fractionLength(2)))) yrs"
                                : "N/A"
                        )
                    }

                    bullet("Creates predictable savings after break-even that can support tax stabilization, reserve health, or service investments.")
                    bullet("Lets the town reshape staffing over time by selectively refilling positions based on service priorities.")
                    bullet("Improves budget planning by making the upfront cost and multi-year payoff transparent.")
                }

                panelCard(title: "Public Questions Before Adoption (some now answered)", systemImage: "questionmark.circle.fill") {
                    bullet("What is the total upfront cost, including incentive payments, accrued leave, health insurance effects, pension impacts, overtime, and transition coverage? — The Town declined to give a gross cost estimate until it knows which of the 53 eligible employees opt in.")
                    bullet("How many CSEA, PBA, and SOA employees are eligible under the age and service filter, and how many are assumed to participate? — ANSWERED: 53 total (29 CSEA, 18 PBA, 6 SOA), per the Town's July 2026 ratification. Participation itself remains unknown until the September 1, 2026 deadline.")
                    bullet("For CSEA, how do the 2026-2029 wage actions, 25-year longevity increase, promotion guarantee, retiree buyback changes, and active/retiree health-premium rules change the payback period?")
                    bullet("Which eligible employees are ERS or PFRS, what tier are they in, and which OSC retirement-plan publication applies to each group?")
                    bullet("For police employees, which candidates are PFRS Article 14 Tier 3, which are in 20-year or 25-year plans, and which benefit formula applies?")
                    bullet("Which positions would be refilled, held vacant, consolidated, or eliminated? — The Town says all vacated positions are expected to be refilled.")
                    bullet("Does the claimed taxpayer savings come from recurring payroll savings, one-time fund balance, surplus interest earnings, or a mix? — UPDATED: the Town's official estimate at ratification is $500,000–$800,000/yr, depending on uptake — lower than the up-to-$1.7M figure floated during the May/June 2026 proposal stage. The bridge between payroll savings and levy savings still isn't shown line by line.")
                    bullet("What fund-balance level remains after the payout, and does it preserve capital projects, grant matches, and bond-rating strength?")
                    bullet("Should the budgetary portion of the plan be discussed in a public work session before any executive-session labor negotiation details are resolved?")
                }

                panelCard(title: "Riverhead ERI History: 2019 vs. 2026", systemImage: "clock.arrow.circlepath") {
                    bullet("Riverhead previously offered early retirement incentives in 2010 for CSEA employees, 2012 for PBA members, and 2019 during CSEA contract negotiations (resolution 2019-538).")
                    bullet("The 2019 program was CSEA-only: 48 months of fully paid family health-insurance premiums (or $600/month for 48 months on individual coverage). Payroll records confirm 9 CSEA employees actually retired in 2019, versus a Town/union estimate of 15–20.")
                    bullet("The 2026 program is structurally different: CSEA AND the police unions (PBA, SOA) are covered, and the benefit is CASH ($12,500 flat for CSEA; $1,000/yr of service + sick payout for police) instead of a multi-year health-premium promise.")
                    bullet("No double-counting: 2026 eligibility is drawn only from employees still active on the 2025 payroll. A name-by-name check confirms none of the 9 CSEA employees who retired in 2019 appear in the 2026 eligible list — they already retired and can't take a second incentive.")
                    bullet("The 2010 and 2012 incentives were adopted by Town Board resolution after public hearings.")
                }

                panelCard(title: "Scenario Inputs", systemImage: "slider.horizontal.3") {
                    if !inputWarnings.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(inputWarnings, id: \.self) { warning in
                                Label(warning, systemImage: "exclamationmark.triangle.fill")
                                    .font(.footnote)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(.bottom, 4)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick scenario")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Scenario", selection: $selectedPreset) {
                            ForEach(ERIScenarioPreset.allCases) { preset in
                                Text(preset.title).tag(preset)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedPreset) { _, newValue in
                            applyPreset(newValue)
                        }
                    }

                    Stepper("Expected participants: \(Int(participants))", value: $participants, in: 1...250, step: 1)
                    MoneyField(title: "Average current salary", value: $averageSalary)
                    RateSliderField(title: "Current benefits load", value: $averageCurrentBenefitsRate, range: 0.10...0.80)
                    RateSliderField(title: "Positions refilled", value: $replacementRate, range: 0.00...1.00)
                    RateSliderField(title: "Replacement salary vs. exiting pay", value: $replacementSalaryFactor, range: 0.40...1.00)
                    RateSliderField(title: "Replacement benefits load", value: $replacementBenefitsRate, range: 0.10...0.70)
                    MoneyField(title: "One-time incentive per participant", value: $incentivePerParticipant)
                    MoneyField(title: "Accrued leave payout per participant", value: $accruedLeavePayoutPerParticipant)
                }

                panelCard(title: "Town Savings Snapshot", systemImage: "chart.line.uptrend.xyaxis.circle.fill") {
                    resultRow("Current annual cost (exiting staff)", value: annualCurrentCost)
                    resultRow("Annual replacement cost", value: annualReplacementCost)
                    resultRow("Gross annual savings", value: annualGrossSavings, emphasize: true)
                    resultRow("Total one-time program cost", value: totalUpfrontCost)
                    resultRow("Net after 3 years", value: netSavings(after: 3), positiveIsGood: true)
                    resultRow("Net after 5 years", value: netSavings(after: 5), positiveIsGood: true)
                }

                panelCard(title: "Realistic Backfill & the Police Promotion Chain", systemImage: "arrow.triangle.branch") {
                    bullet("A step-based backfill (refilling each vacated job at the entry step of the actual salary schedule, not a flat 20% discount) puts realistic annual salary savings at about $702,449/yr across the 20 eligible positions where an entry step is clearly identifiable. (Uses the 2026 Academy step, $53,350, per the signed PBA contract — a rookie hired in 2026 is hired at the 2026 rate, not 2025's.)")
                    bullet("Police are the largest single driver: a top-step police officer earns about $150,351 (2026 contract rate), while a new officer starts near $53,350 — about $97,000 saved per position, every year.")
                    bullet("But a RANKED retirement (sergeant, lieutenant, detective) can't be backfilled by a rookie of that rank — the Town still needs a sergeant. It triggers a promotion chain: a senior officer moves up, and the rookie is hired at the bottom. The real saving is a top-step officer minus a rookie (~$97,001), not the retiree's own rank salary minus a rookie (a naive claim of ~$131,677 for a sergeant, using the SOA contract's 2026 top step of $185,027, overstates it).")
                    bullet("Across the 24 eligible police (12 rank-and-file officers + 12 ranked), realistic recurring savings total about $1,823,597/yr if every position is refilled — $659,585 from officers plus $1,164,012 from the ranked promotion chain.")
                    bullet("A retirement isn't always \"replace with a rookie\": a vacancy can also be filled by promotion (shrinking the saving), a lateral transfer (moving the gap elsewhere), or elimination/restructuring (increasing the saving). Treat these figures as one illustrative path, not a guaranteed result.")
                }

                panelCard(title: "Retiree Healthcare (OPEB) — The Missing Piece", systemImage: "cross.case.fill") {
                    bullet("These savings figures count SALARY only. Retirees keep Town-subsidized health coverage for life — an \"OPEB\" cost the Town already carries at $152,597,117 (2023 audit), the largest single audited liability on the books.")
                    bullet("In 2023 the Town paid $3,552,558 for 211 retirees' health coverage — about $17,000 each per year — against 306 active employees.")
                    bullet("Two effects shrink the salary-only savings: (1) the buyout pulls each new retiree's ~$17k/yr lifetime health cost forward, and (2) if the position is refilled, the Town pays health coverage for BOTH the retiree and the new active employee — so healthcare spending for that slot can nearly double even as salary falls.")
                    bullet("Example: a police officer's ~$60k/yr salary saving minus ~$17k/yr of added retiree health is closer to ~$43k/yr net. For a lower-paid CSEA role, the health cost can offset most or all of the salary saving.")
                    bullet("Tellingly, the Town's 2019 CSEA incentive WAS retiree healthcare — 48 months of paid premiums — which is exactly why this cost is so large.")
                }

                panelCard(title: "Possible Deal Structures", systemImage: "doc.text.magnifyingglass") {
                    DealStructureCard(
                        title: "Flat Buyout + Full Separation",
                        details: "Fixed cash incentive plus normal leave payout, with a firm retirement date.",
                        watchFor: "Simple and auditable, but highest first-year cash need."
                    )

                    DealStructureCard(
                        title: "Tiered Incentive by Service/Title",
                        details: "Higher incentives for harder-to-replace roles or longer service.",
                        watchFor: "Needs objective, transparent criteria to avoid grievances."
                    )

                    DealStructureCard(
                        title: "Deferred Installments",
                        details: "Split payment over two fiscal years to reduce budget shock.",
                        watchFor: "Requires tighter legal language around eligibility and clawback terms."
                    )

                    DealStructureCard(
                        title: "Refill-Control Package",
                        details: "Retirement offer paired with explicit refill caps by department.",
                        watchFor: "Savings depend on discipline in hiring approvals after departures."
                    )
                }

                panelCard(title: "Implementation Notes", systemImage: "checklist") {
                    bullet("Validate plan design with counsel, NYSLRS/PFRS rules, and labor agreements before final terms.")
                    bullet("Model police, highway, and specialized departments separately where backfill rates may be higher.")
                    bullet("For ranked jobs (police sergeants, lieutenants, detectives), don't credit the retiree's full salary as savings: the rank must stay filled, so a retirement sets off a promotion chain and only the bottom seat turns over. The recurring saving is a top-step officer minus a rookie (about $97k), not the sergeant's salary minus a rookie (about $132k).")
                    bullet("Include transition costs (overtime, training, equipment) in the final policy memo.")
                    bullet("Publish clear eligibility windows and governance to keep the process fair and defensible.")
                    bullet("Separate executive-session negotiation details from the public budget math so residents can see cost, funding source, payback period, and reserve impact.")
                }

                panelCard(title: "Disclaimer", systemImage: "exclamationmark.triangle.fill") {
                    Text("The 2026 Voluntary Retirement Incentive Program was ratified by the Town Board on July 7, 2026. The official eligible count is 53 (29 CSEA, 18 PBA, 6 SOA); the 78-employee figure elsewhere on this page is our own hire-date/union upper-bound model, kept for comparison. Participation is voluntary and unknown until the September 1, 2026 election deadline. The sliders below remain a what-if tool for exploring your own assumptions about participation, backfill, and cost — they do not represent an official Town projection.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background((scheme == .dark ? Color.black : RiverheadTheme.Surface.page).ignoresSafeArea())
        .navigationTitle("Early Retirement Incentive")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 42, height: 42)
                    Image(systemName: "person.3.sequence.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Early Retirement Budget Proposal")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("A planning tool to test whether a one-time payout can produce recurring savings without weakening reserves or hiding labor costs.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                kpiPill("Participants", text: "\(Int(participants))")
                kpiPill("3-year net", value: netSavings(after: 3), positive: true)
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [RiverheadTheme.brandBlue, RiverheadTheme.brandSky],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .shadow(color: .black.opacity(scheme == .dark ? 0.5 : 0.16), radius: 12, x: 0, y: 8)
    }

    @ViewBuilder
    private func panelCard<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(RiverheadTheme.accent)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(cardBorder)
        )
    }

    @ViewBuilder
    private func resultRow(
        _ title: String,
        value: Double,
        emphasize: Bool = false,
        positiveIsGood: Bool = false
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value, format: .currency(code: "USD"))
                .fontWeight(emphasize ? .semibold : .regular)
                .foregroundStyle(colorForResult(value: value, positiveIsGood: positiveIsGood))
        }
        .font(.subheadline)
    }

    @ViewBuilder
    private func kpiPill(_ label: String, value: Double, positive: Bool = false) -> some View {
        kpiPill(label, text: value.formatted(.currency(code: "USD")), positive: positive && value >= 0)
    }

    private func kpiPill(_ label: String, text: String, positive: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(positive ? Color.green : RiverheadTheme.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
    }

    private func colorForResult(value: Double, positiveIsGood: Bool) -> Color {
        guard positiveIsGood else { return .primary }
        if value > 0 { return .green }
        if value < 0 { return .red }
        return .secondary
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .padding(.top, 6)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
        }
        .padding(.vertical, 2)
    }

    private func applyPreset(_ preset: ERIScenarioPreset) {
        switch preset {
        case .conservative:
            replacementRate = 0.90
            replacementSalaryFactor = 0.82
            averageCurrentBenefitsRate = 0.40
            replacementBenefitsRate = 0.35
            incentivePerParticipant = 35_000
            accruedLeavePayoutPerParticipant = 20_000
        case .balanced:
            replacementRate = 0.75
            replacementSalaryFactor = 0.72
            averageCurrentBenefitsRate = 0.42
            replacementBenefitsRate = 0.34
            incentivePerParticipant = 30_000
            accruedLeavePayoutPerParticipant = 18_000
        case .aggressive:
            replacementRate = 0.55
            replacementSalaryFactor = 0.66
            averageCurrentBenefitsRate = 0.44
            replacementBenefitsRate = 0.32
            incentivePerParticipant = 27_500
            accruedLeavePayoutPerParticipant = 16_000
        }
    }
}

private enum ERIScenarioPreset: String, CaseIterable, Identifiable {
    case conservative
    case balanced
    case aggressive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .conservative: return "Conservative"
        case .balanced: return "Balanced"
        case .aggressive: return "Aggressive"
        }
    }
}

private struct MoneyField: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, value: $value, format: .currency(code: "USD"))
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
    }
}

private struct RateSliderField: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value, format: .percent.precision(.fractionLength(1)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: 0.01)
                .tint(RiverheadTheme.accent)
        }
    }
}

private struct DealStructureCard: View {
    let title: String
    let details: String
    let watchFor: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(details)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("Watch for: \(watchFor)")
                .font(.footnote)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        EarlyRetirementIncentiveView()
    }
}
