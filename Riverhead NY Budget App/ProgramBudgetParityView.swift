//
//  ProgramBudgetParityView.swift
//  Riverhead NY Budget App
//
//  Native counterpart to Riverhead Budget Live /programs/.
//
//  The allocation math remains owned by web/lib/programs.ts. The web build
//  publishes its computed result at /data/programs.json; this view only decodes
//  and presents that canonical contract. If the data contract is not deployed
//  yet or cannot be loaded, the existing live web page is used automatically so
//  parity access never regresses.
//

import SwiftUI
import Charts
import Foundation

struct ProgramBudgetParityDocument: Decodable, Sendable {
    struct Source: Decodable, Sendable {
        let title: String
        let detail: String
        let url: String
    }

    struct Census: Decodable, Sendable {
        let dataset: String
        let population: Double
        let households: Double
        let householdsMoe: Double
        let medianHouseholdIncome: Double
    }

    struct Department: Decodable, Identifiable, Sendable {
        let fund: String
        let code: String
        let name: String
        let amount: Double

        var id: String { "\(fund)-\(code)-\(name)" }
    }

    /// Deliberately not Identifiable: the name is not an identity. Riverhead runs
    /// two sewer districts and both file a line called "Sewer Rents", so keying a
    /// ForEach on the name renders one and silently drops $839,757 of the other.
    struct Revenue: Decodable, Sendable {
        let name: String
        let amount: Double
    }

    struct Program: Decodable, Identifiable, Sendable {
        let key: String
        let name: String
        let plain: String
        let narrative: String
        let buys: [String]
        let direct: Double
        let benefits: Double
        let fullCost: Double
        let earned: Double
        let net: Double
        let recoveryPct: Double
        let netPerResident: Double
        let netPerHousehold: Double
        let staff: Int
        let departments: [Department]
        let topRevenues: [Revenue]

        var id: String { key }
    }

    struct Totals: Decodable, Sendable {
        let direct: Double
        let benefits: Double
        let fullCost: Double
        let earned: Double
        let net: Double
        let staff: Int
        let debtService: Double
        let contingency: Double
        let interfundTransfers: Double
        let townwideRevenue: Double
        let grandTotal: Double
        let appropriations: Double
    }

    struct PerResident: Decodable, Sendable {
        let programs: Double
        let debtService: Double
        let everything: Double
    }

    struct PerHousehold: Decodable, Sendable {
        let programs: Double
        let debtService: Double
        let everything: Double
        let shareOfMedianIncome: Double
    }

    struct Reconciliation: Decodable, Sendable {
        let computed: Double
        let appropriations: Double
        let variance: Double
    }

    struct Method: Decodable, Identifiable, Sendable {
        let title: String
        let body: String

        var id: String { title }
    }

    struct Limitation: Decodable, Sendable {
        let title: String
        let body: String
    }

    struct Diagnostics: Decodable, Sendable {
        let unmappedPayrollDepartments: [String]
    }

    let schemaVersion: Int
    let source: Source
    let payrollYear: Int
    let census: Census
    let programs: [Program]
    let totals: Totals
    let perResident: PerResident
    let perHousehold: PerHousehold
    let reconciliation: Reconciliation
    let method: [Method]
    let notCovered: Limitation
    let diagnostics: Diagnostics
}

/// Internal rather than private so the contract tests can decode the same
/// bundled file through the same code path the app uses.
enum ProgramBudgetParityClient {
    static let dataURL = URL(string: "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/data/programs.json")!
    static let livePageURL = URL(string: "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/programs/")!

    /// The same contract, shipped in the bundle by this app. Reached when the
    /// network copy cannot be, so the parity route degrades to offline-native
    /// rather than straight to a web page that needs the network anyway.
    static func bundled() -> ProgramBudgetParityDocument? {
        guard let url = Bundle.main.url(forResource: "programs", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode(ProgramBudgetParityDocument.self, from: data)
    }

    static func load() async throws -> ProgramBudgetParityDocument {
        var request = URLRequest(url: dataURL)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(ProgramBudgetParityDocument.self, from: data)
    }
}

@MainActor
struct NativeProgramBudgetView: View {
    @State private var document: ProgramBudgetParityDocument?
    @State private var isLoading = false
    @State private var didLoad = false
    @State private var useWebFallback = false

    var body: some View {
        Group {
            if useWebFallback {
                WebContentView(url: ProgramBudgetParityClient.livePageURL, title: "Program Budget")
            } else if let document {
                nativeContent(document)
            } else {
                ProgressView("Loading program budget…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Program Budget")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadIfNeeded() }
        .refreshable {
            guard !useWebFallback else { return }
            await load(force: true)
        }
    }

    private func nativeContent(_ document: ProgramBudgetParityDocument) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                overviewCard(document)
                programCostChart(document)
                ForEach(document.programs) { program in
                    NavigationLink {
                        ProgramBudgetDetailView(program: program, payrollYear: document.payrollYear)
                    } label: {
                        programRow(program)
                    }
                    .buttonStyle(.plain)
                }
                scaleCard(document)
                reconciliationCard(document)
                limitationCard(document)
                methodCard(document)
                sourceCard(document)
            }
            .padding(16)
        }
        .background(RiverheadTheme.Surface.page.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Link(destination: ProgramBudgetParityClient.livePageURL) {
                    Image(systemName: "safari")
                }
                .accessibilityLabel("Open Program Budget on the web")
            }
        }
    }

    private func overviewCard(_ document: ProgramBudgetParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What the Town does, and what it costs")
                .font(.title2.bold())
                .foregroundStyle(RiverheadTheme.textPrimary)

            Text("The 2026 adopted budget regrouped into seven services using New York's own municipal function codes. Benefits are allocated back to the services whose employees earned them, and user fees are shown against the services that collect them.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 10)], spacing: 10) {
                programStat("Cost of services", moneyShortProgram(document.totals.fullCost), "\(document.programs.count) programs")
                programStat("Earned back", moneyShortProgram(document.totals.earned), "\(String(format: "%.0f", recovery(document)))% recovery")
                programStat("Not covered by fees", moneyShortProgram(document.totals.net), "taxes + general revenue")
                programStat("Per resident", moneyProgram(document.perResident.everything), "all in")
                programStat("Per household", moneyProgram(document.perHousehold.everything), "scale, not a tax bill")
            }
        }
        .programParityCard()
    }

    private func programCostChart(_ document: ProgramBudgetParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Full cost by service")
                .font(.headline)

            Text("Department appropriations plus pension, health insurance, payroll taxes, and other allocated benefits.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(document.programs) { program in
                BarMark(
                    x: .value("Full cost", program.fullCost),
                    y: .value("Program", shortProgramName(program.name))
                )
                .foregroundStyle(RiverheadTheme.accent.gradient)
                .annotation(position: .trailing) {
                    Text(moneyShortProgram(program.fullCost))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let number = value.as(Double.self) {
                            Text(moneyShortProgram(number))
                        }
                    }
                }
            }
            .frame(height: 310)
        }
        .programParityCard()
    }

    private func programRow(_ program: ProgramBudgetParityDocument.Program) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(program.name)
                        .font(.headline)
                        .foregroundStyle(RiverheadTheme.textPrimary)
                    Text("NY function \(program.key)000s • \(program.departments.count) departments")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 10)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }

            Text(program.plain)
                .font(.subheadline)
                .foregroundStyle(RiverheadTheme.textSecondary)

            HStack(spacing: 14) {
                compactValue("Full cost", program.fullCost)
                compactValue("Earned", program.earned)
                compactValue("Net", program.net)
            }

            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: min(max(program.recoveryPct / 100, 0), 1))
                    .tint(RiverheadTheme.brandTeal)
                Text("\(String(format: "%.0f", program.recoveryPct))% recovered from service/user revenue • \(moneyProgram(program.netPerResident)) net per resident")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .programParityCard()
    }

    private func scaleCard(_ document: ProgramBudgetParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scale per person and household")
                .font(.headline)

            Text("Riverhead has about \(Int(document.census.population).formatted()) residents in \(Int(document.census.households).formatted()) households. Per-household figures describe the scale of Town government; they are not an individual parcel's property-tax bill.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 7) {
                programKeyValue("Services / resident", moneyProgram(document.perResident.programs))
                programKeyValue("Services / household", moneyProgram(document.perHousehold.programs))
                programKeyValue("Debt service / household", moneyProgram(document.perHousehold.debtService))
                programKeyValue("All in / household", moneyProgram(document.perHousehold.everything))
                programKeyValue("Share of median household income", String(format: "%.1f%%", document.perHousehold.shareOfMedianIncome))
            }
        }
        .programParityCard()
    }

    private func reconciliationCard(_ document: ProgramBudgetParityDocument) -> some View {
        let reconciles = abs(document.reconciliation.variance) < 0.5

        return VStack(alignment: .leading, spacing: 8) {
            Label(
                reconciles ? "Reconciles to the adopted budget" : "Reconciliation variance",
                systemImage: reconciles ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
            )
            .font(.headline)
            .foregroundStyle(reconciles ? .green : .orange)

            Text("Programs + debt service + contingency + interfund transfers = \(moneyProgram(document.reconciliation.computed)), against \(moneyProgram(document.reconciliation.appropriations)) in adopted appropriations.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            programKeyValue("Variance", moneyProgram(document.reconciliation.variance))
        }
        .programParityCard()
    }

    private func limitationCard(_ document: ProgramBudgetParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(document.notCovered.title, systemImage: "exclamationmark.bubble.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text(document.notCovered.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .programParityCard()
    }

    private func methodCard(_ document: ProgramBudgetParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How this was built")
                .font(.headline)

            ForEach(Array(document.method.enumerated()), id: \.element.id) { index, item in
                DisclosureGroup {
                    Text(item.body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 5)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(index + 1)")
                            .font(.caption.monospacedDigit().bold())
                            .foregroundStyle(RiverheadTheme.accent)
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                    }
                }
                if index != document.method.indices.last {
                    Divider().opacity(0.3)
                }
            }
        }
        .programParityCard()
    }

    private func sourceCard(_ document: ProgramBudgetParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Canonical source", systemImage: "checkmark.seal.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(RiverheadTheme.accent)
            Text(document.source.title)
                .font(.caption.weight(.semibold))
            Text(document.source.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Payroll headcount year: \(document.payrollYear) • Contract schema v\(document.schemaVersion)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if !document.diagnostics.unmappedPayrollDepartments.isEmpty {
                Text("Data diagnostic: \(document.diagnostics.unmappedPayrollDepartments.count) payroll departments are not mapped to a program.")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
        .programParityCard()
    }

    private func programStat(_ label: String, _ value: String, _ note: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(RiverheadTheme.textPrimary)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
            Text(note)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .padding(10)
        .background(RiverheadTheme.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func compactValue(_ label: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(moneyShortProgram(value))
                .font(.caption.monospacedDigit().weight(.bold))
                .foregroundStyle(RiverheadTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func programKeyValue(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .monospacedDigit()
                .foregroundStyle(RiverheadTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .font(.caption)
    }

    private func recovery(_ document: ProgramBudgetParityDocument) -> Double {
        guard document.totals.fullCost > 0 else { return 0 }
        return document.totals.earned / document.totals.fullCost * 100
    }

    private func loadIfNeeded() async {
        guard !didLoad else { return }
        await load(force: false)
    }

    private func load(force: Bool) async {
        if isLoading { return }
        if didLoad && !force { return }

        isLoading = true
        do {
            document = try await ProgramBudgetParityClient.load()
            didLoad = true
            useWebFallback = false
        } catch {
            // The web page is the guaranteed parity fallback. This is especially
            // important while the static JSON contract is rolling out.
            useWebFallback = true
        }
        isLoading = false
    }
}

private struct ProgramBudgetDetailView: View {
    let program: ProgramBudgetParityDocument.Program
    let payrollYear: Int

    var body: some View {
        List {
            Section {
                Text(program.plain)
                    .font(.headline)
                Text(program.narrative)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Cost & recovery") {
                programDetailKV("Direct appropriations", moneyProgram(program.direct))
                programDetailKV("Allocated benefits", moneyProgram(program.benefits))
                programDetailKV("Full cost", moneyProgram(program.fullCost))
                programDetailKV("Earned back", moneyProgram(program.earned))
                programDetailKV("Not covered by fees", moneyProgram(program.net))
                programDetailKV("Cost recovery", String(format: "%.1f%%", program.recoveryPct))
                programDetailKV("Net / resident", moneyProgram(program.netPerResident))
                programDetailKV("Net / household", moneyProgram(program.netPerHousehold))
                programDetailKV("Staff", program.staff > 0 ? "\(program.staff) (\(payrollYear) headcount)" : "Contracted / no mapped payroll")
            }

            Section("What it buys") {
                ForEach(Array(program.buys.enumerated()), id: \.offset) { _, item in
                    Label(item, systemImage: "checkmark.circle")
                }
            }

            Section("Biggest departments") {
                ForEach(program.departments.prefix(12)) { department in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(department.name)
                                .font(.subheadline.weight(.semibold))
                            Text("\(department.fund) • function \(department.code)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 10)
                        Text(moneyShortProgram(department.amount))
                            .font(.caption.monospacedDigit().weight(.semibold))
                    }
                }
            }

            if !program.topRevenues.isEmpty {
                Section("Top service revenues") {
                    ForEach(Array(program.topRevenues.enumerated()), id: \.offset) { _, revenue in
                        HStack(alignment: .top) {
                            Text(revenue.name)
                            Spacer(minLength: 10)
                            Text(moneyShortProgram(revenue.amount))
                                .monospacedDigit()
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func programDetailKV(_ label: String, _ value: String) -> some View {
        LabeledContent(label) {
            Text(value)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
    }
}

private extension View {
    func programParityCard() -> some View {
        self
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(RiverheadTheme.border.opacity(0.35), lineWidth: 0.8)
            )
    }
}

private func shortProgramName(_ name: String) -> String {
    switch name {
    case "General Government Support": return "General Gov."
    case "Economic Assistance & Opportunity": return "Economic / Aid"
    case "Home & Community Services": return "Home / Community"
    case "Culture & Recreation": return "Culture / Rec."
    default: return name
    }
}

private func moneyProgram(_ value: Double) -> String {
    value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
}

private func moneyShortProgram(_ value: Double) -> String {
    let sign = value < 0 ? "-" : ""
    let amount = abs(value)
    if amount >= 1_000_000_000 {
        return "\(sign)$\(String(format: "%.1f", amount / 1_000_000_000))B"
    }
    if amount >= 1_000_000 {
        return "\(sign)$\(String(format: amount < 10_000_000 ? "%.2f" : "%.1f", amount / 1_000_000))M"
    }
    if amount >= 10_000 {
        return "\(sign)$\(String(format: "%.0f", amount / 1_000))K"
    }
    return moneyProgram(value)
}
