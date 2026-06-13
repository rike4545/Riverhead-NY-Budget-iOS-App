import Foundation

enum DepartmentBudgetCategory: String, CaseIterable, Identifiable {
    case governance = "Governance"
    case publicSafety = "Public Safety"
    case services = "Resident Services"
    case infrastructure = "Infrastructure"
    case utilities = "Utilities"

    var id: String { rawValue }
}

struct DepartmentBudgetRecord: Identifiable, Hashable {
    let budgetDepartment: String
    let staffDepartment: String?
    let category: DepartmentBudgetCategory
    let fundCode: String
    let positions: Int?
    let salaryBase: Double?
    let adoptedTotal: Double
    let keyTitles: [String]
    let note: String?

    var id: String { "\(fundCode)-\(budgetDepartment)" }

    var otherExpense: Double? {
        guard let salaryBase else { return nil }
        return adoptedTotal - salaryBase
    }

    var personnelShare: Double? {
        guard let salaryBase, adoptedTotal > 0 else { return nil }
        return salaryBase / adoptedTotal
    }
}

enum RebalanceDirection: String, CaseIterable, Identifiable {
    case tighten = "Tighten"
    case strengthen = "Strengthen"

    var id: String { rawValue }
}

struct RebalanceRecommendation: Identifiable, Hashable {
    let fundFunction: String
    let account: String
    let direction: RebalanceDirection
    let adopted2025: Double
    let adopted2026: Double
    let changeLabel: String?
    let rationale: String

    var id: String { "\(fundFunction)-\(account)" }

    var change: Double { adopted2026 - adopted2025 }

    init(
        fundFunction: String,
        account: String,
        direction: RebalanceDirection,
        adopted2025: Double,
        adopted2026: Double,
        changeLabel: String? = nil,
        rationale: String
    ) {
        self.fundFunction = fundFunction
        self.account = account
        self.direction = direction
        self.adopted2025 = adopted2025
        self.adopted2026 = adopted2026
        self.changeLabel = changeLabel
        self.rationale = rationale
    }
}

enum DepartmentBudgetLensData {
    static let departmentRecords: [DepartmentBudgetRecord] = [
        .init(
            budgetDepartment: "Town Board / Legislature",
            staffDepartment: nil,
            category: .governance,
            fundCode: "A01-1010",
            positions: nil,
            salaryBase: nil,
            adoptedTotal: 295_301,
            keyTitles: [],
            note: "Budget function total from the 2026 adopted budget. Staffing was not separated cleanly in the payroll summary."
        ),
        .init(
            budgetDepartment: "Justice Court",
            staffDepartment: "JUSTICE COURT",
            category: .governance,
            fundCode: "A01-1110",
            positions: 12,
            salaryBase: 710_357.98,
            adoptedTotal: 907_513,
            keyTitles: ["Court Officer (5)", "Justice Court Clerk (2)", "Senior Justice Court Clerk (2)"],
            note: "Court detail includes interpreters, stenographic services, training, and office support above the salary base."
        ),
        .init(
            budgetDepartment: "Supervisor's Office",
            staffDepartment: "SUPERVISOR'S OFFICE",
            category: .governance,
            fundCode: "A01-1220",
            positions: 3,
            salaryBase: 247_790.94,
            adoptedTotal: 407_084,
            keyTitles: ["Town Budget Officer (1)", "Secretary (1)", "Deputy Town Supervisor (1)"],
            note: "Budget line is materially above pure payroll because of part-time support and office operating costs."
        ),
        .init(
            budgetDepartment: "Finance",
            staffDepartment: "FINANCE",
            category: .governance,
            fundCode: "A01-1310",
            positions: 7,
            salaryBase: 655_281.74,
            adoptedTotal: 977_942,
            keyTitles: ["Chief Accountant (1)", "Principal Accountant (1)", "Payroll Supervisor (1)"],
            note: "Professional services and accounting support make this one of the bigger non-salary governance functions."
        ),
        .init(
            budgetDepartment: "Tax Receiver",
            staffDepartment: "TAX RECEIVER'S OFFICE",
            category: .governance,
            fundCode: "A01-1330",
            positions: 3,
            salaryBase: 162_205.21,
            adoptedTotal: 261_537,
            keyTitles: ["Deputy Tax Receiver (1)", "Account Clerk (1)", "Office Assistant (1)"],
            note: "Postage moved sharply higher in the adopted budget and is called out separately in the rebalance view."
        ),
        .init(
            budgetDepartment: "Purchasing",
            staffDepartment: "PURCHASING",
            category: .governance,
            fundCode: "A01-1345",
            positions: 2,
            salaryBase: 165_093.93,
            adoptedTotal: 221_368,
            keyTitles: ["Senior Purchasing Agent (1)", "Purchasing Technician (1)"],
            note: "Mostly a payroll-driven office with modest equipment and postage support."
        ),
        .init(
            budgetDepartment: "Assessors",
            staffDepartment: "ASSESSORS",
            category: .governance,
            fundCode: "A01-1355",
            positions: 3,
            salaryBase: 190_431.20,
            adoptedTotal: 563_314,
            keyTitles: ["Senior Assessment Clerk (1)", "Assessment Clerk (1)", "Account Clerk (1)"],
            note: "The function total includes board stipends and assessment operating support, so the gap above salary is unusually large."
        ),
        .init(
            budgetDepartment: "Town Clerk",
            staffDepartment: "TOWN CLERK",
            category: .governance,
            fundCode: "A01-1410",
            positions: 3,
            salaryBase: 181_579.36,
            adoptedTotal: 307_219,
            keyTitles: ["Deputy Town Clerk (1)", "Senior Account Clerk (1)", "Clerk-Spanish Speaking (1)"],
            note: "Town Clerk operating costs stay fairly contained relative to total spending."
        ),
        .init(
            budgetDepartment: "Town Attorney",
            staffDepartment: "TOWN ATTORNEY",
            category: .governance,
            fundCode: "A01-1420",
            positions: 16,
            salaryBase: 1_594_542.10,
            adoptedTotal: 1_429_097,
            keyTitles: ["Deputy Town Attorney (3)", "Paralegal (2)", "Fire Marshal I (2)"],
            note: "Action required: 16 mapped positions carry a $1.594M salary base against the $1.429M function 1420 adopted total, a roughly $165K overage. Confirm whether fire marshal and code-compliance titles belong under functions 3625/3620, or correct the staffing-to-budget crosswalk."
        ),
        .init(
            budgetDepartment: "Human Resources",
            staffDepartment: "HUMAN RESOURCES",
            category: .governance,
            fundCode: "A01-1430",
            positions: 2,
            salaryBase: 167_583.29,
            adoptedTotal: 217_834,
            keyTitles: ["Town Personnel Officer (1)", "Personnel Assistant (1)"],
            note: "Small office, but it carries recurring EAP and professional support contracts."
        ),
        .init(
            budgetDepartment: "Engineering",
            staffDepartment: "ENGINEERING",
            category: .infrastructure,
            fundCode: "A01-1440",
            positions: 5,
            salaryBase: 537_883.80,
            adoptedTotal: 638_674,
            keyTitles: ["Town Engineer (2)", "Junior Civil Engineer (1)", "Administrative Assistant (1)"],
            note: "A relatively balanced function with a visible but not excessive contractual layer."
        ),
        .init(
            budgetDepartment: "Buildings & Grounds",
            staffDepartment: "BUILDINGS & GROUNDS",
            category: .infrastructure,
            fundCode: "A01-1625",
            positions: 18,
            salaryBase: 1_250_421.89,
            adoptedTotal: 2_239_916,
            keyTitles: ["Maintenance Mechanic II (7)", "Maintenance Mechanic III (3)", "Maintenance Mechanic IV (2)"],
            note: "Large non-salary footprint driven by vehicles, equipment, maintenance, and grounds support."
        ),
        .init(
            budgetDepartment: "Police",
            staffDepartment: "POLICE",
            category: .publicSafety,
            fundCode: "A01-3120",
            positions: 92,
            salaryBase: 12_929_775.95,
            adoptedTotal: 22_388_906,
            keyTitles: ["Police Officer (77)", "Sergeant (8)", "Lieutenant (3)"],
            note: "Largest matched operating function in the General Fund. Overtime, holiday pay, vehicle support, and buy-backs are major drivers."
        ),
        .init(
            budgetDepartment: "Juvenile Aid Bureau",
            staffDepartment: "JUVENILE AID BUREAU",
            category: .publicSafety,
            fundCode: "A01-3125",
            positions: 2,
            salaryBase: 148_867.32,
            adoptedTotal: 160_841,
            keyTitles: ["Youth Counselor (1)", "Account Clerk (1)"],
            note: "One of the tighter budget matches between payroll and adopted total."
        ),
        .init(
            budgetDepartment: "Building Safety Inspection",
            staffDepartment: "BUILDING",
            category: .services,
            fundCode: "A01-3620",
            positions: 7,
            salaryBase: 483_273.09,
            adoptedTotal: 521_209,
            keyTitles: ["Office Assistant (2)", "Building Inspector (1)", "Electrical Inspector (1)"],
            note: "This is a very lean department budget relative to the field workload and is one of the better candidates for targeted strengthening."
        ),
        .init(
            budgetDepartment: "Code Enforcement",
            staffDepartment: nil,
            category: .services,
            fundCode: "A01-3625",
            positions: nil,
            salaryBase: nil,
            adoptedTotal: 671_254,
            keyTitles: [],
            note: "Budget function is clear, but the staffing source does not separate code personnel cleanly from related legal and compliance titles."
        ),
        .init(
            budgetDepartment: "Highway Operations",
            staffDepartment: "HIGHWAY",
            category: .infrastructure,
            fundCode: "DA1-5110",
            positions: 36,
            salaryBase: 2_446_036.22,
            adoptedTotal: 3_553_226,
            keyTitles: ["Automotive Equipment Operator (17)", "Construction Equipment Operator (8)", "Heavy Equipment Operator (5)"],
            note: "Highway operations are payroll-heavy but still carry a large non-salary layer for resurfacing, fuel, rentals, and traffic work."
        ),
        .init(
            budgetDepartment: "Programs for the Aging",
            staffDepartment: nil,
            category: .services,
            fundCode: "A01-6772",
            positions: nil,
            salaryBase: nil,
            adoptedTotal: 1_049_154,
            keyTitles: [],
            note: "The adopted budget clearly shows the program total, but staffing is split across several senior program groups in the salary source."
        ),
        .init(
            budgetDepartment: "Recreation Administration",
            staffDepartment: nil,
            category: .services,
            fundCode: "A01-7020",
            positions: nil,
            salaryBase: nil,
            adoptedTotal: 630_273,
            keyTitles: [],
            note: "Use alongside the staffing summary's Recreation rows; this budget function is the closest overall operating match."
        ),
        .init(
            budgetDepartment: "Planning",
            staffDepartment: "PLANNING",
            category: .services,
            fundCode: "A01-8020",
            positions: 4,
            salaryBase: 394_737.10,
            adoptedTotal: 561_495,
            keyTitles: ["Senior Planner (2)", "Site Plan Reviewer (1)", "Planner (1)"],
            note: "Board stipends and consultant support make this more than a simple four-person payroll function."
        ),
        .init(
            budgetDepartment: "Sanitation / Yard Waste",
            staffDepartment: "SANITATION DEPARTMENT & YARD WASTE PROGRAM",
            category: .infrastructure,
            fundCode: "A01-8160",
            positions: 3,
            salaryBase: 183_756.78,
            adoptedTotal: 481_427,
            keyTitles: ["Automotive Equipment Operator (3)"],
            note: "The function total reflects disposal and vehicle support costs well beyond the small crew payroll base."
        ),
        .init(
            budgetDepartment: "Economic Development / CDA",
            staffDepartment: "ECONOMIC DEVELOPMENT",
            category: .services,
            fundCode: "A01-8686",
            positions: 7,
            salaryBase: 656_874.44,
            adoptedTotal: 771_565,
            keyTitles: ["Associate Administrator (1)", "Grants Analyst (1)", "Housing Inspector (1)"],
            note: "This function is useful for downtown, grant, and project-delivery tracking."
        ),
        .init(
            budgetDepartment: "Riverhead Sewer Operations",
            staffDepartment: "WASTEWATER DISTRICT",
            category: .utilities,
            fundCode: "ES1-8110/8130",
            positions: 17,
            salaryBase: 1_245_421,
            adoptedTotal: 3_251_515,
            keyTitles: ["Wastewater Treatment Plant Operator Trainee (3)", "Maintenance Mechanic II (2)", "Wastewater Dist. Super. (1)"],
            note: "Operations only. The full ES1 fund total is much higher because of depreciation, debt service, transfers, and fund-balance use."
        ),
        .init(
            budgetDepartment: "Water District Operations",
            staffDepartment: "WATER DISTRICT",
            category: .utilities,
            fundCode: "EW1-8310/8320",
            positions: 18,
            salaryBase: 1_489_474.47,
            adoptedTotal: 5_311_840,
            keyTitles: ["Water Treatment Plant Operator Type II B (3)", "Water Treatment Plant Operator Trainee (2)", "Maintenance Mechanic II (2)"],
            note: "Operations only. Water fund totals are much larger once debt, benefits, depreciation, and transfers are added back."
        )
    ]

    static let rebalancedSpending: [RebalanceRecommendation] = [
        .init(
            fundFunction: "A01 Police 3120",
            account: "Police holiday pay union",
            direction: .tighten,
            adopted2025: 752_400,
            adopted2026: 943_000,
            changeLabel: "+25.3%",
            rationale: "Tie to scheduling audit before normalizing as permanent baseline."
        ),
        .init(
            fundFunction: "A01 Police 3120",
            account: "Police health insurance buy-back",
            direction: .tighten,
            adopted2025: 389_000,
            adopted2026: 501_000,
            changeLabel: "+28.8%",
            rationale: "Active audit needed. Capture savings if participation declines."
        ),
        .init(
            fundFunction: "A01 Town Hall 1620",
            account: "Peconic Hockey electricity (new)",
            direction: .tighten,
            adopted2025: 0,
            adopted2026: 167_742,
            changeLabel: "New",
            rationale: "Absorbed into Town Hall utilities with no cost recovery plan."
        ),
        .init(
            fundFunction: "ES5 Scavenger Waste 8189",
            account: "ES5 scavenger waste disposal",
            direction: .tighten,
            adopted2025: 490_000,
            adopted2026: 677_000,
            changeLabel: "+38.2%",
            rationale: "Largest single enterprise fund jump. Benchmark disposal contracts."
        ),
        .init(
            fundFunction: "A01 Tax Collection 1330",
            account: "Tax collection postage",
            direction: .tighten,
            adopted2025: 1_500,
            adopted2026: 13_500,
            changeLabel: "+800%",
            rationale: "Review billing process changes vs. actual mailing volume."
        ),
        .init(
            fundFunction: "A01 Buildings & Grounds 1625",
            account: "Buildings & Grounds vehicles",
            direction: .strengthen,
            adopted2025: 132_000,
            adopted2026: 55_000,
            changeLabel: "-58.3%",
            rationale: "Fleet age risk. Deferred replacement compounds future repair costs."
        ),
        .init(
            fundFunction: "A01 Building 3620",
            account: "Building dept equipment",
            direction: .strengthen,
            adopted2025: 3_750,
            adopted2026: 0,
            changeLabel: "-100%",
            rationale: "Eliminated entirely. Field inspection department with zero equipment budget is a gap."
        ),
        .init(
            fundFunction: "A01 Programs for the Aging 6772",
            account: "Programs for the Aging vehicles",
            direction: .strengthen,
            adopted2025: 0,
            adopted2026: 0,
            changeLabel: "Denied",
            rationale: "Transportation-heavy senior program with no vehicle capital."
        ),
        .init(
            fundFunction: "A01 Buildings & Grounds 1625",
            account: "Road resurfacing & patching",
            direction: .strengthen,
            adopted2025: 25_000,
            adopted2026: 12_500,
            changeLabel: "-50%",
            rationale: "Deferred maintenance is costlier long-term. Restore if complaints are rising."
        )
    ]
}
