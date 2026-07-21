//
//  BoardElectionsView.swift
//  Riverhead NY Budget App
//
//  How the current Town Board was elected — each member's actual winning vote
//  count against the town's total population and its registered voters. A low
//  share isn't an accusation; it's the normal reality of low-turnout local
//  elections, and a reminder of how few votes decide who controls the budget.
//
//  Swift 6 / iOS 17+
//

import SwiftUI

struct BoardElectionMember: Identifiable {
    let id = UUID()
    let name: String
    let office: String
    let party: String
    let electionLabel: String
    let votes: Int
    let result: String
}

enum BoardElectionsData {
    static let population = 35_902
    static let registeredVoters = 24_217

    static let members: [BoardElectionMember] = [
        .init(name: "Jerome (Jerry) Halpin", office: "Town Supervisor", party: "D",
              electionLabel: "November 2025", votes: 3_958,
              result: "Defeated incumbent Tim Hubbard 3,958 to 3,921 — a 37-vote margin that held through a full manual recount."),
        .init(name: "Robert \"Bob\" Kern", office: "Councilman", party: "R",
              electionLabel: "November 2025", votes: 3_958,
              result: "Re-elected to a three-year term; his 3,958 votes were the highest total in any Riverhead race that year."),
        .init(name: "Kenneth Rothwell", office: "Councilman", party: "R",
              electionLabel: "November 2025", votes: 3_882,
              result: "Re-elected to a three-year term, defeating Democrat Mark Woolley 3,882 to 3,824 — a 58-vote margin."),
        .init(name: "Joann Waski", office: "Councilwoman", party: "R",
              electionLabel: "November 2023", votes: 4_875,
              result: "Won one of two open council seats with 4,875 votes (29.2%) in a four-way race."),
        .init(name: "Denise Merrifield", office: "Councilwoman", party: "R",
              electionLabel: "November 2023", votes: 4_992,
              result: "Top vote-getter for the two open council seats with 4,992 votes (29.9%) in a four-way race."),
    ]

    static let note = "Vote counts are the winning candidate's own total, from the Suffolk County Board of Elections' final certified results (including the 2025 supervisor recount). The registered-voter denominator is the November 2025 figure; the 2023 winners are compared against it as an approximate reference. Percentages are the winner's votes divided by each denominator — not a turnout rate."

    static let sources = "RiverheadLOCAL / Riverhead News-Review 2025 and 2023 election results · Suffolk County Board of Elections, Election Results · U.S. Census Bureau, 2020 Census — Town of Riverhead."
}

struct BoardElectionsView: View {
    private func pct(_ votes: Int, _ denom: Int) -> String {
        (Double(votes) / Double(denom)).formatted(.percent.precision(.fractionLength(1)))
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("How the current Town Board was elected")
                        .font(.headline)
                    Text("How many actual votes put each current board member in office — against the town's total population and its registered voters. A low share isn't an accusation; it's the normal reality of low-turnout local elections.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section {
                HStack {
                    statTile("Town population", "\(BoardElectionsData.population.formatted())", "2020 Census")
                    Spacer()
                    statTile("Registered voters", "\(BoardElectionsData.registeredVoters.formatted())", "Nov 2025")
                }
                Text("The percentages below are each winner's own vote total divided by these denominators — not a turnout rate — showing how small a slice of the whole town chose the people who now control its budget.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("Current board") {
                ForEach(BoardElectionsData.members) { m in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(m.name)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(RiverheadTheme.brandNavy)
                            Spacer()
                            Text(m.electionLabel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Text("\(m.office) · \(m.party)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(alignment: .top, spacing: 18) {
                            voteFigure("\(m.votes.formatted())", "votes to win", big: true)
                            voteFigure(pct(m.votes, BoardElectionsData.population), "of population")
                            voteFigure(pct(m.votes, BoardElectionsData.registeredVoters), "of reg. voters")
                        }
                        .padding(.vertical, 2)

                        Text(m.result)
                            .font(.caption)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                Text(BoardElectionsData.note)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Sources: \(BoardElectionsData.sources)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Board Elections")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statTile(_ label: String, _ value: String, _ sub: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.title3.weight(.bold)).foregroundStyle(RiverheadTheme.brandNavy)
            Text(sub).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func voteFigure(_ value: String, _ label: String, big: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(big ? .title3.weight(.heavy) : .headline.weight(.heavy))
                .foregroundStyle(big ? RiverheadTheme.brandNavy : RiverheadTheme.accent)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
