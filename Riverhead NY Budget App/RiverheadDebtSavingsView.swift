import SwiftUI

@MainActor
struct RiverheadDebtSavingsView: View {
    @State private var reservePaydown: Double = 2_500_000
    @State private var assumedRate: Double = 4.0

    private struct DebtMetric: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let note: String
        let tint: Color
    }

    private struct SavingsLever: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let whatItDoes: String
        let caution: String
        let residentQuestion: String
        let tint: Color
    }

    private struct ActionStep: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let icon: String
    }

    private struct PolicyRecommendation: Identifiable {
        let id = UUID()
        let title: String
        let standardBasis: String
        let budgetAdoptionAction: String
        let draftLanguage: String
        let tint: Color
    }

    private var debtMetrics: [DebtMetric] {
        [
            .init(
                title: "Bonded debt",
                value: "$41.28M",
                note: "2023 audit (most recent full audit with a debt schedule), excluding BANs and premiums.",
                tint: RiverheadTheme.brandNavy
            ),
            .init(
                title: "Debt incl. BANs",
                value: "$64.08M",
                note: "Adds $22.8M of bond anticipation notes.",
                tint: RiverheadTheme.brandSky
            ),
            .init(
                title: "Debt limit used",
                value: "3.78%",
                note: "Capacity is not the same as affordability.",
                tint: RiverheadTheme.brandMint
            ),
            .init(
                title: "General Fund cushion",
                value: "$28.40M",
                note: "Total General Fund balance at year-end 2024.",
                tint: RiverheadTheme.brandGold
            )
        ]
    }

    private var savingsLevers: [SavingsLever] {
        [
            .init(
                title: "Refund callable high-rate bonds",
                icon: "arrow.triangle.2.circlepath",
                whatItDoes: "Can lower interest cost when old coupons are above current market rates and call dates allow a current refunding.",
                caution: "A refunding should show real present-value savings after legal, advisory, underwriting, and escrow costs.",
                residentQuestion: "Which maturities are callable now, and what is the net present-value savings?",
                tint: RiverheadTheme.brandNavy
            ),
            .init(
                title: "Reduce BAN rollover exposure",
                icon: "calendar.badge.clock",
                whatItDoes: "Converts short-term rate risk into a fixed repayment schedule or pays down notes before they become long-term debt.",
                caution: "Bonding too early can lock in cost before grants or project closeout numbers are final.",
                residentQuestion: "Which BANs will be retired with cash, grants, renewal notes, or long-term bonds?",
                tint: RiverheadTheme.brandSky
            ),
            .init(
                title: "Use excess reserves against expensive debt",
                icon: "banknote.fill",
                whatItDoes: "Retiring principal early removes future interest on the amount paid down.",
                caution: "Reserve use should stay above the Town's policy floor and include a rebuild plan.",
                residentQuestion: "What reserve level remains after payoff, and which debt produces the highest avoided interest?",
                tint: RiverheadTheme.brandMint
            ),
            .init(
                title: "Maximize EFC and grant funding",
                icon: "drop.fill",
                whatItDoes: "Subsidized clean-water financing, grants, or principal forgiveness can reduce both borrowing cost and effective principal.",
                caution: "Eligible projects need disciplined timing, documentation, and grant-match planning.",
                residentQuestion: "Was every eligible water, sewer, and resiliency project screened for EFC or state aid first?",
                tint: RiverheadTheme.brandTeal
            ),
            .init(
                title: "Pay-go routine replacements",
                icon: "wrench.and.screwdriver.fill",
                whatItDoes: "Funding recurring vehicles and equipment through annual capital reserves avoids turning predictable replacements into debt.",
                caution: "Pay-go only works if the budget funds the reserve before the equipment fails.",
                residentQuestion: "Which replacements are recurring enough to fund annually instead of bonding?",
                tint: RiverheadTheme.brandGold
            )
        ]
    }

    private var actionSteps: [ActionStep] {
        [
            .init(
                title: "Publish a debt schedule",
                detail: "Show each issue, rate, maturity, call date, fund source, and refunding eligibility.",
                icon: "tablecells"
            ),
            .init(
                title: "Rank payoff candidates",
                detail: "Prioritize callable, high-rate, or short-lived assets before touching low-rate long-term debt.",
                icon: "list.number"
            ),
            .init(
                title: "Model total taxpayer cost",
                detail: "Separate lower annual payments from true lifetime savings so restructuring does not hide higher long-run cost.",
                icon: "function"
            )
        ]
    }

    private var policyRecommendations: [PolicyRecommendation] {
        [
            .init(
                title: "Adopt a formal debt management policy",
                standardBasis: "GFOA debt-management guidance says governing-board approval gives credibility, transparency, and a shared framework for evaluating debt.",
                budgetAdoptionAction: "Attach the policy as a 2027 budget appendix and require Town Board review before any new bonds, BAN renewals, direct borrowings, or refundings.",
                draftLanguage: "The 2027 Budget shall include a Debt Management Policy requiring a public debt schedule, refunding savings test, useful-life match, post-issuance compliance review, and written municipal-advisor/bond-counsel recommendation before issuance.",
                tint: RiverheadTheme.brandNavy
            ),
            .init(
                title: "Create a GASB 88-style debt disclosure dashboard",
                standardBasis: "GASB 88 defines debt for note disclosures and emphasizes information about debt terms, risks, and future resource flows.",
                budgetAdoptionAction: "Publish a budget schedule that reconciles audit debt, BANs, direct placements, call dates, maturity dates, and debt service by fund.",
                draftLanguage: "Beginning with the 2027 Budget, the Supervisor's budget shall include a debt disclosure schedule showing principal, interest, maturity, call provisions, pledged revenues, default or acceleration terms, and annual debt service for each obligation.",
                tint: RiverheadTheme.brandSky
            ),
            .init(
                title: "Require capital requests to identify useful life and funding source",
                standardBasis: "GFOA capital-planning guidance links debt to useful life, fiscal capacity, reserve impact, and future operating costs.",
                budgetAdoptionAction: "Use the 2027 capital plan to classify projects as pay-go, grant-funded, EFC/SRF-eligible, BAN-financed, or bond-financed before adoption.",
                draftLanguage: "No 2027 capital appropriation should be adopted without a useful-life estimate, full project cost, expected operating impact, grant/EFC screening result, and recommended funding source.",
                tint: RiverheadTheme.brandMint
            ),
            .init(
                title: "Protect reserves while allowing targeted principal paydown",
                standardBasis: "GASB 54-style fund-balance discipline distinguishes restricted, committed, assigned, and unassigned balances; policy should define when one-time resources can be used.",
                budgetAdoptionAction: "Set a 2027 reserve floor, a target range, and a limited debt-paydown rule for balances above target.",
                draftLanguage: "The 2027 Budget may appropriate excess unassigned General Fund balance for one-time principal retirement only after preserving the adopted reserve floor and identifying a replenishment path for any drawdown.",
                tint: RiverheadTheme.brandGold
            ),
            .init(
                title: "Pair debt strategy with OPEB visibility",
                standardBasis: "GASB 75 makes retiree health obligations visible in financial reporting; the budget should not treat bonded debt as the only long-term exposure.",
                budgetAdoptionAction: "Add an annual OPEB and pension liability page to the 2027 budget so debt savings are not offset by hidden benefit-cost growth.",
                draftLanguage: "The 2027 Budget shall include a long-term obligations schedule covering bonded debt, BANs, leases or direct borrowings, compensated absences, pensions, and OPEB, with the latest audit or actuarial measurement date.",
                tint: RiverheadTheme.brandCoral
            )
        ]
    }

    private var estimatedInterestAvoided: Double {
        reservePaydown * (assumedRate / 100)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                metricGrid
                principleCard
                payoffModelCard
                leversSection
                actionChecklist
                policyRecommendationsSection
                sourceNote
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Debt Savings")
        .navigationBarTitleDisplayMode(.inline)
        .adMobBannerPlacement(showDebugPlaceholder: true)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Debt Cost Control", systemImage: "building.columns.circle.fill")
                .font(.headline)
                .foregroundStyle(RiverheadTheme.brandNavy)

            Text("How Riverhead can reduce interest costs without pretending principal disappears.")
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            Text("The strongest plan combines refunding analysis, fewer BAN rollovers, targeted reserve use, cheaper state financing, and pay-go funding for routine equipment.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RiverheadTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(RiverheadTheme.softBorder, lineWidth: 1)
        )
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(debtMetrics) { metric in
                VStack(alignment: .leading, spacing: 8) {
                    Text(metric.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(metric.value)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(metric.tint)
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)

                    Text(metric.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 122, alignment: .topLeading)
                .background(RiverheadTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(RiverheadTheme.softBorder, lineWidth: 1)
                )
            }
        }
    }

    private var principleCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Interest vs. Principal", systemImage: "percent")
                .font(.headline)
                .foregroundStyle(RiverheadTheme.brandNavy)

            comparisonRow(
                title: "Interest savings",
                detail: "Come from lower rates, shorter borrowing periods, subsidized financing, or faster payoff.",
                icon: "arrow.down.forward.circle.fill",
                color: RiverheadTheme.brandMint
            )

            comparisonRow(
                title: "Principal savings",
                detail: "Come from borrowing less, grants, principal forgiveness, asset-sale proceeds, or cash paydown.",
                icon: "dollarsign.circle.fill",
                color: RiverheadTheme.brandGold
            )

            Text("A restructuring that only stretches payments may lower the yearly bill while increasing total taxpayer cost.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(RiverheadTheme.brandCoral)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RiverheadTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(RiverheadTheme.softBorder, lineWidth: 1)
        )
    }

    private var payoffModelCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Reserve Paydown Sketch", systemImage: "slider.horizontal.3")
                .font(.headline)
                .foregroundStyle(RiverheadTheme.brandNavy)

            valueSlider(
                title: "One-time principal payoff",
                value: $reservePaydown,
                range: 0...10_000_000,
                step: 250_000,
                formattedValue: currency(reservePaydown)
            )

            valueSlider(
                title: "Assumed avoided rate",
                value: $assumedRate,
                range: 2.0...6.5,
                step: 0.25,
                formattedValue: String(format: "%.2f%%", assumedRate)
            )

            HStack(alignment: .firstTextBaseline) {
                Text("Estimated first-year interest avoided")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 12)
                Text(currency(estimatedInterestAvoided))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(RiverheadTheme.brandMint)
            }

            Text("This is a simple directional sketch. A real analysis must use each bond's call terms, remaining life, issuance costs, and reserve-policy floor.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RiverheadTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(RiverheadTheme.softBorder, lineWidth: 1)
        )
    }

    private var leversSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Savings Levers")
                .font(.title3.weight(.semibold))

            ForEach(savingsLevers) { lever in
                leverCard(lever)
            }
        }
    }

    private var actionChecklist: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next Public Ask")
                .font(.title3.weight(.semibold))

            ForEach(actionSteps) { step in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: step.icon)
                        .font(.headline)
                        .foregroundStyle(RiverheadTheme.brandNavy)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.headline)
                        Text(step.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RiverheadTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(RiverheadTheme.softBorder, lineWidth: 1)
                )
            }
        }
    }

    private var policyRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Draft 2027 Policy Package")
                    .font(.title3.weight(.semibold))

                Text("Recommended adoption items that connect the budget to accounting disclosure, capital planning, and long-term obligation management.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(policyRecommendations) { recommendation in
                policyRecommendationCard(recommendation)
            }
        }
    }

    private var sourceNote: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Source Note")
                .font(.headline)

            Text("Debt figures are based on Riverhead's 2023 Audited Basic Financial Statement (the most recent full audit with a debt-administration section — 2024/2025 filings are the simpler OSC Annual Financial Report Update form, which doesn't include one): $41,280,000 bonded debt excluding BANs and premiums, $22,800,000 in BANs, $64,080,000 total including BANs, and 3.78% of the constitutional debt limit exhausted (the governmental-activities portion only — water/sewer debt is excluded from that limit by statute). The General Fund cushion figure is separately confirmed from the 2024 Annual Financial Report Update's General Fund balance sheet ($28,407,676 total fund balance at 12/31/2024). Policy framing is based on GASB debt and OPEB disclosure concepts, GASB 54-style fund-balance discipline, and GFOA debt-management and capital-planning best practices.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RiverheadTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(RiverheadTheme.softBorder, lineWidth: 1)
        )
    }

    private func leverCard(_ lever: SavingsLever) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: lever.icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(lever.tint)
                    .frame(width: 34, height: 34)
                    .background(lever.tint.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(lever.title)
                        .font(.headline)
                    Text(lever.whatItDoes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()

            miniCallout(title: "Watch for", body: lever.caution, color: RiverheadTheme.brandCoral)
            miniCallout(title: "Ask", body: lever.residentQuestion, color: RiverheadTheme.brandNavy)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RiverheadTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(RiverheadTheme.softBorder, lineWidth: 1)
        )
    }

    private func comparisonRow(title: String, detail: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func policyRecommendationCard(_ recommendation: PolicyRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "doc.badge.gearshape")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(recommendation.tint)
                    .frame(width: 34, height: 34)
                    .background(recommendation.tint.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(recommendation.title)
                        .font(.headline)
                    Text(recommendation.standardBasis)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()

            miniCallout(title: "2027 adoption action", body: recommendation.budgetAdoptionAction, color: RiverheadTheme.brandNavy)
            miniCallout(title: "Draft language", body: recommendation.draftLanguage, color: recommendation.tint)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RiverheadTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(RiverheadTheme.softBorder, lineWidth: 1)
        )
    }

    private func miniCallout(title: String, body: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
            Text(body)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func valueSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        formattedValue: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 12)
                Text(formattedValue)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RiverheadTheme.brandNavy)
            }

            Slider(value: value, in: range, step: step)
        }
    }

    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

#Preview {
    NavigationStack {
        RiverheadDebtSavingsView()
    }
}
