import SwiftUI

private let appCurrencyFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.maximumFractionDigits = 0
    return f
}()

@MainActor
struct BudgetExplainersView: View {
    @Environment(RBBudgetStore.self) private var store

    private enum ExplainerCategory: String, CaseIterable, Identifiable {
        case budgetMath
        case reserves
        case pressurePoints

        var id: String { rawValue }

        var title: String {
            switch self {
            case .budgetMath: return "Budget Math"
            case .reserves: return "Reserves & Stability"
            case .pressurePoints: return "Pressure Points"
            }
        }

        var subtitle: String {
            switch self {
            case .budgetMath:
                return "The terms people mix up most often."
            case .reserves:
                return "How to talk about fund balance without mistaking it for surplus cash."
            case .pressurePoints:
                return "The recurring forces that keep showing up in the baseline."
            }
        }
    }

    private struct Explainer: Identifiable {
        let id = UUID()
        let category: ExplainerCategory
        let symbol: String
        let accent: Color
        let title: String
        let plainEnglish: String
        let whyItMatters: String
        let practicalQuestion: String
    }

    private var explainers: [Explainer] {
        [
            .init(
                category: .budgetMath,
                symbol: "chart.bar.xaxis",
                accent: RiverheadTheme.accent,
                title: "Appropriations vs. Levy",
                plainEnglish: "Appropriations are what the Town plans to spend. The tax levy is only the property-tax portion used to pay for that plan after other revenues.",
                whyItMatters: "A budget can grow without all of that increase landing on the levy if recurring revenues, fees, or aid are doing some of the work.",
                practicalQuestion: "If spending rises, which non-tax revenues are expected to offset it before levy impact?"
            ),
            .init(
                category: .budgetMath,
                symbol: "house.and.flag",
                accent: RiverheadTheme.brandSky,
                title: "Why Taxes Can Rise Even If One Budget Line Is Flat",
                plainEnglish: "Your total bill is affected by multiple jurisdictions and assessed value changes, not just one Town line item.",
                whyItMatters: "Residents experience the whole bill, while the Town controls only one part of it.",
                practicalQuestion: "What changed this year: Town levy, assessed value, county/school share, or special districts?"
            ),
            .init(
                category: .reserves,
                symbol: "banknote",
                accent: .green,
                title: "Fund Balance Is Not Free Money",
                plainEnglish: "Using fund balance can smooth one year, but it lowers reserves. Riverhead has long referenced a 15% floor, while GFOA-style guidance often treats roughly two months of spending, about 17%, as a minimum benchmark rather than the automatic target.",
                whyItMatters: "The strongest reserve policy does not just say when money can be used. It also says how and when the cushion gets rebuilt.",
                practicalQuestion: "Is this use one-time, does it drop reserves below the floor, and what is the rebuild plan next year?"
            ),
            .init(
                category: .reserves,
                symbol: "arrow.trianglehead.2.clockwise.rotate.90",
                accent: .mint,
                title: "One-Time Money vs. Recurring Costs",
                plainEnglish: "Reserve draws, asset sales, settlements, or grants can help once. Payroll, benefits, and routine services come back every year.",
                whyItMatters: "A budget can look balanced now and still create a structural gap next year if one-time money is carrying recurring costs.",
                practicalQuestion: "Which part of this plan disappears after one year, and which costs still remain?"
            ),
            .init(
                category: .pressurePoints,
                symbol: "person.3.sequence",
                accent: .orange,
                title: "Contracts and Mandates Drive Baseline Costs",
                plainEnglish: "Large parts of the budget are tied to contracts, health insurance, pensions, and mandated services that are hard to cut quickly.",
                whyItMatters: "That is why salary settlements, overtime, and retirement costs can move the budget before new priorities are even added.",
                practicalQuestion: "What share of the increase is contractual or mandated versus discretionary policy choices?"
            ),
            .init(
                category: .pressurePoints,
                symbol: "building.columns",
                accent: RiverheadTheme.gold,
                title: "Capital vs Operating",
                plainEnglish: "Capital pays for assets (roads, equipment, facilities). Operating pays for ongoing services (staffing, utilities, maintenance).",
                whyItMatters: "A project can be affordable to build and still create new recurring costs after the ribbon-cutting.",
                practicalQuestion: "Will this project add recurring operating costs after construction is complete?"
            ),
            .init(
                category: .pressurePoints,
                symbol: "percent",
                accent: .pink,
                title: "Tax Cap vs. Override",
                plainEnglish: "The New York tax cap limits levy growth unless the Town Board overrides it by local law. It is a legal guardrail, not a promise that taxes never rise.",
                whyItMatters: "The public question is not just whether an override happens. It is whether the Town shows a cap-compliant baseline, clear findings, and a path back to stability.",
                practicalQuestion: "What would the budget look like under the cap, and what exactly does an override fund?"
            )
        ]
    }

    private var reserveRatio: Double {
        guard store.appropriations > 0 else { return 0 }
        return (store.estimatedFundBalance / store.appropriations) * 100
    }

    private var groupedExplainers: [(category: ExplainerCategory, items: [Explainer])] {
        ExplainerCategory.allCases.compactMap { category in
            let items = explainers.filter { $0.category == category }
            guard !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                currentContextCard

                ForEach(groupedExplainers, id: \.category.id) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(group.category.title)
                                .font(.title3.weight(.semibold))

                            Text(group.category.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        ForEach(group.items) { item in
                            explainerCard(item)
                        }
                    }
                }

                deepDivesSection
                howToUseCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Budget Explainers")
        .navigationBarTitleDisplayMode(.inline)
        .adMobBannerPlacement(showDebugPlaceholder: true)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("A plain-language guide to what the numbers are doing.")
                .font(.title2.weight(.bold))

            Text("Use this screen before a hearing, work session, or tax conversation when the language gets technical faster than the public can follow.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                explainerBadge("Plain English", systemImage: "text.alignleft")
                explainerBadge("Hearing-ready", systemImage: "person.2.wave.2")
                explainerBadge("Riverhead context", systemImage: "map")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    RiverheadTheme.brandSky.opacity(0.22),
                    RiverheadTheme.gold.opacity(0.14),
                    RiverheadTheme.cardBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(RiverheadTheme.softBorder, lineWidth: 1)
        )
    }

    private var currentContextCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Current Context")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                metricCard("Budget year", value: store.fiscalYearTitle, tint: RiverheadTheme.accent)
                metricCard("Town rate / $1,000", value: String(format: "$%.2f", store.ratePerThousand), tint: RiverheadTheme.brandSky)
                metricCard("Appropriations", value: currency(store.appropriations), tint: RiverheadTheme.gold)
                metricCard("Est. fund balance", value: currency(store.estimatedFundBalance), tint: .green)
            }

            Text("That estimated fund balance is about \(String(format: "%.1f%%", reserveRatio)) of appropriations, so the public debate is not just whether reserves exist, but how much should be retained, deployed once, or rebuilt.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RiverheadTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RiverheadTheme.softBorder, lineWidth: 1)
        )
    }

    private func explainerCard(_ item: Explainer) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: item.symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(item.accent)
                    .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.headline)

                    Text(item.plainEnglish)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Rectangle()
                .fill(RiverheadTheme.softBorder)
                .frame(height: 1)

            insightRow(title: "Why it matters", body: item.whyItMatters)
            insightRow(title: "Question to ask", body: item.practicalQuestion, accent: RiverheadTheme.accent)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RiverheadTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RiverheadTheme.softBorder, lineWidth: 1)
        )
    }

    private var deepDivesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Deep Dives")
                .font(.title3.weight(.semibold))

            Text("Use these when a short explainer is not enough and you want a specific Riverhead case study or policy lens.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            NavigationLink {
                SnowRemovalOverrunView()
            } label: {
                deepDiveCard(
                    title: "Snow Budget Overrun",
                    subtitle: "See how an in-year overrun can turn into transfers, reserve use, or next-year levy pressure.",
                    systemImage: "snowflake",
                    accent: .cyan
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                RiverheadCampaignContributionsView()
            } label: {
                deepDiveCard(
                    title: "Campaign Donation Ethics",
                    subtitle: "Review Riverhead’s ethics treatment of thresholds, aggregation, and disclosure.",
                    systemImage: "checkmark.shield",
                    accent: .green
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                LegalDefamationAnalysisView()
            } label: {
                deepDiveCard(
                    title: "Defamation Risk Analysis",
                    subtitle: "Review safer wording and New York defamation principles for public statements.",
                    systemImage: "exclamationmark.bubble",
                    accent: .orange
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var howToUseCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How to Use This")
                .font(.headline)

            Text("Pick the card that matches the claim you are hearing, then ask one follow-up about the funding source, the reserve effect, or whether the cost returns next year.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("The cleanest public-budget question is still: what line moves, by how much, and is it one-time or recurring?")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(RiverheadTheme.accent)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RiverheadTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RiverheadTheme.softBorder, lineWidth: 1)
        )
    }

    private func insightRow(title: String, body: String, accent: Color = .secondary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(accent)

            Text(body)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func explainerBadge(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(RiverheadTheme.primaryBlue)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(RiverheadTheme.cardBackground.opacity(0.92))
            .clipShape(Capsule())
    }

    private func metricCard(_ label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)

            Capsule()
                .fill(tint.opacity(0.85))
                .frame(width: 36, height: 5)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .background(RiverheadTheme.Surface.inset)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func deepDiveCard(title: String, subtitle: String, systemImage: String, accent: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RiverheadTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(RiverheadTheme.softBorder, lineWidth: 1)
        )
    }

    private func currency(_ value: Double) -> String {
        appCurrencyFormatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

@MainActor
struct SnowRemovalOverrunView: View {
    @State private var adoptedSnowBudget: Double = 300_000
    @State private var projectedSnowSpend: Double = 300_000

    private let personalServicesAdopted = 75_000.0
    private let contractualAdopted = 225_000.0

    private var overrun: Double {
        max(projectedSnowSpend - adoptedSnowBudget, 0)
    }

    private var overrunPercent: Double {
        guard adoptedSnowBudget > 0 else { return 0 }
        return (overrun / adoptedSnowBudget) * 100
    }

    var body: some View {
        List {
            Section("Riverhead 2026 Snow Line (DA1-5-5142)") {
                valueRow("Personal Services (OT)", value: currency(personalServicesAdopted))
                valueRow("Contractual", value: currency(contractualAdopted))
                valueRow("Adopted Total", value: currency(adoptedSnowBudget))

                Text("Code set: DA1-5-5142-000 / 100 / 111 / 400. 2026 adopted totals provided: OT $75,000 + Contractual $225,000 = $300,000.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Scenario") {
                VStack(alignment: .leading, spacing: 10) {
                    valueRow("Projected Snow Spend", value: currency(projectedSnowSpend))
                    Slider(value: $projectedSnowSpend, in: 100_000...700_000, step: 5_000)

                    valueRow("Projected Overrun", value: currency(overrun))
                    valueRow("Overrun % of Adopted", value: String(format: "%.1f%%", overrunPercent))
                }
            }

            Section("What Usually Happens") {
                Text("1) Department reports the overrun risk as storms accumulate.")
                Text("2) Town Board can adopt a budget transfer or amendment (often from contingency, fund balance, or underspent lines) to cover DA1-5-5142.")
                Text("3) If no in-year offset exists, the gap can reduce year-end fund balance and increase pressure on next year's tax levy.")
                Text("4) Highway operations continue; snow/ice response is typically treated as a core public safety service.")
            }

            Section("Policy Tradeoffs") {
                tradeoffRow(title: "Use contingency", detail: "Fastest operationally, but leaves less cushion for other surprises.")
                tradeoffRow(title: "Use fund balance", detail: "Avoids immediate service cuts, but weakens reserves if repeated.")
                tradeoffRow(title: "Cut other discretionary lines", detail: "Protects reserves, but delays other projects or programs.")
                tradeoffRow(title: "Carry cost into next budget", detail: "May require higher levy or tighter spending elsewhere.")
            }

            Section("Questions Residents Can Ask") {
                Text("What is the current year-to-date snow and ice spend vs budget?")
                Text("What funding source is proposed for any overrun?")
                Text("Is this winter an outlier, or are snow assumptions consistently low?")
                Text("Should the adopted snow line be reset to a more realistic baseline next year?")
            }
        }
        .navigationTitle("Snow Budget Overrun")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func valueRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer(minLength: 8)
            Text(value).fontWeight(.semibold)
        }
    }

    @ViewBuilder
    private func tradeoffRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.subheadline.weight(.semibold))
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func currency(_ value: Double) -> String {
        appCurrencyFormatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}
