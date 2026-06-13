//
//  TownSquareProjectHubView.swift
//  Riverhead NY Budget App
//
//  Created by Bryan on 1/21/26.
//


import SwiftUI

@MainActor
struct TownSquareProjectHubView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section("Town Square") {
                Text("Town Square is a public/private downtown redevelopment project. This hub collects the official documents, planning materials, and app tools that explain what the Town agreed to, what the developer is expected to build, and what public costs or risks residents should track.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Downtown revitalization context") {
                Text("Town Square sits inside a larger downtown plan. The documents below cover the square itself, nearby infrastructure, riverfront amenities, design plans, and transit-oriented redevelopment.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    bullet("**Town Square documents:** Q&E packet with \(TownSquareCoreTerms.qeBudgetDate) budget evidence, presentation materials, and the Master Developer Agreement.")
                    bullet("**Downtown committee record:** the Town's Downtown Revitalization Committee page lists agendas/minutes, members, Town liaisons, the Town Board liaison, mission statement, and related pattern-book documents.")
                    bullet("**Downtown grant pipeline:** reporting said Riverhead secured money for sewer, water, road, and amphitheater work.")
                    bullet("**Peconic River corridor:** the Town's corridor page ties downtown redevelopment to the Route 25/Peconic River BOA study, traffic, parking, pedestrian, bicycle, and historic-structure materials.")
                    bullet("**Planning materials:** Vision Plan, Final Pattern Book, corridor studies, and East Main Street Urban Renewal plan.")
                    bullet("**Transit materials:** Railroad Avenue TOD plan, RFQ, and First Mile/Last Mile pilot study.")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.vertical, 2)
            }

            Section("Latest hotel review") {
                Text("RiverheadLOCAL's May 14, 2026 evening story says the five-story, 94-room Peconic River Hotel at 117-127 East Main Street received a warm Town Board reception. It now goes to a special-meeting public hearing on its site plan and special permit on \(TownSquareCoreTerms.latestHotelProposalPublicHearingDate) at \(TownSquareCoreTerms.latestHotelProposalHearingTime). The review issues include water and sewer capacity, traffic flow, valet operations, off-site parking, and whether approval materials stay easy for residents to inspect.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    bullet("The proposal reportedly includes a \(TownSquareCoreTerms.latestHotelProposalBrand) boutique hotel, restaurant/bar, terrace, coffee shop, retail space, hotel lounge, fitness facilities, and \(TownSquareCoreTerms.latestHotelProposalSuites) fifth-floor suites.")
                    bullet("The revised plan removes the previously planned \(TownSquareCoreTerms.condoUnits) condominium units, which makes the site-plan change important even if the broader Town Square deal remains the same.")
                    bullet("Only nine on-site parking spaces were reported, reserved for staff; guest parking would rely on valet/off-site spaces and the planned First Street garage.")
                    bullet("Board signals to track: Joann Waski praised Petrocelli's downtown investment; Ken Rothwell asked for more detailed vehicle-circulation and drop-off drawings.")
                    bullet("Planning review should make utility-capacity letters, traffic assumptions, public-parking impacts, and hearing materials easy to inspect.")
                    bullet("SEQRA scope to watch: the Town's consultant recommended a limited review on the theory that Town Square is a flood-mitigation project. A 94-room hotel is its own action; residents can ask why its water, sewer, and traffic impacts are not segmented under 6 NYCRR 617.3(g).")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Section("Pattern Book Question") {
                Text("Residents should ask whether the Final Pattern Book was formally adopted, incorporated by reference, or used as a review guide for Town Square. That answer affects how much weight it should carry in the Petrocelli hotel review.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    bullet("If adopted as a binding or official design standard, the review should explain how the hotel matches the Pattern Book's frontage, massing, height, pedestrian-realm, parking, and public-space expectations.")
                    bullet("If it is advisory only, the Town should still say which Pattern Book principles are being followed, which are being waived or modified, and why.")
                    bullet("Any consistency finding should be public before approvals, especially where the project relies on off-site parking, valet circulation, public infrastructure, and a major riverfront public-space setting.")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Section("In-app analysis") {
                NavigationLink {
                    TownSquareBANImpactView(accent: .indigo)
                } label: {
                    Label("BAN Impact Calculator", systemImage: "percent")
                }

                NavigationLink {
                    RBTownSquareQEBudgetMathView()
                } label: {
                    Label("Q&E Budget Math Checker", systemImage: "function")
                }

                NavigationLink {
                    RBTownSquareSweetheartDealAuditView()
                } label: {
                    Label("Deal / Risk Scan", systemImage: "checklist")
                }

                NavigationLink {
                    ProcurementPolicyWatchView()
                } label: {
                    Label("Procurement Watch", systemImage: "doc.text.magnifyingglass")
                }
            }

            Section("Official sources") {
                Button {
                    openURL(TownSquareCoreTerms.downtownRevitalizationHubURL)
                } label: {
                    Label("Downtown Revitalization Projects Hub", systemImage: "link")
                }

                Button {
                    openURL(TownSquareCoreTerms.downtownRevitalizationEffortsURL)
                } label: {
                    Label("Downtown Revitalization Efforts", systemImage: "map")
                }

                Button {
                    openURL(TownSquareCoreTerms.downtownRevitalizationCommitteeURL)
                } label: {
                    Label("Downtown Revitalization Committee", systemImage: "person.3.sequence")
                }

                Button {
                    openURL(TownSquareCoreTerms.historicDowntownPeconicRiverCorridorURL)
                } label: {
                    Label("Historic Downtown / Peconic River Corridor", systemImage: "water.waves")
                }

                Button {
                    openURL(TownSquareCoreTerms.planningDepartmentURL)
                } label: {
                    Label("Planning Department", systemImage: "building.columns")
                }

                Button {
                    openURL(TownSquareCoreTerms.qeDocumentsURL)
                } label: {
                    Label("Town Square Q&E Documents - \(TownSquareCoreTerms.qeBudgetDate) (PDF)", systemImage: "doc.richtext")
                }

                Button {
                    openURL(TownSquareCoreTerms.qePresentationURL)
                } label: {
                    Label("Town Square Q&E Presentation (PDF)", systemImage: "play.rectangle")
                }

                Button {
                    openURL(TownSquareCoreTerms.downtownVisionPlanURL)
                } label: {
                    Label("Vision Plan (PDF)", systemImage: "map")
                }

                Button {
                    openURL(TownSquareCoreTerms.downtownPatternBookURL)
                } label: {
                    Label("Final Pattern Book (PDF)", systemImage: "books.vertical")
                }

                Button {
                    openURL(TownSquareCoreTerms.railroadTODPlanURL)
                } label: {
                    Label("Railroad Avenue TOD Plan (PDF)", systemImage: "tram")
                }

                Button {
                    openURL(TownSquareCoreTerms.firstMileLastMileStudyURL)
                } label: {
                    Label("First Mile / Last Mile Pilot Study (PDF)", systemImage: "figure.walk")
                }

                Button {
                    openURL(TownSquareCoreTerms.eastMainUrbanRenewalPlanURL)
                } label: {
                    Label("East Main Street Urban Renewal Plan (PDF)", systemImage: "building.2")
                }

                Button {
                    openURL(TownSquareCoreTerms.railroadTODRFQURL)
                } label: {
                    Label("Railroad Avenue TOD RFQ (PDF)", systemImage: "doc.text.magnifyingglass")
                }

                Button {
                    openURL(TownSquareCoreTerms.mdaPublicURL)
                } label: {
                    Label("Master Developer Agreement (PDF)", systemImage: "doc.text")
                }

                Button {
                    openURL(TownSquareCoreTerms.downtownGrantArticleURL)
                } label: {
                    Label("Downtown Grants Coverage", systemImage: "newspaper")
                }

                Button {
                    openURL(TownSquareCoreTerms.latestHotelPlanReviewArticleURL)
                } label: {
                    Label("Latest Petrocelli Hotel Review Coverage", systemImage: "newspaper")
                }

                Button {
                    openURL(TownSquareCoreTerms.latestHotelHearingNoticeURL)
                } label: {
                    Label("June 10 Hotel Hearing Notice & Documents (CivicClerk)", systemImage: "doc.text.magnifyingglass")
                }
            }
        }
        .navigationTitle("Town Square")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bullet(_ text: String) -> Text {
        Text("• ") + Text(.init(text))
    }
}
