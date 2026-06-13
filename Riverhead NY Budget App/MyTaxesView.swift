//
//  MyTaxesView.swift
//  Riverhead NY Budget App
//
//  Resident-facing calculator:
//   • Estimate Town property tax from assessed value, exemptions, and rate
//   • Simple “receipt” showing where dollars go (illustrative shares)
//   • Educational tax cap + TBGF explainer with links to NYS guidance
//   • Context card: your bill as a tiny slice of the Town-wide levy
//

import SwiftUI
import Observation

@MainActor
struct MyTaxesView: View {
    @Environment(RBBudgetStore.self) private var store   // Observation style

    // Persisted inputs
    @AppStorage("tax_assessed_value")   private var assessedValue: Double = 450_000
    @AppStorage("tax_exemptions")       private var exemptions: Double = 0
    @AppStorage("tax_rate_per_1000")    private var ratePerThousand: Double = 61.9482
    @AppStorage("cap_prior_year_levy")  private var priorYearLevy: Double = 10_000_000
    @AppStorage("cap_cpi_percent")      private var cpiPercent: Double = 2.00
    @AppStorage("cap_tbgf")             private var tbgf: Double = 1.0072

    @FocusState private var fieldFocus: Field?
    private enum Field { case assessed, exemptions, rate, levy, cpi, tbgf }

    // Sheet state for “Learn more” links
    @State private var activeLearnMoreURL: URL?
    @State private var isShowingLearnMore: Bool = false

    private let cardBG: Material = .thinMaterial
    private let borderColor = Color(uiColor: .separator).opacity(0.25)
    private let contextLevyYear: Int = 2026
    private let receiverGeneralTownRate: Double = 61.9482
    private let receiverHighwayRate: Double = 8.6948
    private let riverheadSewerRentRate: Double = 11.4606
    private let calvertonSewerRentRate: Double = 79.2149

    // MARK: - Core tax math

    private var taxEstimate: RBPropertyTaxEstimate {
        RBPropertyTaxEstimate(
            assessedValue: assessedValue,
            exemptions: exemptions,
            ratePerThousand: ratePerThousand
        )
    }

    private var sanitizedExemptions: Double { taxEstimate.sanitizedExemptions }
    private var sanitizedRate: Double { taxEstimate.sanitizedRate }
    private var taxable: Double { taxEstimate.taxableAssessedValue }
    private var annualTax: Double { taxEstimate.annualTax }
    private var monthlyTax: Double { taxEstimate.monthlyTax }
    private var receiverGeneralAndHighwayRate: Double { receiverGeneralTownRate + receiverHighwayRate }

    private var taxCapEstimate: RBPropertyTaxCapEstimate {
        RBPropertyTaxCapEstimate(
            priorYearLevy: priorYearLevy,
            cpiPercent: cpiPercent,
            taxBaseGrowthFactor: tbgf
        )
    }

    private var rateSourceLabel: String {
        RBPropertyTaxRateSource.classify(
            rate: ratePerThousand,
            generalTownRate: receiverGeneralTownRate,
            highwayRate: receiverHighwayRate
        )
        .label
    }

    // MARK: - “Receipt” shares (illustrative only)

    private var illustrativeShares: [(label: String, weight: Double)] {
        [
            ("Police", 0.325),
            ("Highway / Public Works", 0.245),
            ("General Government", 0.150),
            ("Parks & Recreation", 0.070),
            ("Planning & Code", 0.055),
            ("Debt Service", 0.090),
            ("Other", 0.065)
        ]
    }

    private var breakdown: [(label: String, percent: Double, dollars: Double)] {
        illustrativeShares
            .map { (label, w) in (label, w * 100.0, w * annualTax) }
            .sorted { $0.dollars > $1.dollars }
    }

    // MARK: - Tax cap math (simplified demo)

    private var allowableGrowthPercent: Double { taxCapEstimate.allowableGrowthPercent }
    private var illustrativeLevyLimit: Double { taxCapEstimate.illustrativeLevyLimit }
    private var levyChangeAmount: Double { taxCapEstimate.levyChangeAmount }

    // MARK: - Budget context: your slice of the levy (uses 2026 Adopted where possible)

    private var generalFundContext: (fundLabel: String, levyYear: Int, levy: Double, shareFraction: Double)? {
        guard annualTax > 0 else { return nil }

        // Try to find the General Fund in the store
        let maybeKey = store.funds.first {
            $0.localizedCaseInsensitiveContains("general fund")
            || $0.hasPrefix("A01")
        }

        guard let key = maybeKey else { return nil }

        // 1) Prefer 2026 levy from the store, if present
        let series = store.valueSeries(for: key, metric: .taxLevy)
        var levyValue: Double? = series.first(where: { $0.year == contextLevyYear })?.value

        // 2) Fallback to CSV-parsed 2026 Adopted Budget via Riverhead2026BudgetShift
        if levyValue == nil || levyValue ?? 0 <= 0 {
            let summaries = Riverhead2026BudgetShift.fundSummaries()
            if let summary = summaries.first(where: {
                $0.fundCode.compare("A01", options: .caseInsensitive) == .orderedSame
                || $0.fundName.localizedCaseInsensitiveContains("general")
            }), let levyDec = summary.taxLevy2026 {
                levyValue = (levyDec as NSDecimalNumber).doubleValue
            }
        }

        guard let levy2026 = levyValue, levy2026 > 0 else { return nil }

        let rawShare = annualTax / levy2026
        let clampedShare = max(0, min(rawShare, 1)) // cap at 100% for sanity

        return (fundLabel: key, levyYear: contextLevyYear, levy: levy2026, shareFraction: clampedShare)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    inputsCard
                    resultsCard
                    if generalFundContext != nil {
                        budgetContextCard
                    }
                    receiverReferenceCard
                    receiptCard
                    taxCapCard
                    disclaimerCard
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationTitle("My Taxes")
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { fieldFocus = nil }
                }
            }
            .sheet(isPresented: $isShowingLearnMore) {
                if let url = activeLearnMoreURL {
                    SafariView(url: url)
                        .ignoresSafeArea()
                } else {
                    Text("No URL to display.")
                        .padding()
                }
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 8) {
            Text("Estimate your Town tax and see how it relates to the overall budget.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 6)
    }

    private var inputsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Inputs", systemImage: "slider.horizontal.3")
                    .font(.headline)
                Spacer()
                    Button {
                        withAnimation {
                            assessedValue = 450_000
                            exemptions = 0
                            ratePerThousand = receiverGeneralTownRate
                        }
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.caption)
                }
            }

            CurrencyField(title: "Assessed Value", value: $assessedValue)
                .focused($fieldFocus, equals: .assessed)

            CurrencyField(title: "Exemptions (optional)", value: $exemptions)
                .focused($fieldFocus, equals: .exemptions)

            VStack(alignment: .leading, spacing: 4) {
                Text("Tax Rate per $1,000")
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 8) {
                    TextField(
                        "Rate",
                        value: $ratePerThousand,
                        format: .number.precision(.fractionLength(2))
                    )
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($fieldFocus, equals: .rate)

                    Text("per $1,000")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        ratePresetButton("General Town", rate: receiverGeneralTownRate)
                        ratePresetButton("General + Highway", rate: receiverGeneralAndHighwayRate)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ratePresetButton("General Town", rate: receiverGeneralTownRate)
                        ratePresetButton("General + Highway", rate: receiverGeneralAndHighwayRate)
                    }
                }

                Label(rateSourceLabel, systemImage: "checkmark.seal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Tip: Assessed value and rate vary by year and property class. For an exact bill, refer to your assessment roll and the adopted tax rates.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(cardBG, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(borderColor))
    }

    private var resultsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Estimate", systemImage: "banknote")
                .font(.headline)

            sourceChipStrip([
                ("User inputs", "person.crop.square", Color.accentColor),
                ("App estimate", "function", .orange),
                ("Not a bill", "exclamationmark.triangle", .red)
            ])

            VStack(spacing: 8) {
                statRow(label: "Taxable Assessed Value", value: taxable, style: .currency)
                Divider().opacity(0.2)
                statRow(label: "Estimated Annual Town Tax", value: annualTax, style: .currencyBig)
                statRow(label: "Estimated Monthly", value: monthlyTax, style: .currency)
            }
            .accessibilityElement(children: .combine)

            Text("Using \(rateSourceLabel.lowercased()) at \(ratePerThousand.formatted(.number.precision(.fractionLength(4)))) per $1,000.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(cardBG, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(borderColor))
    }

    /// Context vs. Town-wide General Fund levy (prefers 2026 Adopted data).
    private var budgetContextCard: some View {
        guard let ctx = generalFundContext else { return AnyView(EmptyView()) }

        let currencyCode = Locale.current.currency?.identifier ?? "USD"
        let sharePct = ctx.shareFraction * 100

        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                Label("How this fits into the budget", systemImage: "chart.pie")
                    .font(.headline)

                Text("""
                For context, here’s how your estimated bill compares to the total \(ctx.levyYear) **General Fund tax levy**.
                """)
                .font(.caption)
                .foregroundStyle(.secondary)

                sourceChipStrip([
                    ("Extracted levy", "tablecells", Color.accentColor),
                    ("Your estimate", "person.crop.square", .orange)
                ])

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(ctx.levyYear) General Fund Levy")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(
                            ctx.levy,
                            format: .currency(code: currencyCode)
                        )
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Your Estimated Share")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(sharePct, specifier: "%.3f")%")
                            .font(.title3.weight(.bold))
                            .monospacedDigit()
                    }
                }

                ProgressView(
                    value: ctx.shareFraction,
                    total: 1
                )
                .tint(.accentColor)
                .accessibilityLabel("Your estimated share of the General Fund levy")

                Text("This is a rough illustration using your inputs and the modelled \(ctx.levyYear) levy. Other funds, special districts, and charges may also appear on your actual bill.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(cardBG, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(borderColor))
        )
    }

    private var receiverReferenceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Receiver of Taxes reference", systemImage: "list.bullet.rectangle")
                .font(.headline)

            Text("Riverhead's official 2025-2026 Receiver of Taxes sheet shows how district charges stack on top of the Town-wide bill. It lists General Town at `61.9482` per $1,000 of assessed value, Highway at `8.6948`, Riverhead Sewer Rent at `11.4606`, Calverton Sewer Rent at `79.2149`, and a single-family residential refuse-collection charge of `$482.40`. The same sheet reports a 2025 equalization rate of `8.16%` and a residential assessment ratio of `7.44%`. The Town's Receiver of Taxes archive also preserves annual tax-rate PDFs back through `2013-2014`, which makes historical year-over-year comparison possible. Town Code also makes clear that Calverton sewer rents are set annually by Town Board resolution with the sewer budget, collected by the Receiver of Taxes, and become a lien on the served property.")
                .font(.caption)
                .foregroundStyle(.secondary)

            sourceChipStrip([
                ("Official rate sheet", "building.columns", Color.accentColor),
                ("2025-2026", "calendar", .secondary)
            ])

            VStack(spacing: 8) {
                statTextRow(label: "2025-2026 General Town rate", valueText: "61.9482 / $1,000")
                statTextRow(label: "2025-2026 Highway rate", valueText: "8.6948 / $1,000")
                statTextRow(label: "Riverhead Sewer Rent", valueText: "11.4606 / $1,000")
                statTextRow(label: "Calverton Sewer Rent", valueText: "79.2149 / $1,000")
                statTextRow(label: "Single-family refuse collection", valueText: "$482.40")
                statTextRow(label: "Calverton sewer-rent timing", valueText: "Adopted in November")
            }
        }
        .padding()
        .background(cardBG, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(borderColor))
    }

    private var receiptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Where your dollars go", systemImage: "chart.bar.doc.horizontal")
                .font(.headline)

            if annualTax <= 0 {
                Text("Enter values above to see your personal breakdown.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(breakdown.enumerated()), id: \.offset) { _, item in
                        ReceiptRow(label: item.label,
                                   percent: item.percent,
                                   dollars: item.dollars)
                    }
                }
                .accessibilityElement(children: .contain)
            }

            Text("Percentages are illustrative. Replace with adopted budget shares for accuracy.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(cardBG, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(borderColor))
    }

    private var taxCapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Real Property Tax Cap & TBGF", systemImage: "percent")
                .font(.headline)

            Text("""
            New York’s property tax cap generally limits levy growth to the **lesser of 2% or inflation (CPI-U)**, with limited exclusions and a **60% override**. The **Tax Base Growth Factor (TBGF)** adjusts for physical growth in the tax base. This section is an **educational illustration** only; see official guidance for the full formula.
            """)
            .font(.caption)
            .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                CurrencyField(title: "Prior Year Total Tax Levy", value: $priorYearLevy)
                    .focused($fieldFocus, equals: .levy)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CPI (percent)")
                            .font(.subheadline.weight(.semibold))
                        TextField(
                            "CPI %",
                            value: $cpiPercent,
                            format: .number.precision(.fractionLength(2))
                        )
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .focused($fieldFocus, equals: .cpi)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tax Base Growth Factor")
                            .font(.subheadline.weight(.semibold))
                        TextField(
                            "TBGF",
                            value: $tbgf,
                            format: .number.precision(.fractionLength(4))
                        )
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .focused($fieldFocus, equals: .tbgf)

                        Text("Example TBGF: 1.0072")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            let currencyCode = Locale.current.currency?.identifier ?? "USD"

            VStack(spacing: 8) {
                HStack {
                    Text("Allowable growth (min of 2% or CPI)")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.2f%%", allowableGrowthPercent * 100))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }

                HStack {
                    Text("Illustrative levy limit (simplified)")
                        .font(.subheadline)
                    Spacer()
                    Text(illustrativeLevyLimit,
                         format: .currency(code: currencyCode))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }

                HStack {
                    Text("Change vs. prior levy")
                        .font(.subheadline)
                    Spacer()
                    Text(levyChangeAmount,
                         format: .currency(code: currencyCode))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Learn more")
                    .font(.subheadline.weight(.semibold))

                HStack {
                    Button {
                        if let url = URL(string: "https://www.tax.ny.gov/pdf/publications/orpts/capguidelines.pdf") {
                            activeLearnMoreURL = url
                            isShowingLearnMore = true
                        }
                    } label: {
                        Label("Publication 1000 (Guidelines)", systemImage: "book")
                    }

                    Spacer(minLength: 12)

                    Button {
                        if let url = URL(string: "https://www.osc.ny.gov/files/local-government/property-tax-cap/pdf/formula.pdf") {
                            activeLearnMoreURL = url
                            isShowingLearnMore = true
                        }
                    } label: {
                        Label("OSC Formula Worksheet (PDF)", systemImage: "doc.richtext")
                    }
                }
                .buttonStyle(.bordered)
            }


                HStack {
                    Button {
                        if let url = URL(string: "https://www.townofriverheadny.gov/189/Receiver-of-Taxes") {
                            activeLearnMoreURL = url
                            isShowingLearnMore = true
                        }
                    } label: {
                        Label("Receiver of Taxes", systemImage: "building.2")
                    }

                    Spacer(minLength: 12)

                    Button {
                        if let url = URL(string: "https://tax.egov.basgov.com/riverhead/Search/Search") {
                            activeLearnMoreURL = url
                            isShowingLearnMore = true
                        }
                    } label: {
                        Label("Online Tax Search", systemImage: "magnifyingglass")
                    }
                }
                .buttonStyle(.bordered)

                HStack {
                    Button {
                        if let url = URL(string: "https://www.townofriverheadny.gov/Archive.aspx?AMID=37") {
                            activeLearnMoreURL = url
                            isShowingLearnMore = true
                        }
                    } label: {
                        Label("Tax Rate Archive", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    }

                    Spacer(minLength: 12)

                    Button {
                        if let url = URL(string: "https://ecode360.com/29710664") {
                            activeLearnMoreURL = url
                            isShowingLearnMore = true
                        }
                    } label: {
                        Label("Sewer Rent Law", systemImage: "scroll")
                    }

                    Spacer(minLength: 12)
                }
                .buttonStyle(.bordered)


            VStack(alignment: .leading, spacing: 6) {
                Text("Notes")
                    .font(.subheadline.weight(.semibold))

                Text("• Official levy-limit calculations include PILOT adjustments, carryover, capital exclusions, certain pension/tort exclusions, and the 60% override. This demo omits those for clarity.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("• Always rely on the State Comptroller’s forms and guidance for official filings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(cardBG, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(borderColor))
    }

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Disclaimer", systemImage: "exclamationmark.triangle")
                .font(.headline)

            Text("""
            This calculator is **not an official tax assessment**. It is provided for **informational purposes only** and should **not be relied upon for official tax situations**.

            For an accurate bill, please refer to the Town of Riverhead’s official assessment roll, adopted tax rates, and any applicable exemptions or special district charges.
            """)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(cardBG, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(borderColor))
    }

    // MARK: - Helpers

    private enum StatStyle { case currency, currencyBig }

    private func ratePresetButton(_ title: String, rate: Double) -> some View {
        Button {
            withAnimation {
                ratePerThousand = rate
            }
        } label: {
            Label(title, systemImage: ratePerThousand.isApproximately(rate) ? "checkmark.circle.fill" : "circle")
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .tint(ratePerThousand.isApproximately(rate) ? .accentColor : .secondary)
        .accessibilityLabel("Use \(title) tax rate")
        .accessibilityValue(rate.formatted(.number.precision(.fractionLength(4))) + " per one thousand dollars")
    }

    private func sourceChipStrip(_ items: [(label: String, icon: String, tint: Color)]) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    sourceChip(item.label, icon: item.icon, tint: item.tint)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    sourceChip(item.label, icon: item.icon, tint: item.tint)
                }
            }
        }
    }

    private func sourceChip(_ label: String, icon: String, tint: Color) -> some View {
        Label(label, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(tint.opacity(0.13))
            )
            .overlay(
                Capsule()
                    .strokeBorder(tint.opacity(0.24), lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
    }

    @ViewBuilder
    private func statRow(label: String, value: Double, style: StatStyle) -> some View {
        let currencyCode = Locale.current.currency?.identifier ?? "USD"

        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            switch style {
            case .currency:
                Text(value, format: .currency(code: currencyCode))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            case .currencyBig:
                Text(value, format: .currency(code: currencyCode))
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
            }
        }
        .accessibilityLabel(
            Text("\(label) \(value.formatted(.currency(code: currencyCode)))")
        )
    }

    private func statTextRow(label: String, valueText: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(valueText)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
    }
}

// MARK: - Small subviews

private struct CurrencyField: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        let currencyCode = Locale.current.currency?.identifier ?? "USD"

        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            TextField(
                title,
                value: $value,
                format: .currency(code: currencyCode)
            )
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
        }
    }
}

private struct ReceiptRow: View {
    let label: String
    let percent: Double
    let dollars: Double

    var body: some View {
        let currencyCode = Locale.current.currency?.identifier ?? "USD"

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.1f%%", percent))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                let barWidth = max(
                    0,
                    min(geo.size.width, geo.size.width * CGFloat(percent / 100.0))
                )

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor.opacity(0.6))
                        .frame(width: barWidth, height: 12)
                }
            }
            .frame(height: 12)

            HStack {
                Text(dollars, format: .currency(code: currencyCode))
                    .font(.footnote.weight(.semibold))
                    .monospacedDigit()
                Spacer()
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text("\(label) \(String(format: "%.1f", percent)) percent, \(dollars.formatted(.currency(code: currencyCode)))")
        )
    }
}

#Preview {
    MyTaxesView()
        .environment(RBBudgetStore())
}
