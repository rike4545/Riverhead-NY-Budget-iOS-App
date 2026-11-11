//
//  CandidateWatchView.swift
//  Riverhead NY Budget App
//
//  2026 Town Campaign Candidate Watch — who was on the November 3, 2026 ballot
//  for Riverhead Town office, the unofficial result, each campaign's links and
//  stated platform, sourced from each campaign's own website/social media plus
//  local news coverage. The result mirrors the website's
//  web/lib/election-results-2026.ts; replace both with the certified count when
//  the Suffolk County Board of Elections publishes it.
//
//  Swift 6 / iOS 17+
//

import SwiftUI

struct CandidateWatchCandidate: Identifiable {
    let id = UUID()
    let name: String
    let party: String
    let incumbent: Bool
    let websiteURL: URL?
    let socialMediaLabel: String?
    let socialMediaURL: URL?
    let background: String
    let platform: [String]
    let sources: String
}

enum CandidateWatchData {
    static let electionCalendar: [(label: String, value: String)] = [
        ("Filing Deadline (Major Parties)", "April 6, 2026"),
        ("Filing Deadline (Independents)", "June 15, 2026"),
        ("Filing Deadline (Other Parties)", "July 2026"),
        ("Primary (held)", "June 23, 2026"),
        ("General Election (held)", "November 3, 2026"),
    ]

    /// Unofficial result of the Supervisor race, from the Suffolk County Board of
    /// Elections' election-night results page ("Last Updated" Nov. 4, 2026,
    /// 12:24:42 AM). Not certified; the count can change.
    enum UnofficialResult {
        static let asOf = "November 4, 2026, 12:24 AM"
        struct Row: Identifiable {
            let name: String
            let lines: String
            let votes: Int
            let percent: String
            var id: String { name }
        }
        static let rows: [Row] = [
            .init(name: "Jerry Halpin", lines: "Democratic 6,587 + Taxpayers First 192", votes: 6_779, percent: "52.40%"),
            .init(name: "Ken Rothwell", lines: "Republican 5,264 + Conservative 888", votes: 6_152, percent: "47.55%"),
            .init(name: "Write-in", lines: "", votes: 7, percent: "0.05%"),
        ]
        static let total = 12_938
        static let margin = 627
        static let sourceTitle = "Suffolk County Board of Elections: 2026 General Election results"
        static let sourceURL = URL(string: "https://app.enhancedvoting.com/results/public/suffolk-county-ny/elections/GE2026_20261028145605")!
    }

    static let townSupervisorCandidates: [CandidateWatchCandidate] = [
        .init(
            name: "Jerome (Jerry) Halpin",
            party: "D",
            incumbent: true,
            websiteURL: URL(string: "https://www.votejerryhalpin.com/"),
            socialMediaLabel: "Facebook",
            socialMediaURL: URL(string: "https://www.facebook.com/p/Vote-Jerry-Halpin-61573816546076/"),
            background: "Co-founder and former lead pastor of North Shore Christian Church in Riverhead for about 22 years. Defeated incumbent Tim Hubbard by 37 votes in November 2025, running on opposition to the 2025 budget's 7.89% tax increase.",
            platform: [
                "Keep a tight lid on town spending.",
                "Bring in new tax dollars through economic development rather than raising the levy.",
                "Support businesses and small businesses while maintaining Riverhead's rural character and open space.",
                "Build a stable budget not dependent on over-taxing young adults, working families, and seniors.",
            ],
            sources: "votejerryhalpin.com — campaign website. Riverhead News-Review, “Jerry Halpin secures supervisor nomination from Riverhead Democrats” (Feb. 2026)."
        ),
        .init(
            name: "Kenneth Rothwell",
            party: "R/C",
            incumbent: false,
            websiteURL: URL(string: "https://www.friendsofkenrothwell.com/"),
            socialMediaLabel: "Facebook",
            socialMediaURL: URL(string: "https://www.facebook.com/p/Friends-of-Ken-Rothwell-Riverhead-Town-Council-100065600135011/"),
            background: "Current Town Councilman (appointed Jan. 2021, elected since) and licensed funeral director. Nominated by the Riverhead Republican Committee in February 2026 and also seeking the Conservative Party line. Note: his campaign website still shows content from his prior Town Council races as of this writing, not yet fully updated for the Supervisor race.",
            platform: [
                "Lower the cost of taxes — the campaign's stated top issue.",
                "Make each Town department more self-sustaining to reduce the burden on taxpayers.",
                "Expand clean water access for residents (cites the Manorville clean-water project as a councilman).",
                "Expand veterans programs and continue supporting police and first responders.",
                "Attract high-tech development to build a more sustainable tax base.",
            ],
            sources: "friendsofkenrothwell.com — campaign website. Riverhead News-Review, “Riverhead GOP nominate Kenneth Rothwell for town supervisor” (Feb. 2026)."
        ),
    ]

    static let noRaceNote = "No Town Council seats were on the ballot in November 2026. Bob Kern and Kenneth Rothwell won three-year council terms in the November 2025 election that run through December 31, 2028; Rothwell kept his council seat while running for Supervisor. Joann Waski's and Denise Merrifield's seats are up in 2027."
}

struct CandidateWatchView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("2026 Town Campaign Candidate Watch")
                        .font(.headline)
                    Text("Who was on the November 3, 2026 ballot for Riverhead Town office, the unofficial result, and each candidate's campaign links and stated platform — sourced from each campaign's own website and social media plus local news coverage.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section {
                let r = CandidateWatchData.UnofficialResult.self
                ForEach(r.rows) { row in
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.name)
                                .font(.subheadline.weight(.semibold))
                            if !row.lines.isEmpty {
                                Text(row.lines)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(row.votes.formatted())
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                            Text(row.percent)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
                Text("\(r.total.formatted()) votes in the race. Halpin leads by \(r.margin.formatted()) votes. These numbers are unofficial and can change; the County Board of Elections certifies the final count.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Link(destination: r.sourceURL) {
                    Label(r.sourceTitle, systemImage: "arrow.up.forward.square")
                        .font(.footnote.weight(.semibold))
                }
            } header: {
                Text("Unofficial result, Town Supervisor")
            } footer: {
                Text("As of \(CandidateWatchData.UnofficialResult.asOf). The County lists all 22 election districts as partially reported, and affidavit ballots were not yet counted.")
            }

            Section {
                ForEach(CandidateWatchData.townSupervisorCandidates) { candidate in
                    candidateRow(candidate)
                }
            } header: {
                Text("Town Supervisor")
            } footer: {
                Text("1 seat · \(CandidateWatchData.townSupervisorCandidates.count) candidates · Election Nov 3, 2026")
            }

            Section("Key Dates") {
                ForEach(CandidateWatchData.electionCalendar, id: \.label) { item in
                    HStack {
                        Text(item.label)
                            .font(.footnote)
                        Spacer()
                        Text(item.value)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.brandNavy)
                    }
                }
            }

            Section {
                Text(CandidateWatchData.noRaceNote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Only the Supervisor seat was on this ballot")
            }
        }
        .navigationTitle("Candidate Watch")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Spell out the party code so a reader never has to decode "R/C" or a bare letter.
    private func partyName(_ code: String) -> String {
        switch code {
        case "D": return "Democrat"
        case "R": return "Republican"
        case "R/C": return "Republican · Conservative"
        case "C": return "Conservative"
        default: return code
        }
    }

    @ViewBuilder
    private func candidateRow(_ candidate: CandidateWatchCandidate) -> some View {
        let isDem = candidate.party == "D"
        VStack(alignment: .leading, spacing: 8) {
            Text(candidate.name)
                .font(.headline)
                .foregroundStyle(RiverheadTheme.brandNavy)

            HStack(spacing: 6) {
                Text(candidate.incumbent ? "Incumbent" : "Challenger")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 9).padding(.vertical, 3)
                    .background(candidate.incumbent ? RiverheadTheme.brandNavy : RiverheadTheme.brandNavy.opacity(0.12))
                    .foregroundStyle(candidate.incumbent ? .white : RiverheadTheme.brandNavy)
                    .clipShape(Capsule())
                Text(partyName(candidate.party))
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 9).padding(.vertical, 3)
                    .background((isDem ? Color.blue : Color.red).opacity(0.14))
                    .foregroundStyle(isDem ? Color.blue : Color.red)
                    .clipShape(Capsule())
            }

            HStack(spacing: 14) {
                if let url = candidate.websiteURL {
                    Link(destination: url) {
                        Label("Campaign site", systemImage: "globe")
                            .font(.caption.weight(.semibold))
                    }
                }
                if let url = candidate.socialMediaURL, let label = candidate.socialMediaLabel {
                    Link(destination: url) {
                        Label(label, systemImage: "person.2.fill")
                            .font(.caption.weight(.semibold))
                    }
                }
            }
            .foregroundStyle(RiverheadTheme.accent)

            Text(candidate.background)
                .font(.caption)
                .foregroundStyle(RiverheadTheme.textSecondary)

            Text("What they say they'll do")
                .font(.caption.weight(.bold))
                .padding(.top, 2)
            ForEach(candidate.platform, id: \.self) { line in
                Text("• \(line)")
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)
            }

            Text("Sources: \(candidate.sources)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
        .padding(.vertical, 6)
    }
}
