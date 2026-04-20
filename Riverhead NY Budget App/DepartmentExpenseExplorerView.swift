import SwiftUI

@MainActor
struct DepartmentExpenseExplorerView: View {
    @State private var selectedCategory: DepartmentExpenseFilter = .all
    @State private var searchText = ""

    private var records: [DepartmentBudgetRecord] {
        DepartmentBudgetLensData.departmentRecords
    }

    private var filteredRecords: [DepartmentBudgetRecord] {
        records.filter { record in
            let matchesCategory = selectedCategory.matches(record.category)
            let matchesSearch: Bool
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                matchesSearch = true
            } else {
                let query = searchText.lowercased()
                matchesSearch =
                    record.budgetDepartment.lowercased().contains(query) ||
                    record.staffDepartment?.lowercased().contains(query) == true ||
                    record.fundCode.lowercased().contains(query) ||
                    record.keyTitles.joined(separator: " ").lowercased().contains(query)
            }
            return matchesCategory && matchesSearch
        }
    }

    private var matchedRows: [DepartmentBudgetRecord] {
        filteredRecords.filter { $0.salaryBase != nil }
    }

    private var salaryTotal: Double {
        matchedRows.reduce(0) { $0 + ($1.salaryBase ?? 0) }
    }

    private var adoptedTotal: Double {
        filteredRecords.reduce(0) { $0 + $1.adoptedTotal }
    }

    private var otherExpenseTotal: Double {
        matchedRows.reduce(0) { $0 + ($1.otherExpense ?? 0) }
    }

    var body: some View {
        List {
            Section {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(DepartmentExpenseFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)

                Text("This view blends the staffing count, salary base, and adopted 2026 department totals so residents can see how much of each function is payroll and how much is everything else.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Snapshot") {
                summaryRow(title: "Visible functions", value: "\(filteredRecords.count)")
                summaryRow(title: "Matched salary base", value: salaryTotal, tint: .blue)
                summaryRow(title: "Adopted department totals", value: adoptedTotal, tint: .green)
                summaryRow(title: "Implied non-salary layer", value: otherExpenseTotal, tint: .orange)
            }

            Section("Department Explorer") {
                ForEach(filteredRecords) { record in
                    NavigationLink {
                        DepartmentExpenseDetailView(record: record)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(record.budgetDepartment)
                                        .font(.headline)
                                    Text(record.fundCode)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 12)
                                Text(record.category.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(color(for: record.category))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(color(for: record.category).opacity(0.12))
                                    .clipShape(Capsule())
                            }

                            HStack {
                                if let positions = record.positions {
                                    Label("\(positions) positions", systemImage: "person.3.fill")
                                } else {
                                    Label("Budget total only", systemImage: "doc.text.fill")
                                }

                                Spacer()

                                Text(record.adoptedTotal, format: .currency(code: "USD"))
                                    .font(.subheadline.weight(.semibold))
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                            if let salaryBase = record.salaryBase, let otherExpense = record.otherExpense {
                                HStack {
                                    metricPill("Salary", value: salaryBase, tint: .blue)
                                    metricPill("Other", value: otherExpense, tint: .orange)
                                }
                            }

                            if let title = record.keyTitles.first {
                                Text(title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Department Expense Explorer")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search department, fund, or title")
    }

    @ViewBuilder
    private func summaryRow(title: String, value: Double, tint: Color) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value, format: .currency(code: "USD"))
                .fontWeight(.semibold)
                .foregroundStyle(tint)
        }
    }

    @ViewBuilder
    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }

    @ViewBuilder
    private func metricPill(_ title: String, value: Double, tint: Color) -> some View {
        Text("\(title): \(value.formatted(.currency(code: "USD")))")
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.10))
            .clipShape(Capsule())
    }

    private func color(for category: DepartmentBudgetCategory) -> Color {
        switch category {
        case .governance: return .indigo
        case .publicSafety: return .red
        case .services: return .teal
        case .infrastructure: return .orange
        case .utilities: return .blue
        }
    }
}

private enum DepartmentExpenseFilter: String, CaseIterable, Identifiable {
    case all
    case governance
    case publicSafety
    case services
    case infrastructure
    case utilities

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .governance: return "Gov"
        case .publicSafety: return "Safety"
        case .services: return "Services"
        case .infrastructure: return "Infra"
        case .utilities: return "Utility"
        }
    }

    func matches(_ category: DepartmentBudgetCategory) -> Bool {
        switch self {
        case .all: return true
        case .governance: return category == .governance
        case .publicSafety: return category == .publicSafety
        case .services: return category == .services
        case .infrastructure: return category == .infrastructure
        case .utilities: return category == .utilities
        }
    }
}

private struct DepartmentExpenseDetailView: View {
    let record: DepartmentBudgetRecord

    var body: some View {
        List {
            Section("Overview") {
                detailRow("Budget function", record.budgetDepartment)
                detailRow("Fund code", record.fundCode)
                detailRow("Category", record.category.rawValue)
                if let staffDepartment = record.staffDepartment {
                    detailRow("Staffing match", staffDepartment)
                }
                if let positions = record.positions {
                    detailRow("Positions", "\(positions)")
                }
            }

            Section("2026 Cost View") {
                detailCurrencyRow("Adopted total", record.adoptedTotal, tint: .green)
                if let salaryBase = record.salaryBase {
                    detailCurrencyRow("Salary base", salaryBase, tint: .blue)
                }
                if let otherExpense = record.otherExpense {
                    detailCurrencyRow("Other expense", otherExpense, tint: .orange)
                }
                if let personnelShare = record.personnelShare {
                    detailRow("Payroll share", "\(Int((personnelShare * 100).rounded()))%")
                }
            }

            if !record.keyTitles.isEmpty {
                Section("Titles In This Department") {
                    ForEach(record.keyTitles, id: \.self) { title in
                        Text(title)
                    }
                }
            }

            if let note = record.note {
                Section("Reading Note") {
                    Text(note)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(record.budgetDepartment)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder
    private func detailCurrencyRow(_ title: String, _ value: Double, tint: Color) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value, format: .currency(code: "USD"))
                .fontWeight(.semibold)
                .foregroundStyle(tint)
        }
    }
}
