import SwiftUI
import Charts

private struct ProposedBudgetMetric: Identifiable {
    let title: String
    let value: String
    let note: String
    let tint: Color

    var id: String { title }
}

private struct ProposedBudgetMoneyRow: Identifiable {
    let title: String
    let amount: Double
    let note: String

    var id: String { title }
}

private struct ProposedBudgetFundRow: Identifiable {
    let fund: String
    let baseline2026: Double
    let proposed2027: Double
    let note: String

    var id: String { fund }
    var change: Double { proposed2027 - baseline2026 }
}

private enum Proposed2027BudgetData {
    static let generalFundLevy2026 = 52_864_609.0
    static let generalFundLevy2027 = 51_278_671.0
    static let levyCut = 1_585_938.0
    static let generalFundAppropriations2027 = 72_234_417.0
    static let generalFundRevenues2027 = 72_727_221.0
    static let surplusPlanTotal = 4_950_000.0
    static let surplusRemaining = 50_000.0
    static let recurringOffsets = 1_911_000.0
    static let offsetCushion = 325_062.0

    static let budgetMessage = [
        "This is an unofficial planning proposal. The Town's official 2027 budget will be released later through the normal budget cycle, including the tentative, preliminary, public hearing, and adopted-budget steps.",
        "The proposal puts taxpayers first by modeling a 3% General Fund levy reduction while protecting services, reserves, and long-term financial stability.",
        "The plan does not treat the 2025 surplus as a recurring revenue source. It uses one-time money for one-time priorities: parks, vehicles, software, training, labor pressure, tax stabilization, and targeted workforce modernization.",
        "The tax reduction is supported by recurring savings and recurring revenue: potential early retirement savings, vacancy discipline, procurement controls, software/process improvements, avoided fleet costs, and conservative cannabis revenue recognition.",
        "The goal is a stable budget that does not depend on over-taxation, under-funded labor obligations, or hidden future costs. The Town Board, unions, department heads, and residents should review the assumptions together before adoption."
    ]

    static let headlineMetrics: [ProposedBudgetMetric] = [
        .init(title: "2027 General Fund levy", value: "$51.3M", note: "Modeled 3% below the planning baseline.", tint: .green),
        .init(title: "Levy reduction", value: "$1.59M", note: "Amount needed to hold the 3% tax-cut target.", tint: .green),
        .init(title: "One-time surplus plan", value: "$4.95M", note: "$50K remains unallocated from $5.0M.", tint: RiverheadTheme.brandSky),
        .init(title: "Recurring offsets", value: "$1.91M", note: "$325K cushion above the levy cut target.", tint: RiverheadTheme.brandMint)
    ]

    static let surplusUses: [ProposedBudgetMoneyRow] = [
        .init(title: "Parks and public spaces", amount: 750_000, note: "Visible one-time improvements."),
        .init(title: "Vehicles and fleet replacement", amount: 525_000, note: "Avoid debt, leases, and repair escalation."),
        .init(title: "Software improvements", amount: 150_000, note: "Reduce manual work and duplicate entry."),
        .init(title: "Training and tuition programs", amount: 150_000, note: "Retention and internal advancement."),
        .init(title: "Contract and labor pressure reserve", amount: 1_200_000, note: "CSEA wage/stipend path, longevity, health-benefit effects, and PBA/SOA risk."),
        .init(title: "Tax stabilization fund", amount: 2_000_000, note: "Levy smoothing, not recurring payroll."),
        .init(title: "Classification and compensation work", amount: 175_000, note: "Title changes and targeted headcount.")
    ]

    static let recurringOffsetsRows: [ProposedBudgetMoneyRow] = [
        .init(title: "Early retirement incentive", amount: 461_000, note: "Placeholder planning case. Times Review reported a public claim of up to $1.7M annual savings from 32 eligible employees, but final cost, eligibility, participation, overtime, and backfill details are not public."),
        .init(title: "Vacancy and position controls", amount: 500_000, note: "Hold or eliminate selected openings."),
        .init(title: "Software/process savings", amount: 250_000, note: "Tie savings to specific workflows."),
        .init(title: "Avoided vehicle debt and repairs", amount: 250_000, note: "Savings from cash-funded fleet choices."),
        .init(title: "Cannabis revenue above cautious baseline", amount: 250_000, note: "Use collection history conservatively."),
        .init(title: "Procurement and contract savings", amount: 200_000, note: "Disposal, supplies, software, and services.")
    ]

    static let fundRows: [ProposedBudgetFundRow] = [
        .init(fund: "General Fund", baseline2026: 68_945_417, proposed2027: 72_234_417, note: "Includes one-time surplus plan and recurring offsets."),
        .init(fund: "Highway Fund", baseline2026: 7_919_250, proposed2027: 8_077_635, note: "2% planning growth."),
        .init(fund: "Sewer District", baseline2026: 8_142_722, proposed2027: 8_305_576, note: "2% growth; 2025 loss needs rate review."),
        .init(fund: "Water District", baseline2026: 11_008_655, proposed2027: 11_228_828, note: "2% growth; capital/rate plan needed."),
        .init(fund: "Ambulance District", baseline2026: 2_388_824, proposed2027: 2_436_600, note: "2% planning growth."),
        .init(fund: "Debt Service", baseline2026: 6_888_150, proposed2027: 6_888_150, note: "Held flat pending BAN plan.")
    ]

    static let adoptionDecisions = [
        "Verify early retirement eligibility, payout amount, accrued leave cost, participation, backfill needs, overtime exposure, and reserve impact before booking savings.",
        "Use OSC's publication library to separate ERS and PFRS employees by tier and plan before estimating pension-related savings.",
        "For police employees, separately test PFRS Article 14 Tier 3 and 20-year or 25-year plan rules before assuming who would retire.",
        "Decide which ERI details belong in labor discussions and which budget math belongs in public work session review.",
        "Separate approved CSEA wage, stipend, longevity, and health-benefit pressure from PBA and SOA successor-contract risk after 2026.",
        "Approve recurring offsets before finalizing a 3% levy reduction.",
        "Show how the $2.0M tax stabilization fund may be used without turning it into a recurring payroll subsidy.",
        "Explain the $21.975M of BANs outstanding at 2025 year end and how debt service is handled in 2027.",
        "Review Sewer Fund rates and costs after the 2025 operating loss."
    ]
}

@MainActor
struct Proposed2027BudgetPresentationView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isCompact: Bool {
        horizontalSizeClass == .compact || dynamicTypeSize.isAccessibilitySize
    }

    private var metricColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: isCompact ? 1 : 4)
    }

    private var twoColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 14), count: isCompact ? 1 : 2)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                metricGrid
                budgetMessage
                taxpayerPlan
                surplusAndOffsets
                fundSummary
                adoptionDecisions
            }
            .padding(isCompact ? 14 : 22)
            .frame(maxWidth: 1180, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("2027 Budget Proposal")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "building.columns.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(RiverheadTheme.brandNavy))

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Text("Unofficial proposal")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RiverheadTheme.brandNavy)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(RiverheadTheme.brandMint.opacity(0.18))
                            .clipShape(Capsule())

                        Text("Planning view")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text("2027 Town of Riverhead Budget Proposal")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(RiverheadTheme.brandNavy)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("A taxpayer-first planning case that separates one-time surplus uses from recurring savings needed to reduce the 2027 tax levy.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Divider()

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Modeled tax direction")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("Reduce the General Fund levy by 3%")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.green)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 3) {
                    Text("Official budget")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("Comes later in the formal cycle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.brandNavy)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(isCompact ? 14 : 18)
        .background(RiverheadTheme.Surface.card)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.softBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var metricGrid: some View {
        LazyVGrid(columns: metricColumns, spacing: 12) {
            ForEach(Proposed2027BudgetData.headlineMetrics) { metric in
                metricTile(metric)
            }
        }
    }

    private var budgetMessage: some View {
        briefingPanel(title: "Budget Message", subtitle: "The plain-language case for the proposal.", systemImage: "text.quote") {
            VStack(alignment: .leading, spacing: 11) {
                ForEach(Array(Proposed2027BudgetData.budgetMessage.enumerated()), id: \.offset) { index, paragraph in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 23, height: 23)
                            .background(Circle().fill(index == 0 ? .orange : RiverheadTheme.brandNavy))

                        Text(paragraph)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var taxpayerPlan: some View {
        briefingPanel(title: "Taxpayer Plan", subtitle: "The levy math behind the 3% reduction target.", systemImage: "house.and.flag.fill") {
            LazyVGrid(columns: twoColumns, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    levyStep(title: "2026 planning levy", amount: Proposed2027BudgetData.generalFundLevy2026, tint: .secondary)
                    levyStep(title: "2027 proposed levy", amount: Proposed2027BudgetData.generalFundLevy2027, tint: .green)
                    levyStep(title: "Modeled reduction", amount: Proposed2027BudgetData.levyCut, tint: .green)
                }

                VStack(alignment: .leading, spacing: 10) {
                    statusLine(title: "Recurring offsets", value: currency(Proposed2027BudgetData.recurringOffsets), tint: RiverheadTheme.brandMint)
                    statusLine(title: "Needed for 3% cut", value: currency(Proposed2027BudgetData.levyCut), tint: .green)
                    statusLine(title: "Planning cushion", value: currency(Proposed2027BudgetData.offsetCushion), tint: .orange)

                    Text("A tax rate still depends on assessed value, exemptions, special district rolls, and the final taxable base.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }
        }
    }

    private var surplusAndOffsets: some View {
        LazyVGrid(columns: twoColumns, spacing: 14) {
            briefingPanel(title: "One-Time Surplus Uses", subtitle: "$4.95M assigned, $50K left unallocated.", systemImage: "banknote.fill") {
                Chart(Proposed2027BudgetData.surplusUses) { row in
                    BarMark(
                        x: .value("Amount", row.amount),
                        y: .value("Use", row.title)
                    )
                    .foregroundStyle(row.title.contains("Tax") ? RiverheadTheme.brandMint : RiverheadTheme.brandSky)
                }
                .frame(height: isCompact ? 250 : 290)
                .chartXAxisLabel("Allocation")

                VStack(spacing: 7) {
                    ForEach(Proposed2027BudgetData.surplusUses) { row in
                        moneyRow(row, tint: row.title.contains("Tax") ? RiverheadTheme.brandMint : RiverheadTheme.brandSky)
                    }
                }
            }

            briefingPanel(title: "Recurring Offsets", subtitle: "Savings and revenues that make levy relief durable.", systemImage: "chart.line.downtrend.xyaxis") {
                Chart(Proposed2027BudgetData.recurringOffsetsRows) { row in
                    BarMark(
                        x: .value("Amount", row.amount),
                        y: .value("Offset", row.title)
                    )
                    .foregroundStyle(.green)
                }
                .frame(height: isCompact ? 250 : 290)
                .chartXAxisLabel("Recurring impact")

                VStack(spacing: 7) {
                    ForEach(Proposed2027BudgetData.recurringOffsetsRows) { row in
                        moneyRow(row, tint: .green)
                    }
                }
            }
        }
    }

    private var fundSummary: some View {
        briefingPanel(title: "Fund Summary", subtitle: "Planning appropriations following the East Hampton-style budget outline.", systemImage: "chart.bar.xaxis") {
            Chart(Proposed2027BudgetData.fundRows) { row in
                BarMark(
                    x: .value("Proposed", row.proposed2027),
                    y: .value("Fund", row.fund)
                )
                .foregroundStyle(row.fund == "General Fund" ? RiverheadTheme.brandMint : RiverheadTheme.brandSky)
            }
            .frame(height: isCompact ? 240 : 310)
            .chartXAxisLabel("2027 proposed appropriation")

            VStack(spacing: 8) {
                ForEach(Proposed2027BudgetData.fundRows) { row in
                    fundRow(row)
                }
            }
        }
    }

    private var adoptionDecisions: some View {
        briefingPanel(title: "Decisions Before Adoption", subtitle: "Items to resolve before this can become an official budget.", systemImage: "exclamationmark.triangle.fill") {
            LazyVGrid(columns: twoColumns, spacing: 10) {
                ForEach(Proposed2027BudgetData.adoptionDecisions, id: \.self) { decision in
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.orange)
                            .frame(width: 22)

                        Text(decision)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func briefingPanel<Content: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.brandNavy)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(RiverheadTheme.brandSky.opacity(0.14)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(RiverheadTheme.brandNavy)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            content()
        }
        .padding(isCompact ? 14 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RiverheadTheme.Surface.card)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.softBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func metricTile(_ metric: ProposedBudgetMetric) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(metric.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(metric.value)
                .font(.title3.weight(.bold))
                .foregroundStyle(metric.tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(metric.note)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
        .background(RiverheadTheme.Surface.elevated)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(RiverheadTheme.softBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func levyStep(title: String, amount: Double, tint: Color) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer(minLength: 12)
            Text(currency(amount))
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.vertical, 4)
    }

    private func statusLine(title: String, value: String, tint: Color) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private func moneyRow(_ row: ProposedBudgetMoneyRow, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 12)
                Text(currency(row.amount))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Text(row.note)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(RiverheadTheme.softBorder.opacity(0.55))
                .frame(height: 1)
        }
    }

    private func fundRow(_ row: ProposedBudgetFundRow) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.fund)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 12)
                Text(currency(row.proposed2027))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RiverheadTheme.brandNavy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Text("\(currency(row.change)) change from 2026 baseline. \(row.note)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 5)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(RiverheadTheme.softBorder.opacity(0.55))
                .frame(height: 1)
        }
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

#Preview {
    NavigationStack {
        Proposed2027BudgetPresentationView()
    }
}
