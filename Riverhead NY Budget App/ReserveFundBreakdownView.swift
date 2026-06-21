import SwiftUI

// MARK: - Local GlassCard (mirrors the fileprivate one in RiverheadBudgetHubView)

private struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let title: String?
    let subtitle: String?
    @ViewBuilder var content: Content

    init(title: String? = nil, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title).font(.headline).foregroundStyle(RiverheadTheme.textPrimary)
            }
            if let subtitle {
                Text(subtitle).font(.footnote).foregroundStyle(RiverheadTheme.textSecondary)
            }
            content
        }
        .padding(14)
        .background(
            (reduceTransparency
             ? AnyShapeStyle(RiverheadTheme.Surface.card)
             : AnyShapeStyle(scheme == .dark ? .ultraThinMaterial : .regularMaterial)),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.border.opacity(scheme == .dark ? 0.35 : 0.2))
        )
        .shadow(color: .black.opacity(scheme == .dark ? 0.25 : 0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Reserve types under NY law

private struct NYReserveFundType: Identifiable {
    let id = UUID()
    let name: String
    let citation: String      // e.g. "Gen. Municipal Law §6-c"
    let purpose: String
    let withdrawalRule: String
    let interestRule: String
    let tint: Color
}

// MARK: - Main view

@MainActor
struct ReserveFundBreakdownView: View {

    @Environment(RBBudgetStore.self) private var store

    // Segmentation sliders — percentages of appropriations
    @State private var operatingSlider: Double = 0.15   // match policy minimum
    @State private var pensionSlider: Double = 0.05
    @State private var capitalSlider: Double = 0.05

    // MARK: Derived values

    private var unassigned: Double { store.estimatedFundBalance }
    private var appropriations: Double { store.appropriations }
    private var policyMin: Double { appropriations * store.fundBalancePolicy.minimumPercent }
    private var policyMax: Double { appropriations * (store.fundBalancePolicy.targetUpperPercent ?? 0.20) }
    private var currentPercent: Double { guard appropriations > 0 else { return 0 }; return unassigned / appropriations }

    private var operatingBucket: Double { appropriations * operatingSlider }
    private var pensionBucket: Double { appropriations * pensionSlider }
    private var capitalBucket: Double { appropriations * capitalSlider }
    private var allocatedTotal: Double { operatingBucket + pensionBucket + capitalBucket }
    private var unallocated: Double { max(0, unassigned - allocatedTotal) }
    private var overAllocated: Bool { allocatedTotal > unassigned }

    private let nyReserves: [NYReserveFundType] = [
        .init(
            name: "Budget Reserve Fund",
            citation: "Gen. Mun. Law §6-c",
            purpose: "Accumulate funds to meet a budget deficiency or reduce a tax levy. The classic \"rainy day\" reserve — it must be established by local law or resolution, funded by surplus appropriations or levy, and can be drawn down by board resolution.",
            withdrawalRule: "Board resolution required. May be used to fund a budget deficiency or offset a levy increase.",
            interestRule: "Interest must be credited to the reserve fund, not the general fund.",
            tint: .blue
        ),
        .init(
            name: "Repair Reserve Fund",
            citation: "Gen. Mun. Law §6-d",
            purpose: "Set aside money for repairs to capital improvements (roads, buildings, infrastructure). Useful when a town knows maintenance costs will spike in a future year.",
            withdrawalRule: "Board resolution required; must be for repair or reconstruction of capital improvements.",
            interestRule: "Interest credited to reserve. Withdrawals for any unauthorized purpose require a permissive referendum.",
            tint: .orange
        ),
        .init(
            name: "Machinery Reserve Fund",
            citation: "Gen. Mun. Law §6-e",
            purpose: "Accumulate funds to purchase or replace machinery and equipment. Particularly useful for highway departments and public works fleets.",
            withdrawalRule: "Board resolution; must be for purchase of machinery, apparatus, or equipment.",
            interestRule: "Interest stays in the reserve. Cannot exceed actual cost of replacement.",
            tint: .green
        ),
        .init(
            name: "Capital Reserve Fund",
            citation: "Gen. Mun. Law §6-g",
            purpose: "Accumulate money for a specific capital improvement or class of capital improvements. Must have a defined purpose and an authorized maximum amount.",
            withdrawalRule: "Board resolution; must match the stated capital purpose. Excess after project completion may require permissive referendum to redirect.",
            interestRule: "All interest credited to the reserve. No withdrawal for operating expenses.",
            tint: .purple
        ),
        .init(
            name: "Retirement Contribution Reserve",
            citation: "Gen. Mun. Law §6-r",
            purpose: "Smooth out pension-cost volatility. Contributions can be made in flush years and drawn down when NYSLRS rates spike. OSC recommends municipalities with large pension exposure maintain one.",
            withdrawalRule: "Only for employer retirement system contributions. Board resolution required.",
            interestRule: "Interest credited to reserve. OSC recommends documenting a funding policy.",
            tint: .red
        ),
        .init(
            name: "Insurance Reserve Fund",
            citation: "Gen. Mun. Law §6-n",
            purpose: "Fund self-insurance programs (workers' comp, unemployment, tort liability). Must be formally established if the municipality self-insures any risk category.",
            withdrawalRule: "May only be used for the specified self-insurance purpose. Board resolution required.",
            interestRule: "Interest stays in reserve. Annual actuarial review is prudent.",
            tint: .teal
        ),
    ]

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroCard
                    gasb54TierCard
                    segmentationCard
                    nyLawReservesCard
                    oscGuidanceCard
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(RiverheadTheme.background.ignoresSafeArea())
            .navigationTitle("Reserve Fund Breakdown")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Subviews

    private var heroCard: some View {
        GlassCard(
            title: "Riverhead's Reserve Picture (Live)",
            subtitle: "All figures derive from the 2025 Annual Financial Report and 2026 adopted General Fund appropriations."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(unassigned, format: .currency(code: "USD").precision(.fractionLength(0)))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(RiverheadTheme.accent)
                    Spacer()
                    Text(currentPercent, format: .percent.precision(.fractionLength(1)))
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(colorForPercent(currentPercent))
                }
                Text("Unassigned General Fund balance · GASB 54 Tier 5")
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)

                Divider().opacity(0.25)

                policyRow(label: "Policy minimum (15%)", value: policyMin, color: .orange)
                policyRow(label: "Policy upper target (20%)", value: policyMax, color: .green)
                policyRow(label: "Cushion above minimum", value: max(0, unassigned - policyMin), color: .blue)
                policyRow(label: "Cushion above upper target", value: max(0, unassigned - policyMax), color: .purple)

                Text("The full unassigned balance is currently in one undifferentiated pool. Formally establishing named reserves converts portions of this balance into restricted or committed tiers with legal purpose constraints and board-level withdrawal rules.")
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var gasb54TierCard: some View {
        GlassCard(
            title: "GASB 54: The Five Fund Balance Tiers",
            subtitle: "Where Riverhead's General Fund balance sits under GASB Statement No. 54 (required for all NY local governments)."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                tier54Row(
                    number: "1",
                    name: "Nonspendable",
                    color: .gray,
                    definition: "Amounts that cannot be spent — inventory, prepaid items, long-term receivables, permanent-fund corpus.",
                    riverheadContext: "Riverhead's General Fund likely carries minimal nonspendable balance. Specific amounts appear in the audited GAAP financial statements.",
                    amount: nil
                )
                Divider().opacity(0.2)
                tier54Row(
                    number: "2",
                    name: "Restricted",
                    color: .red,
                    definition: "Constrained by external parties: state law, federal grants, bond covenants, or creditors.",
                    riverheadContext: "Formally established reserve funds (§6-c, §6-d, §6-e, etc.) sit here once adopted by resolution. Special district surpluses held in separate funds also appear here.",
                    amount: nil
                )
                Divider().opacity(0.2)
                tier54Row(
                    number: "3",
                    name: "Committed",
                    color: .orange,
                    definition: "Self-imposed constraints set by the highest level of decision-making (Town Board resolution or local law). Can only be released by the same Board action.",
                    riverheadContext: "A Town Board resolution dedicating a portion of fund balance for a specific future capital project or pension buffer would be classified here.",
                    amount: nil
                )
                Divider().opacity(0.2)
                tier54Row(
                    number: "4",
                    name: "Assigned",
                    color: .yellow,
                    definition: "Amounts the Board intends to use for a specific purpose but has not formally committed. An adopted budget that appropriates fund balance moves it here.",
                    riverheadContext: "The 2026 adopted budget's appropriated fund balance use would normally be classified as assigned. Any amount earmarked by resolution for a named project without a formal reserve fund also lands here.",
                    amount: nil
                )
                Divider().opacity(0.2)
                tier54Row(
                    number: "5",
                    name: "Unassigned",
                    color: .green,
                    definition: "The residual — everything not in Tiers 1–4. This is the truly discretionary balance and the figure OSC and GFOA benchmark against appropriations.",
                    riverheadContext: "Riverhead's \(unassigned.formatted(.currency(code: "USD").precision(.fractionLength(0)))) is classified here. It is not broken into sub-buckets by law or resolution, which gives the Board maximum flexibility but also means there is no formal constraint on its use.",
                    amount: unassigned
                )
            }
        }
    }

    private var segmentationCard: some View {
        GlassCard(
            title: "Reserve Segmentation Model",
            subtitle: "What if Riverhead formally divided its unassigned balance into named buckets? Adjust the sliders to model the split."
        ) {
            VStack(alignment: .leading, spacing: 16) {

                segSlider(
                    label: "Operating Stabilization Reserve",
                    hint: "Covers revenue shortfalls, emergency operating costs, and tax-levy smoothing. OSC's Budget Reserve Fund (§6-c) is the legal vehicle.",
                    value: $operatingSlider,
                    dollarAmount: operatingBucket,
                    color: .blue
                )
                segSlider(
                    label: "Pension Stabilization Reserve",
                    hint: "Absorbs NYSLRS rate volatility. OSC's §6-r Retirement Contribution Reserve is the formal vehicle.",
                    value: $pensionSlider,
                    dollarAmount: pensionBucket,
                    color: .red
                )
                segSlider(
                    label: "Capital / Equipment Reserve",
                    hint: "Funds vehicles, facility repairs, and infrastructure without borrowing. §6-e Machinery and §6-g Capital Reserve are the legal vehicles.",
                    value: $capitalSlider,
                    dollarAmount: capitalBucket,
                    color: .green
                )

                Divider().opacity(0.3)

                // Summary waterfall
                VStack(alignment: .leading, spacing: 8) {
                    summaryRow(label: "Total unassigned balance", value: unassigned, color: RiverheadTheme.accent, bold: false)
                    summaryRow(label: "Operating stabilization", value: -operatingBucket, color: .blue, bold: false)
                    summaryRow(label: "Pension stabilization", value: -pensionBucket, color: .red, bold: false)
                    summaryRow(label: "Capital / equipment", value: -capitalBucket, color: .green, bold: false)
                    Divider().opacity(0.2)
                    summaryRow(
                        label: overAllocated ? "Over-allocated — reduce buckets" : "Remaining unallocated",
                        value: overAllocated ? allocatedTotal - unassigned : unallocated,
                        color: overAllocated ? .red : .purple,
                        bold: true
                    )
                }

                if !overAllocated {
                    let residualPct = appropriations > 0 ? unallocated / appropriations : 0
                    Text("The \(unallocated.formatted(.currency(code: "USD").precision(.fractionLength(0)))) residual (\(residualPct.formatted(.percent.precision(.fractionLength(1)))) of appropriations) would remain unassigned — available for one-time uses, levy stabilization, or further formal designation by board resolution.")
                        .font(.caption)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("The modeled buckets exceed the available balance. Reduce one or more sliders.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Text("Note: This is a what-if model only. Formally establishing any of these reserves requires a Town Board resolution, an OSC-prescribed format, and potentially a permissive referendum for some reserve types. No money moves until the Board acts.")
                    .font(.caption2)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var nyLawReservesCard: some View {
        GlassCard(
            title: "Reserve Fund Types Under NY Law",
            subtitle: "New York General Municipal Law authorizes these distinct reserve types for towns. Each has a specific legal purpose, withdrawal procedure, and interest rule."
        ) {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(nyReserves) { r in
                    reserveTypeRow(r)
                    if r.id != nyReserves.last?.id {
                        Divider().opacity(0.2)
                    }
                }
            }
        }
    }

    private var oscGuidanceCard: some View {
        GlassCard(
            title: "OSC Guidance: Reserve Funds",
            subtitle: "The NY State Comptroller publishes a reserve funds guide specifically for local governments."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("OSC's Reserve Funds publication (February 2022) covers: establishing reserves by resolution, deposit limits, authorized investments, interest treatment, and what triggers a permissive referendum. OSC recommends every municipality maintain a written reserve fund policy reviewed annually by the Board.")
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider().opacity(0.2)

                Link(destination: URL(string: "https://www.osc.ny.gov/local-government/publications/reserve-funds")!) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text("OSC Reserve Funds publication")
                            .underline()
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RiverheadTheme.accent)
                }
                Link(destination: URL(string: "https://www.osc.ny.gov/local-government/financial-toolkit")!) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text("OSC Financial Toolkit (full library)")
                            .underline()
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RiverheadTheme.accent)
                }
                Link(destination: URL(string: "https://www.osc.ny.gov/local-government/publications/gasb54.pdf")!) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text("GASB 54 Fund Balance Reporting guide")
                            .underline()
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RiverheadTheme.accent)
                }
            }
        }
    }

    // MARK: - Row builders

    @ViewBuilder
    private func policyRow(label: String, value: Double, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
                .font(.caption)
                .foregroundStyle(RiverheadTheme.textSecondary)
            Spacer()
            Text(value, format: .currency(code: "USD").precision(.fractionLength(0)))
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
        }
    }

    @ViewBuilder
    private func tier54Row(
        number: String, name: String, color: Color,
        definition: String, riverheadContext: String, amount: Double?
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 26, height: 26)
                    Text(number).font(.caption.weight(.bold)).foregroundStyle(color)
                }
                Text(name).font(.subheadline.weight(.semibold)).foregroundStyle(RiverheadTheme.textPrimary)
                Spacer()
                if let amt = amount {
                    Text(amt, format: .currency(code: "USD").precision(.fractionLength(0)))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(color)
                }
            }
            Text(definition)
                .font(.caption)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Riverhead: \(riverheadContext)")
                .font(.caption2)
                .foregroundStyle(color.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
    }

    @ViewBuilder
    private func segSlider(
        label: String, hint: String,
        value: Binding<Double>, dollarAmount: Double, color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(value.wrappedValue, format: .percent.precision(.fractionLength(0)))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(color)
                    Text(dollarAmount, format: .currency(code: "USD").precision(.fractionLength(0)))
                        .font(.caption2)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                }
            }
            Slider(value: value, in: 0...0.40, step: 0.01)
                .tint(color)
            Text(hint)
                .font(.caption2)
                .foregroundStyle(RiverheadTheme.textSecondary)
        }
    }

    @ViewBuilder
    private func summaryRow(label: String, value: Double, color: Color, bold: Bool) -> some View {
        HStack {
            Text(label)
                .font(bold ? .subheadline.weight(.semibold) : .caption)
                .foregroundStyle(bold ? RiverheadTheme.textPrimary : RiverheadTheme.textSecondary)
            Spacer()
            Text(abs(value), format: .currency(code: "USD").precision(.fractionLength(0)))
                .font(bold ? .subheadline.weight(.bold) : .caption.weight(.medium))
                .foregroundStyle(color)
        }
    }

    @ViewBuilder
    private func reserveTypeRow(_ r: NYReserveFundType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(r.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                Spacer()
                Text(r.citation)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(r.tint.opacity(0.12))
                    .foregroundStyle(r.tint)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            Text(r.purpose)
                .font(.caption)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 4) {
                Image(systemName: "lock.fill").font(.caption2).foregroundStyle(r.tint)
                Text("Withdrawal: \(r.withdrawalRule)")
                    .font(.caption2)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(alignment: .top, spacing: 4) {
                Image(systemName: "percent").font(.caption2).foregroundStyle(r.tint)
                Text("Interest: \(r.interestRule)")
                    .font(.caption2)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Helpers

    private func colorForPercent(_ p: Double) -> Color {
        if p < 0.15 { return .red }
        if p <= 0.20 { return .green }
        return .blue
    }
}

#Preview {
    ReserveFundBreakdownView()
        .environment(RBBudgetStore())
}
