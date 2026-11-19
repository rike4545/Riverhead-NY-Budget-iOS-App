//
//  PBAStepSchedule.swift
//  Riverhead NY Budget App
//
//  The PBA (Police Benevolent Association) salary step schedule, transcribed
//  from the signed 2023-2026 PBA contract, Article XXXVI (Salaries) and
//  Appendix B. This is the actual, contractual step-by-step pay ladder
//  rank-and-file officers move through — as distinct from the across-the-board
//  % increase applied to the whole schedule each year (see CloseTheGap2027's
//  union breakdown for that).
//
//  Mirrors the web edition's web/lib/pba-step-schedule.ts.
//
//  Swift 6 · iOS 17+
//

import Foundation

enum PBAStepSchedule {

    struct StepRow: Identifiable {
        let step: String
        let y2023: Double
        let y2024: Double
        let y2025: Double
        let y2026: Double
        var id: String { step }

        func value(for year: Int) -> Double {
            switch year {
            case 2023: return y2023
            case 2024: return y2024
            case 2025: return y2025
            default:   return y2026
            }
        }
    }

    static let years = [2023, 2024, 2025, 2026]

    /// Officers hired on or after 12/3/2012 climb seven steps to top pay.
    static let officerScheduleHiredOnOrAfter20121203: [StepRow] = [
        .init(step: "Academy",                    y2023:  49_540.66, y2024:  50_779.18, y2025:  52_048.66, y2026:  53_349.88),
        .init(step: "1st Year Officer",           y2023:  64_553.14, y2024:  66_166.97, y2025:  67_821.14, y2026:  69_516.67),
        .init(step: "2nd Year Officer",           y2023:  79_565.62, y2024:  81_554.76, y2025:  83_593.63, y2026:  85_683.47),
        .init(step: "3rd Year Officer",           y2023:  94_578.10, y2024:  96_942.55, y2025:  99_366.11, y2026: 101_850.27),
        .init(step: "4th Year Officer",           y2023: 109_590.57, y2024: 112_330.34, y2025: 115_138.60, y2026: 118_017.06),
        .init(step: "5th Year Officer",           y2023: 124_603.05, y2024: 127_718.13, y2025: 130_911.08, y2026: 134_183.86),
        .init(step: "6th Year Officer (top step)", y2023: 139_615.53, y2024: 143_105.92, y2025: 146_683.57, y2026: 150_350.66),
    ]

    /// Officers hired before 12/3/2012 reach the SAME top dollar figure — but a
    /// full year sooner, since their schedule has no separate 6th-year step. The
    /// rest of that legacy schedule (1st-4th year) isn't reproduced in the
    /// contract text because no one hired before 12/3/2012 is still climbing it
    /// 13+ years later; every such officer is already at or near the top step.
    static let officerTopStepHiredBefore20121203 = StepRow(
        step: "5th Year Officer (top step)",
        y2023: 139_615.53, y2024: 143_105.92, y2025: 146_683.57, y2026: 150_350.66
    )

    static let detectiveSchedule: [StepRow] = [
        .init(step: "Detective Grade III", y2023: 149_793.15, y2024: 153_537.98, y2025: 157_376.43, y2026: 161_310.84),
        .init(step: "Detective Grade II",  y2023: 156_194.43, y2024: 160_099.29, y2025: 164_101.77, y2026: 168_204.31),
        .init(step: "Detective Grade I",   y2023: 160_211.65, y2024: 164_216.95, y2025: 168_322.37, y2026: 172_530.43),
    ]

    static let academyRuleExample = "The contract spells out exactly how the Academy step transitions: an officer hired November 1, 2024 who completed the Academy on April 25, 2025 and reported for regular duty on May 1, 2025 would (a) be paid the Academy Rate from November 1, 2024 through April 30, 2025; (b) move to the 1st Year Officer rate from May 1, 2025 through April 30, 2026, the 2nd Year Officer rate from May 1, 2026 through April 30, 2027, and so on through the 5th year of service."

    static let sourceTitle = "Signed 2023-2026 PBA contract, Article XXXVI (Salaries) and Appendix B"

    static let sourceNote = "Two-tier schedule: officers hired on or after 12/3/2012 climb 7 steps (Academy through 6th Year Officer) to reach top pay; officers hired before that date reach the same top dollar figure a year sooner, with no separate 6th-year step. Detective grade pay applies once promoted, regardless of hire date. These are the 2023–2026 rates. The 2027–2030 stipulation the Board approved on November 17, 2026 (Resolution 2026-1020) raises every step 3.75% a year, plus $500 in 2027."

    // MARK: - What the steps actually paid

    /// Real 2025->2026 raises for actual Police Officers, from the Board's
    /// authorized-salary listings, grouped by identical before/after dollar
    /// pairs and matched to the step each group is moving from. Verified: every
    /// group's actual 2026 pay equals (the contract step schedule's next-step
    /// 2026 rate) plus a flat $2,550 that isn't itemized in Article XXXVI's base
    /// table — likely a holiday-pay or similar stipend the Board's authorized
    /// listing folds into "annual salary" but the base step schedule doesn't.
    /// Not confirmed against contract text beyond Article XXXVI/Appendix B.
    struct RealRaiseExample: Identifiable {
        let fromStep: String
        let toStep: String
        let actual2025: Double
        let actual2026: Double
        let contractStep2026: Double
        let addOn: Double
        let officerCount: Int
        let exampleName: String
        var id: String { fromStep }

        var raise: Double { actual2026 - actual2025 }
    }

    static let realRaiseExamples: [RealRaiseExample] = [
        .init(fromStep: "Academy",                     toStep: "1st Year Officer",            actual2025:  52_048.66, actual2026:  72_066.67, contractStep2026:  69_516.67, addOn: 2_550.00, officerCount:  3, exampleName: "Romer, Krista"),
        .init(fromStep: "1st Year Officer",            toStep: "2nd Year Officer",            actual2025:  67_821.14, actual2026:  88_233.47, contractStep2026:  85_683.47, addOn: 2_550.00, officerCount:  7, exampleName: "Buczynski, Julia"),
        .init(fromStep: "2nd Year Officer",            toStep: "3rd Year Officer",            actual2025:  83_593.63, actual2026: 104_400.27, contractStep2026: 101_850.27, addOn: 2_550.00, officerCount:  8, exampleName: "Dahlem, John"),
        .init(fromStep: "3rd Year Officer",            toStep: "4th Year Officer",            actual2025:  99_366.11, actual2026: 120_567.07, contractStep2026: 118_017.06, addOn: 2_550.01, officerCount:  5, exampleName: "Boden, Bryan"),
        .init(fromStep: "4th Year Officer",            toStep: "5th Year Officer",            actual2025: 115_138.60, actual2026: 136_733.86, contractStep2026: 134_183.86, addOn: 2_550.00, officerCount: 15, exampleName: "Ady, Stephan"),
        .init(fromStep: "5th Year Officer",            toStep: "6th Year Officer (top step)", actual2025: 130_911.08, actual2026: 152_900.66, contractStep2026: 150_350.66, addOn: 2_550.00, officerCount:  2, exampleName: "Anderson, Peter"),
        .init(fromStep: "6th Year Officer (top step)", toStep: "6th Year Officer (top step)", actual2025: 146_683.57, actual2026: 152_900.66, contractStep2026: 150_350.66, addOn: 2_550.00, officerCount: 32, exampleName: "Bianco, William"),
    ]

    static let realRaiseSourceTitle = "Town of Riverhead Board-authorized salary listings for 2025 and 2026 (January 2026 agenda packet)"

    static let realRaiseSourceNote = "Filtered to employees whose title is exactly “Police Officer” in both years, grouped by identical 2025→2026 dollar pairs. The 32 officers already at the 2025 top step and the 2 officers who moved from 5th to 6th Year Officer land at the exact same 2026 figure, since both groups are at (or reach) the ceiling."
}
