//
//  CommunityPreservationFundView.swift
//  Riverhead NY Budget App
//
//  The Peconic Bay Community Preservation Fund's 2% real-estate transfer tax:
//  its real revenue history, fund balance, and related debt, sourced directly
//  from the Town's own audited CPF financial statements (Craig, Fitzsimmons &
//  Meyer LLP for 2024; Cullen & Danowski LLP for 2019 and 2025). This is a
//  trend explainer, not an advocacy page - the fund balance is healthy and
//  growing, but revenue is entirely tied to the real-estate market, which is
//  the real question worth laying out for residents.
//
//  Swift 6 / iOS 17+
//

import SwiftUI

struct CommunityPreservationFundYear: Identifiable {
    let id = UUID()
    let year: Int
    let transferTaxRevenue: Double
    let interestIncome: Double
    let fundBalanceEnd: Double

    var totalRevenue: Double { transferTaxRevenue + interestIncome }
}

enum CommunityPreservationFundData {
    static let history: [CommunityPreservationFundYear] = [
        .init(year: 2019, transferTaxRevenue: 3_431_456, interestIncome: 109_299, fundBalanceEnd: 7_472_219),
        .init(year: 2024, transferTaxRevenue: 9_539_252, interestIncome: 568_130, fundBalanceEnd: 25_595_093),
        .init(year: 2025, transferTaxRevenue: 7_033_230, interestIncome: 976_170, fundBalanceEnd: 30_106_726),
    ]

    static let lowYear = history[0]
    static let peakYear = history[1]
    static let latestYear = history[history.count - 1]

    static let peakToLatestChangePercent = (latestYear.transferTaxRevenue - peakYear.transferTaxRevenue) / peakYear.transferTaxRevenue
    static let lowToPeakMultiple = peakYear.transferTaxRevenue / lowYear.transferTaxRevenue

    static let debtOutstanding2024 = 12_290_588.00
    static let debtOutstanding2025 = 9_756_470.00
    static let debtMatures = 2029
    static let debtRateLow = 0.04
    static let debtRateHigh = 0.05

    static let ratePercent = 0.02
    static let unimprovedThreshold = 75_000.00
    static let improvedThreshold = 150_000.00
    static let authorityBeganYear = 1999
    static let authorityExtendedYear = 2016
    static let authorityExpiresYear = 2050
    static let waterQualityCapPercent = 0.20
    static let lifetimeLandPurchases2025 = 76_983_250.00
    static let acresProtected = 2_280
}

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
                Text(title)
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.textPrimary)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)
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

struct CommunityPreservationFundView: View {
    private var maxRevenue: Double {
        CommunityPreservationFundData.history.map(\.transferTaxRevenue).max() ?? 1
    }

    var body: some View {
        ZStack {
            RiverheadTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    introCard
                    revenueHistoryCard
                    debtCard
                    framingCard
                    sourcesFooter
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Community Preservation Fund")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var introCard: some View {
        GlassCard(
            title: "Peconic Bay Community Preservation Fund",
            subtitle: "The 2% real-estate transfer tax that pays for land preservation \u{2014} its revenue history, what it owes, and the real question behind talk of raising the rate."
        ) {
            Text("Since \(yearText(CommunityPreservationFundData.authorityBeganYear)), the CPF has funded \(currencyText(CommunityPreservationFundData.lifetimeLandPurchases2025)) of land purchases, protecting over \(CommunityPreservationFundData.acresProtected.formatted()) acres \u{2014} but its transfer-tax revenue swung from \(currencyText(CommunityPreservationFundData.lowYear.transferTaxRevenue)) in \(yearText(CommunityPreservationFundData.lowYear.year)) to \(currencyText(CommunityPreservationFundData.peakYear.transferTaxRevenue)) in \(yearText(CommunityPreservationFundData.peakYear.year)), then pulled back \(percentText(abs(CommunityPreservationFundData.peakToLatestChangePercent))) to \(currencyText(CommunityPreservationFundData.latestYear.transferTaxRevenue)) in \(yearText(CommunityPreservationFundData.latestYear.year)).")
                .font(.subheadline)
                .foregroundStyle(RiverheadTheme.textPrimary)
        }
    }

    private var revenueHistoryCard: some View {
        GlassCard(
            title: "Transfer-tax revenue, three audited years",
            subtitle: "Every figure below is the transfer-tax line from that year's audited CPF financial statement \u{2014} not a projection."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(CommunityPreservationFundData.history) { yearData in
                    yearRow(yearData)
                }

                Divider().opacity(0.25)

                Text("\(yearText(CommunityPreservationFundData.lowYear.year)) to \(yearText(CommunityPreservationFundData.peakYear.year)), transfer-tax revenue rose about \(String(format: "%.1f", CommunityPreservationFundData.lowToPeakMultiple))x as the real-estate market ran hot; \(yearText(CommunityPreservationFundData.peakYear.year)) to \(yearText(CommunityPreservationFundData.latestYear.year)) it pulled back \(percentText(abs(CommunityPreservationFundData.peakToLatestChangePercent))) as the market cooled. The fund balance kept growing through all of it, because the Town has been spending less than it takes in most years \u{2014} but the revenue line itself has no floor built in.")
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func yearRow(_ yearData: CommunityPreservationFundYear) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(yearText(yearData.year))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(yearData.transferTaxRevenue, format: .currency(code: "USD"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.accent)
            }
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(RiverheadTheme.Surface.card)
                    .frame(height: 8)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(RiverheadTheme.accent)
                            .frame(width: geo.size.width * (yearData.transferTaxRevenue / maxRevenue), height: 8)
                    }
            }
            .frame(height: 8)
            HStack {
                Text("+ \(currencyText(yearData.interestIncome)) interest = \(currencyText(yearData.totalRevenue)) total revenue")
                Spacer()
                Text("Balance: \(currencyText(yearData.fundBalanceEnd))")
            }
            .font(.caption2)
            .foregroundStyle(RiverheadTheme.textSecondary)
        }
    }

    private var debtCard: some View {
        GlassCard(title: "What the fund still owes") {
            VStack(alignment: .leading, spacing: 8) {
                Text("2018 refunding bonds issued against CPF-financed land purchases. The fund transfers money to the Town's debt service fund each year to pay this down \u{2014} that transfer competes with land-purchase capacity for the same revenue.")
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)

                HStack {
                    Text("Outstanding, year-end 2024")
                    Spacer()
                    Text(CommunityPreservationFundData.debtOutstanding2024, format: .currency(code: "USD"))
                        .fontWeight(.semibold)
                }
                .font(.footnote)

                HStack {
                    Text("Outstanding, year-end 2025")
                    Spacer()
                    Text(CommunityPreservationFundData.debtOutstanding2025, format: .currency(code: "USD"))
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
                .font(.footnote)

                HStack {
                    Text("Rate")
                    Spacer()
                    Text("\(percentText(CommunityPreservationFundData.debtRateLow, digits: 2))\u{2013}\(percentText(CommunityPreservationFundData.debtRateHigh, digits: 2))")
                }
                .font(.caption)
                .foregroundStyle(RiverheadTheme.textSecondary)

                HStack {
                    Text("Matures")
                    Spacer()
                    Text(yearText(CommunityPreservationFundData.debtMatures))
                }
                .font(.caption)
                .foregroundStyle(RiverheadTheme.textSecondary)
            }
        }
    }

    private var framingCard: some View {
        GlassCard(title: "Is the current rate still enough?") {
            VStack(alignment: .leading, spacing: 10) {
                Text("There is no acute crisis in these numbers: the fund balance has grown every year shown here, and the 2018 bonds are on schedule to be paid off by \(yearText(CommunityPreservationFundData.debtMatures)). The real question is about reliability, not solvency \u{2014} the CPF's only revenue source is a fixed \(percentText(CommunityPreservationFundData.ratePercent, digits: 0)) share of real-estate sale prices, which means every dollar of future land-preservation ambition or debt capacity rises and falls with a market the Town does not control. The \(percentText(abs(CommunityPreservationFundData.peakToLatestChangePercent))) pullback from \(yearText(CommunityPreservationFundData.peakYear.year)) to \(yearText(CommunityPreservationFundData.latestYear.year)) happened without any change in Town policy \u{2014} it was purely the market cooling.")
                    .font(.subheadline)
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Text("Whether that argues for a higher rate, an expanded eligible-use list, or simply budgeting land purchases more conservatively in strong years to build a cushion for weak ones, is a genuine Town Board policy question. This page does not take a position on it \u{2014} it lays out the real volatility so residents can weigh in with the actual numbers rather than a general impression that preservation funding is either flush or at risk.")
                    .font(.subheadline)
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Text("The authority to levy this tax runs through \(yearText(CommunityPreservationFundData.authorityExpiresYear)) (extended by referendum in \(yearText(CommunityPreservationFundData.authorityExtendedYear))), and up to \(percentText(CommunityPreservationFundData.waterQualityCapPercent, digits: 0)) of annual revenue may be used for water-quality projects rather than land purchases \u{2014} both are facts about the program's current scope, not arguments either way on the rate.")
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)
            }
        }
    }

    private var sourcesFooter: some View {
        Text("Sources: Town of Riverhead Peconic Bay Community Preservation Fund audited financial statements for the years ended December 31, 2019 (Cullen & Danowski, LLP), December 31, 2024 (Craig, Fitzsimmons & Meyer, LLP), and December 31, 2025 (Cullen & Danowski, LLP).")
            .font(.caption2)
            .foregroundStyle(RiverheadTheme.textSecondary)
    }

    private func currencyText(_ amount: Double) -> String {
        amount.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    // SwiftUI's Text(_:) applies locale-aware grouping to interpolated numeric
    // values (e.g. \(2022) renders as "2,022"), so years must be pre-converted
    // to plain strings before interpolation.
    private func yearText(_ year: Int) -> String {
        String(year)
    }

    private func percentText(_ value: Double, digits: Int = 1) -> String {
        value.formatted(.percent.precision(.fractionLength(digits)))
    }
}
