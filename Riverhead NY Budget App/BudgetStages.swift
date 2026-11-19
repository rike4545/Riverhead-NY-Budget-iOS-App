//
//  BudgetStages.swift
//  Riverhead NY Budget App
//
//  Every budget stage the Town has published (Tentative, Preliminary, Adopted),
//  fund by fund, from each book's own Summary page. This is the website's
//  web/public/data/history/budget-stages.json, copied into BudgetHistory/ by
//  the daily sync (shared-data/manifest.json), so the app's budget screens
//  follow the newest adopted budget without a code change.
//
//  The screens that describe "the budget" read `BudgetStages.current`, the
//  latest adopted year, and compare it with the adopted year before it.
//

import Foundation

struct BudgetStageSource: Decodable, Hashable, Sendable {
    let title: String
    let url: String
}

struct BudgetStageFund: Decodable, Hashable, Sendable {
    let name: String
    let appropriations: Double
    let revenues: Double?
    let fundBalance: Double?
    let levy: Double?
}

struct BudgetStageTotals: Decodable, Hashable, Sendable {
    let funds: Int
    let appropriations: Double
    let levy: Double
    let fundBalance: Double?
}

struct BudgetStageFundRate: Decodable, Hashable, Sendable {
    let rate: Double
    let priorRate: Double
}

/// The "Total Town Wide" rows: the General Fund, Highway and Street Lighting,
/// the three funds on every Town tax bill.
struct BudgetStageTownWide: Decodable, Hashable, Sendable {
    let appropriations: Double
    let priorAppropriations: Double
    let levy: Double
    let priorLevy: Double
    /// Dollars per $1,000 of assessed value.
    let rate: Double
    let priorRate: Double
    let fundRates: [String: BudgetStageFundRate]?
}

struct BudgetStageDoc: Decodable, Hashable, Sendable {
    let source: BudgetStageSource
    let funds: [String: BudgetStageFund]
    let totals: BudgetStageTotals
    let townWide: BudgetStageTownWide?

    /// Funds sorted by code ("A01", "A04", …).
    var fundsByCode: [(code: String, fund: BudgetStageFund)] {
        funds.keys.sorted().map { ($0, funds[$0]!) }
    }

    var generalFund: BudgetStageFund? { funds["A01"] }
}

struct BudgetStageTransition: Decodable, Hashable, Sendable {
    struct Change: Decodable, Hashable { let from: Double; let to: Double; let delta: Double }
    let year: Int
    let from: String
    let to: String
    let fundsChanged: Int
    let appropriations: Change
    let levy: Change
}

enum BudgetStage: String, CaseIterable, Sendable {
    case tentative, preliminary, adopted

    var label: String {
        switch self {
        case .tentative: return "Tentative"
        case .preliminary: return "Preliminary"
        case .adopted: return "Adopted"
        }
    }
}

struct BudgetStagesFile: Decodable, Sendable {
    let years: [String: [String: BudgetStageDoc]]
    let transitions: [BudgetStageTransition]
}

enum BudgetStages {
    /// The bundled file, decoded once. Nil only if the bundle lacks it or it no longer decodes.
    static let file: BudgetStagesFile? = {
        guard let url = Bundle.main.url(forResource: "budget-stages", withExtension: "json", subdirectory: "BudgetHistory")
                ?? Bundle.main.url(forResource: "budget-stages", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(BudgetStagesFile.self, from: data)
    }()

    static func doc(_ year: Int, _ stage: BudgetStage) -> BudgetStageDoc? {
        file?.years[String(year)]?[stage.rawValue]
    }

    /// Every year with an adopted budget on file, oldest first.
    static var adoptedYears: [Int] {
        (file?.years ?? [:]).compactMap { key, stages in stages["adopted"] == nil ? nil : Int(key) }.sorted()
    }

    /// The newest adopted budget: the one the Town is operating under or about to.
    static var currentYear: Int? { adoptedYears.last }
    static var current: BudgetStageDoc? { currentYear.flatMap { doc($0, .adopted) } }

    /// The adopted budget before `currentYear`, for "up X% from last year".
    static var priorYear: Int? { adoptedYears.dropLast().last }
    static var prior: BudgetStageDoc? { priorYear.flatMap { doc($0, .adopted) } }

    /// The stages the Town printed for a year, in order.
    static func stages(_ year: Int) -> [(stage: BudgetStage, doc: BudgetStageDoc)] {
        BudgetStage.allCases.compactMap { s in doc(year, s).map { (s, $0) } }
    }

    /// The adopted figure for one fund across every adopted year, oldest first.
    static func adoptedSeries(fund code: String, _ value: (BudgetStageFund) -> Double?) -> [(year: Int, value: Double)] {
        adoptedYears.compactMap { y in doc(y, .adopted)?.funds[code].flatMap(value).map { (y, $0) } }
    }

    /// The year's adoption, in words, from the record: "adopted November 17, 2026 (Resolution 2026-995, 5–0)".
    /// Kept in step with web/lib/budget-adoption.ts RECORD; nil for a year not listed here.
    static func adoptionNote(_ year: Int) -> String? {
        switch year {
        case 2027: return "adopted November 17, 2026 (Resolution 2026-995, 5–0)"
        default: return nil
        }
    }

    /// Percent change, e.g. 1.73 for +1.73%.
    static func pct(_ to: Double, _ from: Double) -> Double {
        from == 0 ? 0 : (to / from - 1) * 100
    }
}
