//
//  TownBoardVotesView.swift
//  Riverhead NY Budget App
//
//  Every Town Board meeting, resolution, and roll-call vote — straight from the
//  Town's own published minutes — plus a forward-looking "Coming up" card so
//  residents can show up before a vote, not after.
//
//  Swift 6 / iOS 17+
//

import SwiftUI

@MainActor
struct TownBoardVotesView: View {
    @State private var index: MeetingsIndex? = RBMeetingsData.index
    @State private var upcoming: [UpcomingMeeting] = RBMeetingsData.upcoming
    @State private var isRefreshing = false

    // Card greens (match the web / Android "Coming up" card).
    private let cardGreen = Color(red: 0.941, green: 0.992, blue: 0.957)   // #F0FDF4
    private let deepGreen = Color(red: 0.078, green: 0.325, blue: 0.176)   // #14532D
    private let midGreen  = Color(red: 0.086, green: 0.396, blue: 0.204)   // #166534

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

    private func refreshCanonicalData() async {
        guard !isRefreshing else { return }
        isRefreshing = true

        async let refreshedIndex = RBMeetingsData.currentIndex()
        async let refreshedUpcoming = RBMeetingsData.currentUpcoming()
        let (resolvedIndex, resolvedUpcoming) = await (refreshedIndex, refreshedUpcoming)

        index = resolvedIndex
        upcoming = resolvedUpcoming
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
                        (Text("Public hearings: ").font(.caption.weight(.bold))
                            + Text(next.hearings.joined(separator: " · ")).font(.caption))
                            .foregroundStyle(RiverheadTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if next.agendaPublished && !next.docket.isEmpty {
                        Text("\(next.docket.count) resolutions on the docket:")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(midGreen)
                        ForEach(next.docket.prefix(12)) { r in
                            (Text("\(r.number)  ").font(.caption.weight(.bold)).foregroundColor(RiverheadTheme.brandBlue)
                                + Text(r.title).font(.caption).foregroundColor(RiverheadTheme.textPrimary))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if next.docket.count > 12 {
                            Text("…and \(next.docket.count - 12) more")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("The agenda for this meeting hasn't been posted yet — the Town usually publishes it a few days beforehand. The resolutions on the docket and any public hearings will appear here once it does.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Link("Official agendas & meeting info ↗",
                         destination: URL(string: "https://www.townofriverheadny.gov/129/Agendas-Minutes")!)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(midGreen)
                        .padding(.top, 2)
                }

                if !rest.isEmpty {
                    Divider()
                    Text("ALSO SCHEDULED")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(midGreen)
                    ForEach(rest.prefix(8)) { m in
                        Text(RBMeetingsData.formatMeeting(m.startDateTime))
                            .font(.caption)
                            .foregroundStyle(deepGreen)
                    }
                }

                Text("Schedule from the Town's CivicClerk portal. Times are as posted.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            .padding(4)
            .listRowBackground(cardGreen)
        }
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
