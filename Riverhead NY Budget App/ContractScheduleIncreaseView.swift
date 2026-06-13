import SwiftUI

@MainActor
struct ContractScheduleIncreaseView: View {
    @StateObject private var model = ContractScheduleIncreaseModel()
    @State private var searchText: String = ""
    @State private var selectedGroup: LaborGroup? = nil
    @State private var selectedYear: Int = 2027
    @State private var showDeptMapEditor = false

    private var estimatesByID: [UUID: ContractRaiseEstimate] {
        Dictionary(uniqueKeysWithValues: filteredRows.map { row in
            let group = model.effectiveGroup(for: row)
            return (row.id, model.estimate(for: row, year: selectedYear, group: group))
        })
    }

    private var filteredSummary: ContractProjectionSummary {
        let estimates = filteredRows.compactMap { estimatesByID[$0.id] }
        let totalBase = filteredRows.reduce(0) { $0 + $1.currentAmount }
        let totalProjected = estimates.reduce(0) { $0 + $1.projectedAmount }
        let totalIncrease = estimates.reduce(0) { $0 + $1.increaseAmount }

        return ContractProjectionSummary(
            rowCount: filteredRows.count,
            totalBase: totalBase,
            totalProjected: totalProjected,
            totalIncrease: totalIncrease,
            appliedCount: estimates.filter { $0.status == .applied }.count,
            elapsedCount: estimates.filter { $0.status == .elapsed }.count,
            unmappedCount: estimates.filter { $0.status == .unmapped }.count
        )
    }

    private var filteredRows: [ContractEmployeeRow] {
        model.rows.filter { row in
            let group = model.effectiveGroup(for: row)
            let groupOK = selectedGroup == nil || group == selectedGroup
            let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let searchOK = search.isEmpty ||
                row.name.lowercased().contains(search) ||
                row.title.lowercased().contains(search) ||
                row.department.lowercased().contains(search) ||
                (row.step?.lowercased().contains(search) ?? false)
            return groupOK && searchOK
        }
        .sorted { $0.currentAmount > $1.currentAmount }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contract Increase Snapshot")
                        .font(.headline)

                    Text("This view estimates how the app's current contract schedules could change 2026 payroll if you carry them forward to \(selectedYear). It is a planning tool, not a substitute for adopted agreements or payroll setup.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack {
                        projectionMetric("Rows", value: "\(filteredSummary.rowCount)")
                        Spacer()
                        projectionMetric("Base payroll", value: model.currency(filteredSummary.totalBase))
                    }

                    HStack {
                        projectionMetric("Modeled increase", value: model.currency(filteredSummary.totalIncrease), accent: .orange)
                        Spacer()
                        projectionMetric("Projected payroll", value: model.currency(filteredSummary.totalProjected), accent: .green)
                    }

                    HStack(spacing: 8) {
                        statusPill("Active schedule", count: filteredSummary.appliedCount, color: .green)
                        statusPill("Elapsed", count: filteredSummary.elapsedCount, color: .orange)
                        statusPill("No future map", count: filteredSummary.unmappedCount, color: .secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Projection") {
                Picker("Contract Group", selection: Binding(
                    get: { selectedGroup?.id ?? "all" },
                    set: { newValue in
                        selectedGroup = LaborGroup.allCases.first(where: { $0.id == newValue })
                    }
                )) {
                    Text("All Groups").tag("all")
                    ForEach(LaborGroup.allCases) { group in
                        Text(group.displayName).tag(group.id)
                    }
                }
                .pickerStyle(.menu)

                Stepper("Projection Year: \(selectedYear)", value: $selectedYear, in: 2026...2032)

                Button("Edit Department Union Map") {
                    showDeptMapEditor = true
                }

                Text("Future projection carries the current payroll year forward using the app's built-in contract schedule assumptions. If a contract does not reach the selected year, the estimate stops and is marked as elapsed.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Department → Union Map") {
                ForEach(model.departmentSummaries, id: \.department) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.department)
                                .font(.subheadline)
                            Text("Rows: \(item.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(model.displayName(for: item.group))
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
            }

            Section("Name, Schedule, Amount, Modeled Increase") {
                if filteredRows.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.errorMessage ?? "No rows found.")
                            .foregroundStyle(.secondary)
                        if !model.sourceLabel.isEmpty {
                            Text("Data source: \(model.sourceLabel)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    ForEach(filteredRows) { row in
                        let group = model.effectiveGroup(for: row)
                        let estimate = estimatesByID[row.id] ?? model.estimate(for: row, year: selectedYear, group: group)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top, spacing: 8) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(row.name)
                                        .font(.headline)
                                        .lineLimit(1)

                                    Text(row.title)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer(minLength: 8)

                                Text(estimate.status.badgeLabel)
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(estimate.status.color.opacity(0.14))
                                    .foregroundStyle(estimate.status.color)
                                    .clipShape(Capsule())
                            }

                            detailRow("Department", value: row.department)
                            detailRow("Schedule", value: row.scheduleLabel)
                            detailRow("Union", value: model.displayName(for: group))

                            HStack {
                                Text("Current amount")
                                Spacer()
                                Text(model.currency(row.currentAmount))
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)

                            HStack(alignment: .top) {
                                Text("Modeled increase")
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(model.currency(estimate.increaseAmount))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(estimate.increaseAmount > 0 ? .orange : .secondary)
                                    Text("Projected \(selectedYear): \(model.currency(estimate.projectedAmount))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(estimate.methodLabel)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            if let note = estimate.note {
                                Text(note)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Contract Increases")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search name/title/dept/schedule")
        .task {
            model.loadFromBundle()
        }
        .sheet(isPresented: $showDeptMapEditor) {
            NavigationStack {
                DepartmentUnionMapEditor(model: model)
            }
        }
    }

    private func projectionMetric(_ label: String, value: String, accent: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accent)
        }
    }

    private func statusPill(_ label: String, count: Int, color: Color) -> some View {
        Text("\(label): \(count)")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.14))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text("\(label):")
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
    }
}

@MainActor
private struct DepartmentUnionMapEditor: View {
    @ObservedObject var model: ContractScheduleIncreaseModel

    var body: some View {
        List {
            Section("Override Department Union") {
                ForEach(model.allDepartments, id: \.self) { dept in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dept)
                                .font(.subheadline)
                            Text("Auto: \(model.displayName(for: model.defaultGroup(forDepartment: dept)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Picker(
                            "Union",
                            selection: Binding(
                                get: { model.overrideTag(forDepartment: dept) },
                                set: { model.setOverride(department: dept, tag: $0) }
                            )
                        ) {
                            Text("Auto").tag("auto")
                            ForEach(LaborGroup.allCases) { g in
                                Text(g.displayName).tag(g.id)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
        }
        .navigationTitle("Department Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    model.resetOverrides()
                }
            }
        }
    }
}

@MainActor
final class ContractScheduleIncreaseModel: ObservableObject {
    @Published var rows: [ContractEmployeeRow] = []
    @Published var errorMessage: String?
    @Published private(set) var departmentOverrides: [String: LaborGroup] = [:]
    @Published private(set) var sourceLabel: String = ""

    private let primaryCSV = "Payroll_2026_app_ready"
    private let fallbackCSV = "salary_excerpt_2021_2026_app_ready_with_elected_officials_police_highway_2021_2026"
    private let overridesKey = "department_union_overrides_v1"

    private let defaultActions = ContractCatalog.defaultWageActions()

    var allDepartments: [String] {
        Array(Set(rows.map { $0.department })).sorted()
    }

    var departmentSummaries: [DepartmentSummary] {
        let counts = Dictionary(grouping: rows, by: { $0.department }).mapValues { $0.count }
        return counts.keys.sorted().map { dept in
            DepartmentSummary(
                department: dept,
                count: counts[dept] ?? 0,
                group: departmentOverrides[dept] ?? defaultGroup(forDepartment: dept)
            )
        }
    }

    func loadFromBundle() {
        errorMessage = nil
        sourceLabel = ""
        loadOverrides()

        if let url = Bundle.main.url(forResource: primaryCSV, withExtension: "csv") {
            load(url: url, label: "\(primaryCSV).csv")
            if !rows.isEmpty { return }
        }

        if let url = Bundle.main.url(forResource: fallbackCSV, withExtension: "csv") {
            load(url: url, label: "\(fallbackCSV).csv")
            if !rows.isEmpty {
                errorMessage = nil
                return
            }
        }

        errorMessage = errorMessage ?? "Missing payroll CSV in app bundle."
    }

    private func load(url: URL, label: String) {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            sourceLabel = label
            rows = parseCSV(text)
            if rows.isEmpty && errorMessage == nil {
                errorMessage = "No 2026 rows found in \(label)."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func effectiveGroup(for row: ContractEmployeeRow) -> LaborGroup {
        departmentOverrides[row.department] ?? row.defaultLaborGroup
    }

    func defaultGroup(forDepartment department: String) -> LaborGroup {
        if let sample = rows.first(where: { $0.department == department }) {
            return sample.defaultLaborGroup
        }
        return .csea
    }

    func overrideTag(forDepartment department: String) -> String {
        departmentOverrides[department]?.id ?? "auto"
    }

    func setOverride(department: String, tag: String) {
        if tag == "auto" {
            departmentOverrides.removeValue(forKey: department)
        } else if let g = LaborGroup.allCases.first(where: { $0.id == tag }) {
            departmentOverrides[department] = g
        }
        saveOverrides()
        objectWillChange.send()
    }

    func resetOverrides() {
        departmentOverrides = [:]
        saveOverrides()
        objectWillChange.send()
    }

    func estimate(for row: ContractEmployeeRow, year: Int, group: LaborGroup) -> ContractRaiseEstimate {
        let schedule = defaultActions[group] ?? [:]
        let baseYear = row.baseYear

        if year <= baseYear {
            return ContractRaiseEstimate(
                projectedAmount: row.currentAmount,
                increaseAmount: 0,
                methodLabel: "Base year (\(baseYear))",
                status: .baseYear,
                note: "No forward contract action is applied when the selected year is the current payroll base year or earlier."
            )
        }

        var projected = row.currentAmount
        var lastAppliedYear: Int?
        var elapsedAtYear: Int?

        for y in (baseYear + 1)...year {
            guard let action = schedule[y] else {
                elapsedAtYear = y
                break
            }
            projected = action.apply(toBasePayroll: projected, fte: 1)
            lastAppliedYear = y
        }

        let increase = max(0, projected - row.currentAmount)
        let label: String
        let status: ContractEstimateStatus
        let note: String?
        if let elapsedAtYear {
            if let lastAppliedYear {
                label = "Applied through \(lastAppliedYear); contract elapsed at \(elapsedAtYear)"
                status = .elapsed
                note = schedule[lastAppliedYear]?.note
            } else {
                label = "Contract elapsed (no scheduled increase after \(baseYear))"
                status = .unmapped
                note = nil
            }
        } else if let lastAppliedYear {
            label = "Contract schedule applied through \(lastAppliedYear)"
            status = .applied
            note = schedule[lastAppliedYear]?.note
        } else if schedule.isEmpty {
            label = "No contract schedule for this group"
            status = .unmapped
            note = nil
        } else {
            label = "No scheduled future increase"
            status = .unmapped
            note = nil
        }

        return ContractRaiseEstimate(
            projectedAmount: projected,
            increaseAmount: increase,
            methodLabel: label,
            status: status,
            note: note
        )
    }

    func displayName(for group: LaborGroup) -> String {
        group.displayName
    }

    func currency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
    }

    private func loadOverrides() {
        guard let raw = UserDefaults.standard.string(forKey: overridesKey),
              let data = raw.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
            departmentOverrides = [:]
            return
        }

        var mapped: [String: LaborGroup] = [:]
        for (k, v) in decoded {
            if let g = LaborGroup.allCases.first(where: { $0.id == v }) {
                mapped[k] = g
            }
        }
        departmentOverrides = mapped
    }

    private func saveOverrides() {
        let serial = Dictionary(uniqueKeysWithValues: departmentOverrides.map { ($0.key, $0.value.id) })
        if let data = try? JSONEncoder().encode(serial),
           let str = String(data: data, encoding: .utf8) {
            UserDefaults.standard.set(str, forKey: overridesKey)
        }
    }

    private func parseCSV(_ text: String) -> [ContractEmployeeRow] {
        let rows = parseRFC4180(text)
        guard let header = rows.first else { return [] }

        func cleanedHeader(_ s: String) -> String {
            s.replacingOccurrences(of: "\u{FEFF}", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
        }

        func index(_ key: String) -> Int? {
            header.firstIndex(where: { cleanedHeader($0) == key.lowercased() })
        }

        let idxYear = index("Year")
        let idxGroup = index("Employee Group")
        let idxName = index("Name")
        let idxTitle = index("Title")
        let idxStep = index("Step")
        let idxComparable = index("Comparable Annual")
        let idxAnnual = index("Annual Salary")

        func value(_ row: [String], _ idx: Int?) -> String {
            guard let idx, idx < row.count else { return "" }
            return row[idx].trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var out: [ContractEmployeeRow] = []

        for r in rows.dropFirst() {
            let yearRaw = value(r, idxYear)
            let year = Int(yearRaw) ?? Int(Double(yearRaw) ?? 0)
            guard year == 2026 else { continue }

            let dept = value(r, idxGroup)
            let name = value(r, idxName)
            let title = value(r, idxTitle)
            if name.isEmpty || title.isEmpty { continue }

            let step = value(r, idxStep)
            let rawComparable = value(r, idxComparable)
            let rawAnnual = value(r, idxAnnual)
            let amount = parseDouble(rawComparable) ?? parseDouble(rawAnnual) ?? 0
            guard amount > 0 else { continue }

            let defaultGroup = inferLaborGroup(department: dept, title: title)
            let schedule = step.isEmpty ? defaultGroup.displayName : step

            out.append(
                ContractEmployeeRow(
                    baseYear: year,
                    name: name,
                    title: title,
                    step: step.isEmpty ? nil : step,
                    department: dept.isEmpty ? "Unassigned" : dept,
                    scheduleLabel: schedule,
                    currentAmount: amount,
                    defaultLaborGroup: defaultGroup
                )
            )
        }

        return out
    }

    private func inferLaborGroup(department: String, title: String) -> LaborGroup {
        LaborGroup.infer(department: department, title: title, defaultGroup: .csea)
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

struct ContractEmployeeRow: Identifiable, Hashable {
    let id = UUID()
    let baseYear: Int
    let name: String
    let title: String
    let step: String?
    let department: String
    let scheduleLabel: String
    let currentAmount: Double
    let defaultLaborGroup: LaborGroup
}

struct ContractRaiseEstimate: Hashable {
    let projectedAmount: Double
    let increaseAmount: Double
    let methodLabel: String
    let status: ContractEstimateStatus
    let note: String?
}

struct DepartmentSummary: Hashable {
    let department: String
    let count: Int
    let group: LaborGroup
}

enum ContractEstimateStatus: Hashable {
    case baseYear
    case applied
    case elapsed
    case unmapped

    var badgeLabel: String {
        switch self {
        case .baseYear: return "BASE YEAR"
        case .applied: return "ACTIVE"
        case .elapsed: return "ELAPSED"
        case .unmapped: return "CHECK"
        }
    }

    var color: Color {
        switch self {
        case .baseYear: return .blue
        case .applied: return .green
        case .elapsed: return .orange
        case .unmapped: return .secondary
        }
    }
}

struct ContractProjectionSummary: Hashable {
    let rowCount: Int
    let totalBase: Double
    let totalProjected: Double
    let totalIncrease: Double
    let appliedCount: Int
    let elapsedCount: Int
    let unmappedCount: Int
}
