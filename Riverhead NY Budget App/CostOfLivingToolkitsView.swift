//
//  CostOfLivingToolkitsView.swift
//  Riverhead NY Budget App
//
//  FIX + IMPROVEMENT:
//  - Resolves missing BroadbandToolkitView/logStore/showAddLog by providing a complete, self-contained broadband toolkit.
//  - Reframes "Broadband issue" around the Optimum franchise agreement and enabling more competitors (e.g., Verizon),
//    while still supporting resident-facing service/outage logs and a bill calculator.
//  - Persistence is local JSON in Application Support (safe/offline).
//
//  Swift 6 • iOS 17+
//

import SwiftUI
import Combine

@MainActor
public struct CostOfLivingToolkitsView: View {

    enum Tab: String, CaseIterable, Identifiable {
        case energy = "Energy"
        case broadband = "Broadband & Competition"
        var id: String { rawValue }
    }

    @State private var tab: Tab = .energy

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Picker("Toolkit", selection: $tab) {
                ForEach(Tab.allCases) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Group {
                switch tab {
                case .energy:
                    EnergyToolkitView()
                case .broadband:
                    BroadbandToolkitView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Cost‑of‑Living")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Energy Toolkit (lightweight checklist)

private struct EnergyToolkitView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Energy checklist")
                            .font(.headline)

                        ChecklistRow("Audit big loads", "HVAC, electric water heaters, pool pumps, space heaters.")
                        ChecklistRow("Time shifting", "Run heavy loads off‑peak if your plan supports it.")
                        ChecklistRow("Weatherization", "Seals, insulation, attic hatches, door sweeps.")
                        ChecklistRow("Appliances", "Replace worst offenders first, not everything.")
                        ChecklistRow("Bill sanity check", "Look for supply vs delivery changes and one‑time fees.")
                    }
                    .padding(.vertical, 2)
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Municipal levers (examples)")
                            .font(.headline)
                        Bullet("Energy performance contracts (EPC) for public buildings.")
                        Bullet("Competitive supply procurement / aggregation (where applicable).")
                        Bullet("Streetlight conversions & smart controls.")
                        Bullet("Solar + storage for critical sites (shelters, pump stations).")
                    }
                    .padding(.vertical, 2)
                }

                Text("Note: This section is a planning aid. Confirm programs, tariffs, and eligibility with official sources.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 2)

                Spacer(minLength: 16)
            }
            .padding()
        }
    }
}

// MARK: - Broadband Toolkit (competition policy + service log + bill calc)

private struct BroadbandToolkitView: View {

    @StateObject private var logStore = BroadbandLogStore()

    // Bill calculator inputs
    @State private var basePrice: String = ""
    @State private var equipmentFees: String = ""
    @State private var taxesFees: String = ""

    // Log UI
    @State private var showAddLog: Bool = false
    @State private var filterScope: BroadbandScopeFilter = .policyAndService
    @State private var filterStatus: BroadbandStatusFilter = .open
    @State private var query: String = ""

    private var monthlyTotal: Double {
        (Double(basePrice) ?? 0) + (Double(equipmentFees) ?? 0) + (Double(taxesFees) ?? 0)
    }

    var body: some View {
        List {

            // POLICY-FIRST framing
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Broadband & Competition")
                        .font(.title3.weight(.semibold))

                    Text("Track the Optimum franchise conversation and the practical steps that enable more competitors (for example, Verizon), while still logging resident‑level service problems.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            // Filters
            Section {
                TextField("Search (provider, neighborhood, notes)…", text: $query)
                    .textFieldStyle(.roundedBorder)

                Picker("Scope", selection: $filterScope) {
                    ForEach(BroadbandScopeFilter.allCases) { f in
                        Text(f.label).tag(f)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Status", selection: $filterStatus) {
                    ForEach(BroadbandStatusFilter.allCases) { f in
                        Text(f.label).tag(f)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("\(filtered.count) item(s)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        showAddLog = true
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                }
            }

            // Log list
            Section("Items") {
                if filtered.isEmpty {
                    ContentUnavailableView(
                        "No matches",
                        systemImage: "wifi",
                        description: Text(logStore.entries.isEmpty ? "Add a policy item (franchise/competition) or a service log." : "Try different filters or search text.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filtered) { entry in
                        BroadbandLogRow(entry: entry) {
                            logStore.toggleResolved(entry.id)
                        }
                    }
                    .onDelete { idx in
                        let ids = idx.map { filtered[$0].id }
                        logStore.delete(ids: ids)
                    }
                }
            }

            // Franchise levers (policy checklist)
            Section("Franchise & competition levers (plain language)") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("If Riverhead is reviewing or renegotiating an Optimum franchise agreement, these are the knobs that usually matter when the goal is more competition and better service.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    FactRow("Non‑exclusivity", "Confirm the agreement is non‑exclusive and does not create barriers for other providers to serve residents.")
                    FactRow("Rights‑of‑way & permitting", "Speed and predictability of ROW permits often determines whether competitors expand. Track timelines, bottlenecks, and standard conditions.")
                    FactRow("Pole attachments", "Pole access, make‑ready timelines, and cost transparency can enable/limit fiber buildout. Track utilities coordination and delays.")
                    FactRow("Buildout expectations", "If the Town wants broader coverage or upgrades, define measurable buildout milestones and reporting.")
                    FactRow("Performance reporting", "Require periodic reporting of outages, restoration times, customer complaints, and speeds (where feasible) — and publish a dashboard.")
                    FactRow("Consumer protection", "Clear escalation path for residents, billing dispute standards, and service credits during prolonged outages.")
                    FactRow("Enforcement & remedies", "Define consequences for non‑compliance (fees, cure periods, reporting requirements, audits).")
                    FactRow("Public interest commitments", "Public building connectivity, PEG/community channels, or technology grants — ensure deliverables are measurable and tracked.")
                }
                .padding(.vertical, 4)
            }

            // Bill calculator
            Section("Monthly bill calculator") {
                VStack(alignment: .leading, spacing: 10) {
                    AmountField(label: "Base price", placeholder: "e.g., 80", text: $basePrice)
                    AmountField(label: "Equipment fees", placeholder: "e.g., 15", text: $equipmentFees)
                    AmountField(label: "Taxes & other fees", placeholder: "e.g., 12", text: $taxesFees)

                    Divider()

                    HStack {
                        Text("Estimated monthly total")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(monthlyTotal, format: .currency(code: "USD"))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }

                    HStack {
                        Button("Reset") {
                            basePrice = ""
                            equipmentFees = ""
                            taxesFees = ""
                        }
                        .buttonStyle(.borderless)

                        Spacer()

                        Button {
                            // quick action: log this bill as a policy/service note
                            let note = "Estimated bill: " + (NumberFormatter.currency0.string(from: monthlyTotal as NSNumber) ?? String(format: "%.0f", monthlyTotal))
                            let entry = BroadbandLogEntry(
                                scope: .service,
                                topic: .pricing,
                                provider: "Optimum (or other)",
                                neighborhood: "",
                                notes: note,
                                link: nil,
                                resolved: false,
                                measuredDownMbps: nil,
                                measuredUpMbps: nil,
                                date: .now
                            )
                            logStore.add(entry)
                        } label: {
                            Label("Log this bill", systemImage: "plus")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.vertical, 4)
            }

            // Safety / disclaimers
            Section {
                Text("Disclaimer: This toolkit is an informational organizer. It is not legal advice. Always confirm the current franchise terms, state rules, and ROW/pole processes with official sources and counsel.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showAddLog) {
            AddBroadbandItemSheet { entry in
                logStore.add(entry)
            } addOptimumTemplate: {
                logStore.add(BroadbandLogEntry.templateOptimumCompetitionDiscussion())
            }
        }
    }

    private var filtered: [BroadbandLogEntry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return logStore.entries
            .filter { entry in
                // Scope filter
                guard filterScope.accepts(entry.scope) else { return false }
                // Status filter
                guard filterStatus.accepts(entry.resolved) else { return false }

                if q.isEmpty { return true }
                return entry.provider.lowercased().contains(q)
                    || entry.neighborhood.lowercased().contains(q)
                    || entry.notes.lowercased().contains(q)
                    || entry.topic.rawValue.lowercased().contains(q)
            }
            .sorted { a, b in
                // Open first, newest first
                if a.resolved != b.resolved { return a.resolved == false }
                return a.date > b.date
            }
    }
}

// MARK: - Models

private enum BroadbandScope: String, Codable, CaseIterable, Identifiable {
    case policy = "Policy"
    case service = "Service"
    var id: String { rawValue }
}

private enum BroadbandTopic: String, Codable, CaseIterable, Identifiable {
    // Policy topics
    case franchiseAgreement = "Franchise agreement"
    case competitionAccess = "Competition / competitor access"
    case rightOfWayPermitting = "ROW permitting"
    case poleAttachments = "Pole attachments"
    case buildout = "Buildout expectations"
    case reporting = "Reporting & transparency"

    // Service topics
    case speedReliability = "Speed / reliability"
    case outage = "Outage"
    case pricing = "Pricing / billing"
    case other = "Other"

    var id: String { rawValue }

    var defaultScope: BroadbandScope {
        switch self {
        case .franchiseAgreement, .competitionAccess, .rightOfWayPermitting, .poleAttachments, .buildout, .reporting:
            return .policy
        case .speedReliability, .outage, .pricing, .other:
            return .service
        }
    }
}

private struct BroadbandLogEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var scope: BroadbandScope
    var topic: BroadbandTopic

    var provider: String
    var neighborhood: String
    var notes: String
    var link: String?

    var resolved: Bool

    // Optional measured data (resident logs)
    var measuredDownMbps: Double?
    var measuredUpMbps: Double?

    var date: Date

    static func templateOptimumCompetitionDiscussion() -> BroadbandLogEntry {
        BroadbandLogEntry(
            scope: .policy,
            topic: .competitionAccess,
            provider: "Optimum (franchise)",
            neighborhood: "Town-wide",
            notes: [
                "Policy question: How can Riverhead structure ROW access, permitting, and reporting so more competitors (e.g., Verizon) can expand service?",
                "",
                "Notes to capture:",
                "• What is the current franchise term and renewal timeline?",
                "• Is the agreement explicitly non‑exclusive? Any practical barriers?",
                "• Average ROW permit time; common reasons for delays.",
                "• Pole attachment / make‑ready delays (utility coordination).",
                "• Buildout expectations and public reporting (outages, complaints, speeds).",
                "• Resident complaint escalation path + enforcement mechanisms."
            ].joined(separator: "\n"),
            link: nil,
            resolved: false,
            measuredDownMbps: nil,
            measuredUpMbps: nil,
            date: .now
        )
    }
}

// MARK: - Store

@MainActor
private final class BroadbandLogStore: ObservableObject {
    @Published private(set) var entries: [BroadbandLogEntry] = []

    private var saveTask: Task<Void, Never>?
    private var cancellable: AnyCancellable?

    init() {
        cancellable = objectWillChange.sink { [weak self] _ in
            self?.scheduleSave()
        }
        load()
        if entries.isEmpty {
            // Seed a policy starter so the screen isn't blank on first run.
            entries = [BroadbandLogEntry.templateOptimumCompetitionDiscussion()]
        }
    }

    func add(_ entry: BroadbandLogEntry) {
        entries.insert(entry, at: 0)
        scheduleSave()
    }

    func toggleResolved(_ id: UUID) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].resolved.toggle()
        scheduleSave()
    }

    func delete(ids: [UUID]) {
        guard !ids.isEmpty else { return }
        entries.removeAll { ids.contains($0.id) }
        scheduleSave()
    }

    func clear() {
        entries.removeAll()
        scheduleSave()
    }

    // MARK: Persistence

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            saveNow()
        }
    }

    private func storeURL() -> URL {
        let dir = RBAppDirectories.applicationSupportDirectory(appFolder: "RiverheadNYBudgetApp")
        return dir.appendingPathComponent("broadband_log_v2.json")
    }

    private func load() {
        let url = storeURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder.rb.decode([BroadbandLogEntry].self, from: data)
            self.entries = decoded
        } catch {
            // ignore corrupt cache
        }
    }

    private func saveNow() {
        let url = storeURL()
        do {
            let data = try JSONEncoder.rb.encode(entries)
            try data.write(to: url, options: [.atomic])
        } catch {
            // ignore; app should still run
        }
    }
}

private extension JSONEncoder {
    static var rb: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }
}

private extension JSONDecoder {
    static var rb: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}

private extension NumberFormatter {
    static let currency0: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.maximumFractionDigits = 0
        return nf
    }()
}

// MARK: - Filters

private enum BroadbandScopeFilter: String, CaseIterable, Identifiable {
    case policyAndService = "All"
    case policy = "Policy"
    case service = "Service"

    var id: String { rawValue }
    var label: String { rawValue }

    func accepts(_ scope: BroadbandScope) -> Bool {
        switch self {
        case .policyAndService: return true
        case .policy: return scope == .policy
        case .service: return scope == .service
        }
    }
}

private enum BroadbandStatusFilter: String, CaseIterable, Identifiable {
    case open = "Open"
    case resolved = "Resolved"
    case all = "All"

    var id: String { rawValue }
    var label: String { rawValue }

    func accepts(_ isResolved: Bool) -> Bool {
        switch self {
        case .open: return !isResolved
        case .resolved: return isResolved
        case .all: return true
        }
    }
}

// MARK: - Add Sheet

private struct AddBroadbandItemSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onAdd: (BroadbandLogEntry) -> Void
    let addOptimumTemplate: () -> Void

    @State private var scope: BroadbandScope = .policy
    @State private var topic: BroadbandTopic = .competitionAccess

    @State private var provider: String = "Optimum"
    @State private var neighborhood: String = ""
    @State private var notes: String = ""

    @State private var link: String = ""
    @State private var resolved: Bool = false

    @State private var down: String = ""
    @State private var up: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        addOptimumTemplate()
                        dismiss()
                    } label: {
                        Label("Add Optimum franchise + competition template", systemImage: "doc.badge.plus")
                    }
                }

                Section("Scope & topic") {
                    Picker("Scope", selection: $scope) {
                        ForEach(BroadbandScope.allCases) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }

                    Picker("Topic", selection: $topic) {
                        ForEach(BroadbandTopic.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .onChange(of: topic) { _, newValue in
                        // Auto-align scope with topic unless user already set a different scope intentionally.
                        scope = newValue.defaultScope
                    }
                }

                Section("Details") {
                    TextField("Provider / Counterparty", text: $provider)
                    TextField("Neighborhood / Hamlet", text: $neighborhood)
                    TextField("Link (optional)", text: $link)

                    Toggle("Resolved", isOn: $resolved)

                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                        .overlay(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Notes… (meeting dates, key points, requests, evidence)")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }
                        }
                }

                Section("Measured speeds (optional)") {
                    TextField("Down Mbps", text: $down).keyboardType(.decimalPad)
                    TextField("Up Mbps", text: $up).keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { add() }
                        .disabled(provider.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func add() {
        let entry = BroadbandLogEntry(
            scope: scope,
            topic: topic,
            provider: provider.trimmingCharacters(in: .whitespacesAndNewlines),
            neighborhood: neighborhood.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            link: link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : link.trimmingCharacters(in: .whitespacesAndNewlines),
            resolved: resolved,
            measuredDownMbps: Double(down),
            measuredUpMbps: Double(up),
            date: .now
        )
        onAdd(entry)
        dismiss()
    }
}

// MARK: - Row

private struct BroadbandLogRow: View {
    let entry: BroadbandLogEntry
    let toggleResolved: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.topic.rawValue)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 10)
                Text(entry.scope.rawValue)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(entry.scope == .policy ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15)))
                    .foregroundStyle(entry.scope == .policy ? .blue : .orange)
            }

            HStack(spacing: 8) {
                Text(entry.provider)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !entry.neighborhood.isEmpty {
                    Text("• \(entry.neighborhood)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(entry.date, format: .dateTime.year().month().day())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }

            if entry.measuredDownMbps != nil || entry.measuredUpMbps != nil {
                HStack(spacing: 12) {
                    if let d = entry.measuredDownMbps {
                        Text("Down \(d, specifier: "%.0f") Mbps")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if let u = entry.measuredUpMbps {
                        Text("Up \(u, specifier: "%.0f") Mbps")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }

            HStack {
                Text(entry.resolved ? "Resolved" : "Open")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(entry.resolved ? Color.green.opacity(0.18) : Color.gray.opacity(0.14)))
                    .foregroundStyle(entry.resolved ? .green : .secondary)

                Spacer()

                Button(entry.resolved ? "Mark open" : "Mark resolved") {
                    toggleResolved()
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Small UI Helpers

private struct ChecklistRow: View {
    let title: String
    let detail: String
    @State private var done: Bool = false

    init(_ title: String, _ detail: String) {
        self.title = title
        self.detail = detail
    }

    var body: some View {
        Button {
            done.toggle()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(done ? .green : .secondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold))
                    Text(detail).font(.footnote).foregroundStyle(.secondary)
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct Bullet: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}

private struct FactRow: View {
    let title: String
    let bodyText: String
    init(_ title: String, _ bodyText: String) {
        self.title = title
        self.bodyText = bodyText
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline.weight(.semibold))
            Text(bodyText).font(.footnote).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct AmountField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField(placeholder, text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .frame(width: 130)
        }
        .font(.callout)
    }
}

#Preview {
    NavigationStack {
        CostOfLivingToolkitsView()
    }
}
