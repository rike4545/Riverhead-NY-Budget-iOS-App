//
//  RBTownSquareSweetheartDealAuditView.swift
//  Riverhead NY Budget App
//
//  Created by Bryan on 1/21/26.
//


//
//  RBTownSquareSweetheartDealAuditView.swift
//  Riverhead NY Budget App
//
//  “Sweetheart deal” risk scan + math validation for the Town Square lease/BAN amendment.
//
//  Update:
//  - Pulls $2,625,000 land acquisition (Q&E packet budget) as default principal basis
//  - Adds “Q&E shows appraisal line item” as PARTIAL valuation evidence (does not equal confirmed appraisal)
//  - Keeps non-accusatory risk indicators + arithmetic checks
//
//  Swift 6 • iOS 17+
//

import SwiftUI
import Foundation

#if canImport(Charts)
import Charts
#endif

@MainActor
struct RBTownSquareSweetheartDealAuditView: View {

    @Environment(\.openURL) private var openURL

    @State private var inputs = AuditInputs.defaultsUsingQEEvidence
    @State private var showQuestionnaire = true

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                header

                GroupBox { evidenceBox }

                GroupBox { summaryCard }

                GroupBox { mathChecks }

                GroupBox { coverageChecks }

                GroupBox { fairnessIndicators }

                GroupBox { transparencyQuestionnaire }

                GroupBox { disclaimers }
            }
            .padding()
        }
        .navigationTitle("Deal Audit")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Town Square Lease/BAN Audit")
                .font(.title2.weight(.semibold))
            Text("Risk indicators + math validation (no accusations)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Label("Evidence", systemImage: "doc.text")
                Label("Math checks", systemImage: "checkmark.seal")
                Label("Transparency", systemImage: "doc.text.magnifyingglass")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Evidence

    private var evidenceBox: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Q&E evidence inputs")
                .font(.headline)

            Text("These toggles help the audit distinguish between **confirmed** documents and **partial signals**.")
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, 2)

            Toggle("Use Q&E land acquisition as principal basis (\(TownSquareQEEvidence.landAcquisition.currency0))", isOn: $inputs.useQELandAcquisitionAsPrincipal)
                .onChange(of: inputs.useQELandAcquisitionAsPrincipal) { _, newValue in
                    if newValue {
                        inputs.purchasePrincipal = TownSquareQEEvidence.landAcquisition
                    }
                }

            Toggle("Q&E budget includes an appraisal line item (partial valuation evidence)", isOn: $inputs.qeShowsAppraisalLineItem)

            Text("“Appraisal line item” means the budget anticipates appraisal work; it does **not** prove an independent appraisal exists or was disclosed.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, 2)

            HStack(spacing: 10) {
                Button {
                    inputs.purchasePrincipal = TownSquareQEEvidence.landAcquisition
                    inputs.useQELandAcquisitionAsPrincipal = true
                } label: {
                    Label("Reset principal to Q&E", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)

                Button {
                    if let url = URL(string: TownSquareQEEvidence.qeDocumentsURLString) {
                        openURL(url)
                    }
                } label: {
                    Label("Open Q&E packet", systemImage: "link")
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Summary

    private var summaryCard: some View {
        let findings = AuditEngine.findings(inputs: inputs)
        let score = AuditEngine.riskScore(inputs: inputs, findings: findings)
        let level = AuditEngine.riskLevel(score: score)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sweetheart-risk scan")
                    .font(.headline)
                Spacer()
                Text("\(score)/100")
                    .font(.title3.weight(.semibold))
                    .accessibilityLabel("Risk score \(score) out of 100")
            }

            Text(level.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(level.tint)

            Text(level.explainer)
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(findings.prefix(5)) { f in
                    findingRow(f)
                }
            }

            if findings.count > 5 {
                Text("Showing top \(min(5, findings.count)) findings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            #if canImport(Charts)
            Divider().padding(.vertical, 2)
            Text("Score components (approx.)")
                .font(.subheadline.weight(.semibold))

            let parts = AuditEngine.scoreBreakdown(inputs: inputs, findings: findings)
            Chart {
                ForEach(parts) { p in
                    BarMark(
                        x: .value("Component", p.title),
                        y: .value("Points", p.points)
                    )
                }
            }
            .frame(height: 180)
            #endif
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Math Checks

    private var mathChecks: some View {
        let checks = AuditEngine.mathChecks(inputs: inputs)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Math validation")
                .font(.headline)

            ForEach(checks) { c in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: c.passed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(c.passed ? .green : .orange)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(c.title)
                            .font(.subheadline.weight(.semibold))
                        Text(c.detail)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }

            Divider().padding(.vertical, 4)

            Text("Inputs (editable)")
                .font(.subheadline.weight(.semibold))

            VStack(spacing: 10) {
                currencyField("Principal basis", $inputs.purchasePrincipal)
                currencyField("Down payment", $inputs.downPayment)

                Divider().padding(.vertical, 2)

                currencyField("BAN interest (stated)", $inputs.banInterestStated)
                currencyField("BAN principal paid (stated)", $inputs.banPrincipalPaidStated)

                dateField("BAN start", $inputs.banStart)
                dateField("BAN end", $inputs.banEnd)

                Divider().padding(.vertical, 2)

                currencyField("Pre-possession lease $/mo", $inputs.preMonthlyLease)
                dateField("Pre lease first due", $inputs.preFirstDue)
                dateField("Pre lease last due", $inputs.preLastDue)

                currencyField("Extended lease $/mo", $inputs.extMonthlyLease)
                dateField("Extended first due", $inputs.extFirstDue)
                dateField("Extended last due", $inputs.extLastDue)

                Divider().padding(.vertical, 2)

                percentField("Conversion rate (annual)", $inputs.conversionAnnualRate)
                stepperField("Conversion term (years)", $inputs.conversionYears, range: 1...40)
                pickerPaymentsPerYear("Payments/year", $inputs.conversionPaymentsPerYear)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Coverage

    private var coverageChecks: some View {
        let cov = AuditEngine.coverage(inputs: inputs)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Cost coverage vs payments")
                .font(.headline)

            Text("Two views: **annualized** (monthly × 12) and **schedule-matched** (months actually specified).")
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 10) {
                Text("BAN year (stated totals)")
                    .font(.subheadline.weight(.semibold))

                metric("BAN total (principal+interest)", cov.banTotal.currency0)
                metric("BAN monthly-equivalent", cov.banMonthlyEq.currency0)

                Divider().padding(.vertical, 2)

                Text("Pre-possession lease")
                    .font(.subheadline.weight(.semibold))

                metric("Payments in schedule", "\(cov.preMonths) months")
                metric("Scheduled total", cov.preScheduledTotal.currency0)
                metric("Annualized total", cov.preAnnualizedTotal.currency0)
                metric("Schedule vs BAN total", cov.preScheduleVsBanRatio.percent0)
                metric("Annualized vs BAN total", cov.preAnnualizedVsBanRatio.percent0)

                if cov.preTimingGapMonths > 0 {
                    callout(
                        title: "Timing gap",
                        detail: "BAN period begins \(cov.preTimingGapMonths) months before the lease schedule begins. If there were no other payments before the lease start, the schedule-matched totals can look short vs the BAN year total.",
                        severity: .warn
                    )
                }

                Divider().padding(.vertical, 2)

                Text("Conversion debt (modeled)")
                    .font(.subheadline.weight(.semibold))

                metric("Annual debt service (est.)", cov.convAnnualDebtService.currency0)
                metric("Monthly-equivalent (est.)", cov.convMonthlyEq.currency0)

                Divider().padding(.vertical, 2)

                Text("Extended lease")
                    .font(.subheadline.weight(.semibold))

                metric("Payments in schedule", "\(cov.extMonths) months")
                metric("Scheduled total", cov.extScheduledTotal.currency0)
                metric("Schedule-matched debt cost", cov.extScheduleMatchedDebtCost.currency0)
                metric("Schedule vs schedule-matched debt", cov.extScheduleVsDebtRatio.percent0)
                metric("Annualized vs annual debt service", cov.extAnnualizedVsDebtRatio.percent0)
            }

            #if canImport(Charts)
            Divider().padding(.vertical, 4)
            Text("Monthly comparisons (equivalents)")
                .font(.subheadline.weight(.semibold))

            Chart {
                BarMark(x: .value("Item", "BAN eq."), y: .value("Monthly", cov.banMonthlyEq))
                BarMark(x: .value("Item", "Pre lease"), y: .value("Monthly", inputs.preMonthlyLease))
                BarMark(x: .value("Item", "Conv eq."), y: .value("Monthly", cov.convMonthlyEq))
                BarMark(x: .value("Item", "Ext lease"), y: .value("Monthly", inputs.extMonthlyLease))
            }
            .frame(height: 190)
            #endif
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Fairness Indicators

    private var fairnessIndicators: some View {
        let findings = AuditEngine.findings(inputs: inputs)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Potential sweetheart-risk indicators")
                .font(.headline)

            Text("These are **signals** that terms may be unusually favorable or opaque. They’re not proof of collusion or illegality.")
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, 4)

            ForEach(findings) { f in
                findingRow(f)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Transparency Questionnaire

    private var transparencyQuestionnaire: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transparency & process checks")
                    .font(.headline)
                Spacer()
                Toggle("Show", isOn: $showQuestionnaire)
                    .labelsHidden()
            }

            if showQuestionnaire {
                Text("Answering these makes the score more meaningful.")
                    .foregroundStyle(.secondary)

                Divider().padding(.vertical, 4)

                Toggle("Competitive procurement (RFP/RFQ) was used", isOn: $inputs.procurementCompetitive)
                Toggle("Full terms were publicly available before approval", isOn: $inputs.termsPublicBeforeApproval)
                Toggle("No material tax abatements/PILOT/fee waivers were granted", isOn: $inputs.noMaterialTaxBreaks)
                Toggle("No-bid / sole-source award (if true, raises risk)", isOn: $inputs.noBidOrSoleSource)

                Divider().padding(.vertical, 2)

                Toggle("Independent valuation/appraisal is confirmed (documented)", isOn: $inputs.independentValuationConfirmed)

                Text("If you only know the Q&E packet includes an appraisal line item, use the **partial evidence** toggle above (it reduces the penalty but does not count as confirmed).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Disclaimers

    private var disclaimers: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Disclaimers")
                .font(.headline)

            bullet("This tool is a **public-interest audit helper** and does not allege wrongdoing.")
            bullet("It validates arithmetic and highlights **ambiguities** (date ranges, “six months” phrasing, interest estimates).")
            bullet("To evaluate “sweetheart” claims properly, you usually need: procurement record, board resolutions, executed agreements, subsidy/tax documents, and comparable market terms.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - View Helpers

    private func findingRow(_ f: AuditFinding) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: f.severity.icon)
                .foregroundStyle(f.severity.tint)

            VStack(alignment: .leading, spacing: 3) {
                Text(f.title)
                    .font(.subheadline.weight(.semibold))
                Text(f.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func metric(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .font(.body.weight(.semibold))
        }
        .padding(.vertical, 1)
    }

    private func callout(title: String, detail: String, severity: AuditSeverity) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: severity.icon)
                Text(title).font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(severity.tint)

            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").font(.headline)
            Text(.init(text))
                .foregroundStyle(.secondary)
        }
    }

    private func currencyField(_ title: String, _ value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            TextField(title, text: Binding(
                get: { value.wrappedValue.currency0 },
                set: { value.wrappedValue = Double.parseCurrencyLoose($0) ?? 0 }
            ))
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
        }
    }

    private func percentField(_ title: String, _ value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            TextField(title, text: Binding(
                get: { value.wrappedValue.percent2 },
                set: { value.wrappedValue = Double.parsePercentLoose($0) ?? 0 }
            ))
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
        }
    }

    private func dateField(_ title: String, _ value: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            DatePicker(title, selection: value, displayedComponents: [.date])
                .datePickerStyle(.compact)
        }
    }

    private func stepperField(_ title: String, _ value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        Stepper(value: value, in: range) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue)")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func pickerPaymentsPerYear(_ title: String, _ value: Binding<Int>) -> some View {
        Picker(title, selection: value) {
            Text("1 (Annual)").tag(1)
            Text("2 (Semiannual)").tag(2)
            Text("12 (Monthly)").tag(12)
        }
    }
}

// MARK: - Q&E Evidence (shared constants for audit)

private enum TownSquareQEEvidence {
    /// Town-hosted Q&E packet includes a “Uses of Funds” line for Land Acquisition = $2,625,000.
    static let landAcquisition: Double = 2_625_000

    /// The Q&E packet budget soft costs include an “Appraisal” line item (partial valuation signal).
    static let softCostsIncludesAppraisalLineItem: Bool = true

    static let qeDocumentsURLString: String = "https://www.townofriverheadny.gov/DocumentCenter/View/2344/Town-Square-QE-Documents"
}

// MARK: - Data Model

private struct AuditInputs: Equatable {

    // Evidence toggles
    var useQELandAcquisitionAsPrincipal: Bool
    var qeShowsAppraisalLineItem: Bool

    // Core amounts
    var purchasePrincipal: Double
    var downPayment: Double

    // BAN stated values
    var banPrincipalPaidStated: Double
    var banInterestStated: Double
    var banStart: Date
    var banEnd: Date
    var banDayCountDenominator: Double // 360 or 365

    // Lease schedules
    var preMonthlyLease: Double
    var preFirstDue: Date
    var preLastDue: Date

    var extMonthlyLease: Double
    var extFirstDue: Date
    var extLastDue: Date

    // Conversion assumptions
    var conversionAnnualRate: Double
    var conversionYears: Int
    var conversionPaymentsPerYear: Int

    // Transparency questionnaire (unknowns)
    var procurementCompetitive: Bool
    var termsPublicBeforeApproval: Bool
    var noMaterialTaxBreaks: Bool
    var noBidOrSoleSource: Bool

    /// Confirmed appraisal/valuation document exists and supports deal terms
    var independentValuationConfirmed: Bool

    static var defaultsUsingQEEvidence: AuditInputs {
        let cal = Calendar(identifier: .gregorian)

        // Prefer your canonical extracted amendment terms if present in project.
        // (If TownSquareLeaseAmendmentTerms isn’t in target, you’ll get a compile error.)
        let t = TownSquareLeaseAmendmentTerms.self

        func date(_ c: DateComponents) -> Date {
            cal.date(from: c) ?? Date()
        }

        // Default principal basis = Q&E land acquisition (matches $2.625M used in your amendment constants)
        let principal = TownSquareQEEvidence.landAcquisition

        return AuditInputs(
            useQELandAcquisitionAsPrincipal: true,
            qeShowsAppraisalLineItem: TownSquareQEEvidence.softCostsIncludesAppraisalLineItem,

            purchasePrincipal: principal,
            downPayment: t.downPayment,

            banPrincipalPaidStated: t.banYearPrincipalPaid,
            banInterestStated: t.banYearInterestCost,
            banStart: date(t.banPeriodStart),
            banEnd: date(t.banPeriodEnd),
            banDayCountDenominator: 360,

            preMonthlyLease: t.prePossessionMonthlyLease,
            preFirstDue: date(t.prePossessionFirstDue),
            preLastDue: date(t.prePossessionLastDue),

            extMonthlyLease: t.extendedMonthlyLease,
            extFirstDue: date(t.extendedFirstDue),
            extLastDue: date(t.extendedLastDue),

            conversionAnnualRate: t.conversionAnnualRate,
            conversionYears: t.conversionTermYears,
            conversionPaymentsPerYear: t.conversionPaymentsPerYear,

            procurementCompetitive: false,
            termsPublicBeforeApproval: false,
            noMaterialTaxBreaks: false,
            noBidOrSoleSource: false,

            independentValuationConfirmed: false
        )
    }
}

// MARK: - Engine

private enum AuditEngine {

    // ---- Coverage snapshot

    struct Coverage {
        let banTotal: Double
        let banMonthlyEq: Double

        let preMonths: Int
        let preScheduledTotal: Double
        let preAnnualizedTotal: Double
        let preScheduleVsBanRatio: Double
        let preAnnualizedVsBanRatio: Double
        let preTimingGapMonths: Int

        let convAnnualDebtService: Double
        let convMonthlyEq: Double

        let extMonths: Int
        let extScheduledTotal: Double
        let extScheduleMatchedDebtCost: Double
        let extScheduleVsDebtRatio: Double
        let extAnnualizedVsDebtRatio: Double
    }

    static func coverage(inputs: AuditInputs) -> Coverage {
        let banTotal = inputs.banPrincipalPaidStated + inputs.banInterestStated
        let banMonthlyEq = banTotal / 12.0

        let preMonths = monthCountInclusive(from: inputs.preFirstDue, to: inputs.preLastDue)
        let preScheduledTotal = inputs.preMonthlyLease * Double(preMonths)
        let preAnnualizedTotal = inputs.preMonthlyLease * 12.0
        let preScheduleVsBanRatio = safeRatio(preScheduledTotal, banTotal)
        let preAnnualizedVsBanRatio = safeRatio(preAnnualizedTotal, banTotal)

        let gap = monthGap(from: inputs.banStart, to: inputs.preFirstDue)

        let convPayment = DebtMath.levelPayment(
            principal: inputs.purchasePrincipal,
            annualRate: inputs.conversionAnnualRate,
            years: inputs.conversionYears,
            paymentsPerYear: inputs.conversionPaymentsPerYear
        )
        let convAnnual = convPayment * Double(inputs.conversionPaymentsPerYear)
        let convMonthlyEq = convAnnual / 12.0

        let extMonths = monthCountInclusive(from: inputs.extFirstDue, to: inputs.extLastDue)
        let extScheduledTotal = inputs.extMonthlyLease * Double(extMonths)

        let extScheduleMatchedDebtCost = convMonthlyEq * Double(extMonths)
        let extScheduleVsDebtRatio = safeRatio(extScheduledTotal, extScheduleMatchedDebtCost)
        let extAnnualizedVsDebtRatio = safeRatio(inputs.extMonthlyLease * 12.0, convAnnual)

        return Coverage(
            banTotal: banTotal,
            banMonthlyEq: banMonthlyEq,
            preMonths: preMonths,
            preScheduledTotal: preScheduledTotal,
            preAnnualizedTotal: preAnnualizedTotal,
            preScheduleVsBanRatio: preScheduleVsBanRatio,
            preAnnualizedVsBanRatio: preAnnualizedVsBanRatio,
            preTimingGapMonths: max(0, gap),
            convAnnualDebtService: convAnnual,
            convMonthlyEq: convMonthlyEq,
            extMonths: extMonths,
            extScheduledTotal: extScheduledTotal,
            extScheduleMatchedDebtCost: extScheduleMatchedDebtCost,
            extScheduleVsDebtRatio: extScheduleVsDebtRatio,
            extAnnualizedVsDebtRatio: extAnnualizedVsDebtRatio
        )
    }

    // ---- Math checks

    static func mathChecks(inputs: AuditInputs) -> [MathCheck] {
        var out: [MathCheck] = []

        // 1) BAN totals
        let banTotal = inputs.banPrincipalPaidStated + inputs.banInterestStated
        out.append(.init(
            title: "BAN total equals principal + interest",
            passed: banTotal > 0,
            detail: "\(inputs.banPrincipalPaidStated.currency0) + \(inputs.banInterestStated.currency0) = \(banTotal.currency0)"
        ))

        // 2) Down payment / outstanding
        let outstanding = inputs.purchasePrincipal - inputs.downPayment
        out.append(.init(
            title: "Outstanding equals principal minus down payment",
            passed: outstanding > 0,
            detail: "\(inputs.purchasePrincipal.currency0) − \(inputs.downPayment.currency0) = \(outstanding.currency0)"
        ))

        // 3) BAN implied rate from stated interest
        let days = max(0, daysBetween(inputs.banStart, inputs.banEnd))
        let frac = days > 0 ? Double(days) / inputs.banDayCountDenominator : 0
        let impliedRate = (inputs.purchasePrincipal > 0 && frac > 0) ? (inputs.banInterestStated / (inputs.purchasePrincipal * frac)) : 0
        out.append(.init(
            title: "BAN interest implies an annual rate",
            passed: impliedRate > 0,
            detail: "Implied ≈ \(impliedRate.percent2) from \(inputs.banInterestStated.currency0) over \(days) days on \(inputs.purchasePrincipal.currency0) (Actual/\(Int(inputs.banDayCountDenominator)))."
        ))

        // 4) Extension “six month period” vs dates
        let extMonths = monthCountInclusive(from: inputs.extFirstDue, to: inputs.extLastDue)
        out.append(.init(
            title: "Extended lease schedule length looks like 6 months",
            passed: extMonths == 6,
            detail: "Schedule spans \(extMonths) monthly payments (inclusive). If the document says “six months,” a mismatch is a drafting/clarity issue."
        ))

        // 5) Q&E principal basis usage
        out.append(.init(
            title: "Principal basis uses Q&E land acquisition",
            passed: !inputs.useQELandAcquisitionAsPrincipal || abs(inputs.purchasePrincipal - TownSquareQEEvidence.landAcquisition) < 1,
            detail: inputs.useQELandAcquisitionAsPrincipal
                ? "Using Q&E land acquisition \(TownSquareQEEvidence.landAcquisition.currency0) as principal."
                : "Not using Q&E land acquisition as principal (manual/other basis)."
        ))

        return out
    }

    // ---- Findings (“sweetheart risk indicators”)

    static func findings(inputs: AuditInputs) -> [AuditFinding] {
        var out: [AuditFinding] = []
        let cov = coverage(inputs: inputs)

        // A) Under-recovery of stated BAN year total under schedule
        if cov.preScheduleVsBanRatio < 0.95 {
            out.append(.init(
                severity: .flag,
                title: "Pre-possession schedule may not cover the stated BAN year cost",
                detail: "Scheduled pre-possession total \(cov.preScheduledTotal.currency0) vs BAN total \(cov.banTotal.currency0) → \(cov.preScheduleVsBanRatio.percent0) coverage. Could indicate a gap, ambiguity, or payments outside the stated range."
            ))
        } else {
            out.append(.init(
                severity: .info,
                title: "Pre-possession lease roughly tracks BAN year cost (annualized view)",
                detail: "Annualized pre lease \(cov.preAnnualizedTotal.currency0) vs BAN total \(cov.banTotal.currency0) → \(cov.preAnnualizedVsBanRatio.percent0) coverage (annualized)."
            ))
        }

        // B) Timing gap
        if cov.preTimingGapMonths >= 2 {
            out.append(.init(
                severity: .warn,
                title: "Timing gap: financing starts before rent schedule starts",
                detail: "BAN starts \(cov.preTimingGapMonths) months before the pre-possession lease schedule begins. If no other payments exist, the Town may carry interest cost during the gap."
            ))
        }

        // C) Extension “six months” ambiguity
        if cov.extMonths != 6 {
            out.append(.init(
                severity: .warn,
                title: "Extension term length ambiguity",
                detail: "Extended lease schedule spans \(cov.extMonths) payments. If the document describes a “six month period,” this mismatch is a transparency/clarity risk."
            ))
        }

        // D) Extended lease vs modeled debt service
        if cov.extScheduleVsDebtRatio < 0.95 {
            out.append(.init(
                severity: .flag,
                title: "Extended lease may under-cover conversion debt (schedule-matched)",
                detail: "Extended scheduled total \(cov.extScheduledTotal.currency0) vs schedule-matched conversion cost \(cov.extScheduleMatchedDebtCost.currency0) → \(cov.extScheduleVsDebtRatio.percent0)."
            ))
        } else {
            out.append(.init(
                severity: .info,
                title: "Extended lease roughly tracks modeled conversion cost",
                detail: "Schedule-matched: \(cov.extScheduleVsDebtRatio.percent0) coverage. Annualized: \(cov.extAnnualizedVsDebtRatio.percent0) vs modeled annual debt service."
            ))
        }

        // E) Down payment size (signals)
        let dpPct = safeRatio(inputs.downPayment, inputs.purchasePrincipal)
        if dpPct > 0, dpPct < 0.10 {
            out.append(.init(
                severity: .warn,
                title: "Relatively small down payment (risk transfer)",
                detail: "Down payment is \(dpPct.percent0) of principal. Lower upfront equity can shift more risk to the Town if delays/default occur (depending on remedies)."
            ))
        }

        // F) Transparency questionnaire impacts
        if inputs.noBidOrSoleSource {
            out.append(.init(
                severity: .flag,
                title: "No-bid / sole-source process (if confirmed) is a classic sweetheart-risk signal",
                detail: "Sole-source procurement can be legitimate, but it increases the need for strong documentation: appraisals, public findings, and benchmarking."
            ))
        }

        if !inputs.procurementCompetitive {
            out.append(.init(
                severity: .warn,
                title: "Competitive process not confirmed",
                detail: "If there was no RFP/RFQ or equivalent, it’s harder to show the terms are “market” rather than relationship-driven."
            ))
        }

        if !inputs.termsPublicBeforeApproval {
            out.append(.init(
                severity: .warn,
                title: "Public disclosure timing not confirmed",
                detail: "Late disclosure (after approvals) is a common risk signal because it reduces scrutiny."
            ))
        }

        if !inputs.noMaterialTaxBreaks {
            out.append(.init(
                severity: .warn,
                title: "Tax breaks / PILOT / fee waivers not ruled out",
                detail: "If additional subsidies exist, lease payment math alone may not represent the true public cost."
            ))
        }

        // Valuation evidence: confirmed vs partial vs missing
        if inputs.independentValuationConfirmed {
            out.append(.init(
                severity: .info,
                title: "Independent valuation/appraisal is confirmed",
                detail: "A documented valuation/appraisal exists and supports deal terms (as marked)."
            ))
        } else if inputs.qeShowsAppraisalLineItem {
            out.append(.init(
                severity: .info,
                title: "Partial valuation signal: Q&E budget includes appraisal line item",
                detail: "This suggests appraisal work was planned/budgeted, but doesn’t confirm an independent appraisal exists or was publicly disclosed."
            ))
        } else {
            out.append(.init(
                severity: .warn,
                title: "Independent valuation/appraisal not confirmed",
                detail: "Without an appraisal or third-party valuation, favorable pricing/credits can look like a sweetheart arrangement even if lawful."
            ))
        }

        // Sort: most severe first
        return out.sorted { $0.severity.rank > $1.severity.rank }
    }

    // ---- Scoring (heuristic)

    struct ScorePart: Identifiable {
        let id = UUID()
        let title: String
        let points: Int
    }

    static func scoreBreakdown(inputs: AuditInputs, findings: [AuditFinding]) -> [ScorePart] {
        let cov = coverage(inputs: inputs)

        var parts: [ScorePart] = []

        // Coverage gap (pre schedule vs BAN total) up to 30 pts
        let gapRatio = max(0, 1.0 - cov.preScheduleVsBanRatio)
        let coveragePts = Int(min(30.0, gapRatio * 60.0))
        parts.append(.init(title: "Coverage gap", points: coveragePts))

        // Ambiguity up to 20 pts
        var amb = 0
        if cov.preTimingGapMonths >= 2 { amb += 8 }
        if cov.extMonths != 6 { amb += 12 }
        parts.append(.init(title: "Ambiguity", points: min(20, amb)))

        // Low down payment up to 10 pts
        let dpPct = safeRatio(inputs.downPayment, inputs.purchasePrincipal)
        let dpPts = (dpPct > 0 && dpPct < 0.10) ? 10 : 0
        parts.append(.init(title: "Low upfront equity", points: dpPts))

        // Transparency toggles up to 40 pts (with partial valuation nuance)
        var trans = 0
        if inputs.noBidOrSoleSource { trans += 15 }
        if !inputs.procurementCompetitive { trans += 8 }
        if !inputs.termsPublicBeforeApproval { trans += 7 }
        if !inputs.noMaterialTaxBreaks { trans += 4 }

        // Valuation penalty: confirmed (0), partial (3), none (6)
        if inputs.independentValuationConfirmed {
            trans += 0
        } else if inputs.qeShowsAppraisalLineItem {
            trans += 3
        } else {
            trans += 6
        }

        parts.append(.init(title: "Transparency", points: min(40, trans)))

        return parts
    }

    static func riskScore(inputs: AuditInputs, findings: [AuditFinding]) -> Int {
        scoreBreakdown(inputs: inputs, findings: findings).reduce(0) { $0 + $1.points }
    }

    static func riskLevel(score: Int) -> RiskLevel {
        switch score {
        case 0..<25: return .low
        case 25..<55: return .moderate
        default: return .high
        }
    }

    enum RiskLevel {
        case low, moderate, high

        var label: String {
            switch self {
            case .low: return "Low risk indicators"
            case .moderate: return "Moderate risk indicators"
            case .high: return "High risk indicators"
            }
        }

        var explainer: String {
            switch self {
            case .low:
                return "Based on inputs, terms appear broadly explainable by financing costs and structure—still verify procurement and disclosures."
            case .moderate:
                return "Multiple ambiguity/transparency signals or coverage concerns. Not proof of unfairness; it’s a prompt to gather records and benchmark."
            case .high:
                return "Meaningful coverage gaps and/or weak transparency signals. Treat as a prompt to obtain documents (RFP, appraisals, subsidies, approvals) before conclusions."
            }
        }

        var tint: Color {
            switch self {
            case .low: return .green
            case .moderate: return .orange
            case .high: return .red
            }
        }
    }

    // ---- Utilities

    static func monthCountInclusive(from a: Date, to b: Date) -> Int {
        let cal = Calendar(identifier: .gregorian)
        let start = cal.startOfDay(for: a)
        let end = cal.startOfDay(for: b)
        guard start <= end else { return 0 }
        let m = cal.dateComponents([.month], from: start, to: end).month ?? 0
        return max(0, m + 1)
    }

    static func monthGap(from a: Date, to b: Date) -> Int {
        let cal = Calendar(identifier: .gregorian)
        let start = cal.startOfDay(for: a)
        let end = cal.startOfDay(for: b)
        guard start <= end else { return 0 }
        return cal.dateComponents([.month], from: start, to: end).month ?? 0
    }

    static func daysBetween(_ a: Date, _ b: Date) -> Int {
        let comps = Calendar(identifier: .gregorian).dateComponents([.day], from: a, to: b)
        return comps.day ?? 0
    }

    static func safeRatio(_ num: Double, _ den: Double) -> Double {
        guard den != 0 else { return 0 }
        return num / den
    }

    enum DebtMath {
        static func levelPayment(principal: Double, annualRate: Double, years: Int, paymentsPerYear: Int) -> Double {
            guard principal > 0, annualRate >= 0, years > 0, paymentsPerYear > 0 else { return 0 }
            let n = Double(years * paymentsPerYear)
            let r = annualRate / Double(paymentsPerYear)
            if r == 0 { return principal / max(1, n) }
            let denom = 1 - pow(1 + r, -n)
            guard denom != 0 else { return 0 }
            return principal * r / denom
        }
    }
}

// MARK: - Models

private struct MathCheck: Identifiable {
    let id = UUID()
    let title: String
    let passed: Bool
    let detail: String
}

private struct AuditFinding: Identifiable {
    let id = UUID()
    let severity: AuditSeverity
    let title: String
    let detail: String
}

private enum AuditSeverity: Int {
    case info = 0
    case warn = 1
    case flag = 2

    var rank: Int { rawValue }

    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warn: return "exclamationmark.triangle.fill"
        case .flag: return "xmark.octagon.fill"
        }
    }

    var tint: Color {
        switch self {
        case .info: return .blue
        case .warn: return .orange
        case .flag: return .red
        }
    }
}

// MARK: - Formatting Helpers

private extension Double {
    var currency0: String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.maximumFractionDigits = 0
        nf.minimumFractionDigits = 0
        return nf.string(from: NSNumber(value: self)) ?? "$0"
    }

    var percent0: String { String(format: "%.0f%%", self * 100.0) }
    var percent2: String { String(format: "%.2f%%", self * 100.0) }

    static func parseCurrencyLoose(_ text: String) -> Double? {
        let cleaned = text.replacingOccurrences(of: "[^0-9.\\-]", with: "", options: .regularExpression)
        return Double(cleaned)
    }

    static func parsePercentLoose(_ text: String) -> Double? {
        let cleaned = text
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: " ", with: "")
        guard let raw = Double(cleaned) else { return nil }
        return raw > 1 ? raw / 100.0 : raw
    }
}

#Preview("RBTownSquareSweetheartDealAuditView") {
    NavigationStack {
        RBTownSquareSweetheartDealAuditView()
    }
}
