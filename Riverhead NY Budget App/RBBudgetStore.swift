//
//  RBBudgetStore.swift
//  Riverhead NY Budget App
//
//  Central observable store for:
//   • Municipality / app metadata
//   • Fund balance policy + quick tax inputs
//   • NY property tax cap inputs (simplified)
//   • Explore / charting series (via BudgetHistoryShift + Riverhead2026BudgetShift)
//   • Budget history documents + quick links
//

import Foundation
import Observation

// MARK: - Metric enum used by ExploreView / FundDetailView

enum RBBudgetMetric {
    case taxLevy
    case appropriations
}

// MARK: - Store

@MainActor
@Observable
final class RBBudgetStore {

    // MARK: - App / Municipality

    var municipality: RBMunicipality = .riverhead
    var appTitle: String = "Riverhead NY Budget App"
    var fiscalYearTitle: String = "2026 Tentative Budget"

    // MARK: - Fund Balance (General Fund)

    /// Appropriations for the budget year being analyzed (e.g., FY 2026).
    var appropriations: Double = 69_113_159

    /// Estimated Unassigned Fund Balance as of 12/31 of the prior year.
    var estimatedFundBalance: Double = 28_403_924

    /// Active fund balance policy (editable via Policies view).
    var fundBalancePolicy: RBFundBalancePolicy = .init(
        minimumPercent: 0.15,
        targetUpperPercent: 0.20,
        replenishYears: 3,
        notes: ""
    )

    /// Dollar minimum required by policy given `appropriations`.
    var minimumRequired: Double {
        max(0, appropriations * fundBalancePolicy.minimumPercent)
    }

    /// Dollar upper target (if configured) given `appropriations`.
    var targetUpper: Double? {
        guard let up = fundBalancePolicy.targetUpperPercent else { return nil }
        return max(0, appropriations * up)
    }

    // MARK: - Quick Taxes (used by MyTaxesView)

    /// Town-wide tax rate per $1,000 (illustrative; override when you have adopted rates).
    var ratePerThousand: Double = 22.50

    // MARK: - NY Property Tax Cap (simplified inputs)

    /// Prior-year levy used as the base in the cap formula.
    var priorYearLevy: Double = 10_000_000

    /// CPI-U (percent). 2.00 = 2%.
    var cpiPercent: Double = 2.00

    /// Tax Base Growth Factor (e.g. 1.0072).
    var tbgf: Double = 1.0072

    /// Unused cap “carryover” from prior year.
    var carryover: Double = 0.0

    /// Capital levy exclusions.
    var capitalExclusions: Double = 0.0

    /// PILOTs (payments in lieu of taxes) to be netted from the levy limit.
    var pilots: Double = 0.0

    // MARK: - Explore / Charting

    /// Displayable fund names (keys you pass into `valueSeries`).
    ///
    /// These are of the form: "CODE • Name", e.g. "A01 • General Fund",
    /// based on 2026 summaries. ExploreView and FundDetailView both use this.
    private(set) var funds: [String] = []

    private struct FundMeta: Hashable {
        let displayName: String  // "CODE • Name"
        let fundCode: String     // "A01"
        let fundName: String     // "General Fund"
    }

    private var fundMeta: [FundMeta] = []

    /// Cache for series lookups so we don't recompute on every tap.
    private struct SeriesKey: Hashable {
        let displayName: String
        let metric: RBBudgetMetric
    }

    private var seriesCache: [SeriesKey: [(year: Int, value: Double)]] = [:]

    // MARK: - History data (docs & quick links)

    /// Riverhead does **not** use capital budgets. Types used:
    ///   tentative, preliminary, adopted, audit.
    var documents: [RiverheadBudgetDoc]
    private static func makeDocuments() -> [RiverheadBudgetDoc] {
        let cal = Calendar.current
        func d(_ y: Int, _ m: Int, _ day: Int) -> Date? {
            cal.date(from: DateComponents(year: y, month: m, day: day))
        }

        return [
            // 2026
            RiverheadBudgetDoc(
                id: UUID(),
                title: "2026 Tentative Budget",
                type: .tentative,
                year: 2026,
                url: URL.verified("https://www.townofriverheadny.gov/DocumentCenter/View/2779/2026-Tentative-Budget-PDF"),
                published: d(2025, 10, 1),
                sizeMB: nil
            ),
            RiverheadBudgetDoc(
                id: UUID(),
                title: "2026 Budget Supplement",
                type: .audit, // treat Supplement as a financial reference/report
                year: 2026,
                url: URL.verified("https://www.townofriverheadny.gov/DocumentCenter/View/2780/2026-Budget-Supplement-PDF"),
                published: d(2025, 10, 1),
                sizeMB: nil
            ),

            // 2025
            RiverheadBudgetDoc(
                id: UUID(),
                title: "2025 Adopted Budget",
                type: .adopted,
                year: 2025,
                url: URL.verified("https://www.townofriverheadny.gov/DocumentCenter/View/243/2025-Adopted-Budget-PDF"),
                published: d(2024, 11, 20),
                sizeMB: nil
            ),
            RiverheadBudgetDoc(
                id: UUID(),
                title: "2025 Tentative Budget",
                type: .tentative,
                year: 2025,
                url: URL.verified("https://www.townofriverheadny.gov/DocumentCenter/View/242/2025-Tentative-Budget-PDF"),
                published: d(2024, 10, 1),
                sizeMB: nil
            ),

            // 2024
            RiverheadBudgetDoc(
                id: UUID(),
                title: "2024 Adopted Budget",
                type: .adopted,
                year: 2024,
                url: URL.verified("https://www.townofriverheadny.gov/DocumentCenter/View/245/2024-Adopted-Budget-PDF"),
                published: d(2023, 11, 20),
                sizeMB: nil
            )

            // Add AFRU or audited statements as `.audit` when you want them shown in History.
        ]
    }

    /// Shortcut list for the featured “This Year” section in Budget History.
    /// If the calendar year has no docs, falls back to the latest year present.
    var quickLinks: [RiverheadBudgetDoc] {
        let currentYear = Calendar.current.component(.year, from: Date())
        let thisYear = documents.filter { $0.year == currentYear }
        let targetYear = thisYear.isEmpty ? (documents.map(\.year).max() ?? currentYear) : currentYear
        return documents
            .filter { $0.year == targetYear }
            .sorted { typeRank($0.type) < typeRank($1.type) }
    }

    private func typeRank(_ t: RiverheadBudgetDoc.DocType) -> Int {
        // Keep ordering consistent with HistoricalTabView
        switch t {
        case .tentative:   return 0
        case .preliminary: return 1
        case .adopted:     return 2
        case .capital:     return 3
        case .audit:       return 4
        }
    }

    // MARK: - Init

    init() {
        self.documents = Self.makeDocuments()
        rebuildFundMeta()

        // Warm heavy parsing in the background to keep app launch responsive.
        Task(priority: .utility) {
            if Riverhead2026BudgetShift.lastLoadCount == 0 {
                _ = try? Riverhead2026BudgetShift.load()
            }
            _ = BudgetHistoryShift.ensureLoaded()
        }
    }

    /// Call after background warm-up completes to rebuild the visible fund list.
    func refreshFromLoadedData() {
        rebuildFundMeta()
    }

    // MARK: - Explore / Series API

    /// Returns a sorted series of (year, value) for the requested fund + metric.
    ///
    /// - Parameter fund: One of `store.funds` (e.g. "A01 • General Fund").
    /// - Combines:
    ///     • BudgetHistoryShift: 2021–2025 (best-effort by name)
    ///     • Riverhead2026BudgetShift: 2026 (direct by code/name)
    func valueSeries(for fund: String, metric: RBBudgetMetric) -> [(year: Int, value: Double)] {
        let key = SeriesKey(displayName: fund, metric: metric)
        if let cached = seriesCache[key] { return cached }

        guard let meta = fundMeta.first(where: { $0.displayName == fund || $0.fundName == fund }) else {
            return []
        }

        // Start with historical (2021–2025) via BudgetHistoryShift.
        var byYear: [Int: Double] = [:]

        let hist = BudgetHistoryShift.historicalSeries(forFundName: meta.fundName)
        let histSource: [Int: Decimal] = {
            switch metric {
            case .taxLevy:        return hist.levy
            case .appropriations: return hist.app
            }
        }()

        for (year, dec) in histSource {
            byYear[year] = NSDecimalNumber(decimal: dec).doubleValue
        }

        // Add / override 2026 from CSV summaries when available.
        if let s = match2026Summary(for: meta) {
            let dec: Decimal?
            switch metric {
            case .taxLevy:
                dec = s.taxLevy2026
            case .appropriations:
                dec = s.appropriations2026
            }

            if let dec = dec {
                byYear[2026] = NSDecimalNumber(decimal: dec).doubleValue
            }
        }

        // Build sorted array.
        let series = byYear.keys.sorted().compactMap { year -> (Int, Double)? in
            guard let v = byYear[year] else { return nil }
            return (year, v)
        }

        seriesCache[key] = series
        return series
    }

    // MARK: - Internal fund list building

    private func rebuildFundMeta() {
        // 1) Pull all 2026 fund summaries from CSV.
        let summaries = Riverhead2026BudgetShift.fundSummaries()

        var meta: [FundMeta] = summaries.map { s in
            FundMeta(
                displayName: Self.displayName(code: s.fundCode, name: s.fundName),
                fundCode: s.fundCode,
                fundName: s.fundName
            )
        }

        // 2) (Optional) Enrich with any 2021–2025-only funds not in 2026 CSV.
        //    Left commented for now to keep the Explore list focused on current funds.
        /*
        let years = BudgetHistoryShift.availableYears()
        for year in years {
            for row in BudgetHistoryShift.rows(for: year) {
                let nameNorm = Self.normalize(row.fundName)
                let codeNorm = row.fundCode.uppercased()

                let already = meta.contains(where: { m in
                    Self.normalize(m.fundName) == nameNorm
                    || m.fundCode.uppercased() == codeNorm
                })
                if already { continue }

                let disp = row.fundCode.isEmpty
                    ? row.fundName
                    : "\(row.fundCode) • \(row.fundName)"

                meta.append(FundMeta(
                    displayName: disp,
                    fundCode: row.fundCode.isEmpty ? row.fundCode : row.fundCode,
                    fundName: row.fundName
                ))
            }
        }
        */

        // 3) Sort for stable UI and expose public list.
        meta.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }

        self.fundMeta = meta
        self.funds = meta.map(\.displayName)
        self.seriesCache.removeAll(keepingCapacity: true)
    }

    // MARK: - Matching helpers

    private func match2026Summary(for meta: FundMeta) -> RBFundSummary? {
        let all = Riverhead2026BudgetShift.fundSummaries()
        if all.isEmpty { return nil }

        let codeNorm = meta.fundCode.uppercased()
        let nameNorm = Self.normalize(meta.fundName)

        // Priority 1: exact code match.
        if let hit = all.first(where: { $0.fundCode.uppercased() == codeNorm }) {
            return hit
        }

        // Priority 2: normalized name match.
        if let hit = all.first(where: { Self.normalize($0.fundName) == nameNorm }) {
            return hit
        }

        // Priority 3: contains either way.
        if let hit = all.first(where: {
            let n = Self.normalize($0.fundName)
            return n.contains(nameNorm) || nameNorm.contains(n)
        }) {
            return hit
        }

        return nil
    }

    private static func displayName(code: String, name: String) -> String {
        "\(code) • \(name)"
    }

    private static func normalize(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: "district", with: "")
            .replacingOccurrences(of: "fund", with: "")
            .replacingOccurrences(of: "•", with: " ")
            .replacingOccurrences(of: "(", with: " ")
            .replacingOccurrences(of: ")", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
