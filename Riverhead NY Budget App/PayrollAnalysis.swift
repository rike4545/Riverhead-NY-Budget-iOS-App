//
//  PayrollAnalysis.swift
//  Riverhead NY Budget App
//
//  Two analyses over the bundled Gross Earnings records (payroll-records.json,
//  4,444 employee-year rows, 2018-2025):
//
//   1. OVERTIME & STAFFING — is a police rank staffed by premium rather than by
//      headcount? The intuitive test (overtime above 1.5x base salary) finds
//      nobody in Riverhead, and that result is reported rather than hidden: a
//      test that never fires is broken, not conservative. The real signal is at
//      rank level, because overtime is paid at 1.5x — so a rank's overtime
//      divided by 1.5 and then by its average base gives the number of full
//      positions' worth of straight-time hours the overtime represents.
//
//   2. SEPARATION PAY — median final-year overtime is about 0.93x a person's own
//      prior average, so overtime FALLS at the end of a career. The
//      end-of-career money is in the residual (gross minus base minus overtime),
//      which in a separation year is frequently many times the person's norm.
//
//  PROVENANCE, handled asymmetrically and on purpose:
//   • Rank figures use REPORTED titles only. A title carried back from another
//     year would let a since-promoted officer's current rank absorb overtime
//     earned at a lower one.
//   • A union derived from the row's own Pay Class is accepted: "PBA 8-40" names
//     the bargaining unit outright and is not a claim about a different year.
//
//  Mirrors web/lib/overtime-staffing.ts and web/lib/separation-pay.ts, and the
//  Android OvertimeStaffing.kt / SeparationPay.kt.
//
//  Swift 6 · iOS 17+
//

import Foundation

// MARK: - Raw record

struct PayrollRow: Decodable {
    let y: Int
    let n: String
    let f: String?
    let d: String?
    let t: String?
    let c: String?
    let u: String?
    let r: Double
    let o: Double
    let g: Double
    /// Fields carried back from the person's other years: d/t/c/u.
    let i: String?
    /// Hire date from the export (YYYY-MM-DD, or the year alone), when on file.
    let h: String?
    /// Other pay: [longevity, holiday/differential, stipends, buy-outs, retro].
    let k: [Double]?

    var titleIsReported: Bool { !(i ?? "").contains("t") }
    var residual: Double { g - r - o }
    /// Stable across a name change; three people here appear under two surnames.
    var identity: String { (f?.trimmingCharacters(in: .whitespaces)).flatMap { $0.isEmpty ? nil : $0 } ?? n }
}

private struct PayrollFile: Decodable {
    let count: Int
    let records: [PayrollRow]
}

enum PayrollData {
    static let rows: [PayrollRow] = {
        guard let url = Bundle.main.url(forResource: "payroll-records", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(PayrollFile.self, from: data)
        else { return [] }
        return file.records
    }()
}

// MARK: - Overtime & staffing

struct RankYear: Identifiable {
    let year: Int
    let union: String
    let title: String
    let headcount: Int
    let totalBase: Double
    let totalOvertime: Double

    var id: String { "\(year)|\(union)|\(title)" }
    var avgBase: Double { headcount > 0 ? totalBase / Double(headcount) : 0 }
    var otShareOfBase: Double { totalBase > 0 ? totalOvertime / totalBase : 0 }
    /// Full positions' worth of straight-time hours the overtime represents.
    var fteCovered: Double { avgBase > 0 ? totalOvertime / OvertimeStaffing.otPremium / avgBase : 0 }
}

struct RankTrend: Identifiable {
    let union: String
    let title: String
    let years: [RankYear]

    var id: String { "\(union)|\(title)" }
    var latest: RankYear { years[years.count - 1] }
    /// Ran a full position or more in most years on record — not a one-off spike.
    var persistent: Bool { Double(years.filter { $0.fteCovered >= 1 }.count) > Double(years.count) / 2 }
}

struct IndividualRatioCheck {
    let threshold: Double
    let recordsChecked: Int
    let countOverThreshold: Int
    let countOverHalfBase: Int
    let highestRatio: Double
    let highestRatioYear: Int
    let highestRatioTitle: String
}

enum OvertimeStaffing {
    static let otPremium: Double = 1.5
    static let titleDataFrom = 2022
    static let individualRatioThreshold: Double = 1.5
    static let swornUnions: Set<String> = ["PBA", "SOA"]
    static let entryRankTitle = "Police Officer"

    static let trends: [RankTrend] = {
        var buckets: [String: [PayrollRow]] = [:]
        for row in PayrollData.rows {
            guard row.y >= titleDataFrom,
                  let u = row.u, swornUnions.contains(u),
                  row.r > 0, row.titleIsReported,
                  let rawTitle = row.t?.trimmingCharacters(in: .whitespaces), !rawTitle.isEmpty
            else { continue }
            buckets["\(row.y)|\(u)|\(rawTitle)", default: []].append(row)
        }

        let rankYears: [RankYear] = buckets.values.map { rows in
            let first = rows[0]
            return RankYear(
                year: first.y,
                union: first.u ?? "",
                title: first.t?.trimmingCharacters(in: .whitespaces) ?? "",
                headcount: rows.count,
                totalBase: rows.reduce(0) { $0 + $1.r },
                totalOvertime: rows.reduce(0) { $0 + $1.o }
            )
        }

        guard let latestYear = rankYears.map(\.year).max() else { return [] }

        return Dictionary(grouping: rankYears) { "\($0.union)|\($0.title)" }
            .compactMap { _, years -> RankTrend? in
                let sorted = years.sorted { $0.year < $1.year }
                guard sorted.last?.year == latestYear, let first = sorted.first else { return nil }
                return RankTrend(union: first.union, title: first.title, years: sorted)
            }
            .sorted { $0.latest.fteCovered > $1.latest.fteCovered }
    }()

    /// Ranks worth costing a post out: a full position in the latest year, sustained.
    static var flagged: [RankTrend] { trends.filter { $0.latest.fteCovered >= 1 && $0.persistent } }

    /// Reported precisely because it finds nothing.
    static let individualCheck: IndividualRatioCheck = {
        let sworn = PayrollData.rows.filter { row in
            guard let u = row.u else { return false }
            return swornUnions.contains(u) && row.r > 0
        }
        var maxRatio = 0.0, maxYear = 0, maxTitle = ""
        for row in sworn {
            let ratio = row.o / row.r
            if ratio > maxRatio {
                maxRatio = ratio; maxYear = row.y
                maxTitle = row.t?.trimmingCharacters(in: .whitespaces) ?? ""
            }
        }
        return IndividualRatioCheck(
            threshold: individualRatioThreshold,
            recordsChecked: sworn.count,
            countOverThreshold: sworn.filter { $0.o / $0.r >= individualRatioThreshold }.count,
            countOverHalfBase: sworn.filter { $0.o / $0.r >= 0.5 }.count,
            highestRatio: maxRatio,
            highestRatioYear: maxYear,
            // Rank, not name: the argument is about how a rank is staffed, and
            // nobody is doing anything wrong by working overtime offered to them.
            highestRatioTitle: maxTitle
        )
    }()

    static let caveats: [String] = [
        "Not all overtime is vacancy coverage. Court appearances, grant-funded details, special events and genuine emergencies all land in the same line, and none are fixed by adding headcount.",
        "A position is permanent; overtime is not. Overtime flexes down in a quiet year, and a hire made in a busy one still has to be paid in the quiet one — with a pension obligation that outlives the budget that created it.",
        "Supervisory ranks can’t be hired into. Detective, Sergeant and Lieutenant are promotional, so adding one means promoting a serving officer and hiring an entry-step officer to backfill.",
        "Contract terms shape the floor. Minimum call-in guarantees and shift-swap rules can mean a rank cannot convert overtime hours into a post one-for-one.",
        "A new officer isn’t available immediately. Academy and field training mean a hire authorised this budget year does not relieve overtime until well into the next one.",
    ]

    static let sourceNote = "Computed from the Town of Riverhead Gross Earnings reports bundled with this app — actual paid base and overtime by employee and year. Title and union are available from 2022 onward, so rank-level figures start there."
}

// MARK: - Separation pay

struct SeparationGroupRollup: Identifiable {
    let group: String
    let separations: Int
    let excessOverCareerAverage: Double
    let medianFinalYearResidual: Double
    var id: String { group }
}

struct SeparationSummary {
    let separations: Int
    let totalExcess: Double
    let medianFinalYearResidual: Double
    let largestFinalYearResidual: Double
    let concentratedCount: Int
    let concentratedShare: Double
    let byGroup: [SeparationGroupRollup]
}

struct LiabilityYear: Identifiable {
    let asOf: String
    let amount: Double
    var id: String { asOf }
}

enum SeparationPay {

    private static let lastFullYear = 2025
    private static let minYearsOnRecord = 3
    private static let materialExcess: Double = 5_000

    /// A blank union code is not one thing. Most are pre-2022 leavers whose
    /// records predate the Town reporting a group at all — but the largest
    /// payouts in the dataset sit here and are NOT unknown: they are department
    /// heads and appointed officials, who aren't union-covered by definition.
    ///
    /// Where the inference lands on the SAME real category the Town's own union
    /// code already names — ELE for elected, APT for appointed board members —
    /// return that code directly rather than a separate derived bucket. A blank
    /// code doesn't make someone a different kind of person, and emitting both
    /// produced two rows for what is really one group. Only "department head /
    /// contractual" has no corresponding raw code, so it keeps its own bucket.
    private static func group(of row: PayrollRow) -> String {
        if let u = row.u?.trimmingCharacters(in: .whitespaces), !u.isEmpty { return u }
        let payClass = (row.c ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        let title = (row.t ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        if payClass == "elected" || title == "town clerk" || title == "supervisor" { return "ELE" }
        if title.hasPrefix("member of") { return "APT" }
        if payClass.contains("dept head") || payClass.contains("contractual") { return "~appointed" }
        return "~unknown"
    }

    static let groupLabels: [String: String] = [
        "PBA": "Police Benevolent Association",
        "SOA": "Superior Officers Association",
        "CSE": "CSEA",
        "CSEA": "CSEA",
        "NON": "Non-represented (incl. part-time & seasonal)",
        "APT": "Appointed board members",
        "CON": "Individual contract",
        "ELE": "Elected",
        "~appointed": "Department head / appointed — group inferred",
        "~unknown": "Group not recorded",
    ]

    static func label(_ code: String) -> String { groupLabels[code] ?? code }

    private static func median(_ xs: [Double]) -> Double {
        guard !xs.isEmpty else { return 0 }
        let s = xs.sorted()
        let m = s.count / 2
        return s.count % 2 == 1 ? s[m] : (s[m - 1] + s[m]) / 2
    }

    static let summary: SeparationSummary = {
        // Identity must never include a field the pipeline fills in: keying on
        // the union code would split one person in two the moment a blank code
        // got derived, inventing a separation that never happened.
        let byPerson = Dictionary(grouping: PayrollData.rows) { $0.identity }

        struct Row { let group: String; let excess: Double; let finalResidual: Double }
        var rows: [Row] = []

        for (_, personRows) in byPerson {
            let ys = personRows.sorted { $0.y < $1.y }
            guard let last = ys.last, last.y < lastFullYear, ys.count >= minYearsOnRecord else { continue }
            let prior = ys.dropLast().map(\.residual)
            guard !prior.isEmpty else { continue }
            let careerAvg = prior.reduce(0, +) / Double(prior.count)
            rows.append(Row(group: group(of: last), excess: last.residual - careerAvg, finalResidual: last.residual))
        }

        let totalExcess = rows.reduce(0) { $0 + max(0, $1.excess) }
        let concentrated = rows.filter { $0.excess > materialExcess }

        let byGroup = Dictionary(grouping: rows, by: \.group)
            .map { g, rs in
                SeparationGroupRollup(
                    group: g,
                    separations: rs.count,
                    // Only positive excess is summed: a separation year below
                    // someone's own norm isn't evidence of a payout.
                    excessOverCareerAverage: rs.reduce(0) { $0 + max(0, $1.excess) },
                    medianFinalYearResidual: median(rs.map(\.finalResidual))
                )
            }
            .sorted { $0.excessOverCareerAverage > $1.excessOverCareerAverage }

        return SeparationSummary(
            separations: rows.count,
            totalExcess: totalExcess,
            medianFinalYearResidual: median(rows.map(\.finalResidual)),
            largestFinalYearResidual: rows.map(\.finalResidual).max() ?? 0,
            concentratedCount: concentrated.count,
            concentratedShare: totalExcess > 0 ? concentrated.reduce(0) { $0 + $1.excess } / totalExcess : 0,
            byGroup: byGroup
        )
    }()

    // Town-wide Compensated Absences, account W687, Schedule of Non-Current
    // Governmental Liabilities. Transcribed from the Town's filing because the
    // three-year comparative column only appears in the newest report.
    static let liability: [LiabilityYear] = [
        LiabilityYear(asOf: "December 31, 2023", amount: 8_112_950.99),
        LiabilityYear(asOf: "December 31, 2024", amount: 9_773_699.95),
        LiabilityYear(asOf: "December 31, 2025", amount: 11_608_615.25),
    ]

    static var liabilityTwoYearChange: Double {
        (liability.last?.amount ?? 0) - (liability.first?.amount ?? 0)
    }

    static let liabilitySource = "Town of Riverhead 2025 Annual Financial Report — Schedule of Non-Current Governmental Liabilities, account 687, Compensated Absences (town-wide)."

    static let gasb101Note = "The Town adopted GASB Statement No. 101 (“Compensated Absences”) for the fiscal year ended December 31, 2024, which changes how this liability is measured. Part of the jump from 2023 to 2024 is therefore an accounting change, not purely additional accrued leave. The 2024-to-2025 increase is measured the same way at both ends."

    static let whyItMattersNow = "The 2026 retirement incentive the Town Board adopted 5–0 pays PBA and SOA members up to 30 accrued sick days on top of $1,000 per year of service, and CSEA members a flat $12,500. That converts part of this liability into cash inside a single budget year. The savings projection attached to that vote counts the salary the Town stops paying; it does not net out what the payouts cost."

    static let overtimeFinding = "A common suspicion is that people run up overtime late in a career to lift a pension. In Riverhead’s records that is not what happens — median final-year overtime is about 0.93× the same person’s own prior average, meaning overtime falls at the end of a career. The end-of-career money is in a different column: the residual left when you subtract base pay and overtime from gross pay."

    static let caveats: [String] = [
        "The payroll figures measure a residual, not a payout. Gross minus base minus overtime captures longevity, stipends, retroactive contract settlements and leave buy-outs together — the report does not separate them.",
        "“Leave and termination buy-outs” is itself mixed. It holds sick and vacation buy-backs — genuine accrued leave — alongside severance and health-insurance opt-out buy-backs, which are not leave at all. In 2023 the buy-backs were about 44% of that line.",
        "Most separations are unremarkable. The median separation year’s residual is small; this is a tail, and the tail is what the totals are made of.",
        "A separation year can be a partial year, which distorts any comparison against a full-year history.",
        "The liability and the payroll data are different measures — one an audited estimate of leave owed, the other cash that moved. They should move together over time but will not tie out year to year.",
        "None of this implies anyone was paid something they had not earned. Accrued leave is compensation employees banked under contracts the Town signed. The question is whether the Town is tracking and funding what it owes.",
    ]

    static let whatWouldSettleIt = "A schedule of accrued leave balances by bargaining unit, and the annual cash paid out on separation — neither of which the Town publishes, though both exist in its payroll system."
}
