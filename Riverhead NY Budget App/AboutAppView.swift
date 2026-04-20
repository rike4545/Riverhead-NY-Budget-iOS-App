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

                Text("Riverhead NY Helper is a community-made app that simply opens public information from townofriverheadny.gov in a mobile-friendly way.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("What this app does")
                        .font(.headline)

                    bullet("Provides quick shortcuts to town website pages like \"How Do I…\", Departments, News Flash, the town calendar, and online payment portals.")
                    bullet("Keeps a consistent Riverhead-inspired look so it feels familiar when moving between the app and the website.")
                    bullet("Offers a handy contact screen with a map and one-tap calling convenience.")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("What this app does NOT do")
                        .font(.headline)

                    bullet("It does not replace any official communication channels of the Town of Riverhead.")
                    bullet("It does not provide legal, financial, or emergency advice.")
                    bullet("It does not modify or control any information hosted on townofriverheadny.gov.")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Unofficial helper, not an official app")
                        .font(.headline)

                    Text("This app is not produced by, affiliated with, or endorsed by the Town of Riverhead, its officials, or its departments. All logos, names, and website content remain the property of their respective owners. For official information or assistance, always rely on townofriverheadny.gov or direct contact with the Town.")
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
