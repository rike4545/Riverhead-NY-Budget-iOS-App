import SwiftUI
import Charts

// MARK: - Local GlassCard

private struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let title: String?; let subtitle: String?
    @ViewBuilder var content: Content
    init(title: String? = nil, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title; self.subtitle = subtitle; self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title { Text(title).font(.headline).foregroundStyle(RiverheadTheme.textPrimary) }
            if let subtitle { Text(subtitle).font(.footnote).foregroundStyle(RiverheadTheme.textSecondary) }
            content
        }
        .padding(14)
        .background(
            (reduceTransparency ? AnyShapeStyle(RiverheadTheme.Surface.card) : AnyShapeStyle(scheme == .dark ? .ultraThinMaterial : .regularMaterial)),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(RiverheadTheme.border.opacity(scheme == .dark ? 0.35 : 0.2)))
        .shadow(color: .black.opacity(scheme == .dark ? 0.25 : 0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Data

private struct FBPoint: Identifiable {
    let id = UUID()
    let year: Int
    let unassigned: Double      // year-end unassigned General Fund balance (dollars)
    let appropriations: Double  // the next year's adopted General Fund appropriations (dollars)
    let source: PointSource

    enum PointSource {
        case audit      // the Town's independent audit of that year
    }

    var percent: Double { guard appropriations > 0 else { return 0 }; return unassigned / appropriations }
}

// MARK: - Historical series
//
// The same audited series the website uses (web/lib/audits.ts): each year-end
// unassigned General Fund balance from that year's independent audit, over the
// next year's adopted General Fund appropriations, so 2025 reads 41.7% as it
// does on the website's reserves and credit pages.
//  • 2023: $21,848,178 (2023 Audited Basic Financial Statement) over the 2024
//    Adopted Budget's $60,797,800.
//  • 2024: $23,887,952 (2024 Audited Basic Financial Statements) over the 2025
//    Adopted Budget's $64,852,829.
//  • 2025: $28,829,513 (2025 audited financial statements, accepted by the
//    Town Board September 1, 2026, Resolution 2026-834) over the 2026 Adopted
//    Budget's $69,113,159.
// Earlier years are left out: the app used to show estimates for 2014-2024,
// and the two it could check against audits ran $4-5 million high.
private let historicalPoints: [FBPoint] = [
    .init(year: 2023, unassigned: 21_848_178, appropriations: 60_797_800, source: .audit),
    .init(year: 2024, unassigned: 23_887_952, appropriations: 64_852_829, source: .audit),
    .init(year: 2025, unassigned: 28_829_513, appropriations: 69_113_159, source: .audit),
]

// MARK: - View

@MainActor
struct FundBalanceTrendView: View {

    @Environment(RBBudgetStore.self) private var store

    @State private var selectedYear: Int? = nil
    @State private var showDollars: Bool = false

    private let gfoaBenchmark = 1.0 / 6.0   // 16.7%
    private let policyMin     = 0.15
    private let policyUpper   = 0.20   // a reference line only; the Town's policy has no ceiling

    private var points: [FBPoint] { historicalPoints }

    private var selectedPoint: FBPoint? {
        guard let y = selectedYear else { return nil }
        return points.first { $0.year == y }
    }

    var body: some View {
        Group {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    chartCard
                    if let pt = selectedPoint { detailCard(for: pt) }
                    narrativeCard
                    sourcesCard
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(RiverheadTheme.background.ignoresSafeArea())
            .navigationTitle("Reserve Trend: 2023–2025")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Toggle(showDollars ? "$" : "%", isOn: $showDollars)
                        .toggleStyle(.button)
                        .font(.caption.weight(.semibold))
                }
            }
        }
    }

    // MARK: - Cards

    private var headerCard: some View {
        GlassCard(
            title: "Unassigned Fund Balance Trend",
            subtitle: "Riverhead General Fund (A01) year-end unassigned balance from each year's audit, as a share of the next year's adopted General Fund budget, 2023–2025."
        ) {
            HStack(spacing: 8) {
                badge("Audited", color: RiverheadTheme.accent)
                badge("GFOA 16.7%", color: .green)
            }
        }
    }

    private var chartCard: some View {
        GlassCard(
            title: showDollars ? "Unassigned Balance (dollars)" : "Reserve Ratio (% of appropriations)",
            subtitle: "Tap a year to see details. Reference lines show GFOA minimum and Riverhead policy targets."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Chart {
                    // Benchmark band: policyMin to policyUpper
                    if !showDollars {
                        RectangleMark(
                            xStart: .value("Start", points.first!.year - 1),
                            xEnd:   .value("End",   points.last!.year + 1),
                            yStart: .value("Min", policyMin * 100),
                            yEnd:   .value("Upper", policyUpper * 100)
                        )
                        .foregroundStyle(Color.green.opacity(0.08))

                        // GFOA line
                        RuleMark(y: .value("GFOA", gfoaBenchmark * 100))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .foregroundStyle(Color.green.opacity(0.7))
                            .annotation(position: .topLeading) {
                                Text("GFOA 16.7%").font(.system(size: 9)).foregroundStyle(.green)
                            }

                        // Policy min line
                        RuleMark(y: .value("Policy min", policyMin * 100))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .foregroundStyle(Color.orange.opacity(0.7))
                            .annotation(position: .topLeading) {
                                Text("15% min").font(.system(size: 9)).foregroundStyle(.orange)
                            }
                    }

                    // Area fill
                    ForEach(points) { pt in
                        AreaMark(
                            x: .value("Year", pt.year),
                            y: .value(showDollars ? "$" : "%", showDollars ? pt.unassigned / 1_000_000 : pt.percent * 100)
                        )
                        .foregroundStyle(RiverheadTheme.accent.opacity(0.12))
                        .interpolationMethod(.catmullRom)
                    }

                    // Line
                    ForEach(points) { pt in
                        LineMark(
                            x: .value("Year", pt.year),
                            y: .value(showDollars ? "$M" : "%", showDollars ? pt.unassigned / 1_000_000 : pt.percent * 100)
                        )
                        .foregroundStyle(RiverheadTheme.accent)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)
                    }

                    // Points — AFR confirmed in accent, estimates in orange
                    ForEach(points) { pt in
                        PointMark(
                            x: .value("Year", pt.year),
                            y: .value(showDollars ? "$M" : "%", showDollars ? pt.unassigned / 1_000_000 : pt.percent * 100)
                        )
                        .foregroundStyle(RiverheadTheme.accent)
                        .symbolSize(pt.year == selectedYear ? 120 : 50)
                    }

                    // Selected year annotation
                    if let pt = selectedPoint {
                        RuleMark(x: .value("Selected", pt.year))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 2]))
                            .foregroundStyle(RiverheadTheme.textSecondary.opacity(0.5))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: points.map(\.year)) { val in
                        AxisValueLabel { if let y = val.as(Int.self) { Text("\(y)").font(.caption2) } }
                        AxisGridLine()
                    }
                }
                .chartYAxis {
                    AxisMarks { val in
                        AxisValueLabel {
                            if let v = val.as(Double.self) {
                                Text(showDollars ? "$\(v, format: .number.precision(.fractionLength(0)))M" : "\(v, format: .number.precision(.fractionLength(0)))%")
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { val in
                                        let plotOriginX: CGFloat
                                        if let frame = proxy.plotFrame {
                                            plotOriginX = geo[frame].origin.x
                                        } else {
                                            plotOriginX = 0
                                        }
                                        let x = val.location.x - plotOriginX
                                        if let year: Int = proxy.value(atX: x) {
                                            let nearest = points.min(by: { abs($0.year - year) < abs($1.year - year) })
                                            selectedYear = nearest?.year
                                        }
                                    }
                                    .onEnded { _ in /* keep selection visible */ }
                            )
                    }
                }
                .frame(height: 230)

                // X-axis year tap buttons for easier selection on small screens
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(points) { pt in
                            Button {
                                selectedYear = selectedYear == pt.year ? nil : pt.year
                            } label: {
                                Text("\(pt.year)")
                                    .font(.caption2.weight(selectedYear == pt.year ? .bold : .regular))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(selectedYear == pt.year ? RiverheadTheme.accent.opacity(0.2) : Color.gray.opacity(0.1))
                                    .foregroundStyle(selectedYear == pt.year ? RiverheadTheme.accent : RiverheadTheme.textSecondary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func detailCard(for pt: FBPoint) -> some View {
        GlassCard(
            title: "FY\(pt.year) Snapshot",
            subtitle: "From the Town's independent audit of \(pt.year)."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(pt.percent, format: .percent.precision(.fractionLength(1)))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(colorForPercent(pt.percent))
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(pt.unassigned, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .font(.subheadline.weight(.semibold))
                        Text("unassigned balance")
                            .font(.caption2)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                    }
                }

                Divider().opacity(0.25)

                statRow("\(String(pt.year + 1)) appropriations", value: pt.appropriations.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                statRow("Reserve ratio", value: pt.percent.formatted(.percent.precision(.fractionLength(1))))
                statRow("vs. GFOA 16.7%", value: ((pt.percent - gfoaBenchmark) * 100).formatted(.number.precision(.fractionLength(1))) + " pp")
                statRow("vs. 15% policy min", value: ((pt.percent - policyMin) * 100).formatted(.number.precision(.fractionLength(1))) + " pp")

                let trend = trendLabel(for: pt)
                if let t = trend {
                    Text(t)
                        .font(.caption)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
            }
        }
    }

    private var narrativeCard: some View {
        GlassCard(
            title: "What the Trend Shows",
            subtitle: "Three audited years, and what they mean for 2027."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                narrativeParagraph(
                    icon: "arrow.up.right.circle.fill", color: .green,
                    text: "The balance grew each year: $21.8 million at the end of 2023, $23.9 million at the end of 2024 and $28.8 million at the end of 2025. Measured against the next year's budget, that is 35.9%, 36.8% and 41.7%, all well above the Town's 15% floor."
                )
                Divider().opacity(0.2)
                narrativeParagraph(
                    icon: "doc.text.fill", color: .blue,
                    text: "The Town's policy is Resolution 918 of 2011. It sets a 15% floor and no ceiling. The shaded band up to 20% on the chart is a reference line this app draws, not a Town target."
                )
                Divider().opacity(0.2)
                narrativeParagraph(
                    icon: "calendar.badge.clock", color: RiverheadTheme.accent,
                    text: "Looking to 2027: the 2027 Preliminary Budget counts $880,000 of General Fund savings as income. The 2027 Lab models scenarios that keep the ratio above the 15% floor while paying for service changes."
                )
            }
        }
    }

    private var sourcesCard: some View {
        GlassCard(
            title: "Data Sources",
            subtitle: "How each data point was sourced."
        ) {
            VStack(alignment: .leading, spacing: 8) {
                sourceRow(color: RiverheadTheme.accent, label: "Audits (2023–2025)", detail: "Unassigned balances from the Town's audited financial statements: $21,848,178 (2023), $23,887,952 (2024) and $28,829,513 (2025, accepted September 1, 2026). Budgets from the Town's 2024, 2025 and 2026 Adopted Budgets. The Town's unaudited 2025 Annual Financial Report put the 2025 balance at $29,671,084.")
                sourceRow(color: .orange, label: "Earlier years", detail: "Not shown. The app's earlier estimates for 2014–2024 did not match the audits where they could be checked, so they were removed rather than kept as guesses.")

                Divider().opacity(0.2)

                Link(destination: URL(string: "https://www.osc.ny.gov/local-government/data")!) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text("State Comptroller local government data")
                            .underline()
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RiverheadTheme.accent)
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.15)).foregroundStyle(color)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(RiverheadTheme.textSecondary)
            Spacer()
            Text(value).font(.caption.weight(.semibold)).foregroundStyle(RiverheadTheme.textPrimary)
        }
    }

    @ViewBuilder
    private func sourceRow(color: Color, label: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Circle().fill(color).frame(width: 7, height: 7)
                Text(label).font(.caption.weight(.semibold)).foregroundStyle(RiverheadTheme.textPrimary)
            }
            Text(detail)
                .font(.caption2).foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func narrativeParagraph(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundStyle(color).font(.subheadline)
            Text(text)
                .font(.caption).foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func colorForPercent(_ p: Double) -> Color {
        if p < policyMin { return .red }
        if p <= policyUpper { return .green }
        return .blue
    }

    private func trendLabel(for pt: FBPoint) -> String? {
        guard let idx = points.firstIndex(where: { $0.year == pt.year }), idx > 0 else { return nil }
        let prev = points[idx - 1]
        let delta = pt.percent - prev.percent
        let sign = delta >= 0 ? "+" : ""
        return "Year-over-year: \(sign)\((delta * 100).formatted(.number.precision(.fractionLength(1)))) percentage points vs. FY\(prev.year)"
    }
}

#Preview {
    FundBalanceTrendView()
        .environment(RBBudgetStore())
}
