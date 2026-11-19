//
//  BudgetOverviewShiftView.swift
//  Riverhead NY Budget App
//
//  Resident-facing overview of the newest adopted budget:
//   • Plain-English snapshot of the latest Adopted Budget (2027 as of November 2026)
//   • Key numbers from that book's Summary page, via BudgetStages (budget-stages.json)
//   • Tap “Use of Fund Balance” to see a fund-by-fund breakdown
//

import SwiftUI

@MainActor
struct BudgetOverviewShiftView: View {
    @Environment(\.colorScheme) private var scheme

    // MARK: - Snapshot numbers: the newest adopted budget's Summary page

    private let year: Int = BudgetStages.currentYear ?? 2027
    private let doc: BudgetStageDoc? = BudgetStages.current
    private let prior: BudgetStageDoc? = BudgetStages.prior

    // Total Town Operating row (all operating funds)
    private var totalOperatingAppropriations: Double { doc?.totals.appropriations ?? 0 }
    private var totalOperatingLevy: Double { doc?.totals.levy ?? 0 }
    private var appropriatedFundBalance: Double { doc?.totals.fundBalance ?? 0 }

    // Town-wide row (A01 General, DA1 Highway, SL1 Street Lighting)
    private var townWideLevy: Double { doc?.townWide?.levy ?? 0 }

    /// " Up 1.73% from 2026.", from the adopted budgets on file.
    private func change(_ now: Double, _ before: Double?) -> String {
        guard let before, before > 0, let py = BudgetStages.priorYear else { return "" }
        let p = BudgetStages.pct(now, before)
        return String(format: " %@ %.2f%% from %d.", p >= 0 ? "Up" : "Down", abs(p), py)
    }

    // Simple currency formatter (no cents)
    private let nfCurrency0: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.maximumFractionDigits = 0
        return nf
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                summaryCard
                snapshotHeader
                snapshotIntro
                snapshotTiles
                contextNotes
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationTitle("Budget Overview")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Background

    /// Deep near-black in dark mode so cards pop; brand surface in light mode.
    private var pageBackground: Color {
        scheme == .dark
        ? Color.black.opacity(0.98)
        : RiverheadTheme.Surface.page
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        BudgetCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(String(year)) Adopted Budget")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Text("High-level snapshot of the Town of Riverhead’s \(String(year)) Adopted Budget, from the Summary page of the official book\(BudgetStages.adoptionNote(year).map { ". The Town Board \($0)" } ?? "").")
                    .font(.subheadline)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()
                    .background(RiverheadTheme.border.opacity(0.5))

                Text("Numbers here are rounded and simplified for residents. They are not an official notice or bill. Always verify with the Town’s adopted budget and tax bill.")
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Snapshot

    private var snapshotHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "chart.pie.fill")
                .imageScale(.medium)
                .foregroundStyle(RiverheadTheme.primaryBlue)
            Text("Town Snapshot (All Operating Funds)")
                .font(.headline.weight(.semibold))
                .foregroundStyle(RiverheadTheme.textPrimary)
            Spacer()
        }
    }

    private var snapshotIntro: some View {
        Text(
            "Total Town operating appropriations across all funds in \(String(year)) are " +
            "\(currency(totalOperatingAppropriations))." + change(totalOperatingAppropriations, prior?.totals.appropriations) +
            " This is funded by estimated revenues, use of fund balance, and the Town’s property tax levy across all operating funds."
        )
        .font(.footnote)
        .foregroundStyle(RiverheadTheme.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var snapshotTiles: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            // Town-wide levy only (A01, DA1, SL1)
            BudgetMetricTile(
                title: "Town-Wide Tax Levy",
                bigValue: shortMillions(townWideLevy),
                subtitle: "\(String(year)) levy for Town-wide funds only: General, Highway, and Street Lighting (A01 + DA1 + SL1)." + change(townWideLevy, prior?.townWide?.levy)
            )

            // Total levy across all operating funds
            BudgetMetricTile(
                title: "Total Tax Levy (All Funds)",
                bigValue: shortMillions(totalOperatingLevy),
                subtitle: "Total \(String(year)) Town property tax levy across all operating funds (the “Total Town Operating” row)." + change(totalOperatingLevy, prior?.totals.levy)
            )

            // Total operating appropriations across all funds
            BudgetMetricTile(
                title: "Total Operating Budget",
                bigValue: shortMillions(totalOperatingAppropriations),
                subtitle: "Appropriations across all Town operating funds: \(currency(totalOperatingAppropriations))."
            )

            // Appropriated fund balance across all funds — now tappable for breakdown
            NavigationLink {
                FundBalanceUseBreakdownView()
            } label: {
                BudgetMetricTile(
                    title: "Use of Fund Balance",
                    bigValue: shortMillions(appropriatedFundBalance),
                    subtitle: "Total appropriated fund balance in \(String(year)) across all operating funds. Tap for a fund-by-fund breakdown."
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var contextNotes: some View {
        BudgetCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Context")
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Text("“Town-wide” funds (A01, DA1, SL1) appear on every Town tax bill. Other funds, like ambulance or refuse districts, appear only where those districts apply.")
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("These amounts cover only the Town portion of your overall property tax bill. School districts, Suffolk County, libraries, and other jurisdictions set their own budgets and tax rates.")
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Helpers

    private func currency(_ n: Double) -> String {
        nfCurrency0.string(from: n as NSNumber) ?? "$0"
    }

    /// e.g. 61,178,292 → "$61.18M"
    private func shortMillions(_ n: Double) -> String {
        let millions = n / 1_000_000
        return String(format: "$%.2fM", millions)
    }
}

// MARK: - Reusable Card & Tile Styles

/// Solid card used for all content on this screen — darker in dark mode (no frosted glass).
private struct BudgetCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    /// Card fill tuned for contrast:
    /// - Dark mode: very dark navy/black
    /// - Light mode: standard Surface.card
    private var cardFill: Color {
        if scheme == .dark {
            return Color(red: 10/255, green: 14/255, blue: 20/255) // deep navy-ish
        } else {
            return RiverheadTheme.Surface.card
        }
    }

    private var borderColor: Color {
        if scheme == .dark {
            return Color.white.opacity(0.14)
        } else {
            return RiverheadTheme.border.opacity(0.25)
        }
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(borderColor)
            )
            .shadow(
                color: .black.opacity(scheme == .dark ? 0.55 : 0.16),
                radius: 18,
                x: 0,
                y: 10
            )
    }
}

private struct BudgetMetricTile: View {
    var title: String
    var bigValue: String
    var subtitle: String

    var body: some View {
        BudgetCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textSecondary)

                Text(bigValue)
                    .font(.title3.monospacedDigit().weight(.bold))
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

//
//  FundBalanceUseBreakdownView
//  Shows how the newest adopted budget's appropriated fund balance is split by fund.
//

@MainActor
private struct FundBalanceUseBreakdownView: View {
    @Environment(\.colorScheme) private var scheme

    private struct Entry: Identifiable {
        let id = UUID()
        let code: String
        let name: String
        let amount: Double
    }

    private let year: Int = BudgetStages.currentYear ?? 2027

    // The "Appropriated Fund Balance" column of the newest adopted budget's Summary page.
    private let entries: [Entry] = (BudgetStages.current?.fundsByCode ?? [])
        .compactMap { row in
            guard let amount = row.fund.fundBalance, amount > 0 else { return nil }
            return Entry(code: row.code, name: row.fund.name, amount: amount)
        }

    private var totalAmount: Double {
        entries.reduce(0) { $0 + $1.amount }
    }

    // Local currency formatter (whole dollars)
    private let nfCurrency0: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.maximumFractionDigits = 0
        return nf
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BudgetCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Use of Fund Balance – \(String(year))")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.textPrimary)

                        Text("This is the portion of previously accumulated fund balances that is planned to be used to support \(String(year)) appropriations, by fund.")
                            .font(.footnote)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Divider()
                            .background(RiverheadTheme.border.opacity(0.5))

                        HStack {
                            Text("Total across all operating funds")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(RiverheadTheme.textSecondary)
                            Spacer()
                            Text(currency(totalAmount))
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(RiverheadTheme.textPrimary)
                        }
                    }
                }

                ForEach(entries) { entry in
                    BudgetCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(entry.code) \(entry.name)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RiverheadTheme.textPrimary)

                            Text(currency(entry.amount))
                                .font(.title3.monospacedDigit().weight(.bold))
                                .foregroundStyle(RiverheadTheme.textPrimary)

                            Text("Appropriated fund balance in \(String(year)) for this fund, as shown in the adopted budget summary.")
                                .font(.footnote)
                                .foregroundStyle(RiverheadTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                BudgetCard {
                    Text("These amounts come from the “Appropriated Fund Balance” column in the \(String(year)) Adopted Budget summary. They explain how the total of \(currency(totalAmount)) is spread across individual funds.")
                        .font(.footnote)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(
            (scheme == .dark ? Color.black.opacity(0.98) : RiverheadTheme.Surface.page)
                .ignoresSafeArea()
        )
        .navigationTitle("Fund Balance Use")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func currency(_ n: Double) -> String {
        nfCurrency0.string(from: n as NSNumber) ?? "$0"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BudgetOverviewShiftView()
            .preferredColorScheme(.light)
    }
}
