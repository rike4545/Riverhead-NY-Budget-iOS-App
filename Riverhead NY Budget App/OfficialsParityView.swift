//
//  OfficialsParityView.swift
//  Riverhead NY Budget App
//
//  Native parity for Riverhead Budget Live's /officials/ route.
//
//  Fetched from the web app's published officials-pensions.json rather than
//  restated in Swift. This page names real people and reports what they are
//  paid, so a stale copy here would be worse than no copy at all.
//

import SwiftUI

struct OfficialsParityDocument: Decodable, Sendable {
    let title: String
    let asOf: String
    let intro: String
    let legalNote: String
    /// Status code to resident-facing wording, carried in the document so the
    /// labels follow the web page instead of being pinned in Swift.
    let statusLabels: [String: String]
    let officials: [Official]
    let sources: [String]
    let note: String

    struct Official: Decodable, Sendable {
        let name: String
        let office: String
        /// The web page guards on `o.party && o.party !== '—'`, so a party is
        /// allowed to be absent, and three assessors carry an em dash to mean
        /// "not tracked". Normalised at decode so the badge is simply omitted
        /// rather than rendering a dash in a capsule.
        let party: String?
        let status: String
        let background: String
        let pension: String
        /// The web page guards on `o.sources?.length > 0`, so treat an omitted
        /// list as empty rather than failing the whole document.
        let sources: [String]

        private enum CodingKeys: String, CodingKey {
            case name, office, party, status, background, pension, sources
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            office = try container.decode(String.self, forKey: .office)
            status = try container.decode(String.self, forKey: .status)
            background = try container.decode(String.self, forKey: .background)
            pension = try container.decode(String.self, forKey: .pension)
            sources = try container.decodeIfPresent([String].self, forKey: .sources) ?? []

            let rawParty = try container.decodeIfPresent(String.self, forKey: .party)
            party = Self.meaningfulParty(rawParty)
        }

        /// Mirrors the web page's own test. An em dash is the published file's
        /// placeholder for "no party recorded", not a party.
        static func meaningfulParty(_ raw: String?) -> String? {
            guard let trimmed = raw?.trimmingCharacters(in: .whitespaces),
                  !trimmed.isEmpty,
                  trimmed != "—" else { return nil }
            return trimmed
        }
    }

    func label(for status: String) -> String {
        // Falls back to the raw code rather than an empty capsule: if the web
        // app adds a status before adding its wording, showing "housing" is
        // less misleading than showing nothing at all.
        statusLabels[status] ?? status
    }

    var pensionCount: Int { officials.filter { $0.status == "pension" }.count }
    var activeCount: Int { officials.filter { $0.status == "active" }.count }

    /// Every status used by an official should have wording in `statusLabels`.
    /// Empty in the published document, and the contract test keeps it that way.
    var unlabelledStatuses: Set<String> {
        Set(officials.map(\.status)).subtracting(statusLabels.keys)
    }
}

enum OfficialsParityOrdering {
    /// Mirrors `ORDER` in the web page: the headline finding first, the rows
    /// nobody has checked yet last.
    static let statusOrder = ["pension", "unconfirmed", "active", "none", "review"]

    static func rank(_ status: String) -> Int {
        // `indexOf` returns -1 in the web page, which would float an
        // unrecognised status to the very top of the roster. That reads as an
        // oversight rather than a decision, so an unknown status sorts last
        // here. All five published statuses are listed, so this changes
        // nothing today — it only decides where a sixth would land.
        statusOrder.firstIndex(of: status) ?? statusOrder.count
    }

    /// The web page sorts with a plain comparator, and JavaScript's sort has
    /// been stable since ES2019, so officials sharing a status keep their
    /// document order. Swift's `sort` promises no such thing, so position is
    /// the tiebreaker: without it the roster could reshuffle between launches
    /// while the web page stayed put.
    static func sorted(_ officials: [OfficialsParityDocument.Official]) -> [OfficialsParityDocument.Official] {
        officials.enumerated()
            .sorted { lhs, rhs in
                let left = rank(lhs.element.status)
                let right = rank(rhs.element.status)
                if left != right { return left < right }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}

enum OfficialsParityClient {
    static let dataURL = URL(string: "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/data/officials-pensions.json")!
    static let livePageURL = URL(string: "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/officials/")!

    static func load() async throws -> OfficialsParityDocument {
        var request = URLRequest(url: dataURL)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(OfficialsParityDocument.self, from: data)
    }
}

/// The accent the web page gives each status: amber for a pension being drawn
/// or unconfirmed, blue for someone still accruing one, green for none found,
/// grey for not yet reviewed.
private func statusAccent(for status: String) -> Color {
    switch status {
    case "pension", "unconfirmed": return .orange
    case "active": return .blue
    case "none": return .green
    default: return .secondary
    }
}

@MainActor
struct NativeOfficialsParityView: View {
    @State private var document: OfficialsParityDocument?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let document {
                content(document)
            } else if loadFailed {
                WebContentView(url: OfficialsParityClient.livePageURL, title: "Officials & Pensions")
            } else {
                ProgressView("Loading the sourced review…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Officials & Pensions")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard document == nil, !loadFailed else { return }
            do {
                document = try await OfficialsParityClient.load()
            } catch {
                loadFailed = true
            }
        }
    }

    @ViewBuilder
    private func content(_ data: OfficialsParityDocument) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(data.title).font(.headline)
                    Text(data.asOf)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(data.intro)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .officialsCard()

                // Leads the page on the web, and should lead it here. Naming
                // people alongside pension figures without this framing would
                // imply an accusation the data does not support.
                VStack(alignment: .leading, spacing: 6) {
                    Label("It’s legal — this is disclosure, not an accusation.", systemImage: "building.columns")
                        .font(.subheadline.weight(.semibold))
                    Text(data.legalNote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .officialsCard(edge: .blue)

                stats(data)

                // This paragraph lives in the web page's markup rather than in
                // the published JSON, so it is mirrored here and will not
                // follow an edit on the web side. It is carried anyway because
                // it draws the distinction the whole page rests on — drawing a
                // pension versus building one — and dropping it would leave
                // the roster looking like one undifferentiated list.
                VStack(alignment: .leading, spacing: 6) {
                    Text("What counts here")
                        .font(.subheadline.weight(.semibold))
                    Text("""
                        This flags officials **collecting** a New York pension while in office — \
                        retirees from a government career. People still working a public job (even \
                        a long one) are *building* a pension, not drawing one, so they are listed \
                        separately. Private-sector business owners have no public pension at all.
                        """)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .officialsCard()

                ForEach(Array(OfficialsParityOrdering.sorted(data.officials).enumerated()), id: \.offset) { _, official in
                    officialCard(official, in: data)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(data.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if !data.sources.isEmpty {
                        Text("Sources: " + data.sources.joined(separator: " · "))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .officialsCard()
            }
            .padding(16)
        }
    }

    private func stats(_ data: OfficialsParityDocument) -> some View {
        HStack(alignment: .top, spacing: 10) {
            stat("Reviewed", value: data.officials.count, tint: .primary)
            stat("Collect a pension", value: data.pensionCount, tint: .orange)
            stat("Still accruing", value: data.activeCount, tint: .blue)
        }
    }

    private func stat(_ label: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(value)")
                .font(.title2.weight(.bold))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .officialsCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func officialCard(_ official: OfficialsParityDocument.Official, in data: OfficialsParityDocument) -> some View {
        let tint = statusAccent(for: official.status)
        let statusLabel = data.label(for: official.status)
        let drawsPension = official.status == "pension"

        return VStack(alignment: .leading, spacing: 6) {
            Text(official.name)
                .font(.subheadline.weight(.semibold))

            Text(officeLine(official))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(statusLabel)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(tint.opacity(0.14), in: Capsule())
                .fixedSize(horizontal: false, vertical: true)

            Text(official.background)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)

            Text(official.pension)
                .font(.caption)
                .fontWeight(drawsPension ? .semibold : .regular)
                .foregroundStyle(drawsPension ? tint : Color.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if !official.sources.isEmpty {
                Text("Sources: " + official.sources.joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .officialsCard(edge: tint)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(official.name), \(officeLine(official)). \(statusLabel).")
    }

    /// Office and party on one line, the way the web page joins them, with the
    /// party dropped when the document does not record one.
    private func officeLine(_ official: OfficialsParityDocument.Official) -> String {
        guard let party = official.party else { return official.office }
        return "\(official.office) · \(party)"
    }
}

private extension View {
    func officialsCard(edge: Color? = nil) -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(alignment: .leading) {
                if let edge {
                    Rectangle()
                        .fill(edge)
                        .frame(width: 4)
                        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                        .padding(.vertical, 6)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(uiColor: .separator).opacity(0.22))
            )
    }
}
