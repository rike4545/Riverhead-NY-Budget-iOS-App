//
//  TownSquareBANImpactView 2.swift
//  Riverhead NY Budget App
//
//  Created by Bryan on 1/21/26.
//


//
//  TownSquareBANImpactView.swift
//  Riverhead NY Budget App
//
//  “Town Square Project” • BAN (Bond Anticipation Note) impact explainer + calculator.
//  Swift 6 • iOS 17+
//
//  This revision (executed Master Developer Agreement data):
//  - Purchase Price: $2,625,000 (MDA §3.04(a))
//  - Down payment: 5% (MDA §3.04(a))
//  - Grant funding commitments listed: $360k + $150k + $150k (= $660k), credited to the extent already paid to Town (MDA §3.04(a))
//  - Town Square O&M fee: $150,000/yr for 10 years (MDA discussion prior to closing; also reiterated in strategies section)
//
//  DISCLAIMER
//  - Educational estimator, not official financial advice.
//  - BAN day-count, payment timing, rollover terms, issuance costs vary.
//  - The MDA references credits “to the extent already paid to the Town” — enter what’s actually been paid.
//

import SwiftUI
import Foundation

#if canImport(Charts)
import Charts
#endif

// MARK: - Public Entry View

public struct TownSquareBANImpactView: View {

    public init(accent: Color = .indigo) {
        self.accent = accent
    }

    private let accent: Color

    @State private var inputs = BANInputs.defaultsFromMDA
    @State private var showAdvanced = false

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                header

                GroupBox { overviewText }

                GroupBox { mdaKeyTerms }

                GroupBox { acquisitionMath }

                GroupBox { leaseCoverage }

                GroupBox { banInputs }

                GroupBox { resultsSummary }

                GroupBox { scenarioCompare }

                GroupBox { sensitivity }

                GroupBox { fundBalanceContext }

                GroupBox { notesAndDisclaimers }
            }
            .padding()
        }
        .navigationTitle("Town Square • BAN Impact")
        .navigationBarTitleDisplayMode(.inline)
        .tint(accent)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(inputs.projectTitle.isEmpty ? "Town Square Project" : inputs.projectTitle)
                .font(.title2.weight(.semibold))

            Text("BAN costs • MDA purchase terms • lease coverage • 15-year conversion")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Label("BAN", systemImage: "percent")
                Label("MDA terms", systemImage: "doc.text")
                Label("Lease coverage", systemImage: "doc.text.magnifyingglass")
                Label("15y conversion", systemImage: "building.columns")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Overview

    private var overviewText: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What a BAN is")
                .font(.headline)

            Text("A Bond Anticipation Note (BAN) is short-term borrowing—often used to fund a project now, with the expectation it will later be “taken out” by permanent financing (like a long-term bond) or another funding source.")
                .foregroundStyle(.secondary)

            Text("What “conversion to long-term debt” means")
                .font(.headline)
                .padding(.top, 4)

            Text("If the BAN is converted, the town replaces short-term borrowing with long-term debt service. That spreads repayment over years, but creates an annual debt-service obligation (principal + interest) for the term.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - MDA Terms

    private var mdaKeyTerms: some View {
        let mda = TownSquareMDATerms.self

        return VStack(alignment: .leading, spacing: 10) {
            Text("Executed Master Developer Agreement • Key terms")
                .font(.headline)

            Text("These figures come from the executed Master Developer Agreement (MDA).")
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, 2)

            metricRow("Purchase price", mda.purchasePrice.currency(allowCents: false))
            metricRow("Down payment rate", mda.downPaymentRate.percentString())
            metricRow("Down payment amount (5%)", mda.downPaymentAmount.currency(allowCents: false))

            Divider().padding(.vertical, 2)

            metricRow("Grant commitments listed", mda.totalGrantCommitments.currency(allowCents: false))
            Text("Breakdown: \(mda.grantCommitments.map { $0.currency(allowCents: false) }.joined(separator: " + ")).")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("Per MDA: credited against the closing balance **to the extent already paid to the Town**.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, 2)

            metricRow("Town Square O&M fee", "\(mda.townSquareOMAnnualFee.currency(allowCents: false))/yr × \(mda.townSquareOMTermYears)y")
            metricRow("O&M monthly equivalent", (mda.townSquareOMAnnualFee / 12.0).currency(allowCents: false))

            Divider().padding(.vertical, 2)

            metricRow("Program summary", "Up to \(mda.hotelRoomsMax) hotel rooms + \(mda.condoUnits) condos")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Acquisition / Closing Math (MDA-driven)

    private var acquisitionMath: some View {
        let mda = TownSquareMDATerms.self

        let deposit = mda.downPaymentAmount
        let creditsCap = mda.totalGrantCommitments

        let creditsPaid = inputs.creditsAlreadyPaidToTown.clamped(to: 0...creditsCap)
        let closing = max(0, inputs.estimatedTransferAndClosingCosts)

        // “Net balance” is: purchase price + closing costs - credits already paid - deposit already posted.
        // This is NOT guaranteed to equal BAN principal; it’s a helpful “financing target” estimate.
        let netBalance = max(0, mda.purchasePrice + closing - creditsPaid - deposit)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Acquisition math (what-if)")
                .font(.headline)

            Text("MDA purchase price is “plus transfer tax and other real-property transfer costs.” Enter your best estimate, and how much of the listed grant commitments has already been paid to the Town (credited at closing).")
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, 2)

            currencyField(title: "Estimated transfer + closing costs", value: $inputs.estimatedTransferAndClosingCosts)

            VStack(alignment: .leading, spacing: 6) {
                Text("Grant credits already paid to Town (credited at closing)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    TextField("Credits paid", text: Binding(
                        get: { inputs.creditsAlreadyPaidToTown.currency(allowCents: false) },
                        set: { inputs.creditsAlreadyPaidToTown = Double.parseCurrency($0) }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)

                    Button("Max") { inputs.creditsAlreadyPaidToTown = creditsCap }
                        .buttonStyle(.bordered)
                }

                Slider(
                    value: Binding(
                        get: { creditsPaid },
                        set: { inputs.creditsAlreadyPaidToTown = $0 }
                    ),
                    in: 0...creditsCap
                )
            }

            Divider().padding(.vertical, 2)

            metricRow("Purchase price", mda.purchasePrice.currency(allowCents: false))
            metricRow("Down payment (already posted)", deposit.currency(allowCents: false))
            metricRow("Credits paid (entered)", creditsPaid.currency(allowCents: false))
            metricRow("Transfer + closing (entered)", closing.currency(allowCents: false))
            metricRow("Net balance after deposit/credits", netBalance.currency(allowCents: false))

            HStack(spacing: 10) {
                Button("Use Purchase Price as Principal") {
                    withAnimation(.snappy) {
                        inputs.principal = mda.purchasePrice
                    }
                }
                .buttonStyle(.bordered)

                Button("Use Net Balance as Principal") {
                    withAnimation(.snappy) {
                        inputs.principal = netBalance
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 6)

            Text("Tip: “Net balance” is a helpful financing target, but your BAN principal should match the actual note amount in the BAN documents.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Lease Coverage Panel (editable; defaults retained)

    private var leaseCoverage: some View {
        let base = BANImpactEngine.baseBAN(inputs: inputs)
        let rollover = BANImpactEngine.rolloverScenario(inputs: inputs)
        let bond = BANImpactEngine.bondConversionScenario(inputs: inputs)

        let preMonthly = inputs.prePossessionLeaseMonthly
        let extMonthly = inputs.extendedLeaseMonthly

        let preAnnual = preMonthly * 12.0
        let extAnnual = extMonthly * 12.0

        let modeledBANMonthly = base.interestPerMonth
        let modeledBANMonthlyRollover: Double = {
            guard rollover.totalDays > 0 else { return 0 }
            let months = max(1.0, Double(rollover.totalDays) / 30.0)
            return rollover.totalInterest / months
        }()

        let chosenBANMonthly = (inputs.rolloverCount > 0) ? modeledBANMonthlyRollover : modeledBANMonthly

        // Optional: derive BAN rate from a stated annual interest amount (if user enters it)
        let statedAnnualInterest = max(0, inputs.statedBANAnnualInterestForPeriod)
        let statedMonthly = statedAnnualInterest > 0 ? (statedAnnualInterest / 12.0) : nil

        let preDeltaModeled = preMonthly - modeledBANMonthly
        let extDeltaModeledBAN = extMonthly - chosenBANMonthly
        let extDeltaBond = extMonthly - bond.monthlyEquivalent

        let preDeltaStated = statedMonthly != nil ? (preMonthly - (statedMonthly ?? 0)) : nil

        return VStack(alignment: .leading, spacing: 12) {
            Text("Lease coverage (what-if)")
                .font(.headline)

            Text("Compares monthly lease payments against modeled BAN interest/month and the modeled bond monthly-equivalent (conversion).")
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, 2)

            // Editable lease inputs
            VStack(spacing: 10) {
                currencyField(title: "Pre-possession lease (monthly)", value: $inputs.prePossessionLeaseMonthly)
                currencyField(title: "Extended lease if closing delayed (monthly)", value: $inputs.extendedLeaseMonthly)
            }

            Divider().padding(.vertical, 2)

            // Optional stated interest to compare against
            VStack(alignment: .leading, spacing: 6) {
                Text("Optional: stated BAN interest for the period (total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Stated interest (optional)", text: Binding(
                    get: { inputs.statedBANAnnualInterestForPeriod == 0 ? "" : inputs.statedBANAnnualInterestForPeriod.currency(allowCents: false) },
                    set: { inputs.statedBANAnnualInterestForPeriod = Double.parseCurrency($0) }
                ))
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)

                if let statedMonthly, statedMonthly > 0 {
                    Text("That’s ≈ \(statedMonthly.currency(allowCents: false)) / month.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Divider().padding(.vertical, 2)

            // Coverage blocks
            VStack(alignment: .leading, spacing: 10) {

                VStack(alignment: .leading, spacing: 6) {
                    Text("Pre-possession lease")
                        .font(.subheadline.weight(.semibold))

                    metricRow("Monthly lease", preMonthly.currency(allowCents: false))
                    metricRow("Annualized", preAnnual.currency(allowCents: false))

                    if let preDeltaStated {
                        metricRow("Vs stated monthly-equivalent", preDeltaStated.signedCurrency())
                    }

                    metricRow("Vs modeled BAN interest/month", preDeltaModeled.signedCurrency())

                    Text("Modeled BAN interest/month uses your BAN dates, rate, and day-count basis.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Divider().padding(.vertical, 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Extended lease (if closing delayed)")
                        .font(.subheadline.weight(.semibold))

                    metricRow("Monthly lease", extMonthly.currency(allowCents: false))
                    metricRow("Annualized", extAnnual.currency(allowCents: false))
                    metricRow("Vs modeled BAN interest/month", extDeltaModeledBAN.signedCurrency())
                    metricRow("Vs modeled bond monthly-equivalent", extDeltaBond.signedCurrency())

                    Text("Modeled bond monthly-equivalent: \(bond.monthlyEquivalent.currency(allowCents: false)) / month.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if base.days > 0 {
                    Divider().padding(.vertical, 2)
                    Text("Your current BAN inputs estimate interest of \(base.interest.currency(allowCents: false)) over \(base.days) days.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - BAN Inputs

    private var banInputs: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("BAN + Conversion inputs")
                    .font(.headline)
                Spacer()
                Button("Reset to MDA Defaults") {
                    withAnimation(.snappy) { inputs = .defaultsFromMDA }
                }
                .buttonStyle(.bordered)
            }

            VStack(spacing: 10) {
                TextField("Project title (optional)", text: $inputs.projectTitle)
                    .textFieldStyle(.roundedBorder)

                currencyField(title: "BAN principal", value: $inputs.principal)
                percentField(title: "BAN annual interest rate", value: $inputs.annualRate)

                Picker("Day-count basis", selection: $inputs.dayCountBasis) {
                    ForEach(DayCountBasis.allCases) { b in
                        Text(b.label).tag(b)
                    }
                }

                DatePicker("Issue date", selection: $inputs.issueDate, displayedComponents: [.date])
                DatePicker("Maturity date", selection: $inputs.maturityDate, displayedComponents: [.date])

                Toggle("Show advanced scenario settings", isOn: $showAdvanced)

                if showAdvanced {
                    Divider().padding(.vertical, 4)

                    Text("Rollovers (optional what-if)")
                        .font(.subheadline.weight(.semibold))

                    Stepper(value: $inputs.rolloverCount, in: 0...10) {
                        HStack {
                            Text("Expected rollovers")
                            Spacer()
                            Text("\(inputs.rolloverCount)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Stepper(value: $inputs.rolloverDurationDays, in: 30...365, step: 30) {
                        HStack {
                            Text("Days per rollover")
                            Spacer()
                            Text("\(inputs.rolloverDurationDays) days")
                                .foregroundStyle(.secondary)
                        }
                    }

                    percentField(title: "Rate bump each rollover", value: $inputs.rolloverRateBump)

                    Divider().padding(.vertical, 4)

                    HStack {
                        Text("Bond conversion")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Button("Set 15y @ 3.5%") {
                            inputs.bondRate = 0.035
                            inputs.bondTermYears = 15
                            inputs.paymentsPerYear = 2
                        }
                        .buttonStyle(.bordered)
                    }

                    percentField(title: "Bond rate (annual)", value: $inputs.bondRate)

                    Stepper(value: $inputs.bondTermYears, in: 1...40) {
                        HStack {
                            Text("Bond term")
                            Spacer()
                            Text("\(inputs.bondTermYears) years")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Picker("Payments per year", selection: $inputs.paymentsPerYear) {
                        Text("1 (Annual)").tag(1)
                        Text("2 (Semiannual)").tag(2)
                        Text("12 (Monthly)").tag(12)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Results

    private var resultsSummary: some View {
        let base = BANImpactEngine.baseBAN(inputs: inputs)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Estimated cost (BAN term)")
                .font(.headline)

            metricRow("Days outstanding", "\(base.days)")
            metricRow("Estimated interest", base.interest.currency(allowCents: false))
            metricRow("Total due at maturity (principal + interest)", base.totalDue.currency(allowCents: false))

            Divider().padding(.vertical, 4)

            metricRow("Interest per day (avg)", base.interestPerDay.currency(allowCents: false))
            metricRow("Interest per month (avg)", base.interestPerMonth.currency(allowCents: false))

            if base.days <= 0 {
                Text("Check your dates: maturity should be after issue date.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Scenario Compare

    private var scenarioCompare: some View {
        let base = BANImpactEngine.baseBAN(inputs: inputs)
        let rollover = BANImpactEngine.rolloverScenario(inputs: inputs)
        let bond = BANImpactEngine.bondConversionScenario(inputs: inputs)
        let om = TownSquareMDATerms.townSquareOMAnnualFee
        let omMonthly = om / 12.0

        return VStack(alignment: .leading, spacing: 12) {
            Text("Scenarios")
                .font(.headline)

            VStack(spacing: 10) {
                scenarioCard(
                    title: "BAN (hold to maturity)",
                    subtitle: "Simple interest estimate on the selected term.",
                    interest: base.interest,
                    total: base.totalDue,
                    days: base.days
                )

                scenarioCard(
                    title: "BAN with rollovers (\(inputs.rolloverCount))",
                    subtitle: "Adds \(inputs.rolloverCount) periods of \(inputs.rolloverDurationDays) days; rate bumps each rollover.",
                    interest: rollover.totalInterest,
                    total: inputs.principal + rollover.totalInterest,
                    days: rollover.totalDays
                )

                scenarioBondCard(bond: bond)

                // MDA O&M context
                VStack(alignment: .leading, spacing: 6) {
                    Text("O&M context (MDA)")
                        .font(.subheadline.weight(.semibold))

                    Text("Town Square Operation & Management fee: \(om.currency(allowCents: false))/yr (≈ \(omMonthly.currency(allowCents: false))/mo) for \(TownSquareMDATerms.townSquareOMTermYears) years.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    metricRow("Bond monthly-equivalent", bond.monthlyEquivalent.currency(allowCents: false))
                    metricRow("Bond + O&M (monthly)", (bond.monthlyEquivalent + omMonthly).currency(allowCents: false))
                }
                .padding(12)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            #if canImport(Charts)
            if base.days > 0 {
                Divider().padding(.vertical, 6)
                Text("Interest comparison")
                    .font(.subheadline.weight(.semibold))

                Chart {
                    BarMark(
                        x: .value("Scenario", "BAN"),
                        y: .value("Interest", base.interest)
                    )
                    BarMark(
                        x: .value("Scenario", "Rollovers"),
                        y: .value("Interest", rollover.totalInterest)
                    )
                    BarMark(
                        x: .value("Scenario", "Bond (Yr1 est)"),
                        y: .value("Interest", max(0, bond.firstYearInterestEstimate))
                    )
                }
                .frame(height: 190)
            }
            #endif
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Sensitivity

    private var sensitivity: some View {
        let base = BANImpactEngine.baseBAN(inputs: inputs)

        let down = max(0, inputs.annualRate - 0.01)
        let up = inputs.annualRate + 0.01

        let iDown = BANImpactEngine.simpleInterest(
            principal: inputs.principal,
            annualRate: down,
            days: base.days,
            basis: inputs.dayCountBasis
        )

        let iUp = BANImpactEngine.simpleInterest(
            principal: inputs.principal,
            annualRate: up,
            days: base.days,
            basis: inputs.dayCountBasis
        )

        return VStack(alignment: .leading, spacing: 12) {
            Text("Rate sensitivity")
                .font(.headline)

            Text("How much BAN interest changes if the BAN rate moves ±1.00%.")
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                metricRow("At \(down.percentString())", iDown.currency(allowCents: false))
                metricRow("At \(inputs.annualRate.percentString())", base.interest.currency(allowCents: false))
                metricRow("At \(up.percentString())", iUp.currency(allowCents: false))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var fundBalanceContext: some View {
        let annualDebtCarry = TownSquareMDATerms.townSquareOMAnnualFee
        let bond = BANImpactEngine.bondConversionScenario(inputs: inputs)

        return VStack(alignment: .leading, spacing: 10) {
            Text("Fund balance context")
                .font(.headline)

            Text("This tool estimates financing cost, but the budget question is how the Town chooses to pay for it.")
                .foregroundStyle(.secondary)

            bullet("If the Town borrows, debt service becomes a recurring budget line and the reserve cushion is preserved more in the short term.")
            bullet("If the Town uses fund balance instead, there is less new debt but the General Fund cushion falls immediately.")
            bullet("Riverhead's policy benchmark elsewhere in the app is a **15% minimum** reserve. If a draw would reduce projected fund balance below that level, the policy says the Town Board should approve the appropriation by **resolution**.")
            bullet("Using your current bond assumptions, the modeled recurring carry is about \(bond.annualDebtService.currency(allowCents: false)) per year in debt service, before adding the \(annualDebtCarry.currency(allowCents: false)) annual O&M obligation.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Notes

    private var notesAndDisclaimers: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notes")
                .font(.headline)

            bullet("This focuses on **interest**. BAN issuance/renewal costs (legal, underwriting, bank fees) aren’t included.")
            bullet("Day-count basis often uses **Actual/360** for short-term instruments. Confirm the actual convention in the BAN documents.")
            bullet("Conversion is modeled as **fixed-rate level-payment amortization**. Municipal debt service can be structured differently (non-level schedules, call features, capitalized interest, etc.).")
            bullet("MDA credit language: grant commitments are credited **to the extent already paid to the Town**. Enter what’s actually been paid.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - UI Helpers

    private func metricRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
            Spacer()
            Text(value)
                .font(.body.weight(.semibold))
        }
        .padding(.vertical, 2)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").font(.headline)
            Text(.init(text))
                .foregroundStyle(.secondary)
        }
    }

    private func scenarioCard(title: String, subtitle: String, interest: Double, total: Double, days: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.weight(.semibold))
            Text(subtitle).font(.caption).foregroundStyle(.secondary)

            Divider().padding(.vertical, 4)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Interest").font(.caption).foregroundStyle(.secondary)
                    Text(interest.currency(allowCents: false)).font(.body.weight(.semibold))
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total due").font(.caption).foregroundStyle(.secondary)
                    Text(total.currency(allowCents: false)).font(.body.weight(.semibold))
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Days").font(.caption).foregroundStyle(.secondary)
                    Text("\(max(0, days))").font(.body.weight(.semibold))
                }
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func scenarioBondCard(bond: BondConversionEstimate) -> some View {
        let title = "Convert to long-term debt (\(bond.termYears)y @ \(bond.annualRate.percentString()))"
        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            Text("Level-payment amortization using your conversion assumptions.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, 4)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Payment").font(.caption).foregroundStyle(.secondary)
                    Text(bond.paymentPerPeriod.currency(allowCents: false)).font(.body.weight(.semibold))
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Payments/yr").font(.caption).foregroundStyle(.secondary)
                    Text("\(bond.paymentsPerYear)").font(.body.weight(.semibold))
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly equiv.").font(.caption).foregroundStyle(.secondary)
                    Text(bond.monthlyEquivalent.currency(allowCents: false)).font(.body.weight(.semibold))
                }
            }

            Divider().padding(.vertical, 4)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total paid (term)").font(.caption).foregroundStyle(.secondary)
                    Text(bond.totalPaid.currency(allowCents: false)).font(.body.weight(.semibold))
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total interest (term)").font(.caption).foregroundStyle(.secondary)
                    Text(bond.totalInterest.currency(allowCents: false)).font(.body.weight(.semibold))
                }
            }

            if bond.isDegenerate {
                Text("Bond estimate needs a positive term and rate; check conversion inputs.")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 4)
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func currencyField(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            TextField(title, text: Binding(
                get: { value.wrappedValue == 0 ? "" : value.wrappedValue.currency(allowCents: false) },
                set: { value.wrappedValue = Double.parseCurrency($0) }
            ))
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
        }
    }

    private func percentField(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            TextField(title, text: Binding(
                get: { value.wrappedValue.percentString() },
                set: { value.wrappedValue = Double.parsePercent($0) }
            ))
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - Executed MDA Terms (constants)

private enum TownSquareMDATerms {
    // MDA §3.04(a)
    static let purchasePrice: Double = 2_625_000.00
    static let downPaymentRate: Double = 0.05

    // MDA §3.04(a) grant commitments (credited to the extent paid to Town)
    static let grantCommitments: [Double] = [360_000.00, 150_000.00, 150_000.00]

    // MDA negotiation note / strategies section (also reiterated later)
    static let townSquareOMAnnualFee: Double = 150_000.00
    static let townSquareOMTermYears: Int = 10

    // MDA strategies summary section
    static let hotelRoomsMax: Int = 76
    static let condoUnits: Int = 12

    static var downPaymentAmount: Double { purchasePrice * downPaymentRate }
    static var totalGrantCommitments: Double { grantCommitments.reduce(0, +) }
}

// MARK: - Inputs Model

private struct BANInputs: Equatable {
    var projectTitle: String

    // BAN principal + terms
    var principal: Double
    var annualRate: Double
    var dayCountBasis: DayCountBasis
    var issueDate: Date
    var maturityDate: Date

    // Optional rollovers
    var rolloverCount: Int
    var rolloverDurationDays: Int
    var rolloverRateBump: Double

    // Bond conversion
    var bondRate: Double
    var bondTermYears: Int
    var paymentsPerYear: Int

    // Acquisition math inputs (MDA-driven)
    var creditsAlreadyPaidToTown: Double
    var estimatedTransferAndClosingCosts: Double

    // Lease coverage inputs (editable)
    var prePossessionLeaseMonthly: Double
    var extendedLeaseMonthly: Double
    var statedBANAnnualInterestForPeriod: Double

    static var defaultsFromMDA: BANInputs {
        let cal = Calendar(identifier: .gregorian)

        // Keep the previously-used BAN window as a sensible default (editable).
        let issue = cal.date(from: DateComponents(year: 2025, month: 8, day: 15)) ?? Date()
        let maturity = cal.date(from: DateComponents(year: 2026, month: 8, day: 15))
            ?? Calendar.current.date(byAdding: .year, value: 1, to: Date())
            ?? issue

        return BANInputs(
            projectTitle: "Riverhead Town Square Project",
            principal: TownSquareMDATerms.purchasePrice,
            annualRate: 0.04,                // Placeholder default; set to actual BAN rate if known
            dayCountBasis: .actual360,
            issueDate: issue,
            maturityDate: maturity,
            rolloverCount: 0,
            rolloverDurationDays: 180,
            rolloverRateBump: 0.005,
            bondRate: 0.035,
            bondTermYears: 15,
            paymentsPerYear: 2,
            creditsAlreadyPaidToTown: 0,     // Enter the amount actually paid to Town (credited at closing)
            estimatedTransferAndClosingCosts: 0,
            prePossessionLeaseMonthly: 17_500, // defaults retained; edit to match the lease amendment
            extendedLeaseMonthly: 19_000,      // defaults retained; edit to match the lease amendment
            statedBANAnnualInterestForPeriod: 0
        )
    }
}

// MARK: - Day Count

private enum DayCountBasis: String, CaseIterable, Identifiable {
    case actual360
    case actual365

    var id: String { rawValue }

    var label: String {
        switch self {
        case .actual360: return "Actual/360"
        case .actual365: return "Actual/365"
        }
    }

    var denominator: Double {
        switch self {
        case .actual360: return 360.0
        case .actual365: return 365.0
        }
    }
}

// MARK: - Calculation Engine

private enum BANImpactEngine {

    struct BaseBAN {
        let days: Int
        let interest: Double
        let totalDue: Double
        let interestPerDay: Double
        let interestPerMonth: Double
    }

    struct RolloverScenario {
        let totalDays: Int
        let totalInterest: Double
        let trancheBreakdown: [Tranche]
        struct Tranche: Identifiable {
            let id = UUID()
            let index: Int
            let days: Int
            let rate: Double
            let interest: Double
        }
    }

    static func baseBAN(inputs: BANInputs) -> BaseBAN {
        let days = max(0, daysBetween(inputs.issueDate, inputs.maturityDate))
        let interest = simpleInterest(
            principal: inputs.principal,
            annualRate: inputs.annualRate,
            days: days,
            basis: inputs.dayCountBasis
        )
        let totalDue = inputs.principal + interest
        let perDay = days > 0 ? (interest / Double(days)) : 0
        let perMonth = days > 0 ? (interest / max(1.0, Double(days) / 30.0)) : 0

        return BaseBAN(
            days: days,
            interest: interest,
            totalDue: totalDue,
            interestPerDay: perDay,
            interestPerMonth: perMonth
        )
    }

    static func rolloverScenario(inputs: BANInputs) -> RolloverScenario {
        let baseDays = max(0, daysBetween(inputs.issueDate, inputs.maturityDate))
        var totalInterest = 0.0
        var breakdown: [RolloverScenario.Tranche] = []

        let i0 = simpleInterest(principal: inputs.principal, annualRate: inputs.annualRate, days: baseDays, basis: inputs.dayCountBasis)
        totalInterest += i0
        breakdown.append(.init(index: 0, days: baseDays, rate: inputs.annualRate, interest: i0))

        if inputs.rolloverCount > 0 && inputs.rolloverDurationDays > 0 {
            for n in 1...inputs.rolloverCount {
                let r = inputs.annualRate + Double(n) * inputs.rolloverRateBump
                let d = inputs.rolloverDurationDays
                let ix = simpleInterest(principal: inputs.principal, annualRate: r, days: d, basis: inputs.dayCountBasis)
                totalInterest += ix
                breakdown.append(.init(index: n, days: d, rate: r, interest: ix))
            }
        }

        let totalDays = baseDays + inputs.rolloverCount * max(0, inputs.rolloverDurationDays)
        return RolloverScenario(totalDays: totalDays, totalInterest: totalInterest, trancheBreakdown: breakdown)
    }

    static func bondConversionScenario(inputs: BANInputs) -> BondConversionEstimate {
        BondConversionEstimate(
            principal: inputs.principal,
            annualRate: inputs.bondRate,
            termYears: inputs.bondTermYears,
            paymentsPerYear: inputs.paymentsPerYear
        )
    }

    static func simpleInterest(principal: Double, annualRate: Double, days: Int, basis: DayCountBasis) -> Double {
        guard principal > 0, annualRate >= 0, days > 0 else { return 0 }
        return principal * annualRate * (Double(days) / basis.denominator)
    }

    static func daysBetween(_ a: Date, _ b: Date) -> Int {
        let comps = Calendar.current.dateComponents([.day], from: a, to: b)
        return comps.day ?? 0
    }
}

// MARK: - Bond Conversion Estimate

private struct BondConversionEstimate: Equatable {
    let principal: Double
    let annualRate: Double
    let termYears: Int
    let paymentsPerYear: Int

    var isDegenerate: Bool {
        principal <= 0 || annualRate < 0 || termYears <= 0 || paymentsPerYear <= 0
    }

    private var nPeriods: Int { max(0, termYears * paymentsPerYear) }
    private var ratePerPeriod: Double { annualRate / Double(max(1, paymentsPerYear)) }

    var paymentPerPeriod: Double {
        guard !isDegenerate, nPeriods > 0 else { return 0 }
        let n = Double(nPeriods)
        let r = ratePerPeriod
        if r == 0 { return principal / max(1, n) }
        let denom = 1 - pow(1 + r, -n)
        guard denom != 0 else { return 0 }
        return principal * r / denom
    }

    var totalPaid: Double {
        guard !isDegenerate else { return 0 }
        return paymentPerPeriod * Double(nPeriods)
    }

    var totalInterest: Double {
        max(0, totalPaid - principal)
    }

    var annualDebtService: Double {
        guard !isDegenerate else { return 0 }
        return paymentPerPeriod * Double(paymentsPerYear)
    }

    var monthlyEquivalent: Double {
        guard !isDegenerate else { return 0 }
        return annualDebtService / 12.0
    }

    var firstYearInterestEstimate: Double {
        guard !isDegenerate else { return 0 }
        let r = ratePerPeriod
        let pmt = paymentPerPeriod
        var balance = principal
        var interestSum = 0.0

        for _ in 0..<max(1, paymentsPerYear) {
            let interest = balance * r
            let principalPaid = max(0, pmt - interest)
            balance = max(0, balance - principalPaid)
            interestSum += interest
            if balance <= 0 { break }
        }
        return interestSum
    }
}

// MARK: - Formatting / Parsing

private extension Double {
    static let _currency0: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.maximumFractionDigits = 0
        nf.minimumFractionDigits = 0
        return nf
    }()

    static let _currency2: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 2
        return nf
    }()

    func currency(allowCents: Bool = true) -> String {
        let nf = allowCents ? Self._currency2 : Self._currency0
        return nf.string(from: NSNumber(value: self)) ?? "$0"
    }

    func signedCurrency() -> String {
        let sign = self >= 0 ? "+" : "−"
        return "\(sign)\(abs(self).currency(allowCents: false))"
    }

    func percentString() -> String {
        let pct = self * 100.0
        return String(format: "%.2f%%", pct)
    }

    static func parseCurrency(_ text: String) -> Double {
        let cleaned = text.replacingOccurrences(of: "[^0-9.\\-]", with: "", options: .regularExpression)
        return Double(cleaned) ?? 0
    }

    static func parsePercent(_ text: String) -> Double {
        let cleaned = text
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: " ", with: "")
        let raw = Double(cleaned) ?? 0
        return raw > 1.0 ? (raw / 100.0) : raw
    }
}

private extension Comparable {
    func clamped(to r: ClosedRange<Self>) -> Self {
        min(max(self, r.lowerBound), r.upperBound)
    }
}

// MARK: - Preview

#Preview("TownSquareBANImpactView") {
    NavigationStack {
        TownSquareBANImpactView(accent: .indigo)
    }
}
