import SwiftUI

struct LocalNewsEconomyView: View {
    private struct Outlet: Identifiable {
        let id = UUID()
        let name: String
        let blurb: String
        let url: URL
    }

    private struct StatRow: Identifiable {
        let id = UUID()
        let label: String
        let value: String
        let detail: String
    }

    private let outlets: [Outlet] = [
        .init(name: "RiverheadLOCAL", blurb: "Daily local coverage focused on Riverhead.", url: URL(string: "https://riverheadlocal.com/")!),
        .init(name: "Riverhead News-Review", blurb: "Community reporting and local town coverage.", url: URL(string: "https://riverheadnewsreview.timesreview.com/")!),
        .init(name: "Riverhead Patch", blurb: "Breaking and community headlines.", url: URL(string: "https://patch.com/new-york/riverhead")!),
        .init(name: "Newsday: Riverhead", blurb: "Regional reporting with Riverhead coverage.", url: URL(string: "https://www.newsday.com/long-island/suffolk/riverhead")!),
        .init(name: "News 12 Long Island", blurb: "Regional TV and web news updates.", url: URL(string: "https://longisland.news12.com/")!)
    ]

    // Town/region snapshot values with explicit source vintage.
    private let landAreaSquareMiles: Double = 67.43
    private let highwayFundAppropriations2026: Double = 7_919_250

    private var highwaySpendPerLandSquareMile: Double {
        highwayFundAppropriations2026 / landAreaSquareMiles
    }

    private var stats: [StatRow] {
        [
            .init(
                label: "Population",
                value: "36,495",
                detail: "Riverhead town population (2020 Census)."
            ),
            .init(
                label: "Median Household Income",
                value: "$93,595",
                detail: "2019-2023 ACS, inflation-adjusted to 2023 dollars."
            ),
            .init(
                label: "Per Capita Income",
                value: "$48,227",
                detail: "2019-2023 ACS, 2023 dollars."
            ),
            .init(
                label: "Average Commute",
                value: "27.7 min",
                detail: "Mean travel time to work, workers age 16+, 2019-2023."
            ),
            .init(
                label: "Businesses",
                value: "1,424",
                detail: "All employer firms (reference year 2022)."
            ),
            .init(
                label: "Current Unemployment (Closest Official Local)",
                value: "3.4%",
                detail: "Suffolk County unemployment rate, Dec 2025 (NYS DOL LAUS)."
            ),
            .init(
                label: "Highway Spending per Land Sq Mi",
                value: currency(highwaySpendPerLandSquareMile),
                detail: "~$7,919,250 Highway Fund appropriations / 67.43 sq mi land area."
            )
        ]
    }

    // User-provided affiliate link.
    private let sponsoredURL = URL(string: "http://click.linksynergy.com/fs-bin/click?id=rG4d7/djvVM&offerid=1949172&type=3&subid=0")!

    var body: some View {
        List {
            Section("Local News Outlets") {
                ForEach(outlets) { outlet in
                    Link(destination: outlet.url) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(outlet.name)
                                .font(.headline)
                            Text(outlet.blurb)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Town Snapshot") {
                ForEach(stats) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.label)
                            .font(.subheadline.weight(.semibold))
                        Text(item.value)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(RiverheadTheme.accent)
                        Text(item.detail)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Sources") {
                Link("U.S. Census QuickFacts: Riverhead town", destination: URL(string: "https://www.census.gov/quickfacts/fact/table/riverheadtownsuffolkcountynewyork/PST045224")!)
                Link("NYS DOL: Dec 2025 Area Unemployment Release (PDF)", destination: URL(string: "https://dol.ny.gov/state-labor-department-releases-preliminary-december-2025-area-unemployment-rates")!)
                Link("Town Highway Department (230 miles)", destination: URL(string: "https://www.townofriverheadny.gov/197/Highway")!)
            }

            Section("Sponsored") {
                Link("SHOP SIMON (formerly Shop Premium Outlets)", destination: sponsoredURL)
                    .font(.subheadline.weight(.semibold))
                Text("Affiliate link")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Local News & Stats")
        .navigationBarTitleDisplayMode(.inline)
    }

    private static func currency(_ amount: Double) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.maximumFractionDigits = 0
        return fmt.string(from: NSNumber(value: amount)) ?? "$0"
    }

    private func currency(_ amount: Double) -> String {
        Self.currency(amount)
    }
}
