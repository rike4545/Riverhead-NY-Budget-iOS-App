import SwiftUI

@MainActor
struct DepartmentSpendForecastView: View {
    @StateObject private var model = DepartmentSpendForecastModel()

    @State private var projectionYear: Int = 2027
    @State private var nonPersonnelInflation: Double = 0.03
    @State private var assumedPersonnelShare: Double = 0.60
    @State private var useDepartmentShareDefaults: Bool = true

    var body: some View {
        List {
            Section("Forecast Settings") {
                Stepper("Projection Year: \(projectionYear)", value: $projectionYear, in: 2026...2032)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Non-Personnel Inflation")
                        Spacer()
                        Text(String(format: "%.1f%%", nonPersonnelInflation * 100))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $nonPersonnelInflation, in: 0...0.10, step: 0.001)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Global Personnel Share Fallback")
                        Spacer()
                        Text(String(format: "%.0f%%", assumedPersonnelShare * 100))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $assumedPersonnelShare, in: 0.35...0.90, step: 0.01)
                    Text("Used when no adopted total is entered and no department-specific rule applies. Formula: Adopted Total ~= Personnel Base / Personnel Share.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Toggle("Use Department-Specific Share Defaults", isOn: $useDepartmentShareDefaults)

                if useDepartmentShareDefaults {
                    Text("Department rules improve realism by applying tailored payroll-share defaults and ranges (for example, police tends to be higher payroll share than highway operations).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    ForEach(model.personnelShareRuleSummaries, id: \.self) { line in
                        Text("• \(line)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Range is limited to 35%–90% to avoid unrealistic extremes.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text("Contract rates are pulled from the in-app contract catalog by department union mapping. Adopted total can be edited per department.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Totals") {
                let rows = model.forecastRows(
                    for: projectionYear,
                    nonPersonnelInflation: nonPersonnelInflation,
                    assumedPersonnelShare: assumedPersonnelShare,
                    useDepartmentShareDefaults: useDepartmentShareDefaults
                )
                let adopted = rows.reduce(0) { $0 + $1.adoptedTotal }
                let projected = rows.reduce(0) { $0 + $1.projectedTotal }
                let variance = projected - adopted

                statRow("Adopted Total", model.currency(adopted))
                statRow("Projected Total", model.currency(projected))
                statRow("Variance", model.currency(variance), color: variance >= 0 ? .orange : .green)
            }

            Section("Department Cost Center Forecast") {
                let rows = model.forecastRows(
                    for: projectionYear,
                    nonPersonnelInflation: nonPersonnelInflation,
                    assumedPersonnelShare: assumedPersonnelShare,
                    useDepartmentShareDefaults: useDepartmentShareDefaults
                )

                if rows.isEmpty {
                    Text(model.errorMessage ?? "No department rows loaded.")
                        .foregroundStyle(.secondary)
                }

                ForEach(rows) { row in
                    NavigationLink {
                        DepartmentForecastDetailView(
                            row: row,
                            onSaveAdopted: { value in
                                model.setAdoptedOverride(value, forDepartment: row.department)
                            }
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(row.department)
                                    .font(.headline)
                                Spacer()
                                Text(model.displayName(for: row.unionGroup))
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.primary.opacity(0.08))
                                    .clipShape(Capsule())
                            }

                            HStack {
                                Text("Headcount")
                                Spacer()
                                Text("\(row.headcount)")
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)

                            HStack {
                                Text("Assumed Personnel Share")
                                Spacer()
                                Text("\(Int(row.assumedPersonnelShare * 100))% (\(row.shareSourceLabel))")
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                            HStack {
                                Text("Adopted")
                                Spacer()
                                Text(model.currency(row.adoptedTotal))
                            }
                            .font(.subheadline)

                            HStack {
                                Text("Projected")
                                Spacer()
                                Text(model.currency(row.projectedTotal))
                            }
                            .font(.subheadline.weight(.semibold))

                            HStack {
                                Text("Projected / Month")
                                Spacer()
                                Text(model.currency(row.projectedPerMonth))
                            }
                            .font(.footnote)

                            HStack {
                                Text("Projected / 26-Pay Cycle")
                                Spacer()
                                Text(model.currency(row.projectedPerPayCycle))
                            }
                            .font(.footnote)

                            HStack {
                                Text("Variance")
                                Spacer()
                                Text(model.currency(row.variance))
                                    .foregroundStyle(row.variance >= 0 ? .orange : .green)
                            }
                            .font(.footnote)

                            Text(row.confidenceLabel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Dept Spend Forecast")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            model.loadFromBundle()
        }
    }

    @ViewBuilder
    private func statRow(_ label: String, _ value: String, color: Color = .primary) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
}

@MainActor
private struct DepartmentForecastDetailView: View {
    let row: DepartmentForecastRow
    let onSaveAdopted: (Double) -> Void

    @State private var adoptedText: String = ""

    var body: some View {
        List {
            Section("Department") {
                rowLine("Name", row.department)
                rowLine("Union Group", row.unionGroup.displayName)
                rowLine("Headcount", "\(row.headcount)")
                rowLine("Data Quality", row.confidenceLabel)
            }

            Section("Current Baseline") {
                rowLine("Personnel Base", currency(row.personnelBase))
                rowLine("Assumed Personnel Share", "\(Int(row.assumedPersonnelShare * 100))% (\(row.shareSourceLabel))")
                rowLine("Non-Personnel Base", currency(row.nonPersonnelBase))
                rowLine("Adopted Total", currency(row.adoptedTotal))
            }

            Section("Projected") {
                rowLine("Projected Personnel", currency(row.projectedPersonnel))
                rowLine("Projected Non-Personnel", currency(row.projectedNonPersonnel))
                rowLine("Projected Total", currency(row.projectedTotal))
                rowLine("Projected / Month", currency(row.projectedPerMonth))
                rowLine("Projected / 26-Pay Cycle", currency(row.projectedPerPayCycle))
                rowLine("Variance", currency(row.variance))
            }

            Section("Salary Schedules In Department") {
                ForEach(row.salarySchedules) { sched in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sched.schedule)
                                .font(.subheadline)
                            Text("Headcount: \(sched.headcount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(currency(sched.totalAnnualComparable))
                            .font(.caption.weight(.semibold))
                    }
                }
            }

            Section("Set Adopted Override") {
                TextField("Adopted total amount", text: $adoptedText)
                    .keyboardType(.decimalPad)

                Button("Save Override") {
                    let cleaned = adoptedText.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
                    if let v = Double(cleaned), v > 0 {
                        onSaveAdopted(v)
                    }
                }
            }
        }
        .navigationTitle(row.department)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            adoptedText = String(format: "%.2f", row.adoptedTotal)
        }
    }

    @ViewBuilder
    private func rowLine(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func currency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
    }
}

@MainActor
final class DepartmentSpendForecastModel: ObservableObject {
    @Published var departments: [DepartmentBase] = []
    @Published var errorMessage: String?

    private let primaryCSV = "Payroll_2026_app_ready"
    private let fallbackCSV = "salary_excerpt_2021_2026_app_ready_with_elected_officials_police_highway_2021_2026"
    private let adoptedOverridesKey = "dept_adopted_overrides_v1"
    private let unionOverridesKey = "department_union_overrides_v1"

    private var adoptedOverrides: [String: Double] = [:]
    private var unionOverrides: [String: LaborGroup] = [:]

    private let contractActions = ContractCatalog.defaultWageActions()

    func loadFromBundle() {
        loadOverrides()

        if let url = Bundle.main.url(forResource: primaryCSV, withExtension: "csv") {
            if load(url) { return }
        }

        if let url = Bundle.main.url(forResource: fallbackCSV, withExtension: "csv") {
            if load(url) { return }
        }

        #if DEBUG
        let localCandidates = [
            "/Users/bryan/Documents/Riverhead NY Budget App/Riverhead NY Budget App/Payroll_2026_app_ready.csv",
            "/Users/bryan/Documents/macbook builds/Riverhead NY Budget App/Riverhead NY Budget App/Payroll_2026_app_ready.csv",
            "/Users/bryan/Documents/Riverhead NY Budget App/Riverhead NY Budget App/salary_excerpt_2021_2026_app_ready_with_elected_officials_police_highway_2021_2026.csv",
            "/Users/bryan/Documents/macbook builds/Riverhead NY Budget App/Riverhead NY Budget App/salary_excerpt_2021_2026_app_ready_with_elected_officials_police_highway_2021_2026.csv"
        ]

        for path in localCandidates {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                if load(url) { return }
            }
        }
        #endif

        errorMessage = "Missing payroll CSV in app bundle (and local debug fallback). Expected: \(primaryCSV).csv or \(fallbackCSV).csv"
    }

    func setAdoptedOverride(_ value: Double, forDepartment department: String) {
        adoptedOverrides[department] = value
        saveAdoptedOverrides()
    }

    func displayName(for group: LaborGroup) -> String {
        group.displayName
    }

    func forecastRows(for year: Int, nonPersonnelInflation: Double, assumedPersonnelShare: Double) -> [DepartmentForecastRow] {
        departments
            .map { base in
                let unionGroup = unionOverrides[base.department] ?? base.defaultUnionGroup
                let projectedPersonnel = projectPersonnel(
                    base: base.personnelBase,
                    group: unionGroup,
                    fromYear: 2026,
                    toYear: year
                )

                let adoptedTotal: Double
                let confidence: String
                let effectiveShare = resolvePersonnelShare(
                    department: base.department,
                    globalShare: assumedPersonnelShare,
                    useDepartmentDefaults: useDepartmentShareDefaults
                )
                if let override = adoptedOverrides[base.department], override > 0 {
                    adoptedTotal = override
                    confidence = "High confidence (manual adopted override)"
                } else {
                    adoptedTotal = base.personnelBase / max(effectiveShare.share, 0.01)
                    confidence = "Medium confidence (adopted estimated from \(effectiveShare.sourceLabel.lowercased()) personnel share)"
                }

                let nonPersonnelBase = max(adoptedTotal - base.personnelBase, 0)
                let years = max(year - 2026, 0)
                let projectedNonPersonnel = nonPersonnelBase * pow(1 + nonPersonnelInflation, Double(years))
                let projectedTotal = projectedPersonnel + projectedNonPersonnel

                return DepartmentForecastRow(
                    department: base.department,
                    unionGroup: unionGroup,
                    headcount: base.headcount,
                    personnelBase: base.personnelBase,
                    nonPersonnelBase: nonPersonnelBase,
                    adoptedTotal: adoptedTotal,
                    projectedPersonnel: projectedPersonnel,
                    projectedNonPersonnel: projectedNonPersonnel,
                    projectedTotal: projectedTotal,
                    projectedPerMonth: projectedTotal / 12,
                    projectedPerPayCycle: projectedTotal / 26,
                    variance: projectedTotal - adoptedTotal,
                    confidenceLabel: confidence,
                    assumedPersonnelShare: effectiveShare.share,
                    shareSourceLabel: effectiveShare.sourceLabel,
                    salarySchedules: base.salarySchedules
                )
            }
            .sorted { $0.projectedTotal > $1.projectedTotal }
    }

    func forecastRows(
        for year: Int,
        nonPersonnelInflation: Double,
        assumedPersonnelShare: Double,
        useDepartmentShareDefaults: Bool
    ) -> [DepartmentForecastRow] {
        self.useDepartmentShareDefaults = useDepartmentShareDefaults
        return forecastRows(for: year, nonPersonnelInflation: nonPersonnelInflation, assumedPersonnelShare: assumedPersonnelShare)
    }

    func currency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
    }

    private func projectPersonnel(base: Double, group: LaborGroup, fromYear: Int, toYear: Int) -> Double {
        guard toYear >= fromYear else { return base }
        var value = base
        if toYear == fromYear { return value }

        for y in (fromYear + 1)...toYear {
            let action = contractActions[group]?[y] ?? .percent(0.02, note: "Fallback +2%")
            value = action.apply(toBasePayroll: value, fte: 1)
        }
        return value
    }

    private var useDepartmentShareDefaults: Bool = true

    var personnelShareRuleSummaries: [String] {
        [
            "Police/Public Safety: 82% default (70–92%)",
            "Highway/DPW/Buildings & Grounds: 68% default (50–82%)",
            "Administration/Finance/Clerk/Assessor: 74% default (60–88%)",
            "Parks/Recreation/Culture: 62% default (45–80%)",
            "Other departments: global fallback"
        ]
    }

    private struct PersonnelShareRule {
        let share: Double
        let min: Double
        let max: Double
        let sourceLabel: String
    }

    private func resolvePersonnelShare(
        department: String,
        globalShare: Double,
        useDepartmentDefaults: Bool
    ) -> PersonnelShareRule {
        let fallback = PersonnelShareRule(
            share: min(max(globalShare, 0.35), 0.90),
            min: 0.35,
            max: 0.90,
            sourceLabel: "global fallback"
        )
        guard useDepartmentDefaults else { return fallback }

        let d = department.lowercased()
        if d.contains("police") || d.contains("public safety") || d.contains("emergency") {
            return PersonnelShareRule(share: 0.82, min: 0.70, max: 0.92, sourceLabel: "dept rule")
        }
        if d.contains("highway") || d.contains("buildings & grounds") || d.contains("buildings and grounds") || d.contains("dpw") {
            return PersonnelShareRule(share: 0.68, min: 0.50, max: 0.82, sourceLabel: "dept rule")
        }
        if d.contains("finance") || d.contains("assessor") || d.contains("clerk") || d.contains("attorney") || d.contains("administrator") || d.contains("engineering") {
            return PersonnelShareRule(share: 0.74, min: 0.60, max: 0.88, sourceLabel: "dept rule")
        }
        if d.contains("parks") || d.contains("recreation") || d.contains("historian") || d.contains("museum") {
            return PersonnelShareRule(share: 0.62, min: 0.45, max: 0.80, sourceLabel: "dept rule")
        }
        return fallback
    }

    @discardableResult
    private func load(_ url: URL) -> Bool {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            let rows = parseCSV(text)
            guard !rows.isEmpty else {
                departments = []
                errorMessage = "No payroll rows parsed from \(url.lastPathComponent)."
                return false
            }
            let grouped = Dictionary(grouping: rows, by: { $0.department })

            departments = grouped.map { dept, entries in
                let personnel = entries.reduce(0) { $0 + $1.comparableAnnual }
                let defaultUnion = dominantGroup(entries)
                let headcount = Set(entries.map { $0.name }).count

                let scheduleMap = Dictionary(grouping: entries, by: { $0.schedule })
                let schedules = scheduleMap.map { schedule, values in
                    DepartmentScheduleSummary(
                        schedule: schedule,
                        headcount: Set(values.map { $0.name }).count,
                        totalAnnualComparable: values.reduce(0) { $0 + $1.comparableAnnual }
                    )
                }
                .sorted { $0.totalAnnualComparable > $1.totalAnnualComparable }

                return DepartmentBase(
                    department: dept,
                    headcount: headcount,
                    personnelBase: personnel,
                    defaultUnionGroup: defaultUnion,
                    salarySchedules: schedules
                )
            }
            .sorted { $0.personnelBase > $1.personnelBase }
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func dominantGroup(_ rows: [ParsedPayrollRow]) -> LaborGroup {
        var counts: [LaborGroup: Int] = [:]
        for r in rows {
            counts[r.group, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? .csea
    }

    private func inferGroup(department: String, title: String) -> LaborGroup {
        let d = department.lowercased()
        let t = title.lowercased()

        if d.contains("police") || t.contains("police") || t.contains("detective") || t.contains("patrol") || t.contains("officer") {
            if t.contains("chief") || t.contains("captain") || t.contains("lieutenant") || t.contains("sergeant") {
                return .soa
            }
            return .pba
        }

        if t.contains("deputy town supervisor") || t.contains("town attorney") || t.contains("deputy town attorney") ||
            t.contains("town engineer") || t.contains("budget officer") || t.contains("administrator") {
            return .exempt
        }

        return .csea
    }

    private func loadOverrides() {
        if let raw = UserDefaults.standard.string(forKey: adoptedOverridesKey),
           let data = raw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            adoptedOverrides = decoded
        }

        if let raw = UserDefaults.standard.string(forKey: unionOverridesKey),
           let data = raw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            var map: [String: LaborGroup] = [:]
            for (k, v) in decoded {
                if let g = LaborGroup.allCases.first(where: { $0.id == v }) {
                    map[k] = g
                }
            }
            unionOverrides = map
        }
    }

    private func saveAdoptedOverrides() {
        if let data = try? JSONEncoder().encode(adoptedOverrides),
           let s = String(data: data, encoding: .utf8) {
            UserDefaults.standard.set(s, forKey: adoptedOverridesKey)
        }
    }

    private func parseCSV(_ text: String) -> [ParsedPayrollRow] {
        let rows = parseRFC4180(text)
        guard let header = rows.first else { return [] }

        func normalized(_ value: String) -> String {
            let lowered = value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let mappedScalars = lowered.unicodeScalars.map { scalar -> Character in
                if CharacterSet.alphanumerics.contains(scalar) {
                    return Character(scalar)
                }
                return " "
            }
            return String(mappedScalars).split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        }

        func index(_ keys: [String]) -> Int? {
            let normalizedHeader = header.map(normalized)
            for key in keys {
                if let idx = normalizedHeader.firstIndex(of: normalized(key)) {
                    return idx
                }
            }
            return nil
        }

        let idxYear = index(["Year", "Fiscal Year"])
        let idxGroup = index(["Employee Group", "Department", "Cost Center", "Unit"])
        let idxName = index(["Name", "Employee Name"])
        let idxTitle = index(["Title", "Position", "Job Title"])
        let idxStep = index(["Step", "Schedule", "Grade"])
        let idxComparable = index(["Comparable Annual", "Annualized Comparable"])
        let idxAnnual = index(["Annual Salary", "Salary", "Amount", "Annual"])

        func value(_ row: [String], _ idx: Int?) -> String {
            guard let idx, idx < row.count else { return "" }
            return row[idx].trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let availableYears = Set(
            rows.dropFirst().compactMap { r -> Int? in
                guard let idxYear else { return nil }
                return Int(value(r, idxYear))
            }
        )
        let targetYear = availableYears.contains(2026) ? 2026 : availableYears.max()

        var out: [ParsedPayrollRow] = []
        var outWithoutYearFilter: [ParsedPayrollRow] = []

        for r in rows.dropFirst() {
            let department = value(r, idxGroup).isEmpty ? "Unassigned" : value(r, idxGroup)
            let name = value(r, idxName)
            let title = value(r, idxTitle)
            let schedule = value(r, idxStep).isEmpty ? "No Step" : value(r, idxStep)
            let comparable = parseDouble(value(r, idxComparable)) ?? parseDouble(value(r, idxAnnual)) ?? 0
            guard comparable > 0 else { continue }

            let group = inferGroup(department: department, title: title)
            let parsed = ParsedPayrollRow(
                department: department,
                name: name,
                schedule: schedule,
                comparableAnnual: comparable,
                group: group
            )
            outWithoutYearFilter.append(parsed)

            if let targetYear, let idxYear {
                let year = Int(value(r, idxYear)) ?? 0
                guard year == targetYear else { continue }
            }
            out.append(parsed)
        }

        return out.isEmpty ? outWithoutYearFilter : out
    }

    private func parseDouble(_ s: String) -> Double? {
        let cleaned = s.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "%", with: "")
        return Double(cleaned)
    }

    private func parseRFC4180(_ text: String) -> [[String]] {
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
                    out.append(row)
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

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            out.append(row)
        }

        return out
    }
}

private struct ParsedPayrollRow {
    let department: String
    let name: String
    let schedule: String
    let comparableAnnual: Double
    let group: LaborGroup
}

struct DepartmentScheduleSummary: Identifiable {
    var id: String { schedule }
    let schedule: String
    let headcount: Int
    let totalAnnualComparable: Double
}

struct DepartmentBase: Identifiable {
    var id: String { department }
    let department: String
    let headcount: Int
    let personnelBase: Double
    let defaultUnionGroup: LaborGroup
    let salarySchedules: [DepartmentScheduleSummary]
}

struct DepartmentForecastRow: Identifiable {
    var id: String { department }
    let department: String
    let unionGroup: LaborGroup
    let headcount: Int
    let personnelBase: Double
    let nonPersonnelBase: Double
    let adoptedTotal: Double
    let projectedPersonnel: Double
    let projectedNonPersonnel: Double
    let projectedTotal: Double
    let projectedPerMonth: Double
    let projectedPerPayCycle: Double
    let variance: Double
    let confidenceLabel: String
    let assumedPersonnelShare: Double
    let shareSourceLabel: String
    let salarySchedules: [DepartmentScheduleSummary]
}
