//
//  CivicImprovementsView.swift
//  Riverhead NY Budget App
//
//  Resident guidance, search, source trail, saved scenarios, scorecard,
//  favorites, budget diff, and action toolkit.
//

import SwiftUI
import PDFKit

private enum CivicDestination: String, Codable, Hashable, CaseIterable {
    case startHere
    case search
    case sourceTrail
    case savedScenarios
    case scorecard
    case pluralityGovernance
    case budgetDiff
    case actionToolkit
    case pdfSearch
    case exportCenter
    case liveRefresh
    case trustPrivacy
    case glossary
    case accessibility
    case performance
    case askAI
    case budgetHub
    case supplementExplorer
    case budget2027Summary
    case budget2027Lab
    case budgetSimulator
    case budgetSignals
    case myTaxes
    case history
    case fundBalance
    case capitalProjects
    case townSquare
    case departmentExplorer
    case accuracyWatchlist
    case civicToolkits

    var title: String {
        switch self {
        case .startHere: return "Start Here"
        case .search: return "Search"
        case .sourceTrail: return "Source Trail"
        case .savedScenarios: return "Saved Scenarios"
        case .scorecard: return "Budget Scorecard"
        case .pluralityGovernance: return "Plurality & Oversight"
        case .budgetDiff: return "What Changed?"
        case .actionToolkit: return "Resident Action Toolkit"
        case .pdfSearch: return "PDF Search"
        case .exportCenter: return "Export & Share"
        case .liveRefresh: return "Data Refresh"
        case .trustPrivacy: return "Trust & Privacy"
        case .glossary: return "Budget Glossary"
        case .accessibility: return "Accessibility Check"
        case .performance: return "Performance"
        case .askAI: return "Ask AI"
        case .budgetHub: return "Budget Hub"
        case .supplementExplorer: return "Supplement Explorer"
        case .budget2027Summary: return "2027 Summary"
        case .budget2027Lab: return "2027 Lab"
        case .budgetSimulator: return "Budget Simulator"
        case .budgetSignals: return "Budget Signals"
        case .myTaxes: return "My Taxes"
        case .history: return "Budget History"
        case .fundBalance: return "Fund Balance"
        case .capitalProjects: return "Capital Projects"
        case .townSquare: return "Town Square"
        case .departmentExplorer: return "Department Explorer"
        case .accuracyWatchlist: return "Accuracy Watchlist"
        case .civicToolkits: return "Civic Toolkits"
        }
    }

    var icon: String {
        switch self {
        case .startHere: return "sparkle.magnifyingglass"
        case .search: return "magnifyingglass"
        case .sourceTrail: return "checkmark.seal"
        case .savedScenarios: return "tray.full"
        case .scorecard: return "gauge.with.dots.needle.67percent"
        case .pluralityGovernance: return "person.3.sequence.fill"
        case .budgetDiff: return "arrow.left.arrow.right"
        case .actionToolkit: return "person.line.dotted.person"
        case .pdfSearch: return "doc.text.magnifyingglass"
        case .exportCenter: return "square.and.arrow.up"
        case .liveRefresh: return "arrow.clockwise.circle"
        case .trustPrivacy: return "hand.raised.square"
        case .glossary: return "text.book.closed"
        case .accessibility: return "accessibility"
        case .performance: return "speedometer"
        case .askAI: return "sparkles"
        case .budgetHub: return "chart.bar.doc.horizontal"
        case .supplementExplorer: return "doc.text.magnifyingglass"
        case .budget2027Summary: return "pencil.and.outline"
        case .budget2027Lab: return "slider.horizontal.below.sun.max.fill"
        case .budgetSimulator: return "function"
        case .budgetSignals: return "waveform.path.ecg"
        case .myTaxes: return "house.and.flag"
        case .history: return "clock.arrow.circlepath"
        case .fundBalance: return "banknote"
        case .capitalProjects: return "map"
        case .townSquare: return "building.2.crop.circle"
        case .departmentExplorer: return "building.columns"
        case .accuracyWatchlist: return "exclamationmark.triangle"
        case .civicToolkits: return "person.2.badge.gearshape"
        }
    }

    var subtitle: String {
        switch self {
        case .startHere: return "Choose a resident goal and get routed to the right workspace."
        case .search: return "Find a topic, document, official source, or tool without guessing where it lives."
        case .sourceTrail: return "Check the source trail before repeating a claim or asking it at a meeting."
        case .savedScenarios: return "Save tax and budget what-ifs so you can compare them later."
        case .scorecard: return "Scan the budget for pressure points, weak spots, and items worth questioning."
        case .pluralityGovernance: return "Understand how representation, competition, and committee structure affect oversight."
        case .budgetDiff: return "See what changed from one budget year to the next."
        case .actionToolkit: return "Turn a concern into calm questions, notes, testimony, or a follow-up request."
        case .pdfSearch: return "Search budget PDFs and official document titles from one place."
        case .exportCenter: return "Share a clean scenario, citation, note, or scorecard without losing context."
        case .liveRefresh: return "See when public data was last checked and what still needs verification."
        case .trustPrivacy: return "Separate official sources, app analysis, AI help, ads, and sponsored links."
        case .glossary: return "Translate budget language into plain English."
        case .accessibility: return "Review whether the app works well with larger text, VoiceOver, and reduced motion."
        case .performance: return "Check loading status, cached data, and startup health."
        case .askAI: return "Ask a budget or civic question in plain language."
        case .budgetHub: return "Open the main budget workspace for resident and expert views."
        case .supplementExplorer: return "Turn 2026 supplement changes into 2027 budget questions."
        case .budget2027Summary: return "Start with the plain-English 2027 budget story."
        case .budget2027Lab: return "Model 2027 choices, tradeoffs, and tax impact."
        case .budgetSimulator: return "Change assumptions and see how the budget moves."
        case .budgetSignals: return "Scan warning signs, fiscal pressure, and policy choices."
        case .myTaxes: return "Estimate how Town budget choices may affect a household bill."
        case .history: return "Look back through budget documents, rates, and prior choices."
        case .fundBalance: return "Understand reserves, targets, one-time money, and fiscal cushion."
        case .capitalProjects: return "Track capital projects, debt, grants, and Town Square exposure."
        case .townSquare: return "Inspect Town Square terms, public costs, private benefits, and review questions."
        case .departmentExplorer: return "Drill into departments, spending pressure, and service tradeoffs."
        case .accuracyWatchlist: return "Track claims that still need source verification."
        case .civicToolkits: return "Use resident workflows for meetings, services, issue tracking, and follow-through."
        }
    }

    var keywords: [String] {
        switch self {
        case .startHere: return ["guide", "onboarding", "resident", "help", "where"]
        case .search: return ["find", "lookup", "tool", "document", "topic"]
        case .sourceTrail: return ["source", "citation", "evidence", "verify", "trust"]
        case .savedScenarios: return ["save", "scenario", "plan", "compare", "bookmark"]
        case .scorecard: return ["score", "risk", "health", "green", "yellow", "red"]
        case .pluralityGovernance: return ["plurality", "one-party", "party", "oversight", "governance", "competition", "representation"]
        case .budgetDiff: return ["changed", "diff", "year", "increase", "decrease"]
        case .actionToolkit: return ["hearing", "meeting", "testimony", "questions", "notes"]
        case .pdfSearch: return ["pdf", "full text", "document", "page", "search"]
        case .exportCenter: return ["export", "share", "pdf", "copy", "scenario"]
        case .liveRefresh: return ["refresh", "updated", "last checked", "live", "documents"]
        case .trustPrivacy: return ["privacy", "trust", "unofficial", "ads", "ai"]
        case .glossary: return ["definition", "term", "appropriation", "levy", "ban"]
        case .accessibility: return ["voiceover", "dynamic type", "reduce motion", "accessibility"]
        case .performance: return ["startup", "load", "cache", "performance", "diagnostics"]
        case .askAI: return ["assistant", "plain english", "explain", "ai"]
        case .budgetHub: return ["budget", "hub", "overview", "expert"]
        case .supplementExplorer: return ["supplement", "2026", "variance", "request", "tentative", "2027"]
        case .budget2027Summary: return ["2027", "executive", "summary", "whiteboard"]
        case .budget2027Lab: return ["2027", "lab", "scenario", "choices"]
        case .budgetSimulator: return ["simulator", "tax", "levy", "assessment"]
        case .budgetSignals: return ["signals", "warning", "risk", "watch"]
        case .myTaxes: return ["tax", "assessment", "homeowner", "bill"]
        case .history: return ["documents", "pdf", "adopted", "tentative", "archive"]
        case .fundBalance: return ["reserve", "fund balance", "unassigned", "policy"]
        case .capitalProjects: return ["capital", "debt", "map", "bond", "ban"]
        case .townSquare: return ["town square", "mda", "developer", "downtown"]
        case .departmentExplorer: return ["department", "expense", "spending", "payroll"]
        case .accuracyWatchlist: return ["accuracy", "watchlist", "verify", "claim"]
        case .civicToolkits: return ["toolkit", "resident", "services", "meeting"]
        }
    }
}

private struct CivicDiscoveryItem: Identifiable, Hashable {
    let destination: CivicDestination
    let isNew: Bool
    let tint: Color

    var id: String { destination.rawValue }
    var title: String { destination.title }
    var subtitle: String { destination.subtitle }
    var icon: String { destination.icon }
    var keywords: [String] { destination.keywords }
}

private enum CivicDiscoveryCatalog {
    static let improvements: [CivicDiscoveryItem] = [
        .init(destination: .startHere, isNew: true, tint: RiverheadTheme.brandSky),
        .init(destination: .search, isNew: true, tint: RiverheadTheme.brandMint),
        .init(destination: .sourceTrail, isNew: true, tint: RiverheadTheme.brandGold),
        .init(destination: .savedScenarios, isNew: true, tint: RiverheadTheme.brandTeal),
        .init(destination: .scorecard, isNew: true, tint: RiverheadTheme.brandCoral),
        .init(destination: .pluralityGovernance, isNew: true, tint: RiverheadTheme.brandNavy),
        .init(destination: .budgetDiff, isNew: true, tint: RiverheadTheme.accent),
        .init(destination: .actionToolkit, isNew: true, tint: RiverheadTheme.brandNavy),
        .init(destination: .pdfSearch, isNew: true, tint: RiverheadTheme.brandSky),
        .init(destination: .exportCenter, isNew: true, tint: RiverheadTheme.brandGold),
        .init(destination: .liveRefresh, isNew: true, tint: RiverheadTheme.brandMint),
        .init(destination: .trustPrivacy, isNew: true, tint: RiverheadTheme.brandCoral),
        .init(destination: .glossary, isNew: true, tint: RiverheadTheme.accent),
        .init(destination: .accessibility, isNew: true, tint: RiverheadTheme.brandTeal),
        .init(destination: .performance, isNew: true, tint: RiverheadTheme.brandNavy)
    ]

    static let tools: [CivicDiscoveryItem] = [
        .init(destination: .askAI, isNew: false, tint: RiverheadTheme.brandSky),
        .init(destination: .budgetHub, isNew: false, tint: RiverheadTheme.accent),
        .init(destination: .supplementExplorer, isNew: true, tint: RiverheadTheme.brandMint),
        .init(destination: .budget2027Summary, isNew: false, tint: RiverheadTheme.brandMint),
        .init(destination: .budget2027Lab, isNew: false, tint: RiverheadTheme.brandTeal),
        .init(destination: .budgetSimulator, isNew: false, tint: RiverheadTheme.brandGold),
        .init(destination: .budgetSignals, isNew: false, tint: RiverheadTheme.brandCoral),
        .init(destination: .myTaxes, isNew: false, tint: RiverheadTheme.brandSky),
        .init(destination: .history, isNew: false, tint: RiverheadTheme.accent),
        .init(destination: .fundBalance, isNew: false, tint: RiverheadTheme.brandMint),
        .init(destination: .capitalProjects, isNew: false, tint: RiverheadTheme.brandTeal),
        .init(destination: .townSquare, isNew: false, tint: RiverheadTheme.brandGold),
        .init(destination: .departmentExplorer, isNew: false, tint: RiverheadTheme.brandNavy),
        .init(destination: .accuracyWatchlist, isNew: false, tint: RiverheadTheme.brandCoral),
        .init(destination: .civicToolkits, isNew: false, tint: RiverheadTheme.accent)
    ]

    static var all: [CivicDiscoveryItem] { improvements + tools }

    static func item(for destination: CivicDestination) -> CivicDiscoveryItem? {
        all.first { $0.destination == destination }
    }
}

private enum CivicPreferences {
    static let favoritesKey = "Riverhead.favoriteDestinations"
    static let recentsKey = "Riverhead.recentDestinations"

    static func decodeDestinations(from raw: String) -> [CivicDestination] {
        raw.split(separator: ",").compactMap { CivicDestination(rawValue: String($0)) }
    }

    static func encodeDestinations(_ destinations: [CivicDestination]) -> String {
        destinations.map(\.rawValue).joined(separator: ",")
    }
}

private struct SavedBudgetScenario: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var assessment: Double
    var levyChangePercent: Double
    var note: String
    var createdAt = Date()

    var annualTownTaxChange: Double {
        (assessment / 1_000) * (22.50 * levyChangePercent / 100)
    }
}

private struct EvidenceItem: Identifiable, Hashable {
    let id = UUID()
    let claim: String
    let status: String
    let source: String
    let citation: String
    let pageHint: String
    let detail: String
    let confidence: String
    let icon: String
    let tint: Color
}

private struct PDFSearchResult: Identifiable, Hashable {
    let id = UUID()
    let documentTitle: String
    let page: Int?
    let excerpt: String
    let url: URL?
}

private struct BudgetGlossaryEntry: Identifiable, Hashable {
    let id = UUID()
    let term: String
    let shortDefinition: String
    let whyItMatters: String
    let example: String
}

private struct ScorecardSignal: Identifiable, Hashable {
    enum Level: String {
        case strong = "Green"
        case watch = "Yellow"
        case risk = "Red"
    }

    let id = UUID()
    let title: String
    let level: Level
    let value: String
    let explanation: String
    let nextStep: String

    var color: Color {
        switch level {
        case .strong: return .green
        case .watch: return .orange
        case .risk: return RiverheadTheme.brandCoral
        }
    }

    var icon: String {
        switch level {
        case .strong: return "checkmark.circle.fill"
        case .watch: return "exclamationmark.circle.fill"
        case .risk: return "xmark.octagon.fill"
        }
    }
}

private struct BudgetChangeItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let from: String
    let to: String
    let impact: String
    let explanation: String
    let tint: Color
}

struct CivicImprovementsHubView: View {
    @AppStorage(CivicPreferences.favoritesKey) private var favoriteRaw = ""
    @AppStorage(CivicPreferences.recentsKey) private var recentRaw = ""
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    private var favorites: [CivicDestination] { CivicPreferences.decodeDestinations(from: favoriteRaw) }
    private var recents: [CivicDestination] { CivicPreferences.decodeDestinations(from: recentRaw) }
    private var isAccessibilityLayout: Bool { dynamicTypeSize.isAccessibilitySize }
    private var adaptiveColumns: [GridItem] {
        [GridItem(.adaptive(minimum: isAccessibilityLayout ? 240 : 156), spacing: 12)]
    }
    private var cardMinimumHeight: CGFloat { isAccessibilityLayout ? 174 : 142 }
    private var heroTextStyle: Color { reduceTransparency ? RiverheadTheme.textPrimary : .white }
    private var heroSecondaryTextStyle: Color { reduceTransparency ? RiverheadTheme.textSecondary : .white.opacity(0.86) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                if !favorites.isEmpty { destinationRail("Favorites", favorites) }
                if !recents.isEmpty { destinationRail("Recently Viewed", recents) }
                section("Resident Workflow", items: CivicDiscoveryCatalog.improvements)
                section("Budget and Oversight Tools", items: CivicDiscoveryCatalog.tools)
            }
            .padding(16)
        }
        .background {
            if reduceTransparency {
                RiverheadTheme.Surface.page.ignoresSafeArea()
            } else {
                RiverheadTheme.backgroundGradient.ignoresSafeArea()
            }
        }
        .navigationTitle("Civic Command Center")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Start with the issue. Leave with a next step.")
                .font(.title2.weight(.bold))
                .foregroundStyle(heroTextStyle)
                .fixedSize(horizontal: false, vertical: true)
            Text("Use the Command Center to move from concern to source trail to meeting-ready questions. It is built for residents who want the facts, the context, and the next action in one place.")
                .font(.subheadline)
                .foregroundStyle(heroSecondaryTextStyle)
                .fixedSize(horizontal: false, vertical: true)
            NavigationLink {
                StartHereView()
            } label: {
                Label("Choose my next step", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(RiverheadTheme.brandGold)
            .simultaneousGesture(TapGesture().onEnded { remember(.startHere) })
            .accessibilityHint("Opens the guided goal picker.")
            .accessibilityInputLabels(["Choose my next step", "Start here", "Goal picker"])
        }
        .padding(18)
        .background(
            reduceTransparency
            ? AnyShapeStyle(RiverheadTheme.Surface.card)
            : AnyShapeStyle(RiverheadTheme.headerGradient),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.white.opacity(0.18)))
        .shadow(color: RiverheadTheme.cardShadow(scheme, elevated: true), radius: 18, x: 0, y: 10)
        .accessibilityElement(children: .contain)
    }

    private func destinationRail(_ title: String, _ destinations: [CivicDestination]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(destinations, id: \.self) { destination in
                        if let item = CivicDiscoveryCatalog.item(for: destination) {
                            NavigationLink {
                                destinationView(destination)
                            } label: {
                                compactCard(item)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded { remember(destination) })
                        }
                    }
                }
            }
        }
    }

    private func section(_ title: String, items: [CivicDiscoveryItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            LazyVGrid(columns: adaptiveColumns, spacing: 12) {
                ForEach(items) { item in
                    NavigationLink {
                        destinationView(item.destination)
                    } label: {
                        improvementCard(item)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded { remember(item.destination) })
                }
            }
        }
    }

    private func improvementCard(_ item: CivicDiscoveryItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: item.icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(item.tint)
                    .accessibilityHidden(true)
                Spacer()
                if item.isNew {
                    if differentiateWithoutColor {
                        Label("New", systemImage: "sparkle")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(item.tint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(item.tint.opacity(0.14), in: Capsule())
                            .accessibilityLabel("New feature")
                    } else {
                        Text("NEW")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(item.tint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(item.tint.opacity(0.14), in: Capsule())
                            .accessibilityLabel("New feature")
                    }
                }
            }
            Text(item.title)
                .font(.headline)
                .foregroundStyle(RiverheadTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(item.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(isAccessibilityLayout ? nil : 3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: cardMinimumHeight, alignment: .topLeading)
        .background(RiverheadTheme.Surface.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(RiverheadTheme.softBorder))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.isNew ? "\(item.title), new" : item.title)
        .accessibilityValue(item.subtitle)
        .accessibilityHint("Opens \(item.title).")
    }

    private func compactCard(_ item: CivicDiscoveryItem) -> some View {
        Label(item.title, systemImage: item.icon)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(RiverheadTheme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(RiverheadTheme.Surface.card, in: Capsule())
            .overlay(Capsule().strokeBorder(RiverheadTheme.softBorder))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(item.title)
            .accessibilityHint("Opens \(item.title).")
    }

    private func remember(_ destination: CivicDestination) {
        var destinations = recents.filter { $0 != destination }
        destinations.insert(destination, at: 0)
        recentRaw = CivicPreferences.encodeDestinations(Array(destinations.prefix(8)))
    }
}

struct StartHereView: View {
    private let paths: [(String, String, String, CivicDestination)] = [
        ("Estimate my tax impact", "Start with the household effect, then trace the budget assumption behind it.", "house.and.flag.fill", .myTaxes),
        ("Check a public claim", "Open the source trail and accuracy watchlist before sharing or repeating it.", "checkmark.seal.fill", .sourceTrail),
        ("Prepare for a meeting", "Build sourced questions, notes, and testimony that are specific enough to answer.", "person.line.dotted.person.fill", .actionToolkit),
        ("Review Town Square", "Separate the contract, public costs, hotel review, parking, and performance questions.", "building.2.crop.circle", .townSquare),
        ("Follow the 2027 budget", "Start with the executive summary, then test scenarios and tradeoffs.", "pencil.and.outline", .budget2027Summary),
        ("Review the 2026 supplement", "Turn line-item changes into 2027 budget questions.", "doc.text.magnifyingglass", .supplementExplorer),
        ("Think about oversight", "See how representation, liaisons, committees, and political competition shape accountability.", "person.3.sequence.fill", .pluralityGovernance),
        ("Find a department or topic", "Search tools, documents, and budget concepts.", "magnifyingglass", .search)
    ]

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What do you need to do next?")
                        .font(.title2.weight(.bold))
                    Text("Pick the resident task in front of you. The app will route you to the right workspace and keep the source trail close.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Goal Picker") {
                ForEach(paths, id: \.0) { path in
                    NavigationLink {
                        destinationView(path.3)
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(path.0).font(.headline)
                                Text(path.1).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: path.2).foregroundStyle(RiverheadTheme.accent)
                        }
                    }
                }
            }

            Section("Suggested First Pass") {
                Label("Start with the question you want answered.", systemImage: "1.circle")
                Label("Open the source trail before relying on a number or claim.", systemImage: "2.circle")
                Label("Save a meeting question or scenario before leaving.", systemImage: "3.circle")
            }
        }
        .navigationTitle("Start Here")
    }
}

struct UniversalSearchView: View {
    @State private var query = ""
    @AppStorage(CivicPreferences.favoritesKey) private var favoriteRaw = ""
    @AppStorage(CivicPreferences.recentsKey) private var recentRaw = ""
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var favorites: [CivicDestination] { CivicPreferences.decodeDestinations(from: favoriteRaw) }
    private var isAccessibilityLayout: Bool { dynamicTypeSize.isAccessibilitySize }
    private var filtered: [CivicDiscoveryItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return CivicDiscoveryCatalog.all }
        return CivicDiscoveryCatalog.all.filter { item in
            ([item.title, item.subtitle] + item.keywords).joined(separator: " ").lowercased().contains(trimmed)
        }
    }

    var body: some View {
        List {
            Section {
                TextField("Search taxes, fund balance, Town Square, sources...", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Search the app")
                    .accessibilityHint("Searches tools, topics, documents, and budget concepts.")
            }

            Section(filtered.isEmpty ? "No Results" : "Results") {
                if filtered.isEmpty {
                    ContentUnavailableView("No matching tool", systemImage: "magnifyingglass", description: Text("Try words like tax, source, 2027, fund balance, salary, Town Square, or meeting."))
                } else {
                    ForEach(filtered) { item in
                        ViewThatFits(in: .horizontal) {
                            searchResultRow(item, vertical: false)
                            searchResultRow(item, vertical: true)
                        }
                    }
                }
            }
        }
        .navigationTitle("Search")
    }

    private func searchResultRow(_ item: CivicDiscoveryItem, vertical: Bool) -> some View {
        Group {
            if vertical || isAccessibilityLayout {
                VStack(alignment: .leading, spacing: 10) {
                    searchNavigationLink(item)
                    favoriteButton(for: item.destination)
                }
            } else {
                HStack(spacing: 12) {
                    searchNavigationLink(item)
                    favoriteButton(for: item.destination)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func searchNavigationLink(_ item: CivicDiscoveryItem) -> some View {
        NavigationLink {
            destinationView(item.destination)
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title).font(.headline)
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } icon: {
                Image(systemName: item.icon)
                    .foregroundStyle(item.tint)
                    .accessibilityHidden(true)
            }
        }
        .simultaneousGesture(TapGesture().onEnded { remember(item.destination) })
        .accessibilityHint("Opens \(item.title).")
    }

    private func favoriteButton(for destination: CivicDestination) -> some View {
        Button {
            toggleFavorite(destination)
        } label: {
            Label(
                favorites.contains(destination) ? "Remove favorite" : "Add favorite",
                systemImage: favorites.contains(destination) ? "star.fill" : "star"
            )
            .labelStyle(.iconOnly)
            .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(favorites.contains(destination) ? "Remove \(destination.title) from favorites" : "Add \(destination.title) to favorites")
        .accessibilityInputLabels([
            favorites.contains(destination) ? "Remove favorite" : "Add favorite",
            destination.title
        ])
    }

    private func toggleFavorite(_ destination: CivicDestination) {
        var destinations = favorites
        if destinations.contains(destination) {
            destinations.removeAll { $0 == destination }
        } else {
            destinations.insert(destination, at: 0)
        }
        favoriteRaw = CivicPreferences.encodeDestinations(destinations)
    }

    private func remember(_ destination: CivicDestination) {
        var destinations = CivicPreferences.decodeDestinations(from: recentRaw).filter { $0 != destination }
        destinations.insert(destination, at: 0)
        recentRaw = CivicPreferences.encodeDestinations(Array(destinations.prefix(8)))
    }
}

struct SourceTrailView: View {
    @Environment(RBBudgetStore.self) private var store
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    private var evidence: [EvidenceItem] {
        let fundBalancePercent = store.appropriations > 0 ? store.estimatedFundBalance / store.appropriations : 0
        return [
            EvidenceItem(
                claim: "2026 General Fund appropriations are shown as \(store.appropriations.formatted(.currency(code: "USD").precision(.fractionLength(0)))).",
                status: "Loaded app value",
                source: "RBBudgetStore current budget context",
                citation: "2026 budget context loaded in app; verify against official 2026 adopted/tentative budget document.",
                pageHint: "Budget summary / General Fund appropriations table",
                detail: "Used by dashboards, AI context, scorecard, and tax/fund-balance explanations.",
                confidence: "High in-app confidence; verify against the adopted budget before formal use.",
                icon: "chart.bar.doc.horizontal",
                tint: RiverheadTheme.accent
            ),
            EvidenceItem(
                claim: "Estimated unassigned General Fund balance is about \(store.estimatedFundBalance.formatted(.currency(code: "USD").precision(.fractionLength(0)))) or \(fundBalancePercent.formatted(.percent.precision(.fractionLength(1)))).",
                status: "Modeled reserve signal",
                source: "Fund-balance policy model and app-loaded assumptions",
                citation: "App fund-balance model; confirm final classification in audited statements and any Town reserve schedule.",
                pageHint: "Fund balance schedule / audited financial statement notes",
                detail: "The app distinguishes this from restricted or assigned fund balance.",
                confidence: "Medium-high; official classification belongs in audited statements and Town schedules.",
                icon: "banknote.fill",
                tint: RiverheadTheme.brandMint
            ),
            EvidenceItem(
                claim: "Reserve resets are treated as one-time capacity, not recurring operating revenue.",
                status: "Policy interpretation",
                source: "App accounting guidance and municipal-finance practice",
                citation: "Municipal budgeting principle used by app; formal policy depends on Town Board and auditor treatment.",
                pageHint: "Budget message, fund-balance policy, audited statement notes",
                detail: "This prevents one-time savings from being mistaken for a structural fix.",
                confidence: "High as a budgeting principle; exact legal/policy treatment needs Town review.",
                icon: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90",
                tint: RiverheadTheme.brandGold
            ),
            EvidenceItem(
                claim: "Budget claims should identify adopted, tentative, modeled, or unofficial status.",
                status: "Trust rule",
                source: "App source hierarchy",
                citation: "Internal app trust standard.",
                pageHint: "Applies across app-generated claims",
                detail: "This is the app's public-facing standard for civic transparency.",
                confidence: "High; applies across all future analysis screens.",
                icon: "checkmark.seal.fill",
                tint: RiverheadTheme.brandSky
            )
        ]
    }

    var body: some View {
        List {
            Section {
                Text("Every serious number should show its trail: what it says, where it came from, and how much confidence residents should place in it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Evidence Trail") {
                ForEach(evidence) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Label(item.claim, systemImage: item.icon)
                            .font(.headline)
                            .foregroundStyle(item.tint)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(item.status).font(.caption.weight(.semibold))
                        Text(item.source).font(.subheadline)
                        LabeledContent("Citation", value: item.citation)
                            .font(.footnote)
                        LabeledContent("Where to check", value: item.pageHint)
                            .font(.footnote)
                        Text(item.detail).font(.footnote).foregroundStyle(.secondary)
                        Text(item.confidence).font(.caption).foregroundStyle(.secondary)
                        ShareLink(item: "\(item.claim)\n\nCitation: \(item.citation)\nWhere to check: \(item.pageHint)\nConfidence: \(item.confidence)") {
                            Label("Share citation", systemImage: "square.and.arrow.up")
                                .font(.caption.weight(.semibold))
                        }
                    }
                    .padding(.vertical, 6)
                    .accessibilityElement(children: .contain)
                }
            }

            Section("Verification Next Steps") {
                NavigationLink("Open Budget History") { HistoricalTabView() }
                NavigationLink("Open Accuracy Watchlist") { BudgetAccuracyWatchlistView() }
            }
        }
        .navigationTitle("Source Trail")
    }
}

struct SavedScenariosView: View {
    @AppStorage("Riverhead.savedBudgetScenarios") private var savedRaw = ""
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var name = "2027 working scenario"
    @State private var assessment = 450_000.0
    @State private var levyChange = 2.0
    @State private var note = ""

    private var scenarios: [SavedBudgetScenario] {
        guard let data = savedRaw.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([SavedBudgetScenario].self, from: data) else { return [] }
        return decoded
    }
    private var isAccessibilityLayout: Bool { dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        List {
            Section("New Scenario") {
                TextField("Name", text: $name)
                    .accessibilityLabel("Scenario name")
                LabeledContent("Assessment", value: assessment.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                Slider(value: $assessment, in: 150_000...1_500_000, step: 25_000)
                    .accessibilityLabel("Assessment")
                    .accessibilityValue(assessment.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                LabeledContent("Levy change", value: levyChange.formatted(.number.precision(.fractionLength(1))) + "%")
                Slider(value: $levyChange, in: -5...10, step: 0.25)
                    .accessibilityLabel("Levy change")
                    .accessibilityValue(levyChange.formatted(.number.precision(.fractionLength(1))) + " percent")
                TextField("Note", text: $note, axis: .vertical)
                    .accessibilityLabel("Scenario note")
                Button("Save Scenario", systemImage: "tray.and.arrow.down.fill") { saveScenario() }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section("Saved") {
                if scenarios.isEmpty {
                    ContentUnavailableView("No saved scenarios", systemImage: "tray", description: Text("Save a tax or budget scenario here, then compare it before meetings."))
                } else {
                    if scenarios.count > 1 {
                        scenarioComparison
                    }
                    ForEach(scenarios) { scenario in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(scenario.name).font(.headline)
                            Text("Assessment: \(scenario.assessment.formatted(.currency(code: "USD").precision(.fractionLength(0))))")
                            Text("Levy change: \(scenario.levyChangePercent.formatted(.number.precision(.fractionLength(2))))%")
                            Text("Illustrative annual Town-tax change: \(scenario.annualTownTaxChange.formatted(.currency(code: "USD").precision(.fractionLength(0))))")
                                .font(.subheadline.weight(.semibold))
                            if !scenario.note.isEmpty { Text(scenario.note).font(.caption).foregroundStyle(.secondary) }
                            ViewThatFits(in: .horizontal) {
                                scenarioActions(for: scenario, vertical: false)
                                scenarioActions(for: scenario, vertical: true)
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 5)
                        .accessibilityElement(children: .contain)
                    }
                    .onDelete(perform: delete)
                }
            }

            Section("Model Deeper") {
                NavigationLink("Open 2027 Lab") { Budget2027LabView() }
                NavigationLink("Open Budget Simulator") { BudgetSimulator2027View() }
            }
        }
        .navigationTitle("Saved Scenarios")
    }

    private var scenarioComparison: some View {
        let sorted = scenarios.sorted { abs($0.annualTownTaxChange) > abs($1.annualTownTaxChange) }
        let highest = sorted.first
        let lowest = sorted.last
        return VStack(alignment: .leading, spacing: 6) {
            Text("Scenario comparison")
                .font(.headline)
            if let highest, let lowest {
                Text("Highest annual change: \(highest.name), \(highest.annualTownTaxChange.formatted(.currency(code: "USD").precision(.fractionLength(0))))")
                Text("Lowest annual change: \(lowest.name), \(lowest.annualTownTaxChange.formatted(.currency(code: "USD").precision(.fractionLength(0))))")
                Text("Spread: \((highest.annualTownTaxChange - lowest.annualTownTaxChange).formatted(.currency(code: "USD").precision(.fractionLength(0))))")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .font(.footnote)
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private func scenarioActions(for scenario: SavedBudgetScenario, vertical: Bool) -> some View {
        Group {
            if vertical || isAccessibilityLayout {
                VStack(alignment: .leading, spacing: 8) {
                    scenarioActionButtons(for: scenario)
                }
            } else {
                HStack {
                    scenarioActionButtons(for: scenario)
                }
            }
        }
    }

    @ViewBuilder
    private func scenarioActionButtons(for scenario: SavedBudgetScenario) -> some View {
        Button("Duplicate") { duplicate(scenario) }
            .buttonStyle(.bordered)
            .accessibilityLabel("Duplicate \(scenario.name)")
        Button("Restore Inputs") { restore(scenario) }
            .buttonStyle(.borderedProminent)
            .tint(RiverheadTheme.accent)
            .accessibilityLabel("Restore \(scenario.name) into the input fields")
        ShareLink(item: shareText(for: scenario)) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.bordered)
        .accessibilityLabel("Share \(scenario.name)")
    }

    private func saveScenario() {
        var updated = scenarios
        updated.insert(SavedBudgetScenario(name: name, assessment: assessment, levyChangePercent: levyChange, note: note), at: 0)
        encode(updated)
        note = ""
    }

    private func delete(at offsets: IndexSet) {
        var updated = scenarios
        updated.remove(atOffsets: offsets)
        encode(updated)
    }

    private func duplicate(_ scenario: SavedBudgetScenario) {
        var copy = scenario
        copy.id = UUID()
        copy.name = "\(scenario.name) copy"
        var updated = scenarios
        updated.insert(copy, at: 0)
        encode(updated)
    }

    private func restore(_ scenario: SavedBudgetScenario) {
        name = scenario.name
        assessment = scenario.assessment
        levyChange = scenario.levyChangePercent
        note = scenario.note
    }

    private func shareText(for scenario: SavedBudgetScenario) -> String {
        """
        \(scenario.name)
        Assessment: \(scenario.assessment.formatted(.currency(code: "USD").precision(.fractionLength(0))))
        Levy change: \(scenario.levyChangePercent.formatted(.number.precision(.fractionLength(2))))%
        Illustrative annual Town-tax change: \(scenario.annualTownTaxChange.formatted(.currency(code: "USD").precision(.fractionLength(0))))
        Note: \(scenario.note.isEmpty ? "None" : scenario.note)
        """
    }

    private func encode(_ scenarios: [SavedBudgetScenario]) {
        guard let data = try? JSONEncoder().encode(scenarios),
              let raw = String(data: data, encoding: .utf8) else { return }
        savedRaw = raw
    }
}

struct BudgetScorecardView: View {
    @Environment(RBBudgetStore.self) private var store
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    private var signals: [ScorecardSignal] {
        let reservePercent = store.appropriations > 0 ? store.estimatedFundBalance / store.appropriations : 0
        return [
            ScorecardSignal(title: "Recurring Balance", level: .watch, value: "Watch", explanation: "The app flags recurring revenue vs. recurring cost discipline as the central budget test.", nextStep: "Ask which 2027 costs are recurring and which fixes are one-time."),
            ScorecardSignal(title: "Fund Balance", level: reservePercent > 0.25 ? .strong : .watch, value: reservePercent.formatted(.percent.precision(.fractionLength(1))), explanation: "The current model shows reserves above the local floor and near the practical operating range.", nextStep: "Ask for a schedule splitting restricted, assigned, and unassigned balance."),
            ScorecardSignal(title: "One-Time Fixes", level: .risk, value: "High scrutiny", explanation: "Fund balance can buy time, but it cannot permanently fund recurring operations.", nextStep: "Ask whether each proposed use is one-time or recurring."),
            ScorecardSignal(title: "Payroll and Contracts", level: .watch, value: "Pressure", explanation: "Salary schedules, overtime, and retroactive settlements can create delayed budget pressure.", nextStep: "Ask for department-level labor impact tables."),
            ScorecardSignal(title: "Debt and Capital Exposure", level: .watch, value: "Project-specific", explanation: "Capital choices and Town Square terms should show debt service, timing, and offsetting revenue clearly.", nextStep: "Ask for debit-or-credit line citations for each fiscal-impact resolution."),
            ScorecardSignal(title: "Public Explainability", level: .strong, value: "Improving", explanation: "The new source trail, search, and action toolkit make the app easier to audit and use.", nextStep: "Use the Source Trail before sharing claims publicly.")
        ]
    }

    var body: some View {
        List {
            Section {
                Text("A civic scorecard is not an audit opinion. It is a quick resident-facing map of what deserves attention first.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Signals") {
                ForEach(signals) { signal in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label(signal.title, systemImage: signal.icon)
                                .font(.headline)
                                .foregroundStyle(signal.color)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            if differentiateWithoutColor {
                                Label(signal.level.rawValue, systemImage: signal.icon)
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(signal.color.opacity(0.14), in: Capsule())
                            } else {
                                Text(signal.level.rawValue)
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(signal.color.opacity(0.14), in: Capsule())
                            }
                        }
                        Text(signal.value).font(.title3.weight(.bold))
                        Text(signal.explanation).font(.footnote).foregroundStyle(.secondary)
                        Text("Next step: \(signal.nextStep)").font(.caption.weight(.semibold))
                    }
                    .padding(.vertical, 6)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(signal.title), \(signal.level.rawValue), \(signal.value). \(signal.explanation) Next step: \(signal.nextStep)")
                }
            }
        }
        .navigationTitle("Budget Scorecard")
    }
}

struct BudgetDiffView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let changes: [BudgetChangeItem] = [
        .init(title: "Budget posture", from: "2025 adopted baseline", to: "2026/2027 planning frame", impact: "More focus on recurring balance", explanation: "The app now separates structural operating pressure from one-time reserve decisions.", tint: RiverheadTheme.accent),
        .init(title: "Fund balance story", from: "Reserve level as a single number", to: "Reserve floor, practical range, and deployable capacity", impact: "Clearer public tradeoff", explanation: "Residents can see why not every dollar of fund balance should be treated as free cash.", tint: RiverheadTheme.brandMint),
        .init(title: "Resident tax view", from: "Town-wide budget totals", to: "Household assessment examples", impact: "Easier personal context", explanation: "The tax tools translate levy/rate changes into annual, monthly, and per-$100K views.", tint: RiverheadTheme.brandSky),
        .init(title: "Verification", from: "Analysis screens", to: "Source trail plus accuracy watchlist", impact: "Higher trust", explanation: "The app now makes it clearer which claims are loaded values, models, or policy interpretations.", tint: RiverheadTheme.brandGold),
        .init(title: "Meeting readiness", from: "Read-only insight", to: "Questions, notes, and testimony workflow", impact: "More useful civic action", explanation: "Residents can move from understanding to asking better public questions.", tint: RiverheadTheme.brandCoral)
    ]

    var body: some View {
        List {
            Section {
                Text("This view is a resident-friendly diff: not just what changed numerically, but what changed in the budget story and what residents should ask next.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Changes to Watch") {
                ForEach(changes) { change in
                    VStack(alignment: .leading, spacing: 8) {
                        Label(change.title, systemImage: "arrow.left.arrow.right.circle.fill")
                            .font(.headline)
                            .foregroundStyle(change.tint)
                        ViewThatFits(in: .horizontal) {
                            fromToView(change, vertical: false)
                            fromToView(change, vertical: true)
                        }
                        Text(change.impact).font(.subheadline.weight(.semibold))
                        Text(change.explanation).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    .accessibilityElement(children: .combine)
                }
            }

            Section("Dig Deeper") {
                NavigationLink("Open Budget Supplement Explorer") { BudgetSupplementExplorerView() }
                NavigationLink("Open Department Expense Explorer") { DepartmentExpenseExplorerView() }
                NavigationLink("Open Rebalanced Spending") { RebalancedSpendingView() }
                NavigationLink("Open Accuracy Watchlist") { BudgetAccuracyWatchlistView() }
            }
        }
        .navigationTitle("What Changed?")
    }

    private func fromToView(_ change: BudgetChangeItem, vertical: Bool) -> some View {
        Group {
            if vertical || dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    fromBlock(change.from)
                    toBlock(change.to)
                }
            } else {
                HStack(alignment: .top) {
                    fromBlock(change.from)
                    Spacer()
                    toBlock(change.to)
                }
            }
        }
    }

    private func fromBlock(_ text: String) -> some View {
        VStack(alignment: .leading) {
            Text("From").font(.caption.weight(.bold)).foregroundStyle(.secondary)
            Text(text).font(.footnote).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func toBlock(_ text: String) -> some View {
        VStack(alignment: .leading) {
            Text("To").font(.caption.weight(.bold)).foregroundStyle(.secondary)
            Text(text).font(.footnote).fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ResidentActionToolkitView: View {
    @AppStorage("Riverhead.residentActionNotes") private var notes = ""
    @State private var selectedTemplate = ""

    private let templates = [
        "Can the Town show which 2027 costs are recurring and which are one-time?",
        "Which fund-balance dollars are restricted, assigned, or unassigned?",
        "What is the household tax impact per $100,000 of assessed value?",
        "Which capital or Town Square items create future debt-service obligations?",
        "What budget line proves this proposal has a debit or credit attached?"
    ]

    var body: some View {
        List {
            Section {
                Text("Turn a concern into a question someone can answer on the record. Start with the source, name the budget line or policy choice, and ask for the document, number, or timeline that would resolve it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Question Templates") {
                ForEach(templates, id: \.self) { template in
                    Button {
                        selectedTemplate = template
                        append(template)
                    } label: {
                        Label(template, systemImage: "quote.bubble")
                    }
                    .accessibilityHint("Adds this question to your meeting notes.")
                }
            }

            Section("My Meeting Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 180)
                    .accessibilityLabel("Meeting notes")
                    .accessibilityHint("Edit your resident meeting notes and questions.")
                Button("Clear Notes", role: .destructive) { notes = "" }
                    .disabled(notes.isEmpty)
            }

            Section("Helpful Screens") {
                NavigationLink("Source Trail") { SourceTrailView() }
                NavigationLink("Budget Scorecard") { BudgetScorecardView() }
                NavigationLink("Ask AI") { AskAIView(initialPrompt: selectedTemplate) }
                NavigationLink("Town Contact Card") { ContactView() }
            }
        }
        .navigationTitle("Action Toolkit")
    }

    private func append(_ template: String) {
        let prefix = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : "\n\n"
        notes += prefix + "Question: " + template
    }
}

struct BudgetPDFSearchView: View {
    @Environment(RBBudgetStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var query = ""

    private var results: [PDFSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        var matches = store.documents.compactMap { doc -> PDFSearchResult? in
            let haystack = "\(doc.title) \(doc.type.rawValue) \(doc.year) \(doc.url.absoluteString)".lowercased()
            guard haystack.contains(trimmed.lowercased()) else { return nil }
            return PDFSearchResult(
                documentTitle: doc.title,
                page: nil,
                excerpt: "Matched official document metadata for \(doc.year). Open the document to verify page-level language.",
                url: doc.url
            )
        }

        let bundled = Bundle.main.urls(forResourcesWithExtension: "pdf", subdirectory: nil) ?? []
        for url in bundled.prefix(24) {
            guard let document = PDFDocument(url: url) else { continue }
            for index in 0..<min(document.pageCount, 20) {
                guard let page = document.page(at: index),
                      let text = page.string,
                      let range = text.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) else { continue }
                let start = text.index(range.lowerBound, offsetBy: -80, limitedBy: text.startIndex) ?? text.startIndex
                let end = text.index(range.upperBound, offsetBy: 120, limitedBy: text.endIndex) ?? text.endIndex
                let excerpt = text[start..<end]
                    .replacingOccurrences(of: "\n", with: " ")
                    .replacingOccurrences(of: "  ", with: " ")
                matches.append(PDFSearchResult(
                    documentTitle: url.deletingPathExtension().lastPathComponent,
                    page: index + 1,
                    excerpt: String(excerpt),
                    url: url
                ))
                break
            }
        }

        return Array(matches.prefix(30))
    }

    var body: some View {
        List {
            Section {
                TextField("Search bundled PDFs and document titles", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Search budget PDFs")
                    .accessibilityHint("Searches bundled PDFs and official document titles.")
                Text("Search checks official document metadata plus the first pages of bundled PDFs. Use results as pointers, then verify in the source document.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section(results.isEmpty ? "Results" : "\(results.count) Results") {
                if query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
                    ContentUnavailableView("Enter at least two characters", systemImage: "doc.text.magnifyingglass")
                } else if results.isEmpty {
                    ContentUnavailableView("No PDF match", systemImage: "doc.text.magnifyingglass", description: Text("Try levy, fund balance, police, Town Square, sewer, debt, or appropriation."))
                } else {
                    ForEach(results) { result in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(result.documentTitle)
                                .font(.headline)
                                .fixedSize(horizontal: false, vertical: true)
                            if let page = result.page {
                                Text("Page \(page)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(RiverheadTheme.accent)
                            }
                            Text(result.excerpt)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            if let url = result.url {
                                ShareLink(item: url) {
                                    Label("Share/open source", systemImage: "square.and.arrow.up")
                                        .font(.caption.weight(.semibold))
                                }
                                .accessibilityLabel("Share or open source for \(result.documentTitle)")
                            }
                        }
                        .padding(.vertical, 5)
                        .accessibilityElement(children: .contain)
                    }
                }
            }
        }
        .navigationTitle("PDF Search")
    }
}

struct ExportCenterView: View {
    @AppStorage("Riverhead.savedBudgetScenarios") private var savedRaw = ""
    @AppStorage("Riverhead.residentActionNotes") private var notes = ""

    private var exportText: String {
        """
        Riverhead NY Budget App Export

        Saved scenarios JSON:
        \(savedRaw.isEmpty ? "No saved scenarios." : savedRaw)

        Resident action notes:
        \(notes.isEmpty ? "No meeting notes." : notes)

        Reminder: This app is unofficial. Verify formal claims against Town documents and staff.
        """
    }

    var body: some View {
        List {
            Section {
                Text("Share app-generated work products as plain text. This keeps exports transparent and easy to paste into email, notes, or meeting prep.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Export") {
                ShareLink(item: exportText) {
                    Label("Share scenarios and notes", systemImage: "square.and.arrow.up")
                }
                ShareLink(item: "Budget scorecard: recurring balance, fund balance, one-time fixes, payroll/contracts, debt/capital, and explainability should be reviewed before public budget decisions.") {
                    Label("Share scorecard summary", systemImage: "gauge.with.dots.needle.67percent")
                }
                ShareLink(item: "Source rule: every app claim should identify whether it is adopted, tentative, modeled, unofficial analysis, or a live official source.") {
                    Label("Share source rule", systemImage: "checkmark.seal")
                }
            }

            Section("Export Next") {
                Text("A future PDF export can use the same text payloads and render them into a formatted resident packet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Export & Share")
    }
}

struct DataRefreshStatusView: View {
    @Environment(RBBudgetStore.self) private var store
    @AppStorage("Riverhead.lastDocumentRefreshCheck") private var lastCheckRaw = ""
    @State private var isChecking = false

    private var lastCheckText: String {
        lastCheckRaw.isEmpty ? "Never checked on this device" : lastCheckRaw
    }

    var body: some View {
        List {
            Section("Status") {
                LabeledContent("Budget documents loaded", value: "\(store.documents.count)")
                LabeledContent("Last refresh check", value: lastCheckText)
                LabeledContent("Refresh mode", value: "Manual official-source review")
            }

            Section {
                Button {
                    Task { await checkNow() }
                } label: {
                    Label(isChecking ? "Checking..." : "Check Now", systemImage: "arrow.clockwise")
                }
                .disabled(isChecking)
            } footer: {
                Text("This first pass records review time and points residents to official documents. A later network monitor can diff document URLs and notify when the Town posts new PDFs.")
            }

            Section("Official Sources") {
                ForEach(store.documents) { doc in
                    ShareLink(item: doc.url) {
                        Label("\(doc.year) \(doc.title)", systemImage: "doc.richtext")
                    }
                }
            }
        }
        .navigationTitle("Data Refresh")
    }

    private func checkNow() async {
        isChecking = true
        try? await Task.sleep(nanoseconds: 350_000_000)
        lastCheckRaw = Date.now.formatted(date: .abbreviated, time: .shortened)
        isChecking = false
    }
}

struct TrustPrivacyView: View {
    var body: some View {
        List {
            Section("Trust Boundaries") {
                Label("Unofficial civic companion, not a Town app.", systemImage: "exclamationmark.triangle")
                Label("Budget claims should show adopted, tentative, modeled, or unofficial status.", systemImage: "checkmark.seal")
                Label("Legal, audit, deadline, and compliance questions should be verified with official sources.", systemImage: "building.columns")
            }

            Section("Privacy") {
                Label("Saved scenarios, favorites, recent tools, and notes stay in local app storage.", systemImage: "iphone")
                Label("OpenAI API keys are stored in Keychain when the user saves one.", systemImage: "key")
                Label("Live AI requests send the prompt and app context to the AI service only when a key is configured.", systemImage: "sparkles")
            }

            Section("Ads & Sponsorships") {
                Text("Sponsored links and ad placements should remain visibly labeled so civic content and monetized links do not blur together.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Trust & Privacy")
    }
}

struct BudgetTermGlossaryView: View {
    @State private var query = ""

    private let terms: [BudgetGlossaryEntry] = [
        .init(term: "Appropriation", shortDefinition: "Permission to spend up to a budgeted amount.", whyItMatters: "It is not the same as actual spending.", example: "A $1M overtime appropriation means the budget allows up to $1M, not that exactly $1M was spent."),
        .init(term: "Tax levy", shortDefinition: "The total amount the Town raises through property taxes.", whyItMatters: "Levy changes drive the overall tax burden before individual assessments and districts are applied.", example: "A 2% levy increase is different from a 2% increase on every individual bill."),
        .init(term: "Fund balance", shortDefinition: "The accumulated resources left in a fund after prior activity.", whyItMatters: "Restricted, assigned, and unassigned dollars cannot always be used the same way.", example: "Unassigned General Fund balance is the most flexible reserve category."),
        .init(term: "Assigned fund balance", shortDefinition: "Money intended for a specific purpose but not externally restricted.", whyItMatters: "It may look available, but public plans or policies may already point it somewhere.", example: "A board may assign money for equipment replacement."),
        .init(term: "Restricted fund balance", shortDefinition: "Money constrained by law, grantor, or external requirement.", whyItMatters: "It usually cannot be moved freely to plug operating gaps.", example: "Certain grant or dedicated-purpose funds may be restricted."),
        .init(term: "BAN", shortDefinition: "Bond anticipation note, a short-term borrowing tool.", whyItMatters: "BANs can bridge capital costs before long-term bonds or repayment.", example: "Town Square cash flow may include BAN activity before final debt structure."),
        .init(term: "Recurring revenue", shortDefinition: "Revenue expected to repeat year after year.", whyItMatters: "Recurring costs should generally be funded by recurring revenue.", example: "Property taxes are recurring; a one-time reserve draw is not."),
        .init(term: "One-time resource", shortDefinition: "Money available once, not every year.", whyItMatters: "Using it for ongoing salaries can create future gaps.", example: "Excess fund balance can buy time but does not permanently pay payroll.")
    ]

    private var filtered: [BudgetGlossaryEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return terms }
        return terms.filter { "\($0.term) \($0.shortDefinition) \($0.whyItMatters)".lowercased().contains(trimmed) }
    }

    var body: some View {
        List {
            Section {
                TextField("Search budget terms", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Search budget glossary")
            }
            Section("Terms") {
                ForEach(filtered) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.term).font(.headline)
                        Text(entry.shortDefinition).font(.subheadline)
                        Text("Why it matters: \(entry.whyItMatters)").font(.footnote).foregroundStyle(.secondary)
                        Text("Example: \(entry.example)").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 5)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(entry.term). \(entry.shortDefinition) Why it matters: \(entry.whyItMatters) Example: \(entry.example)")
                }
            }
        }
        .navigationTitle("Glossary")
    }
}

struct AccessibilityChecklistView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        List {
            Section("Current Settings") {
                LabeledContent("Dynamic Type", value: dynamicTypeSize.isAccessibilitySize ? "Accessibility size" : "Standard size")
                LabeledContent("Reduce Motion", value: reduceMotion ? "On" : "Off")
                LabeledContent("Reduce Transparency", value: reduceTransparency ? "On" : "Off")
            }

            Section("Checklist") {
                Label("Charts need text summaries and VoiceOver labels.", systemImage: "chart.pie")
                Label("Buttons should use labels, not icon-only affordances.", systemImage: "hand.tap")
                Label("Screens should remain usable at accessibility text sizes.", systemImage: "textformat.size")
                Label("Decorative backgrounds should be hidden from VoiceOver.", systemImage: "eye.slash")
            }
        }
        .navigationTitle("Accessibility")
    }
}

struct PerformanceDiagnosticsView: View {
    @Environment(RBBudgetStore.self) private var store

    var body: some View {
        List {
            Section("Startup Health") {
                LabeledContent("Documents loaded", value: "\(store.documents.count)")
                LabeledContent("Fund summaries loaded", value: "\(store.funds.count)")
                LabeledContent("Heavy data warm-up", value: store.funds.isEmpty ? "Still warming or unavailable" : "Ready")
            }

            Section("Performance Plan") {
                Label("Keep launch light; warm CSV/PDF data in the background.", systemImage: "bolt")
                Label("Defer PDF full-text scans until the user searches.", systemImage: "doc.text.magnifyingglass")
                Label("Cache search indexes after first use in a future pass.", systemImage: "externaldrive")
                Label("Prefer lazy grids/lists for dense civic tool menus.", systemImage: "list.bullet")
            }
        }
        .navigationTitle("Performance")
    }
}

@MainActor
@ViewBuilder
private func destinationView(_ destination: CivicDestination) -> some View {
    switch destination {
    case .startHere:
        StartHereView()
    case .search:
        UniversalSearchView()
    case .sourceTrail:
        SourceTrailView()
    case .savedScenarios:
        SavedScenariosView()
    case .scorecard:
        BudgetScorecardView()
    case .pluralityGovernance:
        PluralityGovernanceView()
    case .budgetDiff:
        BudgetDiffView()
    case .actionToolkit:
        ResidentActionToolkitView()
    case .pdfSearch:
        BudgetPDFSearchView()
    case .exportCenter:
        ExportCenterView()
    case .liveRefresh:
        DataRefreshStatusView()
    case .trustPrivacy:
        TrustPrivacyView()
    case .glossary:
        BudgetTermGlossaryView()
    case .accessibility:
        AccessibilityChecklistView()
    case .performance:
        PerformanceDiagnosticsView()
    case .askAI:
        AskAIView()
    case .budgetHub:
        RiverheadBudgetHubView()
    case .supplementExplorer:
        BudgetSupplementExplorerView()
    case .budget2027Summary:
        Budget2027ExecutiveWhiteboardView()
    case .budget2027Lab:
        Budget2027LabView()
    case .budgetSimulator:
        BudgetSimulator2027View()
    case .budgetSignals:
        BudgetSignalsView()
    case .myTaxes:
        MyTaxesView()
    case .history:
        HistoricalTabView()
    case .fundBalance:
        FundBalanceShiftView()
    case .capitalProjects:
        RBCapitalProjectsMapView()
    case .townSquare:
        RBTownSquareHubView()
    case .departmentExplorer:
        DepartmentExpenseExplorerView()
    case .accuracyWatchlist:
        BudgetAccuracyWatchlistView()
    case .civicToolkits:
        CivicToolkitsHubView()
    }
}

#Preview {
    NavigationStack {
        CivicImprovementsHubView()
            .environment(RBBudgetStore())
            .environmentObject(RBCivicToolkitStore())
            .environmentObject(RBSixSigmaStore())
    }
}
