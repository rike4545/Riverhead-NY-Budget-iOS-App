//
//  PoliceContracts2027.swift
//  Riverhead NY Budget App
//
//  The proposed 2027-2030 PBA and SOA stipulations, items IX.26 and IX.27 on
//  the Town Board's November 17, 2026 agenda, and item IX.2, the one-time
//  retirement-incentive payouts. PROPOSED, NOT APPROVED: set `adopted` once
//  the Board votes.
//
//  Mirrors the web edition's web/lib/police-stipulations-2027.ts, whose
//  verify script checks every figure against the agenda packet. Copy changes
//  from there; don't edit figures here alone.
//
//  Swift 5 language mode
//

import Foundation

enum PoliceContracts2027 {

    struct Row: Identifiable {
        let title: String
        /// 2026 (current) through 2030.
        let rates: [Double]
        var id: String { title }
        var fourYearChange: Double { rates[4] / rates[0] - 1 }
    }

    /// nil until the Board votes; then true or false.
    static let adopted: Bool? = nil

    static let years = [2026, 2027, 2028, 2029, 2030]
    static let meetingDate = "November 17, 2026"
    static let agendaURL = URL(string: "https://riverheadny.portal.civicclerk.com/event/6457/files/agenda/12598")!
    static let packetURL = URL(string: "https://riverheadny.portal.civicclerk.com/event/6457/files/agenda/12599")!

    /// Every row rises this much a year; this app's reading of the schedules.
    static let impliedRaise = 0.0375
    /// Added to 2027 salaries only, for the body-camera agreement.
    static let bodycam2027 = 500.0

    static let pbaOfficers: [Row] = [
        Row(title: "Academy", rates: [55_899.88, 58_496.13, 60_689.73, 62_965.60, 65_326.80]),
        Row(title: "1st year officer", rates: [72_066.67, 75_269.17, 78_091.76, 81_020.21, 84_058.46]),
        Row(title: "2nd year officer", rates: [88_233.47, 92_042.23, 95_493.81, 99_074.83, 102_790.13]),
        Row(title: "3rd year officer", rates: [104_400.27, 108_815.28, 112_895.85, 117_129.45, 121_521.80]),
        Row(title: "4th year officer", rates: [120_567.07, 125_588.34, 130_297.90, 135_184.07, 140_253.47]),
        Row(title: "5th year officer", rates: [136_733.86, 142_361.38, 147_699.93, 153_238.68, 158_985.13]),
        Row(title: "6th year officer (top step)", rates: [152_900.66, 159_134.43, 165_101.98, 171_293.30, 177_716.80]),
    ]

    static let pbaDetectives: [Row] = [
        Row(title: "Detective grade III", rates: [163_860.84, 170_505.62, 176_899.58, 183_533.32, 190_415.82]),
        Row(title: "Detective grade II", rates: [170_754.31, 177_657.60, 184_319.76, 191_231.75, 198_402.94]),
        Row(title: "Detective grade I", rates: [175_080.43, 182_145.95, 188_976.42, 196_063.03, 203_415.40]),
    ]

    static let soaRanks: [Row] = [
        Row(title: "Probationary sergeant", rates: [170_273.93, 177_159.20, 183_802.68, 190_695.28, 197_846.35]),
        Row(title: "Sergeant", rates: [187_647.21, 195_183.98, 202_503.37, 210_097.25, 217_975.90]),
        Row(title: "Detective sergeant", rates: [192_311.78, 200_023.47, 207_524.35, 215_306.51, 223_380.51]),
        Row(title: "Lieutenant", rates: [201_531.81, 209_589.25, 217_448.85, 225_603.18, 234_063.30]),
    ]

    /// Yearly amounts. K-9 is in the PBA schedule only.
    static let nightDifferential: [Row] = [
        Row(title: "Midnight tour", rates: [9_189.11, 9_533.70, 9_891.22, 10_262.14, 10_646.97]),
        Row(title: "Two-tour rotating schedule", rates: [5_365.07, 5_566.26, 5_774.99, 5_991.56, 6_216.24]),
        Row(title: "K-9", rates: [8_047.60, 8_349.39, 8_662.49, 8_987.33, 9_324.36]),
    ]

    /// Both Fiscal Impact Statements, section D, word for word.
    static let fiscalImpactAnswer = "Will the Proposed Legislation have a Fiscal Impact: No"

    /// The website's estimate of the 2027 schedule increase on the Police
    /// Officer ladder, for the 74 officers it counts, on top of step raises.
    static let ladderIncrease2027 = 428_561.0
    static let ladderOfficers = 74

    // MARK: - The CSEA contract, for comparison

    /// The 2026-2029 CSEA agreement, Article 15(2) (Wages), approved December 16,
    /// 2025 (Resolution 2025-1001): each step rises by the percentage, then the
    /// flat amount is added to every step and carries into later years.
    /// Mirrors CSEA_TERMS in the website's web/lib/raises-2027.ts.
    struct CseaTerm: Identifiable {
        let year: Int
        let pct: Double
        let flat: Double
        var id: Int { year }
    }

    static let cseaTerms: [CseaTerm] = [
        CseaTerm(year: 2026, pct: 0.02, flat: 1_500),
        CseaTerm(year: 2027, pct: 0.025, flat: 1_000),
        CseaTerm(year: 2028, pct: 0.03, flat: 500),
        CseaTerm(year: 2029, pct: 0.035, flat: 0),
    ]

    /// What $100 of 2026 pay becomes by `year` under the proposed police terms
    /// (percentages only; the $500 is per person).
    static func policePer100(by year: Int) -> Double {
        100 * pow(1 + impliedRaise, Double(year - 2026))
    }

    /// The same for CSEA, percentages only; its flat amounts are per person.
    static func cseaPer100(by year: Int) -> Double {
        cseaTerms.filter { $0.year > 2026 && $0.year <= year }.reduce(100) { $0 * (1 + $1.pct) }
    }

    /// One CSEA salary carried through the contract: the percentage, then the flat amount.
    static func cseaSalary(from y2026: Double, by year: Int) -> Double {
        cseaTerms.filter { $0.year > 2026 && $0.year <= year }.reduce(y2026) { $0 * (1 + $1.pct) + $1.flat }
    }

    /// The middle salary of the CSEA members on the 2026 authorized list, as the
    /// website's payroll page computes it.
    static let cseaTypical2026 = 68_564.79

    // MARK: - Item IX.2: the one-time retirement-incentive payouts

    struct PayoutLine: Identifiable {
        let account: String
        let name: String
        let amount: Double
        var id: String { account }
    }

    static let payoutsFromFundBalance = 1_387_034.0
    static let payoutsTook = "three CSEA members and seven PBA members accepted this incentive"
    static let payoutLines: [PayoutLine] = [
        PayoutLine(account: "A01-3-3120-101-UNI-00000", name: "Police Uni Personal Services", amount: 1_188_322),
        PayoutLine(account: "A01-1-1110-101-NON-00000", name: "Justice Court Personal Services", amount: 37_180),
        PayoutLine(account: "A01-1-1355-101-NON-00000", name: "Assessors Personal Services", amount: 48_395),
        PayoutLine(account: "A01-1-1680-101-NON-00000", name: "IT Personal Services", amount: 14_569),
        PayoutLine(account: "A01-9-9035-805-UNI-00000", name: "FICA Police Uni", amount: 90_907),
        PayoutLine(account: "A01-9-9030-805-NON-00000", name: "FICA Non-Uni", amount: 7_661),
    ]

    static var statusLabel: String {
        switch adopted {
        case .none: return "Proposed, not yet voted on"
        case .some(true): return "Approved by the Town Board"
        case .some(false): return "Not approved by the Town Board"
        }
    }
}
