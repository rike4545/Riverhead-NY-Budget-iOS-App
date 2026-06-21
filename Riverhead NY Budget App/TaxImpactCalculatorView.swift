import SwiftUI

// MARK: - Local GlassCard

private struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let title: String?; let subtitle: String?
    @ViewBuilder var content: Content
    init(title: String? = nil, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title; self.subtitle = subtitle; self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title { Text(title).font(.headline).foregroundStyle(RiverheadTheme.textPrimary) }
            if let subtitle { Text(subtitle).font(.footnote).foregroundStyle(RiverheadTheme.textSecondary) }
            content
        }
        .padding(14)
        .background(
            (reduceTransparency ? AnyShapeStyle(RiverheadTheme.Surface.card) : AnyShapeStyle(scheme == .dark ? .ultraThinMaterial : .regularMaterial)),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(RiverheadTheme.border.opacity(scheme == .dark ? 0.35 : 0.2)))
        .shadow(color: .black.opacity(scheme == .dark ? 0.25 : 0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Main view

@MainActor
struct TaxImpactCalculatorView: View {

    @Environment(RBBudgetStore.self) private var store

    // 2025 adopted General Fund figures (Receiver of Taxes 2025-2026 sheet)
    private let baseLevy: Double           = 48_639_479   // 2025 adopted GF levy
    private let baseLevyYear: Int          = 2025
    private let generalTownRate: Double    = 61.9482      // per $1,000 AV
    private let highwayRate: Double        = 8.6948       // per $1,000 AV
    private let sewerRentRate: Double      = 11.4606      // per $1,000 AV (Riverhead Sewer Dist.)
    private let calvertonSewerRate: Double = 79.2149      // per $1,000 AV (Calverton only)
    private let refuseCharge: Double       = 482.40       // flat annual (single-family residential)
    private let equalizationRate: Double   = 0.0816       // 2025 equalization rate

    // Total taxable assessed value = levy ÷ (rate ÷ 1,000)
    private var totalTaxableAV: Double { baseLevy / (generalTownRate / 1_000) }

    // User inputs
    @AppStorage("tic_assessed_value")    private var assessedValue: Double   = 45_000
    @AppStorage("tic_levy_change_pct")   private var levyChangePct: Double   = 2.0
    @AppStorage("tic_reserve_offset")    private var reserveOffset: Double   = 0
    @AppStorage("tic_in_sewer_district") private var inSewerDistrict: Bool   = true
    @AppStorage("tic_in_calverton")      private var inCalverton: Bool        = false

    @State private var showMath: Bool = false

    // MARK: - Core math

    /// Net levy after reserve offset
    private var netLevy: Double { baseLevy * (1 + levyChangePct / 100) - reserveOffset }
    private var levyDelta: Double { netLevy - baseLevy }

    /// New General Town rate implied by the net levy and total taxable AV
    private var newGeneralTownRate: Double { (netLevy / totalTaxableAV) * 1_000 }
    private var rateChange: Double { newGeneralTownRate - generalTownRate }

    /// Estimated impact per property
    private var annualImpact: Double { rateChange * (assessedValue / 1_000) }
    private var monthlyImpact: Double { annualImpact / 12 }

    /// Full estimated bill (current year baseline + delta)
    private var currentGeneralTownBill: Double { generalTownRate * (assessedValue / 1_000) }
    private var newGeneralTownBill: Double { newGeneralTownRate * (assessedValue / 1_000) }

    // Other district charges (not affected by General Fund levy changes)
    private var highwayBill: Double { highwayRate * (assessedValue / 1_000) }
    private var sewerBill: Double { inSewerDistrict ? sewerRentRate * (assessedValue / 1_000) : 0 }
    private var calvertonBill: Double { inCalverton ? calvertonSewerRate * (assessedValue / 1_000) : 0 }

    private var currentTotalBill: Double { currentGeneralTownBill + highwayBill + sewerBill + calvertonBill + refuseCharge }
    private var newTotalBill: Double { newGeneralTownBill + highwayBill + sewerBill + calvertonBill + refuseCharge }

    // Estimated full market value
    private var estimatedMarketValue: Double { assessedValue / equalizationRate }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    contextCard
                    inputsCard
                    impactCard
                    billBreakdownCard
                    if showMath { mathCard }
                    reserveOffsetExplainerCard
                    sourcesCard
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(RiverheadTheme.background.ignoresSafeArea())
            .navigationTitle("Tax Impact Calculator")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(showMath ? "Hide math" : "Show math") { showMath.toggle() }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.accent)
                }
            }
        }
    }

    // MARK: - Cards

    private var contextCard: some View {
        GlassCard(
            title: "What does a levy change cost me?",
            subtitle: "This calculator shows how a General Fund levy increase (or a reserve offset) flows through to your annual Town property tax bill. Enter your assessed value from your tax bill."
        ) {
            VStack(alignment: .leading, spacing: 6) {
                infoRow("Base year", "\(baseLevyYear) adopted General Fund levy")
                infoRow("Base levy", baseLevy.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                infoRow("Total taxable AV", totalTaxableAV.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                infoRow("General Town rate", "\(generalTownRate.formatted(.number.precision(.fractionLength(4)))) per $1,000 AV")
                Text("Your \"assessed value\" is the number on your annual property tax bill — not the market value. In Riverhead the equalization rate is approximately 8.16%, so assessed values are a fraction of market value.")
                    .font(.caption2)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
    }

    private var inputsCard: some View {
        GlassCard(title: "Your Inputs", subtitle: "Adjust to match your property and model different levy scenarios.") {
            VStack(alignment: .leading, spacing: 18) {

                // Assessed value
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Your assessed value")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(assessedValue, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RiverheadTheme.accent)
                    }
                    Slider(value: $assessedValue, in: 10_000...200_000, step: 1_000)
                        .tint(RiverheadTheme.accent)
                    HStack {
                        Text("Estimated market value: \(estimatedMarketValue.formatted(.currency(code: "USD").precision(.fractionLength(0))))")
                            .font(.caption2)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                        Spacer()
                        Text("@ \((equalizationRate * 100).formatted(.number.precision(.fractionLength(2))))% eq. rate")
                            .font(.caption2)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                    }
                }

                Divider().opacity(0.25)

                // Levy change
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Proposed levy change")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text((levyChangePct / 100), format: .percent.precision(.fractionLength(1)))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(levyChangePct >= 0 ? .orange : .green)
                    }
                    Slider(value: $levyChangePct, in: -5...10, step: 0.1)
                        .tint(levyChangePct >= 0 ? .orange : .green)
                    HStack {
                        Text("Dollar change in levy")
                            .font(.caption2)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                        Spacer()
                        let rawDelta = baseLevy * (levyChangePct / 100)
                        Text(rawDelta, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(rawDelta >= 0 ? .orange : .green)
                    }
                }

                Divider().opacity(0.25)

                // Reserve offset
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Reserve draw (levy offset)")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(reserveOffset, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(reserveOffset > 0 ? .blue : RiverheadTheme.textSecondary)
                    }
                    Slider(value: $reserveOffset, in: 0...5_000_000, step: 50_000)
                        .tint(.blue)
                    Text("Appropriating fund balance reduces the net levy, lowering the rate. $1M deployed ≈ \((1_000_000 / totalTaxableAV * 1_000).formatted(.number.precision(.fractionLength(4)))) per $1,000 AV rate reduction.")
                        .font(.caption2)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider().opacity(0.25)

                // District toggles
                VStack(alignment: .leading, spacing: 8) {
                    Text("District charges (not affected by levy change)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.textSecondary)
                    Toggle("Riverhead Sewer District (\(sewerRentRate.formatted(.number.precision(.fractionLength(4))))/M)", isOn: $inSewerDistrict)
                        .font(.caption)
                    Toggle("Calverton Sewer District (\(calvertonSewerRate.formatted(.number.precision(.fractionLength(4))))/M)", isOn: $inCalverton)
                        .font(.caption)
                }
                .toggleStyle(.switch)
                .tint(RiverheadTheme.accent)
            }
        }
    }

    private var impactCard: some View {
        GlassCard(
            title: "Estimated Impact on Your Bill",
            subtitle: "General Town tax only — based on levy change and reserve offset."
        ) {
            VStack(alignment: .leading, spacing: 14) {

                HStack(alignment: .firstTextBaseline) {
                    Text(annualImpact >= 0 ? "+" : "")
                    + Text(annualImpact, format: .currency(code: "USD").precision(.fractionLength(2)))
                    Spacer()
                    Text("per year")
                        .font(.title3)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                }
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(annualImpact > 0 ? .red : (annualImpact < 0 ? .green : RiverheadTheme.textSecondary))

                HStack {
                    Text(monthlyImpact >= 0 ? "+" : "")
                    + Text(monthlyImpact, format: .currency(code: "USD").precision(.fractionLength(2)))
                    + Text(" / month")
                }
                .font(.subheadline)
                .foregroundStyle(annualImpact > 0 ? .red.opacity(0.8) : .green.opacity(0.8))

                Divider().opacity(0.25)

                metricRow("Net levy (proposed)", value: netLevy.formatted(.currency(code: "USD").precision(.fractionLength(0))), color: RiverheadTheme.textPrimary)
                metricRow("Levy change from base", value: (levyDelta >= 0 ? "+" : "") + levyDelta.formatted(.currency(code: "USD").precision(.fractionLength(0))), color: levyDelta >= 0 ? .orange : .green)
                metricRow("New General Town rate", value: "\(newGeneralTownRate.formatted(.number.precision(.fractionLength(4)))) per $1,000", color: RiverheadTheme.textPrimary)
                metricRow("Rate change", value: (rateChange >= 0 ? "+" : "") + rateChange.formatted(.number.precision(.fractionLength(4))), color: rateChange >= 0 ? .orange : .green)

                if reserveOffset > 0 {
                    Divider().opacity(0.2)
                    let savingFromReserve = -(reserveOffset / totalTaxableAV * 1_000) * (assessedValue / 1_000)
                    Text("The \(reserveOffset.formatted(.currency(code: "USD").precision(.fractionLength(0)))) reserve draw saves approximately \(abs(savingFromReserve).formatted(.currency(code: "USD").precision(.fractionLength(2))))/year on this assessment, or \((abs(savingFromReserve)/12).formatted(.currency(code: "USD").precision(.fractionLength(2))))/month.")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var billBreakdownCard: some View {
        GlassCard(
            title: "Estimated Full Town Bill",
            subtitle: "All applicable charges for this assessment. District charges use 2025-2026 Receiver of Taxes rates."
        ) {
            VStack(alignment: .leading, spacing: 8) {
                billRow("General Town (current)",   value: currentGeneralTownBill, isNew: false)
                billRow("General Town (proposed)",  value: newGeneralTownBill,     isNew: true,  highlight: true)
                Divider().opacity(0.2)
                billRow("Highway",                  value: highwayBill,            isNew: false)
                if inSewerDistrict {
                    billRow("Riverhead Sewer Rent", value: sewerBill,              isNew: false)
                }
                if inCalverton {
                    billRow("Calverton Sewer Rent", value: calvertonBill,          isNew: false)
                }
                billRow("Residential refuse (flat)", value: refuseCharge,          isNew: false)
                Divider().opacity(0.3)
                HStack {
                    Text("Current estimated total").font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(currentTotalBill, format: .currency(code: "USD").precision(.fractionLength(2)))
                        .font(.subheadline.weight(.bold))
                }
                HStack {
                    Text("Proposed estimated total").font(.subheadline.weight(.semibold)).foregroundStyle(RiverheadTheme.accent)
                    Spacer()
                    Text(newTotalBill, format: .currency(code: "USD").precision(.fractionLength(2)))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(RiverheadTheme.accent)
                }

                Text("Highway, sewer, and refuse charges are shown for context. Only the General Town levy changes with the slider — district charges are set separately.")
                    .font(.caption2)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
    }

    private var mathCard: some View {
        GlassCard(title: "The Math (step by step)", subtitle: "How the rate change and household impact are calculated.") {
            VStack(alignment: .leading, spacing: 8) {
                mathStep("1", "Base levy × (1 + levy change %)",
                         "\(baseLevy.formatted(.currency(code: "USD").precision(.fractionLength(0)))) × \((1 + levyChangePct / 100).formatted(.number.precision(.fractionLength(4)))) = \((baseLevy * (1 + levyChangePct / 100)).formatted(.currency(code: "USD").precision(.fractionLength(0))))")
                mathStep("2", "Subtract reserve offset",
                         "\((baseLevy * (1 + levyChangePct / 100)).formatted(.currency(code: "USD").precision(.fractionLength(0)))) − \(reserveOffset.formatted(.currency(code: "USD").precision(.fractionLength(0)))) = \(netLevy.formatted(.currency(code: "USD").precision(.fractionLength(0))))")
                mathStep("3", "New rate = net levy ÷ total taxable AV × $1,000",
                         "\(netLevy.formatted(.currency(code: "USD").precision(.fractionLength(0)))) ÷ \(totalTaxableAV.formatted(.currency(code: "USD").precision(.fractionLength(0)))) × $1,000 = \(newGeneralTownRate.formatted(.number.precision(.fractionLength(4))))/M")
                mathStep("4", "Rate change = new rate − base rate",
                         "\(newGeneralTownRate.formatted(.number.precision(.fractionLength(4)))) − \(generalTownRate.formatted(.number.precision(.fractionLength(4)))) = \(rateChange.formatted(.number.precision(.fractionLength(4))))/M")
                mathStep("5", "Annual impact = rate change × (assessed value ÷ $1,000)",
                         "\(rateChange.formatted(.number.precision(.fractionLength(4)))) × \((assessedValue / 1_000).formatted(.number.precision(.fractionLength(3)))) = \(annualImpact.formatted(.currency(code: "USD").precision(.fractionLength(2))))/yr")
            }
        }
    }

    private var reserveOffsetExplainerCard: some View {
        GlassCard(
            title: "Reserve Offset Explained",
            subtitle: "How appropriating fund balance reduces the levy and each taxpayer's bill."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("When the Town Board appropriates fund balance (the \"rainy day fund\") as a revenue source in the budget, the adopted levy is reduced by that amount. The savings spread across all taxpayers proportionally — every property benefits equally on a per-dollar-of-assessed-value basis.")
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider().opacity(0.25)

                let perMillionSaving = (1_000_000 / totalTaxableAV * 1_000) * (assessedValue / 1_000)
                VStack(alignment: .leading, spacing: 4) {
                    Text("For every $1M of reserve deployed:")
                        .font(.caption.weight(.semibold))
                    Text("• Levy falls by $1,000,000")
                        .font(.caption2).foregroundStyle(RiverheadTheme.textSecondary)
                    Text("• General Town rate falls by \((1_000_000 / totalTaxableAV * 1_000).formatted(.number.precision(.fractionLength(4))))/M")
                        .font(.caption2).foregroundStyle(RiverheadTheme.textSecondary)
                    Text("• This assessment saves \(perMillionSaving.formatted(.currency(code: "USD").precision(.fractionLength(2))))/year")
                        .font(.caption2).foregroundStyle(.blue)
                }

                Text("OSC cautions that using fund balance as a recurring levy offset is a structural risk — it depletes reserves without addressing the underlying spending growth. Reserve draws are appropriate for one-time purposes or to smooth a transition, with a clear replenishment plan.")
                    .font(.caption2)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
    }

    private var sourcesCard: some View {
        GlassCard(
            title: "Sources & Caveats",
            subtitle: "This is an educational estimate, not an official tax calculation."
        ) {
            VStack(alignment: .leading, spacing: 6) {
                Text("• Rates: 2025-2026 Town of Riverhead Receiver of Taxes rate sheet. General Town $61.9482, Highway $8.6948, Riverhead Sewer Rent $11.4606, Calverton Sewer Rent $79.2149 — all per $1,000 of assessed value. Single-family refuse: $482.40 flat.")
                    .font(.caption2).foregroundStyle(RiverheadTheme.textSecondary)
                Text("• Base levy: 2025 adopted General Fund tax levy of $48,639,479.")
                    .font(.caption2).foregroundStyle(RiverheadTheme.textSecondary)
                Text("• Total taxable AV: derived from the levy ÷ rate. County, school, fire district, and special district levies are separate and are NOT included.")
                    .font(.caption2).foregroundStyle(RiverheadTheme.textSecondary)
                Text("• This calculator models the General Fund levy only. The actual 2027 budget will include a formal tax cap calculation. Confirm your assessed value on your tax bill; it may differ from the slider default.")
                    .font(.caption2).foregroundStyle(RiverheadTheme.textSecondary)
            }
        }
    }

    // MARK: - Row helpers

    @ViewBuilder
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(RiverheadTheme.textSecondary)
            Spacer()
            Text(value).font(.caption.weight(.semibold)).foregroundStyle(RiverheadTheme.textPrimary)
        }
    }

    @ViewBuilder
    private func metricRow(_ label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(RiverheadTheme.textSecondary)
            Spacer()
            Text(value).font(.caption.weight(.semibold)).foregroundStyle(color)
        }
    }

    @ViewBuilder
    private func billRow(_ label: String, value: Double, isNew: Bool, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(highlight ? RiverheadTheme.accent : RiverheadTheme.textSecondary)
            Spacer()
            Text(value, format: .currency(code: "USD").precision(.fractionLength(2)))
                .font(.caption.weight(highlight ? .bold : .medium))
                .foregroundStyle(highlight ? RiverheadTheme.accent : RiverheadTheme.textPrimary)
        }
    }

    @ViewBuilder
    private func mathStep(_ number: String, _ formula: String, _ result: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top, spacing: 6) {
                ZStack {
                    Circle().fill(RiverheadTheme.accent.opacity(0.15)).frame(width: 20, height: 20)
                    Text(number).font(.caption2.weight(.bold)).foregroundStyle(RiverheadTheme.accent)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(formula).font(.caption2.weight(.medium)).foregroundStyle(RiverheadTheme.textPrimary)
                    Text(result).font(.caption2).foregroundStyle(RiverheadTheme.textSecondary)
                }
            }
        }
    }
}

private extension Double {
    // Helpers used in math card string interpolation
    var currency0: String { self.formatted(.currency(code: "USD").precision(.fractionLength(0))) }
}

#Preview {
    TaxImpactCalculatorView()
        .environment(RBBudgetStore())
}
