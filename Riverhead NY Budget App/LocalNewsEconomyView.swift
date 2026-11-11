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

    /// Largest industries by people employed. Note the reconciliation caveat in
    /// `industryNote`: the employer-firm count and this breakdown come from
    /// different Census products and do not sum to one table.
    private struct IndustryRow: Identifiable {
        let id = UUID()
        let rank: Int
        let industry: String
        let employees: Int
    }

    private let topIndustries2024: [IndustryRow] = [
        .init(rank: 1, industry: "Health Care & Social Assistance", employees: 1_009),
        .init(rank: 2, industry: "Construction", employees: 806),
        .init(rank: 3, industry: "Administrative & Support & Waste Management Services", employees: 728)
    ]

    private let totalEmployerFirms = 1_424
    private let totalEmployerFirmsYear = 2022
    private let totalEmployment2024 = 6_520
    private let employmentGrowth2023to2024Pct = 1.72

    private let industryNote = "Employer-firm count and industry breakdown are from different Census products (County Business Patterns firm counts vs. American Community Survey-derived employment by industry, both aggregated by Data USA / Census QuickFacts), so they don't reconcile to a single table — a full establishment-by-industry breakdown (e.g. retail, accommodation & food service, wholesale) wasn't accessible this pass; these are the three largest sectors by people employed, not by establishment count."

    private let industrySource = "U.S. Census Bureau, County Business Patterns (via Census Bureau QuickFacts, Riverhead town, Suffolk County, NY), and Data USA (Census-derived employment by industry)."

    private let outlets: [Outlet] = [
        .init(name: "RiverheadLOCAL", blurb: "Daily local coverage focused on Riverhead.", url: URL(string: "https://riverheadlocal.com/")!),
        .init(name: "Riverhead News-Review", blurb: "Community reporting and local town coverage.", url: URL(string: "https://riverheadnewsreview.timesreview.com/")!),
        .init(name: "Riverhead Patch", blurb: "Breaking and community headlines.", url: URL(string: "https://patch.com/new-york/riverhead")!),
        .init(name: "Newsday: Long Island towns", blurb: "Regional reporting, including Riverhead.", url: URL(string: "https://www.newsday.com/long-island/towns")!),
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
                value: "35,902",
                detail: "Riverhead town population (2020 Census). A 2024 Census Bureau estimate puts it at 35,980."
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
                detail: "All employer firms, reference year 2022 (Census County Business Patterns). Broken out by industry below."
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
    private let sponsoredURL = URL(string: "https://click.linksynergy.com/fs-bin/click?id=rG4d7/djvVM&offerid=1949172&type=3&subid=0")!

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

            Section("Businesses & Industries") {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Employer businesses")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(totalEmployerFirms.formatted())
                            .font(.title3.weight(.bold))
                            .foregroundStyle(RiverheadTheme.accent)
                        Text("All employer firms, \(String(totalEmployerFirmsYear))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 12)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total employment")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(totalEmployment2024.formatted())
                            .font(.title3.weight(.bold))
                            .foregroundStyle(RiverheadTheme.brandNavy)
                        Text("2024, +\(employmentGrowth2023to2024Pct.formatted())% vs 2023")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Largest industries by people employed (2024)")
                        .font(.subheadline.weight(.semibold))
                    ForEach(topIndustries2024) { row in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(row.rank)")
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(row.rank == 1 ? RiverheadTheme.accent : .secondary)
                                .frame(width: 16, alignment: .leading)
                            Text(row.industry)
                                .font(.footnote.weight(row.rank == 1 ? .semibold : .regular))
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Text("\(row.employees.formatted()) employees")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)

                Text(industryNote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Source: \(industrySource)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("Tax Base & Largest Taxpayers") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Implied Full Valuation")
                        .font(.subheadline.weight(.semibold))
                    Text("~$7.08 billion")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(RiverheadTheme.accent)
                    Text("Implied from the audited debt-limit disclosure: the statutory debt limit is 7% of the Town's five-year-average full (market) valuation, and that limit is $495,782,621 — so the five-year-average full valuation is about $7.08 billion.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Largest Known Commercial Taxpayers")
                        .font(.subheadline.weight(.semibold))
                    Text("The Town does not publish a ranked principal-taxpayers schedule in its basic financial statements, so this is a list of major known commercial ratables from public reporting, not an official ranking.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    taxpayerRow("Tanger Outlets", "Two outlet centers on Route 58 — repeatedly cited as the Town's largest single tax generator.")
                    taxpayerRow("PSEG Long Island", "Electric transmission and distribution property is a major utility ratable.")
                    taxpayerRow("Costco Wholesale", "Big-box anchor; has litigated its assessment (a claimed ~$20.3M over-valuation).")
                    taxpayerRow("Walmart", "Big-box anchor; won a settlement cutting its assessed value ~$950,000 over five years.")
                    taxpayerRow("Route 58 big-box corridor", "Home Depot, Lowe's, Target and neighbors form a concentrated commercial tax base.")
                    taxpayerRow("EPCAL / Calverton Enterprise Park", "The former Grumman site — a large publicly-influenced parcel the Town has worked for years to return to the tax rolls.")
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Assessment System Under Strain")
                        .font(.subheadline.weight(.semibold))
                    Text("More than 300 tax-grievance lawsuits are filed against the Town every year, and settlements shift the tax burden onto other taxpayers. A decades-old assessment error tied to the Friar's Head golf property produced tax spikes of up to ~160% for some residents in 2026. Riverhead assesses property at roughly 8% of market value — an assessed value of about $50,040 corresponds to a ~$600,000 market-value home (near the Town median) — so small percentage swings move large dollar amounts.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                Text("Sources: Town of Riverhead 2022 Audited Basic Financial Statements (debt-limit and assessed-value disclosures) · RiverheadLOCAL and Riverhead News-Review reporting on Tanger, big-box assessments, grievance litigation, and the Friar's Head refund (2022, 2024, 2026).")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
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

    private func taxpayerRow(_ name: String, _ note: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "building.2.fill")
                .font(.caption)
                .foregroundStyle(RiverheadTheme.accent)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.caption.weight(.semibold))
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
