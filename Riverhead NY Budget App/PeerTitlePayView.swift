//
//  PeerTitlePayView.swift
//  Riverhead NY Budget App
//
//  The same job title in Riverhead and its neighbours, Southampton and Southold,
//  at a start, middle and current year (2022, 2024 and 2026). Reads the bundled
//  peer-title-pay.json, built by the website's etl/build_peer_title_pay.py from
//  each town's own salary records: Riverhead's January salary resolutions,
//  Southampton's adopted Salary Charts and Southold's schedules of elected
//  officials' salaries. Every figure is the website's; this view only presents it.
//
//  Swift 5 language mode
//

import Charts
import SwiftUI

// MARK: - Model

struct PeerTitlePayDocument: Decodable, Sendable {
    struct Stat: Decodable, Sendable {
        let year: Int
        let count: Int
        let median: Double
        let low: Double
        let high: Double
    }

    struct TownPoints: Decodable, Sendable {
        let start: Stat?
        let mid: Stat?
        let current: Stat?
        let nominalChangePct: Double?
        let realChangePct: Double?

        struct Labeled: Identifiable, Sendable {
            let point: String
            let stat: Stat
            var id: String { point }
        }

        var stats: [Labeled] {
            [("Start", start), ("Middle", mid), ("Current", current)].compactMap { p in
                p.1.map { Labeled(point: p.0, stat: $0) }
            }
        }
    }

    struct Title: Decodable, Identifiable, Sendable {
        let title: String
        let group: String
        let towns: [String: TownPoints]
        let riverheadVsPct: [String: [String: Double]]
        var id: String { title }
    }

    struct Source: Decodable, Identifiable, Sendable {
        let town: String
        let year: Int
        let title: String
        let url: String?
        let note: String?
        var id: String { "\(town)-\(year)" }
    }

    struct CPIYear: Decodable, Sendable {
        let value: Double
        let months: Int
    }

    struct Summary: Decodable, Sendable {
        let titles: Int
        let comparedWithSouthampton2026: Int
        let riverheadHigherThanSouthampton2026: Int
        let medianRiverheadVsSouthampton2026Pct: Double?
    }

    let points: [String: Int]
    let southoldYears: [String: Int]
    let method: String
    let caveats: [String]
    let sources: [Source]
    let cpi: [String: CPIYear]
    let summary: Summary
    let titles: [Title]

    static let towns = ["Riverhead", "Southampton", "Southold"]

    static let bundled: PeerTitlePayDocument? = {
        guard let url = Bundle.main.url(forResource: "peer-title-pay", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(PeerTitlePayDocument.self, from: data)
    }()
}

// MARK: - List

struct PeerTitlePayView: View {
    private let doc = PeerTitlePayDocument.bundled
    @State private var query = ""
    @State private var group = "All"

    private let groups = ["All", "Elected", "Police", "Civilian"]

    var body: some View {
        List {
            if let doc {
                answerSection(doc)
                Section {
                    Picker("Group", selection: $group) {
                        ForEach(groups, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }
                titlesSection(doc)
                methodSection(doc)
            } else {
                ContentUnavailableView("Neighbouring towns' salaries aren't in this build",
                                       systemImage: "building.2",
                                       description: Text("The app's bundled peer-title-pay.json is missing. The next data sync adds it."))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Same Job, Other Towns")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Search a job title")
    }

    private func answerSection(_ doc: PeerTitlePayDocument) -> some View {
        let s = doc.summary
        return Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("In 2026 Riverhead pays more than Southampton for \(s.riverheadHigherThanSouthampton2026) of the \(s.comparedWithSouthampton2026) job titles both towns fill.")
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                if let m = s.medianRiverheadVsSouthampton2026Pct {
                    Text("For the typical title, Riverhead's median salary is \(pct(abs(m))) \(m < 0 ? "below" : "above") Southampton's. Southold publishes salaries only for elected offices, so it appears there alone.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Label("Riverhead against its neighbours", systemImage: "building.2.fill")
        } footer: {
            Text("Years compared: \(doc.points["start"].map { String($0) } ?? "") (start), \(doc.points["mid"].map { String($0) } ?? "") (middle) and \(doc.points["current"].map { String($0) } ?? "") (current). Southold's start is its \(doc.southoldYears["start"].map { String($0) } ?? "") Preliminary Budget, the nearest it has published.")
        }
    }

    private func titlesSection(_ doc: PeerTitlePayDocument) -> some View {
        let rows = doc.titles.filter { t in
            (group == "All" || t.group == group) &&
                (query.isEmpty || t.title.localizedCaseInsensitiveContains(query))
        }
        return Section {
            if rows.isEmpty {
                Text("No job title matches.").foregroundStyle(.secondary)
            }
            ForEach(rows) { t in
                NavigationLink {
                    PeerTitlePayDetailView(title: t, doc: doc)
                } label: {
                    titleRow(t)
                }
            }
        } header: {
            Text("2026 median salary")
        } footer: {
            Text("The percentage compares Riverhead's 2026 median with Southampton's, or Southold's where Southampton has no match.")
        }
    }

    private func titleRow(_ t: PeerTitlePayDocument.Title) -> some View {
        let peer = t.riverheadVsPct["Southampton"]?["current"] != nil ? "Southampton" : "Southold"
        let gap = t.riverheadVsPct[peer]?["current"]
        return VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(t.title).font(.footnote.weight(.semibold))
                Spacer()
                if let gap {
                    Text(signedPct(gap))
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(gap < 0 ? RiverheadTheme.brandCoral : .green)
                        .monospacedDigit()
                        .accessibilityLabel("Riverhead \(pct(abs(gap))) \(gap < 0 ? "below" : "above") \(peer)")
                }
            }
            Text(PeerTitlePayDocument.towns.compactMap { town in
                t.towns[town]?.current.map { "\(town) \(money($0.median))" }
            }.joined(separator: " · "))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private func methodSection(_ doc: PeerTitlePayDocument) -> some View {
        Section("How this is worked out") {
            Text(doc.method).font(.caption)
            ForEach(doc.caveats, id: \.self) { c in
                Label(c, systemImage: "info.circle").font(.caption)
            }
            ForEach(doc.sources) { s in
                if let u = s.url, let url = URL(string: u) {
                    Link(destination: url) {
                        Label("\(s.title)", systemImage: "doc.text").font(.caption)
                    }
                } else {
                    Label(s.title, systemImage: "doc.text").font(.caption)
                }
            }
        }
    }
}

// MARK: - Detail

struct PeerTitlePayDetailView: View {
    let title: PeerTitlePayDocument.Title
    let doc: PeerTitlePayDocument

    private struct ChartPoint: Identifiable {
        let town: String
        let year: Int
        let median: Double
        var id: String { "\(town)-\(year)" }
    }

    private var chartPoints: [ChartPoint] {
        PeerTitlePayDocument.towns.flatMap { town in
            (title.towns[town]?.stats ?? []).map { ChartPoint(town: town, year: $0.stat.year, median: $0.stat.median) }
        }
    }

    var body: some View {
        List {
            Section {
                Text(summary).font(.subheadline).fixedSize(horizontal: false, vertical: true)
            }
            if chartPoints.count > 1 {
                Section("Median salary by year") {
                    Chart(chartPoints) { p in
                        LineMark(x: .value("Year", p.year), y: .value("Median", p.median))
                            .foregroundStyle(by: .value("Town", p.town))
                            .symbol(by: .value("Town", p.town))
                    }
                    .chartForegroundStyleScale(["Riverhead": RiverheadTheme.brandNavy,
                                                "Southampton": RiverheadTheme.brandGold,
                                                "Southold": RiverheadTheme.brandMint])
                    .chartXAxis {
                        AxisMarks(values: Array(Set(chartPoints.map(\.year))).sorted()) { v in
                            AxisGridLine()
                            AxisValueLabel { if let y = v.as(Int.self) { Text(String(y)) } }
                        }
                    }
                    .frame(height: 200)
                    .accessibilityLabel("Median \(title.title) salary in each town by year")
                }
            }
            ForEach(PeerTitlePayDocument.towns, id: \.self) { town in
                if let pts = title.towns[town] {
                    Section(town) {
                        ForEach(pts.stats) { p in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("\(p.point) · \(String(p.stat.year))").font(.footnote.weight(.semibold))
                                    Spacer()
                                    Text(money(p.stat.median)).font(.footnote.weight(.semibold)).monospacedDigit()
                                }
                                Text(detailLine(p.stat))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            .accessibilityElement(children: .combine)
                        }
                        if let real = pts.realChangePct, let nominal = pts.nominalChangePct,
                           let s = pts.start, let c = pts.current {
                            HStack {
                                Text("\(String(s.year)) to \(String(c.year)), after inflation").font(.footnote)
                                Spacer()
                                Text(signedPct(real))
                                    .font(.footnote.weight(.bold))
                                    .foregroundStyle(real < -2 ? RiverheadTheme.brandCoral : (real > 2 ? .green : .secondary))
                                    .monospacedDigit()
                            }
                            .accessibilityElement(children: .combine)
                            Text("\(signedPct(nominal)) before inflation; New York-area prices rose \(pct(inflation(s.year, c.year))) over the same years.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section {
                Text("A median moves with who holds the title, how many are new and how many senior, as well as with the pay scale. Salaries only: no benefits, overtime, longevity or stipends.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(title.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summary: String {
        let parts = title.riverheadVsPct.keys.sorted().compactMap { town -> String? in
            guard let g = title.riverheadVsPct[town]?["current"] else { return nil }
            return "\(pct(abs(g))) \(g < 0 ? "below" : "above") \(town)"
        }
        guard !parts.isEmpty else {
            return "Riverhead and its neighbours don't both have this title in 2026, so only the years each has are shown."
        }
        return "In 2026 Riverhead's median \(title.title) salary is \(parts.joined(separator: " and "))."
    }

    private func detailLine(_ s: PeerTitlePayDocument.Stat) -> String {
        let who = s.count == 1 ? "1 position" : "\(s.count) positions"
        return s.low == s.high ? who : "\(who), \(money(s.low)) to \(money(s.high))"
    }

    private func inflation(_ from: Int, _ to: Int) -> Double {
        guard let a = doc.cpi[String(from)]?.value, let b = doc.cpi[String(to)]?.value else { return 0 }
        return (b / a - 1) * 100
    }
}

// MARK: - Formatting

private func money(_ v: Double) -> String {
    v.formatted(.currency(code: "USD").precision(.fractionLength(0)))
}

private func pct(_ v: Double) -> String {
    "\(v.formatted(.number.precision(.fractionLength(1))))%"
}

private func signedPct(_ v: Double) -> String {
    (v >= 0 ? "+" : "−") + pct(abs(v))
}
