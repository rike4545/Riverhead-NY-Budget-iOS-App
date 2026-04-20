//
//  RBCapitalProjectsMapView.swift
//  Riverhead NY Budget App
//
//  Capital Projects: Map + List + Detail sheet.
//
//  KEY CHANGE:
//  - If the Town Square project is not in the official capital-project dataset,
//    we still SHOW a "Town Square — (MDA-derived)" item (without mutating the dataset).
//    This keeps the app honest about the source while making the project discoverable.
//
//  Also adds a logical linking hub from the Town Square detail sheet:
//  - BAN + lease impact calculator
//  - Q&E budget math
//  - "Sweetheart deal" audit view
//  - Source-document links (MDA, Q&E docs, Town hub)
//
//  Swift 6 • iOS 17+
//

import SwiftUI
import MapKit

@MainActor
struct RBCapitalProjectsMapView: View {
    @EnvironmentObject private var store: RBCivicToolkitStore

    @State private var search: String = ""
    @State private var statusFilter: StatusFilter = .all
    @State private var selected: RBCivicToolkitStore.CapitalProject?

    @State private var includeMDADerivedTownSquare: Bool = true

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.9173, longitude: -72.6629),
            span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
        )
    )

    var body: some View {
        NavigationStack {
            List {
                overviewSection
                controlsSection
                projectsSection
                mapSection
                missingLocationSection
            }
            .navigationTitle("Capital Projects")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selected) { proj in
                ProjectDetailSheet(project: proj)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.snappy) { focusRiverhead() }
                    } label: {
                        Image(systemName: "scope")
                    }
                    .accessibilityLabel("Focus map on Riverhead")
                }
            }
            .refreshable {
                // Hook for future remote reloads
            }
        }
    }

    // MARK: - Source Truth vs Display List

    private var officialProjects: [RBCivicToolkitStore.CapitalProject] {
        store.capitalProjects
    }

    private var displayProjects: [RBCivicToolkitStore.CapitalProject] {
        var items = officialProjects
        if includeMDADerivedTownSquare, !items.contains(where: isTownSquare(_:)) {
            items.append(Self.townSquareMDADerived)
        }
        return items
    }

    // MARK: - Filtering

    private var filteredProjects: [RBCivicToolkitStore.CapitalProject] {
        var items = displayProjects

        if statusFilter != .all {
            items = items.filter { statusFilter.matches($0.status) }
        }

        let q = search.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            items = items.filter { p in
                p.name.localizedCaseInsensitiveContains(q) ||
                p.fundingSource.localizedCaseInsensitiveContains(q) ||
                (p.category?.localizedCaseInsensitiveContains(q) ?? false) ||
                (p.department?.localizedCaseInsensitiveContains(q) ?? false) ||
                p.status.rawValue.localizedCaseInsensitiveContains(q)
            }
        }

        items.sort { a, b in
            if a.status.rawValue == b.status.rawValue { return a.name < b.name }
            return a.status.rawValue < b.status.rawValue
        }

        return items
    }

    private var mappable: [RBCivicToolkitStore.CapitalProject] { filteredProjects.filter { $0.coordinate != nil } }
    private var unmappable: [RBCivicToolkitStore.CapitalProject] { filteredProjects.filter { $0.coordinate == nil } }

    private var totalBudget: Double {
        filteredProjects.compactMap(\.budget).reduce(0, +)
    }

    private var totalSpent: Double {
        filteredProjects.compactMap(\.spent).reduce(0, +)
    }

    private var debtHeavyCount: Int {
        filteredProjects.filter { fundingRiskLabel(for: $0) == .debtHeavy }.count
    }

    private var grantReadyCount: Int {
        filteredProjects.filter { fundingRiskLabel(for: $0) == .grantReady }.count
    }

    private var categoriesSummary: [(label: String, count: Int)] {
        let grouped = Dictionary(grouping: filteredProjects) { projectCategoryLabel($0) }
        return grouped
            .map { ($0.key, $0.value.count) }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 { return lhs.0 < rhs.0 }
                return lhs.1 > rhs.1
            }
            .prefix(4)
            .map { $0 }
    }

    // MARK: - Sections

    private var overviewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Capital Plan Story")
                    .font(.headline)

                Text("This view works best when read as a funding-stack dashboard: which projects are in the pipeline, which ones look debt-heavy, and where Riverhead should push grants or reimbursement before creating new levy or BAN pressure.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack {
                    overviewMetric("Projects", value: "\(filteredProjects.count)")
                    Spacer()
                    overviewMetric("Budget in view", value: totalBudget > 0 ? totalBudget.currency0 : "—")
                }

                HStack {
                    overviewMetric("Spent tracked", value: totalSpent > 0 ? totalSpent.currency0 : "—")
                    Spacer()
                    overviewMetric("Mappable", value: "\(mappable.count)")
                }

                HStack(spacing: 8) {
                    summaryPill("Grant-ready: \(grantReadyCount)", color: .green)
                    summaryPill("Debt-heavy: \(debtHeavyCount)", color: .orange)
                    summaryPill("Missing location: \(unmappable.count)", color: .secondary)
                }

                if !categoriesSummary.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Where the pipeline is concentrated")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(categoriesSummary, id: \.label) { item in
                            HStack {
                                Text(item.label)
                                    .font(.caption)
                                Spacer()
                                Text("\(item.count)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var controlsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                TextField("Search projects…", text: $search)
                    .textFieldStyle(.roundedBorder)

                Picker("Status", selection: $statusFilter) {
                    ForEach(StatusFilter.allCases) { s in
                        Text(s.label).tag(s)
                    }
                }
                .pickerStyle(.menu)

                Toggle(isOn: $includeMDADerivedTownSquare) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show Town Square (MDA-derived)")
                        Text("If it isn’t in the capital-project dataset, this adds a derived item for discoverability.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text("Official: \(officialProjects.count) • Showing: \(displayProjects.count) • Filtered: \(filteredProjects.count)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if !officialProjects.isEmpty, !officialProjects.contains(where: isTownSquare(_:)) {
                        Text("Town Square not in dataset")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                Text("Planning rule of thumb: if a project is long-lived or mandate-driven, Riverhead should test grants, reimbursement, or outside aid before normalizing it into local debt or levy pressure.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private var mapSection: some View {
        Section("Map") {
            ZStack {
                Map(position: $position) {
                    ForEach(mappable) { p in
                        if let c = p.coordinate {
                            let coord = CLLocationCoordinate2D(latitude: c.lat, longitude: c.lon)
                            Annotation(p.name, coordinate: coord, anchor: .bottom) {
                                Button { selected = p } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: pinSymbol(for: p))
                                            .font(.title2)
                                        Text(shortLabel(for: p))
                                            .font(.caption2.weight(.semibold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(.regularMaterial)
                                            .clipShape(Capsule())
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if mappable.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "map")
                            .font(.title2)
                        Text("No map pins yet")
                            .font(.headline)
                        Text("Add coordinates (lat/lon) to projects to show pins.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 18)
                    }
                    .padding(14)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding()
                }
            }
        }
    }

    private var projectsSection: some View {
        Section("Projects") {
            if filteredProjects.isEmpty {
                Text(displayProjects.isEmpty ? "No projects loaded." : "No matches.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filteredProjects) { p in
                    Button { selected = p } label: {
                        ProjectRow(project: p, isDerivedTownSquare: isDerivedTownSquare(p))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var missingLocationSection: some View {
        if unmappable.isEmpty { return AnyView(EmptyView()) }
        return AnyView(
            Section("Missing location (\(unmappable.count))") {
                ForEach(unmappable) { p in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(p.name).font(.subheadline.weight(.semibold))
                        Text("Status: \(p.status.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text((p.address?.isEmpty == false) ? (p.address ?? "") : "Add address + coordinates to show on map.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        )
    }

    // MARK: - Helpers

    private func focusRiverhead() {
        position = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.9173, longitude: -72.6629),
                span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
            )
        )
    }

    private func pinSymbol(for p: RBCivicToolkitStore.CapitalProject) -> String {
        if isTownSquare(p) { return "building.2.crop.circle.fill" }
        let s = p.fundingSource.lowercased()
        if s.contains("ban") || s.contains("bond") || s.contains("lease") { return "banknote.fill" }
        return "mappin.circle.fill"
    }

    private func shortLabel(for p: RBCivicToolkitStore.CapitalProject) -> String {
        if isTownSquare(p) { return "Town Square" }
        return p.status.rawValue
    }

    private func isTownSquare(_ p: RBCivicToolkitStore.CapitalProject) -> Bool {
        p.name.localizedCaseInsensitiveContains("Town Square")
    }

    private func isDerivedTownSquare(_ p: RBCivicToolkitStore.CapitalProject) -> Bool {
        // Derived item is only added when the official dataset is missing Town Square
        includeMDADerivedTownSquare && !officialProjects.contains(where: isTownSquare(_:)) && isTownSquare(p)
    }

    // MARK: - MDA-derived Town Square item (not persisted)

    private static var townSquareMDADerived: RBCivicToolkitStore.CapitalProject {
        // Values pulled from the MDA pages you shared:
        // - Purchase price: $2,625,000.00 (MDA §3.04(a), page showing "Purchase Price")
        // - O&M: $150,000/year for 10 years (pages referencing Operation & Management Agreement)
        RBCivicToolkitStore.CapitalProject(
            name: "Riverhead Town Square Project",
            status: RBCivicToolkitStore.CapitalStatus.design,
            budget: 2_625_000,
            fundingSource: "MDA purchase terms / BAN / lease structure",
            category: "Downtown Revitalization",
            department: "Town Board / Community Development",
            address: "Main St / East Ave area, Riverhead, NY",
            coordinate: .init(lat: 40.9170, lon: -72.6620),
            notes: """
            App-added summary shown because the official capital-project dataset does not separately list Town Square.
            """
        )
    }
}

// MARK: - Row

private struct ProjectRow: View {
    let project: RBCivicToolkitStore.CapitalProject
    let isDerivedTownSquare: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(project.name)
                    .font(.subheadline.weight(.semibold))

                if isDerivedTownSquare {
                    Text("Derived")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.gray.opacity(0.15)))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 10)

                Text(project.status.rawValue)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(statusTint(project.status).opacity(0.15)))
                    .foregroundStyle(statusTint(project.status))
            }

            HStack(spacing: 8) {
                Text(fundingRiskLabel)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(fundingRiskColor.opacity(0.14)))
                    .foregroundStyle(fundingRiskColor)

                Text(categoryLabel)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.primary.opacity(0.08)))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                if let budget = project.budget {
                    (Text("Budget ") + Text(budget, format: .currency(code: "USD")))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                if let spent = project.spent {
                    (Text("Spent ") + Text(spent, format: .currency(code: "USD")))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            if let dept = project.department, !dept.isEmpty {
                Text(dept)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let cat = project.category, !cat.isEmpty {
                Text(cat)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if !project.fundingSource.isEmpty {
                Text(project.fundingSource)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryLabel: String {
        if let cat = project.category, !cat.isEmpty { return cat }
        return "Uncategorized"
    }

    private var fundingRiskLabel: String {
        let source = project.fundingSource.lowercased()
        if source.contains("grant") || source.contains("wqip") || source.contains("wiia") || source.contains("chips") || source.contains("cfa") || source.contains("dasny") {
            return "Grant-ready"
        }
        if source.contains("ban") || source.contains("bond") || source.contains("lease") {
            return "Debt-heavy"
        }
        if source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Need funding plan"
        }
        return "Needs review"
    }

    private var fundingRiskColor: Color {
        switch fundingRiskLabel {
        case "Grant-ready": return .green
        case "Debt-heavy": return .orange
        case "Need funding plan": return .red
        default: return .secondary
        }
    }

    private func statusTint(_ s: RBCivicToolkitStore.CapitalStatus) -> Color {
        switch s {
        case .planned: return .blue
        case .design: return .purple
        case .bid: return .orange
        case .construction: return .yellow
        case .complete: return .green
        }
    }
}

// MARK: - Detail

private struct ProjectDetailSheet: View {
    let project: RBCivicToolkitStore.CapitalProject
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private var isTownSquare: Bool { project.name.localizedCaseInsensitiveContains("Town Square") }
    private var displayName: String { isTownSquare ? "Riverhead Town Square Project" : project.name }

    var body: some View {
        NavigationStack {
            List {
                Section("Project") {
                    Text(displayName)
                        .font(.title3.weight(.semibold))
                    Text("Status: \(project.status.rawValue)")
                        .foregroundStyle(.secondary)

                    if isTownSquare {
                        Text("App summary based on executed agreements and Town financial reports.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let dept = project.department, !dept.isEmpty {
                        Text("Department: \(dept)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if let cat = project.category, !cat.isEmpty {
                        Text("Category: \(cat)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Money") {
                    if let budget = project.budget {
                        LabeledContent("Budget") { Text(budget, format: .currency(code: "USD")) }
                    }
                    if let spent = project.spent {
                        LabeledContent("Spent") { Text(spent, format: .currency(code: "USD")) }
                    }
                    LabeledContent("Funding posture") { Text(fundingRiskLabel(for: project).rawValue) }
                    if isTownSquare {
                        Text("Funding context: MDA purchase terms, BAN history, lease timing, and possible reserve impact.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else if !project.fundingSource.isEmpty {
                        Text("Funding: \(project.fundingSource)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Funding source is not yet clear in the project record. That makes this a good candidate for a CIP sheet that states grants, useful life, financing path, and operating impact explicitly.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if let addr = project.address, !addr.isEmpty || project.coordinate != nil {
                    Section("Location") {
                        if let addr = project.address, !addr.isEmpty { Text(addr) }
                        if let c = project.coordinate, !isTownSquare {
                            Text("\(c.lat), \(c.lon)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if !isTownSquare,
                   let notes = project.notes,
                   !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section("Notes") { Text(notes) }
                }

                if !project.sources.isEmpty {
                    Section("Sources") {
                        ForEach(project.sources) { src in
                            if let url = URL(string: src.url) {
                                Link(src.title, destination: url)
                            } else {
                                Text(src.title)
                            }
                        }
                    }
                }

                if isTownSquare {
                    Section("Town Square snapshot") {
                        Text("Town Square now has both official executed-MDA terms and a later reported construction-phase scope, so the project should not be read as only a land-acquisition deal.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        LabeledContent("Reported full project cost") {
                            Text(TownSquareCoreTerms.currentReportedProjectCost, format: .currency(code: "USD"))
                        }
                        LabeledContent("Reported program") {
                            Text("Up to \(TownSquareCoreTerms.currentReportedHotelRoomsMax) hotel rooms + \(TownSquareCoreTerms.currentReportedCondoUnits) condos")
                        }
                        LabeledContent("Official MDA program") {
                            Text("Up to \(TownSquareCoreTerms.hotelRoomsMax) hotel rooms + \(TownSquareCoreTerms.condoUnits) condos")
                        }
                        LabeledContent("Purchase price") {
                            Text(TownSquareCoreTerms.purchasePrice, format: .currency(code: "USD"))
                        }
                        LabeledContent("Down payment (5%)") {
                            Text(TownSquareCoreTerms.downPaymentAmount, format: .currency(code: "USD"))
                        }
                        LabeledContent("Listed grant credits") {
                            Text(TownSquareCoreTerms.totalGrantCommitments, format: .currency(code: "USD"))
                        }
                        LabeledContent("O&M obligation") {
                            Text("\(TownSquareCoreTerms.townSquareOMAnnualFee.currency0)/yr x \(TownSquareCoreTerms.townSquareOMTermYears)y")
                        }
                    }

                    Section("Debt timeline") {
                        Text("Audited statements and the 2024 Annual Financial Report update show that Town Square has been financed through BAN activity, not just discussed as a future concept.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Text("2022 audited statements: the Town refunded \(TownSquareCoreTerms.refundedBANsDuring2022.currency0) of BANs for acquisition and improvement of land for the downtown Town Square project.")
                            .font(.subheadline)

                        Text("2024 AFR: one Town Square BAN issued \(TownSquareCoreTerms.townSquareBANIssueDate2021) and maturing \(TownSquareCoreTerms.townSquareBANMaturityDate2025) carried a \(TownSquareCoreTerms.outstandingBANBalance2024.currency0) ending balance after \(TownSquareCoreTerms.principalPaidOnOutstandingBAN2024.currency0) of principal paid in 2024.")
                            .font(.subheadline)

                        Text("2024 AFR: a separate Town Square BAN issued \(TownSquareCoreTerms.retiredTownSquareBANIssueDate2021) and maturing \(TownSquareCoreTerms.retiredTownSquareBANMaturityDate2024) ended 2024 at zero after \(TownSquareCoreTerms.retiredTownSquareBAN2024.currency0) of principal retired.")
                            .font(.subheadline)
                    }

                    Section("Fund balance impact") {
                        Text("If the Town chooses to pay more of Town Square from reserves instead of debt, the General Fund cushion falls immediately.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Text("The policy benchmark used elsewhere in the app is a 15% minimum General Fund reserve. If a Town Square appropriation would reduce projected fund balance below that level, the Town Board should approve that draw by resolution.")
                            .font(.subheadline)

                        Text("That is the core budget question for this project: does the Town fund it with debt service over time, or with an immediate reserve draw that weakens fund balance?")
                            .font(.subheadline)
                    }

                    Section("Town Square analysis") {
                        NavigationLink("BAN + lease impact (calculator)") {
                            TownSquareBANImpactView(accent: .indigo)
                        }
                        NavigationLink("Q&E budget math") {
                            RBTownSquareQEBudgetMathView()
                        }
                        NavigationLink("Sweetheart deal audit") {
                            RBTownSquareSweetheartDealAuditView()
                        }
                    }

                    Section("Source documents") {
                        openButton("Downtown Revitalization Projects (Town hub)", TownSquareCoreTerms.downtownRevitalizationHubURL.absoluteString)
                        openButton("Town Square Q&E Documents (Town PDF)", TownSquareCoreTerms.qeDocumentsURL.absoluteString)
                        openButton("Town Square Q&E Presentation (Town PDF)", TownSquareCoreTerms.qePresentationURL.absoluteString)
                        openButton("Master Developer Agreement (Town PDF)", TownSquareCoreTerms.mdaPublicURL.absoluteString)
                        openButton("Vision Plan (Town PDF)", TownSquareCoreTerms.downtownVisionPlanURL.absoluteString)
                        openButton("Final Pattern Book (Town PDF)", TownSquareCoreTerms.downtownPatternBookURL.absoluteString)
                        openButton("Railroad Avenue TOD Plan (Town PDF)", TownSquareCoreTerms.railroadTODPlanURL.absoluteString)
                        openButton("Railroad Avenue TOD Redevelopment RFQ (Town PDF)", TownSquareCoreTerms.railroadTODRFQURL.absoluteString)
                        openButton("First Mile / Last Mile Pilot Study (Town PDF)", TownSquareCoreTerms.firstMileLastMileStudyURL.absoluteString)
                        openButton("East Main Street Urban Renewal Plan (Town PDF)", TownSquareCoreTerms.eastMainUrbanRenewalPlanURL.absoluteString)
                        openButton("2024 Annual Financial Report Update (Town PDF)", TownSquareCoreTerms.annualFinancialReport2024URL.absoluteString)
                        openButton("Financial Reports (Town hub)", TownSquareCoreTerms.financialReportsURL.absoluteString)
                        openButton("Groundbreaking coverage (News-Review)", TownSquareCoreTerms.groundbreakingArticleURL.absoluteString)
                    }
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func openButton(_ title: String, _ urlString: String) -> some View {
        Button(title) {
            if let url = URL(string: urlString) {
                openURL(url)
            }
        }
    }
}

private enum CapitalFundingRiskLabel: String {
    case grantReady = "Grant-ready"
    case debtHeavy = "Debt-heavy"
    case needFundingPlan = "Need funding plan"
    case needsReview = "Needs review"
}

private func fundingRiskLabel(for project: RBCivicToolkitStore.CapitalProject) -> CapitalFundingRiskLabel {
    let source = project.fundingSource.lowercased()
    if source.contains("grant") || source.contains("wqip") || source.contains("wiia") || source.contains("chips") || source.contains("cfa") || source.contains("dasny") {
        return .grantReady
    }
    if source.contains("ban") || source.contains("bond") || source.contains("lease") {
        return .debtHeavy
    }
    if source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return .needFundingPlan
    }
    return .needsReview
}

private func projectCategoryLabel(_ project: RBCivicToolkitStore.CapitalProject) -> String {
    if let category = project.category, !category.isEmpty { return category }
    if let department = project.department, !department.isEmpty { return department }
    return "Other"
}

private func overviewMetric(_ label: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
        Text(label)
            .font(.caption)
            .foregroundStyle(.secondary)
        Text(value)
            .font(.subheadline.weight(.semibold))
    }
}

private func summaryPill(_ text: String, color: Color) -> some View {
    Text(text)
        .font(.caption2.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color.opacity(0.14))
        .foregroundStyle(color)
        .clipShape(Capsule())
}

private extension Double {
    var currency0: String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.maximumFractionDigits = 0
        nf.minimumFractionDigits = 0
        return nf.string(from: NSNumber(value: self)) ?? "$0"
    }
}

// MARK: - Filters

private enum StatusFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case planned = "Planned"
    case design = "In Design"
    case bid = "Bid"
    case construction = "Construction"
    case complete = "Complete"

    var id: String { rawValue }
    var label: String { rawValue }

    func matches(_ status: RBCivicToolkitStore.CapitalStatus) -> Bool {
        switch self {
        case .all: return true
        case .planned: return status == .planned
        case .design: return status == .design
        case .bid: return status == .bid
        case .construction: return status == .construction
        case .complete: return status == .complete
        }
    }
}
