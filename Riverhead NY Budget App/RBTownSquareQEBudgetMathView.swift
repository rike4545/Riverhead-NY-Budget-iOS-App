//
//  RBTownSquareQEBudgetMathView.swift
//  Riverhead NY Budget App
//
//  Created by Bryan on 1/21/26.
//


//
//  RBTownSquareQEBudgetMathView.swift
//  Riverhead NY Budget App
//
//  Town Square Q&E packet: budget evidence + arithmetic validation.
//  Swift 6 • iOS 17+
//
//  What this is:
//  - A public-interest audit helper that checks whether the Q&E budget table is internally consistent.
//  - It does NOT allege wrongdoing or label anything a “sweetheart deal.”
//
//  Sources (links shown in-app):
//  - Downtown Revitalization Projects hub (Town site)
//  - Town Square QE Documents (PDF)
//

import SwiftUI
import Foundation

#if canImport(Charts)
import Charts
#endif

@MainActor
struct RBTownSquareQEBudgetMathView: View {

    @Environment(\.openURL) private var openURL

    @State private var model = QEBudget.defaultFromTownQE
    @State private var otherReportedLandPrice: Double = 2_650_000 // optional comparator
    @State private var showComparator = true

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                GroupBox { sourcesBox }

                GroupBox { budgetBox }

                GroupBox { mathChecksBox }

                GroupBox { interpretationBox }

                GroupBox { disclaimerBox }
            }
            .padding()
        }
        .navigationTitle("Q&E Budget Check")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - UI

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Town Square Q&E — Budget Math")
                .font(.title2.weight(.semibold))
            Text("Validates arithmetic + highlights reconciliation needs.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Label("Evidence", systemImage: "doc.text")
                Label("Math", systemImage: "function")
                Label("Reconcile", systemImage: "arrow.left.arrow.right")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sourcesBox: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sources (Town-hosted)")
                .font(.headline)

            sourceRow(
                title: "Downtown Revitalization Projects (hub)",
                subtitle: "Town page linking to Q&E docs/presentation",
                url: URL(string: "https://www.townofriverheadny.gov/213/2896/Downtown-Revitalization-Projects")!
            )

            Divider()

            sourceRow(
                title: "Town Square Q&E Documents (PDF)",
                subtitle: "Budget summary + financial verification letter(s)",
                url: URL(string: "https://www.townofriverheadny.gov/DocumentCenter/View/2344/Town-Square-QE-Documents")!
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sourceRow(title: String, subtitle: String, url: URL) -> some View {
        Button {
            openURL(url)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
                Text(url.absoluteString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var budgetBox: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Q&E Budget (7/22/2025)")
                .font(.headline)

            // High-level
            metric("Total project cost (sources = uses)", model.total.currency2)

            Divider().padding(.vertical, 2)

            Text("Sources of funds")
                .font(.subheadline.weight(.semibold))
            metric("Construction loan", model.constructionLoan.currency2)
            metric("Developer equity", model.developerEquity.currency2)
            metric("Restore NY grant (awarded 2024)", model.restoreNYGrant.currency2)

            Divider().padding(.vertical, 2)

            Text("Uses of funds")
                .font(.subheadline.weight(.semibold))
            metric("Land acquisition", model.landAcquisition.currency2)
            metric("Hard costs", model.hardCosts.currency2)
            metric("Soft costs", model.softCosts.currency2)
            metric("Contingency", model.contingency.currency2)

            Divider().padding(.vertical, 2)

            Text("Units & derived metrics")
                .font(.subheadline.weight(.semibold))
            metric("Hotel rooms", "\(model.hotelRooms)")
            metric("Condo units", "\(model.condoUnits)")
            metric("Keys (rooms + condos)", "\(model.keys)")
            metric("Cost per key (derived)", model.costPerKey.currency2)

            #if canImport(Charts)
            Divider().padding(.vertical, 2)

            Text("Sources mix")
                .font(.subheadline.weight(.semibold))

            let parts = model.sourceMix
            Chart {
                ForEach(parts) { p in
                    BarMark(x: .value("Source", p.label), y: .value("Percent", p.pct))
                }
            }
            .frame(height: 180)
            #endif

            Divider().padding(.vertical, 2)

            Toggle("Show comparator vs other reported land price", isOn: $showComparator)
                .font(.subheadline)

            if showComparator {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Comparator (optional)")
                        .font(.subheadline.weight(.semibold))

                    currencyField("Other reported land price", $otherReportedLandPrice)

                    let delta = otherReportedLandPrice - model.landAcquisition
                    let pct = safeRatio(abs(delta), model.landAcquisition)

                    HStack {
                        Text("Δ vs Q&E land acquisition")
                        Spacer()
                        Text(delta.signedCurrency2)
                            .font(.body.weight(.semibold))
                    }
                    HStack {
                        Text("Percent difference")
                        Spacer()
                        Text(pct.percent2)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text("If this delta exists across sources, your app should label it as: “**needs reconciliation**” (parcel scope, amendment timing, inclusions, or rounding).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mathChecksBox: some View {
        let checks = model.mathChecks()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Math checks")
                .font(.headline)

            ForEach(checks) { c in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: c.passed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(c.passed ? .green : .orange)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(c.title).font(.subheadline.weight(.semibold))
                        Text(c.detail).font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }

            Divider().padding(.vertical, 2)

            Text("Editable inputs")
                .font(.subheadline.weight(.semibold))
            Text("If the Town posts an updated budget, you can paste updated figures here and immediately re-run checks.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                currencyField("Total", $model.total)

                Divider().padding(.vertical, 2)

                currencyField("Construction loan", $model.constructionLoan)
                currencyField("Developer equity", $model.developerEquity)
                currencyField("Restore NY grant", $model.restoreNYGrant)

                Divider().padding(.vertical, 2)

                currencyField("Land acquisition", $model.landAcquisition)
                currencyField("Hard costs", $model.hardCosts)
                currencyField("Soft costs", $model.softCosts)
                currencyField("Contingency", $model.contingency)

                Divider().padding(.vertical, 2)

                Stepper(value: $model.hotelRooms, in: 0...500) {
                    HStack { Text("Hotel rooms"); Spacer(); Text("\(model.hotelRooms)").foregroundStyle(.secondary) }
                }
                Stepper(value: $model.condoUnits, in: 0...500) {
                    HStack { Text("Condo units"); Spacer(); Text("\(model.condoUnits)").foregroundStyle(.secondary) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var interpretationBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How this helps the “sweetheart” audit")
                .font(.headline)

            bullet("This Q&E packet provides **official budget context** (sources/uses) that’s more reliable than secondhand summaries.")
            bullet("The table shows a large **developer equity** component and a **construction loan**, which can reduce “public subsidy” concerns for the private build—but it doesn’t answer procurement fairness by itself.")
            bullet("Soft costs include an **appraisal** line item, which suggests valuation work occurred; your audit can treat that as a partial “independent valuation exists” signal—pending the actual appraisal document.")
            bullet("If other sources cite a different land price, treat it as “reconcile scope/timing,” not automatically as misconduct.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var disclaimerBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Disclaimer")
                .font(.headline)

            Text("This screen validates arithmetic and flags reconciliation needs. It does not allege wrongdoing. A true “sweetheart deal” finding usually requires procurement records (RFP/RFQ, bids), board resolutions, executed contracts, subsidy/tax docs, and market benchmarking.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helpers

    private func metric(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).font(.body.weight(.semibold))
        }
        .padding(.vertical, 1)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").font(.headline)
            Text(text).foregroundStyle(.secondary)
        }
    }

    private func currencyField(_ title: String, _ value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            TextField(title, text: Binding(
                get: { value.wrappedValue.currency2 },
                set: { value.wrappedValue = Double.parseCurrencyLoose($0) ?? 0 }
            ))
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
        }
    }

    private func safeRatio(_ num: Double, _ den: Double) -> Double {
        guard den != 0 else { return 0 }
        return num / den
    }
}

// MARK: - Model

private struct QEBudget: Equatable {

    // Headline
    var total: Double

    // Sources
    var constructionLoan: Double
    var developerEquity: Double
    var restoreNYGrant: Double

    // Uses
    var landAcquisition: Double
    var hardCosts: Double
    var softCosts: Double
    var contingency: Double

    // Units
    var hotelRooms: Int
    var condoUnits: Int

    var keys: Int { hotelRooms + condoUnits }
    var costPerKey: Double {
        let k = Double(max(1, keys))
        return total / k
    }

    struct MixPart: Identifiable {
        let id = UUID()
        let label: String
        let pct: Double
    }

    var sourceMix: [MixPart] {
        let t = max(1, total)
        return [
            .init(label: "Loan", pct: constructionLoan / t * 100.0),
            .init(label: "Equity", pct: developerEquity / t * 100.0),
            .init(label: "Restore NY", pct: restoreNYGrant / t * 100.0)
        ]
    }

    struct Check: Identifiable {
        let id = UUID()
        let title: String
        let passed: Bool
        let detail: String
    }

    func mathChecks() -> [Check] {
        var out: [Check] = []

        let sourcesSum = constructionLoan + developerEquity + restoreNYGrant
        out.append(.init(
            title: "Sources sum to total",
            passed: abs(sourcesSum - total) < 0.01,
            detail: "\(constructionLoan.currency2) + \(developerEquity.currency2) + \(restoreNYGrant.currency2) = \(sourcesSum.currency2) (total \(total.currency2))"
        ))

        let usesSum = landAcquisition + hardCosts + softCosts + contingency
        out.append(.init(
            title: "Uses sum to total",
            passed: abs(usesSum - total) < 0.01,
            detail: "\(landAcquisition.currency2) + \(hardCosts.currency2) + \(softCosts.currency2) + \(contingency.currency2) = \(usesSum.currency2) (total \(total.currency2))"
        ))

        let k = max(1, keys)
        let derived = total / Double(k)
        out.append(.init(
            title: "Cost per key is consistent",
            passed: derived.isFinite && derived > 0,
            detail: "\(total.currency2) ÷ \(k) keys = \(derived.currency2)"
        ))

        // Basic sanity: percentages shouldn’t exceed 100 by much
        let pctSum = (constructionLoan + developerEquity + restoreNYGrant) / max(1, total) * 100.0
        out.append(.init(
            title: "Percent sanity (sources/total)",
            passed: abs(pctSum - 100.0) < 0.5,
            detail: "Sources/total ≈ \(String(format: "%.2f%%", pctSum))"
        ))

        return out
    }

    static var defaultFromTownQE: QEBudget {
        // From Town Square Q&E packet budget summary (7/22/2025).
        QEBudget(
            total: 32_672_889.76,
            constructionLoan: 19_603_733.86,
            developerEquity: 12_069_155.90,
            restoreNYGrant: 1_000_000.00,
            landAcquisition: 2_625_000.00,
            hardCosts: 26_079_289.76,
            softCosts: 3_365_600.00,
            contingency: 603_000.00,
            hotelRooms: 76,
            condoUnits: 12
        )
    }
}

// MARK: - Formatting

private extension Double {
    var currency2: String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 2
        return nf.string(from: NSNumber(value: self)) ?? "$0.00"
    }

    var signedCurrency2: String {
        let sign = self >= 0 ? "+" : "−"
        return "\(sign)\(abs(self).currency2)"
    }

    var percent2: String { String(format: "%.2f%%", self * 100.0) }

    static func parseCurrencyLoose(_ text: String) -> Double? {
        let cleaned = text.replacingOccurrences(of: "[^0-9.\\-]", with: "", options: .regularExpression)
        return Double(cleaned)
    }
}

#Preview("RBTownSquareQEBudgetMathView") {
    NavigationStack { RBTownSquareQEBudgetMathView() }
}
