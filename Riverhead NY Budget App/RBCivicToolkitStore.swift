//
//  RBCivicToolkitStore.swift
//  Riverhead NY Budget App
//
//  Compile-safe Civic Toolkit store + persistence.
//
//  Goals:
//  - One clean ObservableObject used across the app (no top-level declarations).
//  - Local JSON persistence (Application Support) with debounced autosave.
//  - Types required by existing views:
//      • CapitalProject + CapitalStatus  (RBCapitalProjectsMapView expects these cases)
//      • BroadbandIssue                  (CivicToolkitsHubView reflects over this)
//      • plus other civic collections used by the hub/host views.
//
//  Broadband improvement:
//  - Broadband issues can track Optimum franchise agreement + competition policy items,
//    in addition to resident service/outage logs.
//
//  Swift 6 • iOS 17+
//

import Foundation
import Combine
// MARK: - Date helpers

private enum RBISODate {
    static let fullDate: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()
}

/// Parse ISO8601 full-date "YYYY-MM-DD" in GMT. Returns nil if parsing fails.
@inline(__always)
private func ISODate(_ yyyyMMdd: String) -> Date? {
    RBISODate.fullDate.date(from: yyyyMMdd)
}

@MainActor
final class RBCivicToolkitStore: ObservableObject {

    // MARK: - Backend

    enum Backend: Equatable {
        case fileSystem
        case inMemory
    }

    let backend: Backend

    // MARK: - Shared small primitives

    struct SourceRef: Identifiable, Codable, Hashable {
        var id: UUID = UUID()
        var title: String
        var url: String

        init(id: UUID = UUID(), title: String, url: String) {
            self.id = id
            self.title = title
            self.url = url
        }
    }

    struct LatLon: Codable, Hashable {
        var lat: Double
        var lon: Double

        init(lat: Double, lon: Double) {
            self.lat = lat
            self.lon = lon
        }
    }

    // MARK: - Highlights

    struct Highlight: Identifiable, Codable, Hashable {
        var id: UUID = UUID()
        var title: String
        var detail: String
        var category: String
        var year: Int
        var sources: [SourceRef]

        init(id: UUID = UUID(),
             title: String,
             detail: String,
             category: String,
             year: Int,
             sources: [SourceRef] = []) {
            self.id = id
            self.title = title
            self.detail = detail
            self.category = category
            self.year = year
            self.sources = sources
        }
    }

    // MARK: - Glossary (lightweight)

    struct GlossaryTerm: Identifiable, Codable, Hashable {
        var id: UUID = UUID()
        var term: String
        var definition: String
        var more: String
        var tags: [String]
        var sources: [SourceRef]

        init(id: UUID = UUID(),
             term: String,
             definition: String,
             more: String = "",
             tags: [String] = [],
             sources: [SourceRef] = []) {
            self.id = id
            self.term = term
            self.definition = definition
            self.more = more
            self.tags = tags
            self.sources = sources
        }
    }

    // MARK: - Watchlist

    enum WatchKind: String, Codable, CaseIterable, Identifiable {
        // ✅ Current categories (used by the app UI)
        case budget = "budget"
        case labor = "labor"
        case debt = "debt"
        case capital = "capital"
        case broadband = "broadband"
        case other = "other"

        // ✅ Legacy categories (kept so older saved JSON still decodes)
        case topic = "topic"
        case vendor = "vendor"
        case project = "project"
        case meeting = "meeting"
        case alert = "alert"
        case facility = "facility"

        var id: String { rawValue }

        /// A friendly label for UI.
        var label: String {
            switch self {
            case .budget: return "Budget"
            case .labor: return "Labor"
            case .debt: return "Debt"
            case .capital: return "Capital"
            case .broadband: return "Broadband"
            case .other: return "Other"
            case .topic: return "Topic"
            case .vendor: return "Vendor"
            case .project: return "Project"
            case .meeting: return "Meeting"
            case .alert: return "Alert"
            case .facility: return "Facility"
            }
        }

        /// Map legacy kinds into the current buckets for grouping.
        var normalized: WatchKind {
            switch self {
            case .topic, .vendor, .project: return .other
            case .meeting: return .other
            case .alert: return .other
            case .facility: return .other
            default: return self
            }
        }
    }

    struct WatchItem: Identifiable, Codable, Hashable {
        var id: UUID = UUID()
        var kind: WatchKind

        /// A stable identifier used to de-duplicate and toggle watch items.
        /// Older builds stored this; we keep it for compatibility.
        var key: String

        /// Human-readable title shown in UI.
        var title: String

        /// Optional notes/context.
        var notes: String

        var createdAt: Date
        var sources: [SourceRef]

        init(id: UUID = UUID(),
             kind: WatchKind,
             key: String,
             title: String,
             notes: String = "",
             createdAt: Date = .now,
             sources: [SourceRef] = []) {
            self.id = id
            self.kind = kind
            self.key = key
            self.title = title
            self.notes = notes
            self.createdAt = createdAt
            self.sources = sources
        }

        /// Convenience initializer used by newer screens: key defaults to the title.
        init(title: String,
             kind: WatchKind,
             notes: String = "",
             createdAt: Date = .now,
             sources: [SourceRef] = []) {
            self.init(kind: kind, key: title, title: title, notes: notes, createdAt: createdAt, sources: sources)
        }

        // MARK: - Codable compatibility (accepts older JSON)

        enum CodingKeys: String, CodingKey { case id, kind, key, title, notes, createdAt, sources }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)

            id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()

            // Kind can come in as different raw strings across versions.
            if let raw = try c.decodeIfPresent(String.self, forKey: .kind) {
                let norm = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                kind = WatchKind(rawValue: norm) ?? .other
            } else {
                kind = .other
            }

            title = try c.decodeIfPresent(String.self, forKey: .title) ?? "Watch Item"
            notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""

            // Older builds always had key; if missing, fall back to title.
            key = try c.decodeIfPresent(String.self, forKey: .key) ?? title

            createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
            sources = try c.decodeIfPresent([SourceRef].self, forKey: .sources) ?? []
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(id, forKey: .id)
            try c.encode(kind.rawValue, forKey: .kind)
            try c.encode(key, forKey: .key)
            try c.encode(title, forKey: .title)
            try c.encode(notes, forKey: .notes)
            try c.encode(createdAt, forKey: .createdAt)
            try c.encode(sources, forKey: .sources)
        }
    }

    // MARK: - Alerts

    enum AlertSeverity: String, Codable, CaseIterable, Identifiable {
        case info = "Info"
        case watch = "Watch"
        case important = "Important"
        case urgent = "Urgent"
        var id: String { rawValue }
    }

    struct Alert: Identifiable, Codable, Hashable {
        var id: UUID = UUID()
        var title: String
        var message: String
        var severity: AlertSeverity
        var createdAt: Date
        var sources: [SourceRef]

        init(id: UUID = UUID(),
             title: String,
             message: String,
             severity: AlertSeverity = .info,
             createdAt: Date = .now,
             sources: [SourceRef] = []) {
            self.id = id
            self.title = title
            self.message = message
            self.severity = severity
            self.createdAt = createdAt
            self.sources = sources
        }
    }

    // MARK: - Meetings

    struct MeetingEvent: Identifiable, Codable, Hashable {
        var id: UUID = UUID()
        var title: String
        var committee: String
        var startsAt: Date
        var location: String
        var agendaURL: String?
        var minutesURL: String?
        var sources: [SourceRef]

        init(id: UUID = UUID(),
             title: String,
             committee: String,
             startsAt: Date,
             location: String,
             agendaURL: String? = nil,
             minutesURL: String? = nil,
             sources: [SourceRef] = []) {
            self.id = id
            self.title = title
            self.committee = committee
            self.startsAt = startsAt
            self.location = location
            self.agendaURL = agendaURL
            self.minutesURL = minutesURL
            self.sources = sources
        }
    }

    struct MeetingFeed: Identifiable, Codable, Hashable {
        var id: UUID = UUID()
        var name: String
        var url: String
        var enabled: Bool

        init(id: UUID = UUID(), name: String, url: String, enabled: Bool = true) {
            self.id = id
            self.name = name
            self.url = url
            self.enabled = enabled
        }
    }

    // MARK: - Spending

    struct SpendingRecord: Identifiable, Codable, Hashable {
        var id: UUID = UUID()
        var vendor: String
        var department: String
        var amount: Double
        var date: Date
        var memo: String
        var sources: [SourceRef]

        init(id: UUID = UUID(),
             vendor: String,
             department: String,
             amount: Double,
             date: Date,
             memo: String = "",
             sources: [SourceRef] = []) {
            self.id = id
            self.vendor = vendor
            self.department = department
            self.amount = amount
            self.date = date
            self.memo = memo
            self.sources = sources
        }
    }

    // MARK: - Contracts (non-labor)

    struct Contract: Identifiable, Codable, Hashable {
        var id: UUID = UUID()
        var vendor: String
        var purpose: String
        var amount: Double?
        var startDate: Date?
        var endDate: Date?
        var sources: [SourceRef]

        init(id: UUID = UUID(),
             vendor: String,
             purpose: String,
             amount: Double? = nil,
             startDate: Date? = nil,
             endDate: Date? = nil,
             sources: [SourceRef] = []) {
            self.id = id
            self.vendor = vendor
            self.purpose = purpose
            self.amount = amount
            self.startDate = startDate
            self.endDate = endDate
            self.sources = sources
        }
    }

    // MARK: - Capital Projects

    enum CapitalStatus: String, Codable, CaseIterable, Identifiable {
        case planned = "Planned"
        case design = "Design"
        case bid = "Bid"
        case construction = "Construction"
        case complete = "Complete"

        var id: String { rawValue }
    }

    struct CapitalProject: Identifiable, Codable, Hashable {
        var id: UUID = UUID()
        var name: String
        var status: CapitalStatus

        var budget: Double?
        var spent: Double?
        var fundingSource: String

        var startDate: Date?
        var endDate: Date?

        var category: String?
        var department: String?

        var address: String?
        var coordinate: LatLon?

        var notes: String?
        var url: String?

        var sources: [SourceRef]

        init(id: UUID = UUID(),
             name: String,
             status: CapitalStatus,
             budget: Double? = nil,
             spent: Double? = nil,
             fundingSource: String = "",
             startDate: Date? = nil,
             endDate: Date? = nil,
             category: String? = nil,
             department: String? = nil,
             address: String? = nil,
             coordinate: LatLon? = nil,
             notes: String? = nil,
             url: String? = nil,
             sources: [SourceRef] = []) {
            self.id = id
            self.name = name
            self.status = status
            self.budget = budget
            self.spent = spent
            self.fundingSource = fundingSource
            self.startDate = startDate
            self.endDate = endDate
            self.category = category
            self.department = department
            self.address = address
            self.coordinate = coordinate
            self.notes = notes
            self.url = url
            self.sources = sources
        }
    }

    // MARK: - Debt

    struct DebtItem: Identifiable, Codable, Hashable {
        var id: UUID = UUID()
        var label: String
        var principal: Double?
        var interestRate: Double?
        var maturity: Date?
        var notes: String
        var sources: [SourceRef]

        init(id: UUID = UUID(),
             label: String,
             principal: Double? = nil,
             interestRate: Double? = nil,
             maturity: Date? = nil,
             notes: String = "",
             sources: [SourceRef] = []) {
            self.id = id
            self.label = label
            self.principal = principal
            self.interestRate = interestRate
            self.maturity = maturity
            self.notes = notes
            self.sources = sources
        }
    }

    // MARK: - Grants

    struct Grant: Identifiable, Codable, Hashable {
        var id: UUID = UUID()
        var name: String
        var agency: String
        var amount: Double?
        var status: String
        var dueDate: Date?
        var notes: String
        var sources: [SourceRef]

        init(id: UUID = UUID(),
             name: String,
             agency: String,
             amount: Double? = nil,
             status: String = "",
             dueDate: Date? = nil,
             notes: String = "",
             sources: [SourceRef] = []) {
            self.id = id
            self.name = name
            self.agency = agency
            self.amount = amount
            self.status = status
            self.dueDate = dueDate
            self.notes = notes
            self.sources = sources
        }
    }

    // MARK: - Facilities

    enum FacilityKind: String, Codable, CaseIterable, Identifiable {
        case town = "Town"
        case park = "Park"
        case water = "Water"
        case sewer = "Sewer"
        case other = "Other"
        var id: String { rawValue }
    }

    struct Facility: Identifiable, Codable, Hashable {
        var id: UUID = UUID()
        var name: String
        var kind: FacilityKind
        var address: String?
        var coordinate: LatLon?
        var sources: [SourceRef]

        init(id: UUID = UUID(),
             name: String,
             kind: FacilityKind = .other,
             address: String? = nil,
             coordinate: LatLon? = nil,
             sources: [SourceRef] = []) {
            self.id = id
            self.name = name
            self.kind = kind
            self.address = address
            self.coordinate = coordinate
            self.sources = sources
        }
    }

    // MARK: - Broadband (Optimum franchise + competition policy + service logs)

    
    // MARK: - Broadband issue tracking

    enum BroadbandIssueType: String, CaseIterable, Codable, Hashable, Identifiable {
        // Policy / governance
        case franchiseAgreement = "Franchise agreement (Optimum)"
        case competitionAccess = "Competition / market access"
        case rightOfWayPermitting = "Right-of-way & street opening"
        case poleAttachments = "Pole attachments & make-ready"
        case buildout = "Build-out obligations & coverage"
        case reporting = "Reporting, audits & transparency"

        // Resident / customer experience
        case speedReliability = "Speed & reliability"
        case availability = "Availability / address eligibility"
        case coverage = "Coverage gaps"
        case pricing = "Pricing"
        case billing = "Billing"
        case outage = "Outages"
        case install = "Installation / service calls"
        case other = "Other"

        var id: String { rawValue }

        var isPolicy: Bool {
            switch self {
            case .franchiseAgreement, .competitionAccess, .rightOfWayPermitting, .poleAttachments, .buildout, .reporting:
                return true
            default:
                return false
            }
        }

        var systemImage: String {
            switch self {
            case .franchiseAgreement: return "doc.text"
            case .competitionAccess: return "person.3"
            case .rightOfWayPermitting: return "signpost.right"
            case .poleAttachments: return "bolt"
            case .buildout: return "map"
            case .reporting: return "chart.bar"

            case .speedReliability: return "speedometer"
            case .availability: return "mappin.and.ellipse"
            case .coverage: return "wifi"
            case .pricing: return "tag"
            case .billing: return "creditcard"
            case .outage: return "bolt.slash"
            case .install: return "wrench.and.screwdriver"
            case .other: return "questionmark.circle"
            }
        }
    }

    /// NOTE:
    /// We store `issueType` as a STRING (rawValue) because CivicToolkitsHubView reads via reflection and prefers strings.
    /// `issueTypeKey` is the stable enum key used for filtering/consistency.
    
    struct BroadbandIssue: Identifiable, Codable, Hashable {
        typealias IssueType = BroadbandIssueType

        var id: UUID
        var type: IssueType

        /// Optional short headline for lists (e.g., "Optimum franchise renewal & competition").
        var title: String?

        /// Current provider / franchise holder (e.g., Optimum / Altice).
        var provider: String

        /// Area / neighborhood / district context (e.g., "Town-wide", "Wading River").
        var location: String

        /// For policy items (e.g., "Active franchise", "Under review", "Renegotiation requested").
        var agreementStatus: String?

        /// What the town is trying to achieve (e.g., "Enable Verizon build-out; reduce barriers to entry").
        var policyGoal: String?

        /// Comma-separated competitor list (e.g., "Verizon, T-Mobile 5G Home, Starlink").
        var competitors: String?

        /// Extra detail, notes, links, etc.
        var notes: String

        /// Optional "key date" (e.g., renewal deadline / RFP due date / public hearing date).
        var keyDate: Date?
        var expiresAt: Date?

        /// When the issue/entry was created or reported.
        var reportedAt: Date

        /// Whether the entry is considered resolved/closed.
        var resolved: Bool

        var sources: [SourceRef]

        /// Readable type string for reflection/export.
        var issueType: String { type.rawValue }

        init(
            id: UUID = UUID(),
            type: IssueType,
            title: String? = nil,
            provider: String,
            location: String,
            agreementStatus: String? = nil,
            policyGoal: String? = nil,
            competitors: String? = nil,
            notes: String = "",
            reportedAt: Date = .now,
            keyDate: Date? = nil,
            expiresAt: Date? = nil,
            resolved: Bool = false,
            sources: [SourceRef] = []
        ) {
            self.id = id
            self.type = type
            self.title = title
            self.provider = provider
            self.location = location
            self.agreementStatus = agreementStatus
            self.policyGoal = policyGoal
            self.competitors = competitors
            self.notes = notes
            self.reportedAt = reportedAt
            self.keyDate = keyDate
            self.expiresAt = expiresAt
            self.resolved = resolved
            self.sources = sources
        }

        // MARK: - Convenience initializers (UI/back-compat)

        /// Back-compat label: `issueType:` (older views/stores used this label).
        init(
            id: UUID = UUID(),
            issueType: IssueType,
            title: String? = nil,
            provider: String,
            location: String,
            agreementStatus: String? = nil,
            policyGoal: String? = nil,
            competitors: String? = nil,
            notes: String = "",
            reportedAt: Date = .now,
            keyDate: Date? = nil,
            expiresAt: Date? = nil,
            resolved: Bool = false,
            sources: [SourceRef] = []
        ) {
            self.init(
                id: id,
                type: issueType,
                title: title,
                provider: provider,
                location: location,
                agreementStatus: agreementStatus,
                policyGoal: policyGoal,
                competitors: competitors,
                notes: notes,
                reportedAt: reportedAt,
                keyDate: keyDate,
                expiresAt: expiresAt,
                resolved: resolved,
                sources: sources
            )
        }

        /// Back-compat label + CSV helper used by older templates: `competitorsCSV:`.
        init(
            id: UUID = UUID(),
            type: IssueType,
            title: String? = nil,
            provider: String,
            location: String,
            competitorsCSV: String? = nil,
            policyGoal: String? = nil,
            agreementStatus: String? = nil,
            notes: String = "",
            keyDate: Date? = nil,
            expiresAt: Date? = nil,
            resolved: Bool = false,
            sources: [SourceRef] = []
        ) {
            self.init(
                id: id,
                type: type,
                title: title,
                provider: provider,
                location: location,
                agreementStatus: agreementStatus,
                policyGoal: policyGoal,
                competitors: competitorsCSV,
                notes: notes,
                reportedAt: .now,
                keyDate: keyDate,
                expiresAt: expiresAt,
                resolved: resolved,
                sources: sources
            )
        }

        enum CodingKeys: String, CodingKey {
            case id
            case type              // new preferred key
            case issueTypeKey      // legacy
            case issueType         // legacy-readable
            case title
            case provider
            case location
            case agreementStatus
            case policyGoal
            case competitors       // string or [string] legacy
            case notes
            case keyDate
            case expiresAt, endDate, contractEnds, expirationDate
            case reportedAt
            case resolved
            case sources
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(UUID.self, forKey: .id)

            // Type: try new key first, then legacy.
            if let t = try c.decodeIfPresent(IssueType.self, forKey: .type) {
                type = t
            } else if let t = try c.decodeIfPresent(IssueType.self, forKey: .issueTypeKey) {
                type = t
            } else if let s = try c.decodeIfPresent(String.self, forKey: .issueType),
                      let t = IssueType.allCases.first(where: { $0.rawValue == s }) {
                type = t
            } else {
                type = .other
            }

            title = try c.decodeIfPresent(String.self, forKey: .title)
            provider = (try c.decodeIfPresent(String.self, forKey: .provider)) ?? "Unknown"
            location = (try c.decodeIfPresent(String.self, forKey: .location)) ?? "—"
            agreementStatus = try c.decodeIfPresent(String.self, forKey: .agreementStatus)
            policyGoal = try c.decodeIfPresent(String.self, forKey: .policyGoal)

            // Competitors: accept either String or [String] (legacy).
            if let s = try c.decodeIfPresent(String.self, forKey: .competitors) {
                competitors = s
            } else if let arr = try c.decodeIfPresent([String].self, forKey: .competitors) {
                competitors = arr.joined(separator: ", ")
            } else {
                competitors = nil
            }

            notes = (try c.decodeIfPresent(String.self, forKey: .notes)) ?? ""
            keyDate = try c.decodeIfPresent(Date.self, forKey: .keyDate)
            // expiresAt: accept multiple legacy keys (avoid throwing `??` rethrows operator)
            if let d = try c.decodeIfPresent(Date.self, forKey: .expiresAt) {
                expiresAt = d
            } else if let d = try c.decodeIfPresent(Date.self, forKey: .endDate) {
                expiresAt = d
            } else if let d = try c.decodeIfPresent(Date.self, forKey: .contractEnds) {
                expiresAt = d
            } else if let d = try c.decodeIfPresent(Date.self, forKey: .expirationDate) {
                expiresAt = d
            } else {
                expiresAt = nil
            }
            reportedAt = (try c.decodeIfPresent(Date.self, forKey: .reportedAt)) ?? .now
            resolved = (try c.decodeIfPresent(Bool.self, forKey: .resolved)) ?? false
            sources = (try c.decodeIfPresent([SourceRef].self, forKey: .sources)) ?? []
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(id, forKey: .id)
            try c.encode(type, forKey: .type)
            try c.encode(type, forKey: .issueTypeKey) // keep legacy key
            try c.encode(type.rawValue, forKey: .issueType) // readable legacy string

            try c.encodeIfPresent(title, forKey: .title)
            try c.encode(provider, forKey: .provider)
            try c.encode(location, forKey: .location)
            try c.encodeIfPresent(agreementStatus, forKey: .agreementStatus)
            try c.encodeIfPresent(policyGoal, forKey: .policyGoal)
            try c.encodeIfPresent(competitors, forKey: .competitors)
            try c.encode(notes, forKey: .notes)
            try c.encodeIfPresent(keyDate, forKey: .keyDate)
            try c.encodeIfPresent(expiresAt, forKey: .expiresAt)
            try c.encode(reportedAt, forKey: .reportedAt)
            try c.encode(resolved, forKey: .resolved)
            try c.encode(sources, forKey: .sources)
        }

        static func templateOptimumFranchiseCompetition() -> BroadbandIssue {
            BroadbandIssue(
                type: .competitionAccess,
                provider: "Optimum (formerly Cablevision)",
                location: "Town-wide (Town of Riverhead, NY)",
                competitorsCSV: "Verizon FiOS; T-Mobile 5G Home; Verizon 5G Home; Starlink; Local ISPs (where available)",
                policyGoal: "Modernize the franchise + right-of-way rules to remove practical barriers for overbuilders and improve service, transparency, and accountability.",
                agreementStatus: "10-year franchise renewal discussed Feb 29, 2016; public hearing set for Apr 5, 2016; executed franchise renewal agreement filed with NYS on Apr 21, 2016. If the 10-year term runs from execution, it would end Apr 21, 2026 (verify the effective date/term language in the signed agreement).",
                notes: """
Context (2016 renewal):
• The Town negotiated a new franchise renewal with Cablevision (now Optimum) after a prior agreement had expired.
• Reporting at the time described the agreement as 10 years and noted language that appeared to grant Cablevision exclusive rights to install/maintain equipment along certain town property/roads.

Contract end (best available from public filings):
• NYS DPS filing indicates the executed franchise renewal agreement was signed Apr 21, 2016.
• If the agreement term is 10 years starting from execution, an expected end date would be Apr 21, 2026.
• If the signed agreement defines a different effective date (e.g., start of the next month / upon PSC approval), use that date instead.

How to improve the franchise to support competition:
1) Explicitly non-exclusive + pro-competition posture
   • State clearly the franchise is non-exclusive and that the Town will process additional franchise applications consistent with federal/state law.

2) “Shot clocks” for permits + right-of-way access
   • Publish standardized permit requirements/fees, predictable make-ready timelines, and transparent escalation paths for all providers.

3) Pole/attachment and make-ready coordination
   • Add provisions supporting one-touch make-ready where allowed, coordinated utility notifications, and dispute-resolution timelines.

4) Dig-once / conduit-ready policy
   • When streets are opened, require conduit placement (or coordinate with overbuilders) to reduce future construction costs.

5) Data + performance accountability
   • Require periodic public reporting (outage minutes, restoration times, complaint metrics, buildout maps), with cure periods and penalties for chronic non-compliance.

6) “No anti-overbuild” constraints
   • Remove (or narrow) any language that can be read as granting exclusivity over town property/roads, and avoid terms that effectively deter competitors.

Practical takeaway:
• Even when exclusivity is prohibited on paper, process friction is where competition dies. Codifying predictable ROW/permitting + transparency is the fastest lever the Town controls.

""",
                keyDate: ISODate("2016-04-05"),
                expiresAt: ISODate("2026-04-21"),
                resolved: false,
                sources: [
                    SourceRef(
                        title: "RiverheadLocal: contract negotiations + Apr 5, 2016 hearing (Cablevision franchise renewal)",
                        url: "https://riverheadlocal.com/2016/02/29/riverhead-finalizes-contract-negotiations-with-cablevision-sets-april-5-public-hearing-on-new-franchise-agreement/"
                    ),
                    SourceRef(
                        title: "NYS DPS filing (PSC): executed franchise renewal agreement date (Apr 21, 2016)",
                        url: "https://documents.dps.ny.gov/public/Common/ViewDoc.aspx?DocRefId=%7B88BB444C-73BD-4283-B45B-17D0C88BA3B9%7D"
                    ),
                    SourceRef(
                        title: "47 U.S.C. § 541 (cable franchising; exclusivity limits)",
                        url: "https://www.govinfo.gov/content/pkg/USCODE-2023-title47/html/USCODE-2023-title47-chap5-subchapV-partI-sec541.htm"
                    )
                ]
            )
        }
    }


    // MARK: - Published state

    @Published var highlights: [Highlight] = []
    @Published var glossary: [GlossaryTerm] = []
    @Published var watchlist: [WatchItem] = []
    @Published var alerts: [Alert] = []
    @Published var meetings: [MeetingEvent] = []
    @Published var meetingFeeds: [MeetingFeed] = []
    @Published var spending: [SpendingRecord] = []
    @Published var contracts: [Contract] = []
    @Published var capitalProjects: [CapitalProject] = []
    @Published var debt: [DebtItem] = []
    @Published var grants: [Grant] = []
    @Published var facilities: [Facility] = []
    @Published var broadbandIssues: [BroadbandIssue] = []

    // MARK: - Internals

    private var autoSaveCancellable: AnyCancellable?
    private var saveTask: Task<Void, Never>?

    // MARK: - Init

    init(backend: Backend = .fileSystem) {
        self.backend = backend

        // Debounced autosave on any change
        autoSaveCancellable = objectWillChange.sink { [weak self] _ in
            self?.scheduleSave()
        }

        Task { @MainActor in
            await load()
            if !isCompletelyEmpty, ensureTownHallEVChargingProjectPresent() {
                scheduleSave()
            }
        }

        // Seed only if still empty shortly after load
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            if isCompletelyEmpty {
                seedStarterContent()
                _ = ensureTownHallEVChargingProjectPresent()
                scheduleSave()
            }
        }
    }

    private var isCompletelyEmpty: Bool {
        highlights.isEmpty
        && glossary.isEmpty
        && watchlist.isEmpty
        && alerts.isEmpty
        && meetings.isEmpty
        && meetingFeeds.isEmpty
        && spending.isEmpty
        && contracts.isEmpty
        && capitalProjects.isEmpty
        && debt.isEmpty
        && grants.isEmpty
        && facilities.isEmpty
        && broadbandIssues.isEmpty
    }

    // MARK: - Persistence

    private func storeDirectory() -> URL? {
        guard backend == .fileSystem else { return nil }
        return RBAppDirectories.applicationSupportDirectory(appFolder: "RiverheadNYBudgetApp")
    }

    /// New writes go here; reads also try legacy names for backwards compatibility.
    private func primaryStoreURL(in dir: URL) -> URL {
        dir.appendingPathComponent("rb_civic_toolkit_v2.json")
    }

    private func candidateStoreURLs(in dir: URL) -> [URL] {
        [
            primaryStoreURL(in: dir),
            dir.appendingPathComponent("rb_civic_toolkit_snapshot.json"),
            dir.appendingPathComponent("rb_civic_toolkit.json"),
            dir.appendingPathComponent("rb_civic_toolkit_minimal.json")
        ]
    }

    struct Snapshot: Codable {
        var highlights: [Highlight] = []
        var glossary: [GlossaryTerm] = []
        var watchlist: [WatchItem] = []
        var alerts: [Alert] = []
        var meetings: [MeetingEvent] = []
        var meetingFeeds: [MeetingFeed] = []
        var spending: [SpendingRecord] = []
        var contracts: [Contract] = []
        var capitalProjects: [CapitalProject] = []
        var debt: [DebtItem] = []
        var grants: [Grant] = []
        var facilities: [Facility] = []
        var broadbandIssues: [BroadbandIssue] = []

        enum CodingKeys: String, CodingKey {
            case highlights, glossary, watchlist, alerts, meetings, meetingFeeds
            case spending, contracts, capitalProjects, debt, grants, facilities, broadbandIssues
        }

        init() {}

        init(highlights: [Highlight],
             glossary: [GlossaryTerm],
             watchlist: [WatchItem],
             alerts: [Alert],
             meetings: [MeetingEvent],
             meetingFeeds: [MeetingFeed],
             spending: [SpendingRecord],
             contracts: [Contract],
             capitalProjects: [CapitalProject],
             debt: [DebtItem],
             grants: [Grant],
             facilities: [Facility],
             broadbandIssues: [BroadbandIssue]) {
            self.highlights = highlights
            self.glossary = glossary
            self.watchlist = watchlist
            self.alerts = alerts
            self.meetings = meetings
            self.meetingFeeds = meetingFeeds
            self.spending = spending
            self.contracts = contracts
            self.capitalProjects = capitalProjects
            self.debt = debt
            self.grants = grants
            self.facilities = facilities
            self.broadbandIssues = broadbandIssues
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            highlights = try c.decodeIfPresent([Highlight].self, forKey: .highlights) ?? []
            glossary = try c.decodeIfPresent([GlossaryTerm].self, forKey: .glossary) ?? []
            watchlist = try c.decodeIfPresent([WatchItem].self, forKey: .watchlist) ?? []
            alerts = try c.decodeIfPresent([Alert].self, forKey: .alerts) ?? []
            meetings = try c.decodeIfPresent([MeetingEvent].self, forKey: .meetings) ?? []
            meetingFeeds = try c.decodeIfPresent([MeetingFeed].self, forKey: .meetingFeeds) ?? []
            spending = try c.decodeIfPresent([SpendingRecord].self, forKey: .spending) ?? []
            contracts = try c.decodeIfPresent([Contract].self, forKey: .contracts) ?? []
            capitalProjects = try c.decodeIfPresent([CapitalProject].self, forKey: .capitalProjects) ?? []
            debt = try c.decodeIfPresent([DebtItem].self, forKey: .debt) ?? []
            grants = try c.decodeIfPresent([Grant].self, forKey: .grants) ?? []
            facilities = try c.decodeIfPresent([Facility].self, forKey: .facilities) ?? []
            broadbandIssues = try c.decodeIfPresent([BroadbandIssue].self, forKey: .broadbandIssues) ?? []
        }
    }

    func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            await saveNow()
        }

    // MARK: - Watchlist helpers (compat)

    func isWatched(kind: WatchKind, key: String) -> Bool {
        watchlist.contains { $0.kind.normalized == kind.normalized && $0.key == key }
    }

    func toggleWatch(kind: WatchKind, key: String, title: String? = nil, notes: String = "", sources: [SourceRef] = []) {
        if let idx = watchlist.firstIndex(where: { $0.kind.normalized == kind.normalized && $0.key == key }) {
            watchlist.remove(at: idx)
        } else {
            watchlist.append(
                WatchItem(
                    kind: kind,
                    key: key,
                    title: title ?? key,
                    notes: notes,
                    createdAt: .now,
                    sources: sources
                )
            )
        }
        scheduleSave()
    }

    }

    func load() async {
        guard let dir = storeDirectory() else { return }
        let candidates = candidateStoreURLs(in: dir)
        guard let url = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) else { return }
        do {
            let data = try Data(contentsOf: url)
            let snap = try JSONDecoder.rb.decode(Snapshot.self, from: data)

            highlights = snap.highlights
            glossary = snap.glossary
            watchlist = snap.watchlist
            alerts = snap.alerts
            meetings = snap.meetings
            meetingFeeds = snap.meetingFeeds
            spending = snap.spending
            contracts = snap.contracts
            capitalProjects = snap.capitalProjects
            debt = snap.debt
            grants = snap.grants
            facilities = snap.facilities
            broadbandIssues = snap.broadbandIssues
        } catch {
            // First run / no file / decode mismatch — ignore (app remains usable)
        }
    }

    func saveNow() async {
        guard let dir = storeDirectory() else { return }
        let url = primaryStoreURL(in: dir)

        let snap = Snapshot(
            highlights: highlights,
            glossary: glossary,
            watchlist: watchlist,
            alerts: alerts,
            meetings: meetings,
            meetingFeeds: meetingFeeds,
            spending: spending,
            contracts: contracts,
            capitalProjects: capitalProjects,
            debt: debt,
            grants: grants,
            facilities: facilities,
            broadbandIssues: broadbandIssues
        )

        do {
            let data = try JSONEncoder.rb.encode(snap)
            try data.write(to: url, options: [.atomic])
        } catch {
            // ignore; app should still run
        }
    }

    // MARK: - Seed

    private func seedStarterContent() {
        let year = Calendar.current.component(.year, from: .now)

        highlights = [
            Highlight(
                title: "Add ‘What Changed’ highlights",
                detail: "Summarize the biggest year‑over‑year changes in plain English (top increases/decreases).",
                category: "Budget",
                year: year,
                sources: []
            )
        ]

        glossary = [
            GlossaryTerm(
                term: "Tax Levy",
                definition: "The total amount of property tax revenue collected by a government.",
                more: "Often discussed with the Tax Cap; levy growth can be constrained unless overridden.",
                tags: ["property tax", "tax cap"],
                sources: []
            )
        ]

        watchlist = [
            WatchItem(
                title: "Broadband franchise / competition",
                kind: .broadband,
                notes: "Track Optimum franchise terms, ROW permitting, and competitor enablement (e.g., Verizon).",
                createdAt: .now,
                sources: []
            )
        ]

        alerts = [
            Alert(
                title: "Tip",
                message: "You can log a policy item (franchise/competition) or a service issue in the Broadband tracker.",
                severity: .info,
                createdAt: .now,
                sources: []
            )
        ]

        // Minimal meeting feed example
        meetingFeeds = [
            MeetingFeed(name: "Town Board (placeholder)", url: "https://example.invalid/feed", enabled: false)
        ]

        // Minimal capital demo pin
        capitalProjects = [
            CapitalProject(
                name: "Example capital project",
                status: .planned,
                budget: 1_200_000,
                spent: 0,
                fundingSource: "Example funding",
                startDate: nil,
                endDate: nil,
                category: "Infrastructure",
                department: "Example Dept",
                address: "Add official address",
                coordinate: LatLon(lat: 40.917, lon: -72.662),
                notes: "Replace with real adopted CIP items.",
                url: nil,
                sources: []
            )
        ]

        facilities = [
            Facility(
                name: "Riverhead Town Hall (example)",
                kind: .town,
                address: "Add official address",
                coordinate: LatLon(lat: 40.917, lon: -72.662),
                sources: []
            )
        ]

        broadbandIssues = [
            BroadbandIssue.templateOptimumFranchiseCompetition()
        ]
    }
}

// MARK: - Codable helpers

private extension JSONEncoder {
    static var rb: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }
}

private extension JSONDecoder {
    static var rb: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
