//
//  UnifiedSearchParityView.swift
//  Riverhead NY Budget App
//
//  Native counterpart to Riverhead Budget Live /search/.
//  It consumes the same sharded search manifest and record schema as the web app.
//

import SwiftUI
import Foundation

// MARK: - Search data contract

enum RiverheadSearchEntryType: String, Codable, CaseIterable, Identifiable, Sendable {
    case fund
    case lineItem = "line-item"
    case payroll
    case salary
    case resolution
    case page

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fund: "Fund"
        case .lineItem: "Budget line"
        case .payroll: "Payroll"
        case .salary: "Salary 2026"
        case .resolution: "Board vote"
        case .page: "Document"
        }
    }

    var systemImage: String {
        switch self {
        case .fund: "building.columns.fill"
        case .lineItem: "list.bullet.rectangle.fill"
        case .payroll: "person.text.rectangle.fill"
        case .salary: "dollarsign.square.fill"
        case .resolution: "checklist.checked"
        case .page: "doc.text.fill"
        }
    }
}

struct RiverheadSearchEntry: Codable, Hashable, Identifiable, Sendable {
    let t: RiverheadSearchEntryType
    let n: String
    let x: String
    let u: String
    let v: Double?

    var id: String { "\(t.rawValue)|\(n)|\(u)" }

    var destinationURL: URL? {
        if let absolute = URL(string: u), absolute.scheme != nil { return absolute }
        return URL(string: "https://rike4545.github.io/Riverhead-NY-Budget-Web-App\(u)")
    }
}

struct RiverheadSearchManifest: Decodable, Sendable {
    struct Shard: Decodable, Sendable {
        let url: String
        let count: Int
        let bytes: Int
    }

    let version: Int
    let shards: [String: Shard]
    let total: Int
}

private struct RiverheadSearchShard: Decodable, Sendable {
    let entries: [RiverheadSearchEntry]
}

private enum RiverheadSearchClient {
    private static let pagesRoot = "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/data/search"
    private static let rawRoot = "https://raw.githubusercontent.com/rike4545/Riverhead-NY-Budget-Web-App/main/web/public/data/search"

    static func loadManifest() async throws -> RiverheadSearchManifest {
        try await loadJSON(RiverheadSearchManifest.self, filename: "manifest.json")
    }

    static func loadCore(manifest: RiverheadSearchManifest) async throws -> [RiverheadSearchEntry] {
        async let lineItems = loadShard(.lineItem, manifest: manifest)
        async let payroll = loadShard(.payroll, manifest: manifest)
        async let salary = loadShard(.salary, manifest: manifest)
        async let resolutions = loadShard(.resolution, manifest: manifest)
        async let funds = loadShard(.fund, manifest: manifest)
        return try await lineItems + payroll + salary + resolutions + funds
    }

    static func loadPageShard(manifest: RiverheadSearchManifest) async throws -> [RiverheadSearchEntry] {
        try await loadShard(.page, manifest: manifest)
    }

    private static func loadShard(
        _ type: RiverheadSearchEntryType,
        manifest: RiverheadSearchManifest
    ) async throws -> [RiverheadSearchEntry] {
        guard let shard = manifest.shards[type.rawValue] else { return [] }
        let envelope = try await loadJSON(RiverheadSearchShard.self, filename: shard.url)
        return envelope.entries
    }

    private static func loadJSON<T: Decodable & Sendable>(_ type: T.Type, filename: String) async throws -> T {
        let roots = [pagesRoot, rawRoot]
        var lastError: Error?

        for root in roots {
            guard let url = URL(string: "\(root)/\(filename)") else { continue }
            do {
                var request = URLRequest(url: url)
                request.cachePolicy = .returnCacheDataElseLoad
                request.timeoutInterval = 25
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      (200..<300).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                lastError = error
            }
        }

        throw lastError ?? URLError(.cannotLoadFromNetwork)
    }
}

// MARK: - Web-compatible scorer

private enum RiverheadSearchScorer {
    private static let stopwords: Set<String> = [
        "the", "a", "an", "and", "or", "of", "to", "in", "on", "for", "is", "are", "was", "were",
        "how", "what", "why", "who", "when", "where", "which", "does", "do", "did", "has", "have",
        "had", "can", "could", "would", "should", "much", "many", "this", "that", "these", "those",
        "it", "its", "be", "been", "as", "at", "by", "with", "from", "about", "into", "over", "per",
        "me", "my", "i", "we", "our", "you", "your", "they", "them", "their", "town", "riverhead"
    ]

    static func findTerms(_ query: String) -> [String] {
        query.lowercased().split(whereSeparator: \.isWhitespace).map(String.init).filter { $0.count >= 2 }
    }

    static func retrievalTerms(_ question: String) -> [String] {
        let q = question.lowercased()
        let preferred = q.split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .filter { $0.count >= 3 && !stopwords.contains($0) }
        if !preferred.isEmpty { return preferred }
        return q.split(whereSeparator: \.isWhitespace).map(String.init).filter { $0.count >= 2 }
    }

    static func score(
        entries: [RiverheadSearchEntry],
        terms: [String],
        phrase: String
    ) -> [RiverheadSearchEntry] {
        guard !terms.isEmpty else { return [] }

        let ranked: [(RiverheadSearchEntry, Double)] = entries.compactMap { entry in
            let name = entry.n.lowercased()
            let context = entry.x.lowercased()
            var score = 0.0
            var matched = 0

            for term in terms {
                if name.hasPrefix(term) {
                    score += 6
                    matched += 1
                } else if wordPrefix(term, in: name) {
                    score += 4
                    matched += 1
                } else if name.contains(term) {
                    score += 3
                    matched += 1
                } else if wordPrefix(term, in: context) {
                    score += 2
                    matched += 1
                } else if context.contains(term) {
                    score += 1
                    matched += 1
                }
            }

            guard matched > 0 else { return nil }
            score += Double(matched * 8)
            if phrase.count > 3 && name.contains(phrase) { score += 6 }
            if entry.t == .page { score *= 0.55 }
            return (entry, score)
        }

        return ranked.sorted { lhs, rhs in
            if lhs.1 == rhs.1 { return lhs.0.n.localizedCaseInsensitiveCompare(rhs.0.n) == .orderedAscending }
            return lhs.1 > rhs.1
        }.map(\.0)
    }

    private static func wordPrefix(_ term: String, in value: String) -> Bool {
        let escaped = NSRegularExpression.escapedPattern(for: term)
        return value.range(of: "\\b\(escaped)", options: .regularExpression) != nil
    }
}

// MARK: - Search-grounded Ask AI

private enum RiverheadGroundedSearchAIError: LocalizedError {
    case missingKey
    case invalidResponse
    case service(String)

    var errorDescription: String? {
        switch self {
        case .missingKey: "Add your OpenAI API key to use Ask AI."
        case .invalidResponse: "The AI service returned a response the app couldn't read."
        case .service(let message): message
        }
    }
}

private struct RiverheadGroundedSearchAI {
    private let endpoint = URL(string: "https://api.openai.com/v1/responses")!

    func ask(question: String, records: [RiverheadSearchEntry], apiKey: String) async throws -> String {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw RiverheadGroundedSearchAIError.missingKey }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 35
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": "gpt-5-mini",
            "instructions": instructions,
            "input": input(question: question, records: records),
            "max_output_tokens": 800
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RiverheadGroundedSearchAIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = errorMessage(data) ?? (http.statusCode == 401
                ? "That OpenAI key was rejected (HTTP 401). Check the key and try again."
                : "OpenAI returned HTTP \(http.statusCode).")
            throw RiverheadGroundedSearchAIError.service(message)
        }
        guard let output = outputText(data)?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty else {
            throw RiverheadGroundedSearchAIError.invalidResponse
        }
        return output
    }

    private var instructions: String {
        """
        You are the Riverhead Budget Search Assistant — an unofficial, in-app explainer for the Town of Riverhead, New York.

        You are given a resident's question and a numbered list of RECORDS retrieved from the app's canonical Riverhead Budget Live search index. Answer using those records.

        Rules:
        - Ground factual claims in the provided records and cite them by bracket number, such as [2].
        - Lead with the direct answer. State the most relevant number plainly when numbers matter.
        - If the records are insufficient, say so instead of inventing a figure.
        - Do not claim you searched live sources beyond the supplied records.
        - Distinguish appropriations from expenses, levies from total revenue, and authorized salary from actual payroll.
        - Modeling is not adopted Town policy; label modeled claims accordingly.
        - Legal conclusions, exact deadlines, and compliance determinations require verification with the official source.
        - Keep the answer concise, resident-friendly, and easy to scan.
        """
    }

    private func input(question: String, records: [RiverheadSearchEntry]) -> String {
        let grounding = records.enumerated().map { index, entry in
            let value = entry.v.map { " — \($0.formatted(.currency(code: "USD").precision(.fractionLength(0))))" } ?? ""
            return "[\(index + 1)] (\(entry.t.label)) \(entry.n)\(value)\n    \(entry.x)"
        }.joined(separator: "\n")

        return """
        Records retrieved for this question:

        \(grounding)

        Resident question:
        \(question)

        Answer using the records above and cite them by number.
        """
    }

    private func outputText(_ data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let direct = object["output_text"] as? String, !direct.isEmpty { return direct }
        guard let output = object["output"] as? [[String: Any]] else { return nil }
        var parts: [String] = []
        for item in output {
            guard item["type"] as? String == "message",
                  let content = item["content"] as? [[String: Any]] else { continue }
            for block in content where block["type"] as? String == "output_text" {
                if let text = block["text"] as? String { parts.append(text) }
            }
        }
        return parts.isEmpty ? nil : parts.joined(separator: "\n\n")
    }

    private func errorMessage(_ data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = object["error"] as? [String: Any],
              let message = error["message"] as? String else { return nil }
        return message
    }
}

// MARK: - Native UI

private enum RiverheadSearchMode: String, CaseIterable, Identifiable {
    case find = "Find records"
    case ask = "Ask AI"
    var id: String { rawValue }
}

@MainActor
struct NativeUnifiedSearchView: View {
    @State private var mode: RiverheadSearchMode = .find
    @State private var query = ""
    @State private var selectedTypes: Set<RiverheadSearchEntryType> = []
    @State private var manifest: RiverheadSearchManifest?
    @State private var coreEntries: [RiverheadSearchEntry] = []
    @State private var pageEntries: [RiverheadSearchEntry] = []
    @State private var results: [RiverheadSearchEntry] = []
    @State private var statusText = "Loading search index…"
    @State private var indexError: String?
    @State private var isLoadingCore = false
    @State private var isLoadingPages = false
    @State private var visibleLimit = 50
    @State private var searchTask: Task<Void, Never>?

    @State private var apiKey = ""
    @State private var keyDraft = ""
    @State private var showKeyPanel = false
    @State private var aiAnswer = ""
    @State private var aiSources: [RiverheadSearchEntry] = []
    @State private var aiError: String?
    @State private var isAskingAI = false

    private let examples = ["police overtime", "Hegermiller", "sewer district", "Island Water Park", "paving", "Petrocelli"]
    private let aiExamples = [
        "How much does the Town spend on police overtime?",
        "Which recent Town Board votes involved the Petrocelli project?",
        "Who are the highest-paid employees on the payroll?"
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                Picker("Search mode", selection: $mode) {
                    ForEach(RiverheadSearchMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                queryCard

                if mode == .find {
                    findContent
                } else {
                    askContent
                }
            }
            .padding(16)
        }
        .background(RiverheadTheme.Surface.page.ignoresSafeArea())
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            apiKey = OpenAIKeychain.loadAPIKey() ?? ""
            await loadCoreIfNeeded()
        }
        .onChange(of: query) { _, _ in
            visibleLimit = 50
            if mode == .find { scheduleSearch() }
        }
        .onChange(of: selectedTypes) { _, _ in
            visibleLimit = 50
            scheduleSearch()
        }
        .onChange(of: mode) { _, newMode in
            if newMode == .find { scheduleSearch() }
        }
        .onDisappear { searchTask?.cancel() }
    }

    private var queryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if mode == .find {
                TextField("Try: police overtime · sewer · paving…", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Search all Riverhead budget data")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(examples, id: \.self) { example in
                            Button(example) { query = example }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                    }
                }
            } else {
                TextField("Ask about Riverhead's budget, pay, funds, or Board votes…", text: $query, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...5)
                    .accessibilityLabel("Ask the Riverhead budget AI a question")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(aiExamples, id: \.self) { example in
                            Button(example) { query = example }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                    }
                }
            }
        }
        .searchParityCard()
    }

    @ViewBuilder
    private var findContent: some View {
        filterCard

        if isLoadingCore && coreEntries.isEmpty {
            ProgressView(statusText)
                .frame(maxWidth: .infinity)
                .padding(24)
        } else if let indexError, coreEntries.isEmpty {
            ContentUnavailableView(
                "Search index unavailable",
                systemImage: "magnifyingglass",
                description: Text(indexError)
            )
            .searchParityCard()
        } else if RiverheadSearchScorer.findTerms(query).isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("Search public records", systemImage: "magnifyingglass")
                    .font(.headline)
                Text("Search budget line items, actual payroll, authorized salaries, Town Board votes, funds, and — when needed — more than twelve thousand official document pages.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let manifest {
                    Text("\(manifest.total.formatted()) indexed records • schema v\(manifest.version)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .searchParityCard()
        } else if results.isEmpty && !isLoadingPages {
            ContentUnavailableView.search(text: query)
                .searchParityCard()
        } else {
            resultsCard
        }
    }

    private var filterCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Record types")
                    .font(.headline)
                Spacer()
                if !selectedTypes.isEmpty {
                    Button("Clear") { selectedTypes.removeAll() }
                        .font(.caption)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(RiverheadSearchEntryType.allCases) { type in
                        let selected = selectedTypes.contains(type)
                        Button {
                            if selected { selectedTypes.remove(type) }
                            else { selectedTypes.insert(type) }
                            if type == .page && !selected {
                                Task { await loadPagesIfNeeded(); scheduleSearch() }
                            }
                        } label: {
                            Label(type.label, systemImage: type.systemImage)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .foregroundStyle(selected ? Color.white : RiverheadTheme.textPrimary)
                                .background(selected ? RiverheadTheme.accent : RiverheadTheme.Surface.elevated, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .searchParityCard()
    }

    private var resultsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(results.count.formatted()) results")
                    .font(.headline)
                Spacer()
                if isLoadingPages {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            ForEach(Array(results.prefix(visibleLimit).enumerated()), id: \.element.id) { index, entry in
                if let url = entry.destinationURL {
                    NavigationLink {
                        WebContentView(url: url, title: entry.n)
                    } label: {
                        searchResultRow(entry)
                    }
                    .buttonStyle(.plain)
                } else {
                    searchResultRow(entry)
                }

                if index + 1 < min(visibleLimit, results.count) {
                    Divider().opacity(0.3)
                }
            }

            if visibleLimit < results.count {
                Button("Show 50 more") { visibleLimit += 50 }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
            }
        }
        .searchParityCard()
    }

    private func searchResultRow(_ entry: RiverheadSearchEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label(entry.t.label, systemImage: entry.t.systemImage)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(typeTint(entry.t))
                Spacer()
                if let value = entry.v {
                    Text(value.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(RiverheadTheme.textPrimary)
                }
            }

            Text(entry.n)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RiverheadTheme.textPrimary)
                .multilineTextAlignment(.leading)

            Text(searchSnippet(entry.x, terms: RiverheadSearchScorer.findTerms(query)))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(4)

            Text(entry.u)
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 3)
    }

    @ViewBuilder
    private var askContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Grounded Ask AI", systemImage: "sparkles")
                    .font(.headline)
                Spacer()
                Button(apiKey.isEmpty ? "Add key" : "API key") {
                    keyDraft = ""
                    showKeyPanel.toggle()
                }
                .font(.caption.weight(.semibold))
            }

            Text("The question is answered only from records retrieved from the same search index shown in Find Records. The source records stay visible below the answer.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if showKeyPanel || apiKey.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    SecureField("OpenAI API key", text: $keyDraft)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        Button("Save locally") {
                            let trimmed = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty, OpenAIKeychain.saveAPIKey(trimmed) {
                                apiKey = trimmed
                                keyDraft = ""
                                showKeyPanel = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(keyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        if !apiKey.isEmpty {
                            Button("Remove", role: .destructive) {
                                _ = OpenAIKeychain.deleteAPIKey()
                                apiKey = ""
                            }
                        }
                    }
                    Text("Stored only in this device's Keychain. The key is sent directly to OpenAI when you ask a question.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                Task { await runAsk() }
            } label: {
                if isAskingAI {
                    Label("Searching records…", systemImage: "hourglass")
                } else {
                    Label("Ask from the records", systemImage: "sparkles")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 || isAskingAI)

            if let aiError {
                Label(aiError, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .searchParityCard()

        if !aiAnswer.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Answer")
                    .font(.headline)
                Text(aiAnswer)
                    .font(.body)
                    .textSelection(.enabled)
            }
            .searchParityCard()
        }

        if !aiSources.isEmpty {
            VStack(alignment: .leading, spacing: 9) {
                Text("Records used")
                    .font(.headline)

                ForEach(Array(aiSources.enumerated()), id: \.element.id) { index, entry in
                    if let url = entry.destinationURL {
                        NavigationLink {
                            WebContentView(url: url, title: entry.n)
                        } label: {
                            aiSourceRow(number: index + 1, entry: entry)
                        }
                        .buttonStyle(.plain)
                    } else {
                        aiSourceRow(number: index + 1, entry: entry)
                    }
                    if index != aiSources.indices.last {
                        Divider().opacity(0.3)
                    }
                }
            }
            .searchParityCard()
        }
    }

    private func aiSourceRow(number: Int, entry: RiverheadSearchEntry) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Text("\(number)")
                .font(.caption.monospacedDigit().bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(RiverheadTheme.accent, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.n)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                Text(entry.x)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .contentShape(Rectangle())
    }

    private func loadCoreIfNeeded() async {
        guard coreEntries.isEmpty, !isLoadingCore else { return }
        isLoadingCore = true
        indexError = nil
        statusText = "Loading search index…"
        do {
            let loadedManifest = try await RiverheadSearchClient.loadManifest()
            manifest = loadedManifest
            coreEntries = try await RiverheadSearchClient.loadCore(manifest: loadedManifest)
            statusText = "\(coreEntries.count.formatted()) core records loaded"
            scheduleSearch()
        } catch {
            indexError = error.localizedDescription
            statusText = "Search index could not be loaded"
        }
        isLoadingCore = false
    }

    private func loadPagesIfNeeded() async {
        guard pageEntries.isEmpty, !isLoadingPages else { return }
        guard let manifest else { return }
        isLoadingPages = true
        do {
            pageEntries = try await RiverheadSearchClient.loadPageShard(manifest: manifest)
        } catch {
            if indexError == nil { indexError = "Document pages could not be loaded: \(error.localizedDescription)" }
        }
        isLoadingPages = false
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        let currentQuery = query
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 140_000_000)
            guard !Task.isCancelled, currentQuery == query else { return }
            await performSearch()
        }
    }

    private func performSearch() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let terms = RiverheadSearchScorer.findTerms(q)
        guard !terms.isEmpty else {
            results = []
            return
        }

        if selectedTypes.contains(.page) && pageEntries.isEmpty {
            await loadPagesIfNeeded()
        }

        var entries = coreEntries
        if !pageEntries.isEmpty { entries += pageEntries }
        let selected = selectedTypes
        let scored = await Task.detached(priority: .userInitiated) {
            RiverheadSearchScorer.score(entries: entries, terms: terms, phrase: q)
        }.value
        var filtered = selected.isEmpty ? scored : scored.filter { selected.contains($0.t) }

        if filtered.isEmpty && pageEntries.isEmpty && !selected.contains(where: { $0 != .page }) {
            await loadPagesIfNeeded()
            if !pageEntries.isEmpty {
                entries = coreEntries + pageEntries
                let rescored = await Task.detached(priority: .userInitiated) {
                    RiverheadSearchScorer.score(entries: entries, terms: terms, phrase: q)
                }.value
                filtered = selected.isEmpty ? rescored : rescored.filter { selected.contains($0.t) }
            }
        }

        results = filtered
    }

    private func runAsk() async {
        let question = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard question.count >= 3, !isAskingAI else { return }
        if coreEntries.isEmpty { await loadCoreIfNeeded() }
        guard !coreEntries.isEmpty else {
            aiError = indexError ?? "The search index is unavailable."
            return
        }

        isAskingAI = true
        aiError = nil
        aiAnswer = ""
        aiSources = []

        let terms = RiverheadSearchScorer.retrievalTerms(question)
        var entries = coreEntries
        var records = Array(RiverheadSearchScorer.score(entries: entries, terms: terms, phrase: question.lowercased()).prefix(24))
        if records.count < 8 && pageEntries.isEmpty {
            await loadPagesIfNeeded()
            entries = coreEntries + pageEntries
            records = Array(RiverheadSearchScorer.score(entries: entries, terms: terms, phrase: question.lowercased()).prefix(24))
        }
        aiSources = records

        guard !apiKey.isEmpty else {
            showKeyPanel = true
            aiError = "Add your OpenAI API key to generate an answer. The matching source records are shown below."
            isAskingAI = false
            return
        }

        do {
            aiAnswer = try await RiverheadGroundedSearchAI().ask(question: question, records: records, apiKey: apiKey)
        } catch {
            aiError = error.localizedDescription
        }
        isAskingAI = false
    }

    private func typeTint(_ type: RiverheadSearchEntryType) -> Color {
        switch type {
        case .fund: RiverheadTheme.accent
        case .lineItem: .green
        case .payroll: .orange
        case .salary: .pink
        case .resolution: .purple
        case .page: .secondary
        }
    }
}

private extension View {
    func searchParityCard() -> some View {
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

private func searchSnippet(_ text: String, terms: [String]) -> String {
    guard text.count > 200 else { return text }
    let lower = text.lowercased()
    let firstIndex = terms.compactMap { term -> String.Index? in
        lower.range(of: term)?.lowerBound
    }.min()

    guard let firstIndex else { return String(text.prefix(200)) + "…" }
    let offset = lower.distance(from: lower.startIndex, to: firstIndex)
    let startOffset = max(0, offset - 70)
    let endOffset = min(text.count, offset + 110)
    let start = text.index(text.startIndex, offsetBy: startOffset)
    let end = text.index(text.startIndex, offsetBy: endOffset)
    return (startOffset > 0 ? "…" : "") + String(text[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines) + (endOffset < text.count ? "…" : "")
}
