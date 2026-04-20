import SwiftUI

@MainActor
struct GrossEarningsNewsdayView: View {

    @StateObject private var model = GrossEarningsNewsdayModel()
    @State private var searchText: String = ""
    @State private var selectedYear: Int? = nil

    var body: some View {
        List {
            Section {
                HStack {
                    Label("Total Rows", systemImage: "list.bullet")
                    Spacer()
                    Text("\(yearScopedRows.count)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Matches", systemImage: "line.3.horizontal.decrease.circle")
                    Spacer()
                    Text("\(filteredRows.count)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Source", systemImage: "doc.text")
                    Spacer()
                    Text(model.sourceLabel)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let error = model.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section("Year") {
                Picker("Year", selection: $selectedYear) {
                    Text("All Years").tag(nil as Int?)
                    ForEach(model.availableYears, id: \.self) { year in
                        Text(String(year)).tag(year as Int?)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Workforce Summary (Year-over-Year)") {
                HStack {
                    Label(activeEmployeesLabel, systemImage: "person.fill.checkmark")
                    Spacer()
                    Text("\(activeEmployeesInScope)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label(separationsLabel, systemImage: "person.fill.xmark")
                    Spacer()
                    Text("\(separationsInScope)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Turnover vs Prior Year", systemImage: "percent")
                    Spacer()
                    Text(yoyComparisonAvailable ? yoyTurnoverRate.percent1 : "—")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("New Employees vs Prior Year", systemImage: "person.badge.plus")
                    Spacer()
                    Text(yoyComparisonAvailable ? "\(newEmployeesThisYear)" : "—")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Net Active Headcount Change", systemImage: "arrow.up.arrow.down")
                    Spacer()
                    Text(yoyComparisonAvailable ? netActiveHeadcountChangeLabel : "—")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Average Tenure (\(summaryScopeLabel))", systemImage: "calendar")
                    Spacer()
                    Text(averageTenureYearsInScope > 0 ? "\(averageTenureYearsInScope.number1) years" : "—")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Median Gross Salary (\(summaryScopeLabel))", systemImage: "chart.bar.fill")
                    Spacer()
                    Text(medianGrossSalaryInScope > 0 ? medianGrossSalaryInScope.currency : "—")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Average Gross Salary (\(summaryScopeLabel))", systemImage: "chart.line.uptrend.xyaxis")
                    Spacer()
                    Text(averageGrossSalaryInScope > 0 ? averageGrossSalaryInScope.currency : "—")
                        .foregroundStyle(.secondary)
                }

                if !isAllYearsSelection && yoyComparisonAvailable {
                    HStack {
                        Label("Avg Tenure of \(summaryYearLabel) Separations", systemImage: "hourglass")
                        Spacer()
                        Text(avgTenureOfTerminatedThisYear > 0 ? "\(avgTenureOfTerminatedThisYear.number1) years" : "—")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Employees") {
                if filteredRows.isEmpty {
                    ContentUnavailableView(
                        "No matching employees",
                        systemImage: "person.crop.circle.badge.xmark",
                        description: Text("Try searching by payroll name, employee ID, or union code.")
                    )
                } else {
                    ForEach(filteredRows) { row in
                        NavigationLink {
                            GrossEarningsEmployeeDetailView(row: row)
                        } label: {
                            GrossEarningsEmployeeRowView(row: row)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Gross Earnings")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search name, employee ID, union"
        )
        .task {
            model.loadFromBundleIfNeeded()
            if selectedYear == nil {
                selectedYear = model.availableYears.last
            }
        }
    }

    private var filteredRows: [GrossEarningsEmployeeRow] {
        let query = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let base = yearScopedRows.sorted { lhs, rhs in
            lhs.payrollName.localizedCaseInsensitiveCompare(rhs.payrollName) == .orderedAscending
        }

        guard !query.isEmpty else { return base }

        let tokens = query
            .split(whereSeparator: { $0.isWhitespace || $0 == "," })
            .map(String.init)
            .filter { !$0.isEmpty }

        return base.filter { row in
            let fields = [
                row.payrollName.lowercased(),
                row.employeeID.lowercased(),
                row.unionCode.lowercased(),
                row.grossPayString.lowercased()
            ]
            let idDigits = row.employeeID.filter(\.isNumber)
            let idDigitsNoLeadingZeros = String(idDigits.drop(while: { $0 == "0" }))

            return tokens.allSatisfy { token in
                if token.allSatisfy(\.isNumber) {
                    return idDigits.contains(token) || idDigitsNoLeadingZeros.contains(token)
                }
                return fields.contains(where: { $0.contains(token) })
            }
        }
    }

    private var yearScopedRows: [GrossEarningsEmployeeRow] {
        guard let selectedYear else { return model.rows }
        return model.rows.filter { $0.year == selectedYear }
    }

    private var isAllYearsSelection: Bool { selectedYear == nil }

    private var summaryScopeLabel: String {
        selectedYear.map(String.init) ?? "All Years"
    }

    private var activeEmployeesLabel: String {
        isAllYearsSelection ? "Active Employees (Latest Snapshot)" : "Active Employees (\(summaryYearLabel))"
    }

    private var separationsLabel: String {
        isAllYearsSelection ? "Separations (All Years)" : "Separations in \(summaryYearLabel)"
    }

    private var averageTenureYearsInScope: Double {
        let tenuresInDays = summaryRowsForScope.compactMap(\.tenureDays)
        guard !tenuresInDays.isEmpty else { return 0 }
        let averageDays = tenuresInDays.reduce(0, +) / Double(tenuresInDays.count)
        return averageDays / 365.25
    }

    private var averageGrossSalaryInScope: Double {
        guard !summaryRowsForScope.isEmpty else { return 0 }
        let total = summaryRowsForScope.reduce(0) { $0 + $1.grossPay }
        return total / Double(summaryRowsForScope.count)
    }

    private var medianGrossSalaryInScope: Double {
        let values = summaryRowsForScope
            .map(\.grossPay)
            .sorted()
        guard !values.isEmpty else { return 0 }
        let mid = values.count / 2
        if values.count.isMultiple(of: 2) {
            return (values[mid - 1] + values[mid]) / 2
        }
        return values[mid]
    }

    private var summaryYear: Int? {
        if let selectedYear { return selectedYear }
        return model.availableYears.last
    }

    private var summaryRowsForScope: [GrossEarningsEmployeeRow] {
        if let _ = selectedYear {
            return summaryRowsForYear
        }
        return summaryRowsAllYears
    }

    private var summaryRowsForYear: [GrossEarningsEmployeeRow] {
        guard let summaryYear else { return [] }
        let rows = model.rows.filter { $0.year == summaryYear }
        return dedupedRowsByEmployee(rows)
    }

    private var summaryRowsAllYears: [GrossEarningsEmployeeRow] {
        let years = model.availableYears
        var result: [GrossEarningsEmployeeRow] = []
        result.reserveCapacity(model.rows.count)
        for year in years {
            let rows = model.rows.filter { $0.year == year }
            result.append(contentsOf: dedupedRowsByEmployee(rows))
        }
        return result
    }

    private func dedupedRowsByEmployee(_ rows: [GrossEarningsEmployeeRow]) -> [GrossEarningsEmployeeRow] {
        var byEmployee: [String: GrossEarningsEmployeeRow] = [:]
        for row in rows {
            if let current = byEmployee[row.employeeKey] {
                switch (current.terminationDate, row.terminationDate) {
                case let (c?, r?):
                    if r > c { byEmployee[row.employeeKey] = row }
                case (.none, .some):
                    byEmployee[row.employeeKey] = row
                case (.some, .none):
                    break
                case (.none, .none):
                    if row.grossPay > current.grossPay { byEmployee[row.employeeKey] = row }
                }
            } else {
                byEmployee[row.employeeKey] = row
            }
        }
        return Array(byEmployee.values)
    }

    private var summaryYearLabel: String {
        guard let summaryYear else { return "Latest Year" }
        return String(summaryYear)
    }

    private var previousYear: Int? {
        guard let y = summaryYear else { return nil }
        let years = model.availableYears.sorted()
        guard let idx = years.firstIndex(of: y), idx > 0 else { return nil }
        return years[idx - 1]
    }

    private var summaryRowsForPreviousYear: [GrossEarningsEmployeeRow] {
        guard let previousYear else { return [] }
        let rows = model.rows.filter { $0.year == previousYear }
        return dedupedRowsByEmployee(rows)
    }

    private var yoyComparisonAvailable: Bool {
        !isAllYearsSelection && previousYear != nil && !summaryRowsForPreviousYear.isEmpty
    }

    private var activeEmployeesInScope: Int {
        if isAllYearsSelection {
            return latestRowsByEmployee.filter(\.isActive).count
        }
        return summaryRowsForYear.filter(\.isActive).count
    }

    private var activeEmployeesInPreviousYear: Int {
        summaryRowsForPreviousYear.filter(\.isActive).count
    }

    private var yoyTurnoverRate: Double {
        guard activeEmployeesInPreviousYear > 0 else { return 0 }
        return Double(separationsInSummaryYear.count) / Double(activeEmployeesInPreviousYear)
    }

    private var newEmployeesThisYear: Int {
        let current = Set(summaryRowsForYear.map(\.employeeKey))
        let previous = Set(summaryRowsForPreviousYear.map(\.employeeKey))
        return current.subtracting(previous).count
    }

    private var netActiveHeadcountChange: Int {
        summaryRowsForYear.filter(\.isActive).count - activeEmployeesInPreviousYear
    }

    private var netActiveHeadcountChangeLabel: String {
        if netActiveHeadcountChange > 0 { return "+\(netActiveHeadcountChange)" }
        return String(netActiveHeadcountChange)
    }

    private var separationsInSummaryYear: [GrossEarningsEmployeeRow] {
        guard let summaryYear else { return [] }

        var byEmployee: [String: GrossEarningsEmployeeRow] = [:]
        for row in model.rows {
            guard let term = row.terminationDate else { continue }
            let termYear = Calendar.current.component(.year, from: term)
            guard termYear == summaryYear else { continue }

            if let current = byEmployee[row.employeeKey] {
                // Keep the row with the latest termination date for that employee.
                if let currentTerm = current.terminationDate, term > currentTerm {
                    byEmployee[row.employeeKey] = row
                }
            } else {
                byEmployee[row.employeeKey] = row
            }
        }

        return Array(byEmployee.values)
    }

    private var separationsAllYears: [GrossEarningsEmployeeRow] {
        var bySeparation: [String: GrossEarningsEmployeeRow] = [:]
        let formatter = ISO8601DateFormatter()
        for row in model.rows {
            guard let term = row.terminationDate else { continue }
            let key = "\(row.employeeKey)|\(formatter.string(from: term))"
            if bySeparation[key] == nil {
                bySeparation[key] = row
            }
        }
        return Array(bySeparation.values)
    }

    private var separationsInScope: Int {
        if isAllYearsSelection { return separationsAllYears.count }
        return separationsInSummaryYear.count
    }

    private var latestRowsByEmployee: [GrossEarningsEmployeeRow] {
        dedupedRowsByEmployee(model.rows)
    }

    private var avgTenureOfTerminatedThisYear: Double {
        let days = separationsInSummaryYear.compactMap(\.tenureDays)
        guard !days.isEmpty else { return 0 }
        return (days.reduce(0, +) / Double(days.count)) / 365.25
    }
}

private struct GrossEarningsEmployeeRowView: View {
    let row: GrossEarningsEmployeeRow

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(row.payrollName)
                .font(.headline)
                .lineLimit(2)

            HStack(spacing: 12) {
                Text("ID: \(row.employeeID)")
                Text("Union: \(row.unionCode)")
                Spacer(minLength: 0)
                Text(row.grossPay.currency)
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Text("Hire: \(row.hireDateLabel)")
                Text("Term: \(row.terminationDateLabel)")
                Spacer(minLength: 0)
                Text("Tenure: \(row.tenureLabel)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

private struct GrossEarningsEmployeeDetailView: View {
    let row: GrossEarningsEmployeeRow

    var body: some View {
        List {
            Section("Employee") {
                LabeledContent("Year", value: String(row.year))
                LabeledContent("Payroll Name", value: row.payrollName)
                LabeledContent("Employee ID", value: row.employeeID)
                LabeledContent("Union Code", value: row.unionCode)
            }

            Section("Dates") {
                LabeledContent("Hire Date", value: row.hireDateLabel)
                LabeledContent("Termination Date", value: row.terminationDateLabel)
                LabeledContent("Length of Tenure", value: row.tenureLabel)
            }

            Section("Pay") {
                LabeledContent("Gross Pay", value: row.grossPay.currency)
            }
        }
        .navigationTitle("Employee Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor
final class GrossEarningsNewsdayModel: ObservableObject {
    @Published var rows: [GrossEarningsEmployeeRow] = []
    @Published var sourceLabel: String = "GrossEarnings_Newsday_2019_2021.csv"
    @Published var errorMessage: String?

    private var hasLoaded: Bool = false
    var availableYears: [Int] {
        Array(Set(rows.map(\.year))).sorted()
    }

    func loadFromBundleIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true

        let primaryURL = Bundle.main.url(
            forResource: "GrossEarnings_Newsday_2019_2021",
            withExtension: "csv"
        )
        let fallbackURL = Bundle.main.url(
            forResource: "New Gross Earnings Report_Newsday.2021 (1)",
            withExtension: "csv"
        )

        guard let url = primaryURL ?? fallbackURL else {
            errorMessage = "Could not find gross earnings CSV in the app bundle."
            return
        }

        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            let parsed = GrossEarningsNewsdayParser.parseRows(from: text)
            rows = parsed
            errorMessage = nil
        } catch {
            errorMessage = "Failed to read CSV: \(error.localizedDescription)"
        }
    }
}

private enum GrossEarningsNewsdayParser {
    static func parseRows(from csvText: String) -> [GrossEarningsEmployeeRow] {
        let lines = csvText
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard let headerLine = lines.first else { return [] }
        let header = parseCSVLine(headerLine)

        let idxName = index(in: header, matching: ["Payroll Name"])
        let idxID = index(in: header, matching: ["File Number", "Employee ID"])
        let idxYear = index(in: header, matching: ["Year"])
        let idxHireDate = index(in: header, matching: ["Hire Date"])
        let idxTerminationDate = index(in: header, matching: ["Termination Date"])
        let idxGrossPay = index(in: header, matching: ["Gross Pay"])
        let idxUnionCode = index(in: header, matching: ["Union Code"])

        guard let idxName, let idxID, let idxHireDate, let idxTerminationDate, let idxGrossPay, let idxUnionCode else {
            return []
        }

        return lines.dropFirst().compactMap { line -> GrossEarningsEmployeeRow? in
            let row = parseCSVLine(line)
            let payrollName = value(row, at: idxName)
            let employeeID = value(row, at: idxID)

            guard !payrollName.isEmpty else { return nil }
            guard normalize(payrollName) != normalize("Payroll Name") else { return nil }
            guard normalize(employeeID) != normalize("File Number") else { return nil }

            let hireDateRaw = value(row, at: idxHireDate)
            let terminationDateRaw = value(row, at: idxTerminationDate)
            let yearRaw = value(row, at: idxYear ?? -1)

            let hireDate = parseDate(hireDateRaw)
            let terminationDate = parseDate(terminationDateRaw)
            let grossPay = parseCurrency(value(row, at: idxGrossPay))
            let unionCode = value(row, at: idxUnionCode)
            let parsedYear = parseYear(yearRaw) ?? 2021

            return GrossEarningsEmployeeRow(
                year: parsedYear,
                payrollName: payrollName,
                employeeID: employeeID.isEmpty ? "—" : employeeID,
                hireDate: hireDate,
                hireDateRaw: hireDateRaw,
                terminationDate: terminationDate,
                terminationDateRaw: terminationDateRaw,
                grossPay: grossPay,
                grossPayString: value(row, at: idxGrossPay),
                unionCode: unionCode.isEmpty ? "—" : unionCode
            )
        }
    }

    private static func parseDate(_ raw: String) -> Date? {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }

        let formats = ["M/d/yy", "M/d/yyyy", "MM/dd/yy", "MM/dd/yyyy"]
        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = format
            if let date = formatter.date(from: cleaned) {
                return date
            }
        }
        return nil
    }

    private static func parseCurrency(_ raw: String) -> Double {
        let cleaned = raw
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(cleaned) ?? 0
    }

    private static func parseYear(_ raw: String) -> Int? {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let year = Int(cleaned) {
            return year
        }
        if let value = Double(cleaned) {
            return Int(value)
        }
        return nil
    }

    private static func value(_ row: [String], at index: Int) -> String {
        guard index >= 0, index < row.count else { return "" }
        return row[index].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func index(in header: [String], matching keys: [String]) -> Int? {
        let normalizedHeader = header.map(normalize)
        for key in keys {
            if let idx = normalizedHeader.firstIndex(of: normalize(key)) {
                return idx
            }
        }
        return nil
    }

    private static func normalize(_ text: String) -> String {
        let lowered = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let mapped = lowered.unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : " "
        }
        return String(mapped).split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var row: [String] = []
        var field = ""
        var inQuotes = false

        var index = line.startIndex
        while index < line.endIndex {
            let ch = line[index]

            if inQuotes {
                if ch == "\"" {
                    let next = line.index(after: index)
                    if next < line.endIndex, line[next] == "\"" {
                        field.append("\"")
                        index = next
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
                } else {
                    field.append(ch)
                }
            }

            index = line.index(after: index)
        }

        row.append(field)
        return row
    }
}

struct GrossEarningsEmployeeRow: Identifiable {
    let year: Int
    let payrollName: String
    let employeeID: String
    let hireDate: Date?
    let hireDateRaw: String
    let terminationDate: Date?
    let terminationDateRaw: String
    let grossPay: Double
    let grossPayString: String
    let unionCode: String

    var id: String {
        "\(employeeID)|\(payrollName)|\(hireDateRaw)|\(terminationDateRaw)"
    }

    // Use employee ID as canonical identity for cross-year summary math.
    var employeeKey: String {
        let digits = employeeID.filter(\.isNumber)
        if !digits.isEmpty {
            let trimmed = String(digits.drop(while: { $0 == "0" }))
            return trimmed.isEmpty ? "0" : trimmed
        }
        return payrollName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isActive: Bool {
        terminationDate == nil && terminationDateRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hireDateLabel: String {
        Self.displayDate(hireDate, fallback: hireDateRaw)
    }

    var terminationDateLabel: String {
        if terminationDate == nil && terminationDateRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Active"
        }
        return Self.displayDate(terminationDate, fallback: terminationDateRaw)
    }

    var tenureLabel: String {
        guard let hireDate else { return "—" }

        let endDate = terminationDate ?? Date()
        guard endDate >= hireDate else { return "—" }

        let parts = Calendar.current.dateComponents([.year, .month, .day], from: hireDate, to: endDate)
        let years = parts.year ?? 0
        let months = parts.month ?? 0
        let days = parts.day ?? 0

        if years > 0 { return "\(years)y \(months)m" }
        if months > 0 { return "\(months)m \(days)d" }
        return "\(max(days, 0))d"
    }

    var tenureDays: Double? {
        guard let hireDate else { return nil }
        let endDate = terminationDate ?? Date()
        guard endDate >= hireDate else { return nil }
        return endDate.timeIntervalSince(hireDate) / 86_400
    }

    private static func displayDate(_ date: Date?, fallback raw: String) -> String {
        if let date {
            return date.formatted(date: .abbreviated, time: .omitted)
        }

        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "—" : cleaned
    }
}

private extension Double {
    var currency: String {
        formatted(.currency(code: "USD"))
    }

    var percent1: String {
        formatted(.percent.precision(.fractionLength(1)))
    }

    var number1: String {
        formatted(.number.precision(.fractionLength(1)))
    }
}
