//
//  ModelVsAdopted2027.swift
//  Riverhead NY Budget App
//
//  The app's 2027 model tools (Lab, Simulator, Whiteboard, the App's 2027 Plan,
//  Spending Reduction) were built in September 2026 from the 2026 Adopted Budget.
//  They stay as they were made. This card sets each modeled figure beside what the
//  Town Board adopted on November 17, 2026 (Resolution 2026-995, 5–0), read from
//  budget-stages.json and the 2027 line file (BudgetLines). It projects nothing.
//

import SwiftUI

enum ModelVsAdopted2027 {
    struct Row: Identifiable {
        let label: String
        let modeled: String
        let adopted: String
        let note: String

        var id: String { label }
    }

    /// The App's 2027 Plan's General Fund levy (Proposed2027BudgetData.generalFundLevy2027): 3% below 2026.
    static let planGeneralFundLevy: Double = 51_278_671

    private static func usd(_ v: Double) -> String {
        v.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private static func signed(_ v: Double) -> String {
        (v >= 0 ? "+" : "−") + usd(abs(v))
    }

    /// The change from 2026 to 2027 adopted in spending lines matching `match`, all funds.
    private static func adoptedChange(_ match: (BudgetLineRecord) -> Bool) -> Double? {
        guard let file = BudgetLines.file, BudgetLines.isAdopted else { return nil }
        let lines = file.lines.filter { $0.isExpenditure && match($0) }
        guard !lines.isEmpty else { return nil }
        return lines.reduce(0) { $0 + (BudgetLines.value($1) ?? 0) - ($1.adopted ?? 0) }
    }

    /// Nil until the 2027 adopted figures are in the bundle.
    static var rows: [Row]? {
        guard let doc = BudgetStages.doc(2027, .adopted), let prior = BudgetStages.doc(2026, .adopted) else { return nil }
        var out: [Row] = []

        let levyPct = BudgetStages.pct(doc.totals.levy, prior.totals.levy)
        out.append(Row(
            label: "Levy, all funds",
            modeled: "\(usd(CloseTheGap2027.predictedLevy)) (+\(String(format: "%.1f", CloseTheGap2027.predictedLevyPct))%)",
            adopted: "\(usd(doc.totals.levy)) (\(levyPct >= 0 ? "+" : "")\(String(format: "%.2f", levyPct))%)",
            note: "The September model's levy against the Summary page's."))

        if let gf = doc.generalFund?.levy {
            out.append(Row(
                label: "General Fund levy",
                modeled: "\(usd(planGeneralFundLevy)) (the App's 2027 Plan, 3% cut)",
                adopted: usd(gf),
                note: "The Plan aimed to cut the General Fund levy 3%; the adopted levy rose."))
        }

        if let pension = adoptedChange({ ["9010", "9015"].contains($0.functionCode) }) {
            out.append(Row(
                label: "NYS retirement (pension), all funds",
                modeled: "\(usd(Budget2027PensionPressureModel.lowIncrease)) to \(usd(Budget2027PensionPressureModel.highIncrease)) more",
                adopted: "\(signed(pension)) from 2026",
                note: "Retirement lines 9010 (non-uniform) and 9015 (police), every fund."))
        }

        if let pay = adoptedChange({ !$0.functionCode.hasPrefix("9") && $0.objectCode.hasPrefix("1") }) {
            out.append(Row(
                label: "Pay (personal services), all funds",
                modeled: "\(usd(Budget2027ScenarioModel.modeledAutomaticPayrollPressure)) of automatic raises",
                adopted: "\(signed(pay)) from 2026",
                note: "The adopted change also carries staffing changes and every unit's raises, so it is not the model's automatic raises alone."))
        }

        if let health = adoptedChange({ ["9060", "9065"].contains($0.functionCode) }) {
            out.append(Row(
                label: "Health insurance, all funds",
                modeled: "Not modeled separately",
                adopted: "\(signed(health)) from 2026",
                note: "Hospital, dental and optical lines 9060 and 9065."))
        }

        if let ot = BudgetLines.byAccount["A01-3-3120-111-UNI-00000"].flatMap(BudgetLines.value) {
            out.append(Row(
                label: "Police uniform overtime",
                modeled: "\(usd(Budget2027TaxCapOffsetModel.peerBenchmarkNormalizedBudget)) at the peer rate",
                adopted: usd(ot),
                note: "The model's Southampton-rate benchmark for about 100 officers, against the adopted line; 2025 actual spending was $1,113,609."))
        }
        return out
    }
}

/// The card each model screen shows near its top.
struct ModelVsAdoptedCard: View {
    var body: some View {
        if let rows = ModelVsAdopted2027.rows {
            VStack(alignment: .leading, spacing: 10) {
                Label("What the model said, and what the Board adopted", systemImage: "arrow.left.arrow.right")
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.textPrimary)
                Text("This screen is the app's model, made in September 2026 from the 2026 Adopted Budget. The Town Board adopted the 2027 budget on November 17, 2026 (Resolution 2026-995, 5–0). The adopted figures come from its Summary page and its account lines.")
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(rows) { row in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.textPrimary)
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Model").font(.caption2).foregroundStyle(.secondary)
                                Text(row.modeled).font(.caption.weight(.semibold)).monospacedDigit()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Adopted").font(.caption2).foregroundStyle(.secondary)
                                Text(row.adopted).font(.caption.weight(.semibold)).monospacedDigit()
                                    .foregroundStyle(RiverheadTheme.accent)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Text(row.note)
                            .font(.caption2)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                    .padding(.vertical, 4)
                    if row.id != rows.last?.id {
                        Divider().opacity(0.3)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RiverheadTheme.Surface.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(RiverheadTheme.softBorder, lineWidth: 1)
            )
        }
    }
}
