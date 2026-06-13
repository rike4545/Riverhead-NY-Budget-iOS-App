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

                panelCard(title: "Current Status", systemImage: "megaphone.fill") {
                    bullet("On May 26, 2026, Supervisor Jerry Halpin publicly proposed an early retirement incentive and said it could potentially save taxpayers up to 3% in 2027 and create savings over five years.")
                    bullet("A May 2026 Times Review report says the supervisor's office identified 32 eligible employees and projected up to $1.7M in annual savings, with each 1% tax decrease estimated at roughly $550,000.")
                    bullet("Against the January 2026 salary-resolution payroll, 3% of payroll is about $915,000. That means the public $1.7M savings claim would exceed a 3% payroll target, but only if backfill, overtime, and fringe assumptions hold.")
                    bullet("No final agreement or Town Board resolution is in place in this model. The proposal still needs union discussion, public cost details, and board review.")
                    bullet("The proposal is expected to use an age and service filter and a one-time payout, but the exact eligibility rules, payout amount, participant count, and backfill plan have not been released.")
                    bullet("The financial administrator said one goal is predictability: eligible employees may already be entitled to accrued-time payouts, but timing those retirements in advance would help the Town budget the obligation.")
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

                panelCard(title: "Public Questions Before Adoption", systemImage: "questionmark.circle.fill") {
                    bullet("What is the total upfront cost, including incentive payments, accrued leave, health insurance effects, pension impacts, overtime, and transition coverage?")
                    bullet("How many CSEA, PBA, and SOA employees are eligible under the age and service filter, and how many are assumed to participate?")
                    bullet("For CSEA, how do the 2026-2029 wage actions, 25-year longevity increase, promotion guarantee, retiree buyback changes, and active/retiree health-premium rules change the payback period?")
                    bullet("Which eligible employees are ERS or PFRS, what tier are they in, and which OSC retirement-plan publication applies to each group?")
                    bullet("For police employees, which candidates are PFRS Article 14 Tier 3, which are in 20-year or 25-year plans, and which benefit formula applies?")
                    bullet("Which positions would be refilled, held vacant, consolidated, or eliminated?")
                    bullet("Does the claimed 3% taxpayer savings come from recurring payroll savings, one-time fund balance, surplus interest earnings, or a mix? The Times Review report cites up to $1.7M in annual savings and about $550,000 per 1% tax decrease, so the bridge between payroll savings and levy savings should be shown line by line.")
                    bullet("What fund-balance level remains after the payout, and does it preserve capital projects, grant matches, and bond-rating strength?")
                    bullet("Should the budgetary portion of the plan be discussed in a public work session before any executive-session labor negotiation details are resolved?")
                }

                panelCard(title: "Riverhead ERI History", systemImage: "clock.arrow.circlepath") {
                    bullet("Riverhead previously offered early retirement incentives in 2010 for CSEA employees, 2012 for PBA members, and 2019 during CSEA contract negotiations.")
                    bullet("RiverheadLOCAL reported the 2019 CSEA incentive applied to an estimated 15 to 20 eligible unit members, with employees choosing between 48 months of fully paid family health-insurance premiums or $600 per month for 48 months if enrolled in individual coverage.")
                    bullet("The 2019 CSEA contract also had raises reported as 2.5% in 2019, 2.25% in 2020, 2.25% in 2021, and 1.5% in 2022 when step movement was included.")
                    bullet("The 2010 and 2012 incentives were adopted by Town Board resolution after public hearings.")
                    bullet("That history supports treating the current proposal as both a labor matter and a public budget decision.")
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
                    bullet("Include transition costs (overtime, training, equipment) in the final policy memo.")
                    bullet("Publish clear eligibility windows and governance to keep the process fair and defensible.")
                    bullet("Separate executive-session negotiation details from the public budget math so residents can see cost, funding source, payback period, and reserve impact.")
                }

                panelCard(title: "Disclaimer", systemImage: "exclamationmark.triangle.fill") {
                    Text("This is a planning and what-if analysis only. As of May 27, 2026, the Town Board has not adopted an Early Retirement Incentive program in this app, and the released public information does not include final cost, eligibility, payout, participation, or backfill details.")
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
