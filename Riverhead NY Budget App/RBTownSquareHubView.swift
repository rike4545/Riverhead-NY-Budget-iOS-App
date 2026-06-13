//
//  RBTownSquareHubView.swift
//  Riverhead NY Budget App
//
//  Created by Bryan on 1/21/26.
//


//
//  RBTownSquareHubView.swift
//  Riverhead NY Budget App
//
//  Town Square “Start here” hub that links the three tools + sources.
//  Swift 6 • iOS 17+
//

import SwiftUI

@MainActor
struct RBTownSquareHubView: View {

    @Environment(\.openURL) private var openURL

    var accent: Color = .indigo

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Start Here")
                        .font(.headline)

                    Text("Town Square is a downtown redevelopment deal that combines public land, a new public square, private hotel/restaurant/retail construction, grants, debt timing, and long-term operations. This page separates the public agreement from later project announcements so residents can see what is actually in the deal.")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        bullet("**Master Developer Agreement:** the main contract naming the developer and setting land-sale, grant-credit, construction-management, and operation terms.")
                        bullet("**Downtown committee record:** the Town's committee page is where residents can check agendas, minutes, members, liaisons, mission language, and pattern-book documents.")
                        bullet("**BAN / debt timing:** short-term borrowing used while the Town carries acquisition or project costs before final repayment.")
                        bullet("**Q&E packet:** the budget evidence package showing sources, uses, and math that should reconcile back to Town resolutions.")
                        bullet("**Tools below:** calculators and checklists that turn those documents into resident-friendly questions.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Project snapshot") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The simplest way to read the project is in two layers: the signed agreement controls the land and deal terms, while later public reporting describes the bigger buildout residents expect to see downtown.")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        bullet("**Signed deal terms:** \(TownSquareCoreTerms.mdaExecutionMonthYear) agreement; $\(Int(TownSquareCoreTerms.purchasePrice).formatted()) land purchase price; 5% down payment; up to $\(Int(TownSquareCoreTerms.totalGrantCommitments).formatted()) in listed grant credits if already paid to the Town.")
                        bullet("**Public/private buildout:** later reporting described a $\(Int(TownSquareCoreTerms.currentReportedProjectCost).formatted()) construction-phase project with a \(TownSquareCoreTerms.currentReportedCompletionYear) target. A newer May 2026 site-plan article describes a \(TownSquareCoreTerms.latestHotelProposalRooms)-room hotel proposal.")
                        bullet("**Outside funding:** reporting references a $\(Int(TownSquareCoreTerms.currentReportedDRIGrant).formatted()) DRI grant, $\(Int(TownSquareCoreTerms.currentReportedAdditionalStateSupport).formatted()) in additional state support, and a $\(Int(TownSquareCoreTerms.currentReportedFederalRaiseGrant).formatted()) federal RAISE grant.")
                        bullet("**Debt already used:** audited statements show $\(Int(TownSquareCoreTerms.refundedBANsDuring2022).formatted()) of BANs refunded in 2022 for downtown Town Square land acquisition and improvement.")
                        bullet("**2024 debt snapshot:** the AFR shows one Town Square note with a $\(Int(TownSquareCoreTerms.outstandingBANBalance2024).formatted()) ending balance and another Town Square note paid down to zero.")
                        bullet("**Ongoing obligation:** the agreement references a $\(Int(TownSquareCoreTerms.townSquareOMAnnualFee).formatted()) annual operation-and-management fee for \(TownSquareCoreTerms.townSquareOMTermYears) years.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Current Hotel Plan Review") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("RiverheadLOCAL reported on May 14, 2026 that Petrocelli's Peconic River Hotel plan received a warm Town Board reception. It now goes to a special-meeting public hearing on the site plan and special permit on \(TownSquareCoreTerms.latestHotelProposalPublicHearingDate) at \(TownSquareCoreTerms.latestHotelProposalHearingTime). This is a site-plan and special-permit review layer, not the same thing as the executed Master Developer Agreement.")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        bullet("**Hotel scale:** \(TownSquareCoreTerms.latestHotelProposalStories) stories, \(TownSquareCoreTerms.latestHotelProposalRooms) rooms, and about \(TownSquareCoreTerms.latestHotelProposalSquareFeet.formatted()) square feet.")
                        bullet("**Program change:** the revised plan removes the prior \(TownSquareCoreTerms.condoUnits) condominium units and builds the fifth floor as \(TownSquareCoreTerms.latestHotelProposalSuites) suites with balconies or terraces.")
                        bullet("**Program:** \(TownSquareCoreTerms.latestHotelProposalBrand) boutique hotel, restaurant/bar with \(TownSquareCoreTerms.latestHotelProposalRestaurantSeats) seats, outdoor terrace, coffee shop, hotel lounge, fitness facilities, and nearly \(TownSquareCoreTerms.latestHotelProposalRetailSquareFeet.formatted()) square feet of retail.")
                        bullet("**Utilities:** reporting says the revised project remains within the prior downtown environmental findings, with the earlier review carrying roughly \(TownSquareCoreTerms.latestHotelProposalSEQRAFlowBenchmarkGallonsPerDay.formatted()) gallons per day of conservative water/wastewater flow for the site area.")
                        bullet("**Parking:** only \(TownSquareCoreTerms.latestHotelProposalOnSiteParkingSpaces) on-site spaces were reported, reserved for staff, while guests would rely on valet/off-site parking behind the Suffolk Theater and eventually the planned First Street garage.")
                        bullet("**Board review signals:** Joann Waski praised Petrocelli's continued downtown investment, while Ken Rothwell asked for more detailed drawings showing circulation and drop-off operations.")
                        bullet("**SEQRA scope to watch:** the Town's consultant recommended a limited review on the theory that Town Square is a flood-mitigation project. A 94-room hotel is its own action — watch for a segmentation question under 6 NYCRR 617.3(g), and ask that Water and Sewer District letters of availability be in the file before any approval.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }

            Section("What Residents Should Watch") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The important question is not just whether Town Square sounds good. It is whether the public costs, private benefits, competition, debt, grants, parking, and operating duties are visible enough for residents to judge the tradeoff.")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        bullet("Does every public dollar have a named funding source?")
                        bullet("Are grant credits, parking costs, and operating fees shown separately from the private hotel/retail investment?")
                        bullet("Can residents compare the master developer deal to what an ordinary competitive process might have produced?")
                        bullet("If the project changes, does the Town update the agreement, budget math, and public performance measures?")
                        bullet("If the Final Pattern Book was adopted or treated as official guidance, does the hotel review show a clear consistency analysis for massing, frontage, streetscape, parking, and public-space design?")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Science Center Civic Action") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The Long Island Science Center issue should be read as part of the same downtown-policy file: the Town Square plan depends on land control, but Riverhead also has a public interest in keeping a visible STEM museum active downtown.")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        bullet("After the \(TownSquareCoreTerms.scienceCenterPublicHearingDate) public hearing, the Town Board voted on \(TownSquareCoreTerms.scienceCenterCondemnationVoteDate) to begin condemnation of the Science Center's \(TownSquareCoreTerms.scienceCenterBuildingAddress) building (the former Swezey's). That vote — not the hearing — is the likely trigger for the EDPL §207 challenge window.")
                        bullet("The Science Center says it wants to move into the building next to Town Square with a 24,000-square-foot museum concept, including classrooms, exhibit space, and a planetarium.")
                        bullet("The companion petition asks Riverhead to avoid eminent domain and work with the Science Center; Change.org showed \(TownSquareCoreTerms.scienceCenterPetitionSignatureCount) verified signatures when checked.")
                        bullet("Resident questions should focus on public purpose, cost, appraisal, relocation or reuse plan, impact on the nonprofit, and whether a negotiated museum-support path is cheaper and better than a taking.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                LinkRow(title: "Petition: Save the Long Island Science Center", url: TownSquareCoreTerms.scienceCenterPetitionURL)
                LinkRow(title: "Science Center public hearing coverage", url: TownSquareCoreTerms.scienceCenterEminentDomainArticleURL)
                LinkRow(title: "Long Island Science Center", url: TownSquareCoreTerms.scienceCenterWebsiteURL)
            }

            Section("Museum Tax Lens") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("A museum tax is not the only answer, but Long Island examples show a concrete policy alternative to repeated crisis fights: voters can be asked whether a cultural or educational institution deserves stable, recurring community support in exchange for public benefits.")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        bullet("**Legal hook:** New York Education Law §253 says the provisions in that library-law part apply equally to libraries, museums, and combined library/museum institutions, which is why museum propositions can be discussed through the library-tax framework.")
                        bullet("Three Village voters are weighing a Long Island Museum proposition for \(TownSquareCoreTerms.longIslandMuseumPropositionAmount.currency0) annually, with public materials describing resident passes, school partnerships, longer hours, and operating support.")
                        bullet("Southold Historical Museum is asking for \(TownSquareCoreTerms.southoldMuseumPropositionAmount.currency0) annually, estimated at about \(TownSquareCoreTerms.southoldMuseumEstimatedHouseholdCost.currency0) per household per year, with a community-wide household membership model.")
                        bullet("Rocky Point Historical Society says voters approved \(TownSquareCoreTerms.rockyPointHistoricalAnnualLevy.currency0) annually in 2024 for the Hallock Homestead Museum, estimated at about \(TownSquareCoreTerms.rockyPointHistoricalEstimatedHouseholdCost.currency2) per year for the average homeowner.")
                        bullet("For Riverhead, the policy question is whether a STEM/cultural district support model should be studied before the Town spends money on condemnation, litigation, acquisition, demolition, or replacement public amenities. Any proposal should cite the exact legal authority and ballot language.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                LinkRow(title: "NYS Education Law §253", url: TownSquareCoreTerms.educationLaw253URL)
                LinkRow(title: "Long Island Museum 2026 vote information", url: TownSquareCoreTerms.longIslandMuseumVoteURL)
                LinkRow(title: "Southold Historical Museum budget vote", url: TownSquareCoreTerms.southoldMuseumBudgetVoteURL)
                LinkRow(title: "Rocky Point Historical Society funding note", url: TownSquareCoreTerms.rockyPointHistoricalBudgetVoteURL)
            }

            Section("Fund balance lens") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fund balance is the Town's financial cushion. Town Square affects that cushion if the Town uses reserves to pay costs, cover overruns, or fill timing gaps before grants, sale proceeds, or debt repayment arrive.")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        bullet("Riverhead's policy floor used elsewhere in the app is **15% of operating appropriations** for the General Fund.")
                        bullet("If a proposed appropriation would push projected fund balance below that floor, the Town's policy says the **Town Board should adopt a resolution** approving the draw.")
                        bullet("That means the real resident question is not just “is the project expensive?” but also “what funding source is being used, and does it require a board-authorized reserve draw?”")
                        bullet("Using debt can protect cash in the short run but adds future debt-service payments. Using fund balance avoids borrowing but lowers the reserve cushion unless the Town rebuilds it later.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Analysis tools") {
                NavigationLink {
                    TownSquareBANImpactView(accent: accent)
                } label: {
                    toolRow(
                        title: "BAN Impact & MDA Terms",
                        subtitle: "BAN interest estimator + acquisition math + conversion what-ifs",
                        systemImage: "percent"
                    )
                }

                NavigationLink {
                    RBTownSquareQEBudgetMathView()
                } label: {
                    toolRow(
                        title: "Q&E Budget Check",
                        subtitle: "Arithmetic validation and reconciliation notes",
                        systemImage: "function"
                    )
                }

                NavigationLink {
                    RBTownSquareSweetheartDealAuditView()
                } label: {
                    toolRow(
                        title: "Deal Audit",
                        subtitle: "Risk indicators + math checks (non-accusatory)",
                        systemImage: "checkmark.seal"
                    )
                }
            }

            Section("Primary sources (Town-hosted)") {
                LinkRow(title: "Master Developer Agreement (PDF)", url: TownSquareCoreTerms.mdaPublicURL)
                LinkRow(title: "Town Square Q&E Documents (PDF)", url: TownSquareCoreTerms.qeDocumentsURL)
                LinkRow(title: "Town Square Q&E Presentation (PDF)", url: TownSquareCoreTerms.qePresentationURL)
                LinkRow(title: "Downtown Revitalization Projects (hub)", url: TownSquareCoreTerms.downtownRevitalizationHubURL)
                LinkRow(title: "Downtown Revitalization Efforts", url: TownSquareCoreTerms.downtownRevitalizationEffortsURL)
                LinkRow(title: "Downtown Revitalization Committee", url: TownSquareCoreTerms.downtownRevitalizationCommitteeURL)
                LinkRow(title: "Historic Downtown / Peconic River Corridor", url: TownSquareCoreTerms.historicDowntownPeconicRiverCorridorURL)
                LinkRow(title: "Planning Department", url: TownSquareCoreTerms.planningDepartmentURL)
                LinkRow(title: "Vision Plan (PDF)", url: TownSquareCoreTerms.downtownVisionPlanURL)
                LinkRow(title: "Final Pattern Book (PDF)", url: TownSquareCoreTerms.downtownPatternBookURL)
                LinkRow(title: "Railroad Avenue TOD Plan (PDF)", url: TownSquareCoreTerms.railroadTODPlanURL)
                LinkRow(title: "Railroad Avenue TOD Redevelopment RFQ (PDF)", url: TownSquareCoreTerms.railroadTODRFQURL)
                LinkRow(title: "First Mile / Last Mile Pilot Study (PDF)", url: TownSquareCoreTerms.firstMileLastMileStudyURL)
                LinkRow(title: "East Main Street Urban Renewal Plan (PDF)", url: TownSquareCoreTerms.eastMainUrbanRenewalPlanURL)
                LinkRow(title: "2024 Annual Financial Report Update (PDF)", url: TownSquareCoreTerms.annualFinancialReport2024URL)
                LinkRow(title: "Financial Reports (hub)", url: TownSquareCoreTerms.financialReportsURL)
                LinkRow(title: "2016 Internal Control Report (fund balance policy quote)", url: TownSquareCoreTerms.internalControl2016URL)
                LinkRow(title: "Groundbreaking coverage (News-Review)", url: TownSquareCoreTerms.groundbreakingArticleURL)
                LinkRow(title: "Latest Petrocelli hotel review coverage (RiverheadLOCAL)", url: TownSquareCoreTerms.latestHotelPlanReviewArticleURL)
                LinkRow(title: "June 10 hotel hearing notice & documents (CivicClerk)", url: TownSquareCoreTerms.latestHotelHearingNoticeURL)
                LinkRow(title: "Petition: Revise Riverhead's Fund Balance Policy", url: TownSquareCoreTerms.fundBalancePetitionURL)
                LinkRow(title: "Petition: Save the Long Island Science Center", url: TownSquareCoreTerms.scienceCenterPetitionURL)
                LinkRow(title: "NYS Education Law §253", url: TownSquareCoreTerms.educationLaw253URL)
            }

            Section("Key numbers (at a glance)") {
                keyRow("Reported full project cost", TownSquareCoreTerms.currentReportedProjectCost.currency0)
                keyRow("Reported DRI grant", TownSquareCoreTerms.currentReportedDRIGrant.currency0)
                keyRow("Purchase price", TownSquareCoreTerms.purchasePrice.currency0)
                keyRow("Down payment (5%)", TownSquareCoreTerms.downPaymentAmount.currency0)
                keyRow("Grant commitments listed", TownSquareCoreTerms.totalGrantCommitments.currency0)
                keyRow("2024 Town Square BAN balance", TownSquareCoreTerms.outstandingBANBalance2024.currency0)
                keyRow("O&M fee", "\(TownSquareCoreTerms.townSquareOMAnnualFee.currency0)/yr × \(TownSquareCoreTerms.townSquareOMTermYears)y")
                keyRow("Latest hotel proposal", "\(TownSquareCoreTerms.latestHotelProposalRooms) rooms, \(TownSquareCoreTerms.latestHotelProposalStories) stories")
                keyRow("Hearing (special meeting)", "\(TownSquareCoreTerms.latestHotelProposalPublicHearingDate), \(TownSquareCoreTerms.latestHotelProposalHearingTime)")
            }
        }
        .navigationTitle("Town Square")
        .navigationBarTitleDisplayMode(.inline)
        .tint(accent)
    }

    // MARK: - UI helpers

    private func toolRow(title: String, subtitle: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: systemImage)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func keyRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
            Spacer()
            Text(value).font(.body.weight(.semibold))
        }
    }

    private func bullet(_ text: String) -> Text {
        Text("• ") + Text(.init(text))
    }
}

private struct LinkRow: View {
    let title: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(url.absoluteString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.vertical, 2)
        }
    }
}

private extension Double {
    var currency0: String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.maximumFractionDigits = 0
        nf.minimumFractionDigits = 0
        return nf.string(from: NSNumber(value: self)) ?? "$0"
    }

    var currency2: String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 2
        return nf.string(from: NSNumber(value: self)) ?? "$0.00"
    }
}
