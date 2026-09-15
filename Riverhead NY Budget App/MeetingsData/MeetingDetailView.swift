//
//  MeetingDetailView.swift
//  Riverhead NY Budget App
//
//  A single Town Board meeting: who was present, and every resolution with its
//  result, who moved and seconded it, and how each member voted. Meetings whose
//  minutes aren't posted yet show the agenda docket instead.
//
//  Swift 6 / iOS 17+
//

import SwiftUI

@MainActor
struct MeetingDetailView: View {
    let slug: String
    let date: String

    @State private var contestedOnly = false
    @State private var detail: MeetingDetail?

    init(slug: String, date: String) {
        self.slug = slug
        self.date = date
        _detail = State(initialValue: RBMeetingsData.meeting(slug))
    }

    var body: some View {
        List {
            if let detail {
                if !detail.roster.isEmpty {
                    Section {
                        ForEach(detail.roster) { m in
                            HStack {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(m.name).font(.subheadline.weight(.semibold))
                                    Text(m.title).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if let party = m.party, !party.isEmpty {
                                    Text(party)
                                        .font(.caption2.weight(.semibold))
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(partyColor(party).opacity(0.16), in: Capsule())
                                        .foregroundStyle(partyColor(party))
                                }
                            }
                        }
                    } header: {
                        Label(detail.calledToOrder.map { "Called to order \($0)" } ?? "Board", systemImage: "person.3.fill")
                    }
                }

                if detail.isPreliminary {
                    preliminarySection(detail)
                } else {
                    resolutionsSection(detail)
                }
            } else {
                ContentUnavailableView(
                    "Meeting unavailable",
                    systemImage: "doc.questionmark",
                    description: Text("The record for this meeting could not be loaded.")
                )
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle(date)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: slug) {
            await refreshCanonicalDetail()
        }
        .refreshable {
            await refreshCanonicalDetail()
        }
    }

    private func refreshCanonicalDetail() async {
        if let current = await RBMeetingsData.currentMeeting(slug) {
            detail = current
        }
    }

    // MARK: - Preliminary (agenda docket, no votes yet)

    @ViewBuilder
    private func preliminarySection(_ detail: MeetingDetail) -> some View {
        Section {
            Text("Minutes for this meeting haven't been posted yet, so the roll-call votes aren't available. Below is the agenda docket — what the Board was scheduled to decide. The votes will appear here once the Town publishes the minutes (usually two to three days after the meeting).")
                .font(.caption)
                .foregroundStyle(.secondary)
                .listRowBackground(Color.clear)
        }

        if let docket = detail.docket, !docket.isEmpty {
            Section {
                ForEach(docket) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.number)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RiverheadTheme.brandBlue)
                        Text(item.title)
                            .font(.subheadline)
                            .foregroundStyle(RiverheadTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Label("Agenda docket · \(docket.count) resolutions", systemImage: "list.number")
            }
        }
    }

    // MARK: - Resolutions

    @ViewBuilder
    private func resolutionsSection(_ detail: MeetingDetail) -> some View {
        let shown = contestedOnly
            ? detail.resolutions.filter { ($0.tag ?? "") != "unanimous" }
            : detail.resolutions

        Section {
            Toggle(isOn: $contestedOnly) {
                Text("Show only contested, failed, or tabled")
                    .font(.footnote)
            }
            .listRowBackground(Color.clear)
        }

        Section {
            if shown.isEmpty {
                Text(contestedOnly ? "Every resolution at this meeting was unanimous." : "No resolutions recorded.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(shown) { res in
                    ResolutionRow(res: res, roster: detail.roster)
                }
            }
        } header: {
            Label("\(detail.resolutions.count) resolutions", systemImage: "checklist")
        }
    }

    private func partyColor(_ party: String) -> Color {
        switch party.lowercased().first {
        case "d": return RiverheadTheme.brandBlue
        case "r": return RiverheadTheme.brandCoral
        default:  return .secondary
        }
    }
}

// MARK: - Resolution row

private struct ResolutionRow: View {
    let res: Resolution
    let roster: [RosterMember]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if let number = res.number {
                    Text(number)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RiverheadTheme.brandBlue)
                }
                Spacer(minLength: 4)
                Text(resultLabel)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(tagColor.opacity(0.16), in: Capsule())
                    .foregroundStyle(tagColor)
            }

            Text(res.title)
                .font(.subheadline)
                .foregroundStyle(RiverheadTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let mover = res.mover, !mover.isEmpty {
                let second = (res.seconder.map { ", seconded by \($0)" }) ?? ""
                Text("Moved by \(mover)\(second)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let votes = res.votes, !votes.isEmpty {
                let dissent = (res.tag ?? "") != "unanimous"
                if dissent {
                    // Roll call matters here — show each member's vote.
                    FlowChips(members: roster, votes: votes)
                } else {
                    Text("Unanimous — all present voting aye")
                        .font(.caption2)
                        .foregroundStyle(RiverheadTheme.brandTeal)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var resultLabel: String {
        if let result = res.result, !result.isEmpty { return result }
        switch res.tag {
        case "failed":  return "FAILED"
        case "tabled":  return "TABLED"
        case "contested": return "CONTESTED"
        default: return (res.adopted ?? false) ? "ADOPTED" : "—"
        }
    }

    private var tagColor: Color {
        switch res.tag {
        case "failed":    return RiverheadTheme.brandCoral
        case "tabled":    return RiverheadTheme.brandGold
        case "contested": return RiverheadTheme.brandCoral
        default:          return RiverheadTheme.brandTeal
        }
    }
}

// MARK: - Per-member vote chips

private struct FlowChips: View {
    let members: [RosterMember]
    let votes: [String: String]

    var body: some View {
        // Simple wrapping row of member vote chips.
        VStack(alignment: .leading, spacing: 4) {
            ForEach(members) { m in
                let vote = votes[m.last] ?? "absent"
                HStack(spacing: 6) {
                    Circle().fill(color(for: vote)).frame(width: 7, height: 7)
                    Text(m.last).font(.caption2.weight(.semibold))
                    Text(vote.capitalized).font(.caption2).foregroundStyle(color(for: vote))
                }
            }
        }
    }

    private func color(for vote: String) -> Color {
        switch vote.lowercased() {
        case "aye", "yes":       return RiverheadTheme.brandTeal
        case "nay", "no":        return RiverheadTheme.brandCoral
        case "abstain":          return RiverheadTheme.brandGold
        default:                 return .secondary   // absent / recused
        }
    }
}
