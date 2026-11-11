//
//  CreditRating.swift
//  Riverhead NY Budget App
//
//  Riverhead's municipal credit rating: where it stands, how it got there, how
//  it compares to nearby towns (Brookhaven in particular, which holds Moody's
//  and S&P's top rating), and what the rating agencies' own stated criteria
//  suggest would move it.
//
//  Ported from the web edition's web/lib/credit-rating.ts so the platforms tell
//  the same story.
//
//  SOURCING NOTE: primary rating-agency documents (moodys.com, spglobal.com)
//  and several town press-release pages (brookhavenny.gov, riverheadlocal.com)
//  were not directly fetchable in the environment that compiled this data.
//  Every quote and figure below is flagged for confidence: .verified (matches a
//  figure already sourced elsewhere in this app from an audited filing) or
//  .reported (from news coverage / press releases, not independently confirmed
//  against the primary document). Nothing here should be read as a direct,
//  word-for-word quotation unless marked .verified — reported quotes are the
//  best available reconstruction from public coverage, not a certified
//  transcript.
//
//  Swift 6 · iOS 17+
//

import SwiftUI

enum CreditRating {

    // MARK: - Confidence

    enum Confidence: String {
        case verified = "VERIFIED"
        case reported = "REPORTED"

        var color: Color {
            switch self {
            case .verified: return RiverheadTheme.brandMint
            case .reported: return RiverheadTheme.brandGold
            }
        }
    }

    // MARK: - Riverhead today

    enum Current {
        static let agency = "Moody's Investors Service"
        static let rating = "Aa2"
        static let affirmedDate = "February 16, 2024"
        static let shortTermRating = "MIG 1"
        static let shortTermContext = "assigned to a $20 million Bond Anticipation Note renewal issued alongside the Feb. 2024 affirmation"
        static let confidence: Confidence = .reported
        static let sourceTitle = "RiverheadLOCAL, “Moody's affirms Riverhead's credit rating, citing downtown growth, strong local economy and town's conservative budgeting,” Feb. 25, 2024"
        static let sourceDetail = "A primary Moody's rating-action letter is hosted by the Town itself (townofriverheadny.gov/files/documents), but could not be retrieved in this pass to quote verbatim."
    }

    // MARK: - Rating history

    struct RatingEvent: Identifiable {
        let id = UUID()
        let date: String
        let action: String
        let rating: String
        let quote: String?
        let quoteAttribution: String?
        let confidence: Confidence
    }

    static let ratingHistory: [RatingEvent] = [
        .init(
            date: "March 2015",
            action: "Downgraded",
            rating: "Aa2 → Aa3",
            quote: nil,
            quoteAttribution: nil,
            confidence: .reported
        ),
        .init(
            date: "July 23, 2021",
            action: "Upgraded",
            rating: "Aa3 → Aa2",
            quote: "the town's much improved reserve position over the past several years along with the expectation that these levels will be maintained in the future; the town's sizable tax base [and] declining debt burden, but elevated OPEB liability",
            quoteAttribution: "Moody's rating rationale, as reported by RiverheadLOCAL",
            confidence: .reported
        ),
        .init(
            date: "February 16, 2024",
            action: "Affirmed",
            rating: "Aa2 (plus MIG 1 short-term, on a $20M BAN renewal)",
            quote: "the Town Board's conservative fiscal budgeting is leading us down the right path",
            quoteAttribution: "Bill Rothaar, Riverhead Financial Administrator, as reported by RiverheadLOCAL",
            confidence: .reported
        ),
    ]

    static let ratingGap = "The most recent Moody's action found in public reporting is the February 2024 affirmation. Riverhead carried $21,975,000 in Bond Anticipation Notes as of Dec. 31, 2025 — a balance that typically gets renewed annually and usually comes with a fresh (if brief) rating letter. If a 2024–2025 renewal rating exists, it isn't in the coverage indexed here; ask the Financial Administrator's office for the most recent letter before treating Feb. 2024 as current."

    // MARK: - Brookhaven

    enum Brookhaven {
        static let moodyRating = "Aaa"
        static let spRating = "AAA"
        static let outlook = "stable"
        static let consecutiveMoodyAaaYears = 7
        static let asOf = "reported ~September 2025"
        static let confidence: Confidence = .reported
        static let spRationale = "the growing local economy, comprehensive formal financial management policies, strong budgetary performance with very strong reserves, and moderate debt with rapid amortization and manageable pension and OPEB costs"
        static let history = "Brookhaven's climb to a top rating predates the current administration — coverage traces AAA-adjacent recognition back to at least 2015 (under then-Supervisor Ed Romaine) and a 2020 upgrade to triple-A, carried forward through Supervisor Dan Panico. It reads as a decade-plus of sustained practice, not one administration's achievement."
        static let sources = [
            "Town of Brookhaven press release, “Panico Announces Brookhaven Maintains AAA Rating with Stable Outlook from Moody's and S&P Global” (~Sept. 2025)",
            "The Bond Buyer, “Budgeting credited for Brookhaven, N.Y., upgrade to triple-A” (2020)",
        ]
    }

    // A quote supplied for this page could NOT be located verbatim in any
    // retrievable source after multiple targeted searches. The closest
    // confirmed-adjacent statement is a DIFFERENT Panico quote, about the 2026
    // budget PROPOSAL, not the AAA rating announcement. Per this project's
    // sourcing standard, an unverified quote is not published as a direct
    // attribution — it's noted here so the gap is visible rather than silently
    // dropped, and so a future pass can confirm it against
    // brookhavenny.gov/CivicAlerts.aspx?AID=4604.
    enum BrookhavenQuoteNote {
        static let suppliedQuote = "We have remained disciplined in our budgeting, strengthened the Town's financial position, and planned responsibly for Brookhaven's future."
        static let status = "UNVERIFIED — not found verbatim in any source checked; not published as an attributed quote in this app."
        static let closestConfirmedAdjacent = "“a plan that strengthens the town's core functions and reflects the priorities of our residents — safety, quality of life and financial responsibility” — Supervisor Dan Panico, on the 2026 budget PROPOSAL (a different announcement than the AAA rating news)."
    }

    // MARK: - Suffolk peer ladder

    struct PeerRating: Identifiable {
        let id = UUID()
        let town: String
        let moodyRating: String?
        /// 0 = Aaa. Used only for the same-agency (Moody's) comparison bar.
        let moodyNotchesBelowAaa: Int
        let otherAgencyRating: String?
        let asOf: String
        let confidence: Confidence
        let isRiverhead: Bool
    }

    // Same-agency (Moody's) comparison only — mixing S&P/Fitch notches onto the
    // same bar would require an equivalence table this project can't source, so
    // those ratings are shown as a separate label instead of a bar position.
    static let peerRatings: [PeerRating] = [
        .init(town: "Brookhaven", moodyRating: "Aaa", moodyNotchesBelowAaa: 0, otherAgencyRating: "AAA (S&P)", asOf: "~Sept. 2025", confidence: .reported, isRiverhead: false),
        .init(town: "Smithtown", moodyRating: "Aaa", moodyNotchesBelowAaa: 0, otherAgencyRating: nil, asOf: "reaffirmed 2024–2026 bond issues", confidence: .reported, isRiverhead: false),
        .init(town: "Islip", moodyRating: "Aaa", moodyNotchesBelowAaa: 0, otherAgencyRating: nil, asOf: "Oct. 2020 — may be stale, re-verify", confidence: .reported, isRiverhead: false),
        .init(town: "Southold", moodyRating: "Aa1", moodyNotchesBelowAaa: 1, otherAgencyRating: nil, asOf: "July 2015 — may be stale, re-verify", confidence: .reported, isRiverhead: false),
        .init(town: "Riverhead", moodyRating: "Aa2", moodyNotchesBelowAaa: 2, otherAgencyRating: nil, asOf: "affirmed Feb. 2024", confidence: .reported, isRiverhead: true),
        .init(town: "Huntington", moodyRating: nil, moodyNotchesBelowAaa: 0, otherAgencyRating: "AAA (Fitch)", asOf: "no Moody's rating found", confidence: .reported, isRiverhead: false),
        .init(town: "Suffolk County", moodyRating: "Baa1", moodyNotchesBelowAaa: 7, otherAgencyRating: "AA- (Fitch & S&P, Oct. 2025)", asOf: "Moody's downgraded A3 → Baa1 in 2020", confidence: .reported, isRiverhead: false),
    ]

    // MARK: - What the criteria weigh

    // General rating-criteria framing (Moody's US Cities & Counties Methodology
    // and S&P's local-government criteria). Weights are approximate — a search
    // synthesis of secondary summaries, not a read of the primary methodology
    // PDFs (both moodys.com and spglobal.com were unreachable) — so they're
    // presented as illustrative ranges, not citable exact percentages.
    struct CriteriaFactor: Identifiable {
        let id = UUID()
        let factor: String
        let approxWeight: String
        let whatItMeans: String
        let riverheadRead: String
    }

    static let ratingCriteria: [CriteriaFactor] = [
        .init(
            factor: "Economy / tax base",
            approxWeight: "~30%",
            whatItMeans: "Total taxable value, value per resident, income levels, and how diversified the local economy is.",
            riverheadRead: "A strength that's improving: Moody's Feb. 2024 affirmation specifically cited downtown redevelopment and a strong local economy. EPCAL/Calverton remains underused capacity for further tax-base diversification."
        ),
        .init(
            factor: "Financial position / reserves",
            approxWeight: "~30%",
            whatItMeans: "Fund balance as a share of revenue, and — agencies say this explicitly — whether that level is expected to hold, not just its snapshot value.",
            riverheadRead: "Riverhead's clearest strength: unassigned General Fund balance was about 41.7% of 2026 appropriations at the end of 2025 — above the 38.8% Brookhaven's 2026 budget shows on the same measure (its unappropriated, unreserved balance). (That figure is from the independent audit of 2025, which the Town Board accepted on September 1, 2026.) This has not translated into a rating edge, which suggests other factors are the binding constraint."
        ),
        .init(
            factor: "Management / formal policies",
            approxWeight: "~10–20%",
            whatItMeans: "Whether budgeting, multi-year planning, and reserve policy are written, followed, and disclosed — not just practiced informally.",
            riverheadRead: "Brookhaven's S&P rationale explicitly credits “comprehensive formal financial management policies.” Riverhead's reserve policy is a standing Town Board resolution — Resolution 918 of 2011, which updated one from 2006 — but it sets only a 15% floor, with no ceiling, and the audits describe it without citing it by number. It has not been revised since 2011."
        ),
        .init(
            factor: "Debt & long-term liabilities",
            approxWeight: "~20–30%",
            whatItMeans: "Debt burden relative to the tax base and revenue, how fast principal amortizes, and pension/OPEB liabilities.",
            riverheadRead: "Split picture: bonded debt is a genuine strength — the 2025 audit puts debt subject to the constitutional limit at 5.48% of it, down from 6.74% a year earlier, and the Town issued no new debt at all during 2025, retiring $6.36M of principal instead. But OPEB (retiree health) is a documented drag — Moody's named “elevated OPEB liability” explicitly in the 2021 upgrade language, and at $129.5M (governmental activities, Dec. 31, 2025) it is still the largest single thing the Town owes, bigger than all bonds, notes, pension and leave liabilities combined."
        ),
    ]

    // MARK: - Levers

    struct Lever: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let evidence: String
    }

    static let levers: [Lever] = [
        .init(
            title: "Reserve what the law actually allows, and press the State on OPEB",
            detail: "Riverhead's retiree-health liability — the specific factor Moody's flagged as a drag in 2021 — stood at $129.5M on the governmental-activities basis at the end of 2025, and none of it is funded. The direction is worth stating precisely: that figure fell sharply in 2024, almost all of it the GASB 75 discount rate moving from 4.00% to 4.28%, and rose again in 2025 even though the rate rose further, to 4.43%. None of it was the Town setting money aside. What a New York town cannot do is fix this with a trust. The Comptroller's reserve-fund guide enumerates every reserve a town may create, and there is no OPEB reserve on that list — the guide does not use the word once. Money a board “sets aside” for retiree health is legally just unrestricted fund balance: spendable on anything, and worth nothing under GASB 75, which only lets a plan use a higher discount rate when assets sit in an irrevocable trust the State has not authorized. The honest agenda is two-part: fund the reserves that are authorized (§6-p for accrued leave, §6-r for pension-contribution volatility), and press for the enabling legislation that would let towns pre-fund OPEB at all.",
            evidence: "OPEB liability $129,479,192 governmental activities at Dec. 31, 2025 (2025 Annual Financial Report, Schedule W acct. 683); audited all-activities total $142,758,111 at Dec. 31, 2025, up $10,340,924 in the year (2025 audited financial statements, accepted Sept. 1, 2026). The per-resident ranking below is computed on the older $152.6M (2023) figure, which is what the Empire Center tool held when this comparison was built — Riverhead ranked 4th-highest of 10 Suffolk towns at $13,726/resident."
        ),
        .init(
            title: "Close the last structural gaps with recurring revenue, not one-time transfers",
            detail: "The 2027 Preliminary still counts $880,000 of General Fund savings as income, and $4,945,000 more across the water and sewer districts. Agencies explicitly reward towns that “balance responsibly — without dipping into reserves” (cited for Smithtown's own rating). Closing those draws with recurring revenue at adoption, not with fund balance, keeps that praise applicable to Riverhead too.",
            evidence: "2027 Preliminary Summary: appropriated fund balance $880,000 in the General Fund and $5,825,000 across all funds. The 2026 adopted budget's General Fund mismatch was $74,283."
        ),
        .init(
            title: "Update the reserve policy, and put it where a rating analyst looks",
            detail: "Riverhead's written policy, Resolution 918 of 2011, sets a 15% floor and names three uses for money above it: reducing the next year's property taxes, one-time capital costs, and natural emergencies. It sets no ceiling, and the Town is running well above the floor (41.7%). The Comptroller's reserve-funds guide is specific about what a written policy has to do, and it is more than naming a percentage: it should say why the money is being set aside, the board's financial objectives, optimal funding levels, and the conditions under which the assets will be used \u{2014} plus how a drawn-down reserve gets replenished. The same guide warns that reserves \u{201C}should not be merely a \u{2018}parking lot\u{2019} for excess cash or fund balance,\u{201D} which is the harder question for a town holding 41.7%. It also asks boards to review existing reserves periodically, set a ceiling on what accumulates, and reduce or close any reserve whose purpose has been met. Updating the 2011 resolution to answer those, and disclosing it in the AFR's Management's Discussion & Analysis, is what Brookhaven's S&P rationale is crediting when it praises \u{201C}comprehensive formal financial management policies.\u{201D}",
            evidence: "Riverhead's current unassigned fund balance: 41.7% of 2026 General Fund appropriations (2025 audit), vs. 38.8% for Brookhaven's unappropriated, unreserved balance in its 2026 budget. Policy criteria and the \u{2018}parking lot\u{2019} caution: NYS Comptroller, \u{201C}Reserve Funds\u{201D} (Local Government Management Guide), Board Direction and Oversight. That guide also notes that when a transfer of surplus into a reserve is not already in the adopted budget, a board resolution is generally required, and it should state the amount and name the reserve being credited."
        ),
        .init(
            title: "Keep growing the tax base beyond Tanger and Route 58",
            detail: "Moody's own 2024 affirmation cited downtown redevelopment and economic growth as a positive. EPCAL/Calverton — the former Grumman site — remains a large, underused parcel the Town has worked for years to return fully to the tax rolls. Continued progress there is a direct, on-record positive for the “economy / tax base” factor, and reduces reliance on a small number of big-box and outlet-mall ratables.",
            evidence: "Largest taxpayers concentrated in Tanger Outlets, PSEG, and the Route 58 big-box corridor; EPCAL redevelopment still in progress."
        ),
        .init(
            title: "Ask Moody's for a fresh look",
            detail: "The last confirmed rating action found in public reporting is Feb. 2024 — before the reserve position grew further and before the 2026 buyout/retirement program reshaped payroll. The 2021 upgrade explicitly cited an “expectation that these [reserve] levels will be maintained in the future.” Riverhead has since exceeded that expectation. A rating review timed to reflect the current, stronger reserve position — rather than waiting for the next routine BAN renewal — is a low-cost, board-directed step.",
            evidence: "Moody's Feb. 2024 affirmation vs. $21,975,000 in BANs outstanding as of Dec. 31, 2025, implying at least one un-reported renewal since."
        ),
    ]

    // MARK: - OPEB levers

    // Two different things: FUNDING the liability (how it gets paid for) vs.
    // SHRINKING it (how big it gets in the first place). Current retirees' and
    // current employees' accrued benefits are generally vested and can't be
    // clawed back — the plan-design levers below apply to future hires and to
    // funding mechanics, not to cutting what's already been promised.
    static let opebLevers: [Lever] = [
        .init(
            title: "Know why a trust is not on the table — and who can change that",
            detail: "Riverhead pays retiree health costs out of the current operating budget each year, and the $129.5M liability just sits on the books. The obvious fix — park money in a trust the way a pension is funded — is not available to a New York town. General Municipal Law authorizes a specific, closed list of reserve funds (capital §6-c, repair §6-d, contingency and tax stabilization §6-e, bonded indebtedness §6-h, workers’ compensation §6-j, unemployment §6-m, insurance §6-n, accrued employee benefits §6-p, retirement contributions §6-r, and a handful more), and none of them is an OPEB reserve. This matters beyond bookkeeping: GASB 75 lets a plan discount at an expected investment return only when assets sit in an irrevocable trust dedicated to the benefit. With no such vehicle in statute, Riverhead must use the lower municipal-bond rate no matter how much it saves — which is exactly why the reported liability swings with that index rather than with anything the Board does. Changing this needs Albany, not Town Hall.",
            evidence: "$129,479,192 OPEB liability, unfunded, pay-as-you-go basis (2025 Annual Financial Report, Schedule W acct. 683 — governmental activities). Authority: General Municipal Law §§6-c through 6-r are the reserve funds a town may create — capital, repair, contingency and tax stabilization, snow and ice, bonded indebtedness, airport, workers’ compensation, electric utility depreciation, mandatory, unemployment, insurance, solid waste, employee benefit accrued liability (§6-p) and retirement contributions (§6-r). None is an OPEB or retiree-health reserve, and the Comptroller’s “Reserve Funds” guide does not use the word OPEB once. The later Article 2 sections are separate schemes, not reserve funds — §6-s community preservation, §6-t and §6-u charitable gifts, §6-v asset forfeiture — and none of them appears in that guide. Riverhead’s own Community Preservation Fund is a different account again, created under Town Law § 64-e, not under the reserve-fund article at all."
        ),
        .init(
            title: "Coordinate retirees onto Medicare more aggressively",
            detail: "The single biggest lever in Riverhead's own numbers. NYSHIP's benchmark rate runs about $19,337/year for a non-Medicare retiree's individual coverage, versus about $7,157/year once Medicare becomes primary at 65 — roughly a 3x difference for the same person. Riverhead's blended average of about $17,000/retiree/year implies a meaningful share of the pool is still pre-Medicare-primary. Making sure every eligible retiree is actually enrolled in Medicare Part B, with the Town's plan wrapping around it rather than paying first, captures most of that gap with no benefit cut.",
            evidence: "NYSHIP Participating Employer rates: ~$19,337/yr non-Medicare individual vs. ~$7,157/yr Medicare-primary; Riverhead blended ~$17,000/retiree/yr (2023 audit)."
        ),
        .init(
            title: "Bargain plan-design changes for future hires in successor contracts",
            detail: "Current retirees' benefits are vested and can't be reduced. But the PBA contract expired in 2026 with no successor public yet — a real, near-term opening. Police and fire units have historically negotiated the strongest retiree-health terms of any bargaining unit, so this is the highest-leverage seat at the table. Common changes towns negotiate for new hires only: a longer years-of-service vesting requirement before retiree health kicks in, retiree premium cost-sharing instead of a fully Town-paid premium, or capping the Town's dollar contribution so it doesn't automatically scale with future healthcare cost inflation.",
            evidence: "PBA contract (2023–2026) expired with no successor public as of this writing; police/fire units cited as the workforce segment carrying the strongest retiree-health terms."
        ),
        .init(
            title: "Extend the buyback/opt-out CSEA already has to PBA and SOA",
            detail: "The 2026–2029 CSEA contract added a buyback amount for employees who decline Town health coverage — for example because they're covered under a spouse's plan — paying a smaller stipend instead of a full premium. That's already precedent inside the Town's own contracts; extending an equivalent option to PBA and SOA in their next contracts is a natural, already-proven ask.",
            evidence: "Riverhead's CSEA 2026–2029 contract added new retiree buyback amounts for employees who decline coverage."
        ),
        .init(
            title: "Put the surplus into the reserves that are authorized",
            detail: "Riverhead already holds more in reserves (42.9% of budget) than its own peer comparisons suggest it needs, and that one-time money cannot legally go into an OPEB trust. It can go into reserves the statute does authorize, two of which map directly onto costs the Town is already carrying. An Employee Benefit Accrued Liability Reserve (§6-p) pays out accumulated sick, vacation and holiday leave when employees separate — Riverhead's accrued-leave liability is $11.6M and rising, and the 2026 retirement incentive converts part of it to cash inside a single budget year. A Retirement Contribution Reserve (§6-r) absorbs pension-contribution swings; the Town's net pension liability moved from $21.4M to $27.3M in one year on investment returns alone. Neither needs a referendum — a board resolution creates them.",
            evidence: "Unassigned fund balance 42.9% of 2026 General Fund appropriations, above every peer town in this app's comparison. Accrued leave $11,608,615 and net pension liability $27,346,801 at Dec. 31, 2025 (2025 Annual Financial Report, Schedule W accts. 687 and 638). Reserve authority: GML §6-p and §6-r, both created by board resolution without referendum."
        ),
    ]

    // MARK: - OPEB per-resident context

    struct OpebPeer: Identifiable {
        let id = UUID()
        let town: String
        let perResident: Int
        let isRiverhead: Bool
    }

    /// Net OPEB liability per resident, 10 Suffolk towns — the ranking the
    /// "4th-highest" claim above rests on. Sorted highest first.
    static let opebPerResident: [OpebPeer] = [
        .init(town: "Shelter Island", perResident: 30_359, isRiverhead: false),
        .init(town: "East Hampton", perResident: 17_565, isRiverhead: false),
        .init(town: "Southampton", perResident: 15_478, isRiverhead: false),
        .init(town: "Riverhead", perResident: 13_726, isRiverhead: true),
        .init(town: "Southold", perResident: 10_830, isRiverhead: false),
        .init(town: "Smithtown", perResident: 6_816, isRiverhead: false),
        .init(town: "Huntington", perResident: 4_922, isRiverhead: false),
        .init(town: "Islip", perResident: 3_638, isRiverhead: false),
        .init(town: "Brookhaven", perResident: 3_322, isRiverhead: false),
        .init(town: "Babylon", perResident: 3_039, isRiverhead: false),
    ]

    static var riverheadOpebRank: Int {
        (opebPerResident.firstIndex(where: \.isRiverhead) ?? 0) + 1
    }

    // MARK: - Headline figures used on the page

    /// Unassigned General Fund balance as a share of 2026 appropriations, from
    /// the 2025 audit (accepted September 1, 2026), as the website's
    /// lib/credit-rating.ts states it.
    static let riverheadReserveShare: Double = 0.417
    static let brookhavenReserveShare = "38.8%"
    /// Share of the constitutional debt limit used, from the 2025 audit
    /// (Note 3.E; 6.74% in the 2024 audit, on the same basis). The 2023 audit's 3.78% is NOT the same measurement — that
    /// aggregate counted bonds only, while this one counts the two BANs as
    /// well. The basis changed, so the two percentages are not a trend.
    static let debtLimitExhaustedPct = 5.48

    // MARK: - OPEB liability, on both of the bases it gets published on

    /// Riverhead's retiree-health liability is reported two different ways,
    /// and quoting one against the other across years invents a trend that
    /// does not exist:
    ///
    ///   • The AFR's Schedule W (acct. 683) reports **governmental
    ///     activities only**.
    ///   • The audited statements report an **all-activities total**, adding
    ///     the water and sewer enterprises.
    ///
    /// The widely-quoted $152.6M is the 2023 *all-activities* figure — the
    /// highest of the three years, and now two years stale.
    struct OpebYear: Identifiable {
        let id = UUID()
        let asOf: String
        /// Governmental activities (AFR Schedule W acct. 683).
        let governmental: Int
        /// Water & sewer share, from the audit. Nil where no audit is out yet.
        let businessType: Int?
        /// All-activities total, from the audit.
        let total: Int?
        /// The GASB 75 discount rate the valuation used.
        let discountRate: Double?
    }

    static let opebSeries: [OpebYear] = [
        .init(asOf: "December 31, 2023", governmental: 140_439_500, businessType: 12_157_618, total: 152_597_117, discountRate: 4.00),
        .init(asOf: "December 31, 2024", governmental: 120_100_149, businessType: 12_317_039, total: 132_417_187, discountRate: 4.28),
        .init(asOf: "December 31, 2025", governmental: 129_479_192, businessType: nil, total: nil, discountRate: nil),
    ]

    /// Newest figure available on any basis: governmental activities, 12/31/2025.
    static let opebLiability = 129_479_192

    /// Why the number moves the way it does. Read on the governmental basis
    /// alone the liability FELL $20.3M in 2024 and then rose $9.4M in 2025,
    /// which looks like the Town did something and then stopped. It didn't.
    static let opebWhyItMoves = "This liability is an actuarial estimate, not a bill. Most of the year-to-year movement comes from the discount rate GASB 75 requires an unfunded plan to use — the S&P Municipal Bond 20-Year High Grade index. It rose from 4.00% at the 2023 valuation to 4.28% at the 2024 one, which is the bulk of why the reported liability dropped that year. Nothing was pre-funded and no benefit was reduced. Read the direction of this number as a rate story first and a policy story second."

    // MARK: - Caveats

    static let caveats = [
        "Every quote and figure here that isn't independently confirmed against a primary audited document is marked REPORTED — reconstructed from news coverage and press releases, not a certified transcript of the rating agency's own text.",
        "Rating-agency methodology weights are approximate, synthesized from secondary summaries rather than a direct read of the current Moody's/S&P methodology PDFs — treat them as illustrative, not precise.",
        "Islip's Aaa (2020) and Southold's Aa1 (2015) are the newest data points found for those towns and may be outdated; ratings can and do move without making it into easily searchable coverage.",
        "A supplied Brookhaven quote about disciplined budgeting could not be verified verbatim against any source checked and is not presented here as an attributed quotation — see the note on this screen.",
    ]
}
