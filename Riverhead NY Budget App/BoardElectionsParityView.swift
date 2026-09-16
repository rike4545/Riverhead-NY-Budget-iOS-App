import SwiftUI
import Foundation

struct BoardElectionsParityDocument: Decodable, Sendable {
    struct Denominators: Decodable, Sendable {
        let population: Int
        let populationSource: String
        let registeredVoters: Int
        let registeredVotersSource: String
    }

    struct Member: Decodable, Identifiable, Sendable {
        let name: String
        let office: String
        let party: String
        let electionLabel: String
        let votes: Int
        let result: String
        var id: String { "\(name)|\(office)" }
    }

    struct Candidate: Decodable, Identifiable, Sendable {
        let name: String
        let party: String
        let votes: Int
        var id: String { "\(name)|\(party)|\(votes)" }
    }

    struct Race: Decodable, Identifiable, Sendable {
        let office: String
        let seats: Int
        let note: String?
        let winners: [Candidate]
        let runnersUp: [Candidate]
        var id: String { "\(office)|\(seats)" }
    }

    struct PriorElection: Decodable, Identifiable, Sendable {
        let year: Int
        let turnoutNote: String
        let races: [Race]
        var id: Int { year }
    }

    let title: String
    let asOf: String
    let intro: String
    let denominators: Denominators
    let note: String
    let members: [Member]
    let priorElections: [PriorElection]
    let priorElectionsNote: String
    let sources: [String]
}

private enum BoardElectionsParityClient {
    private static let candidates = [
        "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/data/board-elections.json",
        "https://raw.githubusercontent.com/rike4545/Riverhead-NY-Budget-Web-App/main/web/public/data/board-elections.json"
    ]

    static func load() async throws -> BoardElectionsParityDocument {
        var lastError: Error?
        for candidate in candidates {
            guard let url = URL(string: candidate) else { continue }
            do {
                var request = URLRequest(url: url)
                request.cachePolicy = .returnCacheDataElseLoad
                request.timeoutInterval = 20
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      (200..<300).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode(BoardElectionsParityDocument.self, from: data)
            } catch {
                lastError = error
            }
        }
        throw lastError ?? URLError(.cannotLoadFromNetwork)
    }
}

@MainActor
struct NativeBoardElectionsParityView: View {
    @State private var document: BoardElectionsParityDocument?
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var didLoad = false

    var body: some View {
        Group {
            if let document {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 7) {
                            Label("Canonical election record", systemImage: "checkmark.seal.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(RiverheadTheme.brandTeal)
                            Text(document.title)
                                .font(.title3.weight(.bold))
                            Text(document.intro)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    Section("Reference population") {
                        LabeledContent("Town population (2020 Census)", value: document.denominators.population.formatted())
                        LabeledContent("Registered voters (Nov. 2025)", value: document.denominators.registeredVoters.formatted())
                        Text("Each winning vote count is compared with registered voters and total population. Neither percentage is a turnout rate; the population denominator also includes people who cannot vote.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Section("Current Town Board") {
                        ForEach(document.members) { member in
                            VStack(alignment: .leading, spacing: 7) {
                                HStack(alignment: .firstTextBaseline) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(member.name)
                                            .font(.subheadline.weight(.bold))
                                        Text("\(member.office) · \(member.party)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 8)
                                    Text(member.electionLabel)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Text(member.votes.formatted())
                                        .font(.title2.weight(.heavy))
                                    Text("votes won the seat")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Text("\(voteShare(member.votes, denominator: document.denominators.registeredVoters)) of registered voters · \(voteShare(member.votes, denominator: document.denominators.population)) of residents")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(RiverheadTheme.accent)

                                ProgressView(value: Double(member.votes), total: Double(document.denominators.registeredVoters))

                                Text(member.result)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    Section {
                        Text(document.priorElectionsNote)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("Recent general elections")
                    }

                    ForEach(document.priorElections) { election in
                        Section("\(election.year) General Election") {
                            Text(election.turnoutNote)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ForEach(election.races) { race in
                                VStack(alignment: .leading, spacing: 7) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(race.office)
                                            .font(.subheadline.weight(.bold))
                                        Spacer()
                                        Text(race.seats == 1 ? "1 seat" : "\(race.seats) seats")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let note = race.note {
                                        Text(note)
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(RiverheadTheme.accent)
                                    }

                                    let candidates = race.winners.map { ($0, true) } + race.runnersUp.map { ($0, false) }
                                    let maxVotes = candidates.map { $0.0.votes }.max() ?? 1
                                    ForEach(Array(candidates.enumerated()), id: \.offset) { _, item in
                                        candidateRow(item.0, won: item.1, maxVotes: maxVotes)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    Section("What the job legally requires") {
                        NavigationLink {
                            OfficeQualificationsParityView()
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Qualifications, term limits & election timing")
                                        .font(.body.weight(.semibold))
                                    Text("State law, Riverhead Town Code, elected offices, and the odd-year/even-year conflict.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "scroll.fill")
                                    .foregroundStyle(RiverheadTheme.accent)
                            }
                        }
                    }

                    Section("Source & limitations") {
                        Text(document.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(document.denominators.populationSource)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(document.denominators.registeredVotersSource)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        ForEach(document.sources, id: \.self) { source in
                            Text("• \(source)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            } else if isLoading {
                ProgressView("Loading certified election record…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "Election record unavailable",
                    systemImage: "checkmark.rectangle.stack",
                    description: Text(loadError ?? "The canonical board-election dataset could not be loaded.")
                )
            }
        }
        .navigationTitle("Board Elections")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadIfNeeded() }
        .refreshable { await load(force: true) }
    }

    private func candidateRow(_ candidate: BoardElectionsParityDocument.Candidate, won: Bool, maxVotes: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("\(won ? "✓ " : "")\(candidate.name) (\(candidate.party))")
                    .font(.caption.weight(won ? .bold : .regular))
                    .foregroundStyle(won ? RiverheadTheme.textPrimary : .secondary)
                Spacer()
                Text(candidate.votes.formatted())
                    .font(.caption.monospacedDigit().weight(.bold))
            }
            ProgressView(value: Double(candidate.votes), total: Double(maxVotes))
                .tint(won ? RiverheadTheme.accent : .secondary)
        }
    }

    private func voteShare(_ votes: Int, denominator: Int) -> String {
        guard denominator > 0 else { return "—" }
        return (Double(votes) / Double(denominator)).formatted(.percent.precision(.fractionLength(1)))
    }

    private func loadIfNeeded() async {
        guard !didLoad else { return }
        await load(force: false)
    }

    private func load(force: Bool) async {
        guard force || document == nil else { return }
        isLoading = true
        loadError = nil
        do {
            document = try await BoardElectionsParityClient.load()
            didLoad = true
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }
}

private struct OfficeQualificationsParityView: View {
    var body: some View {
        List {
            Section {
                Text("The qualifications are the same for Supervisor and Council members. The statutory floor is intentionally modest; the electorate is effectively the qualification test beyond it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Elected-office requirements") {
                ForEach(OfficeQualifications.electedRequirements) { requirement in
                    requirementRow(requirement)
                }
            }

            Section(OfficeQualifications.electorTitle) {
                Text(OfficeQualifications.electorLede)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                ForEach(OfficeQualifications.electorTests) { test in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(test.label).font(.footnote.weight(.semibold))
                        Text(test.detail).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Text(OfficeQualifications.electorDisqualified).font(.caption).foregroundStyle(.secondary)
                Text(OfficeQualifications.electorNote).font(.caption).foregroundStyle(.secondary)
                Text(OfficeQualifications.electorSources).font(.caption2).foregroundStyle(.secondary)
            }

            Section(OfficeQualifications.notRequiredTitle) {
                ForEach(OfficeQualifications.notRequired, id: \.self) { item in
                    Label(item, systemImage: "xmark")
                        .font(.footnote)
                }
                Text(OfficeQualifications.notRequiredClosing)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(OfficeQualifications.termLimitTitle) {
                Text(OfficeQualifications.termLimitAdopted).font(.caption2).foregroundStyle(.secondary)
                Text(OfficeQualifications.termLimitIntent).font(.footnote)
                Text(OfficeQualifications.termLimitMechanics).font(.footnote).foregroundStyle(.secondary)
                Text(OfficeQualifications.termLimitAuthority).font(.caption).foregroundStyle(.secondary)
            }

            Section(OfficeQualifications.electedOfficesTitle) {
                Text(OfficeQualifications.electedOfficesLede).font(.footnote).foregroundStyle(.secondary)
                Text(OfficeQualifications.electedOffices.joined(separator: " · "))
                    .font(.footnote.weight(.semibold))
                ForEach(OfficeQualifications.codeDecisions) { decision in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(decision.what).font(.footnote.weight(.semibold))
                        Text(decision.detail).font(.caption).foregroundStyle(.secondary)
                        Text(decision.source).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }

            Section(OfficeQualifications.oddYearTitle) {
                ForEach(OfficeQualifications.oddYearBody, id: \.self) { paragraph in
                    Text(paragraph)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section(OfficeQualifications.staffTitle) {
                Text(OfficeQualifications.staffLede).font(.footnote).foregroundStyle(.secondary)
                ForEach(OfficeQualifications.staffRequirements) { requirement in
                    requirementRow(requirement)
                }
                Text(OfficeQualifications.officerVsEmployee).font(.caption).foregroundStyle(.secondary)
            }

            Section("Legal note") {
                Text(OfficeQualifications.disclaimer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Office Qualifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func requirementRow(_ requirement: OfficeRequirement) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                Text(requirement.label).font(.subheadline.weight(.semibold))
                Spacer()
                Text(requirement.value).font(.caption.weight(.bold)).foregroundStyle(RiverheadTheme.accent)
            }
            Text(requirement.detail).font(.caption).foregroundStyle(.secondary)
            Text(requirement.source).font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
