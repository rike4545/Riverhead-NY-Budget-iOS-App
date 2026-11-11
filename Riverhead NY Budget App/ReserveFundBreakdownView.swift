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

    // Corrected against the statute and the Comptroller's "Reserve Funds"
    // guide. Three entries here were previously misattributed: §6-c is the
    // CAPITAL reserve (not a rainy-day budget reserve), §6-e is CONTINGENCY AND
    // TAX STABILIZATION (not machinery), and §6-g is the fire-district capital
    // reserve, which a town cannot use.
    //
    // Deliberately NOT listed: the Town Law §55 General Reserve, §55-a
    // improvement-district reserve and §55-b judgments-and-claims reserve.
    // Those are open to "suburban towns" only. Every town in Suffolk County is
    // a town of the SECOND class regardless of population (Town Law §10), and
    // becoming a suburban town requires a public hearing plus a resolution
    // subject to permissive referendum that also converts the town to the FIRST
    // class (Town Law §50-a). Riverhead has not done that, so these three are
    // unavailable to it. Source: OSC, "Information for Town Officials"
    // (January 2026), Chapter 1.
    private let nyReserves: [NYReserveFundType] = [
        .init(
            name: "Contingency and Tax Stabilization Reserve",
            citation: "Gen. Mun. Law \u{00A7}6-e",
            purpose: "The one written for Riverhead\u{2019}s actual problem. It funds unanticipated revenue losses and unanticipated expenditures, and it may be used to lessen or prevent a projected levy increase above 2\u{00BD}%. For a town the \u{201C}eligible portion\u{201D} is the town-wide general and highway funds \u{2014} about $77.0M for 2026, so the fund could hold up to roughly $7.7M.",
            withdrawalRule: "Establishing it is a board resolution subject to permissive referendum. Spending from it takes a recommendation from the chief executive officer plus a two-thirds vote of the board.",
            interestRule: "Hard ceiling of 10% of the eligible portion of the annual budget. If the balance is over that when the tentative budget is prepared, the excess MUST be applied to reduce next year\u{2019}s levy.",
            tint: .purple
        ),
        .init(
            name: "Employee Benefit Accrued Liability Reserve",
            citation: "Gen. Mun. Law \u{00A7}6-p",
            purpose: "Pays the cash value of accumulated sick, vacation, holiday and compensatory leave owed to employees when they separate from service. This matches Riverhead\u{2019}s largest workforce liability outside retiree health \u{2014} accrued leave stood at $11.6M at the end of 2025 and has risen every year since 2023.",
            withdrawalRule: "Board resolution; no referendum to create or to spend. Cannot be used for a benefit already covered by another reserve.",
            interestRule: "Interest credited to the reserve. Funded from budgetary appropriations or transfers from certain other reserves.",
            tint: .orange
        ),
        .init(
            name: "Retirement Contribution Reserve",
            citation: "Gen. Mun. Law \u{00A7}6-r",
            purpose: "Smooths pension-cost volatility. Strictly for employer contributions to the State retirement systems \u{2014} NYSLRS and the Police and Fire Retirement System. Riverhead\u{2019}s net pension liability moved from $21.4M to $27.3M in a single year on investment returns alone.",
            withdrawalRule: "Board resolution; no referendum. Only for employer retirement-system contributions \u{2014} this reserve has nothing to do with retiree health.",
            interestRule: "Interest credited to the reserve. Several other reserves may transfer unexpended balances here, subject to a public hearing on 15 days\u{2019} notice.",
            tint: .red
        ),
        .init(
            name: "Capital Reserve Fund",
            citation: "Gen. Mun. Law \u{00A7}6-c",
            purpose: "Finances construction, reconstruction or acquisition of a capital improvement or item of equipment. Can be written for a named project (\u{201C}specific\u{201D}) or a category such as highway equipment (\u{201C}type\u{201D}).",
            withdrawalRule: "For a town, establishing a SPECIFIC capital reserve is subject to permissive referendum unless the item\u{2019}s period of probable usefulness is under five years; spending from it then needs only a board resolution. A TYPE reserve is the mirror image \u{2014} no referendum to establish, but the expenditure is subject to permissive referendum.",
            interestRule: "Interest follows the principal. Residual balances after a project completes may be moved to another capital reserve without referendum.",
            tint: .blue
        ),
        .init(
            name: "Repair Reserve Fund",
            citation: "Gen. Mun. Law \u{00A7}6-d",
            purpose: "Pays for repairs to capital improvements or equipment of a kind that does NOT recur annually or more often. Routine yearly maintenance does not qualify.",
            withdrawalRule: "No referendum to establish or spend, but a resolution appropriating money from it requires a public hearing with at least five days\u{2019} notice. In an emergency the board can skip the hearing on a two-thirds vote \u{2014} then half must be repaid the next fiscal year and the rest the year after.",
            interestRule: "Interest credited to the reserve. Balances may be transferred to a capital reserve or a contingency and tax stabilization reserve.",
            tint: .teal
        ),
        .init(
            name: "Reserve Fund for Payment of Bonded Indebtedness",
            citation: "Gen. Mun. Law \u{00A7}6-h",
            purpose: "Pays principal and interest on, or buys back, the Town\u{2019}s own bonds \u{2014} limited to issues with a maximum maturity of at least five years. It cannot be used for debt payable from assessments or from taxes on an area smaller than the whole town.",
            withdrawalRule: "Board resolution; no referendum to establish or to spend. If the current budget already funds that debt service from another source, the reserve may not also be used for it this year.",
            interestRule: "Interest follows the principal. Transferring the balance out to a capital reserve is subject to permissive referendum.",
            tint: .indigo
        ),
        .init(
            name: "Insurance Reserve Fund",
            citation: "Gen. Mun. Law \u{00A7}6-n",
            purpose: "Funds uninsured losses, claims, actions or judgments, plus the professional services used to investigate and settle them. A long list of coverages is excluded \u{2014} life, health, workers\u{2019} compensation, fidelity and surety, title and several others.",
            withdrawalRule: "Board resolution; no referendum. Settlements paid from it are capped at $25,000 each where compromised or settled with judicial approval.",
            interestRule: "Annual contributions are capped at the greater of $33,000 or 5% of the total budget, though there is no ceiling on the balance itself. A separate account must be kept for each kind of risk.",
            tint: .mint
        ),
    ]

    // MARK: - Body

    var body: some View {
        Group {
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
                policyRow(label: "20% reference line (not Town policy)", value: policyMax, color: .green)
                policyRow(label: "Cushion above minimum", value: max(0, unassigned - policyMin), color: .blue)
                policyRow(label: "Above the 20% reference line", value: max(0, unassigned - policyMax), color: .purple)

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
                    riverheadContext: "Reported at $2,012,534.08 in the General Fund at December 31, 2025 \u{2014} prepaid items and similar assets that exist but cannot be spent.",
                    amount: 2_012_534.08
                )
                Divider().opacity(0.2)
                tier54Row(
                    number: "2",
                    name: "Restricted",
                    color: .red,
                    definition: "Constrained by external parties: state law, federal grants, bond covenants, or creditors.",
                    riverheadContext: "Just $17,924.16 at the end of 2025, and all of it opioid-settlement money, which may only be spent on the purposes that settlement allows. Formally established reserve funds would also sit here once adopted \u{2014} Riverhead has essentially none, which is why this tier is so small.",
                    amount: 17_924.16
                )
                Divider().opacity(0.2)
                tier54Row(
                    number: "3",
                    name: "Committed",
                    color: .orange,
                    definition: "Self-imposed constraints set by the highest level of decision-making (Town Board resolution or local law). Can only be released by the same Board action.",
                    riverheadContext: "$42,435 at the end of 2025, up from $22,005 a year earlier. Committed balance takes a formal Board action to create, and the same level of action to release.",
                    amount: 42_435.00
                )
                Divider().opacity(0.2)
                tier54Row(
                    number: "4",
                    name: "Assigned",
                    color: .yellow,
                    definition: "Amounts the Board intends to use for a specific purpose but has not formally committed. An adopted budget that appropriates fund balance moves it here.",
                    riverheadContext: "$1,663,273.34 at the end of 2025 \u{2014} $1,250,000 of it the fund balance appropriated into the 2026 budget, and $413,273.34 assigned but unappropriated.",
                    amount: 1_663_273.34
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

                Link(destination: URL(string: "https://www.osc.ny.gov/files/local-government/publications/pdf/reserve-funds.pdf")!) {
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
                Link(destination: URL(string: "https://www.osc.ny.gov/files/local-government/publications/pdf/gasb54.pdf")!) {
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
