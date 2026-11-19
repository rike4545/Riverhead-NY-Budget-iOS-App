import SwiftUI

@MainActor
struct BudgetAccuracyWatchlistView: View {
    private enum AccuracySeverity: String {
        case critical = "Critical"
        case high = "High"
        case explain = "Explain"

        var color: Color {
            switch self {
            case .critical: return .red
            case .high: return .orange
            case .explain: return .blue
            }
        }
    }

    private struct BudgetAccuracyFlag: Identifiable {
        let id = UUID()
        let rank: Int
        let title: String
        let severity: AccuracySeverity
        let actual2024: String
        let budget2024: String
        let variance: String
        let adopted2026: String
        let plainEnglish: String?
        let issue: String
        let action: String
        /// The flagged account, to read its newer figures from the 2027 Supplement.
        let account: String?

        init(
            rank: Int,
            title: String,
            severity: AccuracySeverity,
            actual2024: String,
            budget2024: String,
            variance: String,
            adopted2026: String,
            plainEnglish: String? = nil,
            issue: String,
            action: String,
            account: String? = nil
        ) {
            self.rank = rank
            self.title = title
            self.severity = severity
            self.actual2024 = actual2024
            self.budget2024 = budget2024
            self.variance = variance
            self.adopted2026 = adopted2026
            self.plainEnglish = plainEnglish
            self.issue = issue
            self.action = action
            self.account = account
        }
    }

    private var flags: [BudgetAccuracyFlag] {
        [
            .init(
                rank: 1,
                title: "Finance Department - Management Buy-Back",
                severity: .critical,
                actual2024: "$290,150",
                budget2024: "$30,000",
                variance: "+867%",
                adopted2026: "$35,400",
                plainEnglish: "This is usually cash paid to management or exempt employees for accrued leave, not normal salary. It can be caused by retirements, resignations, separation payouts, unused vacation/personal/comp time cash-outs, or a one-time settlement or reclassification.",
                issue: "The 2024 actual was nearly 10 times the recurring baseline shown for 2025, yet the 2026 line rises only modestly. This may be deferred buyout payments, a settlement, or reclassification, but the current supplement trail does not explain it.",
                action: "Require an immediate account-level explanation and identify whether the 2024 actual was amended, reclassified, or left to absorb silently.",
                account: "A01-1-1310-153-000-00000"
            ),
            .init(
                rank: 2,
                title: "Town Hall Postage",
                severity: .critical,
                actual2024: "$56,973",
                budget2024: "$6,265",
                variance: "+809%",
                adopted2026: "$6,265",
                issue: "The 2026 budget repeats the 2025 amount despite 2024 actual spending at about nine times the line.",
                action: "Confirm whether charges were misposted in 2024 or whether the recurring postage baseline is chronically understated.",
                account: "A01-1-1620-421-000-00000"
            ),
            .init(
                rank: 3,
                title: "Police Uniform OT",
                severity: .critical,
                actual2024: "$1,401,354",
                budget2024: "$1,000,000",
                variance: "+40%",
                adopted2026: "$1,000,000",
                plainEnglish: "Uniform OT means overtime for sworn uniformed police personnel. It is driven by minimum staffing rules, vacancies, sick or vacation backfill, shift coverage, arrests, court time, events, emergencies, training coverage, and contract overtime premiums.",
                issue: "The account is frozen below actual spend, making police costs look smaller at adoption while overruns are absorbed later. March workload data complicates the offset story: criminal incidents rose to 167 from 144 and total incidents rose to 2,994 from 2,922, even though accidents and summonses fell.",
                action: "Treat this as the first 2027 offset test: either reset the recurring overtime baseline honestly, or publish a monthly Police OT recovery plan showing how much of the $401K 2024 overrun can be captured through scheduling, cause coding, and tighter court/recall/training/event review without assuming workload has declined.",
                account: "A01-3-3120-111-UNI-00000"
            ),
            .init(
                rank: 4,
                title: "Police Sick Buy-Back",
                severity: .high,
                actual2024: "$334,738",
                budget2024: "$174,200",
                variance: "+92%",
                adopted2026: "$116,900",
                plainEnglish: "This is payment for unused sick leave under police contract or work rules. It can come from retirement or separation payouts, annual sick-leave sellbacks if permitted, or accumulated sick banks converting into cash.",
                issue: "The 2024 actual was nearly double budget, but the 2026 budget cuts the line by about one-third.",
                action: "Identify the contract change, usage change, or accounting correction that would make the lower 2026 number realistic.",
                account: "A01-3-3120-152-000-00000"
            ),
            .init(
                rank: 5,
                title: "Fire Protection - Part-Time Staff",
                severity: .critical,
                actual2024: "$47,089",
                budget2024: "$0",
                variance: "No budget",
                adopted2026: "$0",
                issue: "A personal-services payment was made against a line with no 2025 or 2026 budget.",
                action: "Determine whether this was a misposting or staff paid outside a visible appropriation.",
                account: "A01-3-3410-102-000-00000"
            ),
            .init(
                rank: 6,
                title: "Police Body Cameras",
                severity: .high,
                actual2024: "$1,304,519",
                budget2024: "$0",
                variance: "One-time",
                adopted2026: "$0",
                issue: "The body-camera purchase is a separate Police equipment account, not part of IT Equipment. It may be a one-time capital outlay, but the supplement shows no adopted baseline for the account.",
                action: "Confirm the capital authorization, funding source, and budget amendment trail so the one-time purchase is not confused with recurring IT equipment.",
                account: "A01-3-3120-240-305-00000"
            ),
            .init(
                rank: 7,
                title: "IT Equipment",
                severity: .high,
                actual2024: "$503,573",
                budget2024: "$230,450",
                variance: "+119%",
                adopted2026: "$164,660",
                issue: "IT Equipment is its own variance: 2024 actual was about 2.2 times the 2025 adopted baseline, then the 2026 line is cut further.",
                action: "Confirm what drove the 2024 equipment spike and whether the lower 2026 equipment baseline is operationally sustainable.",
                account: "A01-1-1680-240-000-00000"
            ),
            .init(
                rank: 8,
                title: "ES1 Sewer Hospitalization",
                severity: .high,
                actual2024: "$2,268,127",
                budget2024: "$353,997",
                variance: "+541%",
                adopted2026: "$400,963",
                issue: "This is consistent with a non-cash GASB 75/OPEB actuarial allocation through the sewer enterprise fund's hospitalization account, rather than normal insurance payments. The supplement does not explain the swing before returning to a much lower 2026 baseline.",
                action: "Tie the 2024 charge to the audited OPEB allocation or journal entry, identify where it was disclosed, and explain why the supplement does not label the spike as non-cash accounting activity.",
                account: "ES1-9-9060-810-NON-00000"
            ),
            .init(
                rank: 9,
                title: "Highway Machinery 5130",
                severity: .high,
                actual2024: "$1,268,472",
                budget2024: "$681,819",
                variance: "+86%",
                adopted2026: "Review",
                issue: "The Highway Machinery function spent far above the recurring baseline. The total combines $882,072 of equipment against a $236,500 equipment baseline, plus R&M equipment that was under its own baseline.",
                action: "Confirm whether the spending was separately authorized through capital or board action, and tie it back to the operating budget."
            ),
            .init(
                rank: 10,
                title: "Planning Environmental Review",
                severity: .critical,
                actual2024: "$100,081",
                budget2024: "$0",
                variance: "No budget",
                adopted2026: "$0",
                issue: "A six-figure consulting spend appears with no 2025 or 2026 budget line.",
                action: "Determine whether this was grant-funded, reimbursed, or an unappropriated consulting expenditure.",
                account: "A01-8-8020-436-100-00000"
            ),
            .init(
                rank: 11,
                title: "CDA Special Events",
                severity: .explain,
                actual2024: "$0",
                budget2024: "$0",
                variance: "YTD $7K",
                adopted2026: "$43,200",
                issue: "The $7,000 amount is 2025 YTD, not 2024 actual. The account had no 2025 adopted baseline, then gets formalized at $43,200 for 2026.",
                action: "Explain the event plan, funding source, public purpose, and why the new 2026 baseline is being created after mid-year spending appeared in 2025.",
                account: "A01-8-8686-450-000-00000"
            )
        ]
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Budget accuracy watch list", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(.red)

                    Text("These flags were first drawn from the 2026 Budget Supplement, which compared 2024 actuals to the 2025 adopted baseline. Each now also shows its 2025 actual, 2026 adopted and 2027 Adopted figures from the 2027 Supplement (the 2027 Preliminary, adopted unchanged on November 17, 2026), so you can see whether the new budget fixed the gap.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Important Caveat") {
                Text("This PDF does not show the 2024 adopted or amended budget. A variance here is not, by itself, proof of unauthorized spending. It is evidence that the recurring budget baseline, accounting classification, amendment trail, or public explanation needs review.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Through-Line") {
                Text("The pattern is bigger than one account: multiple recurring expense baselines sit below recent actuals, while several revenue lines, especially interest earnings, are budgeted far below actual collections. That combination can make the adopted budget look tighter and less volatile than the operating reality.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Quick Read") {
                metricRow("Flagged accounts", value: "\(flags.count)", tint: .red)
                metricRow("Zero-baseline activity flags", value: "4", tint: .orange)
                metricRow("Worst expense miss", value: "+867%", tint: .red)
            }

            Section("Revenue Baseline Warning") {
                Text("Interest earnings were budgeted far below actual receipts. General Fund interest came in at $1.936M in 2024 and $1.491M in 2025 against a $50K budget; the 2027 Adopted Budget raises it to $1.0M. DA1 took in $251K in 2025 against $5K, now $155K. EW1 took in $423K in 2025 against $400, now $11,371. Understated revenue can create a hidden year-end cushion while recurring expenses are also underbudgeted.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Accounts To Explain") {
                ForEach(flags) { flag in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(flag.rank)")
                                .font(.caption.weight(.black))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(flag.severity.color)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(flag.title)
                                    .font(.headline)
                                Text(flag.severity.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(flag.severity.color)
                            }

                            Spacer(minLength: 8)
                        }

                        newerFigures(for: flag)

                        HStack {
                            moneyBlock("2024 actual", flag.actual2024, tint: .red)
                            Spacer()
                            moneyBlock("2025 adopted", flag.budget2024, tint: .secondary)
                            Spacer()
                            moneyBlock("Variance", flag.variance, tint: flag.severity.color)
                            Spacer()
                            moneyBlock("2026", flag.adopted2026, tint: .blue)
                        }

                        if let plainEnglish = flag.plainEnglish {
                            Label(plainEnglish, systemImage: "text.bubble")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Text(flag.issue)
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Label(flag.action, systemImage: "checklist")
                            .font(.caption)
                            .foregroundStyle(flag.severity.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 8)
                }
            }

            sevenYearSections
            dataDrivenSections
        }
        .navigationTitle("Budget Accuracy")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Data-driven flags (from the shared Supplement ETL)

    @ViewBuilder
    private var sevenYearSections: some View {
        if let h = SupplementData.history {
            Section {
                Text(h.note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("\(String(h.supplementYears?.count ?? 7))-Year View \u{00B7} \(String(h.supplementYears?.first ?? 2020))\u{2013}\(String(h.supplementYears?.last ?? 2026)) Supplements")
            }

            if !h.underBudgeted.isEmpty {
                Section {
                    Text("These sit at or near zero for years, so any single-year comparison reads them as dead lines. Then the bill arrives. Together the \(String(h.proposalYear)) budget is \(h.underBudgeted.reduce(0) { $0 + $1.shortfall }.formatted(.currency(code: "USD").precision(.fractionLength(0)))) short of what they cost in the years they actually happened.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    ForEach(h.underBudgeted) { line in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(line.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RiverheadTheme.brandNavy)
                            sparkline(line.series)
                            HStack {
                                Text("Costs \(line.averageWhenActive.formatted(.currency(code: "USD").precision(.fractionLength(0)))) when it happens")
                                Spacer()
                                Text("\(String(h.proposalYear)): \(line.proposed.formatted(.currency(code: "USD").precision(.fractionLength(0))))")
                                    .foregroundStyle(line.proposed == 0 ? RiverheadTheme.brandCoral : RiverheadTheme.textSecondary)
                            }
                            .font(.caption2)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Goes Quiet, Then Costs Real Money")
                }
            }

            if !h.dueInBudgetYear.isEmpty {
                Section {
                    Text("Spending here repeats on an interval rather than every year. The last spike and the interval put the next one in \(String(h.proposalYear)), the year this budget covers.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    ForEach(h.dueInBudgetYear) { c in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(c.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RiverheadTheme.brandNavy)
                            Text("Every \(c.periodYears) years \u{00B7} last \(String(c.spikeYears.last ?? 0))")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(RiverheadTheme.brandGold)
                            sparkline(c.series)
                            Text("About \(c.spikeAverage.formatted(.currency(code: "USD").precision(.fractionLength(0)))) when it lands; the \(String(h.proposalYear)) budget carries \(c.proposed.formatted(.currency(code: "USD").precision(.fractionLength(0)))).")
                                .font(.caption2)
                                .foregroundStyle(RiverheadTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("On A Cycle, Due Again In \(String(h.proposalYear))")
                }
            }

            if !h.renumbered.isEmpty {
                Section {
                    Text("These accounts stopped and an identically-named one started. Nothing was cut and nothing appeared from nowhere \u{2014} the money changed account numbers. Listed so neither half is read as a finding.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    ForEach(h.renumbered) { r in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(r.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RiverheadTheme.brandNavy)
                            Text("\(r.oldAccount) through \(String(r.lastYear))")
                                .font(.caption2)
                                .foregroundStyle(RiverheadTheme.textSecondary)
                            Text("\(r.newAccount) from \(String(r.firstYear))")
                                .font(.caption2)
                                .foregroundStyle(RiverheadTheme.textSecondary)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Renumbered, Not Abandoned")
                }
            }
        }
    }

    @ViewBuilder
    private func sparkline(_ series: [String: Double]) -> some View {
        let years = series.keys.sorted()
        let peak = max(series.values.map { abs($0) }.max() ?? 1, 1)
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(years, id: \.self) { y in
                let v = series[y] ?? 0
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(v > 0 ? RiverheadTheme.brandSky : RiverheadTheme.textSecondary.opacity(0.25))
                    .frame(width: 8, height: max(2, CGFloat(abs(v) / peak) * 26))
            }
        }
        .frame(height: 28, alignment: .bottom)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var dataDrivenSections: some View {
        if let o = SupplementData.outliers {
            Section {
                Text("Beyond the curated flags above, these are auto-detected across the expenditure lines of the \(String(o.budgetYear)) Supplement. Mandated costs (pension, workers' comp, insurance, debt service) and revenue are excluded — their variance is obligation or timing, not waste.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Data-Detected · \(String(o.budgetYear)) Supplement")
            }

            outlierSection(
                "Over-Budget vs. Trailing Actuals",
                subtitle: "Controllable lines budgeted >30% above their run-rate. Recoverable pool: \(o.recoverablePoolControllable.formatted(.currency(code: "USD").precision(.fractionLength(0)))).",
                items: o.overBudget, tint: RiverheadTheme.brandCoral, amountLabel: "over", year: o.budgetYear
            )
            outlierSection(
                "Chronic Overruns",
                subtitle: "\(String(o.budgetYear - 2)) actual ran well above the \(String(o.budgetYear - 1)) adopted budget — a sign the baseline is unrealistic.",
                items: o.chronicOverrun, tint: .orange, amountLabel: "over budget", year: o.budgetYear
            )
            outlierSection(
                "Spending With No Budget",
                subtitle: "Real spending on lines the \(String(o.budgetYear - 1)) budget set to zero (interfund transfers excluded).",
                items: o.noBudget, tint: .red, amountLabel: "spent", year: o.budgetYear
            )
        }
    }

    @ViewBuilder
    private func outlierSection(_ title: String, subtitle: String, items: [SupplementOutlier], tint: Color, amountLabel: String, year: Int) -> some View {
        if !items.isEmpty {
            Section {
                ForEach(items.prefix(12)) { item in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Spacer(minLength: 8)
                            Text(item.excess, format: .currency(code: "USD").precision(.fractionLength(0)))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(tint)
                        }
                        Text("\(item.fund) · \(String(year - 2)) actual \(usd(item.actual)) → \(String(year)) \(BudgetLines.adoptedYear == year ? "adopted" : "proposed") \(usd(item.proposal)) · \(amountLabel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text("\(title) — \(items.count)")
            } footer: {
                Text(subtitle)
            }
        }
    }

    /// The flagged line in the newest Supplement (2027): its latest actual and the new year's figure.
    @ViewBuilder
    private func newerFigures(for flag: BudgetAccuracyFlag) -> some View {
        if let current = SupplementData.currentLines, let account = flag.account,
           let line = current.lines.first(where: { $0.account == account }) {
            let y = current.supplementYear
            let stage = BudgetLines.adoptedYear == y ? "adopted" : "proposed"
            HStack {
                moneyBlock("\(String(y - 2)) actual", usd(line.actual), tint: .red)
                Spacer()
                moneyBlock("\(String(y - 1)) adopted", usd(line.adopted), tint: .secondary)
                Spacer()
                moneyBlock("\(String(y)) \(stage)", usd(line.proposal), tint: .blue)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func usd(_ v: Double?) -> String {
        (v ?? 0).formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private func metricRow(_ title: String, value: String, tint: Color) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(tint)
        }
    }

    private func moneyBlock(_ label: String, _ value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
        }
        .frame(minWidth: 58, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        BudgetAccuracyWatchlistView()
    }
}
