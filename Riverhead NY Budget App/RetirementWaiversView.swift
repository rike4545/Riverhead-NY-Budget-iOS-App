//
//  RetirementWaiversView.swift
//  Riverhead NY Budget App
//
//  Plain-English explainer for NY retirement waivers, with direct source links.
//

import SwiftUI

struct RetirementWaiversView: View {
    private let waiversURL = URL(string: "https://www.seethroughny.net/waivers")!
    private let dataNotesURL = URL(string: "https://www.seethroughny.net/data-notes")!

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Retirement Waivers (NY)")
                        .font(.headline)
                    Text("SeeThroughNY publishes a waiver database for retirees under 65 who applied for or received permission to earn above a salary threshold while collecting a pension.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section("What To Look At") {
                bullet("Status: approved, pending, denied, limited approval, over 65, and related outcomes.")
                bullet("Employer type and agency: narrow to towns and the relevant employer.")
                bullet("Waiver dates: check start/end dates for active or past coverage periods.")
                bullet("Name-level records: verify whether the same retiree appears across periods.")
            }

            Section("Riverhead-Focused Workflow") {
                bullet("Open the Waivers page and set Type of Employer to `Towns`.")
                bullet("Use Agency/Sub Agency filters to isolate Town of Riverhead records (if listed).")
                bullet("Sort by start or end date to review recent activity first.")
                bullet("Use Status + Name together to separate active approvals from closed/denied records.")
            }

            Section("Open Source") {
                NavigationLink {
                    WebContentView(url: waiversURL, title: "Retirement Waivers")
                } label: {
                    Label("SeeThroughNY Waivers", systemImage: "link")
                }

                Link(destination: waiversURL) {
                    Label("Open in Safari", systemImage: "safari")
                }

                Link(destination: dataNotesURL) {
                    Label("SeeThroughNY Data Notes", systemImage: "doc.text")
                }
            }

            Section("Notes") {
                Text("This app is not an official legal or pension authority. Use source documents and agency guidance for final determinations.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Retirement Waivers")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .padding(.top, 6)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        RetirementWaiversView()
    }
}
