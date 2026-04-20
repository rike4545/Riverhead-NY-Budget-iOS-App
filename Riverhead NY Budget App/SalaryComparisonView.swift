import SwiftUI

@MainActor
struct SalaryComparisonView: View {
    private struct TownSalarySnapshot: Identifiable {
        let id = UUID()
        let town: String
        let supervisorSalary: Double?
        let councilSalary: Double?
        let townClerkSalary: Double?
        let registrarStipend: Double?
        let townJusticeSalary: Double?
        let taxReceiverSalary: Double?
        let assessorChairSalary: Double?
        let assessorSalary: Double?
        let trusteeSalary: Double?
        let highwaySuperSalary: Double?
        let dataYear: Int
        let sourceNote: String
    }

    private enum AutoIncreaseMethod: String, CaseIterable, Identifiable {
        case none = "No Auto Increase"
        case inflation = "Inflation"
        case cpiu = "CPI-U"
        case cpi = "CPI"
        case custom = "Custom X%"

        var id: String { rawValue }
    }

    @State private var autoIncreaseMethod: AutoIncreaseMethod = .none
    @State private var inflationPercent: Double = 3.0
    @State private var cpiUPercent: Double = 3.2
    @State private var cpiPercent: Double = 3.0
    @State private var customPercent: Double = 2.0
    @State private var showBlankRoles: Bool = false
    @State private var expandedTowns: Set<String> = ["Riverhead"]

    private var selectedIncreasePercent: Double {
        switch autoIncreaseMethod {
        case .none: return 0
        case .inflation: return inflationPercent
        case .cpiu: return cpiUPercent
        case .cpi: return cpiPercent
        case .custom: return customPercent
        }
    }

    private let snapshots: [TownSalarySnapshot] = [
        .init(
            town: "Riverhead",
            supervisorSalary: 110_000,
            councilSalary: 50_558,
            townClerkSalary: 96_085,
            registrarStipend: 5_000,
            townJusticeSalary: 96_872,
            taxReceiverSalary: 96_085,
            assessorChairSalary: 110_663,
            assessorSalary: 96_085,
            trusteeSalary: nil,
            highwaySuperSalary: 107_967,
            dataYear: 2026,
            sourceNote: "Riverhead 2026 elected/payroll snapshot: Town Clerk $96,085; Registrar stipend $5,000; Town Justice $96,872; Tax Receiver $96,085; Assessor Chair $110,663; Assessor $96,085; Highway Superintendent $107,967."
        ),
        .init(
            town: "Brookhaven",
            supervisorSalary: 177_366,
            councilSalary: 103_464,
            townClerkSalary: 133_250,
            registrarStipend: nil,
            townJusticeSalary: nil,
            taxReceiverSalary: 122_747,
            assessorChairSalary: nil,
            assessorSalary: nil,
            trusteeSalary: nil,
            highwaySuperSalary: 169_125,
            dataYear: 2026,
            sourceNote: "Brookhaven 2026 Adopted Operating Budget (Salaries of Elected Officials): Supervisor $177,366; Council $103,464; Tax Receiver $122,747; Town Clerk $133,250; Highway Superintendent $169,125."
        ),
        .init(
            town: "Smithtown",
            supervisorSalary: 161_694,
            councilSalary: 95_451,
            townClerkSalary: 91_779,
            registrarStipend: 22_500,
            townJusticeSalary: nil,
            taxReceiverSalary: 95_451,
            assessorChairSalary: nil,
            assessorSalary: 200_364,
            trusteeSalary: nil,
            highwaySuperSalary: 155_782,
            dataYear: 2026,
            sourceNote: "Smithtown 2026 elected/payroll snapshot: Supervisor $161,694; Councilmember $95,451; Assessor $200,364; Receiver of Taxes $95,451; Town Clerk $91,779; Registrar stipend $22,500; Highway Superintendent $155,782."
        ),
        .init(
            town: "East Hampton",
            supervisorSalary: 148_350,
            councilSalary: 93_564,
            townClerkSalary: 125_408,
            registrarStipend: nil,
            townJusticeSalary: nil,
            taxReceiverSalary: nil,
            assessorChairSalary: 119_442,
            assessorSalary: 108_073,
            trusteeSalary: nil,
            highwaySuperSalary: 125_408,
            dataYear: 2026,
            sourceNote: "East Hampton 2026 elected/payroll snapshot: Supervisor $148,350; Town Clerk $125,408; Assessor Chair $119,442; Assessor $108,073; Councilmember $93,564; Highway Superintendent $125,408."
        ),
        .init(
            town: "Southold",
            supervisorSalary: 129_502,
            councilSalary: 44_370,
            townClerkSalary: 122_038,
            registrarStipend: nil,
            townJusticeSalary: 65_838,
            taxReceiverSalary: 47_616,
            assessorChairSalary: nil,
            assessorSalary: 91_216,
            trusteeSalary: 26_234,
            highwaySuperSalary: 126_653,
            dataYear: 2026,
            sourceNote: "Southold 2026 elected/payroll snapshot: Supervisor $129,502; Council $44,370; Town Justice $65,838; Town Clerk $122,038; Highway Superintendent $126,653; Tax Receiver $47,616; Assessor $91,216; Trustee $26,234."
        )
    ]

    private var riverhead: TownSalarySnapshot? {
        snapshots.first { $0.town == "Riverhead" }
    }

    var body: some View {
        List {
            Section("Automatic Increase Scenario") {
                Picker("Method", selection: $autoIncreaseMethod) {
                    ForEach(AutoIncreaseMethod.allCases) { method in
                        Text(method.rawValue).tag(method)
                    }
                }

                if autoIncreaseMethod != .none {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Increase Rate")
                            Spacer()
                            Text(String(format: "%.1f%%", selectedIncreasePercent))
                                .foregroundStyle(.secondary)
                        }

                        switch autoIncreaseMethod {
                        case .inflation:
                            Slider(value: $inflationPercent, in: 0...8, step: 0.1)
                        case .cpiu:
                            Slider(value: $cpiUPercent, in: 0...8, step: 0.1)
                        case .cpi:
                            Slider(value: $cpiPercent, in: 0...8, step: 0.1)
                        case .custom:
                            Slider(value: $customPercent, in: 0...12, step: 0.1)
                        case .none:
                            EmptyView()
                        }
                    }

                    Text("Shows a what-if projection if salaries auto-increased by the selected method.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Toggle("Show roles without data", isOn: $showBlankRoles)
                    .font(.footnote)
            }

            Section("Elected Officials Salary Comparison") {
                ForEach(snapshots) { row in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedTowns.contains(row.town) },
                            set: { expanded in
                                if expanded { expandedTowns.insert(row.town) }
                                else { expandedTowns.remove(row.town) }
                            }
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            if showBlankRoles || row.supervisorSalary != nil { roleLine("Supervisor", salary: row.supervisorSalary, baseSalary: riverhead?.supervisorSalary) }
                            if showBlankRoles || row.councilSalary != nil { roleLine("Council Member", salary: row.councilSalary, baseSalary: riverhead?.councilSalary) }
                            if showBlankRoles || row.townClerkSalary != nil { roleLine("Town Clerk", salary: row.townClerkSalary, baseSalary: riverhead?.townClerkSalary) }
                            if showBlankRoles || row.registrarStipend != nil { roleLine("Registrar Stipend", salary: row.registrarStipend, baseSalary: riverhead?.registrarStipend) }
                            if showBlankRoles || row.townJusticeSalary != nil { roleLine("Town Justice", salary: row.townJusticeSalary, baseSalary: riverhead?.townJusticeSalary) }
                            if showBlankRoles || row.taxReceiverSalary != nil { roleLine("Tax Receiver", salary: row.taxReceiverSalary, baseSalary: riverhead?.taxReceiverSalary) }
                            if showBlankRoles || row.assessorChairSalary != nil { roleLine("Assessor Chair", salary: row.assessorChairSalary, baseSalary: riverhead?.assessorChairSalary) }
                            if showBlankRoles || row.assessorSalary != nil { roleLine("Assessor", salary: row.assessorSalary, baseSalary: riverhead?.assessorSalary) }
                            if showBlankRoles || row.trusteeSalary != nil { roleLine("Trustee", salary: row.trusteeSalary, baseSalary: riverhead?.trusteeSalary) }
                            if showBlankRoles || row.highwaySuperSalary != nil { roleLine("Superintendent of Highways", salary: row.highwaySuperSalary, baseSalary: riverhead?.highwaySuperSalary) }

                            roleLine("Combined (available roles)", salary: combined(row), baseSalary: combined(riverhead))

                            Text(row.sourceNote)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 6)
                    } label: {
                        HStack {
                            Text(row.town)
                                .font(.headline)
                            Spacer()
                            Text("\(Int(roleCount(for: row))) roles")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Scope") {
                Text("This view compares current elected/payroll offices currently tracked in-app.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("How To Read Deltas") {
                Text("Expand each town to see role details. Delta is always shown vs Riverhead. Optional auto-increase adds a projected salary and projected delta line.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Elected Salary Compare")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func roleLine(_ title: String, salary: Double?, baseSalary: Double?) -> some View {
        let currentDelta = delta(current: salary, base: baseSalary)

        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.subheadline)
                Spacer(minLength: 8)
                Text(formatCurrency(salary))
                    .font(.subheadline.weight(.semibold))
                Text(formatDelta(currentDelta))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(deltaColor(currentDelta))
            }

            if autoIncreaseMethod != .none,
               let projected = projectedSalary(salary),
               let uplift = increaseAmount(salary) {
                let projectedDelta = delta(current: projectedSalary(salary), base: projectedSalary(baseSalary))
                HStack {
                    Spacer()
                    Text("With \(String(format: "%.1f%%", selectedIncreasePercent)) auto-increase: \(formatCurrency(projected)) (+\(formatCurrency(uplift))) | Delta vs Riverhead: \(formatDelta(projectedDelta))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func projectedSalary(_ value: Double?) -> Double? {
        guard let value else { return nil }
        return value * (1 + selectedIncreasePercent / 100)
    }

    private func increaseAmount(_ value: Double?) -> Double? {
        guard let value else { return nil }
        return projectedSalary(value).map { $0 - value }
    }

    private func combined(_ row: TownSalarySnapshot?) -> Double? {
        guard let row else { return nil }
        let values = [
            row.supervisorSalary,
            row.councilSalary,
            row.townClerkSalary,
            row.registrarStipend,
            row.townJusticeSalary,
            row.taxReceiverSalary,
            row.assessorChairSalary,
            row.assessorSalary,
            row.trusteeSalary,
            row.highwaySuperSalary
        ].compactMap { $0 }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +)
    }

    private func roleCount(for row: TownSalarySnapshot) -> Int {
        [
            row.supervisorSalary,
            row.councilSalary,
            row.townClerkSalary,
            row.registrarStipend,
            row.townJusticeSalary,
            row.taxReceiverSalary,
            row.assessorChairSalary,
            row.assessorSalary,
            row.trusteeSalary,
            row.highwaySuperSalary
        ].compactMap { $0 }.count
    }

    private func delta(current: Double?, base: Double?) -> Double? {
        guard let current, let base else { return nil }
        return current - base
    }

    private func formatCurrency(_ value: Double?) -> String {
        guard let value else { return "—" }
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "$0"
    }

    private func formatDelta(_ value: Double?) -> String {
        guard let value else { return "" }
        let absVal = abs(value)
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 0
        let cash = f.string(from: NSNumber(value: absVal)) ?? "$0"
        if value > 0 { return "(+\(cash))" }
        if value < 0 { return "(-\(cash))" }
        return "(same)"
    }

    private func deltaColor(_ value: Double?) -> Color {
        guard let value else { return .secondary }
        if value > 0 { return .orange }
        if value < 0 { return .green }
        return .secondary
    }
}
