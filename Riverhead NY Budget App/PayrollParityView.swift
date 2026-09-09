import SwiftUI

// MARK: - Canonical web payroll contracts

private enum PayrollParityDataClient {
    private static let pagesRoot = "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/data/"
    private static let rawRoot = "https://raw.githubusercontent.com/rike4545/Riverhead-NY-Budget-Web-App/main/web/public/data/"

    static func load<T: Decodable>(_ relativePath: String, as type: T.Type = T.self) async throws -> T {
        var lastError: Error?
        for root in [pagesRoot, rawRoot] {
            guard let url = URL(string: root + relativePath) else { continue }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse,
                      (200..<300).contains(http.statusCode) else { continue }
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                lastError = error
            }
        }
        throw lastError ?? URLError(.badServerResponse)
    }
}

private struct PayrollRecordsDocument: Decodable, Sendable {
    let count: Int?
    let records: [PayrollParityRecord]
}

private struct PayrollParityRecord: Decodable, Identifiable, Sendable {
    let y: Int
    let n: String
    let d: String
    let t: String
    let c: String
    let u: String
    let r: Double
    let o: Double
    let g: Double
    let f: String?
    let k: [Double]?
    let i: String?

    var id: String { "\(y)|\(f ?? n)|\(n)" }
    var other: Double { g - r - o }
    var inferredTitle: Bool { (i ?? "").contains("t") }
    var inferredDepartment: Bool { (i ?? "").contains("d") }
}

private struct AuthorizedSalaryDocument: Decodable, Sendable {
    let source: Source
    let year: Int
    let note: String
    let count: Int
    let totalAuthorized: Double
    let byGroup: [GroupRollup]
    let records: [AuthorizedSalaryRecord]

    struct Source: Decodable, Sendable { let title: String; let url: String }
    struct GroupRollup: Decodable, Identifiable, Sendable {
        let group: String
        let headcount: Int
        let authorized: Double
        var id: String { group }
    }
}

private struct AuthorizedSalaryRecord: Decodable, Identifiable, Sendable {
    let name: String
    let grade: String
    let title: String
    let department: String
    let group: String
    let resolution: String?
    let annual: Double
    let hourly: Double?
    let isStipend: Bool
    let actualYear: Int?
    let actualRegular: Double?
    let actualOvertime: Double?
    let actualGross: Double?

    var id: String { "\(name)|\(title)|\(group)|\(annual)" }
}

private struct SalaryComparisonDocument: Decodable, Sendable {
    let source: Source
    let note: String
    let summary: Summary
    let records: [SalaryRaiseRecord]

    struct Source: Decodable, Sendable { let title: String; let url: String }
    struct Summary: Decodable, Sendable {
        let count2026: Int
        let matched: Int
        let raised: Int
        let promotions: Int
        let totalRaise: Double
        let avgRaise: Double
        let medianRaisePct: Double?
    }
}

private struct SalaryRaiseRecord: Decodable, Identifiable, Sendable {
    let name: String
    let title2026: String
    let title2025: String?
    let department: String
    let group: String
    let annual2026: Double
    let annual2025: Double?
    let raise: Double?
    let raisePct: Double?
    let promoted: Bool?
    let comparable: Bool

    var id: String { "\(name)|\(title2026)|\(group)" }
}

// MARK: - Hub

@MainActor
struct NativePayrollParityView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Actual pay and authorized salary are different records", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                        .foregroundStyle(RiverheadTheme.brandTeal)
                    Text("Actual pay is what appeared in the Town payroll record. Authorized salary is the Board-set base rate. Overtime, longevity, retroactive pay, stipends, and separation payouts can make actual gross pay higher.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Payroll records") {
                NavigationLink {
                    NativePayrollExplorerView()
                } label: {
                    payrollRow("Employees & Pay", "Actual earnings · 2018–2025", "person.text.rectangle.fill")
                }

                NavigationLink {
                    NativeAuthorizedSalaryView()
                } label: {
                    payrollRow("Authorized Salary", "Board-set base pay · 2025 & 2026", "checkmark.seal.fill")
                }

                NavigationLink {
                    NativeSalaryRaisesView()
                } label: {
                    payrollRow("Raises 2025 → 2026", "Matched authorized salary changes", "arrow.up.right.circle.fill")
                }
            }

            Section("Analysis") {
                NavigationLink {
                    OvertimeStaffingView()
                } label: {
                    payrollRow("Overtime & Staffing", "Overtime pressure and police staffing patterns", "clock.badge.exclamationmark")
                }

                NavigationLink {
                    SeparationPayView()
                } label: {
                    payrollRow("Separation Pay", "Unused leave liabilities and departure costs", "person.crop.circle.badge.minus")
                }

                NavigationLink {
                    PoliceStepScheduleView()
                } label: {
                    payrollRow("Police Pay Steps", "How PBA step increases work", "figure.walk.motion")
                }
            }

            Section("Source") {
                Text("Actual earnings come from the Town of Riverhead Gross Earnings reports. Authorized salaries and the 2025→2026 comparison come from the same web ETL contracts used by Riverhead Budget Live. The native overtime and separation analyses use the shared 2018–2025 payroll bundle generated from that pipeline.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Payroll")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func payrollRow(_ title: String, _ detail: String, _ symbol: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: symbol).foregroundStyle(RiverheadTheme.accent)
        }
    }
}

// MARK: - Actual earnings

private enum PayrollActualSort: String, CaseIterable, Identifiable {
    case gross = "Gross pay"
    case overtime = "Overtime"
    case regular = "Regular pay"
    case name = "Name"
    var id: String { rawValue }
}

@MainActor
private struct NativePayrollExplorerView: View {
    @State private var records: [PayrollParityRecord] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedYear = 2025
    @State private var selectedUnion = "All"
    @State private var selectedDepartment = "All"
    @State private var sort: PayrollActualSort = .gross
    @State private var searchText = ""

    private var years: [Int] { Array(Set(records.map(\.y))).sorted() }
    private var unions: [String] {
        Array(Set(records.filter { $0.y == selectedYear }.map(\.u).filter { !$0.isEmpty })).sorted()
    }
    private var departments: [String] {
        Array(Set(records.filter { $0.y == selectedYear }.map(\.d).filter { !$0.isEmpty })).sorted()
    }

    private var filtered: [PayrollParityRecord] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var rows = records.filter { row in
            guard row.y == selectedYear else { return false }
            if selectedUnion != "All" && row.u != selectedUnion { return false }
            if selectedDepartment != "All" && row.d != selectedDepartment { return false }
            guard !q.isEmpty else { return true }
            let haystack = "\(row.n) \(row.t) \(row.d) \(row.f ?? "")".lowercased()
            return haystack.contains(q)
        }
        rows.sort {
            switch sort {
            case .gross: return $0.g > $1.g
            case .overtime: return $0.o > $1.o
            case .regular: return $0.r > $1.r
            case .name: return $0.n.localizedCaseInsensitiveCompare($1.n) == .orderedAscending
            }
        }
        return rows
    }

    private var totalGross: Double { filtered.reduce(0) { $0 + $1.g } }
    private var totalOvertime: Double { filtered.reduce(0) { $0 + $1.o } }
    private var medianGross: Double {
        let values = filtered.map(\.g).sorted()
        guard !values.isEmpty else { return 0 }
        let middle = values.count / 2
        return values.count.isMultiple(of: 2) ? (values[middle - 1] + values[middle]) / 2 : values[middle]
    }

    var body: some View {
        List {
            if isLoading {
                Section { ProgressView("Loading canonical payroll records…") }
            }
            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red).font(.footnote) }
            }

            if !records.isEmpty {
                Section("Summary") {
                    stat("Employees actually paid", "\(filtered.count)")
                    stat("Total gross pay", money(totalGross))
                    stat("Total overtime", money(totalOvertime))
                    stat("Median gross pay", money(medianGross))
                }

                Section("Filters") {
                    Picker("Year", selection: $selectedYear) {
                        ForEach(years.reversed(), id: \.self) { Text(String($0)).tag($0) }
                    }
                    Picker("Union / group", selection: $selectedUnion) {
                        Text("All").tag("All")
                        ForEach(unions, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Department", selection: $selectedDepartment) {
                        Text("All").tag("All")
                        ForEach(departments, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Sort", selection: $sort) {
                        ForEach(PayrollActualSort.allCases) { Text($0.rawValue).tag($0) }
                    }
                }

                Section("Employees") {
                    ForEach(filtered) { row in
                        NavigationLink {
                            NativePayrollRecordDetailView(row: row)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.n).font(.subheadline.weight(.semibold))
                                if !row.t.isEmpty {
                                    Text("\(row.t)\(row.inferredTitle ? " · carried" : "")")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                HStack {
                                    Text("Gross \(money(row.g))")
                                    Spacer()
                                    if row.o != 0 { Text("OT \(money(row.o))") }
                                }
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Employees & Pay")
        .searchable(text: $searchText, prompt: "Name, title, department, or file #")
        .task { await load() }
        .onChange(of: selectedYear) { _, _ in
            selectedUnion = "All"
            selectedDepartment = "All"
        }
    }

    private func load() async {
        guard records.isEmpty else { return }
        do {
            let document: PayrollRecordsDocument = try await PayrollParityDataClient.load("payroll/records.json")
            records = document.records
            selectedYear = years.last ?? 2025
            isLoading = false
        } catch {
            errorMessage = "Could not load the canonical payroll records. \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        LabeledContent(label, value: value)
    }
}

private struct NativePayrollRecordDetailView: View {
    let row: PayrollParityRecord

    var body: some View {
        List {
            Section("Employee") {
                LabeledContent("Name", value: row.n)
                LabeledContent("Year", value: String(row.y))
                if let file = row.f, !file.isEmpty { LabeledContent("Payroll file #", value: file) }
                if !row.t.isEmpty { LabeledContent("Title", value: row.t + (row.inferredTitle ? " · carried" : "")) }
                if !row.d.isEmpty { LabeledContent("Department", value: row.d + (row.inferredDepartment ? " · carried" : "")) }
                if !row.u.isEmpty { LabeledContent("Group", value: row.u) }
            }
            Section("Actual pay") {
                LabeledContent("Regular", value: money(row.r))
                LabeledContent("Overtime", value: money(row.o))
                LabeledContent("Other pay", value: money(row.other))
                LabeledContent("Gross pay", value: money(row.g))
            }
            if row.inferredTitle || row.inferredDepartment {
                Section("Provenance") {
                    Text("The Town payroll export reports title and department from 2022 onward. A field marked ‘carried’ was carried back only where the ETL found a stable value across the employee's reported years; it is an inference, not a contemporaneous field in that older payroll record.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(row.n)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Authorized salaries

private enum AuthorizedSalarySort: String, CaseIterable, Identifiable {
    case annual = "Authorized salary"
    case actual = "Actual pay"
    case gap = "Actual over authorized"
    case name = "Name"
    var id: String { rawValue }
}

@MainActor
private struct NativeAuthorizedSalaryView: View {
    @State private var year = 2025
    @State private var document: AuthorizedSalaryDocument?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedGroup = "All"
    @State private var sort: AuthorizedSalarySort = .annual

    private var filtered: [AuthorizedSalaryRecord] {
        guard let document else { return [] }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var rows = document.records.filter {
            (selectedGroup == "All" || $0.group == selectedGroup)
            && (q.isEmpty || "\($0.name) \($0.title)".lowercased().contains(q))
        }
        rows.sort {
            switch sort {
            case .annual: return $0.annual > $1.annual
            case .actual: return ($0.actualGross ?? -1) > ($1.actualGross ?? -1)
            case .gap: return (($0.actualGross ?? -.infinity) - $0.annual) > (($1.actualGross ?? -.infinity) - $1.annual)
            case .name: return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
        return rows
    }

    var body: some View {
        List {
            Section("Salary year") {
                Picker("Year", selection: $year) {
                    Text("2025").tag(2025)
                    Text("2026").tag(2026)
                }
                .pickerStyle(.segmented)
            }

            if isLoading { Section { ProgressView("Loading authorized salary schedule…") } }
            if let errorMessage { Section { Text(errorMessage).foregroundStyle(.red).font(.footnote) } }

            if let document {
                Section("Summary") {
                    stat("Positions", "\(document.count)")
                    stat("Total authorized base", money(document.totalAuthorized))
                    stat("Matched to actual pay", "\(document.records.filter { $0.actualGross != nil }.count) of \(document.count)")
                    if let actualYear = document.records.compactMap(\.actualYear).first {
                        stat("Actual pay year", String(actualYear))
                    }
                }

                Section("Filters") {
                    Picker("Group", selection: $selectedGroup) {
                        Text("All").tag("All")
                        ForEach(document.byGroup) { Text("\($0.group) (\($0.headcount))").tag($0.group) }
                    }
                    Picker("Sort", selection: $sort) {
                        ForEach(AuthorizedSalarySort.allCases) { Text($0.rawValue).tag($0) }
                    }
                }

                Section("Positions") {
                    ForEach(filtered) { row in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.name).font(.subheadline.weight(.semibold))
                            Text("\(row.title) · \(row.group)")
                                .font(.caption).foregroundStyle(.secondary)
                            HStack {
                                Text("Authorized \(money(row.annual))")
                                Spacer()
                                if let actual = row.actualGross { Text("Actual \(money(actual))") }
                            }
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section("Source") {
                    Text(document.note).font(.caption).foregroundStyle(.secondary)
                    if let url = URL(string: document.source.url) {
                        Link(document.source.title, destination: url).font(.caption.weight(.semibold))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Authorized Salary")
        .searchable(text: $searchText, prompt: "Search name or title")
        .task(id: year) { await loadYear() }
    }

    private func loadYear() async {
        isLoading = true
        errorMessage = nil
        selectedGroup = "All"
        do {
            document = try await PayrollParityDataClient.load("salary/authorized-\(year).json")
        } catch {
            document = nil
            errorMessage = "Could not load the \(year) salary schedule. \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func stat(_ label: String, _ value: String) -> some View { LabeledContent(label, value: value) }
}

// MARK: - Raises

private enum RaiseSort: String, CaseIterable, Identifiable {
    case raise = "Raise dollars"
    case percent = "Raise percent"
    case salary = "2026 salary"
    case name = "Name"
    var id: String { rawValue }
}

@MainActor
private struct NativeSalaryRaisesView: View {
    @State private var document: SalaryComparisonDocument?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedGroup = "All"
    @State private var sort: RaiseSort = .raise

    private var groups: [String] {
        guard let document else { return [] }
        return Array(Set(document.records.map(\.group).filter { !$0.isEmpty })).sorted()
    }

    private var filtered: [SalaryRaiseRecord] {
        guard let document else { return [] }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var rows = document.records.filter {
            (selectedGroup == "All" || $0.group == selectedGroup)
            && (q.isEmpty || "\($0.name) \($0.title2026) \($0.title2025 ?? "")".lowercased().contains(q))
        }
        rows.sort {
            switch sort {
            case .raise: return ($0.raise ?? -.infinity) > ($1.raise ?? -.infinity)
            case .percent: return ($0.raisePct ?? -.infinity) > ($1.raisePct ?? -.infinity)
            case .salary: return $0.annual2026 > $1.annual2026
            case .name: return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
        return rows
    }

    var body: some View {
        List {
            if isLoading { Section { ProgressView("Loading 2025 → 2026 salary comparison…") } }
            if let errorMessage { Section { Text(errorMessage).foregroundStyle(.red).font(.footnote) } }

            if let document {
                Section("Summary") {
                    stat("2026 positions", "\(document.summary.count2026)")
                    stat("Matched to 2025", "\(document.summary.matched)")
                    stat("Received a raise", "\(document.summary.raised)")
                    stat("Promotions", "\(document.summary.promotions)")
                    stat("Total matched raise", money(document.summary.totalRaise))
                    stat("Average raise", money(document.summary.avgRaise))
                    if let median = document.summary.medianRaisePct {
                        stat("Median raise", String(format: "%.1f%%", median))
                    }
                }

                Section("Filters") {
                    Picker("Group", selection: $selectedGroup) {
                        Text("All").tag("All")
                        ForEach(groups, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Sort", selection: $sort) {
                        ForEach(RaiseSort.allCases) { Text($0.rawValue).tag($0) }
                    }
                }

                Section("Matched positions") {
                    ForEach(filtered) { row in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(row.name).font(.subheadline.weight(.semibold))
                                if row.promoted == true {
                                    Text("PROMOTION")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(RiverheadTheme.brandGold)
                                }
                            }
                            Text(row.title2026)
                                .font(.caption).foregroundStyle(.secondary)
                            HStack {
                                Text("2026 \(money(row.annual2026))")
                                if let prior = row.annual2025 { Text("2025 \(money(prior))") }
                                Spacer()
                                if let raise = row.raise {
                                    Text("+\(money(raise))")
                                        .foregroundStyle(raise > 0 ? RiverheadTheme.brandCoral : .secondary)
                                }
                            }
                            .font(.caption2.monospacedDigit())
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section("Source") {
                    Text(document.note).font(.caption).foregroundStyle(.secondary)
                    if let url = URL(string: document.source.url) {
                        Link(document.source.title, destination: url).font(.caption.weight(.semibold))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Raises 2025 → 2026")
        .searchable(text: $searchText, prompt: "Search name or title")
        .task { await load() }
    }

    private func load() async {
        guard document == nil else { return }
        do {
            document = try await PayrollParityDataClient.load("salary/comparison-2025-2026.json")
        } catch {
            errorMessage = "Could not load the salary comparison. \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func stat(_ label: String, _ value: String) -> some View { LabeledContent(label, value: value) }
}

private func money(_ value: Double) -> String {
    value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
}
