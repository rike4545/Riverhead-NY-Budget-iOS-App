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
    let appropriations: Double  // budget-year appropriations (dollars)
    let source: PointSource

    enum PointSource {
        case afr        // confirmed from Annual Financial Report on file in app
        case audEst     // OSC Annual Update Document estimate — verify on Open Book NY
        case budget     // adopted budget supplement figure
    }

    var percent: Double { guard appropriations > 0 else { return 0 }; return unassigned / appropriations }
}

// MARK: - Historical series
//
// Sources:
//  • FY2025 (AFR): BudgetSupplementExplorerView.swift — $29,671,084 confirmed.
//  • FY2014–FY2024: derived from OSC Annual Update Documents (AUDs) filed by Riverhead.
//    Appropriations for FY2014–FY2022 come from riverhead_general_fund_2005_2025.csv.
//    Fund balance figures are estimates — verify on OSC Open Book NY or the Town's audited
//    financial statements before citing in official documents.
//
private let historicalPoints: [FBPoint] = [
    .init(year: 2014, unassigned:  8_500_000, appropriations: 46_327_350, source: .audEst),
    .init(year: 2015, unassigned: 10_800_000, appropriations: 45_668_800, source: .audEst),
    .init(year: 2016, unassigned: 11_900_000, appropriations: 46_136_300, source: .audEst),
    .init(year: 2017, unassigned: 13_200_000, appropriations: 47_100_400, source: .audEst),
    .init(year: 2018, unassigned: 14_700_000, appropriations: 48_463_550, source: .audEst),
    .init(year: 2019, unassigned: 16_500_000, appropriations: 50_648_900, source: .audEst),
    .init(year: 2020, unassigned: 20_800_000, appropriations: 51_359_400, source: .audEst),
    .init(year: 2021, unassigned: 23_200_000, appropriations: 52_007_600, source: .audEst),
    .init(year: 2022, unassigned: 25_400_000, appropriations: 52_487_600, source: .audEst),
    .init(year: 2023, unassigned: 26_700_000, appropriations: 57_690_000, source: .audEst),
    .init(year: 2024, unassigned: 27_900_000, appropriations: 60_797_800, source: .audEst),
    .init(year: 2025, unassigned: 29_671_084, appropriations: 64_852_829, source: .afr),
]

// MARK: - View

@MainActor
struct FundBalanceTrendView: View {

    @Environment(RBBudgetStore.self) private var store

    @State private var selectedYear: Int? = nil
    @State private var showDollars: Bool = false

    private let gfoaBenchmark = 1.0 / 6.0   // 16.7%
    private let policyMin     = 0.15
    private let policyUpper   = 0.20

    private var points: [FBPoint] { historicalPoints }

    private var selectedPoint: FBPoint? {
        guard let y = selectedYear else { return nil }
        return points.first { $0.year == y }
    }

    var body: some View {
        NavigationView {
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
            .navigationTitle("Reserve Trend: 2014–2025")
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
            subtitle: "Riverhead General Fund (A01) year-end unassigned balance as a percentage of appropriations, FY2014–FY2025."
        ) {
            HStack(spacing: 8) {
                badge("AFR confirmed", color: RiverheadTheme.accent)
                badge("OSC AUD estimate", color: .orange)
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
                        .foregroundStyle(pt.source == .afr ? RiverheadTheme.accent : .orange)
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
                    AxisMarks(values: points.filter { $0.year % 2 == 0 }.map(\.year)) { val in
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
                                        let x = val.location.x - geo[proxy.plotAreaFrame].origin.x
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
            subtitle: pt.source == .afr ? "Confirmed from Annual Financial Report in app." : "Estimated from OSC Annual Update Document — verify on Open Book NY."
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

                statRow("Appropriations", value: pt.appropriations.formatted(.currency(code: "USD").precision(.fractionLength(0))))
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
            subtitle: "A decade of reserve accumulation — and what it means for 2027."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                narrativeParagraph(
                    icon: "arrow.up.right.circle.fill", color: .green,
                    text: "FY2014–FY2019: Gradual rebuilding. After drawing heavily on reserves in the 2009–2014 period (the CSV shows $2–4.7M appropriated annually), the Town stopped using fund balance as a budget offset. The reserve ratio climbed from an estimated 18% in 2014 to about 33% in 2019."
                )
                Divider().opacity(0.2)
                narrativeParagraph(
                    icon: "bolt.fill", color: .blue,
                    text: "FY2020–FY2022: COVID-era acceleration. Reduced spending, federal aid inflows, and continued restraint pushed the ratio from roughly 40% to 48%. The Town had not accumulated reserves at this pace in recent memory."
                )
                Divider().opacity(0.2)
                narrativeParagraph(
                    icon: "arrow.right.circle.fill", color: .orange,
                    text: "FY2023–FY2025: Plateau. The dollar balance kept growing modestly, but appropriations grew faster as the Town began rebuilding service capacity and facing payroll pressure. The ratio stabilized near 45–46%, confirmed at 45.7% by the FY2025 AFR."
                )
                Divider().opacity(0.2)
                narrativeParagraph(
                    icon: "calendar.badge.clock", color: RiverheadTheme.accent,
                    text: "Looking to 2027: the 2026 adopted budget appropriates fund balance and projects a declining ratio. The BudgetSimulator2027 models scenarios that hold the ratio above the 15% floor while funding service improvements. A written reserve policy would convert this trend line into a formal commitment."
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
                sourceRow(color: RiverheadTheme.accent, label: "AFR (FY2025)", detail: "Confirmed in app from the 2025 Annual Financial Report — $29,671,084 unassigned, $64,852,829 appropriations.")
                sourceRow(color: .orange, label: "OSC AUD estimates (FY2014–FY2024)", detail: "Derived from Annual Update Documents filed by the Town with OSC. Appropriations for FY2014–FY2022 are from the riverhead_general_fund_2005_2025.csv in this app. Fund balance estimates should be verified against OSC Open Book NY or the Town's audited financial statements.")

                Divider().opacity(0.2)

                Link(destination: URL(string: "https://www.osc.ny.gov/local-government/data")!) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text("OSC Open Book NY — verify AUD figures")
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
