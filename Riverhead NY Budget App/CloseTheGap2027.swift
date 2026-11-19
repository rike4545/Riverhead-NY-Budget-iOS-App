//
//  CloseTheGap2027.swift
//  Riverhead NY Budget App
//
//  The real 2027 constraint — the tax-cap gap — and the politically durable path
//  through a divided Town Board. Ported from the web edition's close-the-gap-2027.ts
//  so the three platforms tell the same story.
//
//  Two different "gaps" appeared in the 2027 planning views and they measure
//  different things:
//    • payroll-pressure gap ($936,727) — the recurring cost of standing still.
//    • cap-piercing gap    ($2,316,256) — how far the September model's 2027
//      levy overshot a flat 2% increase.
//
//  These are the website's September model, kept as it was made before the
//  Tentative (budget-2027-prediction-september.json): a projection from recent
//  cost trends and contract raises, not a Town figure. `Outcome` holds what the
//  Town Board actually adopted on November 17, 2026.
//
//  Swift 6 / iOS 17+
//

import Foundation

enum CloseTheGap2027 {
    // The September model's capGap (web/public/data/budget-2027-prediction-september.json).
    // This app's earlier copy ($2,757,133 on a $69,407,951 levy) came from a later
    // re-run, not the model the website quotes; these are the website's figures.
    static let capPiercingGap: Double = 2_316_256
    static let allowedLevy: Double = 66_650_818
    static let predictedLevy: Double = 68_967_074
    static let predictedLevyPct: Double = 5.5

    /// What the Town Board adopted, from the 2027 Adopted Budget's Summary page
    /// (levy across all funds) and the November 17, 2026 minutes.
    enum Outcome {
        static let adoptedLevy: Double = 66_516_005
        static let adoptedLevyPct: Double = 1.79
        static let adoptedOn = "November 17, 2026"
        static let resolution = "2026-995"
        static let vote = "5–0"
        /// Under the 2% reference line by this much (allowedLevy − adoptedLevy).
        static var underReferenceLine: Double { CloseTheGap2027.allowedLevy - adoptedLevy }
        /// Below the September model by this much.
        static var belowModel: Double { CloseTheGap2027.predictedLevy - adoptedLevy }
        static let summary = "The Town Board adopted the 2027 budget on November 17, 2026 (Resolution 2026-995, 5–0) with a levy across all funds of $66,516,005, up 1.79% from 2026. That is $134,813 under the 2% reference line and $2,451,069 below the September model, so the gap the model projected did not happen. The six October 20 amendments cut $643,858 from the Supervisor’s Tentative."
    }
    static let capBasePct: Double = 2

    /// The real ceiling is a little higher than a flat 2% once the tax-base-growth
    /// factor and the exclusions below are added, which shrinks the gap somewhat.
    static let capGapCaveat = "The real ceiling is a bit higher than a flat 2% once the tax-base-growth factor and exclusions are added, which would shrink the gap somewhat."

    // MARK: - How the Personal Services rate is built

    /// Each bargaining unit's own 2027 rate, weighted by its share of 2025 actual
    /// Town payroll — replacing the single flat 3.5% the model used before.
    struct UnionRate: Identifiable {
        let union: String
        let payrollSharePct: Double
        let ratePct: Double
        /// False when the contract expires 12/31/2026 with no successor public —
        /// the rate shown is that unit's own trailing average, used as a placeholder.
        let known2027: Bool
        let term: String?
        let source: String
        var id: String { union }
    }

    static let blendedPersonalServicesRatePct: Double = 3.84

    static let unionBreakdownNote = "How the September model built its Personal Services rate (3.84%/yr): each bargaining unit’s 2027 rate as known then, weighted by its share of 2025 actual Town payroll. It is a projection made before the Tentative, not a Town figure."

    static let unionBreakdown: [UnionRate] = [
        .init(
            union: "CSEA",
            payrollSharePct: 36.8,
            ratePct: 4.57,
            known2027: true,
            term: "2026–2029 CBA",
            source: "Fully executed 2026–2029 CSEA Agreement, Article 15(2) (Wages), signed 12/6/2025. Each year is a step % PLUS a flat, non-recurring dollar add-on that compounds into later years' base (2%+$1,500 in 2026, 2.5%+$1,000 in 2027, 3%+$500 in 2028, 3.5% in 2029) — converted here to an effective % using 2025 actual average CSEA base pay ($45,811), so the flat dollars are properly weighted rather than ignored."
        ),
        .init(
            union: "PBA",
            payrollSharePct: 36.7,
            ratePct: 3.36,
            known2027: false,
            term: "2023–2026 MOA; the September model's placeholder. Approved Nov 17, 2026: 3.75% a year plus $500 in 2027 (Resolution 2026-1020)",
            source: "Signed PBA MOA, Article XXXVII (Salaries), 7/25/2023. Full known PBA history back to 2016 (2%/2%/1.5%/1.5% in 2017–2020, 2%/2% in the 2021–2022 COVID extension per Town Board Resolution 2020-519) confirms the contracts are continuous with no gap — but the placeholder still uses only the most recent 2023–2026 contract, as the closer starting point for the next negotiation."
        ),
        .init(
            union: "SOA",
            payrollSharePct: 8.5,
            ratePct: 4.49,
            known2027: false,
            term: "2023–2026 agreement; the September model's placeholder. Approved Nov 17, 2026: 3.75% a year plus $500 in 2027 (Resolution 2026-1021)",
            source: "Signed SOA MOA, Article XXXII (Salaries), 12/12/2023. Full known SOA history back to 2016 (2%/2%/2%/2%/1.5% in 2016–2020, 2%/2% in the 2021–2022 COVID extension per Town Board Resolution 2020-520) confirms the contracts are continuous with no gap — but the placeholder still uses only the most recent 2023–2026 contract, as the closer starting point for the next negotiation."
        ),
        .init(
            union: "Non-union / other",
            payrollSharePct: 17.9,
            ratePct: 3.0,
            known2027: false,
            term: nil,
            source: "Management-confidential, elected, temporary, and unspecified positions. No CBA covers these positions; a general 3.0% trend assumption is used."
        ),
    ]

    static let unionBreakdownEstimateNote = "“Est.” marks the rates the September model used while PBA and SOA had no successor contract: each union’s own trailing average raise. On November 17, 2026 the Board approved 2027–2030 stipulations for PBA and SOA: 3.75% a year, plus $500 in 2027 (Resolutions 2026-1020 and 2026-1021). The adopted budget, not this model, is what happened."

    // MARK: - Pension exclusion from the tax cap

    /// New York's cap allows a municipality to exclude the portion of a pension
    /// contribution-rate rise above 2 percentage points. Only PFRS clears that
    /// threshold for SFY 2026-27; ERS does not.
    enum PensionExclusion {
        static let totalEstimate: Double = 137_642
        static let pfrsRateIncreasePts: Double = 2.8
        static let ersRateIncreasePts: Double = 1.1
        static let pfrsExcessPts: Double = 0.8
        static let pfrsExclusionEstimate: Double = 137_642
        static let ersExclusionEstimate: Double = 0
        static let payrollYear = 2025
        static let source = "OSC, “NYSLRS Announces Employer Contribution Rates for SFY 2026-27” (9/2025): ERS 16.5%→17.6% (+1.1 pts, no exclusion — under the 2-pt threshold); PFRS 33.7%→36.5% (+2.8 pts, 0.8 pts over the threshold, so a real exclusion applies). Estimate uses actual PBA+SOA payroll as a stand-in for the state's “estimated salary base” — the Town's own ERS/PFRS billing detail would be more precise."
    }

    struct RetirementUnit: Identifiable {
        let unit: String
        let count: Int
        let benefit: String
        var id: String { unit }
    }

    enum RetirementIncentive {
        static let approved = "July 7, 2026 — unanimous Town Board vote"
        static let resolutions = "2026-678 (CSEA), 2026-679 (SOA), 2026-680 (PBA)"
        static let eligibleTotal = 53
        static let eligible: [RetirementUnit] = [
            .init(unit: "CSEA", count: 29, benefit: "Flat $12,500 lump sum"),
            .init(unit: "PBA", count: 18, benefit: "$1,000 / year of service + up to 30 accrued sick days"),
            .init(unit: "SOA", count: 6, benefit: "$1,000 / year of service + up to 30 accrued sick days"),
        ]
        static let projectedSavingsLow: Double = 500_000
        static let projectedSavingsHigh: Double = 800_000
        static let savingsWindow = "the rest of 2026 and the full 2027 budget year"
        static let electionDeadline = "September 1, 2026"
        static let retireBy = "October 1, 2026"
        static let note = "The savings figure is the Town's own projection; the final number depends on how many of the 53 eligible employees actually retire by the September 1, 2026 deadline, and on how each vacated post is refilled. Source: RiverheadLOCAL, July 9, 2026."
    }

    // How each lever fares on a divided board (1 Democratic Supervisor + a
    // 4-member Republican Council majority). `standing` describes political
    // durability, not dollars.
    enum Standing: String {
        case agreed = "Already agreed · 5–0"
        case lowFriction = "Low partisan friction"
        case neutral = "Neutral · no service cut"
        case oneTime = "One-time · bridge only"
        case deliberate = "Legal if done in the open"
        case blunt = "Blunt · overstated"
    }

    struct GapPath: Identifiable {
        let name: String
        let closes: String
        let standing: Standing
        let politics: String
        var id: String { name }
    }

    static let paths: [GapPath] = [
        .init(
            name: "Bank the retirement-incentive savings the whole Board already voted for",
            closes: "$500K–$800K recurring (Town projection)",
            standing: .agreed,
            politics: "The three union incentives passed 5–0 on July 7, 2026. Refilling the vacated posts at a lower step is the one salary saving both the Democratic Supervisor and the Republican majority have already endorsed — no new fight to have."
        ),
        .init(
            name: "Stack the sourced, audit-driven line trims",
            closes: "the firm-confidence recurring trims below",
            standing: .lowFriction,
            politics: "Each trim is tied to a specific, documented anomaly in the Town's own budget — a line that jumped 800%, 1,563%, or budgeted well above its own trailing actuals. Opposing one means defending an unexplained increase on the record, which is hard to do along party lines."
        ),
        .init(
            name: "Grow non-property-tax revenue",
            closes: "$1 off the levy for every $1 of new state aid, fees, mortgage tax, or interest",
            standing: .neutral,
            politics: "Offsets the cap-busting levy dollar-for-dollar with no service cut and no tax increase — the rare move with nothing for either side to run against."
        ),
        .init(
            name: "Use a modest, disclosed one-time fund-balance appropriation for the residual only",
            closes: "whatever gap remains after the recurring measures above",
            standing: .oneTime,
            politics: "An easy vote — it raises no tax and cuts no service — but it spends one-time money on recurring cost, so it can only bridge a transitional remainder. Appropriating the model's full $2.32M would have used ~8.0% of the $28.8M unassigned fund balance (2025 audit) — the truly flexible cushion — for something that recurs."
        ),
        .init(
            name: "If the Board still wants the spending, override the cap — deliberately and in public",
            closes: "the full gap, by raising the legal ceiling",
            standing: .deliberate,
            politics: "The cap can be exceeded legally: adopt the override local law first, in the open, with the 60% vote on the record — as Riverhead did for the 2023, 2024, 2025 and 2026 budgets. The problem to avoid is piercing the cap by accident; a disclosed, on-purpose override is a legitimate choice, not a violation."
        ),
        .init(
            name: "The blunt shortcut: an across-the-board 2.5% cut",
            closes: "~$2.1M on paper",
            standing: .blunt,
            politics: "Politically tempting because it sounds even-handed, but it overstates what's actually cuttable — most of the base is personnel and mandated costs a flat directive can't touch — and it hits services indiscriminately."
        ),
    ]

    static let pragmaticReading = "Start with what already carries bipartisan support (the 5–0 retirement incentive), stack the audit-driven trims and any non-tax revenue on top — none of which asks either side to hand the other a political win — and reserve one-time fund balance for the small residual. A cap override stays available, but as a deliberate, disclosed choice rather than a number the budget backs into."
}
