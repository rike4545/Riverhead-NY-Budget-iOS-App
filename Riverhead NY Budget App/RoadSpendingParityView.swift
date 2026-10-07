//
//  RoadSpendingParityView.swift
//  Riverhead NY Budget App
//
//  Native parity for Riverhead Budget Live's /road-spending/ route.
//
//  The document is fetched from the web app's published canonical JSON rather
//  than restated in Swift. Every figure and every caveat below therefore comes
//  from the same file the web page reads, so the two cannot drift apart — the
//  failure mode that put the iOS meetings bundle eight files behind the web.
//

import SwiftUI

struct RoadSpendingParityDocument: Decodable, Sendable {
    let title: String
    let asOf: String
    let intro: String
    let spending: SourceNote
    let mileage: SourceNote
    let towns: [Town]
    let riverheadMix: [MixLine]
    let caveats: [String]

    struct SourceNote: Decodable, Sendable {
        let source: String
        let detail: String
        let url: String
    }

    struct Town: Decodable, Sendable {
        let town: String
        let highways: Double
        let miles: Double
        let perMile: Double
    }

    struct MixLine: Decodable, Sendable {
        let object: String
        let amount: Double
    }
}

enum RoadSpendingParityClient {
    static let dataURL = URL(string: "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/data/road-spending.json")!
    static let livePageURL = URL(string: "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/road-spending/")!

    static func load() async throws -> RoadSpendingParityDocument {
        var request = URLRequest(url: dataURL)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(RoadSpendingParityDocument.self, from: data)
    }
}

/// Riverhead's standing in the published comparison.
///
/// Computed rather than read from the file: the document happens to arrive
/// sorted by `perMile`, but nothing in the contract promises that, and a
/// resident reading "8th of 10" deserves it to be true of the data actually
/// rendered rather than of the order it happened to be written in.
enum RoadSpendingRanking {
    static func rank(of town: String, in towns: [RoadSpendingParityDocument.Town]) -> Int? {
        let ordered = towns.sorted { $0.perMile > $1.perMile }
        guard let index = ordered.firstIndex(where: { $0.town == town }) else { return nil }
        return index + 1
    }
}

@MainActor
struct NativeRoadSpendingParityView: View {
    @State private var document: RoadSpendingParityDocument?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let document {
                content(document)
            } else if loadFailed {
                WebContentView(url: RoadSpendingParityClient.livePageURL, title: "Road Spending")
            } else {
                ProgressView("Loading canonical road-spending data…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Road Spending")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard document == nil, !loadFailed else { return }
            do {
                document = try await RoadSpendingParityClient.load()
            } catch {
                loadFailed = true
            }
        }
    }

    @ViewBuilder
    private func content(_ data: RoadSpendingParityDocument) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                headerCard(data)
                comparisonCard(data)
                mixCard(data)
                sourcesCard(data)
                caveatsCard(data)
            }
            .padding(16)
        }
    }

    private func headerCard(_ data: RoadSpendingParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.title)
                .font(.headline)
            Text(data.asOf)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(data.intro)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let rank = RoadSpendingRanking.rank(of: "Riverhead", in: data.towns) {
                Divider()
                Text("Riverhead ranks \(rank) of \(data.towns.count) Suffolk towns on spending per maintained mile.")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .roadParityCard()
    }

    private func comparisonCard(_ data: RoadSpendingParityDocument) -> some View {
        let ordered = data.towns.sorted { $0.perMile > $1.perMile }
        let highest = ordered.first?.perMile ?? 0

        return VStack(alignment: .leading, spacing: 10) {
            Text("Spending per maintained mile")
                .font(.headline)

            // Keyed by position: the Sewer Rents collision showed what keying a
            // ForEach on a data field costs when that field repeats.
            ForEach(Array(ordered.enumerated()), id: \.offset) { _, town in
                let isRiverhead = town.town == "Riverhead"
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(town.town)
                            .font(.subheadline.weight(isRiverhead ? .bold : .regular))
                        Spacer(minLength: 8)
                        Text(currency(town.perMile))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                    ProgressView(value: highest > 0 ? town.perMile / highest : 0)
                    Text("\(currency(town.highways)) over \(town.miles, specifier: "%.1f") maintained miles")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 3)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(town.town): \(currency(town.perMile)) per maintained mile")
            }
        }
        .roadParityCard()
    }

    private func mixCard(_ data: RoadSpendingParityDocument) -> some View {
        let total = data.riverheadMix.reduce(0) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 8) {
            Text("What Riverhead's highway spending is made of")
                .font(.headline)

            ForEach(Array(data.riverheadMix.enumerated()), id: \.offset) { _, line in
                HStack(alignment: .firstTextBaseline) {
                    Text(line.object)
                        .font(.subheadline)
                    Spacer(minLength: 8)
                    Text(currency(line.amount))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
            }

            Divider()
            HStack {
                Text("Total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(currency(total))
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
            }
        }
        .roadParityCard()
    }

    private func sourcesCard(_ data: RoadSpendingParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Where these numbers come from")
                .font(.headline)
            sourceBlock("Spending", data.spending)
            Divider()
            sourceBlock("Mileage", data.mileage)
        }
        .roadParityCard()
    }

    private func sourceBlock(_ label: String, _ note: RoadSpendingParityDocument.SourceNote) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(note.source)
                .font(.subheadline.weight(.semibold))
            Text(note.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let url = URL(string: note.url) {
                Link("Open the source", destination: url)
                    .font(.caption.weight(.semibold))
            }
        }
    }

    private func caveatsCard(_ data: RoadSpendingParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What this comparison cannot tell you")
                .font(.headline)
            ForEach(Array(data.caveats.enumerated()), id: \.offset) { _, caveat in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(caveat)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .roadParityCard()
    }

    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

private extension View {
    func roadParityCard() -> some View {
        // Delegates to the shared card so every screen in the app matches
        // and Reduce Transparency is honoured in one place.
        riverheadCard()
    }
}
