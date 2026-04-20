//
//  BudgetOverviewShiftView.swift
//  Riverhead NY Budget App
//
//  Resident-facing 2026 overview:
//   • Plain-English snapshot of the 2026 Adopted Budget
//   • Key numbers pulled directly from the 2026 Adopted Budget summary
//   • Tap “Use of Fund Balance” to see a fund-by-fund breakdown
//

import SwiftUI

@MainActor
struct BudgetOverviewShiftView: View {
    @Environment(\.colorScheme) private var scheme

    // MARK: - 2026 snapshot numbers (from adopted budget summary)

    // Total Town Operating row (all operating funds)
    private let totalOperatingAppropriations2026: Double = 121_110_904
    private let totalOperatingLevy2026: Double = 65_343_939
    private let appropriatedFundBalance2026: Double = 5_995_000

    // Town-wide row (A01 General, DA1 Highway, SL1 Street Lighting)
    private let townWideAppropriations2026: Double = 77_958_942
    private let townWideLevy2026: Double = 61_178_292

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
                Text("2026 Adopted Budget")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Text("High-level snapshot of the Town of Riverhead’s 2026 Adopted Budget, based on the summary table in the official adopted budget.")
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
            "Total Town operating appropriations across all funds in 2026 are " +
            "\(currency(totalOperatingAppropriations2026)). This is funded by estimated revenues, use of fund balance, and the Town’s property tax levy across all operating funds."
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
                bigValue: shortMillions(townWideLevy2026),
                subtitle: "2026 levy for Town-wide funds only: General, Highway, and Street Lighting (A01 + DA1 + SL1)."
            )

            // Total levy across all operating funds
            BudgetMetricTile(
                title: "Total Tax Levy (All Funds)",
                bigValue: shortMillions(totalOperatingLevy2026),
                subtitle: "Total 2026 Town property tax levy across all operating funds (matches the “Total Town Operating” row)."
            )

            // Total operating appropriations across all funds
            BudgetMetricTile(
                title: "Total Operating Budget",
                bigValue: shortMillions(totalOperatingAppropriations2026),
                subtitle: "Appropriations across all Town operating funds: \(currency(totalOperatingAppropriations2026))."
            )

            // Appropriated fund balance across all funds — now tappable for breakdown
            NavigationLink {
                FundBalanceUseBreakdownView()
            } label: {
                BudgetMetricTile(
                    title: "Use of Fund Balance",
                    bigValue: shortMillions(appropriatedFundBalance2026),
                    subtitle: "Total appropriated fund balance in 2026 across all operating funds. Tap for a fund-by-fund breakdown."
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
//  Shows how the $5,995,000 of appropriated fund balance is split by fund.
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

    // From the “2026 Appropriated Fund Balance” column in the summary table.
    // A01 + ES1 + ES3 + ES5 + EW1 = 5,995,000.
    private let entries: [Entry] = [
        .init(code: "A01", name: "General Fund",              amount: 1_250_000),
        .init(code: "ES1", name: "Riverhead Sewer District",  amount: 2_150_000),
        .init(code: "ES3", name: "Calverton Sewer District",  amount: 645_000),
        .init(code: "ES5", name: "Scavenger Waste District",  amount: 100_000),
        .init(code: "EW1", name: "Water District",            amount: 1_850_000)
    ]

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
                        Text("Use of Fund Balance – 2026")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.textPrimary)

                        Text("This is the portion of previously accumulated fund balances that is planned to be used to support 2026 appropriations, by fund.")
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

                            Text("Appropriated fund balance in 2026 for this fund, as shown in the adopted budget summary.")
                                .font(.footnote)
                                .foregroundStyle(RiverheadTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                BudgetCard {
                    Text("These amounts come from the “2026 Appropriated Fund Balance” column in the 2026 Adopted Budget summary. They explain how the total of \(currency(totalAmount)) is spread across individual funds.")
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
