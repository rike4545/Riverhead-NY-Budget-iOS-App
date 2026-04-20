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

                panelCard(title: "Why This Proposal Is Important", systemImage: "exclamationmark.bubble.fill") {
                    bullet("Personnel is usually the largest controllable operating cost, so workforce transition strategy directly affects future budgets.")
                    bullet("A one-time incentive can convert recurring cost pressure into a manageable near-term investment.")
                    bullet("Used carefully, it can avoid blunt measures like across-the-board cuts while still creating measurable savings.")
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

                panelCard(title: "Scenario Inputs", systemImage: "slider.horizontal.3") {
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
                }

                panelCard(title: "Disclaimer", systemImage: "exclamationmark.triangle.fill") {
                    Text("This is a planning and what-if analysis only. As of February 21, 2026, the Town Board has not adopted an Early Retirement Incentive program in this app.")
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
                    Text("A planning tool to test how one-time incentives can reduce long-run payroll pressure and improve fiscal flexibility.")
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
