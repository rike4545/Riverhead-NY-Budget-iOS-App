//
//  CouncilScorecardView.swift
//  Riverhead NY Budget App
//
//  Fun, civic-friendly scorecard (non-official).
//  Term dates reflect Even-Year Election Law transition notes; verify with BOE.
//
//  Swift 6 • iOS 17+
//

import SwiftUI

@MainActor
struct CouncilScorecardView: View {

    private struct CouncilMember: Identifiable {
        var id: String { name }
        let name: String
        let role: String
        let grade: String
        let superlative: String
        let highlights: [String]
        let photoURL: URL?
        let termEnds: Date?
        let profileURL: URL?
        let termSourceURL: URL?
        let campaignFinanceURL: URL?
        let campaignCommitteeName: String?
        let campaignFilerID: String?
        let campaignRaised: Double?
        let campaignLastReported: Date?
        let campaignLoanAmount: Double?
        let campaignLoanLastReported: Date?
    }

    private struct UserRating: Codable {
        var grade: String
        var notes: String
    }

    private struct CampaignSnapshot: Codable {
        let committeeName: String?
        let filerID: String?
        let raised: Double?
        let lastReported: Date?
        let loanAmount: Double?
        let loanLastReported: Date?
    }

    private struct RaisedRow: Decodable {
        let filer_id: String
        let total_raised: String?
        let last_reported: String?
    }

    private struct LoanRow: Decodable {
        let filer_id: String
        let loan_amt: String?
        let last_reported_loan: String?
    }

    private enum GradeStyle {
        static func color(for grade: String) -> Color {
            switch grade.uppercased() {
            case "A+", "A", "A-": return .green
            case "B+", "B", "B-": return .blue
            case "C+", "C", "C-": return .orange
            case "D+", "D", "D-", "F": return .red
            default: return .gray
            }
        }
    }

    private let noUserGrade = "Not set"
    private let userGradeOptions = ["A+", "A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D+", "D", "D-", "F"]

    @AppStorage("council_scorecard_user_ratings_json") private var userRatingsJSON: String = ""
    @AppStorage("council_scorecard_fetched_campaign_snapshots_json") private var fetchedSnapshotsJSON: String = ""
    @AppStorage("council_scorecard_previous_campaign_snapshots_json") private var previousSnapshotsJSON: String = ""
    @AppStorage("council_scorecard_filings_last_updated_iso") private var filingsLastUpdatedISO: String = ""

    @State private var userRatings: [String: UserRating] = [:]
    @State private var fetchedCampaignSnapshots: [String: CampaignSnapshot] = [:]
    @State private var previousCampaignSnapshots: [String: CampaignSnapshot] = [:]
    @State private var isUpdatingFilings: Bool = false
    @State private var filingsUpdateStatus: String?
    @State private var filingsLastUpdatedAt: Date?

    private let termFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        return df
    }()

    private let reportDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        return df
    }()

    private let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 2
        return f
    }()

    private let apiDateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private let nyCampaignDisclosureURL = URL(string: "https://publicreporting.elections.ny.gov/CandidateCommitteeDisclosure/CandidateCommitteeDisclosure")!

    private let publicSafetyClipURL = URL(string: "https://www.youtube.com/watch?v=nEkjSoxLW18")!


    private var members: [CouncilMember] {
        [
            .init(
                name: "Honorable Jerome Halpin",
                role: "Riverhead Town Supervisor",
                grade: "B-",
                superlative: "The Budget Referee",
                highlights: [
                    "Track budget alignment with adopted plan",
                    "Transparency and meeting responsiveness",
                    "Supports inventory growth without service strain"
                ],
                photoURL: URL(string: "https://www.townofriverheadny.gov/ImageRepository/Document?documentID=3086"),
                termEnds: makeDate(year: 2026, month: 12, day: 31),
                profileURL: URL(string: "https://www.townofriverheadny.gov/directory.aspx?eid=6"),
                termSourceURL: URL(string: "https://www.townofriverheadny.gov/244/Town-Board"),
                campaignFinanceURL: nyCampaignDisclosureURL,
                campaignCommitteeName: "Friends of Jerry Halpin",
                campaignFilerID: "506796",
                campaignRaised: 12_953.74,
                campaignLastReported: makeDate(year: 2025, month: 11, day: 25),
                campaignLoanAmount: nil,
                campaignLoanLastReported: nil
            ),
            .init(
                name: "Kenneth Rothwell",
                role: "Councilman",
                grade: "C+",
                superlative: "The Process Hawk",
                highlights: [
                    "Clear decision trails on capital projects",
                    "Cost control and procurement discipline",
                    "Housing actions tied to income targets"
                ],
                photoURL: URL(string: "https://www.townofriverheadny.gov/ImageRepository/Document?documentID=186"),
                termEnds: makeDate(year: 2028, month: 12, day: 31),
                profileURL: URL(string: "https://www.townofriverheadny.gov/directory.aspx?eid=13"),
                termSourceURL: URL(string: "https://www.townofriverheadny.gov/244/Town-Board"),
                campaignFinanceURL: nyCampaignDisclosureURL,
                campaignCommitteeName: "Friends of Ken Rothwell",
                campaignFilerID: "154927",
                campaignRaised: 146_423.93,
                campaignLastReported: makeDate(year: 2025, month: 11, day: 24),
                campaignLoanAmount: nil,
                campaignLoanLastReported: nil
            ),
            .init(
                name: "Joann Waski",
                role: "Councilwoman",
                grade: "B-",
                superlative: "The Community Anchor",
                highlights: [
                    "Neighborhood scale and quality",
                    "Constituent access and follow-up",
                    "Housing inventory with affordability guardrails"
                ],
                photoURL: URL(string: "https://www.townofriverheadny.gov/ImageRepository/Document?documentID=195"),
                termEnds: makeDate(year: 2027, month: 12, day: 31),
                profileURL: URL(string: "https://www.townofriverheadny.gov/directory.aspx?eid=14"),
                termSourceURL: URL(string: "https://www.townofriverheadny.gov/244/Town-Board"),
                campaignFinanceURL: nyCampaignDisclosureURL,
                campaignCommitteeName: "Friends of Joann Waski",
                campaignFilerID: "320293",
                campaignRaised: 19_460.00,
                campaignLastReported: makeDate(year: 2024, month: 1, day: 10),
                campaignLoanAmount: nil,
                campaignLoanLastReported: nil
            ),
            .init(
                name: "Robert \"Bob\" Kern",
                role: "Councilman",
                grade: "C",
                superlative: "The Detail Driver",
                highlights: [
                    "Tracks implementation milestones",
                    "Pushes for measurable outcomes",
                    "Focuses on long-horizon capital decisions"
                ],
                photoURL: URL(string: "https://www.townofriverheadny.gov/ImageRepository/Document?documentID=3106"),
                termEnds: makeDate(year: 2028, month: 12, day: 31),
                profileURL: URL(string: "https://www.townofriverheadny.gov/directory.aspx?eid=11"),
                termSourceURL: URL(string: "https://www.townofriverheadny.gov/244/Town-Board"),
                campaignFinanceURL: nyCampaignDisclosureURL,
                campaignCommitteeName: "Friends of Robert Kern",
                campaignFilerID: "527501",
                campaignRaised: 29_385.18,
                campaignLastReported: makeDate(year: 2025, month: 10, day: 14),
                campaignLoanAmount: nil,
                campaignLoanLastReported: nil
            ),
            .init(
                name: "Denise Merrifield",
                role: "Councilwoman",
                grade: "C",
                superlative: "The Community Listener",
                highlights: [
                    "Constituent-oriented policymaking",
                    "Focus on neighborhood quality of life",
                    "Supports practical housing and service planning"
                ],
                photoURL: URL(string: "https://www.townofriverheadny.gov/ImageRepository/Document?documentID=193"),
                termEnds: makeDate(year: 2027, month: 12, day: 31),
                profileURL: URL(string: "https://www.townofriverheadny.gov/directory.aspx?eid=12"),
                termSourceURL: URL(string: "https://www.townofriverheadny.gov/244/Town-Board"),
                campaignFinanceURL: nyCampaignDisclosureURL,
                campaignCommitteeName: "Committee to Elect Denise Merrifield",
                campaignFilerID: "319756",
                campaignRaised: 17_579.75,
                campaignLastReported: makeDate(year: 2023, month: 11, day: 30),
                campaignLoanAmount: nil,
                campaignLoanLastReported: nil
            )
        ]
    }


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                rubricCard
                publicSafetyTaskForceQuestionCard
                ForEach(members) { member in
                    memberCard(member)
                }
                notesCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(RiverheadTheme.Surface.page.ignoresSafeArea())
        .navigationTitle("Council Scorecard")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadUserRatings()
            loadCachedCampaignSnapshots()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Text("Town Council Report Cards")
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Spacer(minLength: 8)

                Button {
                    Task { await updateCampaignFinanceSnapshots() }
                } label: {
                    if isUpdatingFilings {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Label("Update Filings", systemImage: "arrow.clockwise")
                            .labelStyle(.titleAndIcon)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(RiverheadTheme.accent)
                .disabled(isUpdatingFilings)
            }

            Text("A fun, civic-friendly scorecard that highlights policy priorities and public-facing expectations. This is not an official rating.")
                .font(.subheadline)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let status = filingsUpdateStatus {
                Text(status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let last = filingsLastUpdatedAt {
                Text("Filings last updated: \(reportDateFormatter.string(from: last))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var rubricCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How the grades work (fun + simple)")
                .font(.headline)
                .foregroundStyle(RiverheadTheme.textPrimary)

            BulletRow("Budget discipline")
            BulletRow("Transparency and meeting clarity")
            BulletRow("Housing inventory progress")
            BulletRow("Constituent responsiveness")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    private var publicSafetyTaskForceQuestionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Suggested Public Comment Question")
                .font(.headline)
                .foregroundStyle(RiverheadTheme.textPrimary)

            Text("Would the Town Board consider creating a Riverhead Public Safety Task Force, similar to Southold's model, to set clear local protocols for communication, legal support, and resident safety when federal ICE operations occur?")
                .font(.subheadline)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            BulletRow("Who would serve on it (Town Board, Police, schools, legal aid, community groups)?")
            BulletRow("What public reporting cadence and transparency rules would apply?")
            BulletRow("How would civil rights protections and officer role boundaries be documented?")

            NavigationLink {
                WebContentView(url: publicSafetyClipURL, title: "Related Clip")
            } label: {
                Label("Watch Related Clip", systemImage: "play.rectangle.fill")
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    private func memberCard(_ member: CouncilMember) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                if let photoURL = member.photoURL {
                    AsyncImage(url: photoURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color.secondary.opacity(0.15))
                    }
                    .frame(width: 58, height: 58)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 58, height: 58)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(member.name)
                        .font(.headline)
                        .foregroundStyle(RiverheadTheme.textPrimary)
                    Text(member.role)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                gradeTile(
                    title: "App Grade",
                    value: member.grade,
                    color: GradeStyle.color(for: member.grade)
                )

                let userGrade = userRatings[member.name]?.grade ?? noUserGrade
                gradeTile(
                    title: "Your Grade",
                    value: userGrade,
                    color: GradeStyle.color(for: userGrade)
                )
            }

            Text(member.superlative)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RiverheadTheme.accent)

            BulletSection(title: "Scorecard highlights", bullets: member.highlights)

            if let snapshot = campaignSnapshot(for: member),
               let raised = snapshot.raised,
               let reported = snapshot.lastReported {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Campaign Finance Snapshot")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Raised: \(currencyFormatter.string(from: NSNumber(value: raised)) ?? "$0")")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(RiverheadTheme.accent)

                    if let committee = snapshot.committeeName,
                       let filerID = snapshot.filerID {
                        Text("Committee: \(committee) (Filer ID: \(filerID))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Text("Most recently reported contribution date: \(reportDateFormatter.string(from: reported))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if let deltaText = raisedDeltaText(for: member, latest: snapshot) {
                        Text(deltaText)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.accent)
                    }

                    if let loanAmount = snapshot.loanAmount,
                       let loanReported = snapshot.loanLastReported {
                        Text("Candidate loan to campaign: \(currencyFormatter.string(from: NSNumber(value: loanAmount)) ?? "$0") (last reported \(reportDateFormatter.string(from: loanReported)))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Candidate loan to campaign: no loan entries found in NY disclosure data.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.primary.opacity(0.04))
                )
            }

            DisclosureGroup("Your Grade & Notes") {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Your grade", selection: userGradeBinding(for: member)) {
                        Text(noUserGrade).tag(noUserGrade)
                        ForEach(userGradeOptions, id: \.self) { grade in
                            Text(grade).tag(grade)
                        }
                    }
                    .pickerStyle(.menu)

                    Text("Notes")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                    TextEditor(text: userNotesBinding(for: member))
                        .frame(minHeight: 90)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.primary.opacity(0.04))
                        )

                    HStack {
                        Spacer()
                        Button("Clear My Rating") {
                            clearUserRating(for: member)
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.red)
                    }
                }
                .padding(.top, 6)
            }

            HStack(spacing: 12) {
                if let termEnds = member.termEnds {
                    Label("Term ends \(termFormatter.string(from: termEnds))", systemImage: "calendar")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Label("Term end: Not listed", systemImage: "calendar")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                if let profileURL = member.profileURL {
                    Link("Profile", destination: profileURL)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.accent)
                }

                if let termSourceURL = member.termSourceURL {
                    Link("Term source", destination: termSourceURL)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.accent)
                }

                if let campaignFinanceURL = member.campaignFinanceURL {
                    Link("NYS Filings", destination: campaignFinanceURL)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.accent)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(RiverheadTheme.Surface.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(RiverheadTheme.border.opacity(0.25))
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private func gradeTile(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.heavy))
                .foregroundStyle(color)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(color.opacity(0.22), lineWidth: 1)
        )
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
                .foregroundStyle(RiverheadTheme.textPrimary)

            Text("Grades are informal and meant to spark civic discussion. Verify term dates with the Suffolk County Board of Elections. NYS Filings links open the state disclosure search page for candidate/committee records. Use Update Filings to pull current totals and reporting dates from NY Open Data.")
                .font(.subheadline)
                .foregroundStyle(RiverheadTheme.textSecondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    private func userGradeBinding(for member: CouncilMember) -> Binding<String> {
        Binding(
            get: { userRatings[member.name]?.grade ?? noUserGrade },
            set: { newValue in
                var rating = userRatings[member.name] ?? UserRating(grade: noUserGrade, notes: "")
                rating.grade = newValue
                upsertOrRemoveUserRating(rating, for: member.name)
            }
        )
    }

    private func userNotesBinding(for member: CouncilMember) -> Binding<String> {
        Binding(
            get: { userRatings[member.name]?.notes ?? "" },
            set: { newValue in
                var rating = userRatings[member.name] ?? UserRating(grade: noUserGrade, notes: "")
                rating.notes = newValue
                upsertOrRemoveUserRating(rating, for: member.name)
            }
        )
    }

    private func clearUserRating(for member: CouncilMember) {
        userRatings.removeValue(forKey: member.name)
        saveUserRatings()
    }

    private func upsertOrRemoveUserRating(_ rating: UserRating, for memberName: String) {
        let trimmedNotes = rating.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasGrade = rating.grade != noUserGrade

        if !hasGrade && trimmedNotes.isEmpty {
            userRatings.removeValue(forKey: memberName)
        } else {
            userRatings[memberName] = UserRating(grade: rating.grade, notes: trimmedNotes)
        }
        saveUserRatings()
    }

    private func loadUserRatings() {
        guard !userRatingsJSON.isEmpty,
              let data = userRatingsJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: UserRating].self, from: data) else {
            userRatings = [:]
            return
        }
        userRatings = decoded
    }

    private func saveUserRatings() {
        guard let data = try? JSONEncoder().encode(userRatings),
              let json = String(data: data, encoding: .utf8) else {
            return
        }
        userRatingsJSON = json
    }

    private func baselineCampaignSnapshot(for member: CouncilMember) -> CampaignSnapshot? {
        guard member.campaignRaised != nil || member.campaignLastReported != nil else { return nil }
        return CampaignSnapshot(
            committeeName: member.campaignCommitteeName,
            filerID: member.campaignFilerID,
            raised: member.campaignRaised,
            lastReported: member.campaignLastReported,
            loanAmount: member.campaignLoanAmount,
            loanLastReported: member.campaignLoanLastReported
        )
    }

    private func campaignSnapshot(for member: CouncilMember) -> CampaignSnapshot? {
        if let fetched = fetchedCampaignSnapshots[member.id] {
            return fetched
        }
        return baselineCampaignSnapshot(for: member)
    }

    private func parseAPIDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        if let d = apiDateFormatter.date(from: value) { return d }
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        return fallback.date(from: value)
    }

    private func parseAmount(_ value: String?) -> Double? {
        guard let value else { return nil }
        return Double(value)
    }

    private func updateCampaignFinanceSnapshots() async {
        guard !isUpdatingFilings else { return }
        isUpdatingFilings = true
        filingsUpdateStatus = nil
        defer { isUpdatingFilings = false }

        let filerIDs = members.compactMap(\.campaignFilerID)
        guard !filerIDs.isEmpty else {
            filingsUpdateStatus = "No filer IDs configured."
            return
        }

        let inClause = filerIDs.map { "'\($0)'" }.joined(separator: ",")

        let raisedQuery = "$select=filer_id,sum(org_amt) as total_raised,max(sched_date) as last_reported&$where=filer_id in (\(inClause))&$group=filer_id"
        let loanQuery = "$select=filer_id,sum(org_amt) as loan_amt,max(sched_date) as last_reported_loan&$where=filer_id in (\(inClause)) and (lower(filing_sched_desc) like '%loan%' or lower(cntrbn_type_desc) like '%loan%')&$group=filer_id"

        guard let raisedURL = URL(string: "https://data.ny.gov/resource/4j2b-6a2j.json?\(raisedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"),
              let loanURL = URL(string: "https://data.ny.gov/resource/4j2b-6a2j.json?\(loanQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            filingsUpdateStatus = "Could not build filings query URL."
            return
        }

        do {
            async let raisedDataReq = URLSession.shared.data(from: raisedURL)
            async let loanDataReq = URLSession.shared.data(from: loanURL)

            let (raisedData, _) = try await raisedDataReq
            let (loanData, _) = try await loanDataReq

            let raisedRows = try JSONDecoder().decode([RaisedRow].self, from: raisedData)
            let loanRows = try JSONDecoder().decode([LoanRow].self, from: loanData)

            var raisedByFiler: [String: RaisedRow] = [:]
            for row in raisedRows { raisedByFiler[row.filer_id] = row }

            var loanByFiler: [String: LoanRow] = [:]
            for row in loanRows { loanByFiler[row.filer_id] = row }

            var updated: [String: CampaignSnapshot] = [:]
            for member in members {
                guard let fid = member.campaignFilerID else { continue }
                let raisedRow = raisedByFiler[fid]
                let loanRow = loanByFiler[fid]

                let raised = parseAmount(raisedRow?.total_raised) ?? member.campaignRaised
                let reported = parseAPIDate(raisedRow?.last_reported) ?? member.campaignLastReported
                let loanAmt = parseAmount(loanRow?.loan_amt)
                let loanDate = parseAPIDate(loanRow?.last_reported_loan)

                updated[member.id] = CampaignSnapshot(
                    committeeName: member.campaignCommitteeName,
                    filerID: fid,
                    raised: raised,
                    lastReported: reported,
                    loanAmount: loanAmt,
                    loanLastReported: loanDate
                )
            }

            if !fetchedCampaignSnapshots.isEmpty {
                previousCampaignSnapshots = fetchedCampaignSnapshots
            }
            fetchedCampaignSnapshots = updated
            filingsLastUpdatedAt = Date()
            filingsUpdateStatus = "Campaign filings updated from NY Open Data."
            persistCampaignSnapshots()
        } catch {
            filingsUpdateStatus = "Update failed: \(error.localizedDescription)"
        }
    }

    private func previousSnapshot(for member: CouncilMember) -> CampaignSnapshot? {
        previousCampaignSnapshots[member.id]
    }

    private func raisedDeltaText(for member: CouncilMember, latest: CampaignSnapshot) -> String? {
        guard let prior = previousSnapshot(for: member),
              let latestRaised = latest.raised,
              let priorRaised = prior.raised else {
            return nil
        }

        let delta = latestRaised - priorRaised
        let formatted = currencyFormatter.string(from: NSNumber(value: abs(delta))) ?? "$0"
        if abs(delta) < 0.005 {
            return "Since last update: no change in raised total."
        }
        let direction = delta > 0 ? "+" : "-"
        return "Since last update: \(direction)\(formatted) in raised total."
    }

    private func loadCachedCampaignSnapshots() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let data = fetchedSnapshotsJSON.data(using: .utf8),
           let decoded = try? decoder.decode([String: CampaignSnapshot].self, from: data) {
            fetchedCampaignSnapshots = decoded
        }

        if let data = previousSnapshotsJSON.data(using: .utf8),
           let decoded = try? decoder.decode([String: CampaignSnapshot].self, from: data) {
            previousCampaignSnapshots = decoded
        }

        if !filingsLastUpdatedISO.isEmpty {
            let iso = ISO8601DateFormatter()
            filingsLastUpdatedAt = iso.date(from: filingsLastUpdatedISO)
        }
    }

    private func persistCampaignSnapshots() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(fetchedCampaignSnapshots),
           let json = String(data: data, encoding: .utf8) {
            fetchedSnapshotsJSON = json
        }

        if let data = try? encoder.encode(previousCampaignSnapshots),
           let json = String(data: data, encoding: .utf8) {
            previousSnapshotsJSON = json
        }

        if let last = filingsLastUpdatedAt {
            filingsLastUpdatedISO = ISO8601DateFormatter().string(from: last)
        }
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        let comps = DateComponents(year: year, month: month, day: day)
        return Calendar.current.date(from: comps) ?? Date()
    }
}

private struct BulletRow: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.secondary.opacity(0.6))
                .frame(width: 5, height: 5)
                .padding(.top, 7)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct BulletSection: View {
    let title: String
    let bullets: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.secondary.opacity(0.6))
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)

                        Text(bullet)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}
