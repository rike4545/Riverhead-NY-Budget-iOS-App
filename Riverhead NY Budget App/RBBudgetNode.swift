//
//  RBBudgetNode.swift
//  Riverhead NY Budget App
//
//  Budget Explorer JSON model + local cache store.
//  Fixes mismatch between older view/store variants by:
//  - Providing resilient Codable decoding (missing children/amountsByYear => defaults)
//  - Standardizing on: name, kind, amountsByYear, children
//  - Optional fields: subtitle, notes
//
//  Swift 6 • iOS 17+
//

import Foundation
import UniformTypeIdentifiers

public struct RBBudgetNode: Identifiable, Codable, Hashable {
    public enum Kind: String, Codable, CaseIterable, Identifiable {
        case fund
        case department
        case program
        case object
        case lineItem

        public var id: String { rawValue }

        public var displayName: String {
            switch self {
            case .fund: return "Fund"
            case .department: return "Department"
            case .program: return "Program"
            case .object: return "Object"
            case .lineItem: return "Line Item"
            }
        }
    }

    public var id: UUID
    public var name: String
    public var kind: Kind

    public var subtitle: String?
    public var notes: String?

    public var amountsByYear: [Int: Double]
    public var children: [RBBudgetNode]

    public init(
        id: UUID = UUID(),
        name: String,
        kind: Kind,
        subtitle: String? = nil,
        notes: String? = nil,
        amountsByYear: [Int: Double] = [:],
        children: [RBBudgetNode] = []
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.subtitle = subtitle
        self.notes = notes
        self.amountsByYear = amountsByYear
        self.children = children
    }

    // Resilient decoding (accepts missing keys for amounts/children)
    private enum CodingKeys: String, CodingKey {
        case id, name, kind, subtitle, notes, amountsByYear, children
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try c.decode(String.self, forKey: .name)
        self.kind = try c.decode(Kind.self, forKey: .kind)
        self.subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
        self.notes = try c.decodeIfPresent(String.self, forKey: .notes)

        // Decode dictionary [String:Double] or [Int:Double] safely
        if let asInt = try? c.decodeIfPresent([Int: Double].self, forKey: .amountsByYear) {
            self.amountsByYear = asInt
        } else if let asString = try? c.decodeIfPresent([String: Double].self, forKey: .amountsByYear) {
            let mapped = asString.compactMap { (k, v) -> (Int, Double)? in
                guard let i = Int(k) else { return nil }
                return (i, v)
            }
            self.amountsByYear = Dictionary(uniqueKeysWithValues: mapped)
        } else {
            self.amountsByYear = [:]
        }

        self.children = try c.decodeIfPresent([RBBudgetNode].self, forKey: .children) ?? []
    }
}

// Convenience computed properties (helps older view code stay readable)
public extension RBBudgetNode {
    var title: String { name }
    var subtitleText: String? { subtitle ?? kind.displayName }

    var allYears: Set<Int> {
        var out = Set(amountsByYear.keys)
        for c in children { out.formUnion(c.allYears) }
        return out
    }
}

// MARK: - Store

@MainActor
public final class RBBudgetExplorerStore: ObservableObject {

    public enum Source: String, CaseIterable, Identifiable {
        case none
        case imported
        case cached

        public var id: String { rawValue }

        public var label: String {
            switch self {
            case .none: return "None"
            case .imported: return "Imported"
            case .cached: return "Cached"
            }
        }

        public var systemImage: String {
            switch self {
            case .none: return "questionmark.circle"
            case .imported: return "square.and.arrow.down"
            case .cached: return "internaldrive"
            }
        }
    }

    @Published public private(set) var nodes: [RBBudgetNode] = []
    @Published public private(set) var source: Source = .none
    @Published public private(set) var lastLoadedAt: Date?
    @Published public var errorMessage: String?

    @Published public var isLoading: Bool = false

    private let cacheURL: URL = {
        let dir = RBAppDirectories.cachesDirectory()
        return dir.appendingPathComponent("rb_budget_explorer_cache.json")
    }()

    public init() {
        loadFromCacheIfPresent()
    }

    // MARK: - Import / Cache

    public func loadFromCacheIfPresent() {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else { return }
        do {
            let data = try Data(contentsOf: cacheURL)
            let decoded = try JSONDecoder.rb.decode([RBBudgetNode].self, from: data)
            self.nodes = decoded
            self.source = .cached
            self.lastLoadedAt = Date()
        } catch {
            // If cache is corrupt, clear it silently.
            try? FileManager.default.removeItem(at: cacheURL)
        }
    }

    public func importFromFile(url: URL) async {
        isLoading = true
        defer { isLoading = false }

        var didStart = false
        if url.startAccessingSecurityScopedResource() {
            didStart = true
        }
        defer { if didStart { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder.rb.decode([RBBudgetNode].self, from: data)
            self.nodes = decoded
            self.source = .imported
            self.lastLoadedAt = Date()
            self.errorMessage = nil

            try data.write(to: cacheURL, options: [.atomic])
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    public func importFromFile(_ url: URL) async {
        await importFromFile(url: url)
    }

    public func clearDataset() {
        nodes = []
        source = .none
        lastLoadedAt = nil
        errorMessage = nil
        try? FileManager.default.removeItem(at: cacheURL)
    }

    // MARK: - Years

    public var availableYears: [Int] {
        var years = Set<Int>()
        for n in nodes { years.formUnion(n.allYears) }
        return years.sorted()
    }

    // MARK: - Search (tree-preserving)

    public func search(query: String) -> [RBBudgetNode] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return nodes }

        return nodes.compactMap { filterTree($0, query: q) }
    }

    private func filterTree(_ node: RBBudgetNode, query: String) -> RBBudgetNode? {
        let hit =
            node.name.localizedCaseInsensitiveContains(query) ||
            (node.subtitle?.localizedCaseInsensitiveContains(query) ?? false) ||
            node.kind.displayName.localizedCaseInsensitiveContains(query) ||
            (node.notes?.localizedCaseInsensitiveContains(query) ?? false)

        let filteredChildren = node.children.compactMap { filterTree($0, query: query) }

        if hit || !filteredChildren.isEmpty {
            return RBBudgetNode(
                id: node.id,
                name: node.name,
                kind: node.kind,
                subtitle: node.subtitle,
                notes: node.notes,
                amountsByYear: node.amountsByYear,
                children: filteredChildren
            )
        }
        return nil
    }

    // MARK: - Template + Export

    public func templateJSONURL() throws -> URL {
        let template: [RBBudgetNode] = [
            RBBudgetNode(
                name: "General Fund",
                kind: .fund,
                subtitle: "Example",
                notes: "Replace this template with official budget tree data.",
                amountsByYear: [2025: 1000000, 2026: 1100000],
                children: [
                    RBBudgetNode(
                        name: "Police Department",
                        kind: .department,
                        amountsByYear: [2025: 300000, 2026: 340000],
                        children: [
                            RBBudgetNode(
                                name: "Salaries",
                                kind: .object,
                                amountsByYear: [2025: 200000, 2026: 220000]
                            ),
                            RBBudgetNode(
                                name: "Overtime",
                                kind: .object,
                                amountsByYear: [2025: 50000, 2026: 60000]
                            )
                        ]
                    )
                ]
            )
        ]

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("rb_budget_template.json")
        let data = try JSONEncoder.rb.encode(template)
        try data.write(to: url, options: [.atomic])
        return url
    }

    public func exportCurrentDatasetURL() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("rb_budget_export.json")
        let data = try JSONEncoder.rb.encode(nodes)
        try data.write(to: url, options: [.atomic])
        return url
    }

    public var jsonTemplate: String {
        (try? String(contentsOf: templateJSONURL(), encoding: .utf8)) ?? ""
    }
}

// MARK: - Codable helpers

private extension JSONEncoder {
    static var rb: JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }
}

private extension JSONDecoder {
    static var rb: JSONDecoder {
        JSONDecoder()
    }
}
