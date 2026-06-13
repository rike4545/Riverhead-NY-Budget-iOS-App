//
//  ProcurementPolicyWatchView.swift
//  Riverhead NY Budget App
//
//  Created by Codex on 5/14/26.
//

import SwiftUI

@MainActor
struct ProcurementPolicyWatchView: View {
    @Environment(\.openURL) private var openURL

    private let procurementCodeURL = URL(string: "https://ecode360.com/30531590")!
    private let petrocelliArticleURL = URL(string: "https://riverheadlocal.com/2026/05/14/riverhead-petrocelli-downtown-hotel-plans-review/")!
    private let newsdayTownSquareURL = URL(string: "https://www.newsday.com/long-island/towns/riverhead-town-square-master-developer-osr2wie7")!
    private let riverheadLocalHearingURL = URL(string: "https://riverheadlocal.com/2025/07/24/riverhead-weighs-whether-petrocelli-is-qualified-and-eligible-for-town-square-development/")!
    private let riverheadLocalDesignationURL = URL(string: "https://riverheadlocal.com/2025/08/06/town-square-moves-forward-as-riverhead-designates-petrocelli-qualified-and-eligible/")!
    private let masterDeveloperHearingURL = URL(string: "https://riverheadnewsreview.timesreview.com/2025/07/127343/july-22-hearing-set-for-town-square-master-developer/")!
    private let qualifiedEligibleApprovalURL = URL(string: "https://riverheadnewsreview.timesreview.com/2025/08/127728/j-petrocelli-named-qualified-and-eligible-town-square-developer/")!
    private let eastEndBeaconApprovalURL = URL(string: "https://www.eastendbeacon.com/riverhead-board-deems-petrocelli-qualified-eligible-to-build-town-square-hotel/")!
    private let competitiveBiddingBenchmarkURL = URL(string: "https://www.nysed.gov/facilities-planning/competitive-bidding-or-equal-and-bidding-cost-control")!
    private let ftcPriceFixingURL = URL(string: "https://www.ftc.gov/tips-advice/competition-guidance/guide-antitrust-laws/dealings-competitors/price-fixing")!
    private let petrocelliBoardBioURL = URL(string: "https://nymarinerescue.org/our-board-joseph-petrocelli/")!
    private let petrocelliBusinessProfileURL = URL(string: "https://libn.com/1999/07/23/for-petrocellis-construction-not-the-only-concern/")!
    private let zoningLotAgreementURL = URL(string: "https://www.klgates.com/the-zoning-lot-development-agreement-a-new-york-concept-long-overdue-in-new-jersey")!
    private let mdaURL = TownSquareCoreTerms.mdaPublicURL

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Procurement Watch", systemImage: "doc.text.magnifyingglass")
                        .font(.title3.weight(.semibold))

                    Text("A resident-facing lens for when repeat professional-services awards, sole-source claims, or master developer contracts appear to move around the spirit of Riverhead's procurement policy.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Why this matters") {
                WatchRow(
                    icon: "person.2.slash",
                    title: "Special access can crowd out competition",
                    detail: "Riverhead's policy purpose is open competition, prudent use of public money, and documented business judgment. Frequent carveouts for the same professional-service vendors or developer-side arrangements can weaken that purpose even when a narrow exception exists."
                )

                WatchRow(
                    icon: "repeat.circle",
                    title: "Frequency is the warning sign",
                    detail: "One professional-services resolution may be explainable. A pattern of repeated awards, renewals, amendments, and single-source justifications should be treated as a procurement-control issue."
                )

                WatchRow(
                    icon: "building.2.crop.circle",
                    title: "Master developer contracts need extra sunlight",
                    detail: "Downtown projects can bundle land, infrastructure, approvals, operating duties, grants, parking, utilities, and private development. The larger the bundle, the more residents need the original RFQ/RFP, scoring, appraisals, amendments, and board findings in one public trail."
                )
            }

            Section("Policy hooks to check") {
                FactRow(label: "Open competition", value: "The code says procurement should use sound business judgment and provide full and open competition.")
                FactRow(label: "Cumulative estimates", value: "Purchasers must estimate annual need and keep supporting documentation with the purchase file.")
                FactRow(label: "RFP / quote records", value: "Mid-range purchases and public works require documented requests and multiple quotes unless an exception applies.")
                FactRow(label: "Professional services", value: "Professional-services contracts are exempt from the RFP/quotation requirement, but they are still subject to Town Board resolution.")
                FactRow(label: "Sole source", value: "Sole-source situations are exempt from RFP/quotes only with written verification from the vendor.")
                FactRow(label: "Annual review", value: "The procurement policy is supposed to be reviewed annually.")
            }

            Section("Not a normal bid path") {
                WatchRow(
                    icon: "list.bullet.rectangle",
                    title: "Normal public bidding is broader and more mechanical",
                    detail: "As a benchmark, NYSED's public-works bidding guidance describes advertised competitive bidding, free competition, and award to the lowest responsible bidder. The Petrocelli path instead used a qualified-and-eligible sponsor / master developer process, so residents should not mistake it for an ordinary RFP or low-bid award."
                )

                WatchRow(
                    icon: "hammer",
                    title: "Experience is relevant, but not a substitute for competition",
                    detail: "A 1999 Long Island Business News profile described J. Petrocelli Construction as a large regional builder with school, stadium, office, warehouse, museum, library, restaurant, and other projects. That supports experience review, but it does not answer whether the Town tested price, terms, and alternatives through open competition."
                )

                WatchRow(
                    icon: "slider.horizontal.3",
                    title: "Selection criteria should be reconstructed",
                    detail: "If bids were not solicited and ranked like a normal RFP, the Town should publish the substitute decision record: eligibility criteria, financial review, experience review, alternatives considered, valuation support, and why this structure beat a competitive solicitation."
                )
            }

            Section("Petrocelli / Town Square contract") {
                Text("J. Petrocelli Riverhead Town Square LLC is the designated master developer for Riverhead's Town Square project. The deal is not just a private hotel application: it ties together public land, a town square, public amenities, construction management, long-term operation and maintenance, grant commitments, and a private hotel / restaurant / retail development.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                FactRow(label: "Hearing", value: "A qualified-and-eligible sponsor hearing was held July 22, 2025. RiverheadLOCAL reported the hearing was required before the Town Board could use Urban Renewal Law to designate the sponsor and sell 127 East Main Street without competitive bidding.")
                FactRow(label: "Designation path", value: "The Town Board had approved an April 2022 resolution designating J. Petrocelli Development Associates as master developer, followed by the 2025 qualified-and-eligible sponsor process. RiverheadLOCAL reported the Aug. 5, 2025 Town Board vote was unanimous.")
                FactRow(label: "Land price", value: "The MDA lists a $2.625M purchase price for the parcels, with a 5% down payment and credits for up to $660K in developer support for Town grant applications.")
                FactRow(label: "Private project", value: "The 2025 hearing coverage described a five-story mixed-use hotel project with up to 76 hotel rooms, 12 condominium units, restaurant / retail space, and 12 underground parking stalls; later 2026 coverage described a revised 94-room hotel proposal that removes the condos.")
                FactRow(label: "Latest hotel filing", value: "RiverheadLOCAL's May 14, 2026 evening coverage described a five-story, 69,738-square-foot Peconic River Hotel proposal with 94 rooms, a 116-seat restaurant/bar, coffee shop, nearly 2,900 square feet of retail, 14 fifth-floor suites, Hilton Tapestry branding, and expected public hearings on June 10, 2026.")
                FactRow(label: "Utility review", value: "The same coverage reported projected demand of about 20,000 gallons of water per day and 16,568 gallons of wastewater per day, with formal water and sewer availability letters and infrastructure-capacity analysis still required before site-plan approval.")
                FactRow(label: "Parking operations", value: "The hotel plan reportedly includes only nine on-site parking spaces, reserved for staff, with guest parking relying on valet operations, off-site spaces behind the Suffolk Theater, and eventually the planned First Street garage.")
                FactRow(label: "Hotel brand / benefits", value: "Newsday coverage of the Town Square project has described the hotel as a Hilton Tapestry Collection boutique hotel and reported that Petrocelli submitted an application for Riverhead IDA benefits, with specific terms not yet available at the time of that report.")
                FactRow(label: "Public square work", value: "The agreement materials reportedly included consulting agreements making Petrocelli construction manager for the amphitheater, playground, public gathering space, walkways, and other Town Square features.")
                FactRow(label: "Fee and O&M", value: "The hearing coverage reported a 7% construction-management fee based on total construction costs and a 10-year, $150K-per-year operation and maintenance obligation for the Town Square.")
                FactRow(label: "PILOT possibility", value: "The 2025 article also reported the contract allowed Petrocelli to apply to the Riverhead IDA for a PILOT, which would affect the standard property-tax path.")
                FactRow(label: "Full agreement", value: "The Town-hosted Master Developer Agreement and its exhibits are the primary contract source residents should use to verify every land-sale, credit, fee, O&M, staging, easement, parking, grant, and approval obligation.")

                Text("That structure does not prove a procurement violation by itself. It does mean the public should be able to see the competitive selection record, the scoring, the appraisal / valuation support, every credit, every amendment, and the taxpayer rationale in one place.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Public ledger") {
                WatchRow(
                    icon: "doc.text.magnifyingglass",
                    title: "Procurement transparency",
                    detail: "Because this was a qualified-and-eligible sponsor path rather than a normal competitive bid / RFP, residents need the substitute record: selection criteria, financial review, alternatives analysis, valuation support, board rationale, exhibits, amendments, and closing documents."
                )

                WatchRow(
                    icon: "parkingsign.circle",
                    title: "Parking costs",
                    detail: "If hotel guests rely on public lots, valet staging, or the planned garage, the Town should show whether the developer pays for reserved use, congestion management, enforcement, garage operations, and long-term parking-district impacts."
                )

                WatchRow(
                    icon: "percent",
                    title: "PILOT / tax impacts",
                    detail: "Any IDA PILOT should be shown against normal taxation so residents can see which taxes are reduced or delayed, whether schools and districts are affected, and whether the public benefit outweighs the tax discount."
                )

                WatchRow(
                    icon: "house.and.flag",
                    title: "Affordability impacts",
                    detail: "Tourism and higher-end redevelopment can raise land values, rents, assessments, and business occupancy costs. A hotel is transient lodging, so the Town should identify any year-round workforce, senior, or affordable-housing offset."
                )

                WatchRow(
                    icon: "square.3.layers.3d",
                    title: "Lot, easement, and development-rights structure",
                    detail: "New York zoning-lot agreement concepts show how contiguous parcels can be treated as one zoning unit and reallocate development capacity while ownership remains separate. Riverhead should disclose whether any lot merger, lot-line change, easement, parking covenant, development-right transfer, or successor-binding restriction affects the Town Square deal."
                )
            }

            Section("Public-process concern") {
                WatchRow(
                    icon: "exclamationmark.bubble",
                    title: "Qualified-and-eligible finding changed the procurement posture",
                    detail: "RiverheadLOCAL reported on Aug. 6, 2025 that the qualified-and-eligible designation allowed the Town to sell land adjacent to the square, including 127 East Main Street, to Petrocelli for $2.625M without a competitive bidding process."
                )

                WatchRow(
                    icon: "doc.badge.clock",
                    title: "Financial review materials should be easy to inspect",
                    detail: "The same article reported that Town personnel reviewed financial information and found the developer had sufficient resources, while some residents criticized that the memo was not available for public review before the decision."
                )

                WatchRow(
                    icon: "calendar.badge.exclamationmark",
                    title: "Hearing documents and comment timing matter",
                    detail: "RiverheadLOCAL reported that some applicant documents presented at the July 22 hearing were posted the day after the meeting, and later reported the Town Board decided to move forward before the Friday afternoon written-comment deadline."
                )

                WatchRow(
                    icon: "doc.text.magnifyingglass",
                    title: "Process concerns were separate from qualifications",
                    detail: "East End Beacon reported that many speakers considered Petrocelli qualified, while still questioning the process because only the proposed contract was available before the hearing and financial information was not posted in written form until after."
                )

                WatchRow(
                    icon: "envelope.badge",
                    title: "Hotel opposition should be counted separately",
                    detail: "East End Beacon reported a resident statement that 17 of 19 letters submitted through the public-hearing process opposed the hotel portion, underscoring the need to separate support for Town Square from support for the private hotel."
                )

                WatchRow(
                    icon: "questionmark.diamond",
                    title: "Grant-credit questions should be answered plainly",
                    detail: "The Aug. 6 RiverheadLOCAL article reported a resident question about whether a matching-funds pledge later credited against the property purchase effectively obligated the Town to approve the developer."
                )

                WatchRow(
                    icon: "parkingsign.circle",
                    title: "Parking and PILOT impacts need budget treatment",
                    detail: "The July 2025 hearing coverage reported resident questions about public parking use and a proposed PILOT provision described as material to the transaction economics."
                )
            }

            Section("Affordability pressure") {
                WatchRow(
                    icon: "house.and.flag",
                    title: "Real-estate policy can price out residents",
                    detail: "When public land, grants, tax abatements, parking assets, and infrastructure are steered toward higher-end redevelopment, the Town should show how the policy affects assessments, rents, local business costs, and year-round housing affordability."
                )

                WatchRow(
                    icon: "bed.double",
                    title: "Transient lodging is not the same as resident housing",
                    detail: "A hotel may support tourism and downtown spending, but it does not create ordinary affordable homes. The public benefit case should separate visitor lodging from workforce, senior, and year-round resident housing needs."
                )
            }

            Section("Hotel pricing competition") {
                WatchRow(
                    icon: "dollarsign.arrow.circlepath",
                    title: "Reduced competition can increase pricing power",
                    detail: "If Town policy leaves downtown hotel supply concentrated around one favored developer or related hotel interests, residents should ask whether the project limits future competition and strengthens pricing power for transient lodging."
                )

                WatchRow(
                    icon: "building.2",
                    title: "Related tourism and hotel interests should be disclosed",
                    detail: "A public board bio for Joseph Petrocelli identifies him with J. Petrocelli Contracting and as a co-founder / owner of the Long Island Aquarium and Hyatt Place East End Hotel. That background is relevant to experience, but also to market-concentration review."
                )

                WatchRow(
                    icon: "exclamationmark.shield",
                    title: "Price fixing requires evidence of agreement",
                    detail: "FTC guidance treats price fixing as an agreement among competitors to raise, lower, maintain, or stabilize prices. This screen does not allege price fixing; it flags the need to review market concentration, shared pricing tools, ownership ties, public incentives, and barriers to hotel competition."
                )
            }

            Section("Performance metrics") {
                WatchRow(
                    icon: "gauge.with.dots.needle.67percent",
                    title: "Revitalization needs measurable outcomes",
                    detail: "The public benefit case should include trackable metrics, not only renderings and broad economic-development claims. Residents should be able to compare promised outcomes with actual results over time."
                )

                WatchRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Metrics should connect to taxpayer value",
                    detail: "Useful measures include public-space usage, event days, downtown vacancy, local sales activity, parking demand, infrastructure costs, PILOT/tax impact, hotel occupancy, public maintenance quality, and year-round housing affordability."
                )

                WatchRow(
                    icon: "calendar.badge.checkmark",
                    title: "Milestones should have remedies",
                    detail: "If the MDA or related agreements set construction, operation, maintenance, reporting, or funding milestones, the Town should publish due dates, responsible parties, cure periods, penalties, termination rights, and annual status reports."
                )
            }

            Section("Petrocelli questions") {
                VStack(alignment: .leading, spacing: 8) {
                    bullet("Was the master developer designation based on a clear competitive RFQ/RFP record, and is that record still valid after later project changes?")
                    bullet("Were competing developers invited to bid or propose under comparable terms, or was Petrocelli evaluated through a non-RFP qualified-and-eligible process?")
                    bullet("If this was not a normal RFP / low-bid selection, where is the substitute record showing criteria, alternatives, scoring, and taxpayer value?")
                    bullet("Which Petrocelli experience factors were credited, and were those factors scored against any other qualified downtown developers or hotel operators?")
                    bullet("What exact legal basis allowed the land sale to proceed without competitive bidding after the qualified-and-eligible finding?")
                    bullet("Were all applicant financial and qualification documents available before residents testified, or were key materials posted only after the hearing?")
                    bullet("Was the Aug. 1 financial-review memo posted before the vote, and if not, why was the decision made before residents could inspect it?")
                    bullet("Why did the Board move forward before the written-comment deadline, and were late-filed comments incorporated into the final decision record?")
                    bullet("Did the Town separately count public support for the public square versus opposition to the private hotel, or were the two issues bundled together?")
                    bullet("Did the 2022 matching-funds pledge or later purchase-price credit create any practical obligation, expectation, or appearance problem before the qualified-and-eligible vote?")
                    bullet("What changed between the up-to-76-room / 12-condo concept reported in 2025 and the 94-room hotel proposal reported in 2026, and did any change require new public findings?")
                    bullet("Do the land price, grant credits, construction-management fee, and O&M payments reconcile to the public benefit the Town says it is receiving?")
                    bullet("Was the 7% construction-management role separately tested against the market, or folded into the master developer structure?")
                    bullet("Does the $150K/year, 10-year O&M arrangement include measurable service standards, termination rights, and annual reporting?")
                    bullet("If a PILOT is pursued, how will the tax impact be presented alongside the land sale, grants, public-square costs, and private hotel benefits?")
                    bullet("What IDA benefits were requested for the Hilton Tapestry Collection hotel component, and are the proposed exemption terms public before any vote?")
                    bullet("If the hotel relies on public parking assets, should the operating budget show reserved-space or garage-use payments beyond ordinary parking-district taxes?")
                    bullet("If the Final Pattern Book was adopted, incorporated, or used as official downtown guidance, how might it affect the Town Square hotel review for building massing, frontage, pedestrian access, parking placement, streetscape design, and public-space compatibility?")
                    bullet("If the hotel plan differs from Pattern Book expectations, what public finding explains the departure, and who has authority to approve that change?")
                    bullet("Do lot-line changes, easements, shared parking rights, access covenants, development rights, or successor-binding restrictions function like a zoning-lot or development-rights agreement that should be separately summarized for residents?")
                    bullet("Does the executed Master Developer Agreement match the public summaries, and are all exhibits, side agreements, amendments, and closing documents posted together?")
                    bullet("What performance metrics will prove the project delivered revitalization: event use, public-space activity, new revenue, downtown vacancy reduction, parking performance, maintenance quality, and resident affordability?")
                    bullet("Who reports those metrics, how often are they published, and what happens if the developer or Town misses a milestone?")
                    bullet("Has the Town modeled whether current redevelopment policy is raising land values, rents, and assessments faster than Riverhead residents and local workers can afford?")
                    bullet("What year-round affordable housing, workforce housing, or senior housing benefit offsets a policy shift toward hotels, visitor traffic, and higher-end real estate?")
                    bullet("Does the deal leave Riverhead with meaningful hotel competition, or does it concentrate pricing power in a way that could raise room rates, event costs, and visitor-facing prices?")
                    bullet("Are there ownership, management, brand, pricing-software, referral, or tourism-asset relationships among local hotels and attractions that antitrust counsel should review before public incentives strengthen one market position?")
                    bullet("Were professional-service exceptions used sparingly, or did they become the default way to support the deal?")
                    bullet("If any sole-source claim was used anywhere in the chain, where is the vendor's written verification?")
                    bullet("Are appraisals, scoring sheets, amendments, grant obligations, demolition timing, parking assumptions, sewer and water capacity letters, and public-benefit findings linked together?")
                }
                .font(.subheadline)
            }

            Section("Resident test") {
                Text("If officials cannot produce the competition record, exception memo, written sole-source verification, and board-resolution rationale in one plain public packet, the app should treat the deal as a transparency risk until the record is complete.")
                    .font(.callout.weight(.semibold))

                Text("This screen is an oversight checklist, not a legal finding. The standard is simple: if public money, public land, public approvals, or public infrastructure are part of the deal, the public should be able to see why this vendor, why this structure, and why now.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Sources") {
                Button {
                    openURL(procurementCodeURL)
                } label: {
                    Label("Riverhead Code Chapter 115: Procurement Policy", systemImage: "link")
                }

                Button {
                    openURL(petrocelliArticleURL)
                } label: {
                    Label("RiverheadLOCAL: Petrocelli hotel plan review", systemImage: "newspaper")
                }

                Button {
                    openURL(newsdayTownSquareURL)
                } label: {
                    Label("Newsday: Town Square master developer", systemImage: "newspaper")
                }

                Button {
                    openURL(masterDeveloperHearingURL)
                } label: {
                    Label("Riverhead News-Review: master developer hearing", systemImage: "newspaper")
                }

                Button {
                    openURL(riverheadLocalHearingURL)
                } label: {
                    Label("RiverheadLOCAL: qualified and eligible hearing", systemImage: "newspaper")
                }

                Button {
                    openURL(riverheadLocalDesignationURL)
                } label: {
                    Label("RiverheadLOCAL: qualified and eligible designation", systemImage: "newspaper")
                }

                Button {
                    openURL(qualifiedEligibleApprovalURL)
                } label: {
                    Label("Riverhead News-Review: qualified and eligible approval", systemImage: "newspaper")
                }

                Button {
                    openURL(eastEndBeaconApprovalURL)
                } label: {
                    Label("East End Beacon: qualified and eligible vote", systemImage: "newspaper")
                }

                Button {
                    openURL(competitiveBiddingBenchmarkURL)
                } label: {
                    Label("NYSED: competitive bidding benchmark", systemImage: "building.columns")
                }

                Button {
                    openURL(ftcPriceFixingURL)
                } label: {
                    Label("FTC: price-fixing guidance", systemImage: "exclamationmark.shield")
                }

                Button {
                    openURL(petrocelliBoardBioURL)
                } label: {
                    Label("NY Marine Rescue: Joseph Petrocelli board bio", systemImage: "person.text.rectangle")
                }

                Button {
                    openURL(petrocelliBusinessProfileURL)
                } label: {
                    Label("LIBN: Petrocelli business profile", systemImage: "briefcase")
                }

                Button {
                    openURL(zoningLotAgreementURL)
                } label: {
                    Label("K&L Gates: zoning lot agreement concept", systemImage: "square.3.layers.3d")
                }

                Button {
                    openURL(mdaURL)
                } label: {
                    Label("Full Master Developer Agreement (Town PDF)", systemImage: "doc.text")
                }
            }
        }
        .navigationTitle("Procurement Watch")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.caption)
                .foregroundStyle(RiverheadTheme.accent)
                .padding(.top, 2)

            Text(text)
                .foregroundStyle(.secondary)
        }
    }
}

private struct WatchRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(RiverheadTheme.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct FactRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline.weight(.semibold))
            Text(value)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }
}

#Preview("ProcurementPolicyWatchView") {
    NavigationStack {
        ProcurementPolicyWatchView()
    }
}
