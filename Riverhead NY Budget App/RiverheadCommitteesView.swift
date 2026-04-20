//
//  RiverheadCommitteesView.swift
//  YourApp
//
//  Swift 6 • iOS 17+
//
//  Riverhead Committees Browser
//  - Loads committee list from: https://www.townofriverheadny.gov/240/Town-Hall-Committees
//  - For each committee page, extracts:
//      • Members (+ other member-like sections where present)
//      • Member count
//      • Vacancies (best-effort)
//      • Term length (best-effort; looks for "Terms of Office")
//
//  Notes:
//  - This is a best-effort HTML-to-text scrape of CivicPlus pages without external dependencies.
//  - If the town changes page structure, parsing may need tweaks.
//  - “Vacancies” and “Term length” are only shown when the source page provides enough info.
//

import SwiftUI
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - View

@MainActor
public struct RiverheadCommitteesView: View {

    @StateObject private var store = RiverheadCommitteesStore()

    @State private var query: String = ""
    @State private var sort: SortMode = .name
    @State private var showOnlyWithVacancies: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                switch store.state {
                case .idle, .loading:
                    loadingView
                case .failed(let message):
                    errorView(message: message)
                case .loaded(let committees):
                    listView(committees: committees)
                }
            }
            .navigationTitle("Riverhead Committees")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await store.refresh(forceNetwork: true) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh")
                }
            }
            .task {
                await store.refresh(forceNetwork: false)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
            Text(store.state == .loading ? store.progressLabel : "Loading…")
                .font(.callout)
                .foregroundStyle(.secondary)

            if let last = store.lastUpdated {
                Text("Last updated: \(last.formatted(date: .abbreviated, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("Couldn’t Load Committees", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task { await store.refresh(forceNetwork: true) }
            }
        }
        .padding()
    }

    private func listView(committees: [RiverheadCommittee]) -> some View {
        let filtered = committees
            .filter { query.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(query) }
            .filter { showOnlyWithVacancies ? ($0.vacancies ?? 0) > 0 : true }
            .sorted(by: sort.sorter)

        return List {
            Section {
                controlsView(total: committees.count, shown: filtered.count)
            }

            Section("Committees") {
                ForEach(filtered) { committee in
                    NavigationLink {
                        RiverheadCommitteeDetailView(committee: committee)
                    } label: {
                        RiverheadCommitteeRow(committee: committee)
                    }
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Data source: Town of Riverhead website.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Vacancies/terms appear only when published on the source page (best-effort scrape).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if let last = store.lastUpdated {
                        Text("Fetched: \(last.formatted(date: .abbreviated, time: .shortened))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search committees")
    }

    private func controlsView(total: Int, shown: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Picker("Sort", selection: $sort) {
                    Text("Name").tag(SortMode.name)
                    Text("Vacancies").tag(SortMode.vacancies)
                    Text("Members").tag(SortMode.members)
                }
                .pickerStyle(.segmented)
            }

            Toggle("Only show committees with vacancies", isOn: $showOnlyWithVacancies)
                .font(.callout)

            Text("Showing \(shown) of \(total)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private enum SortMode: String, CaseIterable, Identifiable {
        case name, vacancies, members
        var id: String { rawValue }

        var sorter: (RiverheadCommittee, RiverheadCommittee) -> Bool {
            switch self {
            case .name:
                return { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            case .vacancies:
                return {
                    let a = $0.vacancies ?? -1
                    let b = $1.vacancies ?? -1
                    if a == b { return $0.name < $1.name }
                    return a > b
                }
            case .members:
                return {
                    let a = $0.primaryMembers.count
                    let b = $1.primaryMembers.count
                    if a == b { return $0.name < $1.name }
                    return a > b
                }
            }
        }
    }
}

// MARK: - Row

private struct RiverheadCommitteeRow: View {
    let committee: RiverheadCommittee

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(committee.name)
                .font(.headline)

            HStack(spacing: 10) {
                Label("\(committee.primaryMembers.count) members", systemImage: "person.3")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let seats = committee.authorizedSeats {
                    Text("• \(seats) seats")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let vac = committee.vacancies {
                    Text("• \(vac) vacant")
                        .font(.subheadline)
                        .foregroundStyle(vac > 0 ? .orange : .secondary)
                }
            }

            if let term = committee.termSummary, !term.isEmpty {
                Text("Term: \(term)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("Term: Not listed")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detail View

private struct RiverheadCommitteeDetailView: View {
    let committee: RiverheadCommittee
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section("Summary") {
                HStack {
                    Text("Members")
                    Spacer()
                    Text("\(committee.primaryMembers.count)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Vacancies")
                    Spacer()
                    Text(committee.vacancies.map(String.init) ?? "—")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Term length")
                    Spacer()
                    Text(committee.termSummary ?? "Not listed")
                        .foregroundStyle(.secondary)
                }

                if let notes = committee.termNotes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Term notes")
                            .font(.subheadline)
                        Text(notes)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    openURL(committee.sourceURL)
                } label: {
                    Label("Open Source Page", systemImage: "link")
                }
            }

            if !committee.primaryMembers.isEmpty {
                Section("Members") {
                    ForEach(committee.primaryMembers) { m in
                        memberRow(m)
                    }
                }
            }

            ForEach(committee.otherSections.sorted(by: { $0.key < $1.key }), id: \.key) { sectionName, members in
                if !members.isEmpty {
                    Section(sectionName) {
                        ForEach(members) { m in
                            memberRow(m)
                        }
                    }
                }
            }
        }
        .navigationTitle(committee.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func memberRow(_ m: RiverheadCommitteeMember) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(m.name)
                .font(.body)
            if let role = m.role, !role.isEmpty {
                Text(role)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Models

public struct RiverheadCommittee: Identifiable, Codable, Hashable {
    public var id: String { sourceURL.absoluteString }

    public let name: String
    public let sourceURL: URL

    /// Parsed from "Members" section. This is what we use for member counts.
    public var primaryMembers: [RiverheadCommitteeMember]

    /// Other member-like sections: e.g. Liaisons, Town Board Liaison(s), Town Counsel, etc.
    public var otherSections: [String: [RiverheadCommitteeMember]]

    /// If the page states a seat count (e.g., "consists of five members"), we store it here.
    public var authorizedSeats: Int?

    /// If the page provides terms (e.g. "five (5) year terms"), we store a concise summary here.
    public var termSummary: String?

    /// Extra text around term details, if present.
    public var termNotes: String?

    /// Vacancy count (best-effort):
    /// - If authorizedSeats exists, vacancy = max(0, authorizedSeats - filledMembers)
    /// - Else if member list includes explicit "Vacant", vacancy = count("Vacant")
    /// - Else nil
    public var vacancies: Int? {
        let explicitVacants = primaryMembers.filter { $0.isVacant }.count

        if let seats = authorizedSeats {
            // Count filled members as non-vacant.
            let filled = primaryMembers.filter { !$0.isVacant }.count
            return max(0, seats - filled)
        }

        return explicitVacants > 0 ? explicitVacants : nil
    }
}

public struct RiverheadCommitteeMember: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public var role: String?

    public init(name: String, role: String? = nil) {
        self.name = name
        self.role = role
        self.id = "\(name)|\(role ?? "")"
    }

    public var isVacant: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().contains("vacant")
    }
}

// MARK: - Store

@MainActor
final class RiverheadCommitteesStore: ObservableObject {

    enum State: Equatable {
        case idle
        case loading
        case loaded([RiverheadCommittee])
        case failed(String)
    }

    @Published var state: State = .idle
    @Published var lastUpdated: Date? = nil

    fileprivate var progressLabel: String {
        switch progress {
        case .none:
            return "Loading…"
        case .index:
            return "Loading committee index…"
        case .committee(let current, let total):
            return "Loading committees… \(current)/\(total)"
        case .parsing(let name):
            return "Parsing \(name)…"
        }
    }

    private enum Progress: Equatable {
        case none
        case index
        case committee(current: Int, total: Int)
        case parsing(name: String)
    }

    private var progress: Progress = .none

    private let cache = RiverheadCommitteesCache()
    private let scraper = RiverheadCommitteesScraper()

    func refresh(forceNetwork: Bool) async {
        // Fast path: show cached data immediately unless forceNetwork.
        if !forceNetwork, let cached = cache.load() {
            self.state = .loaded(cached.committees)
            self.lastUpdated = cached.fetchedAt
        }

        self.state = .loading
        self.progress = .index

        do {
            let index = try await scraper.fetchCommitteeIndex()
            let total = index.count
            var results: [RiverheadCommittee] = []
            results.reserveCapacity(total)

            // Fetch committee pages concurrently, but keep UI progress updated.
            try await withThrowingTaskGroup(of: RiverheadCommittee?.self) { group in
                for (idx, item) in index.enumerated() {
                    group.addTask {
                        // Each task fetches & parses one committee page.
                        do {
                            return try await self.scraper.fetchCommitteeDetail(name: item.name, url: item.url)
                        } catch {
                            // If one page fails, we skip it (still show others).
                            return nil
                        }
                    }

                    // Small throttling can be added here if needed.
                    _ = idx
                }

                var completed = 0
                for try await committee in group {
                    completed += 1
                    await MainActor.run {
                        self.progress = .committee(current: completed, total: total)
                    }
                    if let c = committee {
                        results.append(c)
                    }
                }
            }

            // Sort stable by name for default display
            results.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            let payload = RiverheadCommitteesCache.Payload(fetchedAt: Date(), committees: results)
            cache.save(payload)
            self.lastUpdated = payload.fetchedAt
            self.state = .loaded(results)

        } catch {
            self.state = .failed(error.localizedDescription)
        }

        self.progress = .none
    }
}

// MARK: - Scraper

final class RiverheadCommitteesScraper {

    struct IndexItem: Hashable {
        let name: String
        let url: URL
    }

    // Known stable index page:
    private let indexURL = URL(string: "https://www.townofriverheadny.gov/240/Town-Hall-Committees")!

    func fetchCommitteeIndex() async throws -> [IndexItem] {
        let html = try await fetchHTML(indexURL)

        // CivicPlus pages often include the committee list repeatedly (menu + content).
        // We only keep URLs that look like committee pages: "/<digits>/<slug>"
        // and we exclude obvious non-committee destinations (Home, Government, etc.) by name heuristics.
        let linkPairs = RiverheadHTMLParser.extractAnchorPairs(html: html)

        var seen = Set<URL>()
        var items: [IndexItem] = []

        for (rawTitle, rawHref) in linkPairs {
            guard !rawTitle.isEmpty else { continue }
            guard let url = RiverheadHTMLParser.absoluteURL(from: rawHref, base: indexURL) else { continue }

            // Keep internal CivicPlus content pages.
            let path = url.path
            guard RiverheadHTMLParser.looksLikeCommitteePath(path) else { continue }

            // Filter out duplicates.
            guard !seen.contains(url) else { continue }
            seen.insert(url)

            // Heuristic: keep items that match known committee-ish titles (avoid breadcrumbs).
            // The index menu includes Home/Government, etc. This drops obvious ones.
            let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            if RiverheadHTMLParser.isLikelyNonCommitteeTitle(title) { continue }

            items.append(IndexItem(name: title, url: url))
        }

        // The menu list can include items in other departments. We "prefer" those that show up in the
        // Town Hall Committees list by requiring the title to include common committee/board keywords,
        // OR be in a known exceptions list.
        let filtered = items.filter { RiverheadHTMLParser.isLikelyCommitteeTitle($0.name) }

        // If filtering becomes too strict due to site changes, fall back to raw items.
        return filtered.count >= 10 ? filtered : items
    }

    func fetchCommitteeDetail(name: String, url: URL) async throws -> RiverheadCommittee {
        let html = try await fetchHTML(url)
        let plain = RiverheadHTMLParser.htmlToPlainText(html)

        // Sections
        let sections = RiverheadTextSectionParser.extractSections(from: plain)
        let htmlSections = RiverheadHTMLParser.extractSectionHTMLBlocks(html: html)

        var members = RiverheadTextSectionParser.parseMembersBlock(sections["Members"] ?? "")
        if members.isEmpty,
           let membersHTML = RiverheadHTMLParser.sectionBlock(in: htmlSections, matchingAny: ["Members"]) {
            let membersText = RiverheadHTMLParser.htmlToPlainText(membersHTML)
            members = RiverheadTextSectionParser.parseMembersBlock(membersText)
        }

        var other = RiverheadTextSectionParser.parseOtherMemberSections(from: sections)
        if other.isEmpty {
            other = RiverheadTextSectionParser.parseOtherMemberSections(fromHTMLSections: htmlSections)
        }

        // Authorized seats (best-effort)
        let seatCount = RiverheadTextSectionParser.extractSeatCount(from: plain)

        // Term info (best-effort)
        let term = RiverheadTextSectionParser.extractTermInfo(from: plain)

        return RiverheadCommittee(
            name: name,
            sourceURL: url,
            primaryMembers: members,
            otherSections: other,
            authorizedSeats: seatCount,
            termSummary: term?.summary,
            termNotes: term?.notes
        )
    }

    private func fetchHTML(_ url: URL) async throws -> String {
        var req = URLRequest(url: url)
        req.timeoutInterval = 25
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.setValue("text/html,*/*;q=0.8", forHTTPHeaderField: "Accept")

        let (data, resp) = try await URLSession.shared.data(for: req)

        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw NSError(domain: "RiverheadCommittees", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "HTTP \(http.statusCode) loading \(url.absoluteString)"
            ])
        }

        // Try UTF-8 first, then fall back to ISO-8859-1.
        if let s = String(data: data, encoding: .utf8) {
            return s
        }
        if let s = String(data: data, encoding: .isoLatin1) {
            return s
        }
        return String(decoding: data, as: UTF8.self)
    }
}

// MARK: - Cache

final class RiverheadCommitteesCache {

    struct Payload: Codable {
        let fetchedAt: Date
        let committees: [RiverheadCommittee]
    }

    private let fileURL: URL = {
        let dir = RBAppDirectories.cachesDirectory()
        return dir.appendingPathComponent("riverhead_committees_cache.json")
    }()

    func load() -> Payload? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Payload.self, from: data)
    }

    func save(_ payload: Payload) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}

// MARK: - HTML Helpers (no external deps)

enum RiverheadHTMLParser {

    static func extractAnchorPairs(html: String) -> [(title: String, href: String)] {
        // Very simple anchor extractor: <a ... href="...">TITLE</a>
        // Not a full HTML parser, but works well for CivicPlus-style pages.
        let pattern = #"(?is)<a[^>]*\shref\s*=\s*"([^"]+)"[^>]*>(.*?)</a>"#
        guard let re = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }

        let ns = html as NSString
        let matches = re.matches(in: html, options: [], range: NSRange(location: 0, length: ns.length))

        return matches.compactMap { m in
            guard m.numberOfRanges >= 3 else { return nil }
            let href = ns.substring(with: m.range(at: 1))
            let rawTitle = ns.substring(with: m.range(at: 2))
            let title = stripTags(rawTitle)
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\t", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return (title: title, href: href)
        }
    }

    static func absoluteURL(from href: String, base: URL) -> URL? {
        if href.hasPrefix("http://") || href.hasPrefix("https://") {
            return URL(string: href)
        }
        if href.hasPrefix("//") {
            return URL(string: "https:\(href)")
        }
        if href.hasPrefix("/") {
            var comps = URLComponents(url: base, resolvingAgainstBaseURL: false)
            comps?.path = href
            comps?.query = nil
            comps?.fragment = nil
            return comps?.url
        }
        return URL(string: href, relativeTo: base)?.absoluteURL
    }

    static func looksLikeCommitteePath(_ path: String) -> Bool {
        // Matches "/123/Some-Slug"
        let parts = path.split(separator: "/").map(String.init)
        guard parts.count >= 2 else { return false }
        guard let first = parts.first, Int(first) != nil else { return false }
        return true
    }

    static func isLikelyNonCommitteeTitle(_ title: String) -> Bool {
        let t = title.lowercased()
        if t == "home" { return true }
        if t == "government" { return true }
        if t == "services" { return true }
        if t == "departments" { return true }
        if t == "how do i..." { return true }
        if t.contains("skip to main content") { return true }
        if t.contains("create a website account") { return true }
        if t.contains("website sign in") { return true }
        if t.contains("view most recent agendas") { return true }
        if t.contains("agendas") && t.contains("minutes") { return true }
        return false
    }

    static func isLikelyCommitteeTitle(_ title: String) -> Bool {
        let t = title.lowercased()

        // Most committee/board names contain one of these.
        let keywords = [
            "committee", "task force", "board", "council", "forum", "agency"
        ]
        if keywords.contains(where: { t.contains($0) }) { return true }

        // Exceptions (in case names are short/odd).
        let allowList: Set<String> = [
            "ida", "industrial development agency (ida)"
        ]
        if allowList.contains(t.trimmingCharacters(in: .whitespacesAndNewlines)) { return true }

        return false
    }

    static func stripTags(_ s: String) -> String {
        let pattern = #"(?is)<[^>]+>"#
        return s.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }

    static func htmlToPlainText(_ html: String) -> String {
        #if canImport(UIKit)
        if let data = html.data(using: .utf8) {
            let opts: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            if let attributed = try? NSAttributedString(data: data, options: opts, documentAttributes: nil) {
                return normalizeText(attributed.string)
            }
        }
        #endif

        // Fallback: strip tags
        return normalizeText(stripTags(html))
    }

    static func normalizeText(_ s: String) -> String {
        var x = s
        x = x.replacingOccurrences(of: "\r\n", with: "\n")
        x = x.replacingOccurrences(of: "\r", with: "\n")
        // Collapse many blank lines
        x = x.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
        return x
    }

    static func extractSectionHTMLBlocks(html: String) -> [String: String] {
        // Capture content between heading tags as a fallback when plain-text extraction misses list structure.
        let pattern = #"(?is)<h([1-6])[^>]*>(.*?)</h\1>"#
        guard let re = try? NSRegularExpression(pattern: pattern) else { return [:] }

        let ns = html as NSString
        let matches = re.matches(in: html, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return [:] }

        var out: [String: String] = [:]

        for (i, match) in matches.enumerated() {
            guard match.numberOfRanges >= 3 else { continue }
            let headingRaw = ns.substring(with: match.range(at: 2))
            let headingText = decodeBasicHTMLEntities(
                stripTags(headingRaw)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            )

            let blockStart = match.range.location + match.range.length
            let blockEnd = (i + 1 < matches.count) ? matches[i + 1].range.location : ns.length
            guard blockEnd > blockStart else { continue }

            let block = ns.substring(with: NSRange(location: blockStart, length: blockEnd - blockStart))
            if !headingText.isEmpty {
                out[headingText] = block
            }
        }

        return out
    }

    static func sectionBlock(in sections: [String: String], matchingAny keys: [String]) -> String? {
        for wanted in keys {
            if let direct = sections[wanted] { return direct }
            if let fuzzy = sections.first(where: { $0.key.caseInsensitiveCompare(wanted) == .orderedSame })?.value {
                return fuzzy
            }
        }
        return nil
    }

    private static func decodeBasicHTMLEntities(_ s: String) -> String {
        s.replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
    }
}

// MARK: - Text Section Parser

enum RiverheadTextSectionParser {

    // Captures major headings like:
    // "Meetings", "Agendas & Minutes", "Members", "Town Board Liaison", "Overview", "Terms of Office", etc.
    static func extractSections(from plain: String) -> [String: String] {
        let lines = plain
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Known headings (CivicPlus commonly uses these exact words).
        let headings: Set<String> = Set([
            "Meetings",
            "Agendas & Minutes",
            "Agendas and Minutes",
            "Members",
            "Ex-Officio Members",
            "Ex Officio Members",
            "Town Board Liaison",
            "Town Board Liaisons",
            "Town Liaison",
            "Town Liaisons",
            "Town CDA Liaison",
            "Town Counsel",
            "Town Attorney Liaison",
            "Town Attorney",
            "Liaisons",
            "Internal Green Team",
            "Overview",
            "Mission Statement",
            "Terms of Office",
            "In the News",
            "Related Documents",
            "Contact Us",
            "FAQs",
            "FAQ"
        ])

        var out: [String: [String]] = [:]
        var currentKey: String? = nil

        func isHeadingLine(_ line: String) -> Bool {
            if headings.contains(line) { return true }
            // Some pages use "### Mission Statement" etc; after HTML->text decode,
            // the hash marks are typically removed, but keep a guard:
            let cleaned = line.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            return headings.contains(cleaned)
        }

        for line in lines {
            let normalized = line.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines)

            if isHeadingLine(normalized) {
                currentKey = normalized
                if out[currentKey!] == nil { out[currentKey!] = [] }
                continue
            }

            if let key = currentKey {
                out[key, default: []].append(normalized)
            }
        }

        // Join back to blocks
        return out.mapValues { $0.joined(separator: "\n") }
    }

    static func parseMembersBlock(_ block: String) -> [RiverheadCommitteeMember] {
        guard !block.isEmpty else { return [] }

        let rawLines = block
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var members: [RiverheadCommitteeMember] = []
        var currentGroup: String? = nil

        for line in rawLines {
            // Stop if this block accidentally includes another heading-like marker
            if isBoundaryLine(line) { break }

            // Remove common bullet characters.
            let cleaned = line
                .trimmingCharacters(in: CharacterSet(charactersIn: "•*-").union(.whitespaces))

            guard !cleaned.isEmpty else { continue }

            // Beach Advisory and some others include category lines like "Iron Pier Beach".
            if looksLikeGroupHeading(cleaned) {
                currentGroup = cleaned
                continue
            }

            let parsed = parseNameAndRole(cleaned, defaultRole: currentGroup)
            members.append(parsed)
        }

        return members
    }

    static func parseOtherMemberSections(from sections: [String: String]) -> [String: [RiverheadCommitteeMember]] {
        var out: [String: [RiverheadCommitteeMember]] = [:]

        // We keep these sections if present.
        let keysToKeep = [
            "Town Board Liaison",
            "Town Board Liaisons",
            "Town Liaison",
            "Town Liaisons",
            "Town CDA Liaison",
            "Town Counsel",
            "Town Attorney Liaison",
            "Town Attorney",
            "Liaisons",
            "Internal Green Team",
            "Ex-Officio Members",
            "Ex Officio Members"
        ]

        for key in keysToKeep {
            guard let block = sections[key], !block.isEmpty else { continue }
            let members = parseLoosePeopleLines(block, sectionName: key)
            if !members.isEmpty {
                out[key] = members
            }
        }

        return out
    }

    static func parseOtherMemberSections(fromHTMLSections sections: [String: String]) -> [String: [RiverheadCommitteeMember]] {
        var out: [String: [RiverheadCommitteeMember]] = [:]

        let keysToKeep = [
            "Town Board Liaison",
            "Town Board Liaisons",
            "Town Liaison",
            "Town Liaisons",
            "Town CDA Liaison",
            "Town Counsel",
            "Town Attorney Liaison",
            "Town Attorney",
            "Liaisons",
            "Internal Green Team",
            "Ex-Officio Members",
            "Ex Officio Members"
        ]

        for key in keysToKeep {
            guard let htmlBlock = RiverheadHTMLParser.sectionBlock(in: sections, matchingAny: [key]) else { continue }
            let blockText = RiverheadHTMLParser.htmlToPlainText(htmlBlock)
            let members = parseLoosePeopleLines(blockText, sectionName: key)
            if !members.isEmpty {
                out[key] = members
            }
        }

        return out
    }

    // MARK: Seat count extraction (best-effort)

    static func extractSeatCount(from plain: String) -> Int? {
        let lower = plain.lowercased()

        // Common phrasing: "consists of three members" / "consists of five members"
        if let n = matchIntNearPhrase(text: lower, phrase: "consists of", followedBy: "members") {
            return n
        }

        // Another phrasing: "consists of 3 members"
        if let n = matchDigitBeforeWord(text: lower, word: "members") {
            return n
        }

        return nil
    }

    // MARK: Term extraction (best-effort)

    struct TermInfo {
        let summary: String
        let notes: String?
    }

    static func extractTermInfo(from plain: String) -> TermInfo? {
        let lower = plain.lowercased()
        guard let range = lower.range(of: "terms of office") else { return nil }

        // Take a window after the heading.
        let start = range.upperBound
        let window = String(plain[start...].prefix(600))

        // Try to find years in the window.
        if let years = extractYearCount(from: window) {
            // Summary: "X years"
            let summary = "\(years) year" + (years == 1 ? "" : "s")

            // Notes: first 1–2 lines of the window for context.
            let notes = window
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .prefix(3)
                .joined(separator: " ")

            return TermInfo(summary: summary, notes: notes.isEmpty ? nil : notes)
        }

        return nil
    }

    // MARK: Helpers

    private static func parseLoosePeopleLines(_ block: String, sectionName: String) -> [RiverheadCommitteeMember] {
        let rawLines = block
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var members: [RiverheadCommitteeMember] = []
        for line in rawLines {
            if isBoundaryLine(line) { break }

            // Skip phone/email noise
            let l = line.lowercased()
            if l.hasPrefix("phone:") { continue }
            if l.hasPrefix("email") { continue }
            if l.contains("ext") && l.contains("631") { continue }

            let cleaned = line.trimmingCharacters(in: CharacterSet(charactersIn: "•*-").union(.whitespaces))
            guard !cleaned.isEmpty else { continue }

            members.append(parseNameAndRole(cleaned, defaultRole: nil))
        }
        return members
    }

    private static func parseNameAndRole(_ line: String, defaultRole: String?) -> RiverheadCommitteeMember {
        // Patterns:
        // - "Jane Doe, Chair"
        // - "John Smith - Vice Chair"
        // - "Liz Sanders (Alternate)"
        // - "Otto Wittmeier, Chairman"
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.contains(",") {
            let parts = trimmed.split(separator: ",", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            let name = parts.first ?? trimmed
            let role = parts.count > 1 ? parts[1] : defaultRole
            return RiverheadCommitteeMember(name: name, role: role)
        }

        if trimmed.contains(" - ") {
            let parts = trimmed.components(separatedBy: " - ")
            let name = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? trimmed
            let role = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespacesAndNewlines) : defaultRole
            return RiverheadCommitteeMember(name: name, role: role)
        }

        if let open = trimmed.firstIndex(of: "("), let close = trimmed.lastIndex(of: ")"), close > open {
            let name = String(trimmed[..<open]).trimmingCharacters(in: .whitespacesAndNewlines)
            let role = String(trimmed[trimmed.index(after: open)..<close]).trimmingCharacters(in: .whitespacesAndNewlines)
            return RiverheadCommitteeMember(name: name.isEmpty ? trimmed : name, role: role.isEmpty ? defaultRole : role)
        }

        return RiverheadCommitteeMember(name: trimmed, role: defaultRole)
    }

    private static func looksLikeGroupHeading(_ line: String) -> Bool {
        // Used for nested lists like the Beach Advisory Committee.
        // Treat short lines without commas as group headers if they look like a location/category.
        if line.contains(",") { return false }
        let lower = line.lowercased()
        if lower.contains("beach") { return true }
        if lower.contains("parks") { return true }
        if lower.contains("all beaches") { return true }
        if lower.contains("all other") { return true }
        // Keep it conservative.
        return line.count <= 35 && line.split(separator: " ").count <= 5
    }

    private static func isBoundaryLine(_ line: String) -> Bool {
        let lower = line.lowercased()
        // If the members block accidentally contains these, stop.
        let boundaries = [
            "overview", "mission statement", "agendas", "minutes", "meetings",
            "contact us", "related documents", "in the news", "terms of office"
        ]
        return boundaries.contains(where: { lower == $0 })
    }

    private static func extractYearCount(from text: String) -> Int? {
        // Digits: "5 year", "five (5) year" handled by digit capture first.
        let lower = text.lowercased()

        // 1) digit-based
        if let n = matchDigitBeforeWord(text: lower, word: "year") { return n }
        if let n = matchDigitBeforeWord(text: lower, word: "years") { return n }

        // 2) word-number based (common: "five (5) year terms")
        let wordToInt: [String: Int] = [
            "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
            "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
            "eleven": 11, "twelve": 12
        ]

        for (w, v) in wordToInt {
            if lower.contains("\(w) year") || lower.contains("\(w) years") {
                return v
            }
        }

        return nil
    }

    private static func matchDigitBeforeWord(text: String, word: String) -> Int? {
        // Finds patterns like "5 year" or "5-year"
        let pattern = #"(\d{1,2})\s*[-]?\s*\b"# + NSRegularExpression.escapedPattern(for: word) + #"\b"#
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }

        let ns = text as NSString
        guard let m = re.firstMatch(in: text, options: [], range: NSRange(location: 0, length: ns.length)),
              m.numberOfRanges >= 2
        else { return nil }

        let s = ns.substring(with: m.range(at: 1))
        return Int(s)
    }

    private static func matchIntNearPhrase(text: String, phrase: String, followedBy: String) -> Int? {
        // "consists of five members" (word) or "consists of 5 members" (digit)
        // We'll look for: phrase + (word|digit) + followedBy
        let windowSize = 250
        guard let pr = text.range(of: phrase) else { return nil }
        let start = pr.upperBound
        let window = String(text[start...].prefix(windowSize))

        // digit
        if let n = matchDigitBeforeWord(text: window, word: followedBy) {
            return n
        }

        // word-number
        let wordToInt: [String: Int] = [
            "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
            "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
            "eleven": 11, "twelve": 12
        ]

        for (w, v) in wordToInt {
            if window.contains("\(w) \(followedBy)") { return v }
        }

        return nil
    }
}
