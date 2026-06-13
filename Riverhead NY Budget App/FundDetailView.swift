//
//  FundDetailView.swift
//  Riverhead NY Budget App
//
//  FIXED (compile-safe) replacement.
//  - Removes stray braces that were closing the struct early (which made `fund`/`store` “out of scope”).
//  - Breaks up the “keep last 7 years” expressions to avoid type-checker timeouts.
//  - Keeps existing features: KPIs, YoY chips, trend chart, policy coverage, 2026 details, warm-up loader.
//
//  Swift 6 • iOS 17+
//

import SwiftUI
import Observation
import Charts

private let targetYear: Int = 2026

@MainActor
public struct FundDetailView: View {
    @Environment(RBBudgetStore.self) private var store
    public let fund: String // e.g. "A01 • General Fund" or "General Fund"

    public init(fund: String) { self.fund = fund }

    @State private var didWarmUpData: Bool = false
    @State private var isWarmingData: Bool = false

    // MARK: Body

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                kpiGrid
                trendsCard
                policyCard
                detailsCard
                departmentsCard
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
        }
        .navigationTitle(displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await warmUpIfNeeded() }
        .overlay(alignment: .top) {
            if isWarmingData {
                ProgressView("Loading data…")
                    .padding(10)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.top, 6)
            }
        }
        .refreshable { await warmUpIfNeeded(force: true) }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(displayTitle)
                .font(.largeTitle.bold())
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Text("Key figures and recent trends")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Use the canonical "CODE • Name" if we can; avoid double-prefixing the code.
    private var displayTitle: String {
        if fund.contains("•") { return fund }
        if let s = matchedSummary() { return "\(s.fundCode) • \(s.fundName)" }
        return fund
    }

    // MARK: KPIs

    private var kpiGrid: some View {
        let money = Self.moneyFormatter0
        func fmtMoney(_ d: Decimal?) -> String {
            guard let x = (d as NSDecimalNumber?)?.doubleValue else { return "—" }
            return money.string(from: x as NSNumber) ?? String(format: "%.0f", x)
        }

        // Canonical 2026 numbers (if available)
        let sum2026 = matchedSummary()
        // Merged series includes store + prior-years from PDFs + 2026 fallback
        let merged = mergedSeries()

        let levyYoY = yoy(for: merged.levy)
        let appYoY  = yoy(for: merged.app)

        let cols = [GridItem(.adaptive(minimum: 160, maximum: 240), spacing: 12, alignment: .topLeading)]

        return LazyVGrid(columns: cols, spacing: 12) {
            kpiCard(
                title: "Tax Levy (2026)",
                value: {
                    if let d = sum2026?.taxLevy2026 { return fmtMoney(d) }
                    if let v = merged.levy.first(where: { $0.year == targetYear })?.value {
                        return money.string(from: v as NSNumber) ?? String(format: "%.0f", v)
                    }
                    return "—"
                }(),
                chip: levyYoY.map { "vs 2025: \($0.delta) (\($0.pct))" }
            )

            kpiCard(
                title: "Appropriations (2026)",
                value: {
                    if let d = sum2026?.appropriations2026 { return fmtMoney(d) }
                    if let v = merged.app.first(where: { $0.year == targetYear })?.value {
                        return money.string(from: v as NSNumber) ?? String(format: "%.0f", v)
                    }
                    return "—"
                }(),
                chip: appYoY.map { "vs 2025: \($0.delta) (\($0.pct))" }
            )

            kpiCard(
                title: "Est. Revenues (2026)",
                value: fmtMoney(sum2026?.estRevenues2026),
                chip: nil
            )

            kpiCard(
                title: "Approp. Fund Balance (2026)",
                value: fmtMoney(sum2026?.appropFundBalance2026),
                chip: nil
            )
        }
    }

    private func kpiCard(title: String, value: String, chip: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(value)
                .font(.title2.weight(.bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            if let chip = chip {
                Label(chip, systemImage: "arrow.up.right")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08))
        )
    }

    // MARK: Trends

    private var trendsCard: some View {
        let merged = mergedSeries()

        let years = Array(Set(merged.levy.map(\.year) + merged.app.map(\.year))).sorted()
        let levyMap = Dictionary(uniqueKeysWithValues: merged.levy.map { ($0.year, $0.value) })
        let appMap  = Dictionary(uniqueKeysWithValues: merged.app.map  { ($0.year, $0.value) })
        let rows = years.map { (year: $0, levy: levyMap[$0], app: appMap[$0]) }

        return VStack(alignment: .leading, spacing: 10) {
            Text("Trends (last 7)")
                .font(.headline)

            Chart {
                ForEach(rows, id: \.year) { r in
                    if let v = r.levy {
                        LineMark(
                            x: .value("Year", r.year),
                            y: .value("Levy", v)
                        )
                        .interpolationMethod(.monotone)
                    }
                    if let v = r.app {
                        LineMark(
                            x: .value("Year", r.year),
                            y: .value("Appropriations", v)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { v in
                    if let y = v.as(Int.self) {
                        AxisValueLabel { Text("\(y)") }
                    }
                }
            }
            .frame(height: 180)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06)))
            .accessibilityHidden(true)

            HStack(spacing: 12) {
                legendDot()
                Text("Levy").font(.caption)
                legendDot(secondary: true)
                Text("Appropriations")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 6)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08)))
    }

    private func legendDot(secondary: Bool = false) -> some View {
        Circle()
            .frame(width: 8, height: 8)
            .foregroundStyle(secondary ? .secondary : .primary)
    }

    // MARK: Policy Card (clamped ProgressView)

    private var policyCard: some View {
        guard let sum = matchedSummary() else { return AnyView(EmptyView()) }

        let bal = Riverhead2026BudgetShift.fundBalances().first {
            $0.fundCode.compare(sum.fundCode, options: .caseInsensitive) == .orderedSame
            || normalize($0.fundName) == normalize(fund)
        }
        let target = Riverhead2026BudgetShift.minimumPolicyReserve(forAppropriations: sum.appropriations2026)
        let est25  = bal?.estimatedFundBalance_2025_12_31

        // Show only if we have at least one side to display
        guard target != nil || est25 != nil else { return AnyView(EmptyView()) }

        let money = Self.moneyFormatter0
        func fmt(_ d: Decimal?) -> String {
            guard let x = (d as NSDecimalNumber?)?.doubleValue else { return "—" }
            return money.string(from: x as NSNumber) ?? String(format: "%.0f", x)
        }

        // Compute coverage safely (Est. FB / Target), clamp to 0...1 for the bar,
        // and show true percent in the label (capped visually to 300%).
        var clampedProgress: Double? = nil
        var displayPct: String? = nil
        var overTarget = false

        if
            let t = (target as NSDecimalNumber?)?.doubleValue, t > 0,
            let e = (est25  as NSDecimalNumber?)?.doubleValue,
            e.isFinite
        {
            let coverage = e / t
            overTarget = coverage > 1
            clampedProgress = max(0, min(coverage, 1))

            let shown = min(max(coverage, 0), 3) * 100
            displayPct = String(format: "%.0f%%", shown)
        }

        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                Text("Fund Balance Policy")
                    .font(.headline)

                Text("Target is at least 15% of appropriations.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let p = clampedProgress {
                    ProgressView(value: p, total: 1)   // always within 0...1 now
                        .progressViewStyle(.linear)
                        .tint(overTarget ? .green : .blue)

                    HStack {
                        Text("Est. FB 12/31/25: \(fmt(est25))")
                        Spacer()
                        if let dp = displayPct {
                            Group {
                                if overTarget {
                                    Label(dp, systemImage: "checkmark.seal.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    Text(dp)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        Text("Target (15%): \(fmt(target))")
                            .foregroundStyle(.secondary)
                    }
                    .font(.footnote)
                } else {
                    HStack {
                        Text("Est. FB 12/31/25: \(fmt(est25))")
                        Spacer()
                        Text("Target (15%): \(fmt(target))")
                            .foregroundStyle(.secondary)
                    }
                    .font(.footnote)
                }
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08)))
        )
    }

    // MARK: 2026 Details

    private var detailsCard: some View {
        let sum = matchedSummary()
        let money = Self.moneyFormatter0
        func fmt(_ d: Decimal?) -> String {
            guard let x = (d as NSDecimalNumber?)?.doubleValue else { return "—" }
            return money.string(from: x as NSNumber) ?? String(format: "%.0f", x)
        }

        return VStack(alignment: .leading, spacing: 10) {
            Text("2026 Details")
                .font(.headline)

            VStack(spacing: 8) {
                rowKV("Appropriations", fmt(sum?.appropriations2026))
                rowKV("Estimated Revenues", fmt(sum?.estRevenues2026))
                rowKV("Appropriated Fund Balance", fmt(sum?.appropFundBalance2026))
                rowKV("Tax Levy", fmt(sum?.taxLevy2026))
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08)))
    }

    private var departmentsCard: some View {
        let departments = departmentRows()

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Departments & Sub-Accounts")
                    .font(.headline)
                Spacer()
                Text("\(departments.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if departments.isEmpty {
                ContentUnavailableView(
                    "No department rows found",
                    systemImage: "list.bullet.rectangle",
                    description: Text("The bundled 2026 table data does not expose department-level rows for this fund yet.")
                )
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(departments) { department in
                        NavigationLink {
                            DepartmentBudgetDetailView(department: department)
                        } label: {
                            DepartmentLinkRow(department: department)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08)))
    }

    private func rowKV(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).foregroundStyle(.secondary)
            Spacer()
            Text(v).monospacedDigit()
        }
        .font(.callout)
    }

    // MARK: Data & Matching

    /// Merge store series + prior-year PDF series + 2026 fallback (for display only).
    private func mergedSeries() -> (levy: [(year: Int, value: Double)], app: [(year: Int, value: Double)]) {
        // Start with store
        var levy = store.valueSeries(for: fund, metric: .taxLevy)
        var app  = store.valueSeries(for: fund, metric: .appropriations)

        // Add prior years from PDFs (fill missing years only)
        let hist = BudgetHistoryShift.historicalSeries(forFundName: fund)

        for (y, d) in hist.levy where !levy.contains(where: { $0.year == y }) {
            levy.append((year: y, value: (d as NSDecimalNumber).doubleValue))
        }
        for (y, d) in hist.app where !app.contains(where: { $0.year == y }) {
            app.append((year: y, value: (d as NSDecimalNumber).doubleValue))
        }

        // Add 2026 canonical fallback from the 2026 summary row
        if let sum = matchedSummary() {
            func toD(_ d: Decimal?) -> Double? { (d as NSDecimalNumber?)?.doubleValue }

            if !levy.contains(where: { $0.year == targetYear }), let L = toD(sum.taxLevy2026) {
                levy.append((year: targetYear, value: L))
            }
            if !app.contains(where: { $0.year == targetYear }), let A = toD(sum.appropriations2026) {
                app.append((year: targetYear, value: A))
            }
        }

        // Clamp to <= 2026 and keep last 7 (split up to avoid type-checker timeouts)
        levy = levy.filter { $0.year <= targetYear }
        levy.sort { $0.year < $1.year }
        if levy.count > 7 { levy = Array(levy.suffix(7)) }

        app = app.filter { $0.year <= targetYear }
        app.sort { $0.year < $1.year }
        if app.count > 7 { app = Array(app.suffix(7)) }

        return (levy, app)
    }

    /// YoY delta and pct vs 2025 for a series (if both 2025 and 2026 exist).
    private func yoy(for series: [(year: Int, value: Double)]) -> (delta: String, pct: String)? {
        guard
            let v2026 = series.first(where: { $0.year == targetYear })?.value,
            let v2025 = series.first(where: { $0.year == targetYear - 1 })?.value,
            v2025 != 0
        else { return nil }

        let delta = v2026 - v2025
        let pct   = v2026 / v2025 - 1

        let dStr = Self.moneyFormatter0.string(from: delta as NSNumber) ?? String(format: "%.0f", delta)
        let pStr = Self.percentFormatter1.string(from: pct as NSNumber) ?? "—"
        return (dStr, pStr)
    }

    /// Match this fund to the 2026 Summary row for canonical 2026 values.
    private func matchedSummary() -> RBFundSummary? {
        let all = Riverhead2026BudgetShift.fundSummaries()

        // 1) If fund is already "CODE • Name", try to match by code first
        if let code = codeToken(from: fund),
           let hit = all.first(where: { $0.fundCode.compare(code, options: .caseInsensitive) == .orderedSame }) {
            return hit
        }

        // 2) Exact normalized name
        if let hit = all.first(where: { normalize($0.fundName) == normalize(fund) }) {
            return hit
        }

        // 3) Contains (either way)
        if let hit = all.first(where: {
            let lhs = normalize($0.fundName)
            let rhs = normalize(fund)
            return lhs.contains(rhs) || rhs.contains(lhs)
        }) {
            return hit
        }

        return nil
    }

    private func departmentRows() -> [RBDepartmentBudgetRow] {
        guard let code = matchedSummary()?.fundCode ?? codeToken(from: displayTitle) else { return [] }
        return Riverhead2026BudgetShift.departmentBudgets(fundCode: code)
    }

    private func codeToken(from s: String) -> String? {
        let first = s.split(separator: " ").first.map(String.init) ?? ""
        return first.range(of: #"^[A-Z]{1,2}\d{1,2}$"#, options: .regularExpression) != nil ? first : nil
    }

    private func normalize(_ s: String) -> String {
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

    // MARK: Warm-up

    private func warmUpIfNeeded(force: Bool = false) async {
        if didWarmUpData && !force { return }
        didWarmUpData = true
        isWarmingData = true

        await Task.detached(priority: .utility) {
            _ = BudgetHistoryShift.ensureLoaded()
            if Riverhead2026BudgetShift.lastLoadCount == 0 {
                _ = try? Riverhead2026BudgetShift.load()
            }
        }.value

        isWarmingData = false
    }

    // MARK: Formatters

    fileprivate static let moneyFormatter0: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.maximumFractionDigits = 0
        return nf
    }()

    private static let percentFormatter1: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .percent
        nf.maximumFractionDigits = 1
        return nf
    }()
}

private struct DepartmentLinkRow: View {
    let department: RBDepartmentBudgetRow

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "building.2.fill")
                .font(.headline)
                .foregroundStyle(RiverheadTheme.accent)
                .frame(width: 34, height: 34)
                .background(RiverheadTheme.accent.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(department.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                    .multilineTextAlignment(.leading)

                Text("\(department.fundCode) function \(department.functionCode) • \(department.subAccounts.count) sub-accounts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(Self.money(department.adopted2026))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private static func money(_ value: Decimal?) -> String {
        guard let amount = (value as NSDecimalNumber?)?.doubleValue else { return "—" }
        return FundDetailView.moneyFormatter0.string(from: amount as NSNumber) ?? String(format: "%.0f", amount)
    }
}

private struct DepartmentBudgetDetailView: View {
    let department: RBDepartmentBudgetRow
    @State private var searchText = ""

    private var filteredSubAccounts: [RBSubAccountRow] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return department.subAccounts }
        return department.subAccounts.filter {
            $0.accountNumber.lowercased().contains(query) ||
            $0.description.lowercased().contains(query) ||
            $0.objectCode.lowercased().contains(query)
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(department.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RiverheadTheme.textPrimary)

                    Text("\(department.fundCode) function \(department.functionCode)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        Label("\(department.subAccounts.count) sub-accounts", systemImage: "list.bullet.rectangle")
                        Spacer()
                        Text(Self.money(department.adopted2026))
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Sub-Accounts") {
                ForEach(filteredSubAccounts) { account in
                    NavigationLink {
                        SubAccountDetailView(account: account, departmentName: department.name)
                    } label: {
                        SubAccountLinkRow(account: account)
                    }
                }
            }
        }
        .navigationTitle(department.name)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search sub-account or code")
    }

    private static func money(_ value: Decimal?) -> String {
        guard let amount = (value as NSDecimalNumber?)?.doubleValue else { return "—" }
        return FundDetailView.moneyFormatter0.string(from: amount as NSNumber) ?? String(format: "%.0f", amount)
    }
}

private struct SubAccountLinkRow: View {
    let account: RBSubAccountRow

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(account.description.isEmpty ? "Sub-account \(account.objectCode)" : account.description)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                    .lineLimit(2)

                Spacer(minLength: 8)

                Text(Self.money(account.adopted2026))
                    .font(.footnote.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Text(account.accountNumber)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding(.vertical, 3)
    }

    private static func money(_ value: Decimal?) -> String {
        guard let amount = (value as NSDecimalNumber?)?.doubleValue else { return "—" }
        return FundDetailView.moneyFormatter0.string(from: amount as NSNumber) ?? String(format: "%.0f", amount)
    }
}

private struct SubAccountDetailView: View {
    let account: RBSubAccountRow
    let departmentName: String

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(account.description.isEmpty ? "Sub-account \(account.objectCode)" : account.description)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.textPrimary)

                    Text(account.accountNumber)
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)

                    Text(departmentName)
                        .font(.subheadline)
                        .foregroundStyle(RiverheadTheme.accent)
                }
                .padding(.vertical, 4)
            }

            Section("Budget Values") {
                valueRow("2025 Budget", account.budget2025)
                valueRow("2026 Tentative", account.tentative2026)
                valueRow("2026 Preliminary", account.preliminary2026)
                valueRow("2026 Adopted", account.adopted2026)
            }

            Section("Source") {
                LabeledContent("Fund", value: account.fundCode)
                LabeledContent("Function", value: account.functionCode)
                LabeledContent("Object", value: account.objectCode)
                LabeledContent("PDF page", value: "\(account.page)")
                LabeledContent("Table row", value: "\(account.rowIndex)")
            }
        }
        .navigationTitle("Sub-Account")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func valueRow(_ title: String, _ value: Decimal?) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(Self.money(value))
                .fontWeight(title == "2026 Adopted" ? .semibold : .regular)
                .monospacedDigit()
                .foregroundStyle(title == "2026 Adopted" ? RiverheadTheme.accent : .secondary)
        }
    }

    private static func money(_ value: Decimal?) -> String {
        guard let amount = (value as NSDecimalNumber?)?.doubleValue else { return "—" }
        return FundDetailView.moneyFormatter0.string(from: amount as NSNumber) ?? String(format: "%.0f", amount)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FundDetailView(fund: "General Fund")
            .environment(RBBudgetStore())
    }
}
