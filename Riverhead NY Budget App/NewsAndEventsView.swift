//
//  NewsAndEventsView.swift
//  Riverhead NY Budget App
//
//  Improvements:
//  - Removes dependency on RiverheadURLs
//  - Adds quick actions for News Flash + Calendar
//  - Uses WebContentView for in-app browsing
//
//  Swift 6 • iOS 17+
//

import SwiftUI

struct NewsAndEventsView: View {

    private let newsFlashURL = URL(string: "https://www.townofriverheadny.gov/CivicAlerts.asp?CID=1")!
    private let calendarURL = URL(string: "https://www.townofriverheadny.gov/calendar.aspx")!
    private let agendasURL = URL(string: "https://www.townofriverheadny.gov/agendacenter")! // Official Agenda Center

    var body: some View {
        List {
            Section {
                NavigationLink {
                    WebContentView(url: newsFlashURL, title: "News Flash")
                } label: {
                    row("News Flash", "Official notices and alerts", "megaphone.fill")
                }

                NavigationLink {
                    WebContentView(url: calendarURL, title: "Calendar")
                } label: {
                    row("Calendar", "Meetings and community events", "calendar")
                }

                NavigationLink {
                    WebContentView(url: agendasURL, title: "Agendas & Minutes")
                } label: {
                    row("Agendas & Minutes", "Searchable meeting packets", "doc.text.magnifyingglass")
                }
            } header: {
                Text("Stay up to date")
            } footer: {
                Text("These links open the Town’s official website pages inside the app.")
            }
        }
        .navigationTitle("News & Events")
        .navigationBarTitleDisplayMode(.inline)
        .adMobBannerPlacement(showDebugPlaceholder: true)
    }

    @ViewBuilder
    private func row(_ title: String, _ subtitle: String, _ icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 28)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}
