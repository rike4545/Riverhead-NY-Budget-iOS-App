//
//  Budget2026Explore+Shift.swift
//  Riverhead NY Budget App
//
//  Combined file:
//   • ExploreView (2026-only, device-safe, scroll-safe)
//   • Riverhead2026BudgetShift (CSV loader + search + tolerant parsers)
//
//  Usage:
//   • Put `tables_flat.csv` in the BUNDLE ROOT (Target Membership ON).
//   • Ensure `try? Riverhead2026BudgetShift.load()` runs once at startup.
//   • ExploreView expects an environment `RBBudgetStore` exposing:
//        var funds: [String] { get }
//        func valueSeries(for fund: String, metric: RBBudgetMetric) -> [(year: Int, value: Double)]
//     with enum RBBudgetMetric { case taxLevy, appropriations }
//

import SwiftUI
import Observation
import Charts
import Foundation

// ======================================================
// MARK: - ExploreView (device-safe, 2026-locked)
// ======================================================

private let targetYear: Int = 2026

/// Official 2026 funds (code + name) from the Town’s 2026 Preliminary Budget.
private let allowed2026Funds: [(code: String, name: String)] = [
    ("A01", "General Fund"),
    ("A04", "Police Athletic League"),
    ("A06", "Recreation Program Fund"),
    ("CM1", "Business Improvement District"),
    ("CM2", "East Creek Docking Facility"),
    ("CM4", "Community Preservation Fund"),
    ("DA1", "Highway Fund"),
    ("ES1", "Riverhead Sewer District"),
    ("ES3", "Calverton Sewer District"),
    ("ES5", "Riverhead Scavenger Waste"),
    ("EW1", "Water District"),
    ("MS1", "Workers Compensation Fund"),
    ("MS2", "Risk Retention Fund"),
    ("SL1", "Street Lighting District"),
    ("SM1", "Ambulance District"),
    ("SR1", "Refuse and Garbage District"),
    ("ST1", "Public Parking District"),
    ("V01", "Debt Service Fund"),
    ("Z14", "Calverton Parks Community Development Agency (CDA)")
]

@inline(__always) private func displayName(_ item: (code: String, name: String)) -> String {
    "\(item.code) • \(item.name)"
}

@inline(__always) private func normalize(_ s: String) -> String {
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

/// Extract the plain fund name from "CODE • Name".
@inline(__always) private func storeKey(from display: String) -> String {
    if let sep = display.firstIndex(of: "•") {
        let name = display[display.index(after: sep)...].trimmingCharacters(in: .whitespaces)
        return String(name)
    }
    return display
}

/// Resolve a store key in `store.funds` for a given official (code,name).
private func resolveStoreKey(allowed: (code: String, name: String), in storeFunds: [String]) -> String? {
    guard !storeFunds.isEmpty else { return nil }

    let codeNorm = normalize(allowed.code)
    let nameNorm = normalize(allowed.name)
    let candidates: [(raw: String, norm: String)] = storeFunds.map { ($0, normalize($0)) }

    // 1) Exact (case-insensitive) name
    if let exact = candidates.first(where: { $0.raw.compare(allowed.name, options: .caseInsensitive) == .orderedSame }) {
        return exact.raw
    }
    // 2) Exact normalized name
    if let normName = candidates.first(where: { $0.norm == nameNorm }) { return normName.raw }
    // 3) Contains name/code
    if let containsName = candidates.first(where: { $0.norm.contains(nameNorm) }) { return containsName.raw }
    if let containsCode = candidates.first(where: { $0.norm.contains(codeNorm) }) { return containsCode.raw }
    // 4) Code prefix/suffix
    if let startsWithCode = candidates.first(where: { $0.norm.hasPrefix(codeNorm + " ") }) { return startsWithCode.raw }
    if let endsWithCode = candidates.first(where: { $0.norm.hasSuffix(" " + codeNorm) }) { return endsWithCode.raw }
    // 5) Token overlap (≥2 tokens)
    let nameTokens = Set(nameNorm.split(separator: " ").map(String.init)).filter { $0.count > 1 }
    if let overlap = candidates.first(where: { cand in
        let tokens = Set(cand.norm.split(separator: " ").map(String.init))
        return tokens.intersection(nameTokens).count >= 2
    }) {
        return overlap.raw
    }
    return nil
}

// MARK: CSV fallback plumbing

@inline(__always) private func codeFromDisplay(_ display: String) -> String? {
    // "A01 • General Fund" -> "A01"
    if let sep = display.firstIndex(of: "•") {
        let code = display[..<sep].trimmingCharacters(in: .whitespaces)
        return code.isEmpty ? nil : String(code)
    }
    // fallback: try first token
    if let sp = display.firstIndex(of: " ") {
        let maybe = String(display[..<sp]).trimmingCharacters(in: .whitespaces)
        return maybe.range(of: #"^[A-Z]{1,2}\d{1,2}$"#, options: .regularExpression) != nil ? maybe : nil
    }
    return nil
}

private func fallback2026(for display: String) -> (levy: Double?, app: Double?)? {
    let sums = Riverhead2026BudgetShift.fundSummaries()
    let code = codeFromDisplay(display)
    let normName = normalize(storeKey(from: display))

    func toD(_ d: Decimal?) -> Double? {
        guard let d = d as NSDecimalNumber? else { return nil }
        return d.doubleValue
    }

    // Priority 1: code match
    if let code = code, let hit = sums.first(where: { $0.fundCode.compare(code, options: .caseInsensitive) == .orderedSame }) {
        return (levy: toD(hit.taxLevy2026), app: toD(hit.appropriations2026))
    }
    // Priority 2: strict name match
    if let hit = sums.first(where: { normalize($0.fundName) == normName }) {
        return (levy: toD(hit.taxLevy2026), app: toD(hit.appropriations2026))
    }
    // Priority 3: contains
    if let hit = sums.first(where: { normalize($0.fundName).contains(normName) || normName.contains(normalize($0.fundName)) }) {
        return (levy: toD(hit.taxLevy2026), app: toD(hit.appropriations2026))
    }
    return nil
}

public struct ExploreView: View {
    @Environment(RBBudgetStore.self) private var store
    @Environment(\.horizontalSizeClass) private var hSize

    @State private var query: String = ""
    @State private var keyCache: [String: String] = [:] // "CODE • Name" -> resolved store key

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(spacing: 16) {
                    header
                    quickLinksRow
                    responsiveFundsGrid()

                    if filteredDisplayLabels.isEmpty {
                        ContentUnavailableView(
                            "No matching funds",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("Try “General”, “Highway”, “Sewer”, or a code like A01/DA1.")
                        )
                        .padding(.top, 24)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Riverhead Budgets")
            .searchable(text: $query,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search funds or codes")
            .onAppear {
                if Riverhead2026BudgetShift.lastLoadCount == 0 {
                    _ = try? Riverhead2026BudgetShift.load()
                }
                buildKeyCacheIfNeeded()
            }
        }
        .dynamicTypeSize(.xSmall ... .accessibility3)
        .textSelection(.disabled)
    }

    // MARK: Header

    private var header: some View {
        ViewThatFits {
            VStack(alignment: .leading, spacing: 6) {
                Text("Riverhead Budgets")
                    .font(.largeTitle.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .accessibilityAddTraits(.isHeader)
                Text("Simple view for residents")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text("Riverhead Budgets")
                    .font(.title.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .accessibilityAddTraits(.isHeader)
                Text("Simple view for residents")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Quick Links

    private var quickLinksRow: some View {
        let cards: [QuickCard] = [
            .init(
                title: "Fund Balance Policy",
                subtitle: "GASB 54 + Riverhead",
                systemImage: "checklist",
                destination: AnyView(FundBalancePoliciesView())
            ),
            .init(
                title: "Fund Balance Audit",
                subtitle: "Policy vs Actuals",
                systemImage: "shield.checkerboard",
                destination: AnyView(RiverheadFundBalanceAuditView())
            )
        ]

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(cards) { card in
                    NavigationLink {
                        card.destination.environment(store)
                    } label: {
                        QuickLinkCard(card: card)
                            .frame(width: 320)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityElement(children: .contain)
    }

    private struct QuickCard: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let systemImage: String
        let destination: AnyView
    }

    private struct QuickLinkCard: View {
        let card: QuickCard
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: card.systemImage)
                    .font(.title3)
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(card.title)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(card.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08)))
        }
    }

    // MARK: Grid (responsive, 2026-only, scroll-safe)

    @ViewBuilder
    private func responsiveFundsGrid() -> some View {
        let columns = [
            GridItem(.adaptive(minimum: 260, maximum: 420), spacing: 12, alignment: .topLeading)
        ]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            ForEach(filteredDisplayLabels, id: \.self) { display in
                let key = keyCache[display] ?? storeKey(from: display)

                if let card = FundCardData.make2026(from: store, fund: key, fallbackDisplay: display) {
                    NavigationLink {
                        FundDetailView(fund: key).environment(store)
                    } label: {
                        FundCard(card: card, titleOverride: display)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    HollowFundCard(title: display)
                }
            }
        }
    }

    private func buildKeyCacheIfNeeded() {
        guard keyCache.isEmpty else { return }
        let storeFunds = store.funds
        var map: [String: String] = [:]
        for allowed in allowed2026Funds {
            let display = displayName(allowed)
            if let resolved = resolveStoreKey(allowed: allowed, in: storeFunds) {
                map[display] = resolved
            } else {
                map[display] = allowed.name // fallback to name
            }
        }
        keyCache = map
    }

    private var orderedDisplayLabels: [String] { allowed2026Funds.map(displayName) }

    private var filteredDisplayLabels: [String] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return orderedDisplayLabels }
        return orderedDisplayLabels.filter { $0.lowercased().contains(q) }
    }
}

// MARK: ExploreView Card Models

private struct FundCardData {
    let fund: String               // resolved store key
    let displayYear: Int           // 2026
    let metricTitle: String
    let metricValue: String        // 2026 or "—"
    let yoyText: String?           // vs 2025
    let smallTrend: [(Int, Double)]// years ≤ 2026

    /// Always attempts to merge 2026 CSV fallback values into the store series if missing.
    @MainActor
    static func make2026(from store: RBBudgetStore, fund: String, fallbackDisplay: String) -> FundCardData? {
        var levy = store.valueSeries(for: fund, metric: .taxLevy)
        var app  = store.valueSeries(for: fund, metric: .appropriations)

        // Merge CSV fallback for 2026 if the store lacks that year (per-series).
        if let fb = fallback2026(for: fallbackDisplay) {
            if !levy.contains(where: { $0.year == targetYear }), let L = fb.levy {
                levy.append((year: targetYear, value: L))
            }
            if !app.contains(where: { $0.year == targetYear }), let A = fb.app {
                app.append((year: targetYear, value: A))
            }
        }

        // Prefer levy if it has 2026; otherwise use appropriations
        let usingLevy = levy.contains(where: { $0.year == targetYear })
        let base = usingLevy ? levy : app
        guard !base.isEmpty else { return nil }

        let clamped = base.filter { $0.year <= targetYear }.sorted { $0.year < $1.year }
        let v2026 = clamped.first(where: { $0.year == targetYear })?.value
        let v2025 = clamped.first(where: { $0.year == targetYear - 1 })?.value

        let nfMoney: NumberFormatter = {
            let nf = NumberFormatter()
            nf.numberStyle = .currency
            nf.maximumFractionDigits = 0
            return nf
        }()
        let nfPct: NumberFormatter = {
            let nf = NumberFormatter()
            nf.numberStyle = .percent
            nf.maximumFractionDigits = 1
            return nf
        }()

        let metricTitle = usingLevy ? "Tax Levy (2026)" : "Appropriations (2026)"
        let metricValue: String = {
            guard let v = v2026 ?? clamped.last?.value else { return "—" }
            return nfMoney.string(from: v as NSNumber) ?? String(format: "%.0f", v)
        }()

        let yoyText: String? = {
            guard let a = v2026, let b = v2025, b != 0 else { return nil }
            let delta = a - b
            let pct   = a / b - 1
            let dStr  = nfMoney.string(from: delta as NSNumber) ?? String(format: "%.0f", delta)
            let pStr  = nfPct.string(from: pct as NSNumber) ?? "—"
            return "vs 2025: \(dStr) (\(pStr))"
        }()

        let trend = Array(clamped.suffix(7)).map { ($0.year, $0.value) }

        return FundCardData(
            fund: fund,
            displayYear: targetYear,
            metricTitle: metricTitle,
            metricValue: metricValue,
            yoyText: yoyText,
            smallTrend: trend
        )
    }
}

private struct FundCard: View {
    let card: FundCardData
    var titleOverride: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(titleOverride ?? card.fund)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .layoutPriority(1)
                Spacer(minLength: 6)
                Text("\(card.displayYear)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Text(card.metricTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(card.metricValue)
                .font(.title2.weight(.bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            if let yoy = card.yoyText {
                Label {
                    Text(yoy)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                } icon: {
                    Image(systemName: "arrow.up.right")
                        .accessibilityHidden(true)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Chart(card.smallTrend, id: \.0) { (year, value) in
                LineMark(x: .value("Year", year),
                         y: .value("Value", value))
                    .interpolationMethod(.monotone)
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { v in
                    if let y = v.as(Int.self) {
                        AxisValueLabel { Text("\(y)") }
                    }
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 80)
            .accessibilityHidden(true)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08)))
    }
}

private struct HollowFundCard: View {
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 6)
                Text("\(targetYear)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text("No 2026 data")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text("—")
                .font(.title2.weight(.bold))
                .monospacedDigit()
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08)))
    }
}

// ======================================================
// MARK: - Riverhead2026BudgetShift (CSV loader + search)
// ======================================================

public struct RBSearchHit: Identifiable, Hashable {
    public var id: String { "\(page)-\(tableIndex)-\(row)-\(col)" }
    public let page: Int
    public let tableIndex: Int
    public let row: Int
    public let col: Int
    public let value: String
}

public struct RBFundSummary: Identifiable, Hashable {
    public var id: String { fundCode }
    public let fundCode: String
    public let fundName: String
    public let appropriations2026: Decimal?
    public let estRevenues2026: Decimal?
    public let appropFundBalance2026: Decimal?
    public let taxLevy2026: Decimal?
}

public struct RBFundBalanceRow: Identifiable, Hashable {
    public var id: String { fundCode }
    public let fundCode: String
    public let fundName: String
    public let appropriations2026: Decimal?
    public let unauditedFundBalance_2024_12_31: Decimal?
    public let applicationOfFundBalance_2024: Decimal?
    public let estimatedFundBalance_2025_12_31: Decimal?
}

public struct RBElectedSalaryRow: Identifiable, Hashable {
    public var id: String { title }
    public let title: String
    public let salary2025: Decimal?
    public let salary2026Proposed: Decimal?
}

public struct RBSubAccountRow: Identifiable, Hashable {
    public var id: String { accountNumber }
    public let fundCode: String
    public let functionCode: String
    public let objectCode: String
    public let accountNumber: String
    public let description: String
    public let page: Int
    public let tableIndex: Int
    public let rowIndex: Int
    public let budget2025: Decimal?
    public let tentative2026: Decimal?
    public let preliminary2026: Decimal?
    public let adopted2026: Decimal?
}

public struct RBDepartmentBudgetRow: Identifiable, Hashable {
    public var id: String { "\(fundCode)-\(functionCode)" }
    public let fundCode: String
    public let functionCode: String
    public let name: String
    public let page: Int
    public let adopted2026: Decimal?
    public let subAccounts: [RBSubAccountRow]
}

public enum Riverhead2026BudgetShift {
    // CSV file name in BUNDLE ROOT (no folders)
    private static let flatName = "tables_flat" // -> tables_flat.csv

    // Optional page hints (heuristics)
    private static let likelySummaryPage = 3
    private static let likelyFundBalPage = 4
    private static let likelySalariesPage = 5

    // Backing stores
    private static var flatCells: [RBSearchHit] = []
    private static var pageTextCache: [Int: String] = [:]
    private static let lock = NSLock()
    public private(set) static var lastLoadCount: Int = 0

    // MARK: Load

    @discardableResult
    public static func load() throws -> Int {
        lock.lock(); defer { lock.unlock() }
        let cells = try loadFlatCSV()
        flatCells = cells
        lastLoadCount = cells.count
        pageTextCache.removeAll(keepingCapacity: true)
        return lastLoadCount
    }

    // MARK: Public APIs

    public static func search(_ query: String) -> [RBSearchHit] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        let q = query.lowercased()
        lock.lock(); defer { lock.unlock() }
        return flatCells.filter { $0.value.lowercased().contains(q) }
    }

    public static func fundSummaries() -> [RBFundSummary] {
        lock.lock(); defer { lock.unlock() }
        let onSummaryPage = flatCells.filter { $0.page == likelySummaryPage }
        var out: [RBFundSummary] = parseFundSummaryRows(from: onSummaryPage)
        if out.isEmpty { out = parseFundSummaryRows(from: flatCells) }
        return out.unique(by: \.fundCode)
    }

    public static func fundBalances() -> [RBFundBalanceRow] {
        lock.lock(); defer { lock.unlock() }
        let onFBPage = flatCells.filter { $0.page == likelyFundBalPage }
        var out: [RBFundBalanceRow] = parseFundBalanceRows(from: onFBPage)
        if out.isEmpty { out = parseFundBalanceRows(from: flatCells) }
        return out.unique(by: \.fundCode)
    }

    public static func electedSalaries() -> [RBElectedSalaryRow] {
        lock.lock(); defer { lock.unlock() }
        let onSalPage = flatCells.filter { $0.page == likelySalariesPage }
        var out: [RBElectedSalaryRow] = parseElectedSalaryRows(from: onSalPage)
        if out.isEmpty { out = parseElectedSalaryRows(from: flatCells) }
        return out.unique(by: \.title)
    }

    public static func departmentBudgets(fundCode: String? = nil) -> [RBDepartmentBudgetRow] {
        lock.lock(); defer { lock.unlock() }
        let rows = parseDepartmentBudgetRows(from: flatCells)
        guard let fundCode else { return rows }
        return rows.filter { $0.fundCode.compare(fundCode, options: .caseInsensitive) == .orderedSame }
    }

    public static func debugSnapshot(limit: Int = 10) -> String {
        lock.lock(); defer { lock.unlock() }
        let prefix = flatCells.prefix(limit).map {
            "p\($0.page) t\($0.tableIndex) r\($0.row) c\($0.col): \($0.value)"
        }.joined(separator: "\n")
        return "cells=\(flatCells.count)\n\(prefix)"
    }

    // MARK: Parsing helpers (tolerant to dashes in trailing numeric cells)

    private static func parseFundSummaryRows(from cells: [RBSearchHit]) -> [RBFundSummary] {
        let rows = groupRows(cells)
        var out: [RBFundSummary] = []
        for r in rows {
            guard let (code, name) = inferFundCodeAndName(from: r) else { continue }
            let t = trailingMoneyTokens(in: r)
            guard t.count >= 1 else { continue }
            // Expect 4 trailing tokens; pad missing with "-"
            let four = Array(repeating: "-", count: max(0, 4 - t.count)) + Array(t.suffix(4))
            out.append(RBFundSummary(
                fundCode: code,
                fundName: name,
                appropriations2026:    money(four[safe: four.count - 4]),
                estRevenues2026:       money(four[safe: four.count - 3]),
                appropFundBalance2026: money(four[safe: four.count - 2]),
                taxLevy2026:           money(four[safe: four.count - 1])
            ))
        }
        return out
    }

    private static func parseFundBalanceRows(from cells: [RBSearchHit]) -> [RBFundBalanceRow] {
        let rows = groupRows(cells)
        var out: [RBFundBalanceRow] = []
        for r in rows {
            guard let (code, name) = inferFundCodeAndName(from: r) else { continue }
            let t = trailingMoneyTokens(in: r)
            guard t.count >= 1 else { continue }
            let four = Array(repeating: "-", count: max(0, 4 - t.count)) + Array(t.suffix(4))
            out.append(RBFundBalanceRow(
                fundCode: code,
                fundName: name,
                appropriations2026:                 money(four[safe: four.count - 4]),
                unauditedFundBalance_2024_12_31:    money(four[safe: four.count - 3]),
                applicationOfFundBalance_2024:      money(four[safe: four.count - 2]),
                estimatedFundBalance_2025_12_31:    money(four[safe: four.count - 1])
            ))
        }
        return out
    }

    private static func parseElectedSalaryRows(from cells: [RBSearchHit]) -> [RBElectedSalaryRow] {
        let rows = groupRows(cells)
        var out: [RBElectedSalaryRow] = []
        for r in rows {
            let tokens = r.map { $0.value.trimmed }
            guard tokens.count >= 3 else { continue }
            let lastTwo = tokens.suffix(2)
            let title = tokens.dropLast(2).joined(separator: " ").normalizedTitle()
            guard !title.isEmpty,
                  !title.contains("Preliminary Budget"),
                  !title.lowercased().contains("title") else { continue }
            if lastTwo.allSatisfy({ $0.isMoneyish || $0.isNumberish || $0.isDashish }) {
                out.append(RBElectedSalaryRow(
                    title: title,
                    salary2025:        money(String(lastTwo[first: 0] ?? "")),
                    salary2026Proposed:money(String(lastTwo[last: 1] ?? ""))
                ))
            }
        }
        return out
    }

    private static func parseDepartmentBudgetRows(from cells: [RBSearchHit]) -> [RBDepartmentBudgetRow] {
        let rows = groupRows(cells)
        var departmentNames: [String: String] = [:]
        var departmentPages: [String: Int] = [:]
        var subAccountsByDepartment: [String: [RBSubAccountRow]] = [:]

        for row in rows {
            guard let parsed = parseDetailedAccountRow(row) else { continue }
            let key = "\(parsed.fundCode.uppercased())-\(parsed.functionCode)"

            if parsed.objectCode == "000" {
                if !parsed.description.isEmpty {
                    departmentNames[key] = parsed.description
                }
                departmentPages[key] = min(departmentPages[key] ?? parsed.page, parsed.page)
            } else {
                subAccountsByDepartment[key, default: []].append(parsed)
                departmentPages[key] = min(departmentPages[key] ?? parsed.page, parsed.page)
            }
        }

        return subAccountsByDepartment.map { key, subAccounts in
            let first = subAccounts.first
            let parts = key.split(separator: "-", maxSplits: 1).map(String.init)
            let fund = first?.fundCode ?? parts.first ?? ""
            let function = first?.functionCode ?? (parts.count > 1 ? parts[1] : "")
            let sorted = subAccounts.sorted {
                if $0.page != $1.page { return $0.page < $1.page }
                if $0.tableIndex != $1.tableIndex { return $0.tableIndex < $1.tableIndex }
                return $0.rowIndex < $1.rowIndex
            }
            let adoptedTotal = sorted.compactMap(\.adopted2026).reduce(nil as Decimal?) { partial, value in
                (partial ?? 0) + value
            }

            return RBDepartmentBudgetRow(
                fundCode: fund,
                functionCode: function,
                name: departmentNames[key] ?? inferredDepartmentName(from: sorted, functionCode: function),
                page: departmentPages[key] ?? first?.page ?? 0,
                adopted2026: adoptedTotal,
                subAccounts: sorted
            )
        }
        .sorted {
            if $0.fundCode != $1.fundCode {
                return $0.fundCode.localizedStandardCompare($1.fundCode) == .orderedAscending
            }
            return $0.functionCode.localizedStandardCompare($1.functionCode) == .orderedAscending
        }
    }

    private static func parseDetailedAccountRow(_ row: [RBSearchHit]) -> RBSubAccountRow? {
        let sorted = row.sorted { $0.col < $1.col }
        guard let account = sorted.first(where: { $0.col == 0 })?.value.trimmed,
              account.range(of: #"^[A-Z]{1,2}\d-\d-\d{4}-\d{3}-[A-Z0-9]{3}-\d{5}$"#, options: .regularExpression) != nil else {
            return nil
        }

        let parts = account.split(separator: "-").map(String.init)
        guard parts.count >= 4 else { return nil }

        let description = sorted
            .filter { (1...3).contains($0.col) }
            .map(\.value.trimmed)
            .filter { !$0.isEmpty }
            .joined(separator: "")
            .normalizedTitle()

        let amounts = (4...7).map { column in
            money(sorted.first(where: { $0.col == column })?.value)
        }

        return RBSubAccountRow(
            fundCode: parts[0],
            functionCode: parts[2],
            objectCode: parts[3],
            accountNumber: account,
            description: description,
            page: sorted.first?.page ?? 0,
            tableIndex: sorted.first?.tableIndex ?? 0,
            rowIndex: sorted.first?.row ?? 0,
            budget2025: amounts[safe: 0] ?? nil,
            tentative2026: amounts[safe: 1] ?? nil,
            preliminary2026: amounts[safe: 2] ?? nil,
            adopted2026: amounts[safe: 3] ?? nil
        )
    }

    private static func inferredDepartmentName(from subAccounts: [RBSubAccountRow], functionCode: String) -> String {
        let candidate = subAccounts
            .first(where: { !$0.description.isEmpty })?
            .description
            .split(separator: "-")
            .first
            .map(String.init)?
            .normalizedTitle()

        if let candidate, !candidate.isEmpty {
            return candidate
        }
        return "Function \(functionCode)"
    }

    // MARK: Loaders (bundle root only; no folders)

    private static func loadFlatCSV() throws -> [RBSearchHit] {
        guard let url = Bundle.main.url(forResource: flatName, withExtension: "csv") else {
            throw NSError(
                domain: "BudgetShift",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey:
                            "Missing \(flatName).csv in bundle root (Target Membership)."]
            )
        }

        let rows = try CSV.read(url: url)
        guard let header = rows.first else { return [] }

        let idxPage  = header.firstIndex(of: "page") ?? 0
        let idxTable = header.firstIndex(of: "table_index") ?? 1
        let idxRow   = header.firstIndex(of: "row_index") ?? 2
        let idxCol   = header.firstIndex(of: "col_index") ?? 3
        let idxVal   = header.firstIndex(of: "value") ?? 4

        var out: [RBSearchHit] = []
        for row in rows.dropFirst() {
            let pg  = Int(row[safe: idxPage]  ?? "") ?? 0
            let tid = Int(row[safe: idxTable] ?? "") ?? 0
            let r   = Int(row[safe: idxRow]   ?? "") ?? 0
            let c   = Int(row[safe: idxCol]   ?? "") ?? 0
            let v   = (row[safe: idxVal] ?? "").trimmed
            out.append(.init(page: pg, tableIndex: tid, row: r, col: c, value: v))
        }
        return out
    }

    // MARK: Grouping + inference

    private struct TableRowKey: Hashable {
        let page: Int
        let tableIndex: Int
        let row: Int
    }

    private static func groupRows(_ cells: [RBSearchHit]) -> [[RBSearchHit]] {
        let grouped = Dictionary(grouping: cells) {
            TableRowKey(page: $0.page, tableIndex: $0.tableIndex, row: $0.row)
        }
        return grouped
            .sorted { lhs, rhs in
                if lhs.key.page != rhs.key.page { return lhs.key.page < rhs.key.page }
                if lhs.key.tableIndex != rhs.key.tableIndex { return lhs.key.tableIndex < rhs.key.tableIndex }
                return lhs.key.row < rhs.key.row
            }
            .map { _, arr in arr.sorted { $0.col < $1.col } }
    }

    private static func inferFundCodeAndName(from row: [RBSearchHit]) -> (String, String)? {
        let tokens = row.map { $0.value.trimmed }
        guard tokens.count >= 2 else { return nil }
        let maxLook = min(3, tokens.count - 1)
        for i in 0..<maxLook {
            let t = tokens[i]
            if t.range(of: #"^[A-Z]{1,2}\d{1,2}$"#, options: .regularExpression) != nil {
                let nameParts = tokens[(i+1)...].prefix {
                    !$0.isMoneyish && !$0.isNumberish && !$0.isDashish
                }
                let name = nameParts.joined(separator: " ").normalizedTitle()
                return (t, name)
            }
        }
        return nil
    }

    /// Take the suffix tokens that are numeric/money **or dash placeholders**.
    private static func trailingMoneyTokens(in row: [RBSearchHit]) -> [String] {
        let tokens = row.map { $0.value.trimmed }
        var out: [String] = []
        for t in tokens.reversed() {
            if t.isMoneyish || t.isNumberish || t.isDashish {
                out.append(t)
            } else {
                break
            }
        }
        return out.reversed()
    }

    // Policy helper (15% minimum reserve from appropriations)
    public static func minimumPolicyReserve(forAppropriations approp: Decimal?) -> Decimal? {
        guard let a = approp else { return nil }
        guard let minimumPercent = Decimal(string: "0.15") else {
            assertionFailure("Expected static decimal literal 0.15 to parse")
            return nil
        }
        return a * minimumPercent
    }
}

// ======================================================
// MARK: - CSV + Utilities
// ======================================================

fileprivate enum CSV {
    static func read(url: URL) throws -> [[String]] {
        let data = try Data(contentsOf: url)
        var s = String(decoding: data.dropUTF8BOMIfPresent(), as: UTF8.self)
        // Normalize line endings
        s = s.replacingOccurrences(of: "\r\n", with: "\n")
             .replacingOccurrences(of: "\r", with: "\n")
        return parse(csv: s)
    }

    static func parse(csv: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var cur = ""
        var inQuotes = false
        var i = csv.startIndex

        func pushField() { row.append(cur); cur = "" }
        func pushRow() { rows.append(row); row = [] }

        while i < csv.endIndex {
            let ch = csv[i]
            if ch == "\"" {
                if inQuotes,
                   csv.index(after: i) < csv.endIndex,
                   csv[csv.index(after: i)] == "\"" {
                    cur.append("\"")
                    i = csv.index(after: i)
                } else {
                    inQuotes.toggle()
                }
            } else if ch == "," && !inQuotes {
                pushField()
            } else if ch == "\n" && !inQuotes {
                pushField()
                pushRow()
            } else {
                cur.append(ch)
            }
            i = csv.index(after: i)
        }
        // last field/row
        pushField()
        if !row.isEmpty { pushRow() }
        return rows
    }
}

fileprivate extension Data {
    func dropUTF8BOMIfPresent() -> Data {
        if count >= 3 &&
            self[startIndex] == 0xEF &&
            self[index(startIndex, offsetBy: 1)] == 0xBB &&
            self[index(startIndex, offsetBy: 2)] == 0xBF {
            return self.dropFirst(3)
        }
        return self
    }
}

fileprivate extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var isNumberish: Bool {
        range(of: #"^\(?\$?\d[\d,]*(\.\d+)?\)?$"#,
              options: .regularExpression) != nil
    }
    var isMoneyish: Bool {
        range(of: #"^\(?\$?\d[\d,]*(\.\d+)?\)?$"#,
              options: .regularExpression) != nil
    }
    var isDashish: Bool {
        let t = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return t == "-" || t == "—" || t == "–"
    }

    func normalizedTitle() -> String {
        let s = self.replacingOccurrences(of: #"\s+"#,
                                          with: " ",
                                          options: .regularExpression)
        return s.trimmingCharacters(in: CharacterSet(charactersIn: " .,:;-"))
    }
}

fileprivate func money(_ s: String?) -> Decimal? {
    guard var raw = s?.trimmingCharacters(in: .whitespacesAndNewlines),
          !raw.isEmpty else { return nil }
    if raw == "-" || raw == "—" || raw == "–" { return nil }
    var negative = false
    if raw.hasPrefix("(") && raw.hasSuffix(")") {
        negative = true
        raw = String(raw.dropFirst().dropLast())
    }
    raw = raw.replacingOccurrences(of: "$", with: "")
             .replacingOccurrences(of: ",", with: "")
    if let d = Decimal(string: raw) {
        return negative ? (d * Decimal(-1)) : d
    }
    return nil
}

fileprivate extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: Safe element access

fileprivate extension Collection {
    /// 0 => first element, 1 => second, etc. Returns nil if out of range.
    subscript(first idx: Int) -> Element? {
        guard idx >= 0 else { return nil }
        var i = startIndex
        var n = idx
        while n > 0 {
            guard i != endIndex else { return nil }
            formIndex(after: &i)
            n -= 1
        }
        return i == endIndex ? nil : self[i]
    }
}

fileprivate extension BidirectionalCollection {
    /// 0 => last element, 1 => second-to-last, etc. Returns nil if out of range.
    subscript(last idx: Int) -> Element? {
        var i = endIndex
        for _ in 0...idx {
            guard i != startIndex else { return nil }
            formIndex(before: &i)
        }
        return self[i]
    }
}

// MARK: Unique helpers (closure + keyPath variants)

fileprivate extension Sequence {
    func unique<K: Hashable>(by key: (Element) -> K) -> [Element] {
        var seen = Set<K>()
        var result: [Element] = []
        for e in self {
            let k = key(e)
            if seen.insert(k).inserted {
                result.append(e)
            }
        }
        return result
    }

    func unique<K: Hashable>(by keyPath: KeyPath<Element, K>) -> [Element] {
        var seen = Set<K>()
        var result: [Element] = []
        for e in self {
            let k = e[keyPath: keyPath]
            if seen.insert(k).inserted {
                result.append(e)
            }
        }
        return result
    }
}
