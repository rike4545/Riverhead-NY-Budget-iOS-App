//
//  TownHistoryParityView.swift
//  Riverhead NY Budget App
//
//  Native parity for Riverhead Budget Live's /town-history/ route.
//
//  Fetched from the web app's published town-history.json rather than restated
//  in Swift, so the roster and its sourcing cannot drift from the web page.
//

import SwiftUI

struct TownHistoryParityDocument: Decodable, Sendable {
    let title: String
    let asOf: String
    let intro: String
    let scopeNote: String
    let supervisors: [Officeholder]
    let councilMembers: [Officeholder]

    struct Officeholder: Decodable, Sendable {
        let name: String
        /// Null in the published data for at least one supervisor whose party
        /// registration could not be sourced. Absent party is not "independent".
        let party: String?
        let termStart: String
        /// Null means still serving. Four council members and one supervisor
        /// carry no end date, so this must not be required.
        let termEnd: String?
        let note: String
        let sources: [String]

        var isServing: Bool { termEnd == nil }
    }
}

enum TownHistoryParityClient {
    static let dataURL = URL(string: "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/data/town-history.json")!
    static let livePageURL = URL(string: "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/town-history/")!

    static func load() async throws -> TownHistoryParityDocument {
        var request = URLRequest(url: dataURL)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(TownHistoryParityDocument.self, from: data)
    }
}

enum TownHistoryFormatting {
    /// Dates arrive as ISO calendar days. Only the year is shown, so this takes
    /// the leading component rather than parsing a Date: a term boundary of
    /// "2010-01-01" is a January 1 swearing-in, and running it through a
    /// time-zone-aware parser is how "today" ended up computed in UTC
    /// elsewhere in this app.
    static func year(_ iso: String) -> String {
        String(iso.prefix(4))
    }

    static func term(start: String, end: String?) -> String {
        guard let end else { return "\(year(start)) – present" }
        return "\(year(start)) – \(year(end))"
    }
}

@MainActor
struct NativeTownHistoryParityView: View {
    @State private var document: TownHistoryParityDocument?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let document {
                content(document)
            } else if loadFailed {
                WebContentView(url: TownHistoryParityClient.livePageURL, title: "Town History")
            } else {
                ProgressView("Loading the sourced roster…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Town History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard document == nil, !loadFailed else { return }
            do {
                document = try await TownHistoryParityClient.load()
            } catch {
                loadFailed = true
            }
        }
    }

    @ViewBuilder
    private func content(_ data: TownHistoryParityDocument) -> some View {
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
                .historyCard()

                // The scope note is the honest part of this page: it says what
                // the roster does not cover. Keeping it prominent rather than
                // burying it matches how the rest of the app treats provenance.
                VStack(alignment: .leading, spacing: 6) {
                    Label("What this roster does and does not cover", systemImage: "info.circle")
                        .font(.subheadline.weight(.semibold))
                    Text(data.scopeNote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .historyCard()

                roster("Supervisors", data.supervisors)
                roster("Council members", data.councilMembers)
            }
            .padding(16)
        }
    }

    private func roster(_ title: String, _ people: [TownHistoryParityDocument.Officeholder]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)

            // Keyed by position: two officeholders can share a name across
            // different terms, and the Sewer Rents collision showed what keying
            // a ForEach on a data field costs when that field repeats.
            ForEach(Array(people.enumerated()), id: \.offset) { index, person in
                if index > 0 { Divider() }
                officeholderRow(person)
            }
        }
        .historyCard()
    }

    private func officeholderRow(_ person: TownHistoryParityDocument.Officeholder) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(person.name)
                    .font(.subheadline.weight(.semibold))
                if let party = person.party {
                    Text(party)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.16), in: Capsule())
                }
                Spacer(minLength: 6)
                Text(TownHistoryFormatting.term(start: person.termStart, end: person.termEnd))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(person.isServing ? Color.accentColor : .secondary)
                    .monospacedDigit()
            }

            Text(person.note)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(person.sources.enumerated()), id: \.offset) { _, source in
                Text(source)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(person.name), \(person.party ?? "party not sourced"), \(TownHistoryFormatting.term(start: person.termStart, end: person.termEnd))")
    }
}

private extension View {
    func historyCard() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(uiColor: .separator).opacity(0.22))
            )
    }
}
