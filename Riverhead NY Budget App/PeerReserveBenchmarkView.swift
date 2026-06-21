import SwiftUI

// MARK: - Local GlassCard (mirrors the fileprivate one in RiverheadBudgetHubView)

private struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let title: String?
    let subtitle: String?
    @ViewBuilder var content: Content

    init(title: String? = nil, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title).font(.headline).foregroundStyle(RiverheadTheme.textPrimary)
            }
            if let subtitle {
                Text(subtitle).font(.footnote).foregroundStyle(RiverheadTheme.textSecondary)
            }
            content
        }
        .padding(14)
        .background(
            (reduceTransparency
             ? AnyShapeStyle(RiverheadTheme.Surface.card)
             : AnyShapeStyle(scheme == .dark ? .ultraThinMaterial : .regularMaterial)),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.border.opacity(scheme == .dark ? 0.35 : 0.2))
        )
        .shadow(color: .black.opacity(scheme == .dark ? 0.25 : 0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Data model

private struct ReservePeer: Identifiable {
    let id = UUID()
    let name: String
    let percent: Double      // e.g. 0.388 = 38.8%
    let dataYear: Int
    let source: PeerSource
    let sourceDetail: String
}

private enum PeerSource {
    case adoptedBudget      // figures drawn from an adopted/tentative budget document
    case financialPolicy    // explicitly stated reserve policy, not an actual balance
    case oscAFREstimate     // derived from the Annual Financial Report filed with OSC
    case riverheadLive      // live from RBBudgetStore
}

// MARK: - Main view

@MainActor
struct PeerReserveBenchmarkView: View {

    @Environment(RBBudgetStore.self) private var store

    // GFOA two-month-of-expenditures benchmark (1/6 of annual).
    private let gfoaBenchmark = 1.0 / 6.0   // ≈ 16.7%
    // OSC FSMS fiscal-stress warning threshold — unassigned fund balance below 15% of appropriations
    // is one of several negative indicators in the Fiscal Stress Monitoring System.
    private let oscFSMSThreshold = 0.15
    // Riverhead's adopted local policy minimum (15%) and upper target (20%).
    private let riverheadPolicyMin = 0.15
    private let riverheadPolicyMax = 0.20

    private var riverheadPercent: Double {
        guard store.appropriations > 0 else { return 0 }
        return store.estimatedFundBalance / store.appropriations
    }

    // Peer data sourced from each town's publicly available adopted or tentative budget documents
    // and OSC Annual Financial Reports. Estimates are labeled; sources are cited in footers.
    private var peers: [ReservePeer] {
        [
            ReservePeer(
                name: "Riverhead",
                percent: riverheadPercent,
                dataYear: 2026,
                source: .riverheadLive,
                sourceDetail: "2026 adopted General Fund · unassigned fund balance ÷ total appropriations. Live from app data."
            ),
            ReservePeer(
                name: "East Hampton",
                percent: (29_709_031.0 + 19_034_693.0) / 86_782_601.0,
                dataYear: 2026,
                source: .adoptedBudget,
                sourceDetail: "2026 adopted General Fund. Whole-town ($29.7M) + part-town ($19.0M) projected balances ÷ $86.8M appropriations ≈ 56.2%."
            ),
            ReservePeer(
                name: "Smithtown",
                percent: 24_099_593.0 / 60_384_813.0,
                dataYear: 2026,
                source: .adoptedBudget,
                sourceDetail: "2026 tentative General Fund. Projected fund balance $24.1M ÷ $60.4M appropriations ≈ 39.9%."
            ),
            ReservePeer(
                name: "Brookhaven",
                percent: 60_023_184.0 / 154_611_894.0,
                dataYear: 2026,
                source: .adoptedBudget,
                sourceDetail: "2026 adopted General Town Wide. Unreserved fund balance $60.0M ÷ $154.6M appropriations ≈ 38.8%."
            ),
            ReservePeer(
                name: "Southold",
                percent: 0.342,
                dataYear: 2023,
                source: .oscAFREstimate,
                sourceDetail: "Estimated from OSC Annual Financial Report (AUD) filed for FY 2023. General Fund unassigned balance ÷ appropriations ≈ 34.2%. Confirm via OSC Open Book NY."
            ),
            ReservePeer(
                name: "Huntington",
                percent: 0.271,
                dataYear: 2023,
                source: .oscAFREstimate,
                sourceDetail: "Estimated from OSC Annual Financial Report (AUD) filed for FY 2023. General Fund unassigned balance ÷ appropriations ≈ 27.1%. Confirm via OSC Open Book NY."
            ),
            ReservePeer(
                name: "Islip",
                percent: 0.196,
                dataYear: 2023,
                source: .oscAFREstimate,
                sourceDetail: "Estimated from OSC Annual Financial Report (AUD) filed for FY 2023. General Fund unassigned balance ÷ appropriations ≈ 19.6%. Confirm via OSC Open Book NY."
            ),
            ReservePeer(
                name: "Babylon",
                percent: 0.143,
                dataYear: 2023,
                source: .oscAFREstimate,
                sourceDetail: "Estimated from OSC Annual Financial Report (AUD) filed for FY 2023. General Fund unassigned balance ÷ appropriations ≈ 14.3%. Confirm via OSC Open Book NY."
            ),
            ReservePeer(
                name: "Southampton\n(policy)",
                percent: 0.17,
                dataYear: 2026,
                source: .financialPolicy,
                sourceDetail: "Southampton's 2026 adopted financial policy: 10% restricted reserve + at least 7% unallocated = 17% combined benchmark."
            ),
        ]
        .sorted { $0.percent > $1.percent }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    riverheadHeroCard
                    chartCard
                    benchmarkReferenceCard
                    sourcesCard
                    oscContextCard
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(RiverheadTheme.background.ignoresSafeArea())
            .navigationTitle("Peer Reserve Comparison")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Subviews

    private var headerCard: some View {
        GlassCard(
            title: "Rainy Day Fund vs. Suffolk County Peers",
            subtitle: "How Riverhead's General Fund unassigned balance compares to neighboring towns, OSC fiscal benchmarks, and GFOA best practice."
        ) {
            HStack(spacing: 8) {
                badgeView("Suffolk County towns", color: RiverheadTheme.accent)
                badgeView("OSC AFR data", color: .purple)
                badgeView("GFOA benchmark", color: .green)
            }
        }
    }

    private var riverheadHeroCard: some View {
        GlassCard(
            title: "Riverhead (live)",
            subtitle: "General Fund unassigned balance as a percent of appropriations — from app data."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(riverheadPercent, format: .percent.precision(.fractionLength(1)))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(colorForPercent(riverheadPercent))
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(store.estimatedFundBalance, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .font(.subheadline.weight(.semibold))
                        Text("÷ \(store.appropriations, format: .currency(code: "USD").precision(.fractionLength(0))) appropriations")
                            .font(.caption)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                    }
                }

                if riverheadPercent >= riverheadPolicyMax {
                    statusPill("Above 20% upper target — above policy band", color: .blue)
                } else if riverheadPercent >= riverheadPolicyMin {
                    statusPill("Within 15%–20% policy band", color: .green)
                } else {
                    statusPill("Below 15% local minimum — policy alert", color: .red)
                }

                Text("Riverhead's Town Board adopted a policy requiring unassigned fund balance of at least 15% of General Fund appropriations, with 20% as an upper target. A balance within that band is policy-compliant; above the band is available for intentional one-time deployment.")
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)
            }
        }
    }

    private var chartCard: some View {
        GlassCard(
            title: "Suffolk County Town Comparison",
            subtitle: "Unassigned General Fund balance as % of appropriations. Sorted by reserve ratio."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(peers) { peer in
                    peerBarRow(peer: peer)
                }

                Divider().opacity(0.25)

                // Benchmark reference lines legend
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Rectangle().fill(Color.green).frame(width: 24, height: 2)
                        Text("GFOA two-month benchmark ≈ 16.7%")
                            .font(.caption2)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                    }
                    HStack(spacing: 6) {
                        Rectangle().fill(Color.orange).frame(width: 24, height: 2)
                        Text("OSC FSMS concern threshold: 15%")
                            .font(.caption2)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                    }
                }
            }
        }
    }

    private var benchmarkReferenceCard: some View {
        GlassCard(
            title: "What the Benchmarks Mean",
            subtitle: "OSC and GFOA standard thresholds for New York local governments."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                benchmarkRow(
                    label: "GFOA two-month minimum",
                    value: "≈ 16.7%",
                    color: .green,
                    explanation: "The Government Finance Officers Association recommends that general purpose governments maintain unrestricted fund balance equal to at least two months of operating revenue or expenditures — roughly 16.7% of annual spending."
                )
                Divider().opacity(0.2)
                benchmarkRow(
                    label: "OSC FSMS fiscal-stress indicator",
                    value: "< 15%",
                    color: .orange,
                    explanation: "The NYS Office of the State Comptroller's Fiscal Stress Monitoring System scores municipalities that carry unassigned fund balance below 15% of appropriations as a negative indicator. Falling below this threshold contributes points toward a fiscal-stress classification."
                )
                Divider().opacity(0.2)
                benchmarkRow(
                    label: "Riverhead local policy minimum",
                    value: "15%",
                    color: RiverheadTheme.accent,
                    explanation: "Riverhead's adopted fund-balance policy sets 15% of General Fund appropriations as the minimum floor. The upper target is 20%. Amounts above 20% are candidates for intentional one-time deployment (capital, debt reduction, or tax stabilization) by board resolution."
                )
                Divider().opacity(0.2)
                benchmarkRow(
                    label: "NY statutory \"rainy day\" spirit",
                    value: "Varies",
                    color: .purple,
                    explanation: "New York State does not mandate a single reserve percentage for towns, but OSC guidance and the FSMS framework create strong de facto benchmarks. The statutory budget-note filing requirement triggers when fund balance appropriations exceed available balance — a signal of structural imbalance, not reserve strength."
                )
            }
        }
    }

    private var sourcesCard: some View {
        GlassCard(
            title: "Data Sources & Caveats",
            subtitle: "Reserve ratios vary by how each town defines and reports its General Fund."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                sourceGroup(
                    heading: "Adopted / Tentative Budget figures (most reliable)",
                    towns: peers.filter { $0.source == .adoptedBudget || $0.source == .financialPolicy }
                )
                Divider().opacity(0.2)
                sourceGroup(
                    heading: "OSC Annual Financial Report estimates (verify on Open Book NY)",
                    towns: peers.filter { $0.source == .oscAFREstimate }
                )

                Text("Comparisons should be treated as directional, not definitive. Town fund structures differ: some include special district funds in the General Fund, others do not. East Hampton's figure combines whole-town and part-town balances. Southampton's figure is a stated policy target, not an audited balance. OSC AFR estimates are derived from the Annual Update Documents (AUDs) towns file with OSC; figures may reflect a prior audit year. Visit osc.ny.gov/local-government/financial-toolkit for authoritative guidance.")
                    .font(.caption2)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var oscContextCard: some View {
        GlassCard(
            title: "OSC Toolkit: Reserve Funds",
            subtitle: "New York State resources for understanding and managing municipal reserves."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("The NYS Office of the State Comptroller publishes detailed guidance on reserve funds, including the Budget Reserve Fund (§6-c), Repair Reserve, Equipment Reserve, and others. These are legally distinct from unassigned General Fund balance — they are formally established by resolution, may have deposit and withdrawal restrictions, and are reported as \"restricted\" or \"assigned\" under GASB 54.")
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider().opacity(0.2)

                Link(destination: URL(string: "https://www.osc.ny.gov/local-government/financial-toolkit")!) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text("OSC Financial Toolkit")
                            .underline()
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RiverheadTheme.accent)
                }

                Link(destination: URL(string: "https://www.osc.ny.gov/local-government/publications/reserve-funds")!) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text("OSC Reserve Funds publication")
                            .underline()
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RiverheadTheme.accent)
                }

                Link(destination: URL(string: "https://www.osc.ny.gov/local-government/fiscal-stress-monitoring")!) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text("Fiscal Stress Monitoring System (FSMS)")
                            .underline()
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RiverheadTheme.accent)
                }
            }
        }
    }

    // MARK: - Row builders

    @ViewBuilder
    private func peerBarRow(peer: ReservePeer) -> some View {
        let isRiverhead = peer.source == .riverheadLive
        let maxPercent = 0.65 // scale bars to this cap

        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(peer.name)
                    .font(isRiverhead ? .subheadline.weight(.bold) : .subheadline)
                    .foregroundStyle(isRiverhead ? RiverheadTheme.accent : RiverheadTheme.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                HStack(spacing: 4) {
                    Text(peer.percent, format: .percent.precision(.fractionLength(1)))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(colorForPercent(peer.percent))
                    sourceTagView(peer.source)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.12))
                        .frame(height: 10)

                    // Filled bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor(peer: peer))
                        .frame(width: geo.size.width * min(peer.percent / maxPercent, 1.0), height: 10)

                    // GFOA reference line
                    let gfoaX = geo.size.width * (gfoaBenchmark / maxPercent)
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 1.5, height: 14)
                        .offset(x: gfoaX, y: -2)

                    // OSC FSMS threshold line
                    let oscX = geo.size.width * (oscFSMSThreshold / maxPercent)
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 1.5, height: 14)
                        .offset(x: oscX, y: -2)
                }
            }
            .frame(height: 14)

            HStack {
                sourceLabelText(peer)
                    .font(.caption2)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .lineLimit(1)
                Spacer()
                Text("FY\(peer.dataYear.formatted(.number.grouping(.never)))")
                    .font(.caption2)
                    .foregroundStyle(RiverheadTheme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func benchmarkRow(label: String, value: String, color: Color, explanation: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                Spacer()
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(color)
            }
            Text(explanation)
                .font(.caption)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func sourceGroup(heading: String, towns: [ReservePeer]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(heading)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RiverheadTheme.textSecondary)
            ForEach(towns) { peer in
                VStack(alignment: .leading, spacing: 2) {
                    Text(peer.name.replacingOccurrences(of: "\n", with: " "))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RiverheadTheme.textPrimary)
                    Text(peer.sourceDetail)
                        .font(.caption2)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Helper views

    @ViewBuilder
    private func badgeView(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func statusPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func sourceTagView(_ source: PeerSource) -> some View {
        switch source {
        case .adoptedBudget:
            Text("adopted")
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.12))
                .foregroundStyle(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        case .financialPolicy:
            Text("policy")
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.purple.opacity(0.12))
                .foregroundStyle(Color.purple)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        case .oscAFREstimate:
            Text("est.")
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.12))
                .foregroundStyle(Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        case .riverheadLive:
            Text("live")
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(RiverheadTheme.accent.opacity(0.15))
                .foregroundStyle(RiverheadTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }

    @ViewBuilder
    private func sourceLabelText(_ peer: ReservePeer) -> some View {
        switch peer.source {
        case .riverheadLive: Text("Live from app · 2026 adopted")
        case .adoptedBudget: Text("From adopted/tentative budget")
        case .financialPolicy: Text("Stated policy target")
        case .oscAFREstimate: Text("OSC AFR estimate — verify on Open Book NY")
        }
    }

    // MARK: - Helpers

    private func colorForPercent(_ p: Double) -> Color {
        if p < oscFSMSThreshold { return .red }
        if p < riverheadPolicyMin { return .orange }
        if p <= riverheadPolicyMax { return .green }
        return .blue
    }

    private func barColor(peer: ReservePeer) -> Color {
        if peer.source == .riverheadLive { return RiverheadTheme.accent }
        if peer.source == .financialPolicy { return .purple }
        if peer.source == .oscAFREstimate { return .orange }
        return colorForPercent(peer.percent)
    }
}

#Preview {
    PeerReserveBenchmarkView()
        .environment(RBBudgetStore())
}
