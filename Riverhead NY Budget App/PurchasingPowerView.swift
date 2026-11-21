//
//  PurchasingPowerView.swift
//  Riverhead NY Budget App
//
//  Does a Town salary buy as much today as it did when the Town's records first
//  show it? Reads the bundled purchasing-power.json, built by the website's
//  etl/build_purchasing_power.py from the Town Board's January salary
//  resolutions (2018-2026), the payroll export's hire dates, and the BLS CPI-U
//  for the New York-Newark-Jersey City area (via FRED). Every figure is the
//  website's; this view only presents it.
//
//  Swift 5 language mode
//

import Charts
import SwiftUI

// MARK: - Model

struct PurchasingPowerDocument: Decodable, Sendable {
    struct Summary: Decodable, Sendable {
        let people: Int
        let ahead: Int
        let even: Int
        let behind: Int
        let medianRealChangePct: Double?
    }

    struct CohortSummary: Decodable, Sendable {
        let people: Int
        let ahead: Int
        let even: Int
        let behind: Int
        let medianRealChangePct: Double?
        let cumulativeInflationPct: Double
    }

    struct CPIYear: Decodable, Sendable {
        let value: Double
        let months: Int
    }

    struct SameTitle: Decodable, Identifiable, Sendable {
        let title: String
        let count2018: Int
        let count2026: Int
        let median2018: Double
        let median2026: Double
        let median2018InTodayDollars: Double
        let nominalChangePct: Double
        let realChangePct: Double
        var id: String { title }
    }

    struct LowSalary: Decodable, Identifiable, Sendable {
        let name: String
        let title: String
        let salary: Double
        let hourlyAt35: Double
        let hourlyAt40: Double
        var id: String { name + title }
    }

    struct WageFloor: Decodable, Sendable {
        let hourly: Double
        let annualAt35Hours: Double
        let annualAt40Hours: Double
        let belowAt35Hours: Int
        let belowAt40Hours: Int
        let lowestSalaries: [LowSalary]
    }

    struct Point: Decodable, Sendable {
        let year: Int
        let salary: Double
        let parity: Double
    }

    struct Person: Decodable, Identifiable, Sendable {
        let name: String
        let title: String
        let department: String
        let group: String
        let hireDate: String?
        let firstYear: Int
        let firstSalary: Double
        let firstIsStartingSalary: Bool
        let salary: Double
        let cumulativeInflationPct: Double
        let cumulativeInflationUsPct: Double
        let firstInTodayDollars: Double
        let nominalChangePct: Double
        let realChangePct: Double?
        let status: String
        let series: [Point]
        var id: String { name + "|" + title }
    }

    let asOf: String
    let method: String
    let cpi: [String: [String: CPIYear]]
    let evenBandPct: Double
    let summary: Summary
    let byGroup: [String: Summary]
    let byFirstYear: [String: CohortSummary]
    let sameTitle: [SameTitle]
    let wageFloor: WageFloor
    let people: [Person]

    static let bundled: PurchasingPowerDocument? = {
        guard let url = Bundle.main.url(forResource: "purchasing-power", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(PurchasingPowerDocument.self, from: data)
    }()

    /// Cumulative New York-area inflation from 2018 to 2026, in percent.
    var inflationSince2018: Double? {
        guard let a = cpi["ny"]?["2018"]?.value, let b = cpi["ny"]?["2026"]?.value else { return nil }
        return (b / a - 1) * 100
    }

    var inflationSince2018US: Double? {
        guard let a = cpi["us"]?["2018"]?.value, let b = cpi["us"]?["2026"]?.value else { return nil }
        return (b / a - 1) * 100
    }
}

// MARK: - View

struct PurchasingPowerView: View {
    private let doc = PurchasingPowerDocument.bundled
    @State private var query = ""
    @State private var filter: StatusFilter = .all

    enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "All", behind = "Behind", even = "Even", ahead = "Ahead"
        var id: String { rawValue }
        func matches(_ status: String) -> Bool {
            switch self {
            case .all: return true
            case .behind: return status == "behind"
            case .even: return status == "even"
            case .ahead: return status == "ahead"
            }
        }
    }

    var body: some View {
        List {
            if let doc {
                answerSection(doc)
                inflationSection(doc)
                sameJobSection(doc)
                groupSection(doc)
                cohortSection(doc)
                wageFloorSection(doc)
                peopleSection(doc)
                methodSection(doc)
            } else {
                ContentUnavailableView("Purchasing power data isn't in this build",
                                       systemImage: "chart.line.downtrend.xyaxis",
                                       description: Text("The app's bundled purchasing-power.json is missing. The next data sync adds it."))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Purchasing Power")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Search name or title")
    }

    // MARK: The answer

    private func answerSection(_ doc: PurchasingPowerDocument) -> some View {
        let s = doc.summary
        let lagging = doc.sameTitle.filter { $0.realChangePct < -doc.evenBandPct }.count
        let sameMedian = median(doc.sameTitle.map(\.realChangePct))
        return Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Is there an equilibrium?")
                    .font(.headline)
                Text("For most people, no: their pay has outrun inflation. Of \(s.people) Town employees with a salary on file before 2026, \(s.ahead) earn more in buying power than their first salary on file did, \(s.even) are about even, and \(s.behind) have fallen behind. The median employee is \(signedPct(s.medianRealChangePct ?? 0)) ahead of New York-area inflation.")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                Text("For the jobs themselves, the answer runs the other way. Most of that gain comes from climbing steps and being promoted. Of \(doc.sameTitle.count) job titles held by at least two people in both 2018 and 2026, \(lagging) pay less in buying power than in 2018 (median \(signedPct(sameMedian))). The pay scales have not kept pace; the people moving up them have.")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)

            HStack(spacing: 10) {
                statusTile("Ahead", s.ahead, .green)
                statusTile("Even", s.even, .secondary)
                statusTile("Behind", s.behind, RiverheadTheme.brandCoral)
            }
            .padding(.vertical, 2)
        } footer: {
            Text("\u{201C}About even\u{201D} means within \(doc.evenBandPct.formatted(.number.precision(.fractionLength(0))))% of the first salary carried forward by inflation. This app's analysis of the Town's records, not a Town finding.")
        }
    }

    private func statusTile(_ label: String, _ count: Int, _ tint: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)").font(.title2.weight(.bold)).foregroundStyle(tint).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: Inflation

    private func inflationSection(_ doc: PurchasingPowerDocument) -> some View {
        let years = (2018...2026).map(String.init)
        let points: [(year: Int, ny: Double, us: Double)] = years.compactMap { y in
            guard let ny = doc.cpi["ny"]?[y]?.value, let us = doc.cpi["us"]?[y]?.value,
                  let ny0 = doc.cpi["ny"]?["2018"]?.value, let us0 = doc.cpi["us"]?["2018"]?.value else { return nil }
            return (Int(y)!, (ny / ny0 - 1) * 100, (us / us0 - 1) * 100)
        }
        return Section {
            if let ny = doc.inflationSince2018, let us = doc.inflationSince2018US {
                Text("Prices in the New York area rose \(pct(ny)) from 2018 to 2026; across the U.S., \(pct(us)). A 2018 dollar needs about \(money2(1 + ny / 100)) today to buy the same things here.")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Chart {
                ForEach(points, id: \.year) { p in
                    LineMark(x: .value("Year", p.year), y: .value("Since 2018", p.ny))
                        .foregroundStyle(by: .value("Area", "New York area"))
                    LineMark(x: .value("Year", p.year), y: .value("Since 2018", p.us))
                        .foregroundStyle(by: .value("Area", "U.S."))
                }
            }
            .chartYAxisLabel("% above 2018 prices")
            .frame(height: 180)
            .accessibilityLabel("Cumulative inflation since 2018, New York area and U.S.")
        } header: {
            Label("Cumulative inflation (CPI)", systemImage: "cart.fill")
        } footer: {
            Text("BLS CPI-U, all items, not seasonally adjusted: New York-Newark-Jersey City (CUURA101SA0) and U.S. city average (CUUR0000SA0), via FRED. 2026 averages the months through \(doc.asOf).")
        }
    }

    // MARK: Same job

    private func sameJobSection(_ doc: PurchasingPowerDocument) -> some View {
        Section {
            ForEach(doc.sameTitle) { t in
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(t.title).font(.footnote.weight(.semibold))
                        Spacer()
                        Text(signedPct(t.realChangePct))
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(ppTint(t.realChangePct, band: doc.evenBandPct))
                            .monospacedDigit()
                    }
                    Text("Median \(money(t.median2018)) in 2018 (\(money(t.median2018InTodayDollars)) in today's dollars) → \(money(t.median2026)) in 2026, \(signedPct(t.nominalChangePct)) before inflation. \(t.count2018) then, \(t.count2026) now.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
            NavigationLink {
                PeerTitlePayView()
            } label: {
                Label("Compare the same job in Southampton and Southold", systemImage: "building.2")
                    .font(.footnote.weight(.semibold))
            }
        } header: {
            Label("The same job, 2018 and 2026", systemImage: "briefcase.fill")
        } footer: {
            Text("Median authorized salary for each title held by at least two people in both years, with the 2018 figure carried forward by New York-area inflation. A title's median also moves with who holds it: when more junior people fill a title, as with Police Officer, its median falls even if every step rose.")
        }
    }

    // MARK: Groups and cohorts

    private func groupSection(_ doc: PurchasingPowerDocument) -> some View {
        Section("By group") {
            ForEach(doc.byGroup.keys.sorted(), id: \.self) { g in
                if let s = doc.byGroup[g] {
                    summaryRow(g, s.people, s.ahead, s.even, s.behind, s.medianRealChangePct, band: doc.evenBandPct)
                }
            }
        }
    }

    private func cohortSection(_ doc: PurchasingPowerDocument) -> some View {
        Section {
            ForEach(doc.byFirstYear.keys.sorted(), id: \.self) { y in
                if let s = doc.byFirstYear[y] {
                    summaryRow("First on file \(y) · prices +\(pct(s.cumulativeInflationPct))", s.people, s.ahead, s.even, s.behind, s.medianRealChangePct, band: doc.evenBandPct)
                }
            }
        } header: {
            Text("By the year pay is first on file")
        } footer: {
            Text("2018 is the first year of the resolutions on file, so it holds everyone hired by then. Later years are mostly new hires climbing their steps, which is why their gains are larger.")
        }
    }

    private func summaryRow(_ label: String, _ n: Int, _ a: Int, _ e: Int, _ b: Int, _ median: Double?, band: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label).font(.footnote.weight(.semibold))
                Spacer()
                if let median {
                    Text(signedPct(median))
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(ppTint(median, band: band))
                        .monospacedDigit()
                }
            }
            Text("\(n) people · \(a) ahead, \(e) even, \(b) behind (median real change)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Wage floor

    private func wageFloorSection(_ doc: PurchasingPowerDocument) -> some View {
        let w = doc.wageFloor
        return Section {
            Text("New York's minimum wage on Long Island is \(money2(w.hourly)) an hour in 2026, and stays there on January 1, 2027. Full time, that is \(money(w.annualAt35Hours)) a year at 35 hours a week and \(money(w.annualAt40Hours)) at 40. \(w.belowAt40Hours == 0 ? "No full-time salary on the 2026 list is below it." : "\(w.belowAt40Hours) full-time salaries on the 2026 list are below it at 40 hours.")")
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Text("New York sets no official living wage, so this app uses none. The minimum wage is a legal floor, not a measure of what it costs to live here.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(w.lowestSalaries) { l in
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(l.name).font(.footnote.weight(.semibold))
                        Text(l.title).font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(money(l.salary)).font(.footnote.weight(.bold)).monospacedDigit()
                        Text("\(money2(l.hourlyAt40))–\(money2(l.hourlyAt35))/hr").font(.caption2).foregroundStyle(.secondary).monospacedDigit()
                    }
                }
                .accessibilityElement(children: .combine)
            }
        } header: {
            Label("The wage floor", systemImage: "dollarsign.circle")
        } footer: {
            Text("The ten lowest 2026 salaries, as hourly pay at 40 and 35 hours a week. Minimum wage: NYS Department of Labor, dol.ny.gov/minimum-wage-0.")
        }
    }

    // MARK: People

    private func peopleSection(_ doc: PurchasingPowerDocument) -> some View {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        let rows = doc.people
            .filter { filter.matches($0.status) || (filter == .all) }
            .filter { q.isEmpty || $0.name.lowercased().contains(q) || $0.title.lowercased().contains(q) }
            .sorted { ($0.realChangePct ?? .infinity) < ($1.realChangePct ?? .infinity) }
        return Section {
            Picker("Show", selection: $filter) {
                ForEach(StatusFilter.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            ForEach(rows) { p in
                NavigationLink {
                    PurchasingPowerPersonView(person: p, band: doc.evenBandPct)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(p.name).font(.footnote.weight(.semibold))
                            Text("\(p.title) · first on file \(String(p.firstYear))")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(p.realChangePct.map(signedPct) ?? "new")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(p.realChangePct.map { ppTint($0, band: doc.evenBandPct) } ?? .secondary)
                            .monospacedDigit()
                    }
                }
            }
        } header: {
            Text("Every employee (\(rows.count))")
        } footer: {
            Text("Sorted from furthest behind to furthest ahead. Tap a name for the year-by-year path.")
        }
    }

    private func methodSection(_ doc: PurchasingPowerDocument) -> some View {
        Section("How this is worked out") {
            Text(doc.method)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - One person

struct PurchasingPowerPersonView: View {
    let person: PurchasingPowerDocument.Person
    let band: Double

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(person.name).font(.title3.weight(.bold))
                    Text("\(person.title) · \(person.department)")
                        .font(.subheadline).foregroundStyle(.secondary)
                    if let h = person.hireDate {
                        Text("Hired \(h)").font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
                row(person.firstIsStartingSalary ? "Starting salary (\(person.firstYear))" : "First salary on file (\(person.firstYear))", money(person.firstSalary))
                row("That salary in today's dollars", money(person.firstInTodayDollars))
                row("Prices since \(person.firstYear) (NY area)", "+\(pct(person.cumulativeInflationPct))")
                row("Prices since \(person.firstYear) (U.S.)", "+\(pct(person.cumulativeInflationUsPct))")
                row("2026 authorized salary", money(person.salary))
                row("Change before inflation", signedPct(person.nominalChangePct))
                if let r = person.realChangePct {
                    row("Change in buying power", signedPct(r), tint: ppTint(r, band: band))
                }
            } footer: {
                Text(verdict)
            }

            if person.series.count > 1 {
                Section("Salary against inflation") {
                    Chart {
                        ForEach(person.series, id: \.year) { p in
                            LineMark(x: .value("Year", p.year), y: .value("Dollars", p.salary))
                                .foregroundStyle(by: .value("Line", "Authorized salary"))
                            LineMark(x: .value("Year", p.year), y: .value("Dollars", p.parity))
                                .foregroundStyle(by: .value("Line", "First salary + inflation"))
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 3]))
                        }
                    }
                    .frame(height: 200)
                    .accessibilityLabel("Authorized salary each year against the first salary carried forward by inflation")
                    ForEach(person.series, id: \.year) { p in
                        HStack {
                            Text(String(p.year)).font(.footnote.weight(.semibold))
                            Spacer()
                            Text(money(p.salary)).font(.footnote).monospacedDigit()
                            Text("vs \(money(p.parity))").font(.caption2).foregroundStyle(.secondary).monospacedDigit()
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Purchasing Power")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var verdict: String {
        guard let r = person.realChangePct else {
            return "First on the 2026 list, so there is no earlier salary to compare."
        }
        let basis = person.firstIsStartingSalary ? "starting salary" : "2018 salary, the first in the Town's resolutions on file"
        switch r {
        case let x where x > band:
            return "The 2026 salary buys \(pct(x)) more than the \(basis) did. That includes step increases and any promotion, not only raises."
        case let x where x < -band:
            return "The 2026 salary buys \(pct(-x)) less than the \(basis) did: raises have not kept pace with New York-area prices."
        default:
            return "The 2026 salary buys about what the \(basis) did: close to an equilibrium with New York-area prices."
        }
    }

    private func row(_ k: String, _ v: String, tint: Color = .primary) -> some View {
        HStack {
            Text(k).font(.footnote)
            Spacer()
            Text(v).font(.footnote.weight(.semibold)).foregroundStyle(tint).monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Formatting

private func money(_ v: Double) -> String {
    v.formatted(.currency(code: "USD").precision(.fractionLength(0)))
}

private func money2(_ v: Double) -> String {
    v.formatted(.currency(code: "USD").precision(.fractionLength(2)))
}

private func pct(_ v: Double) -> String {
    "\(v.formatted(.number.precision(.fractionLength(1))))%"
}

private func signedPct(_ v: Double) -> String {
    (v >= 0 ? "+" : "−") + pct(abs(v))
}

private func ppTint(_ v: Double, band: Double) -> Color {
    v > band ? .green : (v < -band ? RiverheadTheme.brandCoral : .secondary)
}

private func median(_ xs: [Double]) -> Double {
    let s = xs.sorted()
    guard !s.isEmpty else { return 0 }
    return s.count % 2 == 1 ? s[s.count / 2] : (s[s.count / 2 - 1] + s[s.count / 2]) / 2
}
