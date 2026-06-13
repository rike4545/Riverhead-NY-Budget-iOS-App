import SwiftUI
import Charts

private enum SupplementExplorerPanel: String, CaseIterable, Identifiable {
    case summary
    case actuals
    case retirement
    case levyReduction
    case biggestChanges
    case requestCuts
    case departments
    case scenarioBridge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .summary: return "Summary"
        case .actuals: return "Actuals"
        case .retirement: return "Retirement"
        case .levyReduction: return "Tax Cut"
        case .biggestChanges: return "Variance"
        case .requestCuts: return "Request Review"
        case .departments: return "Departments"
        case .scenarioBridge: return "2027 Controls"
        }
    }
}

private enum SupplementLineKind: String {
    case expense = "Expense"
    case revenue = "Revenue"

    var tint: Color {
        switch self {
        case .expense: return .orange
        case .revenue: return .green
        }
    }
}

private struct SupplementFundSummary: Identifiable {
    let fund: String
    let name: String
    let tentativeExpenditures: Double
    let tentativeRevenues: Double
    let expenditureChange: Double
    let revenueChange: Double

    var id: String { fund }
    var balance: Double { tentativeRevenues - tentativeExpenditures }
}

private struct AnnualFinancialFundResult: Identifiable {
    let fund: String
    let name: String
    let revenuesAndSources: Double
    let expendituresAndUses: Double
    let endingBalance: Double
    let note: String

    var id: String { fund }
    var operatingResult: Double { revenuesAndSources - expendituresAndUses }
}

private struct AnnualFinancialWatchItem: Identifiable {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
    let note: String

    var id: String { title }
}

private struct SupplementChangeLine: Identifiable {
    let title: String
    let fund: String
    let kind: SupplementLineKind
    let adopted2025: Double
    let tentative2026: Double
    let change: Double
    let note: String
    let scenarioQuestion: String

    var id: String { "\(fund)-\(title)-\(kind.rawValue)" }
}

private struct SupplementRequestGapLine: Identifiable {
    let title: String
    let fund: String
    let request: Double
    let tentative: Double
    let note: String

    var id: String { "\(fund)-\(title)" }
    var gap: Double { request - tentative }
}

private struct SupplementDepartmentLine: Identifiable {
    let code: String
    let title: String
    let tentative: Double
    let change: Double
    let note: String

    var id: String { code }
}

private struct SupplementScenarioAction: Identifiable {
    let title: String
    let amount: Double
    let direction: SupplementLineKind
    let action: String
    let labControl: String

    var id: String { title }
}

private struct EarlyRetirementScenario: Identifiable {
    let title: String
    let retirements: Int
    let replacementRate: Double
    let annualSavings: Double
    let oneTimeCost: Double
    let note: String

    var id: String { title }
    var firstYearNet: Double { annualSavings - oneTimeCost }
    var breakEvenYears: Double { oneTimeCost / annualSavings }
}

private struct SurplusPriorityUse: Identifiable {
    let title: String
    let amount: Double
    let note: String

    var id: String { title }
}

private struct LevyReductionOffset: Identifiable {
    let title: String
    let conservative: Double
    let planning: Double
    let note: String

    var id: String { title }
}

private enum BudgetSupplementExplorerData {
    static let officialURL = URL(string: "https://www.townofriverheadny.gov/DocumentCenter/View/2780/2026-Budget-Supplement-PDF")!
    static let annualFinancialReportTitle = "2025 Annual Financial Report"

    static let fundSummaries: [SupplementFundSummary] = [
        .init(fund: "A01", name: "General Fund", tentativeExpenditures: 68_945_417, tentativeRevenues: 69_113_159, expenditureChange: 4_092_588, revenueChange: 4_260_330),
        .init(fund: "DA1", name: "Highway", tentativeExpenditures: 7_919_250, tentativeRevenues: 7_919_250, expenditureChange: 197_450, revenueChange: 197_450),
        .init(fund: "EW1", name: "Water", tentativeExpenditures: 9_908_655, tentativeRevenues: 11_008_655, expenditureChange: 345_655, revenueChange: 345_655),
        .init(fund: "ES1", name: "Sewer District", tentativeExpenditures: 7_342_722, tentativeRevenues: 8_142_722, expenditureChange: 352_338, revenueChange: 397_338),
        .init(fund: "SM1", name: "Ambulance", tentativeExpenditures: 2_388_824, tentativeRevenues: 2_388_824, expenditureChange: -2_124_525, revenueChange: -2_124_525),
        .init(fund: "V01", name: "Debt Service", tentativeExpenditures: 6_888_150, tentativeRevenues: 6_888_150, expenditureChange: 605_550, revenueChange: 605_550)
    ]

    static let annualFinancialResults: [AnnualFinancialFundResult] = [
        .init(fund: "A", name: "General Fund", revenuesAndSources: 71_010_826, expendituresAndUses: 66_007_499, endingBalance: 33_407_251, note: "Actual 2025 results added more than $5.0M to fund balance; unassigned balance ended at $29.7M."),
        .init(fund: "CM", name: "Miscellaneous Special Revenue", revenuesAndSources: 8_582_970, expendituresAndUses: 3_999_024, endingBalance: 30_784_387, note: "Large cash and fund-balance position should be explained by restriction, commitment, or intended use."),
        .init(fund: "DA", name: "Highway Town-wide", revenuesAndSources: 7_971_863, expendituresAndUses: 7_777_382, endingBalance: 5_594_416, note: "Slight positive operating result; useful context for equipment, roadwork, and snow-cost assumptions."),
        .init(fund: "ES", name: "Enterprise Sewer", revenuesAndSources: 8_739_458, expendituresAndUses: 9_831_597, endingBalance: 23_794_711, note: "Sewer lost ground in 2025, so 2026 and 2027 sewer rates, transfers, and capital plans need a real operating explanation."),
        .init(fund: "EW", name: "Enterprise Water", revenuesAndSources: 14_934_371, expendituresAndUses: 9_092_519, endingBalance: 49_353_504, note: "Water strengthened materially in 2025, helped by operating performance and transfers."),
        .init(fund: "V", name: "Debt Service", revenuesAndSources: 5_285_239, expendituresAndUses: 5_285_239, endingBalance: 0, note: "Debt service balanced exactly through transfers; affordability should be reviewed with the BAN maturity schedule.")
    ]

    static let annualFinancialWatchItems: [AnnualFinancialWatchItem] = [
        .init(title: "General Fund unassigned balance", value: "$29.7M", systemImage: "checkmark.seal.fill", tint: .green, note: "This replaces the older app baseline and is the better reserve number for policy and simulator views."),
        .init(title: "Sewer operating result", value: "-$1.1M", systemImage: "exclamationmark.triangle.fill", tint: .orange, note: "The enterprise fund spent more than it brought in during 2025."),
        .init(title: "BAN exposure due in 2026", value: "$22.0M", systemImage: "calendar.badge.exclamationmark", tint: RiverheadTheme.brandCoral, note: "Short-term notes for Town Hall and Town Square properties need repayment, renewal, or permanent financing."),
        .init(title: "General Fund benefits", value: "$18.8M", systemImage: "person.2.wave.2.fill", tint: .purple, note: "Benefits rose from $16.4M in 2024 and should stay tied to payroll, health enrollment, and retirement assumptions."),
        .init(title: "Cannabis tax actual", value: "$801K", systemImage: "leaf.fill", tint: .green, note: "Actual 2025 receipts exceeded the 2026 tentative estimate of $400K, but the line is still young enough to treat carefully."),
        .init(title: "Cash from financials", value: "$160.3M", systemImage: "banknote.fill", tint: RiverheadTheme.brandSky, note: "Large cash and collateral figures should be visible so deposits in transit and pledged coverage do not get misunderstood.")
    ]

    static let earlyRetirementAssumptions = [
        "2026 staffing base: 369 listed positions and about $33.6M of salary base.",
        "Average listed salary base: about $90,970 per position.",
        "Model adds a 35% fringe load for payroll-related savings.",
        "Planning incentive/payout cost: $50,000 per retiree.",
        "Savings only materialize where a position is eliminated, held vacant, or replaced at a lower step.",
        "May 26, 2026 status: the Supervisor publicly proposed an ERI, but no final cost, eligibility filter, payout schedule, participant count, or backfill plan has been released.",
        "Times Review reported that the Supervisor's office identified 32 eligible employees and projected up to $1.7M in annual savings; the same report put each 1% tax decrease at about $550,000.",
        "Independent payroll screen: 3% of the January 2026 salary-resolution payroll is about $915,000, so a 3% payroll-savings claim is plausible only with vacancy control, lower-step replacement, fringe savings, and overtime discipline.",
        "The public budget model should separate union negotiation details from the fiscal math: upfront payout, accrued leave, funding source, reserve impact, payback period, and recurring savings.",
        "Prior Riverhead ERIs were offered in 2010 for CSEA, 2012 for PBA, and 2019 during CSEA negotiations; the 2010 and 2012 programs were adopted by resolution after public hearings.",
        "The 2019 CSEA incentive was reported as applying to an estimated 15 to 20 eligible CSEA members, with retirees choosing between 48 months of fully paid family health-insurance premiums or $600 per month for 48 months if enrolled in individual coverage."
    ]

    static let earlyRetirementScenarios: [EarlyRetirementScenario] = [
        .init(title: "Conservative", retirements: 10, replacementRate: 0.85, annualSavings: 184_000, oneTimeCost: 500_000, note: "Most retirees are replaced close to current cost. This is mainly a workforce transition tool, not a first-year budget fix."),
        .init(title: "Planning Case", retirements: 15, replacementRate: 0.75, annualSavings: 461_000, oneTimeCost: 750_000, note: "Moderate participation with replacement at lower steps. Recurring savings appear after the initial payout period."),
        .init(title: "Aggressive", retirements: 20, replacementRate: 0.65, annualSavings: 860_000, oneTimeCost: 1_000_000, note: "Requires lower-cost backfill, vacancy holds, or selective position elimination. Service impact review becomes important."),
        .init(title: "Position Elimination", retirements: 10, replacementRate: 0.00, annualSavings: 1_228_000, oneTimeCost: 500_000, note: "Largest fiscal impact, but only realistic for functions where work can be redesigned, consolidated, or reduced.")
    ]

    static let surplusPriorityUses: [SurplusPriorityUse] = [
        .init(title: "Parks and public spaces", amount: 750_000, note: "Target visible one-time park improvements without adding recurring maintenance obligations unless the operating budget shows the upkeep."),
        .init(title: "Vehicles and fleet replacement", amount: 525_000, note: "Use cash for justified replacements to reduce future debt, lease, and repair pressure."),
        .init(title: "Software improvements", amount: 150_000, note: "Prioritize systems that reduce manual work, paper handling, duplicate entry, or outside service costs."),
        .init(title: "Training and tuition programs", amount: 150_000, note: "Improve retention, succession planning, certifications, and internal promotion pathways."),
        .init(title: "Contract and labor pressure reserve", amount: 1_200_000, note: "Reserve for the approved CSEA 2026-2029 wage/stipend path, longevity and health-benefit effects, payroll/fringe spillover, and PBA/SOA successor-contract risk so labor costs do not quietly become 2027 levy pressure."),
        .init(title: "Tax stabilization fund", amount: 2_000_000, note: "Hold one-time surplus for smoothing levy shocks, not for recurring salaries or benefits."),
        .init(title: "Classification and compensation investments", amount: 175_000, note: "Fund class and compensation reclassification, title changes, and targeted additional headcount where the budget documents a service need.")
    ]

    static let levyReductionOffsets: [LevyReductionOffset] = [
        .init(title: "Early retirement incentive", conservative: 184_000, planning: 461_000, note: "Times Review reported a public claim of up to $1.7M in annual savings from 32 eligible employees. Do not book any amount as a tax-cut offset until the Town releases cost, eligibility, payout, participation, backfill, overtime, and reserve-impact details."),
        .init(title: "Vacancy and position controls", conservative: 300_000, planning: 500_000, note: "Hold vacancies open or eliminate select positions where work can be consolidated."),
        .init(title: "Software/process savings", conservative: 150_000, planning: 250_000, note: "Tie savings to specific workflows, not generic efficiency language."),
        .init(title: "Avoided vehicle debt and repairs", conservative: 200_000, planning: 250_000, note: "Cash-funded fleet replacement should reduce future debt service, leases, or repair escalation."),
        .init(title: "Cannabis revenue above cautious baseline", conservative: 150_000, planning: 250_000, note: "Use part of the 2025 actual collection history, but keep the line conservative."),
        .init(title: "Procurement and contract savings", conservative: 100_000, planning: 200_000, note: "Target disposal, supplies, software subscriptions, and professional-service renewals.")
    ]

    static var surplusPriorityTotal: Double {
        surplusPriorityUses.reduce(0) { $0 + $1.amount }
    }

    static let surplusEnvelope: Double = 5_000_000

    static var surplusRemaining: Double {
        surplusEnvelope - surplusPriorityTotal
    }

    static var conservativeLevyReductionTotal: Double {
        levyReductionOffsets.reduce(0) { $0 + $1.conservative }
    }

    static var planningLevyReductionTotal: Double {
        levyReductionOffsets.reduce(0) { $0 + $1.planning }
    }

    static let biggestChanges: [SupplementChangeLine] = [
        .init(title: "Property Taxes", fund: "A01", kind: .revenue, adopted2025: 48_639_479, tentative2026: 52_864_609, change: 4_225_130, note: "Largest revenue variance from the 2025 adopted baseline.", scenarioQuestion: "For 2027, separate levy-supported recurring revenue from one-time or uncertain offsets."),
        .init(title: "Police - full-time uniform personnel", fund: "A01", kind: .expense, adopted2025: 13_534_000, tentative2026: 14_966_311, change: 1_432_311, note: "Largest expenditure variance in the operating baseline.", scenarioQuestion: "For 2027, reconcile authorized headcount, salary schedules, and overtime assumptions before setting the appropriation."),
        .init(title: "Police retirement", fund: "A01", kind: .expense, adopted2025: 5_541_809, tentative2026: 6_633_131, change: 1_091_322, note: "A payroll-related fringe benefit that should be reviewed with the salary base.", scenarioQuestion: "For 2027, carry pension cost as a recurring obligation tied to payroll, not as a discretionary add-on."),
        .init(title: "BAN interest expense", fund: "V01", kind: .expense, adopted2025: 940_000, tentative2026: 1_233_750, change: 293_750, note: "Debt-service variance should be tied to the AFR's $21.975M of BANs maturing in 2026.", scenarioQuestion: "For 2027, distinguish principal, interest, renewal risk, and new borrowing before treating capital plans as affordable."),
        .init(title: "Hospitalization - non-uniform personnel", fund: "A01", kind: .expense, adopted2025: 5_134_705, tentative2026: 5_503_333, change: 368_628, note: "Recurring fringe-benefit pressure that belongs in the operating cost base.", scenarioQuestion: "For 2027, document the health-insurance trend rate and employee-count assumption."),
        .init(title: "Tax on adult-use cannabis", fund: "A01", kind: .revenue, adopted2025: 0, tentative2026: 400_000, change: 400_000, note: "The 2025 AFR reports $801K of actual cannabis tax receipts, above the 2026 tentative estimate.", scenarioQuestion: "For 2027, use collection history but avoid building permanent spending on a short revenue track record."),
        .init(title: "Sewer rents", fund: "ES1", kind: .revenue, adopted2025: 4_401_196, tentative2026: 4_838_525, change: 437_329, note: "Enterprise-fund revenue variance should now be reviewed against the Sewer Fund's $1.09M 2025 operating loss.", scenarioQuestion: "For 2027, keep sewer rents in the enterprise-fund model and explain whether rates cover recurring costs."),
        .init(title: "Metered water sales", fund: "EW1", kind: .revenue, adopted2025: 5_500_000, tentative2026: 5_804_577, change: 304_577, note: "Utility operating revenue that should be tested against consumption and rate assumptions.", scenarioQuestion: "For 2027, model water sales with utility demand and rate assumptions, not townwide tax assumptions.")
    ]

    static let requestGaps: [SupplementRequestGapLine] = [
        .init(title: "IT personal services", fund: "A01", request: 722_279, tentative: 580_090, note: "Material request-to-tentative variance; requires a staffing, vacancy, or reclassification explanation."),
        .init(title: "Ambulance vehicles", fund: "SM1", request: 205_000, tentative: 85_000, note: "Capital outlay reduction; verify whether the deferred amount remains a future obligation."),
        .init(title: "MTA tax - uniform personnel", fund: "A01", request: 119_661, tentative: 0, note: "Zero appropriation should be supported by an accounting classification or statutory-basis explanation."),
        .init(title: "MTA tax - non-uniform personnel", fund: "A01", request: 99_478, tentative: 0, note: "Zero appropriation should be reconciled to payroll-tax treatment before the baseline is accepted."),
        .init(title: "Police sick buy-back", fund: "A01", request: 195_000, tentative: 116_900, note: "Compensated-absence exposure; compare the appropriation with contract terms and separation history."),
        .init(title: "Senior services vehicles", fund: "A01", request: 51_000, tentative: 0, note: "Capital request removed from the tentative plan; disclose whether replacement is deferred or funded elsewhere."),
        .init(title: "Assessment personal services", fund: "A01", request: 559_485, tentative: 509_088, note: "Personal-services variance should be reconciled to authorized positions and assessment-cycle workload."),
        .init(title: "Building safety inspection personal services", fund: "A01", request: 518_233, tentative: 477_764, note: "Personal-services variance should be tied to permit volume, inspection backlog, and authorized staffing.")
    ]

    static let departmentLines: [SupplementDepartmentLine] = [
        .init(code: "3120", title: "Police", tentative: 22_388_906, change: 1_907_028, note: "Material General Fund operating function; review salary, overtime, and equipment subaccounts together."),
        .init(code: "9015", title: "Police retirement", tentative: 6_633_131, change: 1_091_322, note: "Fringe-benefit function that should reconcile to payroll and pension-rate assumptions."),
        .init(code: "9060", title: "Hospitalization", tentative: 5_503_333, change: 368_628, note: "Recurring benefit appropriation; review trend rate, enrollment, and plan assumptions."),
        .init(code: "8160", title: "Refuse and garbage", tentative: 5_097_076, change: 84_644, note: "Large service function; variance review should separate contract cost from disposal or volume effects."),
        .init(code: "9710", title: "Serial bond payments", tentative: 4_629_400, change: 111_800, note: "Debt-service function; reconcile to amortization schedules and bond resolutions."),
        .init(code: "5110", title: "Highway maintenance", tentative: 3_553_226, change: 36_636, note: "Core infrastructure function; compare operating baseline with equipment and capital plans."),
        .init(code: "8320", title: "Water source of supply", tentative: 3_491_700, change: 94_000, note: "Enterprise-fund operating function; review within utility rates and user-charge assumptions."),
        .init(code: "9901", title: "Transfers to other funds", tentative: 3_274_950, change: 242_850, note: "Interfund transfer function; preserve the trail between funds to avoid double counting.")
    ]

    static let scenarioActions: [SupplementScenarioAction] = [
        .init(title: "Set the recurring appropriation base", amount: 1_432_311, direction: .expense, action: "Carry the police personnel variance into the 2027 base budget unless management documents a recurring offset, vacancy assumption, or staffing change.", labControl: "Recurring operating pressure"),
        .init(title: "Reconcile payroll-related fringe benefits", amount: 1_459_950, direction: .expense, action: "Tie pension and hospitalization estimates to payroll, headcount, enrollment, and published rate assumptions so recurring costs are not understated.", labControl: "Payroll and benefits"),
        .init(title: "Test early retirement payback", amount: 461_000, direction: .revenue, action: "Use the planning case as recurring savings only after incentive payments, accrued leave payouts, backfill, and overtime risk are shown separately.", labControl: "Workforce savings"),
        .init(title: "Pair surplus with levy reduction", amount: 1_660_000, direction: .revenue, action: "Use the $5M surplus for one-time parks, vehicles, and software, then reduce the 2027 levy only by recurring savings and recurring revenue offsets.", labControl: "Tax reduction"),
        .init(title: "Apply conservative revenue recognition", amount: 400_000, direction: .revenue, action: "Treat new cannabis revenue as provisional until actual receipts support the estimate; avoid using uncertain revenue for permanent spending.", labControl: "Recurring revenue"),
        .init(title: "Separate capital from operations", amount: 336_000, direction: .expense, action: "Keep vehicle and fleet decisions in capital planning or fund-balance analysis instead of treating one-time outlays as recurring operating capacity.", labControl: "Capital and reserves"),
        .init(title: "Document material request variances", amount: 578_574, direction: .expense, action: "Require written budget notes for material request-to-tentative differences before using the tentative amount as the 2027 starting baseline.", labControl: "Budget notes")
    ]
}

@MainActor
struct BudgetSupplementExplorerView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedPanel: SupplementExplorerPanel = .summary
    @State private var searchText = ""

    private var isCompact: Bool {
        horizontalSizeClass == .compact || dynamicTypeSize.isAccessibilitySize
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: isCompact ? 1 : 2)
    }

    private var filteredDepartmentLines: [SupplementDepartmentLine] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard query.isEmpty == false else { return BudgetSupplementExplorerData.departmentLines }
        return BudgetSupplementExplorerData.departmentLines.filter {
            $0.title.lowercased().contains(query) || $0.code.contains(query)
        }
    }

    var body: some View {
        List {
            Section {
                header
                panelPicker
            }

            switch selectedPanel {
            case .summary:
                summaryPanel
            case .actuals:
                actualsPanel
            case .retirement:
                retirementPanel
            case .levyReduction:
                levyReductionPanel
            case .biggestChanges:
                biggestChangesPanel
            case .requestCuts:
                requestGapPanel
            case .departments:
                departmentsPanel
            case .scenarioBridge:
                scenarioBridgePanel
            }
        }
        .navigationTitle("Budget Supplement Explorer")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search departments or codes")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("2026 supplement to 2027 choices", systemImage: "doc.text.magnifyingglass")
                .font(.headline)
                .foregroundStyle(RiverheadTheme.brandNavy)

            Text("This view reads the official 2026 Budget Supplement alongside the 2025 Annual Financial Report: actual results, fund balance, material variances, request-to-tentative differences, and assumptions that should be documented before the 2027 base budget is set.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Link(destination: BudgetSupplementExplorerData.officialURL) {
                Label("Open official supplement PDF", systemImage: "link")
                    .font(.caption.weight(.semibold))
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var panelPicker: some View {
        if isCompact {
            Picker("Explorer panel", selection: $selectedPanel) {
                ForEach(SupplementExplorerPanel.allCases) { panel in
                    Text(panel.title).tag(panel)
                }
            }
            .pickerStyle(.menu)
        } else {
            Picker("Explorer panel", selection: $selectedPanel) {
                ForEach(SupplementExplorerPanel.allCases) { panel in
                    Text(panel.title).tag(panel)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var summaryPanel: some View {
        Group {
            Section("Quick Read") {
                quickReadRow("Tracked funds", value: "\(BudgetSupplementExplorerData.fundSummaries.count)", tint: RiverheadTheme.brandSky)
                quickReadRow("2025 General Fund actual result", value: currency(5_003_327), tint: RiverheadTheme.brandMint)
                quickReadRow("2025 unassigned General Fund balance", value: currency(29_671_084), tint: .green)
                quickReadRow("ERI planning-case annual savings", value: currency(461_000), tint: RiverheadTheme.brandSky)
                quickReadRow("Planning-case levy reduction", value: currency(BudgetSupplementExplorerData.planningLevyReductionTotal), tint: .green)
                quickReadRow("Largest General Fund revenue variance", value: currency(4_260_330), tint: .green)
                quickReadRow("General Fund tentative surplus", value: currency(167_742), tint: RiverheadTheme.brandMint)
            }

            Section("Fund Snapshot") {
                fundBalanceChart

                ForEach(BudgetSupplementExplorerData.fundSummaries) { fund in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(fund.fund) \(fund.name)")
                                    .font(.headline)
                                Text("Tentative revenue less tentative appropriations: \(currency(fund.balance))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(currency(fund.tentativeExpenditures))
                                .font(.subheadline.weight(.semibold))
                        }

                        HStack {
                            metricPill("Revenue change", value: fund.revenueChange, tint: .green)
                            metricPill("Expense change", value: fund.expenditureChange, tint: .orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var levyReductionPanel: some View {
        Group {
            Section("Use $5M Without Creating a 2028 Hole") {
                Text("The surplus plan separates one-time priorities from recurring levy reduction. Parks, vehicles, and software can use cash once; the 2027 tax levy should come down only by recurring savings or recurring revenue.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                surplusUseChart

                ForEach(BudgetSupplementExplorerData.surplusPriorityUses) { use in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(use.title)
                                .font(.headline)
                            Spacer()
                            Text(currency(use.amount))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RiverheadTheme.brandSky)
                        }
                        Text(use.note)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 5)
                }

                quickReadRow("One-time priority total", value: currency(BudgetSupplementExplorerData.surplusPriorityTotal), tint: RiverheadTheme.brandSky)
                quickReadRow(
                    BudgetSupplementExplorerData.surplusRemaining >= 0 ? "Remaining from $5M surplus" : "Amount over $5M surplus",
                    value: currency(abs(BudgetSupplementExplorerData.surplusRemaining)),
                    tint: BudgetSupplementExplorerData.surplusRemaining >= 0 ? .green : .orange
                )
            }

            Section("Recurring 2027 Levy Reduction") {
                levyReductionChart

                HStack {
                    metricBlock("Conservative cut", value: BudgetSupplementExplorerData.conservativeLevyReductionTotal, tint: .green)
                    metricBlock("Planning cut", value: BudgetSupplementExplorerData.planningLevyReductionTotal, tint: RiverheadTheme.brandMint)
                }

                ForEach(BudgetSupplementExplorerData.levyReductionOffsets) { offset in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(offset.title)
                                    .font(.headline)
                                Text(offset.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(currency(offset.planning))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.green)
                        }

                        ViewThatFits(in: .horizontal) {
                            HStack {
                                metricBlock("Conservative", value: offset.conservative, tint: .secondary)
                                metricBlock("Planning", value: offset.planning, tint: .green)
                            }
                            VStack(alignment: .leading) {
                                metricBlock("Conservative", value: offset.conservative, tint: .secondary)
                                metricBlock("Planning", value: offset.planning, tint: .green)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
            }

            Section("Guardrail") {
                Label("Do not use the $5M one-time surplus to pay recurring salaries, benefits, or routine operating lines. That lowers taxes once and creates a replacement problem the next year.", systemImage: "lock.shield")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var retirementPanel: some View {
        Group {
            Section("Early Retirement Incentive") {
                Text("This model estimates budget impact from retirements, lower-cost backfill, and one-time incentive costs. It is a planning screen, not an eligibility list; actual savings require age, service, title, accrued leave, and replacement decisions.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                earlyRetirementChart

                ForEach(BudgetSupplementExplorerData.earlyRetirementScenarios) { scenario in
                    earlyRetirementScenarioRow(scenario)
                }
            }

            Section("Model Assumptions") {
                ForEach(BudgetSupplementExplorerData.earlyRetirementAssumptions, id: \.self) { assumption in
                    Label(assumption, systemImage: "checkmark.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Budget Rule") {
                Label("Do not count incentive savings as recurring until the first-year payout, accrued-leave liability, backfill plan, and overtime exposure are shown separately.", systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var actualsPanel: some View {
        Group {
            Section("2025 Actual Results") {
                Text("The Annual Financial Report adds the reality check: it shows what actually happened in 2025 before the 2026 budget becomes the launch point for 2027 decisions.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                annualFinancialResultsChart

                ForEach(BudgetSupplementExplorerData.annualFinancialResults.sorted { abs($0.operatingResult) > abs($1.operatingResult) }) { result in
                    annualFinancialResultRow(result)
                }
            }

            Section("Watch Items") {
                ForEach(BudgetSupplementExplorerData.annualFinancialWatchItems) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.systemImage)
                            .foregroundStyle(item.tint)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(item.title)
                                    .font(.headline)
                                Spacer()
                                Text(item.value)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(item.tint)
                            }

                            Text(item.note)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        }
    }

    private var biggestChangesPanel: some View {
        Group {
            Section("Material Variances") {
                changeBarChart

                ForEach(BudgetSupplementExplorerData.biggestChanges.sorted { abs($0.change) > abs($1.change) }) { line in
                    changeLineRow(line)
                }
            }
        }
    }

    private var requestGapPanel: some View {
        Group {
            Section("Department Request vs Tentative") {
                Text("These lines show material differences between the department request and the tentative appropriation. A difference is not automatically good or bad; it should be supported by a budget note, accounting classification, service-level decision, or funding-source explanation.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ForEach(BudgetSupplementExplorerData.requestGaps.sorted { $0.gap > $1.gap }) { line in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(line.title)
                                    .font(.headline)
                                Text(line.fund)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(currency(line.gap))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.red)
                        }

                        ViewThatFits(in: .horizontal) {
                            HStack {
                                metricBlock("Requested", value: line.request, tint: .blue)
                                metricBlock("Tentative", value: line.tentative, tint: .orange)
                            }
                            VStack(alignment: .leading) {
                                metricBlock("Requested", value: line.request, tint: .blue)
                                metricBlock("Tentative", value: line.tentative, tint: .orange)
                            }
                        }

                        Text(line.note)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
    }

    private var departmentsPanel: some View {
        Group {
            Section("Department Drilldown") {
                departmentChart

                ForEach(filteredDepartmentLines.sorted { $0.tentative > $1.tentative }) { line in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(line.title)
                                    .font(.headline)
                                Text("Function \(line.code)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(currency(line.tentative))
                                .font(.subheadline.weight(.semibold))
                        }

                        HStack {
                            Text("Change from 2025")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(currency(line.change))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(line.change >= 0 ? .orange : .green)
                        }

                        Text(line.note)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
    }

    private var scenarioBridgePanel: some View {
        Group {
            Section("Convert 2026 Variances Into 2027 Controls") {
                Text("The accounting test is simple: recurring expenditures should be supported by recurring revenues, one-time resources should be used for one-time needs, and material variances should have a traceable explanation before they become the next year's baseline.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ForEach(BudgetSupplementExplorerData.scenarioActions) { action in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: action.direction == .expense ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                                .foregroundStyle(action.direction.tint)
                                .frame(width: 26)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(action.title)
                                    .font(.headline)
                                Text(action.labControl)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(RiverheadTheme.brandNavy)
                            }

                            Spacer()

                            Text(currency(action.amount))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(action.direction.tint)
                        }

                        Text(action.action)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 5)
                }

                NavigationLink {
                    Budget2027LabView()
                } label: {
                    Label("Open 2027 Budget Lab", systemImage: "slider.horizontal.below.sun.max.fill")
                }

                NavigationLink {
                    BudgetSimulator2027View()
                } label: {
                    Label("Open 2027 Budget Simulator", systemImage: "function")
                }
            }
        }
    }

    private var fundBalanceChart: some View {
        Chart(BudgetSupplementExplorerData.fundSummaries) { fund in
            BarMark(
                x: .value("Balance", fund.balance),
                y: .value("Fund", fund.fund)
            )
            .foregroundStyle(fund.balance >= 0 ? RiverheadTheme.brandMint : RiverheadTheme.brandCoral)
            .annotation(position: .trailing) {
                Text(shortCurrency(fund.balance))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 190)
        .chartXAxisLabel("Revenue minus expenditure")
    }

    private var changeBarChart: some View {
        Chart(Array(BudgetSupplementExplorerData.biggestChanges.prefix(6))) { line in
            BarMark(
                x: .value("Change", abs(line.change)),
                y: .value("Line", line.title)
            )
            .foregroundStyle(line.kind.tint)
            .annotation(position: .trailing) {
                Text(shortCurrency(line.change))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 230)
        .chartXAxisLabel("Absolute dollar change")
    }

    private var annualFinancialResultsChart: some View {
        Chart(BudgetSupplementExplorerData.annualFinancialResults) { result in
            BarMark(
                x: .value("2025 actual result", result.operatingResult),
                y: .value("Fund", result.fund)
            )
            .foregroundStyle(result.operatingResult >= 0 ? RiverheadTheme.brandMint : RiverheadTheme.brandCoral)
            .annotation(position: .trailing) {
                Text(shortCurrency(result.operatingResult))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 210)
        .chartXAxisLabel("Revenues and sources minus expenditures and uses")
    }

    private var earlyRetirementChart: some View {
        Chart(BudgetSupplementExplorerData.earlyRetirementScenarios) { scenario in
            BarMark(
                x: .value("Annual recurring savings", scenario.annualSavings),
                y: .value("Scenario", scenario.title)
            )
            .foregroundStyle(RiverheadTheme.brandMint)
            .annotation(position: .trailing) {
                Text(shortCurrency(scenario.annualSavings))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 190)
        .chartXAxisLabel("Estimated annual recurring savings")
    }

    private var surplusUseChart: some View {
        Chart(BudgetSupplementExplorerData.surplusPriorityUses) { use in
            BarMark(
                x: .value("One-time use", use.amount),
                y: .value("Priority", use.title)
            )
            .foregroundStyle(RiverheadTheme.brandSky)
            .annotation(position: .trailing) {
                Text(shortCurrency(use.amount))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 190)
        .chartXAxisLabel("One-time surplus use")
    }

    private var levyReductionChart: some View {
        Chart(BudgetSupplementExplorerData.levyReductionOffsets) { offset in
            BarMark(
                x: .value("Planning levy offset", offset.planning),
                y: .value("Offset", offset.title)
            )
            .foregroundStyle(RiverheadTheme.brandMint)
            .annotation(position: .trailing) {
                Text(shortCurrency(offset.planning))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 230)
        .chartXAxisLabel("Recurring levy reduction capacity")
    }

    private var departmentChart: some View {
        Chart(filteredDepartmentLines.prefix(6)) { line in
            BarMark(
                x: .value("Tentative", line.tentative),
                y: .value("Department", line.title)
            )
            .foregroundStyle(RiverheadTheme.brandSky)
            .annotation(position: .trailing) {
                Text(shortCurrency(line.tentative))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 230)
        .chartXAxisLabel("2026 tentative budget")
    }

    private func changeLineRow(_ line: SupplementChangeLine) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(line.title)
                        .font(.headline)
                    Text("\(line.fund) • \(line.kind.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(currency(line.change))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(line.kind.tint)
            }

            ViewThatFits(in: .horizontal) {
                HStack {
                    metricBlock("2025 adopted", value: line.adopted2025, tint: .secondary)
                    metricBlock("2026 tentative", value: line.tentative2026, tint: line.kind.tint)
                }
                VStack(alignment: .leading) {
                    metricBlock("2025 adopted", value: line.adopted2025, tint: .secondary)
                    metricBlock("2026 tentative", value: line.tentative2026, tint: line.kind.tint)
                }
            }

            Text(line.note)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Label(line.scenarioQuestion, systemImage: "questionmark.bubble")
                .font(.caption)
                .foregroundStyle(RiverheadTheme.brandNavy)
        }
        .padding(.vertical, 5)
    }

    private func annualFinancialResultRow(_ result: AnnualFinancialFundResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.name)
                        .font(.headline)
                    Text("Fund \(result.fund) • \(BudgetSupplementExplorerData.annualFinancialReportTitle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(currency(result.operatingResult))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(result.operatingResult >= 0 ? .green : .orange)
            }

            ViewThatFits(in: .horizontal) {
                HStack {
                    metricBlock("Revenues and sources", value: result.revenuesAndSources, tint: .green)
                    metricBlock("Expenditures and uses", value: result.expendituresAndUses, tint: .orange)
                    metricBlock("Ending balance", value: result.endingBalance, tint: RiverheadTheme.brandSky)
                }
                VStack(alignment: .leading) {
                    metricBlock("Revenues and sources", value: result.revenuesAndSources, tint: .green)
                    metricBlock("Expenditures and uses", value: result.expendituresAndUses, tint: .orange)
                    metricBlock("Ending balance", value: result.endingBalance, tint: RiverheadTheme.brandSky)
                }
            }

            Text(result.note)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 5)
    }

    private func earlyRetirementScenarioRow(_ scenario: EarlyRetirementScenario) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(scenario.title)
                        .font(.headline)
                    Text("\(scenario.retirements) retirements • \(replacementText(scenario.replacementRate))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(currency(scenario.annualSavings))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
            }

            ViewThatFits(in: .horizontal) {
                HStack {
                    metricBlock("Annual savings", value: scenario.annualSavings, tint: .green)
                    metricBlock("One-time cost", value: scenario.oneTimeCost, tint: .orange)
                    metricBlock("First-year net", value: scenario.firstYearNet, tint: scenario.firstYearNet >= 0 ? .green : .orange)
                }
                VStack(alignment: .leading) {
                    metricBlock("Annual savings", value: scenario.annualSavings, tint: .green)
                    metricBlock("One-time cost", value: scenario.oneTimeCost, tint: .orange)
                    metricBlock("First-year net", value: scenario.firstYearNet, tint: scenario.firstYearNet >= 0 ? .green : .orange)
                }
            }

            HStack {
                Text("Estimated payback")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(String(format: "%.1f", scenario.breakEvenYears)) years")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.brandNavy)
            }

            Text(scenario.note)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 5)
    }

    private func quickReadRow(_ title: String, value: String, tint: Color) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(tint)
        }
    }

    private func metricPill(_ title: String, value: Double, tint: Color) -> some View {
        Text("\(title): \(currency(value))")
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.10))
            .clipShape(Capsule())
    }

    private func metricBlock(_ title: String, value: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(currency(value))
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private func shortCurrency(_ value: Double) -> String {
        let sign = value < 0 ? "-" : ""
        let absolute = abs(value)
        if absolute >= 1_000_000 {
            return "\(sign)$\(String(format: "%.1f", absolute / 1_000_000))M"
        }
        if absolute >= 1_000 {
            return "\(sign)$\(String(format: "%.0f", absolute / 1_000))K"
        }
        return currency(value)
    }

    private func replacementText(_ rate: Double) -> String {
        if rate == 0 {
            return "positions eliminated"
        }
        return "\(Int(rate * 100))% replacement cost"
    }
}

#Preview {
    NavigationStack {
        BudgetSupplementExplorerView()
            .environment(RBBudgetStore())
    }
}
