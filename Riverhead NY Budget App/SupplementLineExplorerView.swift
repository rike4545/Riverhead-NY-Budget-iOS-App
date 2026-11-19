//
//  SupplementLineExplorerView.swift
//  Riverhead NY Budget App
//
//  Browsable line-item ledger from the newest Budget Supplement (2027): every
//  expenditure account with two years of actuals, the current year's budget, the
//  new year's figure, and how far that figure sits above or below its trailing
//  run-rate. The 2027 Preliminary's figures are the adopted budget's: the Town
//  Board adopted it unchanged on November 17, 2026 (Resolution 2026-995).
//  Falls back to the 2026 Supplement's lines when the newest file is missing.
//
//  Swift 6 · iOS 17+
//

import SwiftUI

/// One ledger row, from either Supplement, with its columns already labelled by year.
private struct LedgerRow: Identifiable {
    let account: String
    let fund: String
    let name: String
    let control: String
    let columns: [(label: String, value: Double?, highlight: Bool)]
    let overRunRate: Double?

    var id: String { account }
}

@MainActor
struct SupplementLineExplorerView: View {
    @State private var query = ""
    @State private var fundFilter = "All"
    @State private var controlFilter = "All"
    @State private var overBudgetOnly = false

    /// The newest Supplement's year (2027), or 2026 when only the older file is bundled.
    private let year: Int = SupplementData.currentLines?.supplementYear ?? 2026

    /// "adopted" when the newest year's lines are the adopted budget (BudgetLines checks
    /// them against the adopted Summary page), else the stage printed.
    private var newestStageWord: String {
        guard let current = SupplementData.currentLines else { return "tent" }
        if BudgetLines.adoptedYear == current.supplementYear { return "adopted" }
        return current.lines.contains { $0.preliminary != nil } ? "prelim" : "tent"
    }

    private var rows: [LedgerRow] {
        if let current = SupplementData.currentLines {
            let c = current.columns
            func y(_ role: String, _ fallback: Int) -> String { String(c[role] ?? fallback) }
            let stage = newestStageWord
            return current.lines.filter { $0.kind == "expenditure" }.map { line in
                LedgerRow(
                    account: line.account, fund: line.fund, name: line.name, control: line.control,
                    columns: [
                        ("\(y("priorActual", year - 3)) act", line.priorActual, false),
                        ("\(y("actual", year - 2)) act", line.actual, false),
                        ("\(y("adopted", year - 1)) bud", line.adopted, false),
                        ("\(year) \(stage)", line.proposal, true),
                    ],
                    overRunRate: line.overRunRate
                )
            }
        }
        return SupplementData.lines.filter { $0.kind == "expenditure" }.map { line in
            LedgerRow(
                account: line.account, fund: line.fund, name: line.name, control: line.control,
                columns: [
                    ("2023 act", line.actual2023, false),
                    ("2024 act", line.actual2024, false),
                    ("2025 bud", line.budget2025, false),
                    ("2026 tent", line.tentative2026, true),
                ],
                overRunRate: line.overBudget2026
            )
        }
    }

    private var funds: [String] {
        ["All"] + Set(rows.map(\.fund)).sorted()
    }

    private var filtered: [LedgerRow] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return rows.filter { line in
            (fundFilter == "All" || line.fund == fundFilter)
            && (controlFilter == "All" || line.control == controlFilter)
            && (!overBudgetOnly || (line.overRunRate ?? 0) > 0)
            && (q.isEmpty || line.name.lowercased().contains(q) || line.account.lowercased().contains(q))
        }
        .sorted { ($0.overRunRate ?? -.greatestFiniteMagnitude) > ($1.overRunRate ?? -.greatestFiniteMagnitude) }
    }

    private var footnote: String {
        guard SupplementData.currentLines != nil else {
            return "\"Over run-rate\" is the 2026 Tentative minus the trailing full-year run-rate (the larger of 2024 Actual and annualized 2025 YTD). Positive means the line is budgeted above what it has recently spent."
        }
        let stage = newestStageWord == "adopted"
            ? "\(year) Adopted Budget figure (the Preliminary, which the Board adopted unchanged)"
            : "\(year) \(newestStageWord == "prelim" ? "Preliminary" : "Tentative") figure"
        return "From the \(year) Budget Supplement. \"Over run-rate\" is the \(stage) minus the trailing full-year run-rate (the larger of \(year - 2) actual and annualized \(year - 1) year-to-date). Positive means the line is budgeted above what it has recently spent."
    }

    var body: some View {
        List {
            Section {
                Picker("Fund", selection: $fundFilter) {
                    ForEach(funds, id: \.self) { Text($0).tag($0) }
                }
                Picker("Category", selection: $controlFilter) {
                    Text("All").tag("All")
                    Text("Controllable").tag("controllable")
                    Text("Personnel").tag("personnel")
                    Text("Mandated").tag("mandated")
                }
                Toggle("Over-budget only", isOn: $overBudgetOnly)
            } header: {
                Text("\(filtered.count) of \(rows.count) expenditure lines")
            } footer: {
                Text(footnote)
            }

            Section {
                ForEach(filtered.prefix(300)) { line in
                    lineRow(line)
                }
                if filtered.count > 300 {
                    Text("Showing the first 300. Narrow with search or filters.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .searchable(text: $query, prompt: "Search account name or code")
        .navigationTitle("Line-Item Ledger")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func lineRow(_ line: LedgerRow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(line.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                controlBadge(line.control)
            }
            Text("\(line.fund) · \(line.account)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                ForEach(line.columns.indices, id: \.self) { i in
                    col(line.columns[i].label, line.columns[i].value,
                        tint: line.columns[i].highlight ? RiverheadTheme.brandBlue : .primary)
                }
            }

            if let ob = line.overRunRate, abs(ob) >= 1 {
                let over = ob > 0
                Label(
                    "\(over ? "+" : "")\(ob.formatted(.currency(code: "USD").precision(.fractionLength(0)))) vs run-rate",
                    systemImage: over ? "arrow.up.right" : "arrow.down.right"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(over ? RiverheadTheme.brandCoral : RiverheadTheme.brandMint)
            }
        }
        .padding(.vertical, 3)
    }

    private func col(_ label: String, _ value: Double?, tint: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value.map { $0.formatted(.currency(code: "USD").notation(.compactName).precision(.fractionLength(0...1))) } ?? "—")
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func controlBadge(_ c: String) -> some View {
        let (label, tint): (String, Color) = {
            switch c {
            case "controllable": return ("CONTROLLABLE", RiverheadTheme.brandSky)
            case "personnel": return ("PERSONNEL", RiverheadTheme.brandNavy)
            case "mandated": return ("MANDATED", .secondary)
            default: return (c.uppercased(), .secondary)
            }
        }()
        return Text(label)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
    }
}

#Preview {
    NavigationStack { SupplementLineExplorerView() }
}
