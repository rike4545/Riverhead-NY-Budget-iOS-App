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
    @Environment(\.colorScheme) private var scheme

    private struct CouncilMember: Identifiable {
        var id: String { name }
        let name: String
        let role: String
        let responsibilitySummary: String?
        let grade: String
        let superlative: String
        let highlights: [String]
        var scores: [AccountabilityScore] = []
        var evidence: [EvidenceItem] = []
        var residentActions: [String] = []
        var followUpFlags: [String] = []
        var candidateContext: CandidateContext? = nil
        let photoURL: URL?
        let serviceStarted: Date?
        let termStarts: Date?
        let termEnds: Date?
        let nextElection: Date?
        let annualPay: Double?
        let committeeLiaisons: [String]
        let profileURL: URL?
        let termSourceURL: URL?
        let campaignFinanceURL: URL?
        let campaignCommitteeName: String?
        let campaignFilerID: String?
        let additionalCampaignFilings: [CampaignFilingRef]
        let campaignFilingNote: String?
        let campaignRaised: Double?
        let campaignDirectContributions: Double?
        let campaignTransfersIn: Double?
        let campaignLastReported: Date?
        let campaignLoanAmount: Double?
        let campaignLoanLastReported: Date?
    }

    private enum ScoreCategory: String, CaseIterable, Identifiable {
        case budget = "Budget"
        case transparency = "Transparency"
        case housing = "Housing"
        case responsiveness = "Response"
        case ethics = "Ethics"
        case capital = "Capital"

        var id: String { rawValue }

        var title: String {
            switch self {
            case .budget: return "Budget discipline"
            case .transparency: return "Transparency"
            case .housing: return "Housing progress"
            case .responsiveness: return "Resident response"
            case .ethics: return "Ethics/disclosure"
            case .capital: return "Capital planning"
            }
        }

        var icon: String {
            switch self {
            case .budget: return "dollarsign.circle"
            case .transparency: return "eye"
            case .housing: return "house"
            case .responsiveness: return "person.wave.2"
            case .ethics: return "checkmark.shield"
            case .capital: return "wrench.and.screwdriver"
            }
        }
    }

    private struct AccountabilityScore: Identifiable {
        var id: ScoreCategory { category }
        let category: ScoreCategory
        let value: Double
        let note: String
    }

    private struct EvidenceItem: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let sourceLabel: String?
        let sourceURL: URL?
    }

    private struct CandidateContext {
        let title: String
        let summary: String
        let bullets: [String]
    }

    private struct CampaignFilingRef: Codable, Hashable {
        let committeeName: String
        let filerID: String
        let note: String?
    }

    private struct UserRating: Codable {
        var grade: String
        var notes: String
    }

    private struct CampaignSnapshot: Codable {
        let committeeName: String?
        let filerID: String?
        let filingDetails: [CampaignFilingSnapshot]?
        let raised: Double?
        let directContributions: Double?
        let transfersIn: Double?
        let currentYearDirectContributions: Double?
        let currentYearTransfersIn: Double?
        let currentYearFilingActivityAmount: Double?
        let currentYearFilingActivityRowCount: Int?
        let currentYearFilingActivitySchedules: String?
        let currentYearLastReported: Date?
        // 2026-only slice
        let latestYearDirect: Double?
        let latestYearTransfers: Double?
        let latestYearFilingAmount: Double?
        let latestYearRowCount: Int?
        let latestYearSchedules: String?
        let latestYearLastReported: Date?
        let largestIndividualContribution: TopContribution?
        let largestBusinessContribution: TopContribution?
        let petrocelliContributions: [TopContribution]?
        let scottPointeContributions: [TopContribution]?
        let familyLinkedContributions: [TopContribution]?
        let candidateFamilyLoans: [TopContribution]?
        let lastReported: Date?
        let loanAmount: Double?
        let loanLastReported: Date?
        let filingEvents: [CampaignFilingEvent]?
        let donorCount: Int?
        let avgDonationPerDonor: Double?
        let contributorTypeBreakdown: [ContributorTypeAmount]?
        let outstandingLoanAmount: Double?
        let outstandingLoanYear: String?
        /// Direct contributions by election year, most recent first, excluding the current cycle.
        let historicalByYear: [YearBreakdown]?
    }

    private struct YearBreakdown: Codable {
        let year: String
        let raised: Double
        let donorCount: Int
        let avgDonationPerDonor: Double?
        let typeBreakdown: [ContributorTypeAmount]
    }

    // A single filing SUBMISSION (e.g. "January Periodic, Original, Itemized, State/Local"),
    // as opposed to an individual itemized transaction inside it. The bulk Open Data feed has
    // no "date filed" timestamp — only sched_date per transaction, which for a recurring
    // liability (an outstanding loan re-reported every period) can carry a stale original
    // date. lastActivity is the latest transaction date found in that filing, not a
    // submission date.
    private struct CampaignFilingEvent: Codable, Identifiable {
        var id: String { "\(filerID)|\(electionYear)|\(filingDesc)|\(isAmendment)" }
        let filerID: String
        let committeeName: String
        let electionYear: String
        let filingDesc: String
        let isAmendment: Bool
        let category: String
        let electionType: String
        let amount: Double
        let transactionCount: Int
        let lastActivity: Date?
    }

    // A Town payroll employee whose name matches an individual campaign donor to one of the
    // tracked committees. Disclosure context, not an accusation — modest personal donations
    // from Town employees to sitting or former officials are common and legal. Matched by
    // normalized (last, first) name only, so a shared name with a different person is
    // possible and not verified beyond the name match itself.
    private struct EmployeeDonorMatch: Identifiable {
        var id: String { "\(employeeName)|\(officialName)|\(electionYear)|\(filingDesc)|\(amount)" }
        let employeeName: String
        let department: String?
        let title: String?
        let officialName: String
        let committeeName: String
        let electionYear: String
        let filingDesc: String
        let amount: Double
        let date: Date?
    }

    private struct CampaignFilingSnapshot: Codable {
        let committeeName: String
        let filerID: String
        let raised: Double?
        let directContributions: Double?
        let transfersIn: Double?
        let lastReported: Date?
    }

    private struct TopContribution: Codable {
        let donorName: String
        let amount: Double
        let date: Date?
        let contributorType: String?
        let schedule: String?
        let filingLabel: String?
    }

    private struct ContributorTypeAmount: Codable {
        let type: String
        let amount: Double
        let donorCount: Int
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

    /// Schedule N (Outstanding Liabilities/Loans) grouped by election_year — its sched_date
    /// carries the loan's ORIGINAL transaction date forward on every re-report, so the only
    /// reliable way to find "the latest reported balance" is the highest election_year, not date.
    private struct OutstandingLoanRow: Decodable {
        let filer_id: String
        let election_year: String?
        let amount: String?
    }

    private struct LoanDetailRow: Decodable {
        let filer_id: String
        let election_year: String?
        let filing_abbrev: String?
        let filing_desc: String?
        let filing_sched_abbrev: String?
        let filing_sched_desc: String?
        let cntrbr_type_desc: String?
        let flng_ent_name: String?
        let flng_ent_first_name: String?
        let flng_ent_middle_name: String?
        let flng_ent_last_name: String?
        let org_amt: String?
        let owed_amt: String?
        let sched_date: String?
        let loan_lib_number: String?
        let loan_other_desc: String?
    }

    private struct ScheduleBreakdownRow: Decodable {
        let filer_id: String
        let election_year: String?
        let filing_abbrev: String?
        let filing_desc: String?
        let filing_sched_abbrev: String?
        let amount: String?
        let last_reported: String?
        let row_count: String?
    }

    private struct FilingEventRow: Decodable {
        let filer_id: String
        let election_year: String?
        let filing_desc: String?
        let r_amend: String?
        let filing_cat_desc: String?
        let election_type: String?
        let amount: String?
        let row_count: String?
        let last_activity: String?
    }

    private struct ContributionRow: Decodable {
        let filer_id: String
        let election_year: String?
        let filing_abbrev: String?
        let filing_desc: String?
        let filing_sched_abbrev: String?
        let filing_sched_desc: String?
        let cntrbr_type_desc: String?
        let flng_ent_name: String?
        let flng_ent_first_name: String?
        let flng_ent_middle_name: String?
        let flng_ent_last_name: String?
        let org_amt: String?
        let sched_date: String?
    }

    private struct SocrataError: Decodable {
        let message: String?
        let error: Bool?
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
    private let campaignFilingStartYear = 2005
    private let campaignFilingEndYear = 2026
    private var campaignFilingYearRangeLabel: String {
        "\(campaignFilingStartYear)-Present (\(campaignFilingEndYear))"
    }
    private var campaignFilingYearWhereClause: String {
        let years = (campaignFilingStartYear...campaignFilingEndYear)
            .map { "'\($0)'" }
            .joined(separator: ",")
        return "election_year in(\(years))"
    }
    private let currentDate = Date()

    private struct FilingDeadline {
        let label: String
        let dateLabel: String
        let date: Date
        let periodNote: String
    }

    // NY State Board of Elections 2026 filing calendar (State/Local candidates), source:
    // https://elections.ny.gov/system/files/documents/2025/12/2026-filing-calendar-12112025-approved.secure.accessible.pdf
    private var nyFilingDeadlines2026: [FilingDeadline] {
        let entries: [(String, String, String)] = [
            ("July Periodic Report", "2026-07-15", "activity Jan 12 – Jul 11"),
            ("32-Day Pre-General Report", "2026-10-02", "period ends Sep 28"),
            ("11-Day Pre-General Report", "2026-10-23", "period ends Oct 19"),
            ("General Election Day", "2026-11-03", "Election Day, not a filing deadline"),
            ("27-Day Post-General Report", "2026-11-30", "period ends Nov 26"),
        ]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        return entries.compactMap { label, dateString, note in
            guard let date = formatter.date(from: "\(dateString) 23:59:59") else { return nil }
            return FilingDeadline(label: label, dateLabel: dateString, date: date, periodNote: note)
        }
    }

    private var nextFilingDeadline: FilingDeadline? {
        nyFilingDeadlines2026
            .filter { $0.date >= currentDate }
            .min { $0.date < $1.date }
    }

    @AppStorage("council_scorecard_user_ratings_json") private var userRatingsJSON: String = ""
    @AppStorage("council_scorecard_fetched_campaign_snapshots_json") private var fetchedSnapshotsJSON: String = ""
    @AppStorage("council_scorecard_previous_campaign_snapshots_json") private var previousSnapshotsJSON: String = ""
    @AppStorage("council_scorecard_filings_last_updated_iso") private var filingsLastUpdatedISO: String = ""
    @AppStorage("council_scorecard_weight_budget") private var budgetWeight: Double = 1
    @AppStorage("council_scorecard_weight_transparency") private var transparencyWeight: Double = 1
    @AppStorage("council_scorecard_weight_housing") private var housingWeight: Double = 1
    @AppStorage("council_scorecard_weight_response") private var responseWeight: Double = 1
    @AppStorage("council_scorecard_weight_ethics") private var ethicsWeight: Double = 1
    @AppStorage("council_scorecard_weight_capital") private var capitalWeight: Double = 1

    @State private var userRatings: [String: UserRating] = [:]
    @State private var fetchedCampaignSnapshots: [String: CampaignSnapshot] = [:]
    @State private var previousCampaignSnapshots: [String: CampaignSnapshot] = [:]
    @State private var isUpdatingFilings: Bool = false
    @State private var filingsUpdateStatus: String?
    @State private var employeeDonorMatches: [EmployeeDonorMatch] = []
    @State private var filingsLastUpdatedAt: Date?
    @State private var campaignFilingSearchText: String = ""

    private let termFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        return df
    }()

    private let termYearFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy"
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

    private let apiDateFormatterNoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private let apiDateWithoutTimeZoneFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return df
    }()

    private let nyCampaignDisclosureURL = URL(string: "https://publicreporting.elections.ny.gov/CandidateCommitteeDisclosure/CandidateCommitteeDisclosure")!

    private let townBoardURL = URL(string: "https://www.townofriverheadny.gov/244/Town-Board")!

    private let townHallCommitteesURL = URL(string: "https://www.townofriverheadny.gov/240/Town-Hall-Committees")!

    private let evenYearElectionStatusURL = URL(string: "https://riverheadlocal.com/2026/05/12/federal-judge-delays-conference-in-even-year-elections-lawsuit/")!

    private let evenYearTransitionGuidanceURL = URL(string: "https://elections.ny.gov/even-years-election-transition-guidance")!

    private let publicSafetyClipURL = URL(string: "https://www.youtube.com/watch?v=nEkjSoxLW18")!

    private let oscEAOfficialsRegulationURL = URL(string: "https://www.osc.ny.gov/retirement/employers/reporting-ea-officials/about-regulation")!

    private let oscEAOfficialsROAURL = URL(string: "https://www.osc.ny.gov/retirement/employers/reporting-ea-officials/record-activities-roa")!

    private let oscEAOfficialsMemberOverviewURL = URL(string: "https://www.osc.ny.gov/retirement/members/ea-officials/overview")!

    private let oscServiceCreditURL = URL(string: "https://www.osc.ny.gov/retirement/publications/service-credit-tiers-2-through-6#earning")!

    private let oscHiringPublicRetireesURL = URL(string: "https://www.osc.ny.gov/retirement/employers/when-employees-retire/hiring-public-retirees")!

    private let seeThroughNYURL = URL(string: "https://www.seethroughny.net/")!

    private var allTrackedMembers: [CouncilMember] {
        members + formerMembers
    }

    private var visibleCampaignSnapshots: [(member: CouncilMember, snapshot: CampaignSnapshot)] {
        allTrackedMembers.compactMap { member in
            guard let snapshot = campaignSnapshot(for: member) else { return nil }
            return (member, snapshot)
        }
    }

    private var totalDirectFundraising: Double {
        visibleCampaignSnapshots.reduce(0) { total, item in
            total + (item.snapshot.directContributions ?? item.snapshot.raised ?? 0)
        }
    }

    private var totalTransfersIn: Double {
        visibleCampaignSnapshots.reduce(0) { total, item in
            total + (item.snapshot.transfersIn ?? 0)
        }
    }

    private var totalPetroCelliDonations: Double {
        visibleCampaignSnapshots.reduce(0) { total, item in
            let contributions = item.snapshot.petrocelliContributions ?? []
            return total + contributions.reduce(0) { $0 + $1.amount }
        }
    }

    private var petrocelliDonationBreakdown: [(name: String, amount: Double)] {
        visibleCampaignSnapshots.compactMap { item in
            let contributions = item.snapshot.petrocelliContributions ?? []
            let total = contributions.reduce(0) { $0 + $1.amount }
            guard total > 0 else { return nil }
            return (name: item.member.name, amount: total)
        }.sorted { $0.amount > $1.amount }
    }

    private var topDirectFundraiser: (member: CouncilMember, amount: Double)? {
        visibleCampaignSnapshots
            .map { (member: $0.member, amount: $0.snapshot.directContributions ?? $0.snapshot.raised ?? 0) }
            .max { $0.amount < $1.amount }
    }

    private var weightSummary: String {
        let weights = ScoreCategory.allCases.map { "\($0.rawValue) \(String(format: "%.1f", weight(for: $0)))x" }
        return weights.joined(separator: " | ")
    }

    private var townBoardSource: EvidenceItem {
        EvidenceItem(
            title: "Official seat and term source",
            detail: "Town profile and term links are used for office context; the scorecard still asks residents to verify final calendars with BOE.",
            sourceLabel: "Town Board",
            sourceURL: townBoardURL
        )
    }

    private func scoreSet(
        budget: Double,
        transparency: Double,
        housing: Double,
        responsiveness: Double,
        ethics: Double,
        capital: Double
    ) -> [AccountabilityScore] {
        [
            AccountabilityScore(category: .budget, value: budget, note: "Budget choices, tax pressure, and recurring-balance discipline."),
            AccountabilityScore(category: .transparency, value: transparency, note: "Meeting clarity, decision trail, and source visibility."),
            AccountabilityScore(category: .housing, value: housing, note: "Housing supply progress tied to affordability and service capacity."),
            AccountabilityScore(category: .responsiveness, value: responsiveness, note: "Constituent access, follow-up, and public-facing communication."),
            AccountabilityScore(category: .ethics, value: ethics, note: "Disclosure hygiene, campaign-finance context, and conflict handling."),
            AccountabilityScore(category: .capital, value: capital, note: "Long-term infrastructure, project phasing, and implementation follow-through.")
        ]
    }

    private func weight(for category: ScoreCategory) -> Double {
        switch category {
        case .budget: return budgetWeight
        case .transparency: return transparencyWeight
        case .housing: return housingWeight
        case .responsiveness: return responseWeight
        case .ethics: return ethicsWeight
        case .capital: return capitalWeight
        }
    }

    private func weightedScore(for member: CouncilMember) -> Double {
        let weighted = member.scores.reduce(into: (total: 0.0, weight: 0.0)) { result, score in
            let categoryWeight = weight(for: score.category)
            result.total += score.value * categoryWeight
            result.weight += categoryWeight
        }
        return weighted.weight > 0 ? weighted.total / weighted.weight : 0
    }

    private func grade(for score: Double) -> String {
        switch score {
        case 93...: return "A"
        case 90..<93: return "A-"
        case 87..<90: return "B+"
        case 83..<87: return "B"
        case 80..<83: return "B-"
        case 77..<80: return "C+"
        case 73..<77: return "C"
        case 70..<73: return "C-"
        case 67..<70: return "D+"
        case 63..<67: return "D"
        default: return "F"
        }
    }

    private var members: [CouncilMember] {
        [
            .init(
                name: "Honorable Jerome Halpin",
                role: "Riverhead Town Supervisor",
                responsibilitySummary: "Chief Executive Officer, Police Commissioner, Chief Financial Officer, Chairperson of the Town Board, and responsible for Riverhead Town's day-to-day operations.",
                grade: "B-",
                superlative: "The Budget Referee",
                highlights: [
                    "Track budget alignment with adopted plan",
                    "Transparency and meeting responsiveness",
                    "Supports inventory growth without service strain"
                ],
                photoURL: URL(string: "https://www.townofriverheadny.gov/ImageRepository/Document?documentID=3086"),
                serviceStarted: makeDate(year: 2026, month: 1, day: 1),
                termStarts: makeDate(year: 2026, month: 1, day: 1),
                termEnds: makeDate(year: 2026, month: 12, day: 31),
                nextElection: makeDate(year: 2026, month: 11, day: 3),
                annualPay: 110_000,
                committeeLiaisons: [
                    "Personnel"
                ],
                profileURL: URL(string: "https://www.townofriverheadny.gov/directory.aspx?eid=6"),
                termSourceURL: URL(string: "https://www.townofriverheadny.gov/244/Town-Board"),
                campaignFinanceURL: nyCampaignDisclosureURL,
                campaignCommitteeName: "Friends of Jerry Halpin",
                campaignFilerID: "506796",
                additionalCampaignFilings: [],
                campaignFilingNote: "COMMCAND fields: candidate ID 506792, Jerome Halpin, County, TERMINATED, Supervisor, Suffolk / Riverhead Town, 91 Rabbit Run, Riverhead. Committee/filer ID 506796, Friends of Jerry Halpin, County, ACTIVE, Authorized Single Candidate Committee, Suffolk / Riverhead Town, contact Kristen Halpin, 91 Rabbit Run, Riverhead. Because the contact shares the Halpin name and address, Kristen is included in the Halpin family-financing watch list.",
                campaignRaised: 18_440.74,
                campaignDirectContributions: 18_440.74,
                campaignTransfersIn: 0,
                campaignLastReported: makeDate(year: 2026, month: 6, day: 12),
                campaignLoanAmount: 5_600.00,
                campaignLoanLastReported: makeDate(year: 2026, month: 4, day: 22)
            ),
            .init(
                name: "Kenneth Rothwell",
                role: "Councilman",
                responsibilitySummary: nil,
                grade: "C+",
                superlative: "The Process Hawk",
                highlights: [
                    "Clear decision trails on capital projects",
                    "Cost control and procurement discipline",
                    "Housing actions tied to income targets"
                ],
                photoURL: URL(string: "https://www.townofriverheadny.gov/ImageRepository/Document?documentID=186"),
                serviceStarted: makeDate(year: 2021, month: 1, day: 1),
                termStarts: makeDate(year: 2026, month: 1, day: 1),
                termEnds: makeDate(year: 2028, month: 12, day: 31),
                // Rothwell is actively running for Supervisor in the Nov 2026 election (same race
                // as Halpin) rather than waiting out his council term through 2028 — his next
                // electoral event is 2026-11-03, not his council seat's regular 2028 term-end.
                nextElection: makeDate(year: 2026, month: 11, day: 3),
                annualPay: 50_558,
                committeeLiaisons: [
                    "Business Advisory Committee",
                    "Conservation Advisory Council",
                    "Helicopter Noise Task Force",
                    "Hispanic Development Empowerment and Education Committee",
                    "Traffic Safety Committee",
                    "Veterans Advisory Committee"
                ],
                profileURL: URL(string: "https://www.townofriverheadny.gov/directory.aspx?eid=13"),
                termSourceURL: URL(string: "https://www.townofriverheadny.gov/244/Town-Board"),
                campaignFinanceURL: nyCampaignDisclosureURL,
                campaignCommitteeName: "Friends of Ken Rothwell",
                campaignFilerID: "154927",
                additionalCampaignFilings: [
                    CampaignFilingRef(
                        committeeName: "Ken Rothwell Supervisor filing",
                        filerID: "154926",
                        note: "COMMCAND candidate record: County, ACTIVE, Supervisor, Suffolk / Riverhead Town, 20 Dasiy Court, Wading River."
                    )
                ],
                campaignFilingNote: "COMMCAND fields: candidate ID 154926, Kenneth T Rothwell, County, ACTIVE, Supervisor, Suffolk / Riverhead Town, 20 Dasiy Court, Wading River. Committee/filer ID 154927, Friends of Ken Rothwell, County, ACTIVE, Authorized Single Candidate Committee, Suffolk / Riverhead Town, contact Neil A. Manzella, PO Box 277, Selden. This card combines filer IDs 154927 and 154926 because Rothwell is running for Supervisor.",
                campaignRaised: 163_624.61,
                campaignDirectContributions: 163_624.61,
                campaignTransfersIn: 0,
                campaignLastReported: makeDate(year: 2026, month: 6, day: 3),
                campaignLoanAmount: nil,
                campaignLoanLastReported: nil
            ),
            .init(
                name: "Joann Waski",
                role: "Councilwoman",
                responsibilitySummary: nil,
                grade: "B-",
                superlative: "The Community Anchor",
                highlights: [
                    "Neighborhood scale and quality",
                    "Constituent access and follow-up",
                    "Housing inventory with affordability guardrails"
                ],
                photoURL: URL(string: "https://www.townofriverheadny.gov/ImageRepository/Document?documentID=195"),
                serviceStarted: makeDate(year: 2024, month: 1, day: 1),
                termStarts: makeDate(year: 2024, month: 1, day: 1),
                termEnds: makeDate(year: 2027, month: 12, day: 31),
                nextElection: makeDate(year: 2027, month: 11, day: 2),
                annualPay: 50_558,
                committeeLiaisons: [
                    "Code Revision Committee",
                    "Downtown Revitalization Committee",
                    "East Creek Advisory Committee",
                    "Farmland Preservation Committee",
                    "Industrial Development Agency (IDA)",
                    "Landmarks Preservation Commission",
                    "Personnel"
                ],
                profileURL: URL(string: "https://www.townofriverheadny.gov/directory.aspx?eid=14"),
                termSourceURL: URL(string: "https://www.townofriverheadny.gov/244/Town-Board"),
                campaignFinanceURL: nyCampaignDisclosureURL,
                campaignCommitteeName: "Friends of Joann Waski",
                campaignFilerID: "320293",
                additionalCampaignFilings: [],
                campaignFilingNote: "COMMCAND fields: candidate ID 320292, Joann Waski, County, TERMINATED, Council Member, Suffolk / Riverhead Town, 66 Vista Ct., Riverhead. Committee/filer ID 320293, Friends of Joann Waski, County, ACTIVE, Authorized Single Candidate Committee, Suffolk / Riverhead Town, contact Danny Manzella, 17 Salem Street, Patchogue.",
                campaignRaised: 19_460.00,
                campaignDirectContributions: 18_460.00,
                campaignTransfersIn: 1_000.00,
                campaignLastReported: makeDate(year: 2024, month: 1, day: 10),
                campaignLoanAmount: nil,
                campaignLoanLastReported: nil
            ),
            .init(
                name: "Robert \"Bob\" Kern",
                role: "Councilman",
                responsibilitySummary: nil,
                grade: "C",
                superlative: "The Detail Driver",
                highlights: [
                    "Tracks implementation milestones",
                    "Pushes for measurable outcomes",
                    "Focuses on long-horizon capital decisions"
                ],
                photoURL: URL(string: "https://www.townofriverheadny.gov/ImageRepository/Document?documentID=3106"),
                serviceStarted: makeDate(year: 2022, month: 1, day: 1),
                termStarts: makeDate(year: 2026, month: 1, day: 1),
                termEnds: makeDate(year: 2028, month: 12, day: 31),
                nextElection: makeDate(year: 2028, month: 11, day: 7),
                annualPay: 50_558,
                committeeLiaisons: [
                    "Agricultural Advisory Committee",
                    "Alternative Transportation Committee",
                    "Architectural Review Board",
                    "Environmental Advisory Committee",
                    "Open Space Committee",
                    "Recreation Advisory Committee",
                    "Wildlife Management Advisory Committee"
                ],
                profileURL: URL(string: "https://www.townofriverheadny.gov/directory.aspx?eid=11"),
                termSourceURL: URL(string: "https://www.townofriverheadny.gov/244/Town-Board"),
                campaignFinanceURL: nyCampaignDisclosureURL,
                campaignCommitteeName: "Friends of Robert Kern",
                campaignFilerID: "527501",
                additionalCampaignFilings: [
                    CampaignFilingRef(
                        committeeName: "Friends of Bob Kern",
                        filerID: "154941",
                        note: "COMMCAND legacy committee: County, ACTIVE, Authorized Single Candidate Committee, Suffolk / Riverhead Town, contact Nancy Marks, 47 Flintlock Dr, Shirley."
                    )
                ],
                campaignFilingNote: "COMMCAND fields: current committee/filer ID 527501, Friends of Robert Kern, County, ACTIVE, Authorized Single Candidate Committee, Suffolk / Riverhead Town, contact Shawn Hyms, 34 Arlington Road, Lake Ronkonkoma. COMMCAND also shows legacy candidate ID 154940, Robert Kern, County, TERMINATED, Council Member, Suffolk / Riverhead Town, 49 Phillips Ave, Aquebogue, and legacy committee/filer ID 154941, Friends of Bob Kern. This card includes both committee filer IDs for the 2005–2026 review window.",
                campaignRaised: 62_838.80,
                campaignDirectContributions: 62_638.80,
                campaignTransfersIn: 200.00,
                campaignLastReported: makeDate(year: 2025, month: 10, day: 14),
                campaignLoanAmount: nil,
                campaignLoanLastReported: nil
            ),
            .init(
                name: "Denise Merrifield",
                role: "Councilwoman",
                responsibilitySummary: nil,
                grade: "C",
                superlative: "The Community Listener",
                highlights: [
                    "Constituent-oriented policymaking",
                    "Focus on neighborhood quality of life",
                    "Supports practical housing and service planning"
                ],
                photoURL: URL(string: "https://www.townofriverheadny.gov/ImageRepository/Document?documentID=193"),
                serviceStarted: makeDate(year: 2024, month: 1, day: 1),
                termStarts: makeDate(year: 2024, month: 1, day: 1),
                termEnds: makeDate(year: 2027, month: 12, day: 31),
                nextElection: makeDate(year: 2027, month: 11, day: 2),
                annualPay: 50_558,
                committeeLiaisons: [
                    "Climate Smart Community Task Force",
                    "Code Revision Committee",
                    "Disability Advisory Committee",
                    "Parking District Advisory Committee",
                    "Senior Citizen Advisory Council"
                ],
                profileURL: URL(string: "https://www.townofriverheadny.gov/directory.aspx?eid=12"),
                termSourceURL: URL(string: "https://www.townofriverheadny.gov/244/Town-Board"),
                campaignFinanceURL: nyCampaignDisclosureURL,
                campaignCommitteeName: "Committee to Elect Denise Merrifield",
                campaignFilerID: "319756",
                additionalCampaignFilings: [],
                campaignFilingNote: "COMMCAND fields: candidate ID 319755, Denise M. Merrifield, County, TERMINATED, Council Member, Suffolk / Riverhead Town, 84 Farm Road E., Wading River. Committee/filer ID 319756, Committee to Elect Denise Merrifield, County, TERMINATED, Authorized Single Candidate Committee, Suffolk / Riverhead Town, contact Peter Timmons, 84 Farm Road E, Wading River. The shared address is useful context but does not by itself establish a family relationship.",
                campaignRaised: 17_579.75,
                campaignDirectContributions: 15_579.75,
                campaignTransfersIn: 2_000.00,
                campaignLastReported: makeDate(year: 2023, month: 11, day: 30),
                campaignLoanAmount: nil,
                campaignLoanLastReported: nil
            )
        ]
    }

    private var formerMembers: [CouncilMember] {
        [
            .init(
                name: "Tim Hubbard",
                role: "Former Councilman",
                responsibilitySummary: "Served on the Riverhead Town Board. No longer serving as of 2024.",
                grade: "N/A",
                superlative: "Former Official",
                highlights: [
                    "Campaign filings tracked 2005–2026 for Petrocelli-related donor review"
                ],
                photoURL: nil,
                serviceStarted: nil,
                termStarts: nil,
                termEnds: makeDate(year: 2023, month: 12, day: 31),
                nextElection: nil,
                annualPay: nil,
                committeeLiaisons: [],
                profileURL: nil,
                termSourceURL: URL(string: "https://www.townofriverheadny.gov/244/Town-Board"),
                campaignFinanceURL: nyCampaignDisclosureURL,
                campaignCommitteeName: "Friends of Tim Hubbard",
                campaignFilerID: "154933",
                additionalCampaignFilings: [],
                campaignFilingNote: "Former Councilman, Riverhead Town. COMMCAND filer ID 154933 (Friends of Tim Hubbard) — verify against NY COMMCAND as records may be terminated. Included for Petrocelli-related campaign finance review across the 2005–2026 window.",
                campaignRaised: nil,
                campaignDirectContributions: nil,
                campaignTransfersIn: nil,
                campaignLastReported: nil,
                campaignLoanAmount: nil,
                campaignLoanLastReported: nil
            ),
            .init(
                name: "Jodi Giglio",
                role: "Former Councilwoman",
                responsibilitySummary: "Served on the Riverhead Town Board. Later elected to the New York State Assembly (AD-2). No longer serving on the Town Board.",
                grade: "N/A",
                superlative: "Former Official",
                highlights: [
                    "Campaign filings tracked 2005–2026 for Petrocelli-related donor review"
                ],
                photoURL: nil,
                serviceStarted: nil,
                termStarts: nil,
                termEnds: makeDate(year: 2020, month: 12, day: 31),
                nextElection: nil,
                annualPay: nil,
                committeeLiaisons: [],
                profileURL: nil,
                termSourceURL: URL(string: "https://www.townofriverheadny.gov/244/Town-Board"),
                campaignFinanceURL: nyCampaignDisclosureURL,
                campaignCommitteeName: "Friends of Jodi Giglio",
                campaignFilerID: "155155",
                additionalCampaignFilings: [],
                campaignFilingNote: "Former Councilwoman, Riverhead Town; later elected to NY Assembly AD-2. COMMCAND filer ID 155155 (Friends of Jodi Giglio) — verify against NY COMMCAND as records may be terminated or consolidated with her Assembly committee. Included for Petrocelli-related campaign finance review across the 2005–2026 window.",
                campaignRaised: nil,
                campaignDirectContributions: nil,
                campaignTransfersIn: nil,
                campaignLastReported: nil,
                campaignLoanAmount: nil,
                campaignLoanLastReported: nil
            ),
            .init(
                name: "Yvette Aguiar",
                role: "Former Supervisor",
                responsibilitySummary: "Served as Riverhead Town Supervisor. No longer serving.",
                grade: "N/A",
                superlative: "Former Official",
                highlights: [
                    "Campaign filings tracked 2005–2026 for Petrocelli-related donor review"
                ],
                photoURL: nil,
                serviceStarted: nil,
                termStarts: nil,
                termEnds: makeDate(year: 2017, month: 12, day: 31),
                nextElection: nil,
                annualPay: nil,
                committeeLiaisons: [],
                profileURL: nil,
                termSourceURL: URL(string: "https://www.townofriverheadny.gov/244/Town-Board"),
                campaignFinanceURL: nyCampaignDisclosureURL,
                campaignCommitteeName: "Taxpayers for Aguiar",
                campaignFilerID: "66984",
                additionalCampaignFilings: [],
                campaignFilingNote: "Former Supervisor, Riverhead Town. Committee name: Taxpayers for Aguiar, filer ID 66984 — verify against NY COMMCAND as records may be terminated. Included for Petrocelli-related campaign finance review across the 2005–2026 window.",
                campaignRaised: nil,
                campaignDirectContributions: nil,
                campaignTransfersIn: nil,
                campaignLastReported: nil,
                campaignLoanAmount: nil,
                campaignLoanLastReported: nil
            )
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                scorecardToolsCard
                boardComparisonCard
                scorecardSectionTitle("Officials", icon: "person.3.fill")
                ForEach(members) { member in
                    memberCard(member)
                }
                scorecardSectionTitle("Former Officials — Campaign Watch", icon: "clock.arrow.circlepath")
                Text("No longer serving but included for Petrocelli-related campaign finance review across the 2005–2026 filing window. Filer IDs are pulled from NY Open Data alongside current board members.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                ForEach(formerMembers) { member in
                    memberCard(member)
                }
                scorecardSectionTitle("Context", icon: "info.circle")
                campaignFinanceSummaryCard
                electionCalendarStatusCard
                supervisorAdministrationCard
                publicSafetyTaskForceQuestionCard
                rubricCard
                electionTimelineCard
                notesCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 96)
        }
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Council Scorecard")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUserRatings()
            loadCachedCampaignSnapshots()
        }
    }

    private func scorecardSectionTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(RiverheadTheme.accent)
            Text(title)
                .font(.headline)
                .foregroundStyle(RiverheadTheme.textPrimary)
            Spacer()
        }
        .padding(.top, 4)
    }

    private var scorecardToolsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scorecard Tools")
                .font(.headline)
                .foregroundStyle(RiverheadTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 10)], spacing: 10) {
                scorecardToolLink(
                    title: "Campaign Filing Summary",
                    subtitle: "Compare filings, donors, candidate-family support, and project-interest flags.",
                    icon: "tablecells",
                    tint: RiverheadTheme.brandGold
                ) {
                    campaignFilingSummaryView
                }

                scorecardToolLink(
                    title: "Personal Grading Notebook",
                    subtitle: "Adjust weights and keep your private notes.",
                    icon: "pencil.and.list.clipboard",
                    tint: RiverheadTheme.accent
                ) {
                    personalScorecardNotebook
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(RiverheadTheme.Surface.elevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.border.opacity(0.22), lineWidth: 0.8)
        )
    }

    private func scorecardToolLink<Destination: View>(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: icon)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint.opacity(0.8))
                    .padding(.top, 6)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.07))
            )
        }
        .buttonStyle(.plain)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 12) {
                    Text("Town Council Report Cards")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(RiverheadTheme.textPrimary)

                    Spacer(minLength: 8)

                    updateFilingsButton
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Town Council Report Cards")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(RiverheadTheme.textPrimary)

                    updateFilingsButton
                }
            }

            Text("A fun, civic-friendly scorecard that highlights policy priorities and public-facing expectations. This is not an official rating.")
                .font(.subheadline)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let status = filingsUpdateStatus {
                Text(status)
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)
            }

            if let last = filingsLastUpdatedAt {
                Text("Filings last updated: \(reportDateFormatter.string(from: last))")
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)
            }
        }
        .padding(16)
        .background(RiverheadTheme.Surface.elevated)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.border.opacity(0.24), lineWidth: 0.8)
        )
        .shadow(color: RiverheadTheme.cardShadow(scheme), radius: 10, x: 0, y: 5)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var personalScorecardCard: some View {
        NavigationLink {
            personalScorecardNotebook
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "pencil.and.list.clipboard")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.accent)
                    .frame(width: 40, height: 40)
                    .background(RiverheadTheme.accent.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Personal Grading Notebook")
                        .font(.headline)
                        .foregroundStyle(RiverheadTheme.textPrimary)

                    Text("Adjust your weights, save your own grades, and keep private meeting notes in a separate view.")
                        .font(.subheadline)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RiverheadTheme.accent)
                    .padding(.top, 8)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(RiverheadTheme.Surface.elevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(RiverheadTheme.accent.opacity(0.24), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    private var personalScorecardNotebook: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Personal Grading Notebook")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(RiverheadTheme.textPrimary)

                    Text("This view is for your own weights, grades, and notes. It is separate from the public-facing scorecard so the main view stays focused on evidence and disclosure context.")
                        .font(.subheadline)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(RiverheadTheme.Surface.elevated)
                )

                accountabilityWeightsCard

                ForEach(members) { member in
                    personalRatingCard(for: member)
                }
            }
            .padding(16)
            .padding(.bottom, 60)
        }
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("My Grades")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUserRatings()
        }
    }

    private var updateFilingsButton: some View {
        Button {
            Task { await updateCampaignFinanceSnapshots() }
        } label: {
            if isUpdatingFilings {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(minWidth: 120)
            } else {
                Label("Update Filings", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
                    .labelStyle(.titleAndIcon)
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
        .tint(RiverheadTheme.accent)
        .disabled(isUpdatingFilings)
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
                .fill(RiverheadTheme.Surface.elevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.border.opacity(0.22), lineWidth: 0.8)
        )
    }

    private var electionCalendarStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Election Calendar Status")
                        .font(.headline)
                        .foregroundStyle(RiverheadTheme.textPrimary)

                    Text("The even-year election lawsuit is still pending, but there is no court order changing Riverhead's calendar.")
                        .font(.subheadline)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundStyle(RiverheadTheme.brandGold)
            }

            BulletRow("Supervisor race remains scheduled for Nov. 3, 2026 unless a court rules otherwise.")
            BulletRow("If that election is held and certified, the winner takes the regular two-year Supervisor term from Jan. 1, 2027 through Dec. 31, 2028.")
            BulletRow("The next federal conference was delayed to June 18, 2026 for briefing after Louisiana v. Callais.")
            BulletRow("The scorecard keeps the shortened 2026 supervisor term and transition council terms as the working baseline.")

            HStack(spacing: 12) {
                Link(destination: evenYearElectionStatusURL) {
                    Label("Local update", systemImage: "newspaper")
                        .font(.footnote.weight(.semibold))
                }

                Link(destination: evenYearTransitionGuidanceURL) {
                    Label("BOE guidance", systemImage: "doc.text")
                        .font(.footnote.weight(.semibold))
                }
            }
            .foregroundStyle(RiverheadTheme.accent)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(RiverheadTheme.Surface.elevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.brandGold.opacity(0.30), lineWidth: 0.9)
        )
    }

    private var supervisorAdministrationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Supervisor Administration Lens")
                        .font(.headline)
                        .foregroundStyle(RiverheadTheme.textPrimary)

                    Text("The Supervisor's effectiveness depends heavily on senior staff selection, because department heads and top deputies turn campaign promises into budgets, labor decisions, procurement discipline, project delivery, and resident service.")
                        .font(.subheadline)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "person.3.sequence")
                    .font(.title3)
                    .foregroundStyle(RiverheadTheme.accent)
            }

            BulletRow("Ask whether key appointments have relevant municipal, finance, planning, labor, and operations experience.")
            BulletRow("Look for clean reporting lines: who owns grants, capital projects, public communication, and department follow-through?")
            BulletRow("Treat senior staff choices as an early governing signal, not inside-baseball gossip.")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(RiverheadTheme.Surface.elevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.accent.opacity(0.26), lineWidth: 0.8)
        )
    }

    private var electionTimelineCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Election / Term Timeline")
                .font(.headline)
                .foregroundStyle(RiverheadTheme.textPrimary)

            timelineRow(date: "Jan. 1, 2026", title: "Transition term begins", detail: "Current Supervisor term runs for one year under the even-year transition baseline.")
            timelineRow(date: "June 18, 2026", title: "Federal conference", detail: "Court conference scheduled for the pending even-year elections challenge.")
            timelineRow(date: "Nov. 3, 2026", title: "Scheduled Supervisor election", detail: "Election remains on the calendar unless a court changes it.")
            timelineRow(date: "Jan. 1, 2027", title: "Regular term begins", detail: "If the election is held and certified, the winner starts a two-year Supervisor term through Dec. 31, 2028.")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(RiverheadTheme.Surface.elevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.border.opacity(0.22), lineWidth: 0.8)
        )
    }

    private var accountabilityWeightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Scorecard Weights")
                .font(.headline)
                .foregroundStyle(RiverheadTheme.textPrimary)

            Text("Adjust what matters most to you. The personalized score on each card updates from these weights.")
                .font(.subheadline)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(ScoreCategory.allCases) { category in
                weightSlider(for: category)
            }

            Text("Current weighting: \(weightSummary)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(RiverheadTheme.Surface.elevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.border.opacity(0.22), lineWidth: 0.8)
        )
    }

    private var campaignFinanceSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Campaign Finance Check")
                        .font(.headline)
                        .foregroundStyle(RiverheadTheme.textPrimary)

                    Text("Direct fundraising is separated from transfers-in so the scorecard does not overstate donor fundraising.")
                        .font(.subheadline)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            }

            HStack(spacing: 10) {
                financeMetricTile(
                    title: "Direct fundraising",
                    value: currencyFormatter.string(from: NSNumber(value: totalDirectFundraising)) ?? "$0",
                    tint: RiverheadTheme.accent
                )

                financeMetricTile(
                    title: "Transfers in",
                    value: currencyFormatter.string(from: NSNumber(value: totalTransfersIn)) ?? "$0",
                    tint: totalTransfersIn > 0 ? .orange : .green
                )
            }

            if let topDirectFundraiser {
                Text("Top direct fundraiser: \(topDirectFundraiser.member.name) at \(currencyFormatter.string(from: NSNumber(value: topDirectFundraiser.amount)) ?? "$0").")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textSecondary)
            }

            if totalPetroCelliDonations > 0 {
                Divider()

                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("Petrocelli-related donations — all current and former officials (2005–2026)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.textPrimary)
                }

                financeMetricTile(
                    title: "Petrocelli-related total",
                    value: currencyFormatter.string(from: NSNumber(value: totalPetroCelliDonations)) ?? "$0",
                    tint: .orange
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Petrocelli-related donations total: \(currencyFormatter.string(from: NSNumber(value: totalPetroCelliDonations)) ?? "$0") across all current and former officials from 2005 to 2026.")

                VStack(alignment: .leading, spacing: 4) {
                    Text("Breakdown by recipient:")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(petrocelliDonationBreakdown, id: \.name) { entry in
                        HStack {
                            Text(entry.name)
                                .font(.caption)
                            Spacer()
                            Text(currencyFormatter.string(from: NSNumber(value: entry.amount)) ?? "$0")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(entry.name): \(currencyFormatter.string(from: NSNumber(value: entry.amount)) ?? "$0")")
                    }
                }

                Text("Totals reflect matched contributions fetched from NY Open Data or pre-loaded baseline data. Tap Refresh to update. These amounts are transparency context, not proof of coordination or quid pro quo.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !employeeDonorMatches.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Town Employee Donors", systemImage: "person.badge.shield.checkmark")
                        .font(.subheadline.weight(.bold))
                    Text("Town payroll employees whose name matches an individual campaign donor to a tracked committee. Disclosure context, not an accusation — modest personal donations from Town employees to sitting or former officials are common and legal. Matched by name only.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    financeMetricTile(
                        title: "Matched contributions",
                        value: "\(employeeDonorMatches.count) totaling \(currencyFormatter.string(from: NSNumber(value: employeeDonorMatches.reduce(0) { $0 + $1.amount })) ?? "$0")",
                        tint: RiverheadTheme.brandGold
                    )

                    ForEach(Array(Dictionary(grouping: employeeDonorMatches, by: \.officialName).sorted(by: { $0.key < $1.key })), id: \.key) { officialName, matches in
                        DisclosureGroup("\(officialName) (\(matches.count))") {
                            ForEach(matches) { match in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(match.employeeName)
                                        .font(.caption.weight(.semibold))
                                    if let title = match.title {
                                        Text([title, match.department].compactMap { $0 }.joined(separator: ", "))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    HStack {
                                        Text(currencyFormatter.string(from: NSNumber(value: match.amount)) ?? "$0")
                                            .font(.caption.weight(.semibold))
                                        Text("· \(match.electionYear) \(match.filingDesc)")
                                            .foregroundStyle(.secondary)
                                        if let date = match.date {
                                            Text("· \(reportDateFormatter.string(from: date))")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .font(.caption2)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .font(.caption)
                    }
                }
            }

            if let deadline = nextFilingDeadline, deadline.label != "General Election Day" {
                VStack(alignment: .leading, spacing: 3) {
                    Label("Next filing deadline: \(deadline.label) — due \(deadline.dateLabel)", systemImage: "calendar.badge.clock")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.brandGold)
                    Text("\(deadline.periodNote). Every committee tracked in this scorecard is required to file by this date. Source: NY BOE 2026 filing calendar.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text("Source: New York State Board of Elections / NY Open Data. Candidate filing totals in this scorecard use the \(campaignFilingYearRangeLabel) window; use Update Filings for the newest daily Open Data values.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Note: individual council cards use each candidate committee's filer ID. Party committee activity, such as town Democratic or Republican committee receipts, can appear under separate filer IDs and is not rolled into a candidate's fundraising total.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(RiverheadTheme.Surface.elevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.border.opacity(0.22), lineWidth: 0.8)
        )
    }

    private var campaignFilingSummaryCard: some View {
        NavigationLink {
            campaignFilingSummaryView
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "tablecells")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.brandGold)
                    .frame(width: 40, height: 40)
                    .background(RiverheadTheme.brandGold.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Campaign Filing Summary")
                        .font(.headline)
                        .foregroundStyle(RiverheadTheme.textPrimary)

                    Text("Compare every candidate's filings, donors, transfers, candidate-family support, and project-interest flags in one view.")
                        .font(.subheadline)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RiverheadTheme.brandGold)
                    .padding(.top, 8)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(RiverheadTheme.Surface.elevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(RiverheadTheme.brandGold.opacity(0.24), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
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
                .fill(RiverheadTheme.Surface.elevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.border.opacity(0.22), lineWidth: 0.8)
        )
    }

    private var campaignFilingSummaryView: some View {
        let filteredMembers = filteredCampaignFilingMembers

        return List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Campaign Filing Summary")
                        .font(.title3.weight(.bold))
                    Text("A compact comparison of all mapped candidate committees. Tap Update Filings on the scorecard first for the newest NY Open Data values.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            if filteredMembers.isEmpty {
                Section("No Matches") {
                    ContentUnavailableView(
                        "No Filings Found",
                        systemImage: "magnifyingglass",
                        description: Text("Try a candidate name, committee, filer ID, donor flag, or COMMCAND contact.")
                    )
                }
            } else {
                Section(campaignFilingSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Candidates" : "Matches") {
                    ForEach(filteredMembers) { member in
                        NavigationLink {
                            candidateFilingDetailView(for: member)
                        } label: {
                            campaignFilingSummaryRow(for: member)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Filing Summary")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $campaignFilingSearchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search filings, committees, IDs"
        )
    }

    private var filteredCampaignFilingMembers: [CouncilMember] {
        let search = campaignFilingSearchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !search.isEmpty else { return allTrackedMembers }

        return allTrackedMembers.filter { member in
            campaignFilingSearchHaystack(for: member).contains(search)
        }
    }

    private func campaignFilingSearchHaystack(for member: CouncilMember) -> String {
        let snapshot = campaignSnapshot(for: member)
        let filings = campaignFilings(for: member)
        let flags = relatedPartyFlagLabels(for: snapshot)
        var parts: [String] = [
            member.name,
            member.role,
            member.campaignCommitteeName ?? "",
            member.campaignFilerID ?? "",
            member.campaignFilingNote ?? "",
            flags.joined(separator: " ")
        ]

        parts.append(contentsOf: filings.flatMap { filing in
            [
                filing.committeeName,
                filing.filerID,
                filing.note ?? ""
            ]
        })

        if let details = snapshot?.filingDetails {
            parts.append(contentsOf: details.flatMap { detail in
                [
                    detail.committeeName,
                    detail.filerID
                ]
            })
        }

        parts.append(contentsOf: [
            snapshot?.largestIndividualContribution?.donorName,
            snapshot?.largestBusinessContribution?.donorName
        ].compactMap { $0 })

        parts.append(contentsOf: (snapshot?.petrocelliContributions ?? []).map(\.donorName))
        parts.append(contentsOf: (snapshot?.scottPointeContributions ?? []).map(\.donorName))
        parts.append(contentsOf: (snapshot?.candidateFamilyLoans ?? []).map(\.donorName))

        return parts
            .joined(separator: " ")
            .lowercased()
    }

    private func campaignFilingSummaryRow(for member: CouncilMember) -> some View {
        let snapshot = campaignSnapshot(for: member)
        let direct = snapshot?.directContributions ?? snapshot?.raised ?? 0
        let transfers = snapshot?.transfersIn ?? 0
        let loans = snapshot?.loanAmount ?? 0
        let latest = snapshot?.lastReported
        let flags = relatedPartyFlagLabels(for: snapshot)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(.subheadline.weight(.semibold))
                    Text(member.role)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Text(latest.map { reportDateFormatter.string(from: $0) } ?? "Not updated")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                summaryPill("Direct", direct, tint: RiverheadTheme.accent)
                summaryPill("Transfers", transfers, tint: transfers > 0 ? .orange : .green)
                summaryPill("Loans", loans, tint: loans > 0 ? .red : .green)
            }

            if let topDonor = snapshot?.largestIndividualContribution ?? snapshot?.largestBusinessContribution {
                Text("Top donor: \(topDonor.donorName) \(currencyFormatter.string(from: NSNumber(value: topDonor.amount)) ?? "$0")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if flags.isEmpty {
                Text("Flags: none from configured candidate-family or project-interest matchers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Flags: \(flags.joined(separator: ", "))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }

    private func candidateFilingDetailView(for member: CouncilMember) -> some View {
        let snapshot = campaignSnapshot(for: member)
        let filings = campaignFilings(for: member)

        return List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(member.name)
                        .font(.title3.weight(.bold))
                    Text(member.role)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("\(campaignFilingEndYear) Election Cycle") {
                if let nextElection = member.nextElection {
                    let days = Calendar.current.dateComponents([.day], from: Date(), to: nextElection).day ?? 0
                    Label(
                        days > 0 ? "\(days) day\(days == 1 ? "" : "s") to next election" : (days == 0 ? "Election is today" : "Election has passed"),
                        systemImage: "calendar.badge.clock"
                    )
                }
                if let direct = snapshot?.latestYearDirect, direct > 0 {
                    filingMetricRow("Raised this cycle", direct)
                    let perResident = direct / Double(riverheadPopulationEstimate2024)
                    filingMetricRow("Raised per resident", perResident)
                    Text("of \(riverheadPopulationEstimate2024.formatted()) residents (2024 Census estimate)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let donorCount = snapshot?.donorCount, let avg = snapshot?.avgDonationPerDonor {
                    filingMetricRow("Avg. donation per donor (this cycle)", avg)
                    Text("\(donorCount) donor\(donorCount == 1 ? "" : "s") this cycle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let breakdown = snapshot?.contributorTypeBreakdown, !breakdown.isEmpty {
                    ForEach(breakdown, id: \.type) { bucket in
                        HStack {
                            Text("\(bucket.type) (\(bucket.donorCount))")
                            Spacer()
                            Text(bucket.amount, format: .currency(code: "USD"))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Lifetime Totals (\(campaignFilingStartYear)\u{2013}\(campaignFilingEndYear))") {
                filingMetricRow("Total receipts", snapshot?.raised)
                filingMetricRow("Direct contributions", snapshot?.directContributions)
                filingMetricRow("Transfers in", snapshot?.transfersIn)
                if let reported = snapshot?.lastReported {
                    Label("Latest filing date: \(reportDateFormatter.string(from: reported))", systemImage: "calendar")
                } else {
                    Label("Latest filing date: not updated", systemImage: "calendar.badge.exclamationmark")
                }
            }

            if let byYear = snapshot?.historicalByYear, !byYear.isEmpty {
                Section("Direct Contributions by Year") {
                    ForEach(byYear, id: \.year) { year in
                        yearDisclosureRow(year)
                    }
                }
            }

            if (snapshot?.loanAmount ?? 0) > 0 || (snapshot?.outstandingLoanAmount ?? 0) > 0 {
                Section("Loans") {
                    if let received = snapshot?.loanAmount, received > 0 {
                        filingMetricRow("Received (all-time)", received)
                    }
                    if let outstanding = snapshot?.outstandingLoanAmount, outstanding > 0 {
                        filingMetricRow(
                            "Currently outstanding" + (snapshot?.outstandingLoanYear.map { " (as of \($0) filing)" } ?? ""),
                            outstanding
                        )
                    }
                    Text("Local candidate committees are almost always self-funded through loans like these.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                if let direct = snapshot?.latestYearDirect, direct > 0 {
                    filingMetricRow("Direct contributions", direct)
                } else {
                    Label("No direct contribution rows found for \(campaignFilingEndYear) yet.", systemImage: "tray")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                filingMetricRow("Transfers in", snapshot?.latestYearTransfers)
                filingMetricRow("All schedule activity", snapshot?.latestYearFilingAmount)
                if let rows = snapshot?.latestYearRowCount, rows > 0 {
                    Text("Filing rows: \(rows)")
                }
                if let schedules = snapshot?.latestYearSchedules {
                    Text("Schedules: \(schedules)")
                }
                if let lastDate = snapshot?.latestYearLastReported {
                    Label("Latest \(campaignFilingEndYear) row: \(reportDateFormatter.string(from: lastDate))", systemImage: "calendar.badge.checkmark")
                        .foregroundStyle(RiverheadTheme.accent)
                } else {
                    Label("No \(campaignFilingEndYear) filings found — tap Refresh on the scorecard to pull latest data.", systemImage: "calendar.badge.exclamationmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("\(campaignFilingEndYear) Filing Activity", systemImage: "doc.badge.clock")
            }

            Section("\(campaignFilingYearRangeLabel) Full Window") {
                filingMetricRow("Direct contributions", snapshot?.currentYearDirectContributions)
                filingMetricRow("Transfers", snapshot?.currentYearTransfersIn)
                filingMetricRow("All filing activity", snapshot?.currentYearFilingActivityAmount)
                Text("Rows: \(snapshot?.currentYearFilingActivityRowCount ?? 0)")
                Text("Schedules: \(snapshot?.currentYearFilingActivitySchedules ?? "none")")
                if let currentYearLast = snapshot?.currentYearLastReported {
                    Text("Latest row date: \(reportDateFormatter.string(from: currentYearLast))")
                }
            }

            Section("Mapped Committees") {
                ForEach(filings, id: \.filerID) { filing in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(filing.committeeName)
                            .font(.subheadline.weight(.semibold))
                        Text("Filer ID: \(filing.filerID)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let note = filing.note {
                            Text(note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let details = snapshot?.filingDetails,
               !details.isEmpty {
                Section("Committee Breakdown") {
                    ForEach(details, id: \.filerID) { detail in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(detail.committeeName)
                                .font(.subheadline.weight(.semibold))
                            Text("Filer ID: \(detail.filerID)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            filingMetricText("Raised", detail.raised)
                            filingMetricText("Direct", detail.directContributions)
                            filingMetricText("Transfers", detail.transfersIn)
                            if let lastReported = detail.lastReported {
                                Text("Latest: \(reportDateFormatter.string(from: lastReported))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 3)
                    }
                }
            }

            if let events = snapshot?.filingEvents, !events.isEmpty {
                Section("Campaign Filings") {
                    let hasMultipleCommittees = Set(events.map(\.filerID)).count > 1
                    ForEach(groupedFilingEvents(events), id: \.bucket) { group in
                        DisclosureGroup(group.bucket) {
                            ForEach(group.events) { event in
                                campaignFilingRow(event, showCommitteeName: hasMultipleCommittees)
                            }
                        }
                    }
                    Text("\"Latest activity\" is the newest transaction date reported inside that filing, not the date the filing was submitted — the bulk Open Data feed doesn't carry a submission timestamp, only per-transaction dates (which can be old for a recurring loan balance re-reported each period). This list also only shows filings that reported at least one itemized transaction — a filing with no reportable activity for that period won't appear here at all, since the bulk data has no row for it.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Section("Top Donors") {
                if let topIndividual = snapshot?.largestIndividualContribution {
                    topContributionRow(title: "Largest individual", contribution: topIndividual, tint: RiverheadTheme.brandSky)
                } else {
                    Text("Largest individual donor not loaded.")
                        .foregroundStyle(.secondary)
                }

                if let topBusiness = snapshot?.largestBusinessContribution {
                    topContributionRow(title: "Largest business/entity", contribution: topBusiness, tint: RiverheadTheme.brandGold)
                } else {
                    Text("Largest business/entity donor not loaded.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Candidate / Family Financing") {
                if let loans = snapshot?.candidateFamilyLoans,
                   !loans.isEmpty {
                    ForEach(Array(loans.enumerated()), id: \.offset) { _, loan in
                        topContributionRow(title: "Matched self/family row", contribution: loan, tint: .red)
                    }
                    Text("Matches rows marked Candidate/Candidate Spouse or Candidate Family Member, plus explicitly mapped family names. Candidate self-funding and family support are shown here even when BOE records classify them as contribution rows rather than loan schedules.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("No candidate/self, spouse, or explicitly mapped family financing rows found in the \(campaignFilingYearRangeLabel) filing window.")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    contributionLimitNote(
                        title: "Most donors",
                        detail: "capped at the number of registered voters in the district × $0.05 — a limit that scales with the size of the race, not a flat dollar figure."
                    )
                    contributionLimitNote(
                        title: "Family donors",
                        detail: "child, parent, grandparent, sibling, or the spouse of any of those get a higher cap — the greater of (registered voters × $0.25) or $1,250."
                    )
                    contributionLimitNote(
                        title: "The candidate's own money",
                        detail: "no cap at all. New York's self-funding limit only applies to candidates in the state's public campaign-financing program — local town races aren't part of it, so a candidate (or, per the cap above, their family) can put in far more than any ordinary donor could."
                    )
                    Text("Every dollar amount above is real. The specific legal cap for this committee isn't computed here — it depends on the registered-voter count for the exact race and year, which we haven't verified. This is the general shape of the law (NY Election Law § 14-114), not a pass/fail verdict. Confirm specifics with the NY State or Suffolk County Board of Elections before treating any number as authoritative.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            } header: {
                Label("What NY Law Actually Limits", systemImage: "checkmark.shield.fill")
            }

            Section("Project-Interest Flags") {
                if let snapshot {
                    petrocelliDisclosureNote(for: snapshot)
                    scottPointeDisclosureNote(for: snapshot)
                } else {
                    Text("No campaign snapshot available. Run Update Filings from the scorecard.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Source") {
                Link(destination: member.campaignFinanceURL ?? nyCampaignDisclosureURL) {
                    Label("Open NYS Filings", systemImage: "link")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle(member.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func memberCard(_ member: CouncilMember) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                memberPhoto(for: member, size: 64)

                VStack(alignment: .leading, spacing: 5) {
                    Text(displayName(for: member))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(RiverheadTheme.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(member.role)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.accent)

                    if let responsibilitySummary = member.responsibilitySummary {
                        Text(responsibilitySummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(member.superlative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(member.grade)
                        .font(.title2.weight(.black))
                        .foregroundStyle(GradeStyle.color(for: member.grade))
                    Text("App Grade")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(GradeStyle.color(for: member.grade).opacity(0.10))
                )
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 8)], spacing: 8) {
                scorecardStatTile(title: "Title", value: member.role, icon: "person.text.rectangle")
                scorecardStatTile(title: "Service", value: serviceLengthText(for: member), icon: "stopwatch")
                scorecardStatTile(title: "Term", value: termRangeText(for: member), icon: "calendar")
                scorecardStatTile(title: "Next Election", value: nextElectionText(for: member), icon: "checkmark.seal")
                scorecardStatTile(title: "Pay", value: payText(for: member), icon: "dollarsign.circle")
                scorecardStatTile(title: "Liaisons", value: liaisonCountText(for: member), icon: "person.3.sequence")
            }

            liaisonPreview(for: member)

            latestYearFilingChip(for: member)

            NavigationLink {
                memberDetailView(for: member)
            } label: {
                Label("More Information", systemImage: "chart.bar.doc.horizontal")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(RiverheadTheme.accent)
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

    private func memberDetailView(for member: CouncilMember) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                memberPhoto(for: member, size: 58)

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName(for: member))
                        .font(.headline)
                        .foregroundStyle(RiverheadTheme.textPrimary)
                    Text(member.role)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let responsibilitySummary = member.responsibilitySummary {
                        Text(responsibilitySummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                gradeTile(
                    title: "App Grade",
                    value: member.grade,
                    color: GradeStyle.color(for: member.grade)
                )
            }

            Text(member.superlative)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RiverheadTheme.accent)

            collapsibleSection(title: "Scorecard Highlights", systemImage: "star.circle") {
                bulletList(member.highlights)
            }

            collapsibleSection(title: "Committee Liaisons", systemImage: "person.3.sequence") {
                committeeLiaisonsSection(for: member)
            }

            collapsibleSection(title: "Scores and Evidence", systemImage: "chart.bar.doc.horizontal") {
                accountabilityScoreSection(for: member)
                evidenceSection(for: member)
            }

            if let candidateContext = candidateContext(for: member) {
                collapsibleSection(title: "Candidate Context", systemImage: "person.text.rectangle") {
                    candidateLensSection(candidateContext)
                }
            }

            collapsibleSection(title: "Resident Actions", systemImage: "person.line.dotted.person") {
                residentActionSection(for: member)
                followUpSection(for: member)
            }

            collapsibleSection(title: "Key Questions to Ask", systemImage: "questionmark.bubble") {
                keyQuestionsSection(for: member)
            }

            collapsibleSection(title: "Filings and Pay Reporting", systemImage: "doc.text.magnifyingglass") {
                campaignDisclosureStrip(for: member)
                electedOfficialReportingCard
            }

            HStack(spacing: 12) {
                if let termStarts = member.termStarts,
                   let termEnds = member.termEnds {
                    Label("Term \(termFormatter.string(from: termStarts)) - \(termFormatter.string(from: termEnds))", systemImage: "calendar")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if let termEnds = member.termEnds {
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
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle(displayName(for: member))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RiverheadTheme.Surface.card, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    @ViewBuilder
    private func latestYearFilingChip(for member: CouncilMember) -> some View {
        let snapshot = campaignSnapshot(for: member)
        let hasLatestYear = (snapshot?.latestYearFilingAmount ?? 0) > 0 || snapshot?.latestYearLastReported != nil
        let latestDirect = snapshot?.latestYearDirect ?? 0
        let latestTransfers = snapshot?.latestYearTransfers ?? 0
        let latestDate = snapshot?.latestYearLastReported
        let schedules = snapshot?.latestYearSchedules ?? ""

        NavigationLink {
            candidateFilingDetailView(for: member)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: hasLatestYear ? "doc.text.fill" : "doc.text")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(hasLatestYear ? RiverheadTheme.accent : .secondary)
                    .frame(width: 26, height: 26)
                    .background((hasLatestYear ? RiverheadTheme.accent : Color.secondary).opacity(0.10), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("2026 Filings")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RiverheadTheme.textPrimary)

                        if hasLatestYear {
                            Text("ACTIVE")
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(RiverheadTheme.accent, in: Capsule())
                        } else {
                            Text("NO 2026 DATA YET")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    if hasLatestYear {
                        HStack(spacing: 8) {
                            if latestDirect > 0 {
                                Text("Direct: \(currencyFormatter.string(from: NSNumber(value: latestDirect)) ?? "$0")")
                                    .font(.caption)
                                    .foregroundStyle(RiverheadTheme.textPrimary)
                            }
                            if latestTransfers > 0 {
                                Text("Transfers: \(currencyFormatter.string(from: NSNumber(value: latestTransfers)) ?? "$0")")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        if !schedules.isEmpty {
                            Text("Schedules: \(schedules)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        if let date = latestDate {
                            Text("Latest: \(reportDateFormatter.string(from: date))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Tap to view full filing history or use Update Filings to fetch 2026 data.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(hasLatestYear ? RiverheadTheme.accent.opacity(0.06) : Color.primary.opacity(0.035))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(hasLatestYear ? RiverheadTheme.accent.opacity(0.20) : RiverheadTheme.border.opacity(0.14), lineWidth: 0.8)
            )
            .accessibilityLabel(hasLatestYear
                ? "2026 filings active. Direct: \(currencyFormatter.string(from: NSNumber(value: latestDirect)) ?? "$0"). Tap to view details."
                : "No 2026 filing data yet. Tap to view full history or use Update Filings.")
            .accessibilityHint("Opens campaign filing detail view.")
        }
        .buttonStyle(.plain)
    }

    private func campaignDisclosureStrip(for member: CouncilMember) -> some View {
        let snapshot = campaignSnapshot(for: member)
        let direct = snapshot?.directContributions ?? snapshot?.raised ?? 0
        let flags = relatedPartyFlagLabels(for: snapshot)

        return NavigationLink {
            candidateFilingDetailView(for: member)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: flags.isEmpty ? "checkmark.seal" : "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(flags.isEmpty ? .green : .orange)
                    .frame(width: 30, height: 30)
                    .background((flags.isEmpty ? Color.green : Color.orange).opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Campaign filings")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RiverheadTheme.textPrimary)

                    Text("Direct: \(currencyFormatter.string(from: NSNumber(value: direct)) ?? "$0")")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(flags.isEmpty ? "No candidate-family financing or project-interest flags" : "Flags: \(flags.joined(separator: ", "))")
                        .font(.caption.weight(flags.isEmpty ? .regular : .semibold))
                        .foregroundStyle(flags.isEmpty ? Color.secondary : Color.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RiverheadTheme.accent)
                    .padding(.top, 7)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
        }
        .buttonStyle(.plain)
    }

    private func collapsibleSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(.top, 8)
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RiverheadTheme.textPrimary)
        }
        .tint(RiverheadTheme.accent)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.035))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(RiverheadTheme.border.opacity(0.18), lineWidth: 0.8)
        )
    }

    private var electedOfficialReportingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "clock.badge.checkmark")
                    .foregroundStyle(RiverheadTheme.accent)
                Text("Pay and Service Reporting")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
            }

            Text("This matters because Town of Riverhead service is paid public employment with a participating OSC/NYSLRS employer. For elected officials who participate in ERS/NYSLRS, Regulation 315.4 can require actual-hours documentation through a standard-work-day process and, when no eligible daily timekeeping system is used, a three-month Record of Activities. ROA work can include meetings, constituent calls, preparation, and official municipal duties; campaign events, political rallies, private organization meetings, and social time after meetings are not work-related examples.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("OSC's service-credit guide says members earn service credit for paid public employment with a participating employer, and that reported earnings and service information affect service credit, eligibility, and pension calculations. OSC's retiree guidance says earnings are generally not limited when a retiree is elected or appointed to an elected position they did not hold before retirement, but if they continue in the same elected office held before retiring, Section 212 limits may apply; for most other retirees under age 65, the $35,000 limit remains in effect for calendar year 2026.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("SeeThroughNY is included as a public transparency cross-check for payroll, pensions, contracts, spending, and benchmarking. It helps residents compare reported public compensation and spending patterns, while OSC/NYSLRS remains the official source for retirement rules and service-credit requirements.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Link("OSC rule", destination: oscEAOfficialsRegulationURL)
                Link("ROA", destination: oscEAOfficialsROAURL)
                Link("Member guide", destination: oscEAOfficialsMemberOverviewURL)
                Link("Service credit", destination: oscServiceCreditURL)
                Link("Retirees", destination: oscHiringPublicRetireesURL)
                Link("SeeThroughNY", destination: seeThroughNYURL)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(RiverheadTheme.accent)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(RiverheadTheme.accent.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(RiverheadTheme.accent.opacity(0.16), lineWidth: 0.8)
        )
    }

    private func memberPhoto(for member: CouncilMember, size: CGFloat) -> some View {
        Group {
            if let photoURL = member.photoURL {
                AsyncImage(url: photoURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.secondary.opacity(0.15))
                }
            } else {
                Circle()
                    .fill(Color.secondary.opacity(0.15))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private func scorecardStatTile(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.accent)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RiverheadTheme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.035))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    private func liaisonPreview(for member: CouncilMember) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("Committee Liaisons", systemImage: "person.3.sequence")
                .font(.caption.weight(.bold))
                .foregroundStyle(RiverheadTheme.accent)

            Text(liaisonSummaryText(for: member))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.035))
        )
    }

    private func committeeLiaisonsSection(for member: CouncilMember) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            bulletList(
                member.committeeLiaisons.isEmpty
                    ? ["None listed on the Town Hall Committees pages reviewed for this scorecard."]
                    : member.committeeLiaisons
            )

            Link("Open Town Hall Committees source", destination: townHallCommitteesURL)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RiverheadTheme.accent)
        }
    }

    private func bulletList(_ bullets: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(bullets, id: \.self) { bullet in
                BulletRow(bullet)
            }
        }
    }

    private func displayName(for member: CouncilMember) -> String {
        member.name.replacingOccurrences(of: "Honorable ", with: "")
    }

    private func termRangeText(for member: CouncilMember) -> String {
        if let starts = member.termStarts,
           let ends = member.termEnds {
            return "\(termYearFormatter.string(from: starts))-\(termYearFormatter.string(from: ends))"
        }
        if let ends = member.termEnds {
            return "Ends \(termYearFormatter.string(from: ends))"
        }
        return "Not listed"
    }

    private func nextElectionText(for member: CouncilMember) -> String {
        guard let nextElection = member.nextElection else { return "Not listed" }
        return termFormatter.string(from: nextElection)
    }

    private func payText(for member: CouncilMember) -> String {
        guard let annualPay = member.annualPay else { return "Not listed" }
        return currencyFormatter.string(from: NSNumber(value: annualPay)) ?? "$0"
    }

    private func liaisonCountText(for member: CouncilMember) -> String {
        guard !member.committeeLiaisons.isEmpty else { return "None listed" }
        return "\(member.committeeLiaisons.count) listed"
    }

    private func liaisonSummaryText(for member: CouncilMember) -> String {
        guard !member.committeeLiaisons.isEmpty else {
            return "None listed on the Town Hall Committees pages reviewed."
        }
        return member.committeeLiaisons.joined(separator: ", ")
    }

    private func serviceLengthText(for member: CouncilMember) -> String {
        guard let serviceStarted = member.serviceStarted else { return "Not listed" }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: serviceStarted, to: currentDate)
        let years = max(components.year ?? 0, 0)
        let months = max(components.month ?? 0, 0)

        if years > 0 && months > 0 {
            return "\(years)y \(months)m"
        }
        if years > 0 {
            return "\(years)y"
        }
        return "\(max(months, 0))m"
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

    private func financeMetricTile(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 9)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(tint.opacity(0.20), lineWidth: 1)
        )
    }

    private func summaryPill(_ title: String, _ amount: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(currencyFormatter.string(from: NSNumber(value: amount)) ?? "$0")
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func filingMetricRow(_ title: String, _ amount: Double?) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(currencyFormatter.string(from: NSNumber(value: amount ?? 0)) ?? "$0")
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }

    private func filingMetricText(_ title: String, _ amount: Double?) -> some View {
        Text("\(title): \(currencyFormatter.string(from: NSNumber(value: amount ?? 0)) ?? "$0")")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func currencyText(_ amount: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    @ViewBuilder
    private func yearDisclosureRow(_ year: YearBreakdown) -> some View {
        let title = "\(year.year) — \(currencyText(year.raised))"
        DisclosureGroup(title) {
            let donorLabel = "\(year.donorCount) donor" + (year.donorCount == 1 ? "" : "s")
            let avgLabel = year.avgDonationPerDonor.map { ", avg " + currencyText($0) } ?? ""
            Text(donorLabel + avgLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(year.typeBreakdown, id: \.type) { bucket in
                HStack {
                    Text("\(bucket.type) (\(bucket.donorCount))")
                    Spacer()
                    Text(currencyText(bucket.amount))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
    }

    private func contributionLimitNote(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // "2026" / "2025" / "Prior" — the two most recent years on their own, everything else lumped.
    private func filingYearBucket(_ electionYear: String) -> String {
        guard let year = Int(electionYear) else { return "Prior" }
        if year == campaignFilingEndYear { return "\(campaignFilingEndYear)" }
        if year == campaignFilingEndYear - 1 { return "\(campaignFilingEndYear - 1)" }
        return "Prior"
    }

    private func groupedFilingEvents(_ events: [CampaignFilingEvent]) -> [(bucket: String, events: [CampaignFilingEvent])] {
        let buckets = ["\(campaignFilingEndYear)", "\(campaignFilingEndYear - 1)", "Prior"]
        return buckets.compactMap { bucket in
            let matches = events
                .filter { filingYearBucket($0.electionYear) == bucket }
                .sorted { ($0.lastActivity ?? .distantPast) > ($1.lastActivity ?? .distantPast) }
            return matches.isEmpty ? nil : (bucket, matches)
        }
    }

    private func campaignFilingRow(_ event: CampaignFilingEvent, showCommitteeName: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(event.filingDesc)
                .font(.subheadline.weight(.semibold))
            Text("\(event.category), \(event.isAmendment ? "Amendment" : "Original"), \(event.electionType)"
                 + (showCommitteeName ? " · \(event.committeeName)" : ""))
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Text(currencyFormatter.string(from: NSNumber(value: event.amount)) ?? "$0")
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Text("· \(event.transactionCount) row\(event.transactionCount == 1 ? "" : "s")")
                    .foregroundStyle(.secondary)
                if let lastActivity = event.lastActivity {
                    Text("· through \(reportDateFormatter.string(from: lastActivity))")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 3)
    }

    private func relatedPartyFlagLabels(for snapshot: CampaignSnapshot?) -> [String] {
        guard let snapshot else { return [] }
        var labels: [String] = []
        if !(snapshot.petrocelliContributions ?? []).isEmpty {
            labels.append("Petrocelli")
        }
        if !(snapshot.scottPointeContributions ?? []).isEmpty {
            labels.append("Scott's Pointe")
        }
        if !(snapshot.candidateFamilyLoans ?? []).isEmpty {
            labels.append("Candidate/family financing")
        }
        return labels
    }

    private func personalRatingCard(for member: CouncilMember) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(member.name)
                        .font(.headline)
                        .foregroundStyle(RiverheadTheme.textPrimary)

                    Text(member.role)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                let personalizedScore = weightedScore(for: member)
                let personalizedGrade = grade(for: personalizedScore)
                gradeTile(
                    title: "Weighted",
                    value: "\(personalizedGrade) \(Int(personalizedScore.rounded()))",
                    color: GradeStyle.color(for: personalizedGrade)
                )
                .frame(maxWidth: 140)
            }

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
                .frame(minHeight: 110)
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
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(RiverheadTheme.Surface.elevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.border.opacity(0.22), lineWidth: 0.8)
        )
    }

    private func weightSlider(for category: ScoreCategory) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Label(category.title, systemImage: category.icon)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Spacer(minLength: 8)

                Text("\(weight(for: category), specifier: "%.1f")x")
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(RiverheadTheme.accent)
            }

            Slider(value: weightBinding(for: category), in: 0...2, step: 0.25)
                .tint(RiverheadTheme.accent)
        }
    }

    private func weightBinding(for category: ScoreCategory) -> Binding<Double> {
        Binding(
            get: { weight(for: category) },
            set: { newValue in
                switch category {
                case .budget: budgetWeight = newValue
                case .transparency: transparencyWeight = newValue
                case .housing: housingWeight = newValue
                case .responsiveness: responseWeight = newValue
                case .ethics: ethicsWeight = newValue
                case .capital: capitalWeight = newValue
                }
            }
        )
    }

    private func timelineRow(date: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(date)
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(RiverheadTheme.accent)
                .frame(width: 92, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func accountabilityScoreSection(for member: CouncilMember) -> some View {
        let memberScores = scores(for: member)
        let memberNotes  = scoreNotes(for: member)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Explainable Scores")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            radarChart(scores: memberScores)

            ForEach(memberScores) { score in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Label(score.category.title, systemImage: score.category.icon)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.textPrimary)
                        Spacer(minLength: 8)
                        Text("\(Int(score.value.rounded()))")
                            .font(.caption.weight(.bold))
                            .monospacedDigit()
                            .foregroundStyle(GradeStyle.color(for: grade(for: score.value)))
                    }
                    ProgressView(value: score.value, total: 100)
                        .tint(GradeStyle.color(for: grade(for: score.value)))
                    Text(memberNotes[score.category] ?? score.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    // MARK: Radar / spider chart

    private func radarChart(scores: [AccountabilityScore]) -> some View {
        let n = scores.count
        guard n > 2 else { return AnyView(EmptyView()) }
        return AnyView(
            GeometryReader { geo in
                let cx   = geo.size.width  / 2
                let cy   = geo.size.height / 2
                let maxR = min(cx, cy) * 0.72

                ZStack {
                    // Reference rings at 25 / 50 / 75 / 100
                    ForEach([0.25, 0.50, 0.75, 1.00], id: \.self) { pct in
                        Path { p in
                            for i in 0..<n {
                                let angle = spokeAngle(i, of: n)
                                let pt = CGPoint(x: cx + maxR * pct * cos(angle),
                                                 y: cy + maxR * pct * sin(angle))
                                i == 0 ? p.move(to: pt) : p.addLine(to: pt)
                            }
                            p.closeSubpath()
                        }
                        .stroke(Color.gray.opacity(0.18), lineWidth: 0.6)
                    }

                    // Spokes
                    ForEach(0..<n, id: \.self) { i in
                        Path { p in
                            let angle = spokeAngle(i, of: n)
                            p.move(to: CGPoint(x: cx, y: cy))
                            p.addLine(to: CGPoint(x: cx + maxR * cos(angle),
                                                   y: cy + maxR * sin(angle)))
                        }
                        .stroke(Color.gray.opacity(0.22), lineWidth: 0.6)
                    }

                    // Filled data polygon
                    Path { p in
                        for (i, score) in scores.enumerated() {
                            let angle = spokeAngle(i, of: n)
                            let r = maxR * score.value / 100
                            let pt = CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
                            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
                        }
                        p.closeSubpath()
                    }
                    .fill(RiverheadTheme.accent.opacity(0.18))

                    // Stroke data polygon
                    Path { p in
                        for (i, score) in scores.enumerated() {
                            let angle = spokeAngle(i, of: n)
                            let r = maxR * score.value / 100
                            let pt = CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
                            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
                        }
                        p.closeSubpath()
                    }
                    .stroke(RiverheadTheme.accent, lineWidth: 1.8)

                    // Dots at each vertex
                    ForEach(Array(scores.enumerated()), id: \.offset) { i, score in
                        let angle = spokeAngle(i, of: n)
                        let r = maxR * score.value / 100
                        Circle()
                            .fill(GradeStyle.color(for: grade(for: score.value)))
                            .frame(width: 7, height: 7)
                            .position(x: cx + r * cos(angle), y: cy + r * sin(angle))
                    }

                    // Axis labels
                    ForEach(Array(scores.enumerated()), id: \.offset) { i, score in
                        let angle = spokeAngle(i, of: n)
                        let labelR = maxR * 1.22
                        VStack(spacing: 0) {
                            Image(systemName: score.category.icon)
                                .font(.system(size: 9))
                            Text("\(Int(score.value.rounded()))")
                                .font(.system(size: 9, weight: .bold))
                                .monospacedDigit()
                        }
                        .foregroundStyle(GradeStyle.color(for: grade(for: score.value)))
                        .position(x: cx + labelR * cos(angle), y: cy + labelR * sin(angle))
                    }
                }
            }
            .frame(height: 210)
        )
    }

    private func spokeAngle(_ i: Int, of n: Int) -> Double {
        (Double(i) / Double(n)) * 2 * .pi - .pi / 2
    }

    private func evidenceSection(for member: CouncilMember) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Evidence Behind the Grade")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            ForEach(evidence(for: member)) { item in
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RiverheadTheme.textPrimary)
                    Text(item.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let sourceLabel = item.sourceLabel,
                       let sourceURL = item.sourceURL {
                        Link(sourceLabel, destination: sourceURL)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.accent)
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    private func candidateLensSection(_ context: CandidateContext) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(context.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(context.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(context.bullets, id: \.self) { bullet in
                BulletRow(bullet)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(RiverheadTheme.accent.opacity(0.08))
        )
    }

    private func residentActionSection(for member: CouncilMember) -> some View {
        BulletSection(title: "Resident action prompts", bullets: residentActions(for: member))
    }

    private func followUpSection(for member: CouncilMember) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Needs Follow-Up", systemImage: "flag")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RiverheadTheme.textPrimary)

            ForEach(followUpFlags(for: member), id: \.self) { flag in
                BulletRow(flag)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.18), lineWidth: 0.8)
        )
    }

    private func scores(for member: CouncilMember) -> [AccountabilityScore] {
        if !member.scores.isEmpty { return member.scores }
        switch member.name {
        case let name where name.contains("Halpin"):
            return scoreSet(budget: 82, transparency: 78, housing: 80, responsiveness: 80, ethics: 76, capital: 78)
        case let name where name.contains("Rothwell"):
            return scoreSet(budget: 78, transparency: 76, housing: 75, responsiveness: 74, ethics: 72, capital: 79)
        case let name where name.contains("Waski"):
            return scoreSet(budget: 80, transparency: 79, housing: 81, responsiveness: 84, ethics: 78, capital: 76)
        case let name where name.contains("Kern"):
            return scoreSet(budget: 75, transparency: 76, housing: 74, responsiveness: 73, ethics: 72, capital: 78)
        case let name where name.contains("Merrifield"):
            return scoreSet(budget: 74, transparency: 75, housing: 76, responsiveness: 80, ethics: 73, capital: 72)
        default:
            return scoreSet(budget: 75, transparency: 75, housing: 75, responsiveness: 75, ethics: 75, capital: 75)
        }
    }

    private func evidence(for member: CouncilMember) -> [EvidenceItem] {
        if !member.evidence.isEmpty { return member.evidence }
        var items = [
            townBoardSource,
            EvidenceItem(
                title: "Campaign finance disclosure",
                detail: "Candidate committee totals and donor-detail checks are pulled from NY Open Data where available.",
                sourceLabel: "NYS Filings",
                sourceURL: nyCampaignDisclosureURL
            )
        ]

        if member.role.localizedCaseInsensitiveContains("Supervisor") {
            items.append(
                EvidenceItem(
                    title: "Administration capacity",
                    detail: "Senior staff selection should be tracked as an early signal for budget execution, department coordination, and capital-project follow-through.",
                    sourceLabel: nil,
                    sourceURL: nil
                )
            )
        }

        return items
    }

    private func candidateContext(for member: CouncilMember) -> CandidateContext? {
        if let context = member.candidateContext { return context }
        if member.name.contains("Rothwell") {
            return CandidateContext(
                title: "Candidate Lens: Supervisor Run",
                summary: "Because this council member is mapped to a supervisor campaign filing, the scorecard separates current governing performance from candidate capacity.",
                bullets: [
                    "Ask what senior staff roles would change in the first 100 days.",
                    "Ask how the administration would handle budget preparation, grant management, and department performance reviews.",
                    "Compare campaign finance strength with an actual governing plan, not as a substitute for one."
                ]
            )
        }
        return nil
    }

    private func residentActions(for member: CouncilMember) -> [String] {
        if !member.residentActions.isEmpty { return member.residentActions }
        var actions = [
            "Ask for one measurable budget or service outcome this official wants published before the next budget vote.",
            "Ask which vote, amendment, or public question best shows their current priority.",
            "Use the Personal Grading Notebook after a meeting if you want to save your own grade and notes."
        ]
        if member.role.localizedCaseInsensitiveContains("Supervisor") || member.name.contains("Rothwell") {
            actions.insert("Ask who would hold the senior operations, finance, planning, and communications roles in a supervisor administration.", at: 0)
        }
        return actions
    }

    private func followUpFlags(for member: CouncilMember) -> [String] {
        if !member.followUpFlags.isEmpty { return member.followUpFlags }
        var flags = [
            "Tie the grade to specific votes and meeting timestamps as the public record dataset improves.",
            "Refresh NY Open Data filings before relying on campaign-finance totals."
        ]
        if member.role.localizedCaseInsensitiveContains("Supervisor") || member.name.contains("Rothwell") {
            flags.append("Watch for named senior staff, qualifications, and reporting structure for any incoming supervisor administration.")
        }
        return flags
    }

    // MARK: Member-specific score notes

    private func scoreNotes(for member: CouncilMember) -> [ScoreCategory: String] {
        if member.name.contains("Halpin") {
            return [
                .budget:         "New Supervisor entering mid-cycle. Watch first budget modification proposal and whether recurring vs. one-time uses are explicitly labeled.",
                .transparency:   "First months set the tone for agenda lead time, meeting audio/video, and whether action-item follow-up is published. Score pending record.",
                .housing:        "Downtown and workforce-housing posture TBD. Key early signal: whether IDA or CP applications include any income-restricted units.",
                .responsiveness: "Campaign emphasized responsiveness. Monitor whether constituent emails receive dated written replies and whether public-comment periods are upheld.",
                .ethics:         "Campaign committee contact shares Halpin name and address — standard disclosure watch. No conflict flags in first term yet.",
                .capital:        "Town Hall BAN ($22M exposure), highway garage authorization ($1.88M), and fleet requests all need sequenced capital decision-making in 2026."
            ]
        } else if member.name.contains("Rothwell") {
            return [
                .budget:         "Longest tenure on capital and procurement. Watch whether supervisor campaign fundraising shifts vote alignment on IDA, developer agreements, or capital approvals.",
                .transparency:   "Has asked pointed procedural questions at meetings. Score depends on whether those questions consistently produce written staff responses.",
                .housing:        "Supported business-district revival framing. Housing score contingent on whether affordable units are required conditions or treated as optional.",
                .responsiveness: "Veterans and traffic safety committee liaisons suggest constituent-track record. Watch meeting attendance and amendment introduction rate.",
                .ethics:         "Largest campaign fundraiser on the board by a significant margin ($146K reported). Petrocelli and Scott Pointe contribution flags warrant watching on related land-use votes.",
                .capital:        "Strong capital-planning instinct. Score limited by whether phasing plans include debt-service projections and CHIPS eligibility documentation."
            ]
        } else if member.name.contains("Waski") {
            return [
                .budget:         "IDA and Farmland Preservation liaisons suggest mixed budget exposure. Watch whether IDA incentive packages include quantified fiscal impact on the tax levy.",
                .transparency:   "Downtown Revitalization liaison provides natural platform for public-facing progress reporting. Score based on how actively that platform is used.",
                .housing:        "Landmarks and farmland preservation liaisons signal a quality-over-quantity posture. Key question: how are affordable units built into downtown projects she supports?",
                .responsiveness: "Constituent-oriented record in first term. Personnel liaison also gives insight into staffing decisions that affect service delivery.",
                .ethics:         "No significant campaign-finance flags. Committee to Manzella-linked treasurer is a standard watch item consistent with other Suffolk Democratic filings.",
                .capital:        "East Creek and farmland preservation involve capital-adjacent decisions (conservation easements, infrastructure). Watch cost-per-acre and maintenance burden."
            ]
        } else if member.name.contains("Kern") {
            return [
                .budget:         "Open Space and Recreation Advisory liaisons create regular capital-pressure exposure. Watch whether he asks for actuarial or maintenance-cost analysis before adding amenities.",
                .transparency:   "Architectural Review Board liaison involves discretionary design decisions with limited public record. Watch whether ARB minutes are published promptly.",
                .housing:        "Alternative Transportation and Environmental Advisory suggest climate-aligned posture. Housing score depends on whether zoning changes include density and affordability.",
                .responsiveness: "Wildlife Management and Recreation Advisory are constituent-facing roles. Meeting attendance rate and amendment-introduction frequency are the observable indicators.",
                .ethics:         "Two-committee structure (legacy Friends of Bob Kern + current Friends of Robert Kern) warrants combined review of donor overlap. No hard conflict flags yet.",
                .capital:        "Agriculture and open space decisions are inherently long-horizon. Score reflects whether proposals include explicit sequencing and funding-source identification."
            ]
        } else if member.name.contains("Merrifield") {
            return [
                .budget:         "Disability Advisory and Senior Citizen liaisons involve populations sensitive to service cuts. Watch whether she raises constituent impact in budget modification discussions.",
                .transparency:   "Code Revision Committee work should produce a public change log. Score based on whether proposed revisions are published in advance with plain-English summaries.",
                .housing:        "Climate Smart and Parking District liaisons are indirectly housing-adjacent. Watch whether she connects parking policy to missing-middle housing discussions.",
                .responsiveness: "Highest responsiveness score reflects senior and disability constituent access focus. Sustained by consistent meeting attendance and follow-up record.",
                .ethics:         "Committee chair shares address with candidate. Standard watch item, no hard conflict flags as of last review. TERMINATED status on committee record is consistent with post-election wind-down.",
                .capital:        "No direct capital committee liaison. Score reflects general pattern of raising constituent service questions rather than capital-project sequencing questions."
            ]
        }
        return [:]
    }

    // MARK: Board comparison leaderboard card

    private var boardComparisonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundStyle(RiverheadTheme.accent)
                Text("Board Comparison")
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.textPrimary)
                Spacer()
                Text("All six dimensions")
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)
            }

            Text("Score per official per category (0–100). Sorted by weighted average.")
                .font(.caption)
                .foregroundStyle(RiverheadTheme.textSecondary)

            let sortedMembers = members.sorted { weightedScore(for: $0) > weightedScore(for: $1) }

            ForEach(ScoreCategory.allCases) { category in
                VStack(alignment: .leading, spacing: 5) {
                    Label(category.title, systemImage: category.icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.textPrimary)

                    ForEach(sortedMembers) { member in
                        let memberScore = scores(for: member).first(where: { $0.category == category })?.value ?? 75
                        HStack(spacing: 8) {
                            Text(shortName(for: member))
                                .font(.caption2)
                                .foregroundStyle(RiverheadTheme.textSecondary)
                                .frame(width: 68, alignment: .leading)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.gray.opacity(0.12))
                                        .frame(height: 10)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(GradeStyle.color(for: grade(for: memberScore)).opacity(0.75))
                                        .frame(width: geo.size.width * memberScore / 100, height: 10)
                                }
                            }
                            .frame(height: 10)

                            Text("\(Int(memberScore.rounded()))")
                                .font(.caption2.weight(.bold))
                                .monospacedDigit()
                                .foregroundStyle(GradeStyle.color(for: grade(for: memberScore)))
                                .frame(width: 26, alignment: .trailing)
                        }
                    }
                }
                if category != ScoreCategory.allCases.last {
                    Divider().opacity(0.2)
                }
            }

            Divider().opacity(0.3)

            // Weighted average summary row
            HStack(spacing: 0) {
                Text("Weighted avg")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .frame(width: 76, alignment: .leading)
                Spacer()
                ForEach(sortedMembers) { member in
                    VStack(spacing: 1) {
                        Text(shortName(for: member))
                            .font(.caption2)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                        Text(grade(for: weightedScore(for: member)))
                            .font(.caption.weight(.black))
                            .foregroundStyle(GradeStyle.color(for: grade(for: weightedScore(for: member))))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(RiverheadTheme.Surface.elevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.border.opacity(0.22), lineWidth: 0.8)
        )
    }

    private func shortName(for member: CouncilMember) -> String {
        if member.name.contains("Halpin") { return "Halpin" }
        if member.name.contains("Rothwell") { return "Rothwell" }
        if member.name.contains("Waski") { return "Waski" }
        if member.name.contains("Kern") { return "Kern" }
        if member.name.contains("Merrifield") { return "Merrifield" }
        return String(member.name.split(separator: " ").last ?? "")
    }

    // MARK: Key questions per member

    private func keyQuestions(for member: CouncilMember) -> [String] {
        if member.name.contains("Halpin") {
            return [
                "Will the 2027 budget distinguish recurring revenues from one-time fund balance draws, and will that distinction be published in the adopted budget document?",
                "Which senior administration roles (CFO, Town Attorney, Planning Director) have been filled, and what are their qualifications?",
                "How does the Town plan to refinance or retire the estimated $22M in BANs coming due in 2026 for Town Hall and Town Square properties?",
                "Will you commit to publishing Town Board meeting agendas at least 72 hours before each session with supporting documents?",
                "What is the administration's policy on using fund balance to offset the tax levy — under what conditions and with what replenishment timeline?"
            ]
        } else if member.name.contains("Rothwell") {
            return [
                "Given that your campaign committee raised $146K — the largest on the board — have you recused yourself from any votes involving major donors?",
                "As a Supervisor candidate, how do you separate your governing record on the current board from your campaign platform?",
                "What specific changes to the IDA incentive package review process would you require as Supervisor?",
                "Which of the Town's top three capital needs would you fund first, and what financing tool would you use?",
                "How would your first 100-day budget review differ from the current Supervisor's approach?"
            ]
        } else if member.name.contains("Waski") {
            return [
                "Every IDA application you review as liaison: does the project include income-restricted housing units, and if not, what is your ask?",
                "The East Creek Advisory Committee reports to you — what is the current capital plan for remediation, and who is paying?",
                "The Downtown Revitalization Committee: what is the measurable 12-month goal, and how will you report progress publicly?",
                "Farmland Preservation: what is Riverhead's current preservation target acreage, and how does the CPF drawdown rate affect future conservation capacity?",
                "The Personnel committee liaison is a board role affecting all staff decisions. What hiring or retention policies would you change in 2026?"
            ]
        } else if member.name.contains("Kern") {
            return [
                "Open Space Committee purchases: what is the annual CPF contribution level, and is the fund actuarially sustainable at current draw rates?",
                "Environmental Advisory: how do you translate the committee's recommendations into binding land-use conditions rather than advisory opinions?",
                "Recreation Advisory: which Recreation Department capital requests from 2024 were completed, and which remain unfunded?",
                "Alternative Transportation: does the Town have a completed, funded bike lane or pedestrian plan — and if not, what is the specific block?",
                "With two overlapping campaign committees (filer IDs 527501 and 154941), have you filed a final C-7 termination with NYSBOE to close the legacy committee?"
            ]
        } else if member.name.contains("Merrifield") {
            return [
                "Disability Advisory: has the Town completed an ADA Transition Plan, and what is the current compliance backlog for public facilities?",
                "Senior Citizen Advisory: which senior services are facing funding reductions in the 2027 budget proposal, and what is your position?",
                "Climate Smart Community Task Force: has Riverhead adopted a formal Climate Smart resolution, and what is the binding commitment timeline?",
                "Parking District Advisory: how does the Town's parking pricing and supply policy affect housing density in the downtown corridor?",
                "Code Revision Committee: which code amendments proposed in 2024 or 2025 are still pending, and what is holding them up?"
            ]
        }
        return [
            "Ask which vote, amendment, or public question from the past six months best shows this official's current priority.",
            "Ask for one measurable outcome they want published before the next budget vote.",
            "Ask whether they have reviewed the Town's fund-balance policy and whether they support updating it in 2026."
        ]
    }

    private func keyQuestionsSection(for member: CouncilMember) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Questions to Ask at the Next Meeting")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Text("Evidence-backed, open-ended questions any resident can raise during public comment.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(keyQuestions(for: member).enumerated()), id: \.offset) { i, q in
                HStack(alignment: .top, spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(RiverheadTheme.accent.opacity(0.12))
                            .frame(width: 22, height: 22)
                        Text("\(i + 1)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(RiverheadTheme.accent)
                    }
                    Text(q)
                        .font(.caption)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(RiverheadTheme.accent.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(RiverheadTheme.accent.opacity(0.15), lineWidth: 0.8)
        )
    }

    private func topContributionRow(title: String, contribution: TopContribution, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Text(currencyFormatter.string(from: NSNumber(value: contribution.amount)) ?? "$0")
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(tint)
            }

            Text(contribution.donorName)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                if let date = contribution.date {
                    Text(reportDateFormatter.string(from: date))
                }
                if let contributorType = contribution.contributorType,
                   !contributorType.isEmpty {
                    Text(contributorType)
                }
                if let schedule = contribution.schedule,
                   !schedule.isEmpty {
                    Text(schedule)
                }
                if let filingLabel = contribution.filingLabel,
                   !filingLabel.isEmpty {
                    Text(filingLabel)
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(tint.opacity(0.08))
        )
    }

    private func petrocelliDisclosureNote(for snapshot: CampaignSnapshot) -> some View {
        let contributions = snapshot.petrocelliContributions ?? []
        let total = contributions.reduce(0) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: contributions.isEmpty ? "checkmark.shield" : "exclamationmark.triangle.fill")
                    .foregroundStyle(contributions.isEmpty ? .green : .orange)
                Text("Petrocelli Project-Interest Watch")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
            }

            if contributions.isEmpty {
                Text("No Petrocelli-named individual, related business, Hp East End Riverhead LLC, or known venue/entity donor rows were found in NY Open Data for this mapped candidate committee across the 2005–2026 filing window.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Petrocelli project-interest donations found: \(currencyFormatter.string(from: NSNumber(value: total)) ?? "$0") across \(contributions.count) contribution\(contributions.count == 1 ? "" : "s").")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Scope (2005–2026): this is a corporate/project-interest watch, not candidate immediate-family support. It matches Petrocelli-named donor fields (covering J Petrocelli Construction, J. Petrocelli Contracting, J. Petrocelli Development Inc, J. Petrocelli Cont. Inc, J Petrocelli Wine Cellars LLC, J. Petrocelli Cellars LLC, J. Petrocelli Riverhead Town Square LLC, M. Petrocelli, Marie Petrocelli, Michael Petrocelli, Jennifer Petrocelli) and Hp East End Riverhead LLC, as well as known related business/venue watch terms from public profiles, including Jacqueline Phillips, Alexandra Bussi, The Preston House, Atlantis Banquets, Sea Star Ballroom, Taste the East End, Raphael Vineyard, Long Island Aquarium, and Hyatt Place East End. The public-source basis includes Schneps / QNS and Dan's Papers profiles. These matches are transparency context, not proof of coordination or quid pro quo.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(Array(contributions.enumerated()), id: \.offset) { _, contribution in
                    topContributionRow(title: "Matched related donor", contribution: contribution, tint: .orange)
                }

                Text(total > 1_000 ? "Ethics implication: because the matched donor total is above the $1,000 aggregation threshold discussed in the Town ethics summary, any related Town matter should be publicly disclosed and reviewed for conflict handling. For elected officials, disclosure is the minimum guardrail; recusal may still be appropriate depending on the matter and legal advice." : "Ethics implication: the matched total is below the $1,000 aggregation threshold discussed in the Town ethics summary, so it does not by itself establish a code violation or automatic recusal requirement. It still warrants transparency if Petrocelli-related business comes before the Town, because the public concern is appearance, access, and whether any official action could look tied to campaign support.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.orange.opacity(contributions.isEmpty ? 0.06 : 0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.orange.opacity(contributions.isEmpty ? 0.12 : 0.24), lineWidth: 1)
        )
    }

    private func scottPointeDisclosureNote(for snapshot: CampaignSnapshot) -> some View {
        let contributions = snapshot.scottPointeContributions ?? []
        let total = contributions.reduce(0) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: contributions.isEmpty ? "checkmark.shield" : "water.waves")
                    .foregroundStyle(contributions.isEmpty ? .green : RiverheadTheme.brandSky)
                Text("Scott's Pointe Project-Interest Watch")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
            }

            if contributions.isEmpty {
                Text("No donor rows matching Scott's Pointe, Island Water Park Corp, Island Waterpark, Island Water Sports, Lake View Grill, Eric Scott, Claudia Scott, Cody Scott, Jake Scott, Ken Myers, or Grant Anderson were found in NY Open Data for this mapped candidate committee.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Scott's Pointe / Island Water Park-related donations found: \(currencyFormatter.string(from: NSNumber(value: total)) ?? "$0") across \(contributions.count) contribution\(contributions.count == 1 ? "" : "s").")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.brandSky)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Scope: this is a corporate/project-interest watch, not candidate immediate-family support. It matches the family-owned and operated Calverton adventure park interest tied to Island Water Park Corp., Island Water Sports, and Lake View Grill. Northforker reported that Eric, Cody, and Jake Scott run daily operations, that Ken Myers is Cody Scott's cousin and oversees Lake View Grill, and that the Scotts own Calverton's Island Water Sports boat dealership. RiverheadLOCAL's 2026 drifting-track opinion also identifies project manager Ken Myers and drift racer Grant Anderson in the track-use record. These rows are transparency context, not proof of improper conduct.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Enforcement context: RiverheadLOCAL reported on July 18, 2025 that Riverhead Police seized suspected illegal fireworks at Scott's Pointe after a fire marshal alert. The article reported the matter was under investigation and that no charges had been filed at publication, so this should be shown as a compliance/watch item rather than a finding of guilt.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Economic-development context: early 2021 coverage presented Island Water Park/Scott's Pointe as a 42-acre destination attraction with a manmade lake, indoor surf, aquapark, bumper boats, and other activities, with officials and media framing it as a tourism/jobs generator. Use this alongside the later permitting, enforcement, IDA-benefit, and compliance record when weighing public-value claims.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Attraction and tax-benefit context: Northforker described Scott's Pointe as a 43-acre indoor-outdoor park with a 75,000-square-foot building, indoor surf wave, aquapark, laser tag, golf simulators, ax throwing, restaurant uses, a 13-acre lake, and pricing that included general admission plus separate surf and simulator fees. The same feature reported more than $70 million spent developing the park, a 10-year property tax abatement from Riverhead, and an estimate of 900,000 annual guests.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Lawsuit and public-hearing context: Newsday covered the Scott's Pointe/Calverton lawsuit, and Riverhead News-Review reported that the Jan. 22, 2025 public hearing on Scott's Pointe's amended application was packed with supporters who emphasized recreation, youth/family benefits, jobs, and the local economy. The same public record also includes allegations and settlement terms around unauthorized construction, code violations, environmental impacts, a $50,000 town settlement, $5,700 in Town Code fines, lower revised job projections, possible restoration obligations if approvals fail, and pending DEC reclamation review.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Track-use context: RiverheadLOCAL argued on Apr. 20, 2026 that removing the go-karts-only covenant for auto drifting would change the environmental basis of the Town's prior SEQRA review. The opinion cites the track's location near a manmade lake in the aquifer, Town and DEC spill/runoff concerns, and online drifting videos involving Cody Scott, Eric Scott, Claudia Scott, and Grant Anderson.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(Array(contributions.enumerated()), id: \.offset) { _, contribution in
                    topContributionRow(title: "Matched donor", contribution: contribution, tint: RiverheadTheme.brandSky)
                }

                Text(total > 1_000 ? "Ethics implication: this disclosure group exceeds the $1,000 aggregation threshold discussed in the Town ethics summary, so any Scott's Pointe, Island Water Park, or related Town matter should be publicly disclosed and reviewed for conflict handling before the official participates." : "Ethics implication: this disclosure group is at or below the $1,000 aggregation threshold discussed in the Town ethics summary, so it does not by itself establish an automatic violation. It still deserves disclosure discipline if Scott's Pointe, Island Water Park, or related applications, contracts, approvals, or enforcement matters come before the Town.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(RiverheadTheme.brandSky.opacity(contributions.isEmpty ? 0.05 : 0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(RiverheadTheme.brandSky.opacity(contributions.isEmpty ? 0.12 : 0.24), lineWidth: 1)
        )
    }

    private func familyLinkedDisclosureNote(for snapshot: CampaignSnapshot) -> some View {
        let contributions = snapshot.familyLinkedContributions ?? []
        let total = contributions.reduce(0) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: contributions.isEmpty ? "checkmark.shield" : "person.2.fill")
                    .foregroundStyle(contributions.isEmpty ? .green : RiverheadTheme.accent)
                Text("Candidate Household Support")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
            }

            if contributions.isEmpty {
                Text("No candidate household donor rows were found. This bucket is for immediate-family, spouse, household, or explicitly mapped candidate-family support only; corporate and project-related donor groups appear in their own project-interest watch sections.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Candidate household donations found: \(currencyFormatter.string(from: NSNumber(value: total)) ?? "$0") across \(contributions.count) contribution\(contributions.count == 1 ? "" : "s").")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.accent)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(Array(contributions.enumerated()), id: \.offset) { _, contribution in
                    topContributionRow(title: "Candidate household donor", contribution: contribution, tint: RiverheadTheme.accent)
                }

                Text("Treatment: these rows remain in legally reported fundraising totals, but the scorecard separates immediate-family/household support from outside donor strength and from corporate/project-interest donors. They are disclosure context, not an ethics-conflict finding, unless a town contract, land-use matter, employment interest, reimbursement pattern, or other official-action link is verified.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(RiverheadTheme.accent.opacity(contributions.isEmpty ? 0.05 : 0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(RiverheadTheme.accent.opacity(contributions.isEmpty ? 0.12 : 0.24), lineWidth: 1)
        )
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
                .foregroundStyle(RiverheadTheme.textPrimary)

            Text("Grades are informal and meant to spark civic discussion. Term dates follow the even-year election transition baseline while the federal challenge remains pending; verify final election calendars with the Suffolk County Board of Elections. NYS Filings links open the state disclosure search page for candidate/committee records. Filing totals use the \(campaignFilingYearRangeLabel) window; use Update Filings to pull current totals and reporting dates from NY Open Data.")
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
        // Allow former members with only a filer ID — they have no baseline financials but
        // still need a snapshot so live-fetched Petrocelli data enters the totals.
        guard member.campaignRaised != nil || member.campaignLastReported != nil || member.campaignFilerID != nil else { return nil }
        return CampaignSnapshot(
            committeeName: member.campaignCommitteeName,
            filerID: member.campaignFilerID,
            filingDetails: campaignFilings(for: member).map {
                CampaignFilingSnapshot(
                    committeeName: $0.committeeName,
                    filerID: $0.filerID,
                    raised: $0.filerID == member.campaignFilerID ? member.campaignRaised : nil,
                    directContributions: $0.filerID == member.campaignFilerID ? member.campaignDirectContributions : nil,
                    transfersIn: $0.filerID == member.campaignFilerID ? member.campaignTransfersIn : nil,
                    lastReported: $0.filerID == member.campaignFilerID ? member.campaignLastReported : nil
                )
            },
            raised: member.campaignRaised,
            directContributions: member.campaignDirectContributions,
            transfersIn: member.campaignTransfersIn,
            currentYearDirectContributions: nil,
            currentYearTransfersIn: nil,
            currentYearFilingActivityAmount: nil,
            currentYearFilingActivityRowCount: nil,
            currentYearFilingActivitySchedules: nil,
            currentYearLastReported: nil,
            latestYearDirect: nil,
            latestYearTransfers: nil,
            latestYearFilingAmount: nil,
            latestYearRowCount: nil,
            latestYearSchedules: nil,
            latestYearLastReported: nil,
            largestIndividualContribution: nil,
            largestBusinessContribution: nil,
            petrocelliContributions: baselinePetrocelliContributions(for: member),
            scottPointeContributions: baselineScottPointeContributions(for: member),
            familyLinkedContributions: baselineFamilyLinkedContributions(for: member),
            candidateFamilyLoans: baselineCandidateFamilyFinancing(for: member),
            lastReported: member.campaignLastReported,
            loanAmount: member.campaignLoanAmount,
            loanLastReported: member.campaignLoanLastReported,
            filingEvents: nil,
            donorCount: nil,
            avgDonationPerDonor: nil,
            contributorTypeBreakdown: nil,
            outstandingLoanAmount: nil,
            outstandingLoanYear: nil,
            historicalByYear: nil
        )
    }

    /// Riverhead town population — U.S. Census Bureau QuickFacts 2024 estimate. Used only to
    /// contextualize a committee's raised total as a "per resident" figure, not a per-capita claim
    /// about spending or services.
    private let riverheadPopulationEstimate2024 = 35_980

    private func contributorTypeBucket(_ desc: String?) -> String {
        let lower = (desc ?? "").lowercased()
        if lower.contains("individual") { return "Individual" }
        if lower.contains("committee") || lower.contains("party") || lower.contains("pac") { return "PAC / Committee" }
        return "Business / Other"
    }

    private func baselinePetrocelliContributions(for member: CouncilMember) -> [TopContribution]? {
        guard member.campaignFilerID == "154927" else { return [] }
        return [
            TopContribution(
                donorName: "J. Petrocelli Development Associates",
                amount: 500,
                date: makeDate(year: 2021, month: 10, day: 7),
                contributorType: "Association",
                schedule: "C",
                filingLabel: "2021 11-Day Pre-General"
            ),
            TopContribution(
                donorName: "J Petrocelli Contracting Inc",
                amount: 250,
                date: makeDate(year: 2021, month: 6, day: 23),
                contributorType: "Corporation",
                schedule: "B",
                filingLabel: "2021 July Periodic"
            )
        ]
    }

    private func baselineScottPointeContributions(for member: CouncilMember) -> [TopContribution]? {
        if member.campaignFilerID == "154927" {
            return [
                TopContribution(
                    donorName: "Eric Scott",
                    amount: 1_200,
                    date: makeDate(year: 2025, month: 9, day: 30),
                    contributorType: "Individual",
                    schedule: "A",
                    filingLabel: "2025 11-Day Pre-General"
                ),
                TopContribution(
                    donorName: "Jake Scott",
                    amount: 1_200,
                    date: makeDate(year: 2025, month: 9, day: 30),
                    contributorType: "Individual",
                    schedule: "A",
                    filingLabel: "2025 11-Day Pre-General"
                )
            ]
        }

        if member.campaignFilerID == "527501" {
            return [
                TopContribution(
                    donorName: "Eric Scott",
                    amount: 1_000,
                    date: makeDate(year: 2025, month: 8, day: 27),
                    contributorType: "Individual",
                    schedule: "A",
                    filingLabel: "2025 32-Day Pre-General"
                )
            ]
        }

        return []
    }

    private func baselineFamilyLinkedContributions(for member: CouncilMember) -> [TopContribution]? {
        return []
    }

    private func baselineCandidateFamilyFinancing(for member: CouncilMember) -> [TopContribution]? {
        if member.campaignFilerID == "506796" {
            return [
                TopContribution(
                    donorName: "Jerry Halpin",
                    amount: 5_000,
                    date: makeDate(year: 2025, month: 8, day: 11),
                    contributorType: "Candidate/Candidate Spouse",
                    schedule: "N",
                    filingLabel: "2025 Outstanding Liabilities/Loans"
                )
            ]
        }

        return []
    }

    private func campaignSnapshot(for member: CouncilMember) -> CampaignSnapshot? {
        if let fetched = fetchedCampaignSnapshots[member.id] {
            return fetched
        }
        return baselineCampaignSnapshot(for: member)
    }

    private func campaignFilings(for member: CouncilMember) -> [CampaignFilingRef] {
        var filings: [CampaignFilingRef] = []
        if let filerID = member.campaignFilerID,
           let committeeName = member.campaignCommitteeName {
            filings.append(CampaignFilingRef(committeeName: committeeName, filerID: filerID, note: nil))
        }
        filings.append(contentsOf: member.additionalCampaignFilings)
        return filings
    }

    private func campaignFilerIDs(for member: CouncilMember) -> [String] {
        campaignFilings(for: member).map(\.filerID)
    }

    private func parseAPIDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if let d = apiDateFormatter.date(from: trimmed) { return d }
        if let d = apiDateFormatterNoFraction.date(from: trimmed) { return d }
        return apiDateWithoutTimeZoneFormatter.date(from: trimmed)
    }

    private func parseAmount(_ value: String?) -> Double? {
        guard let value else { return nil }
        let cleaned = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        return Double(cleaned)
    }

    private func donorName(for row: ContributionRow) -> String {
        if let entity = row.flng_ent_name?.trimmingCharacters(in: .whitespacesAndNewlines),
           !entity.isEmpty {
            return entity
        }

        let parts = [
            row.flng_ent_first_name,
            row.flng_ent_middle_name,
            row.flng_ent_last_name
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

        return parts.isEmpty ? "Name not listed" : parts.joined(separator: " ")
    }

    private func donorName(for row: LoanDetailRow) -> String {
        if let entity = row.flng_ent_name?.trimmingCharacters(in: .whitespacesAndNewlines),
           !entity.isEmpty {
            return entity
        }

        let parts = [
            row.flng_ent_first_name,
            row.flng_ent_middle_name,
            row.flng_ent_last_name
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

        return parts.isEmpty ? "Name not listed" : parts.joined(separator: " ")
    }

    private func isIndividualContribution(_ row: ContributionRow) -> Bool {
        row.cntrbr_type_desc?.caseInsensitiveCompare("Individual") == .orderedSame
    }

    private func isBusinessOrEntityContribution(_ row: ContributionRow) -> Bool {
        let schedule = row.filing_sched_abbrev?.uppercased() ?? ""
        if schedule == "B" { return true }

        let type = row.cntrbr_type_desc?.lowercased() ?? ""
        let businessTerms = [
            "corporation",
            "company",
            "llc",
            "pllc",
            "partnership",
            "sole proprietorship",
            "association",
            "political action committee",
            "political committee",
            "pac"
        ]
        return businessTerms.contains { type.contains($0) }
    }

    private func isPetrocelliContribution(_ row: ContributionRow) -> Bool {
        let fields = [
            row.flng_ent_name,
            row.flng_ent_first_name,
            row.flng_ent_middle_name,
            row.flng_ent_last_name
        ]
        let haystack = fields
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

        let relatedTerms = [
            "petrocelli",
            "hp east end riverhead",
            "jacqueline phillips",
            "alexandra bussi",
            "preston house",
            "atlantis banquets",
            "sea star ballroom",
            "taste the east end",
            "raphael vineyard",
            "long island aquarium",
            "hyatt place east end"
        ]

        return relatedTerms.contains { haystack.contains($0) }
    }

    private func isScottPointeRelatedContribution(_ row: ContributionRow) -> Bool {
        let entity = row.flng_ent_name?.lowercased() ?? ""
        let entityMatches = [
            "scott's pointe",
            "scotts pointe",
            "island water park",
            "island waterpark",
            "island water park corp",
            "island water sports",
            "lake view grill"
        ]
        if entityMatches.contains(where: { entity.contains($0) }) {
            return true
        }

        let first = row.flng_ent_first_name?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let last = row.flng_ent_last_name?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let relatedPeople = [
            ("eric", "scott"),
            ("claudia", "scott"),
            ("cody", "scott"),
            ("jake", "scott"),
            ("ken", "myers"),
            ("grant", "anderson")
        ]
        return relatedPeople.contains { relatedFirst, relatedLast in
            first == relatedFirst && last == relatedLast
        }
    }

    private func isPossibleFamilyLinkedContribution(_ row: ContributionRow, for member: CouncilMember) -> Bool {
        guard isIndividualContribution(row) else { return false }

        return isCandidateOrFamilyContribution(row, for: member)
    }

    private func isCandidateOrFamilyLoan(_ row: LoanDetailRow, for member: CouncilMember) -> Bool {
        isCandidateOrFamilyFinancing(
            donorName: donorName(for: row),
            contributorType: row.cntrbr_type_desc,
            for: member
        )
    }

    private func isCandidateOrFamilyContribution(_ row: ContributionRow, for member: CouncilMember) -> Bool {
        isCandidateOrFamilyFinancing(
            donorName: donorName(for: row),
            contributorType: row.cntrbr_type_desc,
            for: member
        )
    }

    private func isCandidateOrFamilyFinancing(donorName: String, contributorType: String?, for member: CouncilMember) -> Bool {
        let type = contributorType?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        if type == "candidate/candidate spouse" || type == "candidate family member" {
            return true
        }

        let normalizedDonor = donorName.lowercased()
        if candidateSelfNames(for: member).contains(normalizedDonor) {
            return true
        }

        return candidateFamilyNames(for: member).contains(normalizedDonor)
    }

    private func candidateSelfNames(for member: CouncilMember) -> Set<String> {
        var names: Set<String> = [member.name.lowercased()]
        if member.name.contains("Jerome Halpin") {
            names.insert("jerome halpin")
            names.insert("jerry halpin")
        } else if member.name.contains("Rothwell") {
            names.insert("kenneth rothwell")
            names.insert("kenneth t rothwell")
            names.insert("ken rothwell")
        } else if member.name.contains("Waski") {
            names.insert("joann waski")
        } else if member.name.contains("Kern") {
            names.insert("robert kern")
            names.insert("bob kern")
        } else if member.name.contains("Merrifield") {
            names.insert("denise merrifield")
            names.insert("denise m merrifield")
            names.insert("denise m. merrifield")
        }
        return names
    }

    // Normalized "last|first" key used to match a payroll employee against a campaign donor
    // by name only (case-insensitive, first name reduced to its first token, no middle names).
    private func donorNameKey(last: String?, first: String?) -> String? {
        let l = (last ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let f = (first ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased().split(separator: " ").first.map(String.init) ?? ""
        guard !l.isEmpty, !f.isEmpty else { return nil }
        return "\(l)|\(f)"
    }

    // Payroll names are "Last, First Middle" — split on the first comma.
    private func payrollNameKey(_ name: String) -> String? {
        let parts = name.split(separator: ",", maxSplits: 1)
        guard parts.count == 2 else { return nil }
        let first = parts[1].trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ").first.map(String.init)
        return donorNameKey(last: String(parts[0]), first: first)
    }

    // A council member draws a Town salary too, so without this a candidate donating to
    // their own committee would show up as a "town employee donor" — trivially true and not
    // a meaningful finding. Reuses candidateSelfNames (space-separated "first last" strings).
    private func selfDonorNameKeys(for member: CouncilMember) -> Set<String> {
        Set(candidateSelfNames(for: member).compactMap { full -> String? in
            let parts = full.split(separator: " ")
            guard parts.count >= 2, let first = parts.first, let last = parts.last else { return nil }
            return donorNameKey(last: String(last), first: String(first))
        })
    }

    private func candidateFamilyNames(for member: CouncilMember) -> Set<String> {
        if member.name.contains("Jerome Halpin") {
            return [
                "dennis halpin",
                "chloe halpin",
                "patrick halpin",
                "kristen halpin"
            ]
        } else if member.name.contains("Rothwell") {
            // A $2,500 loan each from Werner Rothwell and Alexander Rothwell to "Friends of Ken
            // Rothwell" (filer 154927), originally dated 2021-03-21, re-reported as an
            // outstanding liability (schedule N) in every periodic/pre-election filing since.
            return [
                "werner rothwell",
                "alexander rothwell"
            ]
        }
        return []
    }

    private func contributionSummary(for row: ContributionRow) -> TopContribution? {
        guard let amount = parseAmount(row.org_amt) else { return nil }
        return TopContribution(
            donorName: donorName(for: row),
            amount: amount,
            date: parseAPIDate(row.sched_date),
            contributorType: row.cntrbr_type_desc?.trimmingCharacters(in: .whitespacesAndNewlines),
            schedule: row.filing_sched_abbrev,
            filingLabel: filingLabel(for: row)
        )
    }

    private func loanSummary(for row: LoanDetailRow) -> TopContribution? {
        guard let amount = parseAmount(row.owed_amt) ?? parseAmount(row.org_amt) else { return nil }
        return TopContribution(
            donorName: donorName(for: row),
            amount: amount,
            date: parseAPIDate(row.sched_date),
            contributorType: row.cntrbr_type_desc?.trimmingCharacters(in: .whitespacesAndNewlines),
            schedule: row.filing_sched_abbrev,
            filingLabel: filingLabel(for: row)
        )
    }

    private func deduplicateContributions(_ contributions: [TopContribution]) -> [TopContribution] {
        var seen: Set<String> = []
        return contributions.filter { contribution in
            let key = [
                contribution.donorName.lowercased(),
                String(format: "%.2f", contribution.amount),
                contribution.date.map { apiDateFormatter.string(from: $0) } ?? "",
                contribution.schedule ?? "",
                contribution.filingLabel ?? ""
            ].joined(separator: "|")
            return seen.insert(key).inserted
        }
    }

    private func filingLabel(for row: ContributionRow) -> String? {
        let parts = [row.election_year, row.filing_desc]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    private func filingLabel(for row: LoanDetailRow) -> String? {
        let parts = [row.election_year, row.filing_desc]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    private func updateCampaignFinanceSnapshots() async {
        guard !isUpdatingFilings else { return }
        isUpdatingFilings = true
        filingsUpdateStatus = nil
        defer { isUpdatingFilings = false }

        let filerIDs = Array(Set(allTrackedMembers.flatMap { campaignFilerIDs(for: $0) })).sorted()
        guard !filerIDs.isEmpty else {
            filingsUpdateStatus = "No filer IDs configured."
            return
        }

        let inClause = filerIDs.map { "'\($0)'" }.joined(separator: ",")
        let filingYearFilter = campaignFilingYearWhereClause
        let raisedQuery = "$select=filer_id,sum(org_amt) as total_raised,max(sched_date) as last_reported&$where=filer_id in (\(inClause)) and \(filingYearFilter) and filing_sched_abbrev in('A','B','C','G')&$group=filer_id"
        let breakdownQuery = "$select=filer_id,filing_sched_abbrev,sum(org_amt) as amount,max(sched_date) as last_reported&$where=filer_id in (\(inClause)) and \(filingYearFilter) and filing_sched_abbrev in('A','B','C','G')&$group=filer_id,filing_sched_abbrev"
        let currentYearBreakdownQuery = "$select=filer_id,election_year,filing_abbrev,filing_desc,filing_sched_abbrev,sum(org_amt) as amount,max(sched_date) as last_reported,count(*) as row_count&$where=filer_id in (\(inClause)) and \(filingYearFilter)&$group=filer_id,election_year,filing_abbrev,filing_desc,filing_sched_abbrev"
        let contributionQuery = "$select=filer_id,election_year,filing_abbrev,filing_desc,filing_sched_abbrev,filing_sched_desc,cntrbr_type_desc,flng_ent_name,flng_ent_first_name,flng_ent_middle_name,flng_ent_last_name,org_amt,sched_date&$where=filer_id in (\(inClause)) and \(filingYearFilter) and filing_sched_abbrev in('A','B','C')&$limit=5000"
        // Schedule I = Loans Received (new money that period, safe to sum across years). Schedule
        // N = Outstanding Liabilities/Loans (a running balance RE-REPORTED every filing, so summing
        // it across years double-counts — handled separately below via outstandingLoanQuery).
        // Neither schedule exists in the itemized-contributions dataset (4j2b-6a2j) at all — both
        // queries below must hit e9ss-239a, the per-filing aggregate dataset, or they'll always
        // return empty.
        let loanFilter = "(filing_sched_abbrev in('I','J','K','N') or lower(filing_sched_desc) like '%loan%' or lower(loan_other_desc) like '%loan%')"
        let loanQuery = "$select=filer_id,sum(coalesce(owed_amt, org_amt)) as loan_amt,max(sched_date) as last_reported_loan&$where=filer_id in (\(inClause)) and \(filingYearFilter) and filing_sched_abbrev='I'&$group=filer_id"
        let outstandingLoanQuery = "$select=filer_id,election_year,sum(org_amt) as amount&$where=filer_id in (\(inClause)) and \(filingYearFilter) and filing_sched_abbrev='N'&$group=filer_id,election_year&$order=election_year DESC"
        let loanDetailQuery = "$select=filer_id,election_year,filing_abbrev,filing_desc,filing_sched_abbrev,filing_sched_desc,cntrbr_type_desc,flng_ent_name,flng_ent_first_name,flng_ent_middle_name,flng_ent_last_name,org_amt,owed_amt,sched_date,loan_lib_number,loan_other_desc&$where=filer_id in (\(inClause)) and \(filingYearFilter) and \(loanFilter)&$limit=5000"
        // Grouped by filing (not by schedule), so each row here is one filing SUBMISSION —
        // e.g. "January Periodic, Original, Itemized, State/Local" — rather than one
        // itemized transaction within it.
        let filingEventsQuery = "$select=filer_id,election_year,filing_desc,r_amend,filing_cat_desc,election_type,sum(org_amt) as amount,count(*) as row_count,max(sched_date) as last_activity&$where=filer_id in (\(inClause)) and \(filingYearFilter)&$group=filer_id,election_year,filing_desc,r_amend,filing_cat_desc,election_type&$order=election_year DESC&$limit=2000"

        guard let raisedURL = URL(string: "https://data.ny.gov/resource/4j2b-6a2j.json?\(raisedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"),
              let breakdownURL = URL(string: "https://data.ny.gov/resource/4j2b-6a2j.json?\(breakdownQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"),
              let currentYearBreakdownURL = URL(string: "https://data.ny.gov/resource/e9ss-239a.json?\(currentYearBreakdownQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"),
              let contributionURL = URL(string: "https://data.ny.gov/resource/4j2b-6a2j.json?\(contributionQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"),
              let loanURL = URL(string: "https://data.ny.gov/resource/e9ss-239a.json?\(loanQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"),
              let outstandingLoanURL = URL(string: "https://data.ny.gov/resource/e9ss-239a.json?\(outstandingLoanQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"),
              let loanDetailURL = URL(string: "https://data.ny.gov/resource/e9ss-239a.json?\(loanDetailQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"),
              let filingEventsURL = URL(string: "https://data.ny.gov/resource/e9ss-239a.json?\(filingEventsQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            filingsUpdateStatus = "Could not build filings query URL."
            return
        }

        do {
            async let raisedRowsReq: [RaisedRow] = fetchCampaignRows(from: raisedURL)
            async let breakdownRowsReq: [ScheduleBreakdownRow] = fetchCampaignRows(from: breakdownURL)
            async let currentYearBreakdownRowsReq: [ScheduleBreakdownRow] = fetchCampaignRows(from: currentYearBreakdownURL)
            async let contributionRowsReq: [ContributionRow] = fetchCampaignRows(from: contributionURL)
            async let loanRowsReq: [LoanRow] = fetchCampaignRows(from: loanURL)
            async let outstandingLoanRowsReq: [OutstandingLoanRow] = fetchCampaignRows(from: outstandingLoanURL)
            async let loanDetailRowsReq: [LoanDetailRow] = fetchCampaignRows(from: loanDetailURL)
            async let filingEventsRowsReq: [FilingEventRow] = fetchCampaignRows(from: filingEventsURL)

            let (raisedRows, breakdownRows, currentYearBreakdownRows, contributionRows, loanRows, outstandingLoanRows, loanDetailRows, filingEventsRows) = try await (raisedRowsReq, breakdownRowsReq, currentYearBreakdownRowsReq, contributionRowsReq, loanRowsReq, outstandingLoanRowsReq, loanDetailRowsReq, filingEventsRowsReq)

            var raisedByFiler: [String: RaisedRow] = [:]
            for row in raisedRows { raisedByFiler[row.filer_id] = row }

            var directByFiler: [String: Double] = [:]
            var transferByFiler: [String: Double] = [:]
            var latestBreakdownDateByFiler: [String: Date] = [:]
            for row in breakdownRows {
                let amount = parseAmount(row.amount) ?? 0
                let schedule = row.filing_sched_abbrev?.uppercased() ?? ""
                if ["A", "B", "C"].contains(schedule) {
                    directByFiler[row.filer_id, default: 0] += amount
                } else if schedule == "G" {
                    transferByFiler[row.filer_id, default: 0] += amount
                }

                if let date = parseAPIDate(row.last_reported),
                   date > (latestBreakdownDateByFiler[row.filer_id] ?? .distantPast) {
                    latestBreakdownDateByFiler[row.filer_id] = date
                }
            }

            var loanByFiler: [String: LoanRow] = [:]
            for row in loanRows { loanByFiler[row.filer_id] = row }

            // Keep only the highest election_year per filer — that's the most recently reported
            // outstanding balance, since summing across years would double-count a balance that
            // gets re-stated (not re-incurred) at every subsequent filing.
            var outstandingByFiler: [String: OutstandingLoanRow] = [:]
            for row in outstandingLoanRows {
                let year = row.election_year ?? ""
                if let existing = outstandingByFiler[row.filer_id], (existing.election_year ?? "") >= year {
                    continue
                }
                outstandingByFiler[row.filer_id] = row
            }
            var loanDetailRowsByFiler: [String: [LoanDetailRow]] = [:]
            for row in loanDetailRows {
                loanDetailRowsByFiler[row.filer_id, default: []].append(row)
            }

            var currentYearBreakdownRowsByFiler: [String: [ScheduleBreakdownRow]] = [:]
            for row in currentYearBreakdownRows {
                currentYearBreakdownRowsByFiler[row.filer_id, default: []].append(row)
            }

            var filingEventRowsByFiler: [String: [FilingEventRow]] = [:]
            for row in filingEventsRows {
                filingEventRowsByFiler[row.filer_id, default: []].append(row)
            }

            var largestIndividualByFiler: [String: TopContribution] = [:]
            var largestBusinessByFiler: [String: TopContribution] = [:]
            var petrocelliByFiler: [String: [TopContribution]] = [:]
            var scottPointeByFiler: [String: [TopContribution]] = [:]
            var contributionRowsByFiler: [String: [ContributionRow]] = [:]
            for row in contributionRows {
                guard let contribution = contributionSummary(for: row) else { continue }
                contributionRowsByFiler[row.filer_id, default: []].append(row)

                if isIndividualContribution(row) {
                    if contribution.amount > (largestIndividualByFiler[row.filer_id]?.amount ?? -.infinity) {
                        largestIndividualByFiler[row.filer_id] = contribution
                    }
                }

                if isBusinessOrEntityContribution(row) {
                    if contribution.amount > (largestBusinessByFiler[row.filer_id]?.amount ?? -.infinity) {
                        largestBusinessByFiler[row.filer_id] = contribution
                    }
                }

                if isPetrocelliContribution(row) {
                    petrocelliByFiler[row.filer_id, default: []].append(contribution)
                }

                if isScottPointeRelatedContribution(row) {
                    scottPointeByFiler[row.filer_id, default: []].append(contribution)
                }
            }

            var updated: [String: CampaignSnapshot] = [:]
            for member in allTrackedMembers {
                let filingRefs = campaignFilings(for: member)
                let memberFilerIDs = filingRefs.map(\.filerID)
                guard !memberFilerIDs.isEmpty else { continue }

                let hasFetchedContributionData = memberFilerIDs.contains { fid in
                    raisedByFiler[fid] != nil || directByFiler[fid] != nil || transferByFiler[fid] != nil
                }

                let raised = hasFetchedContributionData
                    ? memberFilerIDs.reduce(0) { $0 + (parseAmount(raisedByFiler[$1]?.total_raised) ?? 0) }
                    : member.campaignRaised
                let directContributions = hasFetchedContributionData
                    ? memberFilerIDs.reduce(0) { $0 + (directByFiler[$1] ?? 0) }
                    : member.campaignDirectContributions
                let transfersIn = hasFetchedContributionData
                    ? memberFilerIDs.reduce(0) { $0 + (transferByFiler[$1] ?? 0) }
                    : member.campaignTransfersIn

                let reported = memberFilerIDs
                    .compactMap { fid in parseAPIDate(raisedByFiler[fid]?.last_reported) ?? latestBreakdownDateByFiler[fid] }
                    .max() ?? member.campaignLastReported
                let loanAmt = memberFilerIDs.reduce(0) { $0 + (parseAmount(loanByFiler[$1]?.loan_amt) ?? 0) }
                let loanDate = memberFilerIDs
                    .compactMap { parseAPIDate(loanByFiler[$0]?.last_reported_loan) }
                    .max()
                let termJanuaryRows = memberFilerIDs
                    .flatMap { currentYearBreakdownRowsByFiler[$0] ?? [] }
                let currentYearDirect = termJanuaryRows.reduce(0) { total, row in
                    let schedule = row.filing_sched_abbrev?.uppercased() ?? ""
                    return ["A", "B", "C"].contains(schedule) ? total + (parseAmount(row.amount) ?? 0) : total
                }
                let currentYearTransfers = termJanuaryRows.reduce(0) { total, row in
                    let schedule = row.filing_sched_abbrev?.uppercased() ?? ""
                    return schedule == "G" ? total + (parseAmount(row.amount) ?? 0) : total
                }
                let currentYearFilingActivity = termJanuaryRows.reduce(0) { total, row in
                    total + (parseAmount(row.amount) ?? 0)
                }
                let currentYearFilingRows = termJanuaryRows.reduce(0) { total, row in
                    total + (Int(row.row_count ?? "") ?? 0)
                }
                let currentYearFilingSchedules = Set(
                    termJanuaryRows
                        .compactMap { $0.filing_sched_abbrev?.uppercased() }
                        .filter { !$0.isEmpty }
                )
                .sorted()
                .joined(separator: ", ")
                let currentYearReported = termJanuaryRows.compactMap { parseAPIDate($0.last_reported) }.max()

                let latestYearRows = termJanuaryRows.filter { $0.election_year == "\(campaignFilingEndYear)" }
                let latestYearDirect = latestYearRows.reduce(0) { total, row in
                    let schedule = row.filing_sched_abbrev?.uppercased() ?? ""
                    return ["A", "B", "C"].contains(schedule) ? total + (parseAmount(row.amount) ?? 0) : total
                }
                let latestYearTransfers = latestYearRows.reduce(0) { total, row in
                    let schedule = row.filing_sched_abbrev?.uppercased() ?? ""
                    return schedule == "G" ? total + (parseAmount(row.amount) ?? 0) : total
                }
                let latestYearFilingAmount = latestYearRows.reduce(0) { total, row in
                    total + (parseAmount(row.amount) ?? 0)
                }
                let latestYearRowCount = latestYearRows.reduce(0) { total, row in
                    total + (Int(row.row_count ?? "") ?? 0)
                }
                let latestYearSchedules = Set(
                    latestYearRows
                        .compactMap { $0.filing_sched_abbrev?.uppercased() }
                        .filter { !$0.isEmpty }
                )
                .sorted()
                .joined(separator: ", ")
                let latestYearLastReported = latestYearRows.compactMap { parseAPIDate($0.last_reported) }.max()
                let largestIndividual = memberFilerIDs
                    .compactMap { largestIndividualByFiler[$0] }
                    .max { $0.amount < $1.amount }
                let largestBusiness = memberFilerIDs
                    .compactMap { largestBusinessByFiler[$0] }
                    .max { $0.amount < $1.amount }
                let petrocelliContributionsRaw = memberFilerIDs
                    .flatMap { petrocelliByFiler[$0] ?? [] }
                    + (baselinePetrocelliContributions(for: member) ?? [])
                let petrocelliContributions = deduplicateContributions(petrocelliContributionsRaw)
                    .sorted {
                        if let leftDate = $0.date, let rightDate = $1.date {
                            return leftDate > rightDate
                        }
                        return $0.amount > $1.amount
                    }
                let scottPointeContributions = memberFilerIDs
                    .flatMap { scottPointeByFiler[$0] ?? [] }
                    .sorted {
                        if let leftDate = $0.date, let rightDate = $1.date {
                            return leftDate > rightDate
                        }
                        return $0.amount > $1.amount
                    }
                let familyLinkedContributions = memberFilerIDs
                    .flatMap { contributionRowsByFiler[$0] ?? [] }
                    .filter { isPossibleFamilyLinkedContribution($0, for: member) }
                    .compactMap { contributionSummary(for: $0) }
                    .sorted {
                        if let leftDate = $0.date, let rightDate = $1.date {
                            return leftDate > rightDate
                        }
                        return $0.amount > $1.amount
                    }
                let candidateFamilyLoans = memberFilerIDs
                    .flatMap { fid -> [TopContribution] in
                        let loanMatches = (loanDetailRowsByFiler[fid] ?? [])
                            .filter { isCandidateOrFamilyLoan($0, for: member) }
                            .compactMap { loanSummary(for: $0) }
                        let contributionMatches = (contributionRowsByFiler[fid] ?? [])
                            .filter { isCandidateOrFamilyContribution($0, for: member) }
                            .compactMap { contributionSummary(for: $0) }
                        return loanMatches + contributionMatches
                    }
                    + (baselineCandidateFamilyFinancing(for: member) ?? [])
                let dedupedCandidateFamilyLoans = deduplicateContributions(candidateFamilyLoans)
                    .sorted {
                        if let leftDate = $0.date, let rightDate = $1.date {
                            return leftDate > rightDate
                        }
                        return $0.amount > $1.amount
                    }
                let filingDetails = filingRefs.map { filing in
                    CampaignFilingSnapshot(
                        committeeName: filing.committeeName,
                        filerID: filing.filerID,
                        raised: parseAmount(raisedByFiler[filing.filerID]?.total_raised),
                        directContributions: directByFiler[filing.filerID],
                        transfersIn: transferByFiler[filing.filerID],
                        lastReported: parseAPIDate(raisedByFiler[filing.filerID]?.last_reported) ?? latestBreakdownDateByFiler[filing.filerID]
                    )
                }

                var committeeNameByFilerID: [String: String] = [:]
                for ref in filingRefs {
                    committeeNameByFilerID[ref.filerID] = ref.committeeName
                }
                var filingEvents: [CampaignFilingEvent] = []
                for fid in memberFilerIDs {
                    let rowsForFiler: [FilingEventRow] = filingEventRowsByFiler[fid] ?? []
                    for row in rowsForFiler {
                        let event = CampaignFilingEvent(
                            filerID: row.filer_id,
                            committeeName: committeeNameByFilerID[row.filer_id] ?? row.filer_id,
                            electionYear: row.election_year ?? "",
                            filingDesc: row.filing_desc ?? "Unlabeled filing",
                            isAmendment: (row.r_amend ?? "").uppercased() == "Y",
                            category: row.filing_cat_desc ?? "—",
                            electionType: row.election_type ?? "—",
                            amount: parseAmount(row.amount) ?? 0,
                            transactionCount: Int(row.row_count ?? "") ?? 0,
                            lastActivity: parseAPIDate(row.last_activity)
                        )
                        filingEvents.append(event)
                    }
                }
                filingEvents.sort { lhs, rhs in
                    (lhs.lastActivity ?? .distantPast) > (rhs.lastActivity ?? .distantPast)
                }

                // Full window here (not scoped to one year) so both the current-cycle breakdown
                // AND the by-year historical breakdown below can be built from a single pass.
                let allMemberContributionRows = memberFilerIDs.flatMap { contributionRowsByFiler[$0] ?? [] }

                func typeBreakdown(for rows: [ContributionRow]) -> [ContributorTypeAmount] {
                    var typeTotals: [String: (amount: Double, count: Int)] = [:]
                    for row in rows {
                        let bucket = contributorTypeBucket(row.cntrbr_type_desc)
                        let amount = parseAmount(row.org_amt) ?? 0
                        let existing = typeTotals[bucket] ?? (0, 0)
                        typeTotals[bucket] = (existing.amount + amount, existing.count + 1)
                    }
                    return typeTotals
                        .map { ContributorTypeAmount(type: $0.key, amount: $0.value.amount, donorCount: $0.value.count) }
                        .sorted { $0.amount > $1.amount }
                }

                let currentCycleRows = allMemberContributionRows.filter { $0.election_year == String(campaignFilingEndYear) }
                let donorCount = currentCycleRows.count
                let currentCycleRaised = currentCycleRows.reduce(0) { $0 + (parseAmount($1.org_amt) ?? 0) }
                let avgDonationPerDonor = donorCount > 0 ? currentCycleRaised / Double(donorCount) : nil
                let contributorTypeBreakdown = typeBreakdown(for: currentCycleRows)

                let historicalByYear: [YearBreakdown] = Dictionary(
                    grouping: allMemberContributionRows.filter { $0.election_year != String(campaignFilingEndYear) },
                    by: { $0.election_year ?? "Unknown" }
                )
                .map { year, rows in
                    let yearBreakdown = typeBreakdown(for: rows)
                    let yearRaised = yearBreakdown.reduce(0) { $0 + $1.amount }
                    let yearDonorCount = yearBreakdown.reduce(0) { $0 + $1.donorCount }
                    return YearBreakdown(
                        year: year,
                        raised: yearRaised,
                        donorCount: yearDonorCount,
                        avgDonationPerDonor: yearDonorCount > 0 ? yearRaised / Double(yearDonorCount) : nil,
                        typeBreakdown: yearBreakdown
                    )
                }
                .sorted { $0.year > $1.year }

                let outstandingRow = memberFilerIDs.compactMap { outstandingByFiler[$0] }.max { ($0.election_year ?? "") < ($1.election_year ?? "") }
                let outstandingLoanAmount = outstandingRow.flatMap { parseAmount($0.amount) }
                let outstandingLoanYear = outstandingRow?.election_year

                updated[member.id] = CampaignSnapshot(
                    committeeName: filingRefs.map(\.committeeName).joined(separator: " + "),
                    filerID: memberFilerIDs.joined(separator: ", "),
                    filingDetails: filingDetails,
                    raised: raised,
                    directContributions: directContributions,
                    transfersIn: transfersIn,
                    currentYearDirectContributions: currentYearDirect,
                    currentYearTransfersIn: currentYearTransfers,
                    currentYearFilingActivityAmount: currentYearFilingActivity,
                    currentYearFilingActivityRowCount: currentYearFilingRows,
                    currentYearFilingActivitySchedules: currentYearFilingSchedules.isEmpty ? nil : currentYearFilingSchedules,
                    currentYearLastReported: currentYearReported,
                    latestYearDirect: latestYearDirect > 0 ? latestYearDirect : nil,
                    latestYearTransfers: latestYearTransfers > 0 ? latestYearTransfers : nil,
                    latestYearFilingAmount: latestYearFilingAmount > 0 ? latestYearFilingAmount : nil,
                    latestYearRowCount: latestYearRowCount > 0 ? latestYearRowCount : nil,
                    latestYearSchedules: latestYearSchedules.isEmpty ? nil : latestYearSchedules,
                    latestYearLastReported: latestYearLastReported,
                    largestIndividualContribution: largestIndividual,
                    largestBusinessContribution: largestBusiness,
                    petrocelliContributions: petrocelliContributions,
                    scottPointeContributions: scottPointeContributions,
                    familyLinkedContributions: familyLinkedContributions,
                    candidateFamilyLoans: dedupedCandidateFamilyLoans,
                    lastReported: reported,
                    loanAmount: loanAmt > 0 ? loanAmt : nil,
                    loanLastReported: loanDate,
                    filingEvents: filingEvents,
                    donorCount: donorCount > 0 ? donorCount : nil,
                    avgDonationPerDonor: avgDonationPerDonor,
                    contributorTypeBreakdown: contributorTypeBreakdown.isEmpty ? nil : contributorTypeBreakdown,
                    outstandingLoanAmount: outstandingLoanAmount,
                    outstandingLoanYear: outstandingLoanYear,
                    historicalByYear: historicalByYear.isEmpty ? nil : historicalByYear
                )
            }

            var employeeByDonorKey: [String: Employee] = [:]
            for employee in EmployeeStore.shared.employees {
                guard let key = payrollNameKey(employee.name) else { continue }
                employeeByDonorKey[key] = employee
            }
            var newEmployeeDonorMatches: [EmployeeDonorMatch] = []
            for member in allTrackedMembers {
                let filingRefs = campaignFilings(for: member)
                let memberFilerIDs = filingRefs.map(\.filerID)
                guard !memberFilerIDs.isEmpty else { continue }
                var committeeNameByFilerID: [String: String] = [:]
                for ref in filingRefs { committeeNameByFilerID[ref.filerID] = ref.committeeName }
                let selfKeys = selfDonorNameKeys(for: member)
                for fid in memberFilerIDs {
                    let rows: [ContributionRow] = contributionRowsByFiler[fid] ?? []
                    for row in rows {
                        let contributorType = (row.cntrbr_type_desc ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        guard contributorType == "individual" else { continue }
                        guard let key = donorNameKey(last: row.flng_ent_last_name, first: row.flng_ent_first_name) else { continue }
                        guard let employee = employeeByDonorKey[key] else { continue }
                        if selfKeys.contains(key) { continue }
                        guard let amount = parseAmount(row.org_amt) else { continue }
                        let match = EmployeeDonorMatch(
                            employeeName: employee.name,
                            department: employee.department.isEmpty ? nil : employee.department,
                            title: employee.jobTitle.isEmpty ? nil : employee.jobTitle,
                            officialName: member.name,
                            committeeName: committeeNameByFilerID[fid] ?? fid,
                            electionYear: row.election_year ?? "",
                            filingDesc: row.filing_desc ?? "Unlabeled filing",
                            amount: amount,
                            date: parseAPIDate(row.sched_date)
                        )
                        newEmployeeDonorMatches.append(match)
                    }
                }
            }
            newEmployeeDonorMatches.sort { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
            employeeDonorMatches = newEmployeeDonorMatches

            if !fetchedCampaignSnapshots.isEmpty {
                previousCampaignSnapshots = fetchedCampaignSnapshots
            }
            fetchedCampaignSnapshots = updated
            filingsLastUpdatedAt = Date()
            let rangeContributionCount = updated.values.filter {
                (($0.currentYearDirectContributions ?? 0) + ($0.currentYearTransfersIn ?? 0)) > 0
            }.count
            let rangeFilingCount = updated.values.filter {
                ($0.currentYearFilingActivityRowCount ?? 0) > 0
            }.count
            filingsUpdateStatus = "Campaign filings updated from NY Open Data for \(filerIDs.count) filer IDs across \(updated.count) people. \(campaignFilingYearRangeLabel) filing activity found for \(rangeFilingCount); direct contribution or transfer rows found for \(rangeContributionCount)."
            persistCampaignSnapshots()
        } catch {
            filingsUpdateStatus = "Update failed: \(error.localizedDescription)"
        }
    }

    private func fetchCampaignRows<T: Decodable>(from url: URL) async throws -> [T] {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(http.statusCode) else {
            if let apiError = try? JSONDecoder().decode(SocrataError.self, from: data),
               let message = apiError.message {
                throw CampaignFinanceUpdateError.api(message)
            }
            throw CampaignFinanceUpdateError.httpStatus(http.statusCode)
        }

        do {
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            if let body = String(data: data, encoding: .utf8), body.contains("\"error\"") {
                let apiError = try? JSONDecoder().decode(SocrataError.self, from: data)
                throw CampaignFinanceUpdateError.api(apiError?.message ?? body)
            }
            throw error
        }
    }

    private func previousSnapshot(for member: CouncilMember) -> CampaignSnapshot? {
        previousCampaignSnapshots[member.id]
    }

    private func raisedDeltaText(for member: CouncilMember, latest: CampaignSnapshot) -> String? {
        guard let prior = previousSnapshot(for: member),
              let latestRaised = latest.directContributions ?? latest.raised,
              let priorRaised = prior.directContributions ?? prior.raised else {
            return nil
        }

        let delta = latestRaised - priorRaised
        let formatted = currencyFormatter.string(from: NSNumber(value: abs(delta))) ?? "$0"
        if abs(delta) < 0.005 {
            return "Since last update: no change in direct fundraising."
        }
        let direction = delta > 0 ? "+" : "-"
        return "Since last update: \(direction)\(formatted) in direct fundraising."
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

private enum CampaignFinanceUpdateError: LocalizedError {
    case httpStatus(Int)
    case api(String)

    var errorDescription: String? {
        switch self {
        case .httpStatus(let status):
            return "NY Open Data returned HTTP \(status)."
        case .api(let message):
            return message
        }
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
