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
        case gasbAccounting
        case fiscalStress
        case debtInstruments

        var id: String { rawValue }

        var title: String {
            switch self {
            case .budgetMath:      return "Budget Math"
            case .reserves:        return "Reserves & Stability"
            case .pressurePoints:  return "Pressure Points"
            case .gasbAccounting:  return "GASB Accounting Principles"
            case .fiscalStress:    return "Fiscal Stress & Planning"
            case .debtInstruments: return "Debt & Short-Term Borrowing"
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
            case .gasbAccounting:
                return "How Governmental Accounting Standards Board rules shape what you see in a budget."
            case .fiscalStress:
                return "OSC's framework for spotting trouble before it becomes a crisis."
            case .debtInstruments:
                return "The short-term tools towns use when cash and revenue do not arrive at the same time."
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
        let visualSteps: [VisualStep]
        let whyItMatters: String
        let practicalQuestion: String
    }

    private struct VisualStep: Identifiable {
        let id = UUID()
        let label: String
        let systemImage: String
        let tint: Color
    }

    private var explainers: [Explainer] {
        [
            .init(
                category: .budgetMath,
                symbol: "chart.bar.xaxis",
                accent: RiverheadTheme.accent,
                title: "Appropriations vs. Levy",
                plainEnglish: "Appropriations are what the Town plans to spend. The tax levy is only the property-tax portion used to pay for that plan after other revenues.",
                visualSteps: [
                    .init(label: "Spend plan", systemImage: "list.clipboard.fill", tint: RiverheadTheme.accent),
                    .init(label: "Other revenue", systemImage: "arrow.down.circle.fill", tint: .green),
                    .init(label: "Tax levy", systemImage: "house.and.flag.fill", tint: RiverheadTheme.brandSky)
                ],
                whyItMatters: "A budget can grow without all of that increase landing on the levy if recurring revenues, fees, or aid are doing some of the work.",
                practicalQuestion: "If spending rises, which non-tax revenues are expected to offset it before levy impact?"
            ),
            .init(
                category: .budgetMath,
                symbol: "house.and.flag",
                accent: RiverheadTheme.brandSky,
                title: "Why Taxes Can Rise Even If One Budget Line Is Flat",
                plainEnglish: "Your total bill is affected by multiple jurisdictions and assessed value changes, not just one Town line item.",
                visualSteps: [
                    .init(label: "Town levy", systemImage: "building.columns.fill", tint: RiverheadTheme.brandSky),
                    .init(label: "Assessment", systemImage: "house.lodge.fill", tint: RiverheadTheme.gold),
                    .init(label: "Full bill", systemImage: "doc.text.fill", tint: .orange)
                ],
                whyItMatters: "Residents experience the whole bill, while the Town controls only one part of it.",
                practicalQuestion: "What changed this year: Town levy, assessed value, county/school share, or special districts?"
            ),
            .init(
                category: .reserves,
                symbol: "banknote",
                accent: .green,
                title: "Fund Balance Is Not Free Money",
                plainEnglish: "Using fund balance can smooth one year, but it lowers reserves. Riverhead has long referenced a 15% floor, while GFOA-style guidance often treats roughly two months of spending, about 17%, as a minimum benchmark rather than the automatic target.",
                visualSteps: [
                    .init(label: "Reserve bucket", systemImage: "cylinder.split.1x2.fill", tint: .green),
                    .init(label: "One-year draw", systemImage: "drop.fill", tint: RiverheadTheme.gold),
                    .init(label: "Rebuild plan", systemImage: "arrow.trianglehead.2.clockwise.rotate.90", tint: RiverheadTheme.brandSky)
                ],
                whyItMatters: "The strongest reserve policy does not just say when money can be used. It also says how and when the cushion gets rebuilt.",
                practicalQuestion: "Is this use one-time, does it drop reserves below the floor, and what is the rebuild plan next year?"
            ),
            .init(
                category: .reserves,
                symbol: "arrow.trianglehead.2.clockwise.rotate.90",
                accent: .mint,
                title: "One-Time Money vs. Recurring Costs",
                plainEnglish: "Reserve draws, asset sales, settlements, or grants can help once. Payroll, benefits, and routine services come back every year.",
                visualSteps: [
                    .init(label: "One-time help", systemImage: "sparkles", tint: RiverheadTheme.gold),
                    .init(label: "Annual costs", systemImage: "calendar", tint: .red),
                    .init(label: "Next year gap", systemImage: "exclamationmark.triangle.fill", tint: .orange)
                ],
                whyItMatters: "A budget can look balanced now and still create a structural gap next year if one-time money is carrying recurring costs.",
                practicalQuestion: "Which part of this plan disappears after one year, and which costs still remain?"
            ),
            .init(
                category: .pressurePoints,
                symbol: "person.3.sequence",
                accent: .orange,
                title: "Contracts and Mandates Drive Baseline Costs",
                plainEnglish: "Large parts of the budget are tied to contracts, health insurance, pensions, and mandated services that are hard to cut quickly.",
                visualSteps: [
                    .init(label: "Contracts", systemImage: "signature", tint: .orange),
                    .init(label: "Benefits", systemImage: "cross.case.fill", tint: .pink),
                    .init(label: "Baseline", systemImage: "chart.line.uptrend.xyaxis", tint: .red)
                ],
                whyItMatters: "That is why salary settlements, overtime, and retirement costs can move the budget before new priorities are even added.",
                practicalQuestion: "What share of the increase is contractual or mandated versus discretionary policy choices?"
            ),
            .init(
                category: .pressurePoints,
                symbol: "building.columns",
                accent: RiverheadTheme.gold,
                title: "Capital vs Operating",
                plainEnglish: "Capital pays for assets (roads, equipment, facilities). Operating pays for ongoing services (staffing, utilities, maintenance).",
                visualSteps: [
                    .init(label: "Build or buy", systemImage: "hammer.fill", tint: RiverheadTheme.gold),
                    .init(label: "Run it yearly", systemImage: "gearshape.2.fill", tint: RiverheadTheme.brandSky),
                    .init(label: "Show both", systemImage: "rectangle.split.2x1.fill", tint: .green)
                ],
                whyItMatters: "A project can be affordable to build and still create new recurring costs after the ribbon-cutting.",
                practicalQuestion: "Will this project add recurring operating costs after construction is complete?"
            ),
            .init(
                category: .pressurePoints,
                symbol: "percent",
                accent: .pink,
                title: "Tax Cap vs. Override",
                plainEnglish: "The New York tax cap limits levy growth unless the Town Board overrides it by local law. It is a legal guardrail, not a promise that taxes never rise.",
                visualSteps: [
                    .init(label: "Cap formula", systemImage: "function", tint: .pink),
                    .init(label: "Board vote", systemImage: "person.3.fill", tint: RiverheadTheme.brandSky),
                    .init(label: "Public reason", systemImage: "quote.bubble.fill", tint: RiverheadTheme.gold)
                ],
                whyItMatters: "The public question is not just whether an override happens. It is whether the Town shows a cap-compliant baseline, clear findings, and a path back to stability.",
                practicalQuestion: "What would the budget look like under the cap, and what exactly does an override fund?"
            ),

            // MARK: GASB Accounting
            .init(
                category: .gasbAccounting,
                symbol: "list.number",
                accent: RiverheadTheme.primaryBlue,
                title: "GASB 54: The Five Fund Balance Tiers",
                plainEnglish: "Under GASB Statement 54, fund balance is not one bucket. It is five: nonspendable, restricted, committed, assigned, and unassigned. Only the last is truly discretionary.",
                visualSteps: [
                    .init(label: "Nonspendable", systemImage: "lock.fill", tint: .gray),
                    .init(label: "Restricted / Committed", systemImage: "checkmark.shield.fill", tint: .purple),
                    .init(label: "Assigned / Unassigned", systemImage: "hand.raised.fill", tint: .green)
                ],
                whyItMatters: "A town can report a large total fund balance and still have very little that is legally free to spend. OSC's GASB 54 guidance, adopted by NYS local governments, requires every budget document to show which tier each dollar sits in.",
                practicalQuestion: "Of the fund balance shown in this budget, how much is actually unassigned, and what are the constraints on the rest?"
            ),
            .init(
                category: .gasbAccounting,
                symbol: "arrow.left.arrow.right",
                accent: .purple,
                title: "Interfund Loans vs. Interfund Transfers",
                plainEnglish: "An interfund loan must be repaid with interest; an interfund transfer is a one-way move of money between funds. NYS towns routinely confuse the two in discussion, but the accounting and legal requirements are very different.",
                visualSteps: [
                    .init(label: "Loan (repay)", systemImage: "arrow.left.arrow.right", tint: .purple),
                    .init(label: "Transfer (permanent)", systemImage: "arrow.right.circle.fill", tint: RiverheadTheme.gold),
                    .init(label: "ARM rules apply", systemImage: "doc.text.fill", tint: RiverheadTheme.brandSky)
                ],
                whyItMatters: "OSC's Accounting Reference Manual (ARM), Chapter 6, controls how these are recorded. Using a transfer when a loan is intended can misrepresent a fund's real financial condition and create audit findings.",
                practicalQuestion: "Is this an interfund loan with a repayment schedule, or a permanent transfer, and does the board resolution reflect that distinction?"
            ),
            .init(
                category: .gasbAccounting,
                symbol: "calendar.badge.exclamationmark",
                accent: .teal,
                title: "Budgetary Basis vs. GAAP Basis",
                plainEnglish: "The adopted budget uses a modified cash or budgetary basis. The audited financial statements use GAAP. The same year can show a surplus on one basis and a deficit on the other.",
                visualSteps: [
                    .init(label: "Adopted budget", systemImage: "doc.badge.checkmark", tint: .teal),
                    .init(label: "Audit adjustment", systemImage: "plusminus.circle.fill", tint: .orange),
                    .init(label: "GAAP result", systemImage: "chart.line.uptrend.xyaxis", tint: .green)
                ],
                whyItMatters: "OSC audits and the annual Comptroller report compare GAAP results. A town that looks fine in the budget can show structural deterioration in the audited statements because of deferred liabilities, recognition timing, or encumbrance treatment.",
                practicalQuestion: "Does the budget presentation reconcile to GAAP, and what adjustments create the biggest gap between the two?"
            ),

            // MARK: Fiscal Stress
            .init(
                category: .fiscalStress,
                symbol: "waveform.path.ecg",
                accent: .red,
                title: "OSC Fiscal Stress Monitoring System (FSMS)",
                plainEnglish: "OSC annually scores every municipality on financial and environmental stress indicators: fund balance ratio, operating deficits, cash position, and population and property-value trends. A designation of 'significant stress' or 'stress' is a public signal.",
                visualSteps: [
                    .init(label: "Financial score", systemImage: "dollarsign.circle.fill", tint: .red),
                    .init(label: "Environmental score", systemImage: "house.and.flag.fill", tint: .orange),
                    .init(label: "OSC designation", systemImage: "exclamationmark.triangle.fill", tint: .red)
                ],
                whyItMatters: "A municipality can avoid an FSMS designation while still trending toward fiscal stress. The indicators OSC watches — especially recurring deficits, low unassigned fund balance, and negative cash — are the same ones that predict multi-year problems.",
                practicalQuestion: "Where does Riverhead currently score on each FSMS indicator, and which ones are trending in the wrong direction?"
            ),
            .init(
                category: .fiscalStress,
                symbol: "chart.line.uptrend.xyaxis.circle",
                accent: .indigo,
                title: "Multiyear Financial Planning",
                plainEnglish: "A single-year budget shows next year's plan. A multiyear projection shows whether that plan is sustainable. OSC recommends municipalities project revenues and expenditures at least three to five years out, incorporating known cost drivers.",
                visualSteps: [
                    .init(label: "Year 1 budget", systemImage: "1.circle.fill", tint: .indigo),
                    .init(label: "Years 2–5 trend", systemImage: "chart.line.uptrend.xyaxis", tint: .purple),
                    .init(label: "Structural test", systemImage: "checkmark.seal", tint: .green)
                ],
                whyItMatters: "One-year balanced budgets can mask multi-year structural gaps if pension costs, debt service, and contract obligations are growing faster than revenues. OSC's Multiyear Financial Planning guide and spreadsheet tool are available free at osc.ny.gov.",
                practicalQuestion: "Does this budget come with a three- or five-year projection, and what assumptions drive the out-years?"
            ),
            .init(
                category: .fiscalStress,
                symbol: "drop.fill",
                accent: .cyan,
                title: "Cash Flow vs. Fund Balance",
                plainEnglish: "Fund balance is the year-end accounting result. Cash flow is whether you have money in the bank on a given day. A government can have a healthy year-end fund balance and still run out of cash in February.",
                visualSteps: [
                    .init(label: "Tax bills go out", systemImage: "envelope.fill", tint: RiverheadTheme.gold),
                    .init(label: "January cash low", systemImage: "arrow.down.circle.fill", tint: .red),
                    .init(label: "Tax receipts land", systemImage: "arrow.up.circle.fill", tint: .green)
                ],
                whyItMatters: "OSC's cash management guidance recommends a monthly projected cash flow statement as a routine management tool, not just a crisis response. Towns that wait for a cash shortfall to build a forecast are already behind.",
                practicalQuestion: "What month is Riverhead's expected cash low point, and what is the cushion at that moment?"
            ),

            // MARK: Debt Instruments
            .init(
                category: .debtInstruments,
                symbol: "banknote.fill",
                accent: RiverheadTheme.gold,
                title: "Tax Anticipation Notes (TANs)",
                plainEnglish: "A TAN is short-term borrowing issued before tax revenue arrives. The Town borrows to meet expenses, then repays the note when property tax payments land. It is legal, common, and carries interest cost.",
                visualSteps: [
                    .init(label: "Issue TAN", systemImage: "doc.badge.plus", tint: RiverheadTheme.gold),
                    .init(label: "Pay expenses", systemImage: "creditcard.fill", tint: .orange),
                    .init(label: "Repay on receipt", systemImage: "arrow.clockwise", tint: .green)
                ],
                whyItMatters: "A TAN is not free. The interest cost is a real expense. Over-reliance on TANs year after year is an FSMS warning indicator that the operating budget is structurally thin and the town cannot self-fund cash gaps.",
                practicalQuestion: "Does Riverhead use TANs, how large are they, and is the size growing or shrinking over time?"
            ),
            .init(
                category: .debtInstruments,
                symbol: "building.2.crop.circle",
                accent: .orange,
                title: "Budget Notes and Deficiency Notes",
                plainEnglish: "A budget note finances a current-year operating deficit — the Town borrows to cover a shortfall. A deficiency note covers an actual cash deficiency after the year ends. Both are legal but both signal that the budget did not hold together.",
                visualSteps: [
                    .init(label: "Deficit identified", systemImage: "minus.circle.fill", tint: .red),
                    .init(label: "Board authorizes", systemImage: "checkmark.rectangle.fill", tint: .orange),
                    .init(label: "OSC notification", systemImage: "bell.fill", tint: .purple)
                ],
                whyItMatters: "OSC must be notified of deficiency notes. They appear on the municipality's audit history. A pattern of budget notes or deficiency notes is an early stress indicator and often precedes FSMS designation.",
                practicalQuestion: "Has Riverhead ever issued a budget note or deficiency note, and what was the cause?"
            ),
            .init(
                category: .debtInstruments,
                symbol: "hammer.fill",
                accent: RiverheadTheme.brandSky,
                title: "Bond Anticipation Notes (BANs)",
                plainEnglish: "A BAN is used to begin a capital project before permanent bonds are sold. The Town does the work, issues short-term debt (the BAN), then converts it to longer-term bonds when ready. BANs are not operating debt, but they do carry rollover risk.",
                visualSteps: [
                    .init(label: "Capital project", systemImage: "hammer.fill", tint: RiverheadTheme.brandSky),
                    .init(label: "Issue BAN", systemImage: "doc.badge.plus", tint: RiverheadTheme.gold),
                    .init(label: "Convert to bonds", systemImage: "arrow.2.circlepath", tint: .green)
                ],
                whyItMatters: "Riverhead currently carries BANs for capital projects. If a BAN matures and market conditions make permanent bonding expensive, the Town faces higher debt service costs or must roll the BAN again. OSC tracks BAN-heavy capital profiles as a monitoring item.",
                practicalQuestion: "What BANs are outstanding, when do they mature, and is the capital plan funded to convert them?"
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
                oscResourcesCard
                howToUseCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Budget Explainers")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("A plain-language guide to what the numbers are doing.")
                .font(.title2.weight(.bold))

            Text("Use this screen before a hearing, work session, or tax conversation when the language gets technical faster than the public can follow.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ExplainerFlowLayout(spacing: 10, lineSpacing: 8) {
                explainerBadge("Plain English", systemImage: "text.alignleft")
                explainerBadge("Pictures first", systemImage: "rectangle.on.rectangle.angled")
                explainerBadge("Hearing-ready", systemImage: "person.2.wave.2")
                explainerBadge("Riverhead context", systemImage: "map")
                explainerBadge("GASB principles", systemImage: "list.number")
                explainerBadge("OSC toolkit", systemImage: "building.columns.fill")
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

            whiteboardSketch(for: item)

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

    private func whiteboardSketch(for item: Explainer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Whiteboard version", systemImage: "pencil.and.outline")
                .font(.caption.weight(.bold))
                .foregroundStyle(item.accent)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    ForEach(Array(item.visualSteps.enumerated()), id: \.element.id) { index, step in
                        pictogramStep(step)

                        if index < item.visualSteps.count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(item.visualSteps) { step in
                        pictogramStep(step)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(item.accent.opacity(0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private func pictogramStep(_ step: VisualStep) -> some View {
        HStack(spacing: 7) {
            Image(systemName: step.systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(step.tint)
                .frame(width: 22, height: 22)
                .background(step.tint.opacity(0.12), in: Circle())

            Text(step.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(RiverheadTheme.Surface.inset, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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

            NavigationLink {
                OffBalanceLiabilitiesView()
            } label: {
                deepDiveCard(
                    title: "Off-Balance Liabilities",
                    subtitle: "Scan OPEB, leave payouts, claims, BANs, leases, and other costs that can sit outside simple line-item view.",
                    systemImage: "exclamationmark.triangle",
                    accent: RiverheadTheme.brandGold
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var oscResourcesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "building.columns.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.primaryBlue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("OSC Financial Toolkit")
                        .font(.headline)
                    Text("Office of the State Comptroller — free guides for local officials")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                oscResourceRow(
                    title: "Understanding the Budget Process",
                    category: "Budgeting",
                    tint: RiverheadTheme.accent,
                    urlString: "https://www.osc.ny.gov/files/local-government/publications/pdf/budgetprocess.pdf"
                )
                oscResourceRow(
                    title: "GASB 54: Fund Balance Reporting",
                    category: "Accounting",
                    tint: .purple,
                    urlString: "https://www.osc.ny.gov/files/local-government/publications/pdf/gasb54.pdf"
                )
                oscResourceRow(
                    title: "Reserve Funds",
                    category: "Reserves",
                    tint: .green,
                    urlString: "https://www.osc.ny.gov/files/local-government/publications/pdf/reservefunds.pdf"
                )
                oscResourceRow(
                    title: "Multiyear Financial Planning",
                    category: "Planning",
                    tint: .indigo,
                    urlString: "https://www.osc.ny.gov/files/local-government/publications/pdf/multiyear.pdf"
                )
                oscResourceRow(
                    title: "Investing and Protecting Public Funds",
                    category: "Cash Management",
                    tint: .cyan,
                    urlString: "https://www.osc.ny.gov/files/local-government/publications/pdf/investingpublicfunds.pdf"
                )
                oscResourceRow(
                    title: "Trouble Ahead: Managing Your Budget in Fiscal Stress",
                    category: "Fiscal Stress",
                    tint: .red,
                    urlString: "https://www.osc.ny.gov/files/local-government/publications/pdf/managingbudget.pdf"
                )
                oscResourceRow(
                    title: "Fiscal Stress Monitoring System",
                    category: "FSMS",
                    tint: .orange,
                    urlString: "https://www.osc.ny.gov/local-government/fiscal-monitoring"
                )
                oscResourceRow(
                    title: "Accounting Reference Manual (ARM) — Chapter 6",
                    category: "Accounting",
                    tint: .teal,
                    urlString: "https://www.osc.ny.gov/files/local-government/publications/pdf/arm.pdf"
                )
                oscResourceRow(
                    title: "Personal Service Cost Containment",
                    category: "Cost Control",
                    tint: RiverheadTheme.gold,
                    urlString: "https://www.osc.ny.gov/files/local-government/publications/pdf/costcontainment08.pdf"
                )
                oscResourceRow(
                    title: "Multiyear Capital Planning",
                    category: "Capital",
                    tint: RiverheadTheme.brandSky,
                    urlString: "https://www.osc.ny.gov/files/local-government/publications/pdf/capital_planning.pdf"
                )
            }

            Text("All resources published by the New York State Office of the State Comptroller. This app is unofficial and unaffiliated with OSC.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
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

    private func oscResourceRow(title: String, category: String, tint: Color, urlString: String) -> some View {
        Group {
            if let url = URL(string: urlString) {
                Link(destination: url) {
                    oscResourceRowContent(title: title, category: category, tint: tint)
                }
                .buttonStyle(.plain)
            } else {
                oscResourceRowContent(title: title, category: category, tint: tint)
            }
        }
    }

    private func oscResourceRowContent(title: String, category: String, tint: Color) -> some View {
        HStack(alignment: .center, spacing: 10) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(tint.opacity(0.15))
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(category)
                    .font(.caption)
                    .foregroundStyle(tint)
            }

            Spacer(minLength: 4)

            Image(systemName: "arrow.up.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
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
            .lineLimit(1)
            .fixedSize()
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

// MARK: - Wrapping layout for the header badges

/// Lays subviews left-to-right and wraps to a new line when the proposed
/// width runs out. File-scoped/private so it won't collide with any other
/// layout type elsewhere in the project.
private struct ExplainerFlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var widestRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                totalHeight += rowHeight + lineSpacing
                widestRow = max(widestRow, x - spacing)
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        widestRow = max(widestRow, x - spacing)
        let resolvedWidth = proposal.width ?? widestRow
        return CGSize(width: resolvedWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
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
