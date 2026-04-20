//
//  RBSalaryInsightsView.swift
//  Riverhead NY Budget App
//
//  Created by Bryan on 1/1/26.
//


//
//  RBSalaryInsightsView.swift
//  Riverhead NY Budget App
//
//  CSV-driven salary insights (2021–2026 excerpt)
//  - 37.5 hrs/week => 75 hrs/biweekly => 1950 hrs/year
//  - Designed to be standalone (no coupling to RBCivicToolkitStore)
//

import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct RBSalaryInsightsView: View {

    @StateObject private var model = RBSalaryInsightsModel()

    @State private var selectedYear: Int? = nil
    @State private var searchText: String = ""
    @State private var showImporter = false

    var body: some View {
        List {
            Section {
                headerCard
                    .listRowInsets(.init(top: 12, leading: 16, bottom: 10, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section("Data Source") {
                HStack {
                    Label("Bundle CSV", systemImage: "doc")
                    Spacer()
                    Text(model.sourceLabel)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Button {
                    showImporter = true
                } label: {
                    Label("Import a CSV (dev)", systemImage: "square.and.arrow.down")
                }

                if let err = model.errorMessage, !err.isEmpty {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section("Year") {
                Picker("Year", selection: Binding(
                    get: { selectedYear ?? model.availableYears.last },
                    set: { selectedYear = $0 }
                )) {
                    ForEach(model.availableYears, id: \.self) { y in
                        Text(String(y)).tag(y as Int?)
                    }
                }
                .pickerStyle(.menu)

                if let y = (selectedYear ?? model.availableYears.last) {
                    let s = model.summary(for: y)
                    SalaryStatRow(label: "Headcount (unique roles)", value: "\(s.headcount)", systemImage: "person.3.fill")
                    SalaryStatRow(label: "Total comparable payroll", value: s.totalPayroll.currency, systemImage: "banknote.fill")
                    SalaryStatRow(label: "Avg annual (comparable)", value: s.avgAnnual.currency, systemImage: "chart.bar.fill")
                    SalaryStatRow(label: "Avg hourly equiv", value: s.avgHourly.hourly, systemImage: "clock.fill")
                    SalaryStatRow(label: "Avg biweekly gross", value: s.avgBiweekly.currency, systemImage: "calendar.badge.clock")
                }
            }

            Section("Top Increases vs Previous Year") {
                let y = (selectedYear ?? model.availableYears.last)
                if let y, let prev = model.previousYear(of: y) {
                    let top = model.topIncreases(for: y, limit: 12)
                    if top.isEmpty {
                        Text("No comparable changes available for \(prev) → \(y).")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(top) { row in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(row.displayTitle)
                                    .font(.headline)
                                    .lineLimit(2)
                                Text(row.name)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 10) {
                                    Text("\(prev): \(row.prevComparableAnnual?.currency ?? "—")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(y): \(row.comparableAnnual.currency)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                HStack(spacing: 10) {
                                    Text("Δ \(row.deltaPrevYear?.currency ?? "—")")
                                        .font(.caption.weight(.semibold))
                                    Text(row.pctPrevYear?.percent ?? "—")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } else {
                    Text("Pick a year to view changes.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Rows") {
                if model.rows.isEmpty {
                    ContentUnavailableView(
                        "No salary data",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Add Payroll_2026_app_ready.csv to your app bundle, or import a CSV.")
                    )
                } else {
                    ForEach(filteredRows) { row in
                        NavigationLink {
                            RBSalaryRowDetailView(row: row)
                        } label: {
                            SalaryRowCell(row: row)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Salary Insights")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search names, titles, steps…")
        .task {
            model.preloadFromBundleIfNeeded()
            if selectedYear == nil { selectedYear = model.availableYears.last }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    model.load(from: url)
                }
            case .failure(let err):
                model.errorMessage = err.localizedDescription
            }
        }
    }

    private var filteredRows: [RBSalaryRow] {
        let y = selectedYear ?? model.availableYears.last
        var base = model.rows
        if let y { base = base.filter { $0.year == y } }

        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return base.sorted(by: RBSalaryRow.defaultSort) }

        return base.filter { r in
            let hay = "\(r.name) \(r.title) \(r.step ?? "") \(r.employeeGroup ?? "")".lowercased()
            return hay.contains(q)
        }
        .sorted(by: RBSalaryRow.defaultSort)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                        .frame(width: 46, height: 46)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3.weight(.semibold))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Payroll clarity, fast")
                        .font(.headline.weight(.semibold))
                    Text("Uses 37.5 hrs/week • 75 hrs/biweekly • 1950 hrs/year to compare annual and hourly lines on the same basis.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                SalaryPill(label: "Rows", value: "\(model.rows.count)", systemImage: "list.bullet")
                SalaryPill(label: "Years", value: "\(model.availableYears.count)", systemImage: "calendar")
            }
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Detail

private struct RBSalaryRowDetailView: View {
    let row: RBSalaryRow

    var body: some View {
        List {
            Section("Identity") {
                LabeledContent("Name", value: row.name)
                LabeledContent("Title", value: row.title)
                if let step = row.step, !step.isEmpty {
                    LabeledContent("Step", value: step)
                }
                if let group = row.employeeGroup, !group.isEmpty {
                    LabeledContent("Group", value: group)
                }
                LabeledContent("Year", value: String(row.year))
            }

            Section("Pay") {
                LabeledContent("Comparable annual", value: row.comparableAnnual.currency)
                LabeledContent("Hourly equiv (1950h)", value: row.hourlyEquiv.hourly)
                LabeledContent("Biweekly gross (75h)", value: row.biweeklyGross.currency)

                if row.minWageApplies {
                    LabeledContent("Min wage applies", value: "Yes (hourly row)")
                    LabeledContent("Below min wage?", value: row.belowMinWageApplies ? "Yes" : "No")
                } else {
                    LabeledContent("Min wage applies", value: "No (annual/stipend row)")
                }

                if let mult = row.multipleOfMinWage {
                    LabeledContent("Multiple of min wage", value: String(format: "%.2fx", mult))
                }
            }

            Section("Change vs previous year") {
                if let prev = row.prevComparableAnnual {
                    LabeledContent("Prev comparable", value: prev.currency)
                } else {
                    LabeledContent("Prev comparable", value: "—")
                }

                if let d = row.deltaPrevYear {
                    LabeledContent("Δ", value: d.currency)
                } else {
                    LabeledContent("Δ", value: "—")
                }

                if let p = row.pctPrevYear {
                    LabeledContent("%", value: p.percent)
                } else {
                    LabeledContent("%", value: "—")
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: row.shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
}

// MARK: - Cell UI

private struct SalaryRowCell: View {
    let row: RBSalaryRow

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(row.displayTitle)
                .font(.headline)
                .lineLimit(2)

            Text(row.name)
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Text(row.comparableAnnual.currency)
                    .font(.caption.weight(.semibold))

                Text(row.hourlyEquiv.hourly)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                if let p = row.pctPrevYear {
                    Text(p.percent)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                if row.minWageApplies, row.belowMinWageApplies {
                    Text("⚠︎ below min")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                }

                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

private struct SalaryStatRow: View {
    let label: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack {
            Label(label, systemImage: systemImage)
            Spacer()
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

private struct SalaryPill: View {
    let label: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage).font(.caption.weight(.semibold))
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.caption.weight(.semibold))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Model + CSV loading

@MainActor
final class RBSalaryInsightsModel: ObservableObject {

    @Published var rows: [RBSalaryRow] = []
    @Published var errorMessage: String? = nil
    @Published var sourceLabel: String = "Payroll_2026_app_ready.csv"

    private(set) var availableYears: [Int] = []

    // Add your file to the bundle under this name:
    // Payroll_2026_app_ready.csv
    private let bundleCSVName = "Payroll_2026_app_ready"
    private let bundleCSVExt = "csv"
    private let fallbackBundleCSVName = "salary_excerpt_2021_2026_app_ready_with_elected_officials_police_highway_2021_2026"

    func preloadFromBundleIfNeeded() {
        guard rows.isEmpty else { return }
        loadFromBundle()
    }

    func loadFromBundle() {
        errorMessage = nil
        if let url = Bundle.main.url(forResource: bundleCSVName, withExtension: bundleCSVExt) {
            load(from: url, label: "\(bundleCSVName).\(bundleCSVExt)")
            return
        }
        if let fallbackURL = Bundle.main.url(forResource: fallbackBundleCSVName, withExtension: bundleCSVExt) {
            load(from: fallbackURL, label: "\(fallbackBundleCSVName).\(bundleCSVExt)")
            return
        }
        errorMessage = "Missing bundle file: \(bundleCSVName).\(bundleCSVExt) (or fallback). Add to Target Membership."
    }

    func load(from url: URL) {
        load(from: url, label: url.lastPathComponent)
    }

    private func load(from url: URL, label: String) {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            let parsed = try RBSalaryCSV.parse(text: text)
            self.rows = parsed
            self.sourceLabel = label
            self.availableYears = Array(Set(parsed.map(\.year))).sorted()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func summary(for year: Int) -> RBSalaryYearSummary {
        let yearRows = rows.filter { $0.year == year }
        let headcount = Set(yearRows.map { $0.key ?? "\($0.year)|\($0.name)|\($0.title)" }).count
        let totalPayroll = yearRows.reduce(0.0) { $0 + $1.comparableAnnual }
        let avgAnnual = yearRows.isEmpty ? 0 : totalPayroll / Double(yearRows.count)
        let avgHourly = avgAnnual / RBSalaryConstants.hoursPerYear
        let avgBiweekly = avgHourly * RBSalaryConstants.hoursPerPay
        return .init(year: year, headcount: headcount, totalPayroll: totalPayroll, avgAnnual: avgAnnual, avgHourly: avgHourly, avgBiweekly: avgBiweekly)
    }

    func previousYear(of year: Int) -> Int? {
        let sorted = availableYears.sorted()
        guard let idx = sorted.firstIndex(of: year), idx > 0 else { return nil }
        return sorted[idx - 1]
    }

    func topIncreases(for year: Int, limit: Int) -> [RBSalaryRow] {
        // Uses the precomputed Δ vs Prev Year if present
        let yearRows = rows.filter { $0.year == year }
        return yearRows
            .filter { ($0.deltaPrevYear ?? 0) > 0 }
            .sorted { ($0.deltaPrevYear ?? 0) > ($1.deltaPrevYear ?? 0) }
            .prefix(limit)
            .map { $0 }
    }
}

// MARK: - Data types

private enum RBSalaryConstants {
    static let hoursPerWeek: Double = 37.5
    static let hoursPerPay: Double = 75.0
    static let paysPerYear: Double = 26.0
    static let hoursPerYear: Double = 1950.0
}

struct RBSalaryYearSummary: Hashable {
    let year: Int
    let headcount: Int
    let totalPayroll: Double
    let avgAnnual: Double
    let avgHourly: Double
    let avgBiweekly: Double
}

struct RBSalaryRow: Identifiable, Hashable {
    let id: String

    let year: Int
    let employeeGroup: String?
    let name: String
    let title: String
    let step: String?

    let comparableAnnual: Double
    let hourlyEquiv: Double
    let biweeklyGross: Double

    let minWageApplies: Bool
    let belowMinWageApplies: Bool
    let multipleOfMinWage: Double?

    let prevComparableAnnual: Double?
    let deltaPrevYear: Double?
    let pctPrevYear: Double?

    let key: String?

    var displayTitle: String {
        if let step, !step.isEmpty { return "\(title) • \(step)" }
        return title
    }

    var shareText: String {
        var lines: [String] = []
        lines.append("\(name) — \(title)")
        lines.append("Year: \(year)")
        if let step, !step.isEmpty { lines.append("Step: \(step)") }
        if let employeeGroup, !employeeGroup.isEmpty { lines.append("Group: \(employeeGroup)") }
        lines.append("")
        lines.append("Comparable annual: \(comparableAnnual.currency)")
        lines.append("Hourly equiv: \(hourlyEquiv.hourly)")
        lines.append("Biweekly gross (75h): \(biweeklyGross.currency)")
        if minWageApplies {
            lines.append("Min wage applies (hourly row): Yes")
            lines.append("Below min wage?: \(belowMinWageApplies ? "Yes" : "No")")
        } else {
            lines.append("Min wage applies: No (annual/stipend row)")
        }
        if let m = multipleOfMinWage {
            lines.append(String(format: "Multiple of min wage: %.2fx", m))
        }
        if let d = deltaPrevYear, let p = pctPrevYear {
            lines.append("")
            lines.append("Δ vs prev year: \(d.currency) (\(p.percent))")
        }
        return lines.joined(separator: "\n")
    }

    static func defaultSort(_ a: RBSalaryRow, _ b: RBSalaryRow) -> Bool {
        if a.comparableAnnual != b.comparableAnnual { return a.comparableAnnual > b.comparableAnnual }
        return a.name < b.name
    }
}

// MARK: - CSV parsing (RFC4180-ish, quote-aware)

private enum RBSalaryCSV {

    enum ParseError: LocalizedError {
        case empty
        case missingHeaders

        var errorDescription: String? {
            switch self {
            case .empty: return "CSV is empty."
            case .missingHeaders: return "CSV missing headers row."
            }
        }
    }

    static func parse(text: String) throws -> [RBSalaryRow] {
        let rows = parseRFC4180(text)
        guard !rows.isEmpty else { throw ParseError.empty }
        guard let headers = rows.first else { throw ParseError.missingHeaders }

        let headerIndex = makeHeaderIndex(headers)
        var out: [RBSalaryRow] = []

        for i in 1..<rows.count {
            let r = rows[i]
            if r.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { continue }

            let year = int(r, headerIndex, "Year") ?? 0
            let employeeGroup = str(r, headerIndex, "Employee Group")
            let name = str(r, headerIndex, "Name") ?? "Unknown"
            let title = str(r, headerIndex, "Title") ?? "Unknown"
            let step = str(r, headerIndex, "Step")

            let comparableAnnual = dbl(r, headerIndex, "Comparable Annual") ?? 0
            let hourlyEquiv = dbl(r, headerIndex, "Hourly (equiv @37.5h)") ?? (comparableAnnual / RBSalaryConstants.hoursPerYear)
            let biweeklyGross =
                dbl(r, headerIndex, "Biweekly Gross (annual/26)") ??
                (hourlyEquiv * RBSalaryConstants.hoursPerPay)

            let minWageApplies = bool(r, headerIndex, "MinWage Applies") ?? false
            let belowMin = bool(r, headerIndex, "Below Min Wage (applies)") ?? false
            let multiple = dbl(r, headerIndex, "Multiple of Min Wage (hourly basis)")

            let prev = dbl(r, headerIndex, "Prev Year Comparable Annual")
            let delta = dbl(r, headerIndex, "Δ vs Prev Year")
            let pct = dbl(r, headerIndex, "% vs Prev Year")

            let key = str(r, headerIndex, "Key")
            let id = "\(year)|\(key ?? "\(name)|\(title)|\(step ?? "")")"

            out.append(
                RBSalaryRow(
                    id: id,
                    year: year,
                    employeeGroup: employeeGroup,
                    name: name,
                    title: title,
                    step: step,
                    comparableAnnual: comparableAnnual,
                    hourlyEquiv: hourlyEquiv,
                    biweeklyGross: biweeklyGross,
                    minWageApplies: minWageApplies,
                    belowMinWageApplies: belowMin,
                    multipleOfMinWage: multiple,
                    prevComparableAnnual: prev,
                    deltaPrevYear: delta,
                    pctPrevYear: pct,
                    key: key
                )
            )
        }

        return out
    }

    // Quote-aware CSV parser
    private static func parseRFC4180(_ text: String) -> [[String]] {
        var out: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false

        var i = text.startIndex
        while i < text.endIndex {
            let ch = text[i]

            if inQuotes {
                if ch == "\"" {
                    let next = text.index(after: i)
                    if next < text.endIndex, text[next] == "\"" {
                        field.append("\"")
                        i = next
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(ch)
                }
            } else {
                if ch == "\"" {
                    inQuotes = true
                } else if ch == "," {
                    row.append(field)
                    field = ""
                } else if ch == "\n" {
                    row.append(field)
                    out.append(row.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                    row = []
                    field = ""
                } else if ch == "\r" {
                    // ignore
                } else {
                    field.append(ch)
                }
            }

            i = text.index(after: i)
        }

        // flush
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            out.append(row.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
        }

        return out
    }

    private static func makeHeaderIndex(_ headers: [String]) -> [String: Int] {
        var dict: [String: Int] = [:]
        for (idx, h) in headers.enumerated() {
            dict[h.trimmingCharacters(in: .whitespacesAndNewlines)] = idx
        }
        return dict
    }

    private static func str(_ row: [String], _ h: [String: Int], _ key: String) -> String? {
        guard let idx = h[key], idx < row.count else { return nil }
        let v = row[idx].trimmingCharacters(in: .whitespacesAndNewlines)
        return v.isEmpty ? nil : v
    }

    private static func dbl(_ row: [String], _ h: [String: Int], _ key: String) -> Double? {
        guard let s = str(row, h, key) else { return nil }
        let cleaned = s
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "%", with: "")
        return Double(cleaned)
    }

    private static func int(_ row: [String], _ h: [String: Int], _ key: String) -> Int? {
        guard let s = str(row, h, key) else { return nil }
        return Int(s.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func bool(_ row: [String], _ h: [String: Int], _ key: String) -> Bool? {
        guard let s = str(row, h, key) else { return nil }
        let v = s.lowercased()
        if v == "true" || v == "1" || v == "yes" { return true }
        if v == "false" || v == "0" || v == "no" { return false }
        return nil
    }
}

// MARK: - Formatting

private extension Double {
    var currency: String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.maximumFractionDigits = 2
        return nf.string(from: NSNumber(value: self)) ?? String(format: "$%.2f", self)
    }

    var hourly: String {
        String(format: "$%.2f/hr", self)
    }

    var percent: String {
        String(format: "%.2f%%", self * 100.0)
    }
}
