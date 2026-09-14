//
//  ProgramBudgetData.swift
//  Riverhead NY Budget App
//
//  The program budget: the 2026 Adopted Budget regrouped out of funds and into
//  the seven services New York's Uniform System of Accounts says the Town
//  performs — with pension and health insurance pushed back onto the programs
//  whose staff earned them, so Police costs what Police actually costs.
//
//  Loaded from bundled programs.json, which the web app publishes at
//  /data/programs.json expressly as a contract for the native clients
//  (web/app/data/programs.json/route.ts). Nothing here re-derives an allocation.
//  The regrouping, the uniformed/non-uniformed benefit split, the revenue
//  matching and the reconciliation all happen once, on the web side, from the
//  same account-level extract — which is the only way iOS, Android and the
//  website can be prevented from quietly disagreeing about what a service costs.
//
//  Swift 6 / iOS 17+
//

import Foundation

/// A named official document, so any figure on screen can be traced back to the
/// page it came from.
struct ProgramBudgetSource: Decodable {
    let title: String
    let url: String
    let detail: String?

    var link: URL? { URL(string: url) }
}

struct ProgramBudgetCensus: Decodable {
    let dataset: String
    let source: ProgramBudgetSource
    let population: Int
    let households: Int
    /// The Census margin of error on the household count. Per-household figures
    /// are approximate and the app says so rather than implying precision.
    let householdsMoe: Int
    let medianHouseholdIncome: Int
}

/// One budget department inside a program, at the Town's own account code.
struct ProgramBudgetDepartment: Decodable, Identifiable {
    let fund: String
    let code: String
    let name: String
    let amount: Double

    var id: String { "\(fund)-\(code)" }
}

/// One revenue line the Town codes to this program's function group.
///
/// Deliberately not Identifiable: the name is not an identity. Riverhead has two
/// sewer districts and both of their lines are called "Sewer Rents", so anything
/// keyed on the name would merge two real accounts into one.
struct ProgramBudgetRevenue: Decodable {
    let name: String
    let amount: Double
}

struct ProgramBudgetProgram: Decodable, Identifiable {
    /// The State's function digit — "3" is Public Safety, "8" is Home &
    /// Community Services. Riverhead codes to it; this app did not assign it.
    let key: String
    let name: String
    /// One line a resident can read without a finance background.
    let plain: String
    /// What the Town actually does under this heading.
    let narrative: String
    /// Concrete services, drawn from the departments carrying the spending.
    let buys: [String]
    /// The departments' own appropriations.
    let direct: Double
    /// Pension, health insurance, FICA and workers' comp pushed back here.
    let benefits: Double
    let fullCost: Double
    /// Fees paid by the people who use the service — not taxes.
    let earned: Double
    /// What general revenue has to carry.
    let net: Double
    let recoveryPct: Double
    let netPerResident: Double
    let netPerHousehold: Double
    /// Bodies on the payroll, not full-time equivalents.
    let staff: Int
    let departments: [ProgramBudgetDepartment]
    let topRevenues: [ProgramBudgetRevenue]

    var id: String { key }

    /// How the State's own chart of accounts names this block of codes.
    var functionLabel: String { "NY function \(key)000s" }
}

struct ProgramBudgetTotals: Decodable {
    let direct: Double
    let benefits: Double
    let fullCost: Double
    let earned: Double
    let net: Double
    let staff: Int
    let debtService: Double
    let contingency: Double
    /// One Town fund paying another. Counting it would double-count real
    /// dollars, so it sits outside the program totals and is reported on its own.
    let interfundTransfers: Double
    /// Revenue that belongs to no single program — property and sales tax,
    /// PILOTs, mortgage tax, state aid.
    let townwideRevenue: Double
    /// Programs + debt service + contingency. Excludes transfers by design.
    let grandTotal: Double
    let appropriations: Double

    var recoveryPct: Double { fullCost > 0 ? earned / fullCost * 100 : 0 }
}

struct ProgramBudgetPerResident: Decodable {
    let programs: Double
    let debtService: Double
    let everything: Double
}

struct ProgramBudgetPerHousehold: Decodable {
    let programs: Double
    let debtService: Double
    let everything: Double
    let shareOfMedianIncome: Double
}

/// Programs + debt + contingency + transfers, checked against the Town's total
/// adopted appropriations. Rearranging a budget is exactly where a transparency
/// tool can mislead without meaning to, so the check is shown, not assumed.
struct ProgramBudgetReconciliation: Decodable {
    let computed: Double
    let appropriations: Double
    let variance: Double

    /// True when the regrouping neither lost nor invented a dollar.
    var balances: Bool { abs(variance) < 0.5 }
}

struct ProgramBudgetNote: Decodable, Identifiable {
    let title: String
    let body: String

    var id: String { title }
}

struct ProgramBudgetDiagnostics: Decodable {
    /// Payroll department names the ETL could not map to a function. Empty is
    /// the expected state; anything here means a headcount is unaccounted for.
    let unmappedPayrollDepartments: [String]
}

struct ProgramBudget: Decodable {
    let schemaVersion: Int
    let source: ProgramBudgetSource
    /// The payroll year the staff counts come from.
    let payrollYear: Int
    let census: ProgramBudgetCensus
    let programs: [ProgramBudgetProgram]
    let totals: ProgramBudgetTotals
    let perResident: ProgramBudgetPerResident
    let perHousehold: ProgramBudgetPerHousehold
    let reconciliation: ProgramBudgetReconciliation
    /// Every decision that moved a dollar, written down.
    let method: [ProgramBudgetNote]
    /// The honest limit of the exercise.
    let notCovered: ProgramBudgetNote
    let diagnostics: ProgramBudgetDiagnostics
}

enum ProgramBudgetData {
    /// The contract version this app was written against. If the web side ever
    /// bumps it, the app should say the data is newer than the app rather than
    /// render fields it only half understands.
    static let supportedSchemaVersion = 1

    static let current: ProgramBudget? = load(from: .main)

    /// The bundle is a parameter so the tests can read the same file out of
    /// whichever bundle they happen to run from.
    static func load(from bundle: Bundle) -> ProgramBudget? {
        guard let url = bundle.url(forResource: "programs", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode(ProgramBudget.self, from: data)
    }

    /// True when the bundled file was generated by a newer contract than this
    /// build knows about.
    static var isNewerThanApp: Bool {
        guard let current else { return false }
        return current.schemaVersion > supportedSchemaVersion
    }
}
