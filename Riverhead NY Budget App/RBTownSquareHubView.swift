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
                    Text("How the pieces connect")
                        .font(.headline)

                    Text("Use the executed MDA for the acquisition terms, the Lease Amendment for the BAN/lease payment schedule, and the Q&E packet for budget evidence and internal math checks.")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        bullet("**MDA** → purchase price, 5% down payment, credits/grants, O&M responsibilities.")
                        bullet("**Lease Amendment** → BAN year schedule + lease payments meant to cover financing timing.")
                        bullet("**Q&E packet** → budget table evidence (sources/uses) and reconciliation questions.")
                        bullet("**Tools below** → consistent calculators that reference the same constants.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Project snapshot") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Town Square is not just a concept plan. The app now separates the official executed-MDA terms from the later reported full construction-phase buildout.")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        bullet("**Current reported buildout:** $\(Int(TownSquareCoreTerms.currentReportedProjectCost).formatted()) total project cost, up to \(TownSquareCoreTerms.currentReportedHotelRoomsMax) hotel rooms, \(TownSquareCoreTerms.currentReportedCondoUnits) condos, \(TownSquareCoreTerms.currentReportedUndergroundParkingSpots) underground parking spaces, and a reported \(TownSquareCoreTerms.currentReportedCompletionYear) completion target.")
                        bullet("**Reported external support:** $\(Int(TownSquareCoreTerms.currentReportedDRIGrant).formatted()) DRI, $\(Int(TownSquareCoreTerms.currentReportedAdditionalStateSupport).formatted()) in additional state support, and a referenced $\(Int(TownSquareCoreTerms.currentReportedFederalRaiseGrant).formatted()) federal RAISE grant.")
                        bullet("**Executed MDA terms (\(TownSquareCoreTerms.mdaExecutionMonthYear))**: $\(Int(TownSquareCoreTerms.purchasePrice).formatted()) purchase price, 5% down payment, up to $\(Int(TownSquareCoreTerms.totalGrantCommitments).formatted()) in listed grant credits if already paid to the Town, and an official program description of up to \(TownSquareCoreTerms.hotelRoomsMax) hotel rooms plus \(TownSquareCoreTerms.condoUnits) condos.")
                        bullet("**2022 debt activity:** audited statements say the Town refunded $\(Int(TownSquareCoreTerms.refundedBANsDuring2022).formatted()) of BANs for acquisition and improvement of land for the downtown Town Square project.")
                        bullet("**2024 debt snapshot:** the AFR shows one Town Square BAN issued \(TownSquareCoreTerms.townSquareBANIssueDate2021) maturing \(TownSquareCoreTerms.townSquareBANMaturityDate2025) with a $\(Int(TownSquareCoreTerms.outstandingBANBalance2024).formatted()) ending balance after $\(Int(TownSquareCoreTerms.principalPaidOnOutstandingBAN2024).formatted()) of principal paid in 2024.")
                        bullet("**Separate note paid off:** another Town Square BAN issued \(TownSquareCoreTerms.retiredTownSquareBANIssueDate2021) matured \(TownSquareCoreTerms.retiredTownSquareBANMaturityDate2024) and was reported at $0 ending balance after $\(Int(TownSquareCoreTerms.retiredTownSquareBAN2024).formatted()) of principal paid.")
                        bullet("**Recurring Town cost:** the MDA also references a $\(Int(TownSquareCoreTerms.townSquareOMAnnualFee).formatted()) annual O&M obligation for \(TownSquareCoreTerms.townSquareOMTermYears) years.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Fund balance lens") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Town Square matters to fund balance because any choice to cash-fund more of the project, cover overruns, or absorb financing gaps with reserves reduces the General Fund cushion.")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        bullet("Riverhead's policy floor used elsewhere in the app is **15% of operating appropriations** for the General Fund.")
                        bullet("If a proposed appropriation would push projected fund balance below that floor, the Town's policy says the **Town Board should adopt a resolution** approving the draw.")
                        bullet("That means the real resident question is not just “is the project expensive?” but also “what funding source is being used, and does it require a board-authorized reserve draw?”")
                        bullet("Using debt preserves more near-term reserves but adds recurring debt service. Using fund balance avoids new borrowing but permanently lowers the reserve cushion unless it is rebuilt later.")
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
            }

            Section("Key numbers (at a glance)") {
                keyRow("Reported full project cost", TownSquareCoreTerms.currentReportedProjectCost.currency0)
                keyRow("Reported DRI grant", TownSquareCoreTerms.currentReportedDRIGrant.currency0)
                keyRow("Purchase price", TownSquareCoreTerms.purchasePrice.currency0)
                keyRow("Down payment (5%)", TownSquareCoreTerms.downPaymentAmount.currency0)
                keyRow("Grant commitments listed", TownSquareCoreTerms.totalGrantCommitments.currency0)
                keyRow("2024 Town Square BAN balance", TownSquareCoreTerms.outstandingBANBalance2024.currency0)
                keyRow("O&M fee", "\(TownSquareCoreTerms.townSquareOMAnnualFee.currency0)/yr × \(TownSquareCoreTerms.townSquareOMTermYears)y")
                keyRow("Program", "Reported buildout: up to \(TownSquareCoreTerms.currentReportedHotelRoomsMax) hotel rooms + \(TownSquareCoreTerms.currentReportedCondoUnits) condos")
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
}
