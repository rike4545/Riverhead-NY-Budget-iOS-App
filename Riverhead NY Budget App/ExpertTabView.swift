//
//  ExpertTabView.swift
//  Riverhead NY Budget App
//  Swift 6 / iOS 17+
//

import SwiftUI
import Foundation
import Observation

// MARK: - Local Store (self-contained; no RBBudgetStore references)
@Observable
fileprivate final class ExpertStore {
    // Municipality & policy
    var municipalityName: String = "Town of Riverhead"
    var minUnassignedPercent: Double = 0.15
    var targetUpperPercent: Double? = 0.288
    var gfoaFloorPercent: Double = 0.167
    var policyNotes: String = "Minimum unassigned fund balance of 15% of next-year appropriations."
    var policyYears: Int? = 3
    var fiscalYearLabel: String = "2026 Adopted Budget"

    // Fund balance snapshot
    var appropriations: Double = 69_113_159
    var estimatedFundBalance: Double = 28_403_924

    // Quick taxes
    var ratePerThousand: Double = 22.50

    // Tax cap inputs (illustrative)
    var priorYearLevy: Double = 10_000_000
    var cpiPercent: Double = 2.00
    var tbgf: Double = 1.0072
    var carryover: Double = 0
    var capitalExclusions: Double = 0
    var pilots: Double = 0

    @MainActor
    func sync(from budgetStore: RBBudgetStore) {
        municipalityName = "Town of Riverhead"
        minUnassignedPercent = budgetStore.fundBalancePolicy.minimumPercent
        targetUpperPercent = budgetStore.fundBalancePolicy.targetUpperPercent ?? 0.288
        policyYears = budgetStore.fundBalancePolicy.replenishYears
        policyNotes = budgetStore.fundBalancePolicy.notes.isEmpty
            ? "Minimum unassigned fund balance of 15% of next-year appropriations, with a stronger practical operating range above the floor."
            : budgetStore.fundBalancePolicy.notes
        fiscalYearLabel = budgetStore.fiscalYearTitle
        appropriations = budgetStore.appropriations
        estimatedFundBalance = budgetStore.estimatedFundBalance
        ratePerThousand = budgetStore.ratePerThousand
    }
}

// MARK: - Shared formatters (cached)
fileprivate enum Fmt {
    static let currency: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.maximumFractionDigits = 0
        nf.currencyCode = Locale.current.currency?.identifier ?? "USD"
        return nf
    }()
    static let percent1: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .percent
        nf.maximumFractionDigits = 1
        return nf
    }()
    static let num2: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        return nf
    }()
    static let num4: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 4
        return nf
    }()
}

// MARK: - Segments
fileprivate enum ExpertSegment: String, CaseIterable, Identifiable {
    case fundBalance, taxCap, quickTaxes, references
    var id: String { rawValue }
    var title: String {
        switch self {
        case .fundBalance: return "Fund Balance"
        case .taxCap:      return "Tax Cap"
        case .quickTaxes:  return "Quick Taxes"
        case .references:  return "References"
        }
    }
    var icon: String {
        switch self {
        case .fundBalance: return "shield.lefthalf.filled"
        case .taxCap:      return "chart.xyaxis.line"
        case .quickTaxes:  return "house.and.flag"
        case .references:  return "book.pages"
        }
    }
    var subtitle: String {
        switch self {
        case .fundBalance: return "Reserve posture, floors, and deployment discipline."
        case .taxCap: return "Override pressure, levy room, and simplified cap math."
        case .quickTaxes: return "Town-only tax estimate with quick sensitivity inputs."
        case .references: return "Official links, reminders, and source framing."
        }
    }
}

// MARK: - Root View
@MainActor
public struct ExpertTabView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(RBBudgetStore.self) private var budgetStore

    @State private var store = ExpertStore()
    @State private var selected: ExpertSegment = .fundBalance

    public init() {}

    private var pageBackground: Color {
        scheme == .dark
        ? Color.black.opacity(0.98)
        : RiverheadTheme.Surface.page
    }

    public var body: some View {
        VStack(spacing: 12) {
            header
            snapshotStrip

            // Mode picker
            Picker("Mode", selection: $selected) {
                ForEach(ExpertSegment.allCases) { seg in
                    Label(seg.title, systemImage: seg.icon)
                        .labelStyle(.titleAndIcon)
                        .tag(seg)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .tint(RiverheadTheme.tint)

            HStack(alignment: .center, spacing: 8) {
                Image(systemName: selected.icon)
                    .foregroundStyle(RiverheadTheme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(selected.title)
                        .font(.headline)
                    Text(selected.subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal)

            // Active panel
            Group {
                switch selected {
                case .fundBalance:
                    FundBalancePanel(store: store)
                case .taxCap:
                    TaxCapPanel(store: store)
                case .quickTaxes:
                    QuickTaxesPanel(store: store)
                case .references:
                    ReferencesPanel(store: store)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
        .padding(.top, 8)
        .background(pageBackground.ignoresSafeArea())
        .task {
            store.sync(from: budgetStore)
        }
        .onChange(of: budgetStore.appropriations) { _, _ in
            store.sync(from: budgetStore)
        }
        .onChange(of: budgetStore.estimatedFundBalance) { _, _ in
            store.sync(from: budgetStore)
        }
        .onChange(of: budgetStore.ratePerThousand) { _, _ in
            store.sync(from: budgetStore)
        }
        .onChange(of: budgetStore.fiscalYearTitle) { _, _ in
            store.sync(from: budgetStore)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Expert View")
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundStyle(scheme == .dark ? .white : .primary)

                Text("Beta")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.thinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(RiverheadTheme.border.opacity(0.4), lineWidth: 0.5)
                    )
            }

            Text("A sharper Riverhead budget workbench for reserve policy, levy pressure, and Town-only tax math. Use it to stress-test claims before or after hearings.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal)
    }

    private var snapshotStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ExpertMetric("Budget year", value: store.fiscalYearLabel, tint: RiverheadTheme.accent)
                ExpertMetric("Appropriations", value: Fmt.currency.string(from: store.appropriations as NSNumber) ?? "—", tint: RiverheadTheme.gold)
                ExpertMetric("Fund balance", value: Fmt.currency.string(from: store.estimatedFundBalance as NSNumber) ?? "—", tint: .green)
                ExpertMetric("Town rate", value: "$" + (Fmt.num2.string(from: store.ratePerThousand as NSNumber) ?? "—"), tint: RiverheadTheme.brandSky)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Fund Balance Panel
fileprivate struct FundBalancePanel: View {
    @Environment(\.colorScheme) private var scheme
    @Bindable var store: ExpertStore

    private var minimumRequired: Double { max(0, store.appropriations * store.minUnassignedPercent) }
    private var targetUpper: Double? {
        guard let percent = store.targetUpperPercent else { return nil }
        return max(0, store.appropriations * percent)
    }
    private var gfoaFloor: Double { max(0, store.appropriations * store.gfoaFloorPercent) }
    private var surplus: Double { store.estimatedFundBalance - minimumRequired }
    private var fundBalanceRatio: Double {
        guard store.appropriations > 0 else { return 0 }
        return store.estimatedFundBalance / store.appropriations
    }
    private var minimumCoverageProgress: Double {
        let ratio = store.estimatedFundBalance / max(minimumRequired, 1)
        return normalizedProgress(ratio)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Title + status chips
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.municipalityName)
                            .font(.title2.weight(.semibold))
                        Text("Policy minimum vs. estimated unassigned fund balance")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing, spacing: 4) {
                        statusChip
                        ratioChip
                    }
                }
                .padding(.horizontal)

                // Metrics card
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        LabeledContent("Appropriations") {
                            Text(Fmt.currency.string(from: store.appropriations as NSNumber) ?? "—")
                                .monospacedDigit()
                                .fontWeight(.semibold)
                        }
                        LabeledContent("Est. Fund Balance (12/31)") {
                            Text(Fmt.currency.string(from: store.estimatedFundBalance as NSNumber) ?? "—")
                                .monospacedDigit()
                                .fontWeight(.semibold)
                        }
                        LabeledContent("Policy Minimum (\(Fmt.percent1.string(from: store.minUnassignedPercent as NSNumber) ?? "—"))") {
                            Text(Fmt.currency.string(from: minimumRequired as NSNumber) ?? "—")
                                .monospacedDigit()
                        }
                        LabeledContent("GFOA-style Floor (~\(Fmt.percent1.string(from: store.gfoaFloorPercent as NSNumber) ?? "—"))") {
                            Text(Fmt.currency.string(from: gfoaFloor as NSNumber) ?? "—")
                                .monospacedDigit()
                        }
                        if let targetUpper {
                            LabeledContent("Riverhead Target (\(Fmt.percent1.string(from: (store.targetUpperPercent ?? 0) as NSNumber) ?? "—"))") {
                                Text(Fmt.currency.string(from: targetUpper as NSNumber) ?? "—")
                                    .monospacedDigit()
                            }
                        }
                        Divider()
                        LabeledContent(surplus >= 0 ? "Cushion above Minimum" : "Shortfall to Minimum") {
                            Text(Fmt.currency.string(from: abs(surplus) as NSNumber) ?? "—")
                                .monospacedDigit()
                                .fontWeight(.semibold)
                                .foregroundStyle(surplus >= 0 ? .green : .orange)
                        }
                        RatioBar(
                            title: "Coverage of minimum",
                            progress: minimumCoverageProgress,
                            tint: surplus >= 0 ? .green : .orange
                        )
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Riverhead Guidance")
                            .font(.headline)

                        Text("Treat the 15% policy floor as the legal minimum, not the automatic destination. A stronger Riverhead operating range sits above the floor, with the 28.8% target acting as a moderation point between minimum compliance and reserve overaccumulation.")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        if let targetUpper {
                            let deployable = max(store.estimatedFundBalance - targetUpper, 0)
                            LabeledContent("One-time room above target") {
                                Text(Fmt.currency.string(from: deployable as NSNumber) ?? "—")
                                    .monospacedDigit()
                                    .fontWeight(.semibold)
                                    .foregroundStyle(deployable > 0 ? .green : .secondary)
                            }
                        }

                        Text("Expert framing: ask whether reserve use corrects imbalances, reduces future debt pressure, or backfills recurring costs that should instead be budgeted openly.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                // Explanation card
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What the Cushion Means")
                            .font(.headline)

                        Text("""
The “cushion above the minimum” is the portion of unassigned fund balance above your policy floor (for example, 15% of next-year appropriations). It can be used flexibly, ideally for one-time needs such as emergencies, tax stabilization, equipment, timing gaps, or seeding reserves, so you don’t create new structural costs.

Using only the cushion simply shrinks how much cushion you carry forward; it does not need to be “repaid” if you stay at or above the minimum. If spending pushes you below the floor, the policy’s replenishment plan (for example, restoring the minimum over a set number of years) kicks in and is usually met through planned surpluses, controlled spending, or revenue growth.
"""
                        )
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Plain-language explanation of the cushion above the minimum and how replenishment policies typically work.")
                    }
                }

                // Compliance & history card
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Compliance & History")
                            .font(.headline)

                        Text("""
Public reports and commentary have raised questions about how consistently the Town has followed its own fund balance policy and how often it has adopted local laws overriding the New York State property tax cap. Some sources note that earlier policy revisions were discussed but not formally adopted, and that the Town’s independent auditors have flagged cap-calculation issues in past reports.
"""
                        )
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                        Text("Always confirm details directly in the Town’s adopted budgets, local laws, and audited financial statements.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Community note & petition
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Community Note")
                            .font(.headline)

                        Text("""
Some residents argue that the Town should revisit, clarify, and modernize its fund balance policy to better match current best practices and its own recent history.

Residents are also organizing around the Long Island Science Center, arguing that Riverhead should work with the downtown STEM museum before using eminent domain. Read together, the two petitions point to the same governance question: when a public decision affects reserves, taxes, land, or civic institutions, the Town should show the policy rule, funding source, and public alternative before acting.
"""
                        )
                        .font(.callout)
                        .foregroundStyle(.secondary)

                        Link(
                            destination: TownSquareCoreTerms.fundBalancePetitionURL
                        ) {
                            Label("Petition: Revise Riverhead’s Fund Balance Policy", systemImage: "link")
                                .font(.subheadline.weight(.semibold))
                        }
                        .tint(RiverheadTheme.tint)

                        Link(
                            destination: TownSquareCoreTerms.scienceCenterPetitionURL
                        ) {
                            Label("Petition: Save the Long Island Science Center", systemImage: "link")
                                .font(.subheadline.weight(.semibold))
                        }
                        .tint(RiverheadTheme.tint)
                    }
                }

                // What-if controls
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What-if: Adjust Inputs")
                            .font(.headline)

                        Stepper(
                            value: $store.appropriations,
                            in: 0...1_000_000_000,
                            step: 50_000
                        ) {
                            HStack {
                                Text("Appropriations")
                                Spacer()
                                Text(Fmt.currency.string(from: store.appropriations as NSNumber) ?? "—")
                                    .monospacedDigit()
                            }
                        }

                        Stepper(
                            value: $store.estimatedFundBalance,
                            in: 0...1_000_000_000,
                            step: 50_000
                        ) {
                            HStack {
                                Text("Est. Fund Balance")
                                Spacer()
                                Text(Fmt.currency.string(from: store.estimatedFundBalance as NSNumber) ?? "—")
                                    .monospacedDigit()
                            }
                        }
                    }
                }

                if let years = store.policyYears, !store.policyNotes.isEmpty {
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Policy Notes")
                                .font(.headline)

                            Text(store.policyNotes)
                                .font(.callout)
                                .foregroundStyle(.secondary)

                            Text("Typical replenishment timeline: \(years) year\(years == 1 ? "" : "s").")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Status Chips

    private var statusChip: some View {
        HStack(spacing: 6) {
            Circle()
                .frame(width: 8, height: 8)
                .foregroundStyle(surplus >= 0 ? .green : .orange)

            Text(surplus >= 0 ? "Above minimum" : "Below minimum")
                .font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(scheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
        )
    }

    private var ratioChip: some View {
        let pct = Fmt.percent1.string(from: fundBalanceRatio as NSNumber) ?? "—"

        return Text("\(pct) of appropriations")
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.4), lineWidth: 0.5)
            )
    }
}

// MARK: - Tax Cap Panel (illustrative)
fileprivate struct TaxCapPanel: View {
    @Bindable var store: ExpertStore
    @State private var proposedLevy: Double = 10_500_000

    private var levyLimit: Double {
        let cappedCPI = min(max(store.cpiPercent, 0.0), 2.0) / 100.0
        let base = max(0, store.priorYearLevy) * store.tbgf
        let growth = base * (1.0 + cappedCPI)
        return max(0, growth + store.carryover + store.capitalExclusions - store.pilots)
    }
    private var overAmount: Double { max(0, proposedLevy - levyLimit) }
    private var needsOverride: Bool { proposedLevy > levyLimit }
    private var headroomPercent: Double {
        guard levyLimit > 0 else { return 0 }
        return (levyLimit - proposedLevy) / levyLimit
    }
    private var levyProgress: Double {
        let ratio = proposedLevy / max(levyLimit, 1)
        return normalizedProgress(ratio)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Inputs (illustrative)")
                            .font(.headline)

                        moneyStepper("Prior-Year Levy", value: $store.priorYearLevy, step: 50_000)
                        numberStepper("CPI %", value: $store.cpiPercent, step: 0.10, fmt: Fmt.num2, suffix: "%")
                        numberStepper("TBGF",  value: $store.tbgf,       step: 0.0001, fmt: Fmt.num4)
                        moneyStepper("Carryover",          value: $store.carryover,         step: 10_000)
                        moneyStepper("Capital Exclusions", value: $store.capitalExclusions, step: 10_000)
                        moneyStepper("PILOTs",             value: $store.pilots,            step: 10_000)

                        Divider().padding(.vertical, 4)

                        moneyStepper("Proposed Levy", value: $proposedLevy, step: 50_000)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Result")
                            .font(.headline)

                        LabeledContent("Computed Levy Limit") {
                            Text(Fmt.currency.string(from: levyLimit as NSNumber) ?? "—")
                                .monospacedDigit()
                                .font(.title3.weight(.semibold))
                        }

                        LabeledContent("Status") {
                            if needsOverride {
                                Label("Override required", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                            } else {
                                Label("Within cap", systemImage: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                            }
                        }

                        if needsOverride {
                            Text("Over cap by \(Fmt.currency.string(from: overAmount as NSNumber) ?? "—").")
                                .foregroundStyle(.secondary)
                        } else {
                            let pct = Fmt.percent1.string(from: headroomPercent as NSNumber) ?? "—"
                            Text("Headroom below the limit: \(pct).")
                                .foregroundStyle(.secondary)
                        }

                        RatioBar(
                            title: "Proposed levy vs. limit",
                            progress: levyProgress,
                            tint: needsOverride ? .orange : .green
                        )

                        Text("This is a simplified illustration of New York’s property tax cap formula and should be cross-checked against NYS OSC guidance and actual Town calculations.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Expert Read")
                            .font(.headline)

                        Text("Riverhead should show both a cap-compliant baseline and any managed override case. If spending growth is exceeding recurring revenue growth, the issue is structural, not just procedural.")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        Text("A Brookhaven-style trigger can help here: tie Town-wide General Fund expenditure growth to the three-year average of revenue growth plus the three-year average population growth rate, then require a public override process to exceed it.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
    }

    // Helpers
    private func moneyStepper(_ title: String, value: Binding<Double>, step: Double) -> some View {
        Stepper(value: value, in: 0...1_000_000_000, step: step) {
            HStack {
                Text(title)
                Spacer()
                Text(Fmt.currency.string(from: value.wrappedValue as NSNumber) ?? "—")
                    .monospacedDigit()
            }
        }
    }

    private func numberStepper(
        _ title: String,
        value: Binding<Double>,
        step: Double,
        fmt: NumberFormatter,
        suffix: String = ""
    ) -> some View {
        Stepper(value: value, in: 0...1_000_000, step: step) {
            HStack {
                Text(title)
                Spacer()
                Text("\(fmt.string(from: value.wrappedValue as NSNumber) ?? "—")\(suffix)")
                    .monospacedDigit()
            }
        }
    }
}

private func normalizedProgress(_ value: Double) -> Double {
    guard value.isFinite else { return 0 }
    return min(max(value, 0), 1)
}

fileprivate struct RatioBar: View {
    let title: String
    let progress: Double
    let tint: Color

    private var safeProgress: Double {
        normalizedProgress(progress)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.16))

                    Capsule()
                        .fill(tint)
                        .frame(width: proxy.size.width * safeProgress)
                }
            }
            .frame(height: 10)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(Fmt.percent1.string(from: safeProgress as NSNumber) ?? "0%")
        }
    }
}

// MARK: - Quick Taxes Panel
fileprivate struct QuickTaxesPanel: View {
    @Bindable var store: ExpertStore
    @State private var assessedValue: Double = 450_000
    @State private var exemptions: Double = 0

    private var taxablePerThousand: Double {
        max(0, (assessedValue - max(0, exemptions)) / 1_000.0)
    }
    private var estimatedTaxes: Double {
        taxablePerThousand * max(0, store.ratePerThousand)
    }
    private var effectiveRatePercent: Double {
        guard assessedValue > 0 else { return 0 }
        return estimatedTaxes / assessedValue
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Inputs")
                            .font(.headline)

                        Stepper(value: $assessedValue, in: 0...5_000_000, step: 1_000) {
                            HStack {
                                Text("Assessed Value")
                                Spacer()
                                Text(Fmt.currency.string(from: assessedValue as NSNumber) ?? "—")
                                    .monospacedDigit()
                            }
                        }

                        Stepper(value: $exemptions, in: 0...5_000_000, step: 500) {
                            HStack {
                                Text("Exemptions")
                                Spacer()
                                Text(Fmt.currency.string(from: exemptions as NSNumber) ?? "—")
                                    .monospacedDigit()
                            }
                        }

                        Stepper(value: $store.ratePerThousand, in: 0...200, step: 0.05) {
                            HStack {
                                Text("Rate per $1,000 (Town)")
                                Spacer()
                                Text(String(format: "%.2f", store.ratePerThousand))
                                    .monospacedDigit()
                            }
                        }
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Estimate")
                            .font(.headline)

                        LabeledContent("Taxable (per $1,000)") {
                            Text(String(format: "%.2f", taxablePerThousand))
                                .monospacedDigit()
                        }

                        LabeledContent("Estimated Town Tax") {
                            Text(Fmt.currency.string(from: estimatedTaxes as NSNumber) ?? "—")
                                .monospacedDigit()
                                .fontWeight(.semibold)
                        }

                        let eff = Fmt.percent1.string(from: effectiveRatePercent as NSNumber) ?? "—"
                        LabeledContent("Effective Town Rate") {
                            Text(eff)
                                .monospacedDigit()
                        }

                        Text("This is a rough Town-only estimate. Your actual bill will also reflect county, school, library, and other jurisdictions, plus final adopted rates and roll data.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - References Panel
fileprivate struct ReferencesPanel: View {
    @Bindable var store: ExpertStore

    var body: some View {
        List {
            Section("Snapshot") {
                LabeledContent("Municipality") {
                    Text(store.municipalityName)
                }
                LabeledContent("Policy Minimum") {
                    Text(Fmt.percent1.string(from: store.minUnassignedPercent as NSNumber) ?? "—")
                }
                LabeledContent("Fund Balance Policy Notes") {
                    Text(store.policyNotes)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Section("Shortcuts") {
                Link(
                    destination: URL(string: "https://www.gfoa.org/materials/fund-balance-guidelines-for-the-general-fund")!
                ) {
                    Label("GFOA — Fund Balance Guidelines", systemImage: "link")
                }

                Link(
                    destination: URL(string: "https://www.osc.ny.gov/local-government/property-tax-cap")!
                ) {
                    Label("NYS OSC — Property Tax Cap", systemImage: "link")
                }

                Link(
                    destination: TownSquareCoreTerms.fundBalancePetitionURL
                ) {
                    Label("Petition: Revise Riverhead’s Fund Balance Policy", systemImage: "link")
                }

                Link(
                    destination: TownSquareCoreTerms.scienceCenterPetitionURL
                ) {
                    Label("Petition: Save the Long Island Science Center", systemImage: "link")
                }
            }

            Section("Reminder") {
                Text("These tools are for education and discussion only. Always rely on the Town’s adopted budgets, local laws, tax rolls, and audited financial statements for official numbers.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(
            Color.black.opacity(0.98) // matches pageBackground in dark; overridden by system in light
        )
        .tint(RiverheadTheme.tint)
    }
}

fileprivate struct ExpertMetric: View {
    let title: String
    let value: String
    let tint: Color

    init(_ title: String, value: String, tint: Color) {
        self.title = title
        self.value = value
        self.tint = tint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
            Capsule()
                .fill(tint.opacity(0.85))
                .frame(width: 34, height: 5)
        }
        .padding(12)
        .frame(width: 170, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(RiverheadTheme.Surface.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.border.opacity(0.25))
        )
    }
}

// MARK: - Card styling (adaptive, dark-mode friendly)
fileprivate struct Card<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private var cardFill: Color {
        if scheme == .dark {
            // Deep navy-ish card so white text pops
            return Color(red: 10/255, green: 14/255, blue: 20/255)
        } else {
            return RiverheadTheme.Surface.card
        }
    }

    private var borderColor: Color {
        if scheme == .dark {
            return Color.white.opacity(0.12)
        } else {
            return RiverheadTheme.border.opacity(0.25)
        }
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(borderColor)
            )
            .shadow(
                color: .black.opacity(scheme == .dark ? 0.55 : 0.10),
                radius: 14,
                x: 0,
                y: 8
            )
    }
}
