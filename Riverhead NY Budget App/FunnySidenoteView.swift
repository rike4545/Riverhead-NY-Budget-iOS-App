//
//  FunnySidenoteView.swift
//  Riverhead NY Budget App
//
//  A light, optional detour for local video links.
//

import SwiftUI

struct FunnySidenoteView: View {
    @Environment(\.colorScheme) private var scheme

    private let videos: [FunnySidenoteVideo] = [
        .init(
            title: "Funny Sidenote #1",
            subtitle: "Facebook Reel",
            url: URL(string: "https://www.facebook.com/reel/1298820952361228")!
        ),
        .init(
            title: "Funny Sidenote #2",
            subtitle: "Facebook Reel",
            url: URL(string: "https://www.facebook.com/reel/1951736242149256")!
        )
    ]

    var body: some View {
        List {
            Section {
                header
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section("Videos") {
                ForEach(videos) { video in
                    NavigationLink {
                        WebContentView(url: video.url, title: video.title)
                    } label: {
                        FunnySidenoteVideoRow(video: video)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .contentMargins(.bottom, 18, for: .scrollContent)
        .tint(RiverheadTheme.accent)
        .navigationTitle("Funny Sidenote")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "play.rectangle.on.rectangle.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.16), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Funny Sidenote")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("A quick local-video detour from the budget spreadsheets.")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.82))
                }
            }
        }
        .padding(14)
        .background(RiverheadTheme.headerGradient)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: RiverheadTheme.cardShadow(scheme, elevated: true), radius: 14, x: 0, y: 8)
    }
}

private struct FunnySidenoteVideo: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let url: URL
}

private struct FunnySidenoteVideoRow: View {
    let video: FunnySidenoteVideo

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "play.circle.fill")
                .font(.title3)
                .frame(width: 34, height: 34, alignment: .center)
                .foregroundStyle(RiverheadTheme.brandTeal)
                .background(RiverheadTheme.brandTeal.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(video.title)
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.textPrimary)
                Text(video.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(RiverheadTheme.brandTeal.opacity(0.7))
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(video.title), \(video.subtitle)")
    }
}

#Preview {
    NavigationStack {
        FunnySidenoteView()
    }
}
