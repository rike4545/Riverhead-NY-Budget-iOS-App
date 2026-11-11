//
//  ResidentBudgetSnapshot.swift
//  Riverhead NY Budget App
//
//  Numbers-first "at a glance" view of the 2026 budget for everyday residents:
//  big KPI tiles, a fund-balance health bar (where reserves sit against the
//  Town's own 15% floor, with the app's 20% reference line), and a proportional chart of what's
//  pushing the budget up — replacing the previous all-prose summary cards.
//
//  Headline dollar figures come from RBBudgetStore so they stay consistent with
//  the rest of the app and the AI assistant. The year-over-year and cost-driver
//  figures are the 2026 Adopted Budget values already cited in the app.
//
//  Swift 6 · iOS 17+
//

import SwiftUI

@MainActor
struct ResidentBudgetSnapshot: View {
    @Environment(RBBudgetStore.self) private var store
    @Environment(\.colorScheme) private var scheme

    // 2025 adopted total, for the year-over-year comparison (2026 Adopted Budget).
    private let priorYearTotal: Double = 64_895_000

    // The biggest drivers of the 2026 increase, in dollars (2026 Adopted Budget).
    private struct Driver: Identifiable {
        let id = UUID()
        let label: String
        let amount: Double
        let oneTime: Bool
    }
    private let drivers: [Driver] = [
        .init(label: "Police personal services", amount: 1_650_000, oneTime: false),
        .init(label: "Employee benefits",         amount: 1_120_000, oneTime: false),
        .init(label: "Ambulance equipment",       amount: 610_000,   oneTime: true),
    ]

    private var appropriations: Double { store.appropriations }
    private var fundBalance: Double { store.estimatedFundBalance }
    private var fbPercent: Double { appropriations > 0 ? fundBalance / appropriations : 0 }
    private var yoyChange: Double { priorYearTotal > 0 ? (appropriations - priorYearTotal) / priorYearTotal : 0 }
    private var floorPercent: Double { store.fundBalancePolicy.minimumPercent }
    private var targetPercent: Double { store.fundBalancePolicy.targetUpperPercent ?? 0.20 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            kpiRow
            healthCard
            driversCard
        }
    }

    // MARK: - KPI tiles

    private var kpiRow: some View {
        // Wraps to a column at accessibility sizes / narrow widths.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { kpiTiles }
            VStack(spacing: 12) { kpiTiles }
        }
    }

    @ViewBuilder
    private var kpiTiles: some View {
        kpiTile(
            value: compactUSD(appropriations),
            label: "Total 2026 budget",
            caption: "\(signedPercent(yoyChange)) vs 2025",
            accent: RiverheadTheme.brandSky
        )
        kpiTile(
            value: fbPercent.formatted(.percent.precision(.fractionLength(1))),
            label: "Rainy-day reserves",
            caption: "of the budget, in savings",
            accent: RiverheadTheme.brandMint
        )
        kpiTile(
            value: compactUSD(fundBalance),
            label: "Unassigned balance",
            caption: "the flexible cushion",
            accent: RiverheadTheme.brandGold
        )
    }

    private func kpiTile(value: String, label: String, caption: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title.weight(.heavy))
                .foregroundStyle(RiverheadTheme.textPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RiverheadTheme.textPrimary)
            Text(caption)
                .font(.caption)
                .foregroundStyle(RiverheadTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(snapshotSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accent)
                .frame(width: 4)
                .padding(.vertical, 12)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.border.opacity(scheme == .dark ? 0.35 : 0.2))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value), \(caption)")
    }

    // MARK: - Fund-balance health bar

    private var healthCard: some View {
        // Track runs 0% … scaleMax; reserves fill, with floor/target markers.
        let scaleMax = max(fbPercent * 1.15, targetPercent * 1.4, 0.30)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("How healthy are the reserves?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                Spacer()
                Label("Above floor", systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.brandMint)
            }

            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(RiverheadTheme.Surface.card)
                    Capsule()
                        .fill(RiverheadTheme.brandMint)
                        .frame(width: w * CGFloat(min(fbPercent / scaleMax, 1)))
                    marker(at: floorPercent / scaleMax, width: w)
                    marker(at: targetPercent / scaleMax, width: w)
                }
            }
            .frame(height: 16)

            HStack(spacing: 14) {
                legendDot(color: RiverheadTheme.brandMint,
                          text: "Reserves \(fbPercent.formatted(.percent.precision(.fractionLength(1))))")
                legendDot(color: RiverheadTheme.textSecondary,
                          text: "Floor \(floorPercent.formatted(.percent.precision(.fractionLength(0))))")
                legendDot(color: RiverheadTheme.textSecondary,
                          text: "Target \(targetPercent.formatted(.percent.precision(.fractionLength(0))))")
            }
            .font(.caption)
            .foregroundStyle(RiverheadTheme.textSecondary)

            Text("Riverhead keeps far more in reserve than its own 15% minimum — a large cushion, but one that shouldn't be spent on recurring costs.")
                .font(.footnote)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(snapshotSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.border.opacity(scheme == .dark ? 0.35 : 0.2))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reserves are \(fbPercent.formatted(.percent.precision(.fractionLength(1)))) of the budget, above the \(floorPercent.formatted(.percent.precision(.fractionLength(0)))) floor and \(targetPercent.formatted(.percent.precision(.fractionLength(0)))) target.")
    }

    private func marker(at fraction: Double, width: CGFloat) -> some View {
        Rectangle()
            .fill(RiverheadTheme.textPrimary.opacity(0.55))
            .frame(width: 2, height: 22)
            .offset(x: min(max(width * CGFloat(fraction) - 1, 0), width - 2))
    }

    private func legendDot(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text)
        }
    }

    // MARK: - Cost-driver bars

    private var driversCard: some View {
        let maxAmount = drivers.map(\.amount).max() ?? 1

        return VStack(alignment: .leading, spacing: 12) {
            Text("What's pushing the budget up in 2026")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RiverheadTheme.textPrimary)

            ForEach(drivers) { d in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(d.label)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(RiverheadTheme.textPrimary)
                        if d.oneTime {
                            Text("one-time")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6).padding(.vertical, 1)
                                .background(RiverheadTheme.Surface.card, in: Capsule())
                                .foregroundStyle(RiverheadTheme.textSecondary)
                        }
                        Spacer()
                        Text("+\(compactUSD(d.amount))")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(RiverheadTheme.textPrimary)
                            .monospacedDigit()
                    }
                    GeometryReader { geo in
                        Capsule()
                            .fill(d.oneTime ? RiverheadTheme.brandGold : RiverheadTheme.brandSky)
                            .frame(width: max(geo.size.width * CGFloat(d.amount / maxAmount), 6))
                    }
                    .frame(height: 10)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(d.label): up \(compactUSD(d.amount))\(d.oneTime ? ", one-time" : "")")
            }

            Text("Recurring pay and benefits are the lasting drivers; one-time items go away next year.")
                .font(.footnote)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(snapshotSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.border.opacity(scheme == .dark ? 0.35 : 0.2))
        )
    }

    // MARK: - Helpers

    private var snapshotSurface: some ShapeStyle {
        scheme == .dark ? AnyShapeStyle(RiverheadTheme.Surface.card.opacity(0.5)) : AnyShapeStyle(Color.white.opacity(0.7))
    }

    private func compactUSD(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").notation(.compactName).precision(.fractionLength(0...1)))
    }

    private func signedPercent(_ value: Double) -> String {
        let arrow = value >= 0 ? "▲" : "▼"
        return "\(arrow) \(abs(value).formatted(.percent.precision(.fractionLength(1))))"
    }
}
