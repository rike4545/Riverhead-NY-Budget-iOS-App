//
//  BudgetSignalsView.swift
//  Riverhead NY Budget App
//
//  Local budget-intelligence layer that surfaces notable fiscal signals
//  from bundled Riverhead budget data without requiring a network call.
//

import SwiftUI
import Foundation
import Charts

@MainActor
struct BudgetSignalsView: View {
    @Environment(RBBudgetStore.self) private var store
    @Environment(\.colorScheme) private var scheme

    @State private var didWarmUp = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroCard
                trainingPipelineCard
                summaryCard
                signalMixCard
                fundSignalsCard
                departmentSignalsCard
                followUpCard
            }
            .padding(16)
        }
        .background(RiverheadTheme.Surface.page.ignoresSafeArea())
        .navigationTitle("Budget Signals")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !didWarmUp else { return }
            didWarmUp = true
            await BudgetDataBootstrapper.warmUpAsync()
            store.refreshFromLoadedData()
        }
    }

    private var heroCard: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Budget Signals Beta")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Text("A local pattern scan powered by a tiny on-device neural network that highlights funds and departments worth a closer look based on reserve position, levy reliance, growth, staffing mix, and data confidence.")
                    .font(.subheadline)
                    .foregroundStyle(RiverheadTheme.textSecondary)

                Label("New: a reinforcement-learning calibration pass now tunes the network score before ranking signals.", systemImage: "arrow.triangle.2.circlepath")
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)

                Label("The network is calibrated from app data features, not trained on official audit labels.", systemImage: "brain")
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)

                Label("These are decision-support signals, not official audit findings or legal conclusions.", systemImage: "bolt.badge.clock")
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)
            }
        }
    }

    private var trainingPipelineCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Training Pipeline")
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Text("The app now runs a two-stage scoring path: neural inference first, then a deterministic RL-style calibration loop that rewards rankings closer to the app's fiscal-risk objectives.")
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .top, spacing: 10) {
                    pipelineNode(
                        title: "Features",
                        detail: "Reserve gap, levy share, draw, growth, volatility",
                        icon: "tablecells"
                    )

                    pipelineConnector

                    pipelineNode(
                        title: "Neural Net",
                        detail: "Dense layers produce a baseline watch score",
                        icon: "brain"
                    )

                    pipelineConnector

                    pipelineNode(
                        title: "RL Stage",
                        detail: "42-episode local reward calibration",
                        icon: "arrow.triangle.2.circlepath"
                    )
                }

                Text("This is still resident decision-support, not a formal audit model. The RL reward is based on app-defined fiscal risk features, not official labels from Town auditors.")
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var summaryCard: some View {
        let signals = allSignals
        let critical = signals.filter { $0.severity == .high }.count
        let elevated = signals.filter { $0.severity == .elevated }.count
        let watch = signals.filter { $0.severity == .watch }.count

        return card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Signal Summary")
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.textPrimary)

                HStack(spacing: 10) {
                    severityPill(count: critical, label: "High", color: .red)
                    severityPill(count: elevated, label: "Elevated", color: .orange)
                    severityPill(count: watch, label: "Watch", color: RiverheadTheme.brandSky)
                }

                Text("The neural model is currently picking up strongest on reserve usage, levy concentration, volatility, and departments whose operating footprint looks disproportionate to staffing detail.")
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var signalMixCard: some View {
        let rows = severityRows

        return card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Signal Mix")
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Text("A quick infographic of how the RL-calibrated model is distributing the current budget watchlist.")
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)

                Chart(rows) { row in
                    BarMark(
                        x: .value("Count", row.count),
                        y: .value("Severity", row.label)
                    )
                    .foregroundStyle(row.color)
                    .annotation(position: .trailing) {
                        Text("\(row.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.textSecondary)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: 118)
                .padding(.top, 4)
            }
        }
    }

    private var fundSignalsCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Fund Signals")
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Text("Funds ranked by the strongest local risk or watch signals in the current dataset.")
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)

                if fundSignals.isEmpty {
                    ContentUnavailableView(
                        "No fund signals yet",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Budget data may still be loading.")
                    )
                } else {
                    ForEach(fundSignals) { signal in
                        NavigationLink {
                            FundDetailView(fund: signal.navigationFund)
                                .environment(store)
                        } label: {
                            signalRow(signal)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var departmentSignalsCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Department Signals")
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Text("Operational and data-quality patterns inferred from the department budget lens.")
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)

                ForEach(departmentSignals) { signal in
                    signalRow(signal)
                }
            }
        }
    }

    private var followUpCard: some View {
        let prompt = buildFollowUpPrompt()

        return card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Take This Further")
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Text("Open the in-app assistant with a prefilled question that asks it to explain the biggest local budget signals in plain English.")
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                NavigationLink {
                    AskAIView(initialPrompt: prompt)
                        .environment(store)
                } label: {
                    Label("Ask AI About These Signals", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(RiverheadTheme.brandSky)
            }
        }
    }

    private func severityPill(count: Int, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(count)")
                .font(.headline.weight(.bold))
                .foregroundStyle(RiverheadTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(RiverheadTheme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(color.opacity(scheme == .dark ? 0.22 : 0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func pipelineNode(title: String, detail: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(RiverheadTheme.brandSky)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RiverheadTheme.textPrimary)

            Text(detail)
                .font(.caption2)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(RiverheadTheme.softBorder, lineWidth: 1)
        )
    }

    private var pipelineConnector: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.bold))
            .foregroundStyle(RiverheadTheme.textSecondary)
            .padding(.top, 32)
    }

    private func signalRow(_ signal: BudgetSignal) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: signal.icon)
                .font(.title3)
                .foregroundStyle(signal.severity.color)
                .frame(width: 30, height: 30)
                .padding(8)
                .background(signal.severity.color.opacity(scheme == .dark ? 0.20 : 0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    Text(signal.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.textPrimary)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 8)

                    Text(signal.severity.label)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(signal.severity.color.opacity(scheme == .dark ? 0.22 : 0.12), in: Capsule())
                        .foregroundStyle(signal.severity.color)
                }

                Text(signal.detail)
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(signal.whyItMatters)
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.softBorder, lineWidth: 1)
        )
    }

    private var rowBackground: Color {
        scheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.82)
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(RiverheadTheme.Surface.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(RiverheadTheme.softBorder, lineWidth: 1)
        )
    }

    private var fundSignals: [BudgetSignal] {
        RiverheadBudgetSignalEngine.makeFundSignals(store: store)
    }

    private var departmentSignals: [BudgetSignal] {
        RiverheadBudgetSignalEngine.makeDepartmentSignals()
    }

    private var allSignals: [BudgetSignal] {
        (fundSignals + departmentSignals).sorted { $0.score > $1.score }
    }

    private var severityRows: [SignalSeverityRow] {
        let signals = allSignals
        return [
            SignalSeverityRow(label: "High", count: signals.filter { $0.severity == .high }.count, color: .red),
            SignalSeverityRow(label: "Elevated", count: signals.filter { $0.severity == .elevated }.count, color: .orange),
            SignalSeverityRow(label: "Watch", count: signals.filter { $0.severity == .watch }.count, color: RiverheadTheme.brandSky)
        ]
    }

    private func buildFollowUpPrompt() -> String {
        let topSignals = allSignals.prefix(3).map(\.title).joined(separator: "; ")
        if topSignals.isEmpty {
            return "What budget signals should Riverhead residents pay closest attention to in the current app data?"
        }

        return "Explain these Riverhead budget signals in plain English and tell me which one matters most for residents: \(topSignals)."
    }
}

private enum BudgetSignalSeverity: Equatable {
    case high
    case elevated
    case watch

    var label: String {
        switch self {
        case .high:
            return "High"
        case .elevated:
            return "Elevated"
        case .watch:
            return "Watch"
        }
    }

    var color: Color {
        switch self {
        case .high:
            return .red
        case .elevated:
            return .orange
        case .watch:
            return RiverheadTheme.brandSky
        }
    }
}

private struct BudgetSignal: Identifiable {
    let id: String
    let title: String
    let detail: String
    let whyItMatters: String
    let severity: BudgetSignalSeverity
    let score: Int
    let icon: String
    let navigationFund: String
}

private struct SignalSeverityRow: Identifiable {
    let label: String
    let count: Int
    let color: Color

    var id: String { label }
}

@MainActor
private enum RiverheadBudgetSignalEngine {
    static func makeFundSignals(store: RBBudgetStore) -> [BudgetSignal] {
        let summaries = Riverhead2026BudgetShift.fundSummaries()
        let balances = Dictionary(
            uniqueKeysWithValues: Riverhead2026BudgetShift.fundBalances().map { ($0.fundCode.uppercased(), $0) }
        )

        return summaries.compactMap { summary in
            guard let appropriations = decimalToDouble(summary.appropriations2026), appropriations > 0 else {
                return nil
            }

            let levy = decimalToDouble(summary.taxLevy2026) ?? 0
            let levyShare = levy / appropriations
            let appFundBalance = decimalToDouble(summary.appropFundBalance2026) ?? 0
            let drawShare = appFundBalance / appropriations
            let balance = balances[summary.fundCode.uppercased()]
            let estimatedFundBalance = decimalToDouble(balance?.estimatedFundBalance_2025_12_31)
            let reserveRatio = estimatedFundBalance.map { $0 / appropriations }
            let yoyGrowth = yoyGrowthPercent(for: summary, store: store)
            let volatility = appropriationVolatility(for: summary, store: store)

            let reserveGap = max(0, 0.20 - (reserveRatio ?? 0)) / 0.20
            let probability = RiverheadBudgetNeuralSignals.fundProbability(
                reserveGap: reserveGap,
                levyShare: levyShare,
                drawShare: drawShare,
                growthRate: yoyGrowth ?? 0,
                volatility: volatility
            )
            let rlResult = RiverheadBudgetRLTrainer.calibrateFundScore(
                neuralProbability: probability,
                reserveGap: reserveGap,
                levyShare: levyShare,
                drawShare: drawShare,
                growthRate: yoyGrowth ?? 0,
                volatility: volatility
            )
            let score = Int((rlResult.adjustedProbability * 100).rounded())
            var reasons: [String] = []
            var why: [String] = []
            var icon = "waveform.path.ecg"

            if let reserveRatio, reserveRatio < 0.15 {
                reasons.append("estimated fund balance is only \(percent(reserveRatio)) of appropriations")
                why.append("That is below the app's own 15% floor and leaves less room for shocks.")
                icon = "exclamationmark.shield"
            } else if let reserveRatio, reserveRatio < 0.20 {
                reasons.append("estimated fund balance is \(percent(reserveRatio)) of appropriations")
                why.append("That is above the floor, but still close enough that a bad year can narrow options quickly.")
                icon = "gauge.with.dots.needle.33percent"
            }

            if levyShare > 0.70 {
                reasons.append("tax levy covers \(percent(levyShare)) of appropriations")
                why.append("Heavy levy dependence can make next year's budget more sensitive to tax-cap and affordability pressure.")
                icon = "building.columns.circle"
            } else if levyShare > 0.50 {
                reasons.append("tax levy covers \(percent(levyShare)) of appropriations")
                why.append("That is not automatically bad, but it does make the fund more resident-tax sensitive.")
                icon = "building.columns.circle"
            }

            if drawShare > 0.08 {
                reasons.append("appropriated fund balance equals \(percent(drawShare)) of spending")
                why.append("A larger reserve draw can patch a year, but it is not a recurring revenue source.")
                icon = "arrow.down.circle"
            } else if drawShare > 0.03 {
                reasons.append("appropriated fund balance equals \(percent(drawShare)) of spending")
                why.append("Even a moderate reserve draw is worth watching if recurring costs keep climbing.")
                icon = "arrow.down.circle"
            }

            if let yoyGrowth, yoyGrowth > 0.10 {
                reasons.append("2026 appropriations are up \(percent(yoyGrowth)) from 2025")
                why.append("Faster growth usually deserves a plain-English explanation so residents know what is structural versus one-time.")
                icon = "chart.line.uptrend.xyaxis"
            } else if let yoyGrowth, yoyGrowth > 0.05 {
                reasons.append("2026 appropriations are up \(percent(yoyGrowth)) from 2025")
                why.append("This is not extreme, but it is large enough to merit context.")
                icon = "chart.line.uptrend.xyaxis"
            }

            if volatility > 0.22 {
                reasons.append("recent appropriations have been relatively volatile")
                why.append("Volatility can make it harder for residents and officials to separate a durable trend from a short-term swing.")
                icon = "waveform.path.ecg"
            }

            guard score >= 34 else { return nil }
            let firstReason = reasons.first ?? "the neural model flags this fund as one of the stronger current watch items"

            let severity: BudgetSignalSeverity
            switch score {
            case 75...:
                severity = .high
            case 55...:
                severity = .elevated
            default:
                severity = .watch
            }

            let display = "\(summary.fundCode) • \(summary.fundName)"
            return BudgetSignal(
                id: "fund-\(summary.fundCode)",
                title: display,
                detail: firstReason.capitalized + ".",
                whyItMatters: why.first ?? "This fund deserves a closer look in the detail view.",
                severity: severity,
                score: score,
                icon: icon,
                navigationFund: resolveFundName(display: display, store: store)
            )
        }
        .sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.title < rhs.title
        }
        .prefix(6)
        .map { $0 }
    }

    static func makeDepartmentSignals() -> [BudgetSignal] {
        DepartmentBudgetLensData.departmentRecords.compactMap { record in
            let personnelShare = record.personnelShare ?? 0
            let nonPersonnelShare = max(0, 1 - personnelShare)
            let mismatch = record.personnelShare.map { max(0, $0 - 1) } ?? 0
            let thinStaffing = record.positions.map { $0 <= 3 ? 1.0 - (Double($0) / 3.0 * 0.35) : 0 } ?? 0.95
            let missingData = (record.positions == nil || record.salaryBase == nil) ? 1.0 : 0.0
            let budgetScale = min(record.adoptedTotal / 2_500_000, 1)
            let probability = RiverheadBudgetNeuralSignals.departmentProbability(
                payrollMismatch: mismatch,
                nonPersonnelShare: nonPersonnelShare,
                thinStaffing: thinStaffing,
                missingData: missingData,
                budgetScale: budgetScale
            )
            let rlResult = RiverheadBudgetRLTrainer.calibrateDepartmentScore(
                neuralProbability: probability,
                payrollMismatch: mismatch,
                nonPersonnelShare: nonPersonnelShare,
                thinStaffing: thinStaffing,
                missingData: missingData,
                budgetScale: budgetScale
            )
            let score = Int((rlResult.adjustedProbability * 100).rounded())
            var detail: String?
            var why: String?
            var icon = "building.2.crop.circle"

            if let personnelShare = record.personnelShare {
                if personnelShare > 1.02 {
                    if record.fundCode == "A01-1420" {
                        detail = "Town Attorney crosswalk needs confirmation: 16 positions map to $1.594M of salary against a $1.429M function 1420 budget."
                        why = "The roughly $165K overage likely reflects fire marshal and code-compliance titles that should be allocated to functions 3625/3620 rather than 1420."
                    } else {
                        detail = "Mapped salary base runs above the adopted total for this function."
                        why = "That usually means the staffing-to-budget match is imperfect, so residents should read the number carefully before drawing conclusions."
                    }
                    icon = "exclamationmark.triangle"
                } else if record.adoptedTotal > 1_500_000, nonPersonnelShare > 0.45 {
                    detail = "\(percent(nonPersonnelShare)) of the function appears to sit outside base payroll."
                    why = "Large non-salary layers can mean vehicles, equipment, contracted services, or other operating drivers are doing more of the work than headcount alone suggests."
                    icon = "shippingbox"
                } else if personnelShare > 0.82, record.adoptedTotal > 500_000 {
                    detail = "The function looks highly payroll-concentrated at about \(percent(personnelShare))."
                    why = "That kind of budget is especially sensitive to contract settlements, overtime, and vacancy changes."
                    icon = "person.3.sequence"
                }
            }

            if let positions = record.positions, positions <= 3, record.adoptedTotal > 500_000 {
                detail = detail ?? "A relatively small staff is tied to a comparatively large operating budget."
                why = why ?? "Thin bench departments can feel pressure quickly when one vacancy, retirement, or workload spike hits."
                icon = "person.crop.circle.badge.exclamationmark"
            }

            if record.positions == nil || record.salaryBase == nil {
                if record.adoptedTotal > 600_000 {
                    detail = detail ?? "The budget function is sizeable, but staffing detail is incomplete."
                    why = why ?? "Incomplete mapping is a signal in itself because it makes it harder for residents to connect appropriation totals to actual operating drivers."
                    icon = "questionmark.folder"
                }
            }

            let loweredNote = record.note?.lowercased() ?? ""
            if loweredNote.contains("does not map perfectly")
                || loweredNote.contains("not separated")
                || loweredNote.contains("not separate")
                || loweredNote.contains("not separated cleanly") {
                detail = detail ?? "The app's staffing-to-budget mapping is explicitly fuzzy here."
                why = why ?? "This is worth flagging so users do not overread a tidy-looking number that actually has some matching uncertainty behind it."
                icon = "arrow.triangle.branch"
            }

            guard score >= 36 else { return nil }
            let finalDetail = detail ?? "The neural model flags this department as an outsized operating or data-quality watch item."
            let finalWhy = why ?? "It stands out relative to the app's other department inputs on size, staffing profile, or mapping certainty."

            let severity: BudgetSignalSeverity
            switch score {
            case 76...:
                severity = .high
            case 56...:
                severity = .elevated
            default:
                severity = .watch
            }

            return BudgetSignal(
                id: "dept-\(record.id)",
                title: record.budgetDepartment,
                detail: finalDetail,
                whyItMatters: finalWhy,
                severity: severity,
                score: score,
                icon: icon,
                navigationFund: record.budgetDepartment
            )
        }
        .sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.title < rhs.title
        }
        .prefix(6)
        .map { $0 }
    }

    private static func resolveFundName(display: String, store: RBBudgetStore) -> String {
        if let exact = store.funds.first(where: { $0.compare(display, options: .caseInsensitive) == .orderedSame }) {
            return exact
        }

        let displayName = display.components(separatedBy: "•").last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? display
        if let byName = store.funds.first(where: { fund in
            guard let fundName = fund.components(separatedBy: "•").last?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                return false
            }
            return fundName.compare(displayName, options: .caseInsensitive) == .orderedSame
        }) {
            return byName
        }

        return display
    }

    private static func yoyGrowthPercent(for summary: RBFundSummary, store: RBBudgetStore) -> Double? {
        let display = "\(summary.fundCode) • \(summary.fundName)"
        let storeKey = resolveFundName(display: display, store: store)
        let series = store.valueSeries(for: storeKey, metric: .appropriations).sorted { $0.year < $1.year }

        guard
            let current = series.first(where: { $0.year == 2026 })?.value,
            let previous = series.first(where: { $0.year == 2025 })?.value,
            previous != 0
        else {
            return nil
        }

        return (current / previous) - 1
    }

    private static func appropriationVolatility(for summary: RBFundSummary, store: RBBudgetStore) -> Double {
        let display = "\(summary.fundCode) • \(summary.fundName)"
        let storeKey = resolveFundName(display: display, store: store)
        let values = store.valueSeries(for: storeKey, metric: .appropriations)
            .sorted { $0.year < $1.year }
            .map(\.value)

        guard values.count >= 3 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        guard mean > 0 else { return 0 }

        let variance = values.reduce(0) { partial, value in
            let delta = value - mean
            return partial + (delta * delta)
        } / Double(values.count)

        return min(sqrt(variance) / mean, 1)
    }

    private static func decimalToDouble(_ value: Decimal?) -> Double? {
        guard let value else { return nil }
        return NSDecimalNumber(decimal: value).doubleValue
    }

    private static func percent(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "\(value * 100)%"
    }
}
