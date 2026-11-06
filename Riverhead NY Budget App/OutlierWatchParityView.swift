import SwiftUI
import Foundation

enum OutlierWatchParityLogic {
    static let percentThreshold = 20.0
    static let dollarThreshold = 100_000.0

    static func isOutlier(dollarChange: Double, percentChange: Double?) -> Bool {
        guard let percentChange else { return false }
        return abs(percentChange) >= percentThreshold && abs(dollarChange) >= dollarThreshold
    }
}

private struct OutlierHistoryDocument: Decodable, Sendable {
    struct Source: Decodable, Sendable {
        let title: String
        let url: String
    }

    struct FundYear: Decodable, Sendable {
        let appropriations: Double
    }

    struct Fund: Decodable, Sendable {
        let code: String
        let name: String
        let years: [String: FundYear]
        // Span-wide figures the web ETL already computes. This view derives
        // year-over-year changes itself, which is a different measure; these
        // are first-to-last across the whole published range, so they are
        // context rather than a duplicate of anything calculated here.
        //
        // All four are optional on purpose. They are present on all 19 funds
        // today, but a non-optional field that the web later stops publishing
        // throws the whole document away and the native view silently becomes
        // its web fallback — which has already happened once, on /tax-bill/.
        let firstYear: Int?
        let lastYear: Int?
        let totalChange: Double?
        let totalChangePct: Double?
    }

    /// Town-wide appropriations per year, across every fund.
    struct TownTotal: Decodable, Sendable {
        let appropriations: Double
        let fundCount: Int
    }

    let source: Source
    let note: String
    let years: [Int]
    let funds: [Fund]
    let townTotals: [String: TownTotal]?
}

private struct OutlierFundChange: Identifiable, Sendable {
    let code: String
    let name: String
    let fromYear: Int
    let toYear: Int
    let prior: Double
    let current: Double
    let dollarChange: Double
    let percentChange: Double?
    let spanChange: Double?
    let spanChangePct: Double?
    let spanFirstYear: Int?
    let spanLastYear: Int?

    var id: String { "\(code)|\(fromYear)|\(toYear)" }
    var transition: String { "\(fromYear)→\(toYear)" }

    /// "2020→2026", when the document published both ends of the range.
    var spanLabel: String? {
        guard let spanFirstYear, let spanLastYear else { return nil }
        return "\(spanFirstYear)→\(spanLastYear)"
    }
}

private enum OutlierWatchParityClient {
    private static let candidates = [
        "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/data/history/fund-appropriations.json",
        "https://raw.githubusercontent.com/rike4545/Riverhead-NY-Budget-Web-App/main/web/public/data/history/fund-appropriations.json"
    ]

    static func load() async throws -> OutlierHistoryDocument {
        var lastError: Error?
        for candidate in candidates {
            guard let url = URL(string: candidate) else { continue }
            do {
                var request = URLRequest(url: url)
                request.cachePolicy = .returnCacheDataElseLoad
                request.timeoutInterval = 20
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      (200..<300).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode(OutlierHistoryDocument.self, from: data)
            } catch {
                lastError = error
            }
        }
        throw lastError ?? URLError(.cannotLoadFromNetwork)
    }
}

@MainActor
struct NativeOutlierWatchView: View {
    @State private var document: OutlierHistoryDocument?
    @State private var selectedTransition = "All years"
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var didLoad = false

    private var allChanges: [OutlierFundChange] {
        guard let document else { return [] }
        return document.funds.flatMap { fund in
            document.years.dropFirst().enumerated().compactMap { index, toYear in
                let fromYear = document.years[index]
                guard let prior = fund.years[String(fromYear)]?.appropriations,
                      let current = fund.years[String(toYear)]?.appropriations else { return nil }
                let dollarChange = current - prior
                let percentChange = prior == 0 ? nil : (dollarChange / prior) * 100
                return OutlierFundChange(
                    code: fund.code,
                    name: fund.name,
                    fromYear: fromYear,
                    toYear: toYear,
                    prior: prior,
                    current: current,
                    dollarChange: dollarChange,
                    percentChange: percentChange,
                    spanChange: fund.totalChange,
                    spanChangePct: fund.totalChangePct,
                    spanFirstYear: fund.firstYear,
                    spanLastYear: fund.lastYear
                )
            }
        }
    }

    private var outliers: [OutlierFundChange] {
        allChanges
            .filter {
                OutlierWatchParityLogic.isOutlier(
                    dollarChange: $0.dollarChange,
                    percentChange: $0.percentChange
                )
            }
            .sorted { abs($0.dollarChange) > abs($1.dollarChange) }
    }

    private var transitions: [String] {
        guard let document else { return [] }
        return document.years.dropFirst().enumerated().map { index, year in
            "\(document.years[index])→\(year)"
        }
    }

    /// Town-wide appropriations at both ends of the published range. Comes
    /// from the document's `townTotals`, not from summing `funds`, so it stays
    /// whatever the web ETL says the town total is.
    private var townSpan: (first: Int, last: Int, change: Double, percent: Double?)? {
        guard let document,
              let totals = document.townTotals,
              let firstYear = document.years.first,
              let lastYear = document.years.last,
              let from = totals[String(firstYear)]?.appropriations,
              let to = totals[String(lastYear)]?.appropriations
        else { return nil }
        let change = to - from
        return (firstYear, lastYear, change, from == 0 ? nil : (change / from) * 100)
    }

    private var visibleOutliers: [OutlierFundChange] {
        selectedTransition == "All years"
            ? outliers
            : outliers.filter { $0.transition == selectedTransition }
    }

    var body: some View {
        Group {
            if let document {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Outlier Watch")
                                .font(.title3.weight(.bold))
                            Text("Riverhead's \(document.funds.count) town funds, checked year over year against their own adopted-budget history. A flag is a place to ask a question—not proof of a problem.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("A fund is flagged only when appropriations move at least \(Int(OutlierWatchParityLogic.percentThreshold))% and at least \(outlierMoney(OutlierWatchParityLogic.dollarThreshold)) from one adopted budget to the next.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    Section("Snapshot") {
                        LabeledContent("Fund-year comparisons", value: "\(allChanges.count)")
                        LabeledContent("Flagged as outliers", value: "\(outliers.count)")
                        if let biggest = outliers.first {
                            VStack(alignment: .leading, spacing: 2) {
                                LabeledContent("Largest flagged swing", value: outlierMoney(abs(biggest.dollarChange)))
                                Text("\(biggest.name) · \(biggest.transition)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if let span = townSpan {
                            let percent = span.percent.map {
                                " (" + ($0 >= 0 ? "+" : "") + String(format: "%.1f", $0) + "%)"
                            } ?? ""
                            VStack(alignment: .leading, spacing: 2) {
                                LabeledContent(
                                    "Town-wide, all funds",
                                    value: outlierSignedMoney(span.change) + percent
                                )
                                Text(verbatim: "Every fund together, \(String(span.first)) to \(String(span.last)) — the baseline a single fund's swing sits against.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Section("Year range") {
                        Picker("Transition", selection: $selectedTransition) {
                            Text("All years (\(outliers.count))").tag("All years")
                            ForEach(transitions, id: \.self) { transition in
                                let count = outliers.filter { $0.transition == transition }.count
                                Text("\(transition) (\(count))").tag(transition)
                            }
                        }
                    }

                    Section("\(visibleOutliers.count) flagged fund-year\(visibleOutliers.count == 1 ? "" : "s")") {
                        if visibleOutliers.isEmpty {
                            Text("No flagged changes for this range.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(visibleOutliers) { outlier in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(alignment: .firstTextBaseline) {
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(outlier.name)
                                                .font(.subheadline.weight(.bold))
                                            Text(outlier.code)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(outlier.transition)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }

                                    HStack {
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text("Prior").font(.caption2).foregroundStyle(.secondary)
                                            Text(outlierMoney(outlier.prior)).font(.caption.monospacedDigit())
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 1) {
                                            Text("Current").font(.caption2).foregroundStyle(.secondary)
                                            Text(outlierMoney(outlier.current)).font(.caption.monospacedDigit())
                                        }
                                    }

                                    HStack {
                                        Text(outlierSignedMoney(outlier.dollarChange))
                                            .font(.subheadline.monospacedDigit().weight(.bold))
                                            .foregroundStyle(outlier.dollarChange >= 0 ? RiverheadTheme.brandCoral : RiverheadTheme.brandTeal)
                                        Spacer()
                                        if let percentChange = outlier.percentChange {
                                            Text("\(percentChange >= 0 ? "+" : "")\(percentChange, specifier: "%.1f")%")
                                                .font(.subheadline.monospacedDigit().weight(.bold))
                                                .foregroundStyle(percentChange >= 0 ? RiverheadTheme.brandCoral : RiverheadTheme.brandTeal)
                                        } else {
                                            Text("—").foregroundStyle(.secondary)
                                        }
                                    }

                                    if let spanLabel = outlier.spanLabel, let spanChange = outlier.spanChange {
                                        let percent = outlier.spanChangePct.map {
                                            " (" + ($0 >= 0 ? "+" : "") + String(format: "%.1f", $0) + "%)"
                                        } ?? ""
                                        Text(verbatim: "Whole range " + spanLabel + ": " + outlierSignedMoney(spanChange) + percent)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 3)
                            }
                        }
                    }

                    Section("How to read this") {
                        Text("The dual threshold avoids two common false alarms: percentage-only rules overreact to tiny funds, while dollar-only rules would flag the General Fund repeatedly simply because it is much larger. Large changes can have ordinary explanations such as debt payoff, contracts, grants, or one-time capital activity.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Section("Source") {
                        Text(document.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let url = URL(string: document.source.url) {
                            Link("\(document.source.title) ↗", destination: url)
                                .font(.caption.weight(.semibold))
                        }
                        Text("This is the same normalized fund-appropriations history used by native Budget Compare and the web Outlier Watch calculation.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .listStyle(.insetGrouped)
            } else if isLoading {
                ProgressView("Checking budget-history outliers…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "Outlier data unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError ?? "The canonical budget-history dataset could not be loaded.")
                )
            }
        }
        .navigationTitle("Outlier Watch")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadIfNeeded() }
        .refreshable { await load(force: true) }
    }

    private func loadIfNeeded() async {
        guard !didLoad else { return }
        await load(force: false)
    }

    private func load(force: Bool) async {
        guard force || document == nil else { return }
        isLoading = true
        loadError = nil
        do {
            document = try await OutlierWatchParityClient.load()
            didLoad = true
            if selectedTransition != "All years", !transitions.contains(selectedTransition) {
                selectedTransition = "All years"
            }
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }
}

private func outlierMoney(_ value: Double) -> String {
    value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
}

private func outlierSignedMoney(_ value: Double) -> String {
    let prefix = value > 0 ? "+" : value < 0 ? "−" : ""
    return prefix + outlierMoney(abs(value))
}
