import SwiftUI

struct RiverheadCampaignContributionsView: View {
    private let examples: [DonationExample] = [
        .init(label: "Donation #1", amount: 225),
        .init(label: "Donation #2", amount: 250),
        .init(label: "Donation #3", amount: 300),
        .init(label: "Donation #4", amount: 300)
    ]

    private var aggregateTotal: Int {
        examples.reduce(0) { $0 + $1.amount }
    }

    private var exceedsThreshold: Bool {
        aggregateTotal > 1000
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                scenarioCard
                headerCard
                coreRuleCard
                aggregationCard
                relatedPartyCard
                thresholdCard
                recusalDisclosureCard
                allowedVsProhibitedCard
                claimVsCodeCard
                rebuttalCard
                takeawayCard
            }
            .padding(20)
        }
        .background(backgroundGradient.ignoresSafeArea())
        .navigationTitle("Campaign Donations")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension RiverheadCampaignContributionsView {
    var scenarioCard: some View {
        InfoCard(title: "Scenario", systemImage: "questionmark.circle") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Original Question")
                    .font(.headline)

                Text("A developer contributes $225 to a Town official's campaign and later is awarded a Town contract. Does this violate the Town's ethics code?")
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                Text("Key Detail")
                    .font(.headline)

                Text("A single $225 contribution is below the $1,000 aggregation threshold, so it does not automatically trigger conflict-of-interest disclosure or recusal requirements under §113-4(B)(1)(f).")
                    .fixedSize(horizontal: false, vertical: true)

                HighlightBox(
                    title: "Why this matters",
                    message: "The ethics code evaluates total contributions from the same donor over a campaign, not just one payment in isolation."
                )
            }
        }
    }

    var headerCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Riverhead Ethics Code")
                    .font(.title.bold())

                Text("How aggregated campaign donations are treated under Town Code §§ 113-4 and 113-5.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    TagView(title: "Threshold", value: ">$1,000")
                    TagView(title: "Focus", value: "Disclosure")
                    TagView(title: "Topic", value: "Aggregation")
                }
            }
        }
    }

    var coreRuleCard: some View {
        InfoCard(title: "1. Core Rule", systemImage: "building.columns") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Under §113-4(B)(1)(f), campaign contributions aggregating more than $1,000 from the same person during the current or most recent campaign trigger conflict-of-interest scrutiny.")
                    .fixedSize(horizontal: false, vertical: true)

                HighlightBox(
                    title: "What matters most",
                    message: "The code looks at the combined total from the same donor, not just each individual contribution by itself."
                )
            }
        }
    }

    var aggregationCard: some View {
        InfoCard(title: "2. Aggregation Example", systemImage: "sum") {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(examples) { example in
                    HStack {
                        Text(example.label)
                        Spacer()
                        Text(example.amount.currencyString)
                            .fontWeight(.semibold)
                    }
                    .font(.body)
                    .padding(.vertical, 2)
                }

                Divider()

                HStack {
                    Text("Aggregate Total")
                        .font(.headline)
                    Spacer()
                    Text(aggregateTotal.currencyString)
                        .font(.headline)
                        .foregroundStyle(exceedsThreshold ? .red : .primary)
                }

                Label(
                    exceedsThreshold
                    ? "This total exceeds the $1,000 threshold."
                    : "This total does not exceed the $1,000 threshold.",
                    systemImage: exceedsThreshold ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
                )
                .font(.subheadline.weight(.medium))
                .foregroundStyle(exceedsThreshold ? .red : .green)
            }
        }
    }

    var thresholdCard: some View {
        InfoCard(title: "4. What Changes After $1,000", systemImage: "point.topleft.down.curvedto.point.bottomright.up") {
            VStack(alignment: .leading, spacing: 12) {
                BulletRow(text: "The donor becomes a conflict-sensitive party under the ethics code.")
                BulletRow(text: "The official must be careful not to act in a way they know may improperly benefit that donor.")
                BulletRow(text: "The relationship is no longer something that can be brushed aside as a series of unrelated small donations.")
            }
        }
    }

    var relatedPartyCard: some View {
        InfoCard(title: "3. Related-Party Watch", systemImage: "person.2.badge.gearshape") {
            VStack(alignment: .leading, spacing: 12) {
                Text("The scorecard should not stop at one corporate donor name. For Petrocelli-related matters, the watch list includes Petrocelli-named companies, individual family-member donor rows, and public-profile hospitality names when those names appear in campaign filings.")
                    .fixedSize(horizontal: false, vertical: true)

                BulletRow(text: "Entity donations and individual family-member donations should be visible together for transparency.")
                BulletRow(text: "Known public-profile names and assets include Jennifer Petrocelli, Jacqueline Phillips, Alexandra Bussi, The Preston House, Atlantis Banquets, Sea Star Ballroom, Taste the East End, Raphael Vineyard, Long Island Aquarium, and Hyatt Place East End.")
                BulletRow(text: "Related-party matches are not automatic proof of coordination, price fixing, favoritism, or quid pro quo conduct.")
                BulletRow(text: "They are a prompt to ask whether officials disclosed the relationship before acting on contracts, land sales, PILOTs, parking, zoning, or approvals involving the same developer interest.")
                BulletRow(text: "Public-source basis includes Schneps / QNS and Dan's Papers profiles describing Petrocelli family roles in Riverhead hospitality businesses.")

                HighlightBox(
                    title: "Plain-English rule",
                    message: "Do not treat one $225 check as the whole story if related entities or family members also appear in the campaign record."
                )
            }
        }
    }

    var recusalDisclosureCard: some View {
        InfoCard(title: "5. Recusal vs Disclosure", systemImage: "person.text.rectangle") {
            VStack(spacing: 12) {
                ComparisonRow(
                    title: "Appointed Officials",
                    detail: "Must recuse from the matter once the conflict category is triggered."
                )

                ComparisonRow(
                    title: "Elected Officials",
                    detail: "May continue to participate, but the relationship must be disclosed as part of the public record."
                )
            }
        }
    }

    var allowedVsProhibitedCard: some View {
        InfoCard(title: "6. Allowed vs Prohibited", systemImage: "checkmark.shield") {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Still Allowed")
                        .font(.headline)
                    BulletRow(text: "Receiving lawful campaign contributions")
                    BulletRow(text: "Adding together smaller donations for threshold analysis")
                    BulletRow(text: "An elected official participating after proper disclosure")
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Not Allowed")
                        .font(.headline)
                    BulletRow(text: "Quid pro quo arrangements")
                    BulletRow(text: "Steering contracts or approvals in exchange for support")
                    BulletRow(text: "Concealing a relationship that must be disclosed")
                }
            }
        }
    }

    var claimVsCodeCard: some View {
        InfoCard(title: "7. Claim vs Code", systemImage: "square.split.2x2") {
            VStack(spacing: 12) {
                SideBySideRow(
                    leftTitle: "Claim",
                    leftDetail: "$225 donation -> contract award = violation",
                    rightTitle: "Code",
                    rightDetail: "Below $1,000 threshold; no automatic conflict category triggered"
                )

                SideBySideRow(
                    leftTitle: "Claim",
                    leftDetail: "Any donor relationship requires recusal",
                    rightTitle: "Code",
                    rightDetail: "Recusal/disclosure tied to specific triggers (e.g., >$1,000 or financial interest)"
                )

                SideBySideRow(
                    leftTitle: "Claim",
                    leftDetail: "Small donations are irrelevant",
                    rightTitle: "Code",
                    rightDetail: "Small donations aggregate; rules apply once total exceeds $1,000"
                )

                SideBySideRow(
                    leftTitle: "Claim",
                    leftDetail: "Contract award proves wrongdoing",
                    rightTitle: "Code",
                    rightDetail: "Violation depends on process, disclosure, and absence of quid pro quo"
                )
            }
        }
    }

    var rebuttalCard: some View {
        InfoCard(title: "8. Rebuttal to the Issue", systemImage: "bubble.left.and.exclamationmark.bubble.right") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Claim")
                    .font(.headline)

                Text("A $225 campaign donation from a developer automatically means the later contract award was unethical or illegal.")
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                Text("Rebuttal")
                    .font(.headline)

                BulletRow(text: "A single $225 contribution is below the code's $1,000 aggregation threshold for campaign-contributor conflict treatment.")
                BulletRow(text: "That amount alone does not automatically require recusal or transactional disclosure under the specific contributor provision.")
                BulletRow(text: "Winning a Town contract later is not, by itself, proof of a violation. The legal question turns on process, disclosure obligations, and whether there was any improper exchange.")
                BulletRow(text: "The stronger ethics concern arises when multiple donations from the same donor aggregate above the threshold or when facts suggest favoritism, steering, or quid pro quo conduct.")

                HighlightBox(
                    title: "Plain-English rebuttal",
                    message: "The appearance of a connection may create political criticism, but the code does not treat every small lawful donation followed by later Town business as an automatic ethics violation."
                )
            }
        }
    }

    var takeawayCard: some View {
        InfoCard(title: "9. Bottom Line", systemImage: "text.alignleft") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Small donations do not avoid scrutiny forever. Once they aggregate to more than $1,000 from the same donor during the relevant campaign period, the ethics code treats the relationship as significant.")
                    .fixedSize(horizontal: false, vertical: true)

                HighlightBox(
                    title: "Plain-English summary",
                    message: "You cannot evade the rule by breaking one larger donor relationship into several smaller checks."
                )
            }
        }
    }

    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(.systemGroupedBackground),
                Color(.secondarySystemGroupedBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct DonationExample: Identifiable {
    let id = UUID()
    let label: String
    let amount: Int
}

private struct InfoCard<Content: View>: View {
    let title: String?
    let systemImage: String?
    @ViewBuilder let content: Content

    init(
        title: String? = nil,
        systemImage: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                HStack(spacing: 10) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .imageScale(.medium)
                    }

                    Text(title)
                        .font(.headline)
                }
            }

            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(radius: 8, y: 3)
    }
}

private struct TagView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
    }
}

private struct HighlightBox: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct BulletRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: 7))
                .padding(.top, 6)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ComparisonRow: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct SideBySideRow: View {
    let leftTitle: String
    let leftDetail: String
    let rightTitle: String
    let rightDetail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(leftTitle)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(leftDetail)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text(rightTitle)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(rightDetail)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private extension BinaryInteger {
    var currencyString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: Int(self))) ?? "$\(self)"
    }
}

#Preview {
    NavigationStack {
        RiverheadCampaignContributionsView()
    }
}
