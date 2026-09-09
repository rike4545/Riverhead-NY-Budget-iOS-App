//
//  WorkforceByTitleView.swift
//  Riverhead NY Budget App
//
//  How many employees hold each civil-service title, and how each title's
//  headcount has changed year to year (2022 onward). Reads the bundled
//  titles-by-year.json (same data as the web/Android "Workforce by Title" view).
//
//  Swift 6 / iOS 17+
//

import SwiftUI

private struct Wage: Decodable {
    let n: Int
    let hrMin: Double?
    let hrMax: Double?
    let annMin: Int?
    let annMax: Int?
    let hrBasisLow: Int?
    let hrBasisHigh: Int?
    let hrLowLabel: String?
    let hrHighLabel: String?
    let hrDerivedMin: Double?
    let hrDerivedMax: Double?

    private static func hrText(_ lo: Double, _ hi: Double) -> String {
        lo == hi ? String(format: "$%.4f/hr", lo)
                 : String(format: "$%.4f–$%.4f/hr", lo, hi)
    }

    var line: String {
        var parts: [String] = []
        if let lo = hrMin, let hi = hrMax { parts.append(Wage.hrText(lo, hi)) }
        if let lo = annMin, let hi = annMax {
            parts.append(lo == hi ? "$\(lo.formatted())/yr"
                                  : "$\(lo.formatted())–$\(hi.formatted())/yr")
        }
        return parts.isEmpty ? "" : "2026 authorized rate · " + parts.joined(separator: " · ")
    }

    var derivedLine: String {
        guard hrMin == nil, let lo = hrDerivedMin, let hi = hrDerivedMax,
              let loLabel = hrLowLabel, let hiLabel = hrHighLabel else { return "" }
        return String(format: "≈ $%.4f/hr on %@ to $%.4f/hr on %@ — computed by this app, not a published rate",
                      lo, loLabel, hi, hiLabel)
    }
}

private struct TitleRow: Decodable, Identifiable {
    let title: String
    let counts: [String: Int]
    let latest: Int
    let delta: Int
    let wage2026: Wage?
    var id: String { title }
}

private struct TitlesFile: Decodable {
    struct Source: Decodable {
        let title: String
        let url: String
    }

    let years: [Int]
    let note: String
    let source: Source
    let titles: [TitleRow]
}

private enum WorkforceTitleData {
    static let file: TitlesFile? = {
        guard let url = Bundle.main.url(forResource: "titles-by-year", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(TitlesFile.self, from: data)
    }()
}

struct WorkforceByTitleView: View {
    private let file = WorkforceTitleData.file

    @State private var query = ""
    @State private var sort: Sort = .latest

    enum Sort: String, CaseIterable, Identifiable {
        case latest = "Most now"
        case gain = "Biggest ↑"
        case drop = "Biggest ↓"
        case name = "A–Z"
        var id: String { rawValue }
    }

    private var years: [Int] { file?.years ?? [] }
    private var latestYear: Int? { years.last }
    private var latestYearLabel: String { latestYear.map(String.init) ?? "" }

    private var rows: [TitleRow] {
        let all = file?.titles ?? []
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = q.isEmpty ? all : all.filter { $0.title.lowercased().contains(q) }
        switch sort {
        case .latest: return filtered.sorted { $0.latest != $1.latest ? $0.latest > $1.latest : $0.title < $1.title }
        case .gain:   return filtered.sorted { $0.delta > $1.delta }
        case .drop:   return filtered.sorted { $0.delta < $1.delta }
        case .name:   return filtered.sorted { $0.title < $1.title }
        }
    }

    private var distinctLatestTitles: Int {
        (file?.titles ?? []).filter { $0.latest > 0 }.count
    }

    private var latestTitledEmployees: Int {
        (file?.titles ?? []).reduce(0) { $0 + $1.latest }
    }

    private var biggestGain: TitleRow? {
        (file?.titles ?? []).max { $0.delta < $1.delta }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Workforce by Title")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(RiverheadTheme.textPrimary)
                    Text("How many people hold each job title, and how each title's headcount has changed. Titles are available 2022 onward; seasonal roles such as lifeguards and recreation aides run high because everyone paid during the season counts for that year.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
            }

            if file != nil {
                Section("Snapshot") {
                    LabeledContent("Distinct titles (\(latestYearLabel))", value: "\(distinctLatestTitles)")
                    LabeledContent("Employees titled (\(latestYearLabel))", value: "\(latestTitledEmployees)")
                    if let first = years.first, let last = years.last {
                        LabeledContent("Years covered", value: "\(first)–\(last)")
                    }
                    if let gain = biggestGain {
                        LabeledContent("Biggest gain", value: "\(gain.delta > 0 ? "+" : "")\(gain.delta) \(gain.title)")
                    }
                }
            }

            Section {
                Picker("Sort", selection: $sort) {
                    ForEach(Sort.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            Section {
                if rows.isEmpty {
                    Text(file == nil ? "Title data is unavailable." : "No titles match “\(query)”.")
                        .font(.footnote).foregroundStyle(.secondary)
                } else {
                    ForEach(rows) { row in
                        TitleRowView(row: row, years: years, latestYear: latestYearLabel)
                    }
                }
            } header: {
                Text("\(rows.count) of \(file?.titles.count ?? 0) titles")
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    if let note = file?.note { Text(note) }
                    Text("Counts are distinct employees paid under each title that year. The teal line is what the Board's January 2026 salary resolutions actually print. Where the Town publishes only an annual salary, the grey ≈ line is arithmetic by this app rather than a Board-authorized hourly rate: it brackets the annual amount using the applicable workweek assumptions documented by the web app. No inferred hourly figure is presented as an official rate.")
                    if let source = file?.source, let url = URL(string: source.url) {
                        Link("Source: \(source.title) ↗", destination: url)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .searchable(text: $query, prompt: "Search a title (e.g. Police Officer)")
        .navigationTitle("Workforce by Title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TitleRowView: View {
    let row: TitleRow
    let years: [Int]
    let latestYear: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RiverheadTheme.brandNavy)
                Spacer(minLength: 8)
                deltaBadge
            }
            HStack(spacing: 16) {
                ForEach(years, id: \.self) { y in
                    let v = row.counts[String(y)] ?? 0
                    VStack(alignment: .leading, spacing: 1) {
                        Text(String(y)).font(.caption2).foregroundStyle(.secondary)
                        Text(v > 0 ? "\(v)" : "—")
                            .font(.headline.weight(String(y) == latestYear ? .black : .regular))
                            .foregroundStyle(v > 0 ? RiverheadTheme.textPrimary : .secondary)
                    }
                }
            }
            if let w = row.wage2026, !w.line.isEmpty {
                Text(w.line)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RiverheadTheme.brandTeal)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let w = row.wage2026, !w.derivedLine.isEmpty {
                Text(w.derivedLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }

    private var deltaBadge: some View {
        let (label, tint): (String, Color) = {
            if row.delta > 0 { return ("▲ +\(row.delta)", RiverheadTheme.brandTeal) }
            if row.delta < 0 { return ("▼ \(-row.delta)", RiverheadTheme.brandCoral) }
            return ("no change", .secondary)
        }()
        return Text(label)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(tint.opacity(0.16), in: Capsule())
            .foregroundStyle(tint)
    }
}

#Preview {
    NavigationStack { WorkforceByTitleView() }
}
