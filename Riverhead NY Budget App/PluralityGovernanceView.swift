import SwiftUI

private struct GovernancePrinciple: Identifiable {
    let title: String
    let detail: String
    let icon: String
    let tint: Color

    var id: String { title }
}

private struct GovernanceQuestion: Identifiable {
    let title: String
    let prompts: [String]

    var id: String { title }
}

@MainActor
struct PluralityGovernanceView: View {
    private let implications: [GovernancePrinciple] = [
        .init(
            title: "Faster decisions",
            detail: "A single dominant party can move budgets, appointments, contracts, and policy choices quickly because internal agreement is easier to maintain.",
            icon: "forward.fill",
            tint: RiverheadTheme.brandSky
        ),
        .init(
            title: "Clearer responsibility",
            detail: "When one group controls the agenda, residents can more easily identify who owns the outcome.",
            icon: "person.text.rectangle.fill",
            tint: RiverheadTheme.brandMint
        ),
        .init(
            title: "Lower public friction",
            detail: "Consensus inside the governing majority can make meetings feel orderly, but that order can also hide disagreement that should be tested in public.",
            icon: "bubble.left.and.text.bubble.right.fill",
            tint: RiverheadTheme.brandGold
        )
    ]

    private let limitations: [GovernancePrinciple] = [
        .init(
            title: "Weaker oversight",
            detail: "When nearly everyone at the table depends on the same political coalition, hard questions about contracts, hiring, debt, and budget assumptions can arrive late or softly.",
            icon: "eye.trianglebadge.exclamationmark.fill",
            tint: RiverheadTheme.brandCoral
        ),
        .init(
            title: "Groupthink risk",
            detail: "Good people can still normalize weak assumptions when no organized counter-view is present to stress-test them.",
            icon: "brain.head.profile",
            tint: .orange
        ),
        .init(
            title: "Thin public record",
            detail: "If debate happens privately before the vote, residents may see the final result without seeing the real tradeoffs.",
            icon: "doc.text.magnifyingglass",
            tint: .red
        ),
        .init(
            title: "Easier capture",
            detail: "Developers, vendors, unions, large donors, or organized interest groups need fewer access points when the governing coalition is narrow and predictable.",
            icon: "person.2.badge.key.fill",
            tint: .purple
        )
    ]

    private let pluralityPrinciples: [GovernancePrinciple] = [
        .init(
            title: "Plurality is the safer default",
            detail: "A town board works better when multiple viewpoints have enough presence to question assumptions, request documents, and force clearer explanations before votes.",
            icon: "person.3.sequence.fill",
            tint: RiverheadTheme.brandNavy
        ),
        .init(
            title: "Competition improves budgets",
            detail: "Competing blocs make it harder to bury recurring costs, optimistic revenue, weak procurement, or one-time fixes inside a quiet consent agenda.",
            icon: "chart.line.uptrend.xyaxis",
            tint: RiverheadTheme.brandSky
        ),
        .init(
            title: "Plurality is not paralysis",
            detail: "The goal is not constant obstruction. The goal is enough independent scrutiny that consensus means the idea survived public testing.",
            icon: "checkmark.seal.fill",
            tint: RiverheadTheme.brandMint
        )
    ]

    private let questions: [GovernanceQuestion] = [
        .init(
            title: "Budget votes",
            prompts: [
                "Who publicly challenged the baseline assumptions?",
                "Did anyone ask which costs are recurring versus one-time?",
                "Was the request-to-tentative change explained account by account?"
            ]
        ),
        .init(
            title: "Appointments and boards",
            prompts: [
                "Are appointments drawn from a broad civic bench?",
                "Do committees include people willing to disagree with the majority?",
                "Are vacancies, terms, and selection criteria easy to find?"
            ]
        ),
        .init(
            title: "Contracts and development",
            prompts: [
                "Was an independent valuation or competing option shown?",
                "Did the public see the fiscal exposure before approval?",
                "Were recusals, campaign contributions, and conflicts handled in the open?"
            ]
        )
    ]

    var body: some View {
        List {
            Section {
                header
            }

            Section("What One-Party Control Can Do Well") {
                ForEach(implications) { item in
                    principleRow(item)
                }
            }

            Section("Where It Breaks Down") {
                ForEach(limitations) { item in
                    principleRow(item)
                }
            }

            Section("Why Plurality Is Preferred") {
                ForEach(pluralityPrinciples) { item in
                    principleRow(item)
                }
            }

            Section("Resident Test") {
                ForEach(questions) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.title)
                            .font(.headline)

                        ForEach(group.prompts, id: \.self) { prompt in
                            Label(prompt, systemImage: "questionmark.circle")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }

            Section("Use This With Other Tools") {
                NavigationLink {
                    CouncilScorecardView()
                } label: {
                    Label("Open Council Scorecard", systemImage: "checklist.checked")
                }

                NavigationLink {
                    BudgetSupplementExplorerView()
                } label: {
                    Label("Open Budget Supplement Explorer", systemImage: "doc.text.magnifyingglass")
                }
            }
        }
        .navigationTitle("Plurality & Oversight")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Plurality is an accountability tool", systemImage: "person.3.sequence.fill")
                .font(.headline)
                .foregroundStyle(RiverheadTheme.brandNavy)

            Text("This view is not an argument for any single party. It is an argument for competitive representation: a governing table with enough independent voices to make budgets, contracts, appointments, and development deals survive public scrutiny.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("One-party rule can be efficient. Its limitation is that efficiency can become insulation. Plurality is preferred because it gives residents more questions, more document requests, and more visible debate before decisions harden.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func principleRow(_ item: GovernancePrinciple) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.icon)
                .foregroundStyle(item.tint)
                .frame(width: 28, height: 28)
                .background(Circle().fill(item.tint.opacity(0.12)))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                Text(item.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        PluralityGovernanceView()
            .environment(RBBudgetStore())
    }
}
