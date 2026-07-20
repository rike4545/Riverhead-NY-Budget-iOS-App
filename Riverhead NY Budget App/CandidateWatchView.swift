//
//  CandidateWatchView.swift
//  Riverhead NY Budget App
//
//  2026 Town Campaign Candidate Watch — who's running for Riverhead Town
//  office in the November 2026 general election, their campaign links, and
//  their stated platforms, sourced from each campaign's own website/social
//  media plus local news coverage.
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
        ("Primary", "June 23, 2026"),
        ("General Election", "November 3, 2026"),
    ]

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

    static let noRaceNote = "No Town Council seats are on the ballot in November 2026. Bob Kern and Kenneth Rothwell won three-year council terms in the November 2025 election that run through December 31, 2028 — Rothwell's council seat doesn't expire this cycle even though he's running for Supervisor, so it would need to be filled separately (by appointment or special election) if he wins. Joann Waski and Denise Merrifield's seats aren't up until 2027."
}

struct CandidateWatchView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("2026 Town Campaign Candidate Watch")
                        .font(.headline)
                    Text("Who's running for Riverhead Town office in the November 2026 general election, their campaign links, and their stated platforms — sourced from each campaign's own website and social media plus local news coverage.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Election Calendar") {
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

            Section("Page Legend") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("**Bold** = Active Candidate · * = Incumbent")
                        .font(.footnote)
                    Text("Incumbent party listed first.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }

            Section("Town Supervisor") {
                ForEach(CandidateWatchData.townSupervisorCandidates) { candidate in
                    candidateRow(candidate)
                }
            }

            Section {
                Text(CandidateWatchData.noRaceNote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Why there's only one race")
            }
        }
        .navigationTitle("Candidate Watch")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func candidateRow(_ candidate: CandidateWatchCandidate) -> some View {
        let nameLine = "\(candidate.name)\(candidate.incumbent ? " *" : "")"
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(nameLine)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RiverheadTheme.brandNavy)
                Text("· \(candidate.party)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                if let url = candidate.websiteURL {
                    Link(destination: url) {
                        Label("Website", systemImage: "globe")
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

            Text("Stated platform:")
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
