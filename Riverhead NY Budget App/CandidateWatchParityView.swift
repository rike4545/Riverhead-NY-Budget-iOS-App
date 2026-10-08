//
//  CandidateWatchParityView.swift
//  Riverhead NY Budget App
//
//  Native parity for Riverhead Budget Live's /candidate-watch/ route.
//
//  Fetched from the published candidate-watch.json rather than restated in
//  Swift. This page carries what named candidates say they will do, during a
//  live election; a stale copy would misrepresent them.
//

import SwiftUI

struct CandidateWatchParityDocument: Decodable, Sendable {
    let title: String
    let asOf: String
    let intro: String
    let electionCalendar: ElectionCalendar
    /// Decoded but not rendered, because the web page does not render it
    /// either: it describes a bold/asterisk convention that was never
    /// implemented there. Kept in the model so the document round-trips, and so
    /// the omission is a visible decision rather than an oversight.
    let legend: Legend
    let races: [Race]
    let noRaceNote: String

    struct ElectionCalendar: Decodable, Sendable {
        let filingDeadlineMajorParties: String
        let filingDeadlineIndependents: String
        let filingDeadlineOtherParties: String
        let primary: String
        let generalElection: String
    }

    struct Legend: Decodable, Sendable {
        let bold: String
        let asterisk: String
        let note: String
    }

    struct Race: Decodable, Sendable {
        let office: String
        let candidates: [Candidate]
    }

    struct Candidate: Decodable, Sendable {
        let name: String
        /// The ballot line: "D", "R/C".
        let party: String
        /// Present on one of the two candidates in the published file. The web
        /// page's own TypeScript type omits it and casts it back as
        /// `(c as { partyLabel?: string }).partyLabel ?? p.name`, so optional
        /// with a fallback is the documented contract, not a guess.
        ///
        /// It matters: one candidate's label reads "Democratic line · not
        /// enrolled in a party". Flattening that to "Democrat" would state
        /// something about a real person that the source deliberately does not.
        let partyLabel: String?
        let incumbent: Bool
        /// In the data, unused by the web page. Both candidates are currently
        /// active, so rendering it would draw a distinction the source does not.
        let active: Bool
        let website: String
        let socialMedia: [SocialLink]
        let background: String
        let platform: [String]
        let sources: [String]

        struct SocialLink: Decodable, Sendable {
            let platform: String
            let url: String
        }

        /// What the reader should see on the party badge: the candidate's own
        /// label when the document carries one, otherwise the ballot code
        /// spelled out.
        var partyDisplay: String {
            partyLabel ?? CandidateParty.spelledOut(party)
        }
    }
}

enum CandidateParty {
    /// Mirrors the PARTY map in the web page's markup, which is not in the
    /// JSON and so will not follow an edit on the web side. Carried anyway
    /// because a reader should not have to decode "R/C", and an unrecognised
    /// code shows as itself rather than being dropped — the same fallback the
    /// web page takes.
    static func spelledOut(_ code: String) -> String {
        switch code {
        case "D": return "Democrat"
        case "R": return "Republican"
        case "R/C": return "Republican · Conservative"
        case "C": return "Conservative"
        default: return code
        }
    }

    static func tint(_ code: String) -> Color {
        switch code {
        case "D": return .blue
        case "R", "R/C": return .red
        case "C": return .orange
        default: return .secondary
        }
    }
}

enum CandidateWatchParityClient {
    static let dataURL = URL(string: "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/data/candidate-watch.json")!
    static let livePageURL = URL(string: "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/candidate-watch/")!
    static let costBenefitURL = URL(string: "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/candidate-cost-benefit/")!

    static func load() async throws -> CandidateWatchParityDocument {
        var request = URLRequest(url: dataURL)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(CandidateWatchParityDocument.self, from: data)
    }
}

@MainActor
struct NativeCandidateWatchParityView: View {
    @State private var document: CandidateWatchParityDocument?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let document {
                content(document)
            } else if loadFailed {
                WebContentView(url: CandidateWatchParityClient.livePageURL, title: "Candidate Watch")
            } else {
                ProgressView("Loading the candidate roster…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Candidate Watch")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard document == nil, !loadFailed else { return }
            do {
                document = try await CandidateWatchParityClient.load()
            } catch {
                loadFailed = true
            }
        }
    }

    @ViewBuilder
    private func content(_ data: CandidateWatchParityDocument) -> some View {
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
                .riverheadCard()

                // The web page leads with this pointer, and it earns the space:
                // this route is each candidate in their own words, which is not
                // the same thing as an even-handed look at what the promises
                // would cost. Kept in-app rather than opening Safari.
                NavigationLink {
                    WebContentView(
                        url: CandidateWatchParityClient.costBenefitURL,
                        title: "Candidate Proposals"
                    )
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Want the numbers behind the promises?", systemImage: "scale.3d")
                            .font(.subheadline.weight(.semibold))
                        Text("This page is each candidate in their own words. Candidate Proposals weighs every plank for cost and benefit.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .buttonStyle(.plain)
                .riverheadCard(accentEdge: RiverheadTheme.brandTeal)

                ForEach(Array(data.races.enumerated()), id: \.offset) { _, race in
                    raceSection(race, calendar: data.electionCalendar)
                }

                keyDates(data.electionCalendar)

                VStack(alignment: .leading, spacing: 6) {
                    Text("**Only the Supervisor seat is on this ballot.** \(data.noRaceNote)")
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .riverheadCard(accentEdge: .orange)
            }
            .padding(16)
        }
    }

    private func raceSection(
        _ race: CandidateWatchParityDocument.Race,
        calendar: CandidateWatchParityDocument.ElectionCalendar
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(race.office).font(.headline)
                // The web page also prints "1 seat" here, hardcoded in its
                // markup. The document carries no seat count, so asserting one
                // would be inventing it — a two-seat council race would print
                // the wrong number. The election date is read from the
                // calendar rather than hardcoded, for the same reason.
                Text("\(race.candidates.count) candidates · Election \(calendar.generalElection)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            // Document order is meaningful: the legend records that the
            // incumbent's party is listed first. Never sorted.
            ForEach(Array(race.candidates.enumerated()), id: \.offset) { _, candidate in
                candidateCard(candidate)
            }
        }
    }

    private func candidateCard(_ candidate: CandidateWatchParityDocument.Candidate) -> some View {
        let tint = CandidateParty.tint(candidate.party)

        return VStack(alignment: .leading, spacing: 8) {
            Text(candidate.name)
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                badge(candidate.incumbent ? "Incumbent" : "Challenger",
                      tint: RiverheadTheme.accent,
                      filled: candidate.incumbent)
                badge(candidate.partyDisplay, tint: tint, filled: false)
            }

            HStack(spacing: 8) {
                if let site = URL(string: candidate.website) {
                    Link(destination: site) {
                        Label("Campaign site", systemImage: "link")
                            .font(.caption.weight(.semibold))
                    }
                }
                ForEach(Array(candidate.socialMedia.enumerated()), id: \.offset) { _, social in
                    if let url = URL(string: social.url) {
                        Link(destination: url) {
                            Text(social.platform)
                                .font(.caption.weight(.semibold))
                        }
                    }
                }
            }

            Text(candidate.background)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)

            Text("What they say they'll do")
                .font(.caption.weight(.bold))
                .padding(.top, 2)

            ForEach(Array(candidate.platform.enumerated()), id: \.offset) { _, plank in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("•").foregroundStyle(.secondary)
                    Text(plank)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !candidate.sources.isEmpty {
                Text("Sources: " + candidate.sources.joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .riverheadCard(accentEdge: tint)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(candidate.name), \(candidate.incumbent ? "incumbent" : "challenger"), \(candidate.partyDisplay)")
    }

    private func badge(_ text: String, tint: Color, filled: Bool) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(filled ? Color.white : tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(filled ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.14)), in: Capsule())
            .fixedSize(horizontal: false, vertical: true)
    }

    private func keyDates(_ calendar: CandidateWatchParityDocument.ElectionCalendar) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Key dates").font(.headline)
            dateRow("General election", calendar.generalElection, highlight: true)
            dateRow("Primary (held)", calendar.primary)
            dateRow("Filing — major parties", calendar.filingDeadlineMajorParties)
            dateRow("Filing — independents", calendar.filingDeadlineIndependents)
            dateRow("Filing — other parties", calendar.filingDeadlineOtherParties)
        }
        .riverheadCard()
    }

    private func dateRow(_ label: String, _ value: String, highlight: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.caption.weight(highlight ? .bold : .semibold))
                .foregroundStyle(highlight ? RiverheadTheme.accent : .primary)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
