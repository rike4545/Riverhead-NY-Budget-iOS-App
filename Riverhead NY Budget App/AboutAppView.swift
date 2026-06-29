//
//  AboutAppView.swift
//  Riverhead NY
//
//  Created by Bryan on 11/22/25.
//


//
//  AboutAppView.swift
//  Riverhead NY Helper
//
//  Explicit “unofficial helper” explanation.
//

import SwiftUI

@MainActor
struct AboutAppView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("About This App")
                    .font(.title.bold())
                    .foregroundColor(RiverheadTheme.primaryBlue)

                Text("Use this app to share, analyze, and compare public data from governmental entities throughout New York, with a particular focus on the Town of Riverhead.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("What this app does")
                        .font(.headline)

                    bullet("Organizes public budget, tax, campaign-finance, procurement, project, payroll, pension, contract, and civic oversight information into easier-to-read views.")
                    bullet("Links back to official government sources, public records, and other transparency tools so residents can check the underlying material.")
                    bullet("Helps residents compare trends, share context, and prepare better questions before meetings, hearings, and elections.")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("What this app does NOT do")
                        .font(.headline)

                    bullet("It does not replace any official communication channels of the Town of Riverhead.")
                    bullet("It does not provide legal, financial, or emergency advice.")
                    bullet("It does not modify or control any information hosted by the Town, New York State, campaign-finance portals, or third-party transparency sites.")
                    bullet("It cannot guarantee that source data is accurate, complete, current, or interpreted the same way an official agency would interpret it.")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("No campaign or candidate affiliation")
                        .font(.headline)

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "hand.raised.fill")
                            .font(.title3)
                            .foregroundStyle(RiverheadTheme.primaryBlue)
                        Text("This app is not endorsed by, financed by, affiliated with, or produced on behalf of any political campaign, candidate, political party, political action committee, or elected official. It is an independent, community-built civic tool. No candidate or campaign has paid for, directed, or approved any content in this app.")
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(RiverheadTheme.primaryBlue.opacity(0.07))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(RiverheadTheme.primaryBlue.opacity(0.18), lineWidth: 1)
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Unofficial research tool, not an official app")
                        .font(.headline)

                    Text("The information in this app comes from official government sources and public transparency resources, but the developer cannot guarantee data accuracy or completeness. This app is not produced by, affiliated with, or endorsed by the Town of Riverhead, its officials, or its departments. All logos, names, and website content remain the property of their respective owners. For official information or assistance, always rely on the original agency source or direct contact with the responsible government office.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 20)
            }
            .padding()
        }
        .background(RiverheadTheme.background)
        .navigationTitle("About This App")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
        .font(.subheadline)
    }
}
