//
//  MeetingsStore.swift
//  Riverhead NY Budget App
//
//  Town Board Votes — the Board's voting record, straight from the Town's own
//  published minutes, plus the Board's adopted meeting calendar and whatever
//  items an official Town source has published against each date.
//
//  Two sources, both of them the shared ETL's output. The bundled
//  MeetingsData/*.json renders instantly and works with no network; the web
//  app's published copy is preferred when one is reachable, because the bundle
//  only refreshes on an App Store release and the Board meets twice a month.
//
//  Three states are kept apart on purpose, because collapsing them is how a site
//  like this starts inventing things: a meeting having been HELD, its minutes
//  being PUBLISHED, and an individual VOTE RECORD being published. Nothing here
//  infers an agenda item, a vote, or a meeting date the Town has not itself
//  published.
//
//  Swift 6 / iOS 17+
//

import Foundation

// MARK: - Index (list of every meeting on record)

struct MeetingsIndex: Decodable {
    let totals: Totals
    let meetings: [MeetingSummary]

    struct Totals: Decodable {
        let meetings: Int
        let votes: Int
        let contested: Int
        let failed: Int
        let tabled: Int
    }
}

struct MeetingSummary: Decodable, Identifiable {
    let slug: String
    let date: String
    let type: String
    let total: Int
    let unanimous: Int
    let contested: Int
    let failed: Int
    let tabled: Int
    let preliminary: Bool?
    let docketCount: Int?

    var id: String { slug }
    var isPreliminary: Bool { preliminary ?? false }
}

// MARK: - A single meeting

struct MeetingDetail: Decodable {
    let date: String
    let type: String
    let calledToOrder: String?
    let roster: [RosterMember]
    let resolutions: [Resolution]
    let preliminary: Bool?
    let docket: [DocketItem]?

    var isPreliminary: Bool { preliminary ?? false }
}

struct RosterMember: Decodable, Identifiable {
    let last: String
    let name: String
    let title: String
    let party: String?

    var id: String { last }
}

struct Resolution: Decodable, Identifiable {
    let seq: Int
    let number: String?
    let title: String
    let result: String?
    let adopted: Bool?
    let tag: String?
    let ayesCount: Int?
    let naysCount: Int?
    let mover: String?
    let seconder: String?
    let votes: [String: String]?

    var id: Int { seq }
}

struct DocketItem: Decodable, Identifiable {
    let seq: Int
    let number: String
    let title: String

    var id: Int { seq }
}

// MARK: - The Board's schedule, and what has actually been published for it

/// A named official document or portal, so a figure on screen can always be
/// traced back to the Town page it came from.
struct MeetingSourceRef: Decodable {
    let title: String
    let url: String

    var link: URL? { URL(string: url) }
}

struct UpcomingMeeting: Decodable, Identifiable {
    let slug: String
    let date: String
    let startDateTime: String
    let type: String
    let agendaPublished: Bool
    /// Which official document the listed items came from. The ETL never infers
    /// an agenda item, so a date with no published source lists nothing at all
    /// rather than a guess at what the Board is likely to take up.
    let itemsSource: String?
    let docket: [DocketItem]
    let hearings: [String]

    var id: String { startDateTime }

    /// Plain-English name for `itemsSource`, worded as the web edition words it.
    var itemsSourceLabel: String? {
        switch itemsSource {
        case "published-agenda+official-calendar": return "Published agenda + official hearing notices"
        case "published-agenda":                   return "Published Town agenda"
        case "official-calendar":                  return "Official Town hearing notices"
        default:                                   return nil
        }
    }

    /// Everything an official source has actually published for this date.
    var publishedItemCount: Int { docket.count + hearings.count }
}

/// `upcoming.json` — the Board's own adopted meeting calendar, plus whatever
/// items an official Town source has published for each date.
struct MeetingSchedule: Decodable {
    let source: MeetingSourceRef
    /// The Board's adopted meeting calendar, which the ETL reconciles dates
    /// against so a date never appears here that the Town has not itself set.
    let scheduleSource: MeetingSourceRef?
    /// When the ETL last checked the Town's sources.
    let generatedAt: String
    /// Every regular meeting date on the Board's adopted calendar.
    let officialScheduleDates: [String]?
    /// Meetings already held, carried here until an official vote record exists.
    let recent: [UpcomingMeeting]?
    /// Meetings still to come.
    let meetings: [UpcomingMeeting]
}

// MARK: - Loader
//
// Two sources, deliberately: the bundled snapshot renders instantly and works
// with no network, and the web app's published copy is preferred when one is
// reachable so the app does not drift between App Store releases. Both decode
// the same shapes, so nothing downstream has to know which one it got.

enum RBMeetingsData {

    // MARK: Bundled snapshot — instant, offline, always available

    static let index: MeetingsIndex? = loadBundled("index")
    static let schedule: MeetingSchedule? = loadBundled("upcoming")

    static func meeting(_ slug: String) -> MeetingDetail? { loadBundled(slug) }

    // MARK: Reading a schedule

    /// Every dated meeting in a schedule, earliest first, de-duplicated. The ETL
    /// splits `recent` from `meetings` when it runs, but a bundled copy only
    /// refreshes on an app release and even a fetched one was generated earlier
    /// today, so the split is recomputed here rather than trusted.
    private static func scheduledMeetings(in schedule: MeetingSchedule?) -> [UpcomingMeeting] {
        guard let schedule else { return [] }
        var seen = Set<String>()
        return ((schedule.recent ?? []) + schedule.meetings)
            .filter { seen.insert($0.slug).inserted }
            .sorted { $0.startDateTime < $1.startDateTime }
    }

    /// Today-forward meetings, so one that has already happened is never shown
    /// as "next".
    static func upcomingMeetings(in schedule: MeetingSchedule?) -> [UpcomingMeeting] {
        let today = todayKey
        return scheduledMeetings(in: schedule).filter { $0.date >= today }
    }

    /// Meetings already held, newest first.
    static func recentlyHeldMeetings(in schedule: MeetingSchedule?) -> [UpcomingMeeting] {
        let today = todayKey
        return Array(scheduledMeetings(in: schedule).filter { $0.date < today }.reversed())
    }

    /// The most recently held meeting that still has no published roll call —
    /// either no record at all, or an agenda/minutes without vote results.
    ///
    /// A meeting having been held, its minutes being published, and an
    /// individual vote record being published are three separate states. This is
    /// the gap between the first and the last, and naming it is the point: the
    /// alternative is a resident assuming a silent meeting was never held.
    static func meetingAwaitingVoteRecord(
        in schedule: MeetingSchedule?,
        index: MeetingsIndex?
    ) -> UpcomingMeeting? {
        let recorded = index?.meetings ?? []
        return recentlyHeldMeetings(in: schedule).first { held in
            guard let row = recorded.first(where: { $0.slug == held.slug }) else { return true }
            return row.isPreliminary
        }
    }

    // MARK: The bundled snapshot, read through the above — what a view shows first

    static var upcoming: [UpcomingMeeting] { upcomingMeetings(in: schedule) }

    static var recentlyHeld: [UpcomingMeeting] { recentlyHeldMeetings(in: schedule) }

    static var awaitingVoteRecord: UpcomingMeeting? {
        meetingAwaitingVoteRecord(in: schedule, index: index)
    }

    // MARK: Current canonical copy, preferred when the network allows

    /// GitHub Pages first because it is the same published contract Riverhead
    /// Budget Live serves; raw main is a second source in case a Pages deploy is
    /// briefly behind. The bundled copy is returned when neither can be decoded,
    /// so this never renders less than the offline path would.
    static func currentIndex() async -> MeetingsIndex? {
        if let remote: MeetingsIndex = await loadRemote("index") { return remote }
        return index
    }

    static func currentMeeting(_ slug: String) async -> MeetingDetail? {
        if let remote: MeetingDetail = await loadRemote(slug) { return remote }
        return meeting(slug)
    }

    static func currentSchedule() async -> MeetingSchedule? {
        if let remote: MeetingSchedule = await loadRemote("upcoming") { return remote }
        return schedule
    }

    static func currentUpcoming() async -> [UpcomingMeeting] {
        upcomingMeetings(in: await currentSchedule())
    }

    // MARK: Sources

    private static let remoteRoots = [
        "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/data/meetings/",
        "https://raw.githubusercontent.com/rike4545/Riverhead-NY-Budget-Web-App/main/web/public/data/meetings/"
    ]

    private static func loadRemote<T: Decodable>(_ resource: String) async -> T? {
        for root in remoteRoots {
            guard let url = URL(string: root + resource + ".json") else { continue }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse,
                      (200..<300).contains(http.statusCode) else { continue }
                if let decoded = try? JSONDecoder().decode(T.self, from: data) {
                    return decoded
                }
            } catch {
                continue
            }
        }
        return nil
    }

    private static func loadBundled<T: Decodable>(_ resource: String) -> T? {
        let url = Bundle.main.url(forResource: resource, withExtension: "json", subdirectory: "MeetingsData")
            ?? Bundle.main.url(forResource: resource, withExtension: "json")
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    /// "yyyy-MM-dd" in Riverhead's own timezone. A 2 p.m. meeting is not over
    /// because it is past midnight in UTC.
    private static var todayKey: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    /// Format "2026-08-04T14:00:00Z" as "Tuesday, August 4, 2026 · 2:00 PM" using
    /// the clock time exactly as written (no timezone conversion — these are the
    /// local meeting times the Town posts).
    static func formatMeeting(_ iso: String) -> String {
        let datePart = String(iso.prefix(10))
        var day = datePart
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        if let d = f.date(from: datePart) {
            f.dateFormat = "EEEE, MMMM d, yyyy"
            day = f.string(from: d)
        }
        guard let tRange = iso.range(of: #"T(\d{2}):(\d{2})"#, options: .regularExpression) else { return day }
        let hhmm = iso[tRange].dropFirst() // "14:00"
        let parts = hhmm.split(separator: ":")
        guard parts.count == 2, var h = Int(parts[0]) else { return day }
        let minute = String(parts[1])
        let ampm = h >= 12 ? "PM" : "AM"
        h %= 12
        if h == 0 { h = 12 }
        return "\(day) · \(h):\(minute) \(ampm)"
    }
}
