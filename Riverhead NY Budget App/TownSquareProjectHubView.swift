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
                Text("Central hub for Town Square documents, downtown revitalization planning materials, and your in-app analysis tools.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Downtown revitalization context") {
                Text("The Town's Downtown Revitalization Projects page groups Town Square with the broader planning and redevelopment materials shaping downtown Riverhead.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    bullet("**Town Square-specific materials:** Q&E documents and the Town Square presentation.")
                    bullet("**Downtown grant pipeline:** late-2025 reporting said Riverhead secured just over $3.5M for The Vue sewer, water, and road infrastructure plus $675K more for the riverfront amphitheater.")
                    bullet("**Downtown planning materials:** Vision Plan, Final Pattern Book, and East Main Street Urban Renewal plan.")
                    bullet("**Transit-oriented redevelopment materials:** Railroad Avenue TOD plan, RFQ, and First Mile/Last Mile pilot study.")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.vertical, 2)
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
            }

            Section("Official sources") {
                Button {
                    openURL(TownSquareCoreTerms.downtownRevitalizationHubURL)
                } label: {
                    Label("Downtown Revitalization Projects Hub", systemImage: "link")
                }

                Button {
                    openURL(TownSquareCoreTerms.qeDocumentsURL)
                } label: {
                    Label("Town Square Q&E Documents (PDF)", systemImage: "doc.richtext")
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
            }
        }
        .navigationTitle("Town Square")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bullet(_ text: String) -> Text {
        Text("• ") + Text(.init(text))
    }
}
