//
//  TownBoardVotesView.swift
//  Riverhead NY Budget App
//
//  Every Town Board meeting, resolution, and roll-call vote — straight from the
//  Town's own published minutes — plus a forward-looking "Coming up" card so
//  residents can show up before a vote, not after.
//
//  The card only ever lists what an official Town source has actually published.
//  A date with no agenda posted shows that it has none, rather than a guess at
//  what the Board is likely to take up, and a meeting that has been held but has
//  no roll call on record says exactly that instead of disappearing.
//
//  Swift 6 / iOS 17+
//

import SwiftUI

@MainActor
struct TownBoardVotesView: View {
    // Seeded from the bundled snapshot so the first frame is instant and works
    // offline, then replaced by the web app's canonical copy if one is reachable
    // — the bundle only refreshes on an App Store release, and the Board meets
    // twice a month.
    @State private var index: MeetingsIndex? = RBMeetingsData.index
    @State private var schedule: MeetingSchedule? = RBMeetingsData.schedule
    @State private var isRefreshing = false

    private var upcoming: [UpcomingMeeting] {
        RBMeetingsData.upcomingMeetings(in: schedule)
    }

    private var awaitingVoteRecord: UpcomingMeeting? {
        RBMeetingsData.meetingAwaitingVoteRecord(in: schedule, index: index)
    }

    // Card greens (match the web / Android "Coming up" card).
    private let cardGreen = Color(red: 0.941, green: 0.992, blue: 0.957)   // #F0FDF4
    private let deepGreen = Color(red: 0.078, green: 0.325, blue: 0.176)   // #14532D
    private let midGreen  = Color(red: 0.086, green: 0.396, blue: 0.204)   // #166534

    // Card ambers for "held, but no roll call published yet" — a waiting state,
    // not a failure, so it reads as a note rather than an alarm.
    private let cardAmber = Color(red: 1.000, green: 0.984, blue: 0.922)   // #FFFBEB
    private let deepAmber = Color(red: 0.475, green: 0.267, blue: 0.035)   // #794409
    private let midAmber  = Color(red: 0.706, green: 0.400, blue: 0.055)   // #B4660E

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Town Board Votes")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(RiverheadTheme.textPrimary)
                    Text("Every Town Board meeting, resolution, and roll-call vote, straight from the Town's own published minutes.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Label(
                        isRefreshing ? "Checking the canonical meeting record…" : "Canonical web record · bundled offline fallback",
                        systemImage: isRefreshing ? "arrow.triangle.2.circlepath" : "checkmark.seal.fill"
                    )
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
            }

            if let held = awaitingVoteRecord {
                awaitingVoteRecordSection(held)
            }

            if let next = upcoming.first {
                comingUpSection(next: next, rest: Array(upcoming.dropFirst()))
            }

            if let totals = index?.totals {
                Section {
                    Text("\(totals.meetings) meetings · \(totals.votes) votes · \(totals.contested) contested · \(totals.failed) failed · \(totals.tabled) tabled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                if let meetings = index?.meetings {
                    ForEach(meetings) { meeting in
                        NavigationLink {
                            MeetingDetailView(slug: meeting.slug, date: meeting.date)
                        } label: {
                            MeetingRow(meeting: meeting)
                        }
                    }
                } else {
                    Text("Meeting records are unavailable.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("On record", systemImage: "checklist")
            } footer: {
                Text("Most votes are unanimous — the ones worth a second look are flagged contested, failed, or tabled. Tap any meeting for the full roll call.")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Town Board Votes")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await refreshCanonicalData()
        }
        .refreshable {
            await refreshCanonicalData()
        }
    }

    /// Prefers the web app's published copy, falling back to what is already on
    /// screen. Both halves are fetched together because the "held, but no roll
    /// call yet" card is derived from the schedule and the index agreeing.
    private func refreshCanonicalData() async {
        guard !isRefreshing else { return }
        isRefreshing = true

        async let refreshedIndex = RBMeetingsData.currentIndex()
        async let refreshedSchedule = RBMeetingsData.currentSchedule()
        let (resolvedIndex, resolvedSchedule) = await (refreshedIndex, refreshedSchedule)

        if let resolvedIndex { index = resolvedIndex }
        if let resolvedSchedule { schedule = resolvedSchedule }
        isRefreshing = false
    }

    // MARK: - Coming up

    @ViewBuilder
    private func comingUpSection(next: UpcomingMeeting, rest: [UpcomingMeeting]) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Coming up")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(deepGreen)
                    Text("show up before the vote, not after")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(midGreen)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("NEXT MEETING")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(midGreen)
                    Text(RBMeetingsData.formatMeeting(next.startDateTime))
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(deepGreen)
                        .fixedSize(horizontal: false, vertical: true)

                    if !next.hearings.isEmpty {
                        Text("\(Text("Officially noticed public hearings: ").font(.caption.weight(.bold)))\(Text(next.hearings.joined(separator: " · ")).font(.caption))")
                            .foregroundStyle(RiverheadTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if !next.docket.isEmpty {
                        Text("\(next.docket.count) published resolution\(next.docket.count == 1 ? "" : "s"):")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(midGreen)
                        ForEach(next.docket.prefix(12)) { r in
                            Text("\(Text("\(r.number)  ").font(.caption.weight(.bold)).foregroundColor(RiverheadTheme.brandBlue))\(Text(r.title).font(.caption).foregroundColor(RiverheadTheme.textPrimary))")
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if next.docket.count > 12 {
                            Text("…and \(next.docket.count - 12) more")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Nothing published is a fact about the Town's sources, so it
                    // is reported as one. The old copy predicted that an agenda
                    // "usually" appears a few days beforehand; this app does not
                    // know that, and a resident planning around it would be
                    // planning around our guess.
                    if next.publishedItemCount == 0 {
                        Text("No agenda items are published yet in the Town sources this app indexes. It does not fill this space with inferred or expected items.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let itemsSource = next.itemsSourceLabel {
                        Text("Item source: \(itemsSource).")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }

                    Link("Official agendas & meeting info ↗",
                         destination: URL(string: "https://www.townofriverheadny.gov/129/Agendas-Minutes")!)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(midGreen)
                        .padding(.top, 2)
                }

                if !rest.isEmpty {
                    Divider()
                    Text("LATER OFFICIAL DATES")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(midGreen)
                    ForEach(rest.prefix(8)) { m in
                        Text("\(RBMeetingsData.formatMeeting(m.startDateTime))\(Text(publishedItemsNote(m)).foregroundColor(.secondary))")
                            .font(.caption)
                            .foregroundStyle(deepGreen)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                provenanceFootnote
            }
            .padding(4)
            .listRowBackground(cardGreen)
        }
    }

    /// What the schedule above is, and what it is not. The two Town pages the
    /// dates and the items each come from are named, because "the Town's site"
    /// is not a citation anyone can check.
    @ViewBuilder
    private var provenanceFootnote: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let generatedAt = schedule?.generatedAt {
                Text("Schedule checked \(generatedAt). Times are as posted.")
            }
            if let dates = schedule?.officialScheduleDates, let first = dates.first {
                Text("The Board adopted \(dates.count) regular meeting dates for \(String(first.prefix(4))); no date appears here that the Town has not itself set.")
            }
            Text("A meeting being held, its minutes being published, and an individual vote record being published are three separate states. Listed items come only from a published agenda packet or an official Town public-hearing notice — this app does not infer agenda items.")
            if let scheduleSource = schedule?.scheduleSource, let url = scheduleSource.link {
                Link("Official Board meeting schedule ↗", destination: url)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(midGreen)
                    .padding(.top, 1)
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 2)
    }

    // MARK: - Held, but no roll call published yet

    /// The gap a resident is most likely to misread. The meeting happened; the
    /// Town has not published who voted how. Saying so beats letting the meeting
    /// vanish between the "coming up" card and the voting record.
    @ViewBuilder
    private func awaitingVoteRecordSection(_ held: UpcomingMeeting) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("LATEST MEETING · HELD")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(midAmber)

                Text(RBMeetingsData.formatMeeting(held.startDateTime))
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(deepAmber)
                    .fixedSize(horizontal: false, vertical: true)

                Text("This meeting has been held. No official Town source stating the individual vote results has been published yet, and this app will not infer those votes from the agenda, the resolution titles, or the video.")
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if !held.hearings.isEmpty {
                    Text("\(Text("Public hearings held: ").font(.caption.weight(.bold)))\(Text(held.hearings.joined(separator: " · ")).font(.caption))")
                        .foregroundStyle(RiverheadTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let row = recordedRow(for: held.slug) {
                    NavigationLink {
                        MeetingDetailView(slug: row.slug, date: row.date)
                    } label: {
                        Text("Open the agenda on record →")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(midAmber)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .listRowBackground(cardAmber)
        }
    }

    private func recordedRow(for slug: String) -> MeetingSummary? {
        index?.meetings.first { $0.slug == slug }
    }

    /// Kept out of the view body so the type-checker never has to reason about a
    /// ternary inside an interpolation inside a concatenated Text.
    private func publishedItemsNote(_ meeting: UpcomingMeeting) -> String {
        let count = meeting.publishedItemCount
        if count == 0 { return "  ·  no items published yet" }
        return count == 1 ? "  ·  1 published item" : "  ·  \(count) published items"
    }
}

// MARK: - Meeting row

private struct MeetingRow: View {
    let meeting: MeetingSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(meeting.date)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                Spacer(minLength: 8)
                if meeting.isPreliminary {
                    Text("agenda")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.brandBlue)
                } else {
                    Text("\(meeting.total) votes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(meeting.type)
                .font(.caption)
                .foregroundStyle(.secondary)

            if meeting.isPreliminary {
                Text("Minutes not posted yet — \(meeting.docketCount ?? 0) resolutions on the agenda")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.brandBlue)
            } else {
                let flags = flagText
                if flags.isEmpty {
                    Text("All unanimous")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.brandTeal)
                } else {
                    Text(flags)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.brandCoral)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var flagText: String {
        var parts: [String] = []
        if meeting.contested > 0 { parts.append("\(meeting.contested) contested") }
        if meeting.failed > 0 { parts.append("\(meeting.failed) failed") }
        if meeting.tabled > 0 { parts.append("\(meeting.tabled) tabled") }
        return parts.joined(separator: " · ")
    }
}
