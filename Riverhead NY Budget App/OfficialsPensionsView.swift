//
//  OfficialsPensionsView.swift
//  Riverhead NY Budget App
//
//  Elected officials who also collect a public pension — a transparent,
//  sourced review of every current Town of Riverhead elected official.
//

import SwiftUI

struct OfficialsPensionsView: View {
    private enum PensionStatus: Equatable {
        case pension, unconfirmed, active, none, review

        var label: String {
            switch self {
            case .pension: return "Collects a public pension"
            case .unconfirmed: return "Public-service background — pension status not confirmed"
            case .active: return "Career public employee — still working"
            case .none: return "No public pension identified"
            case .review: return "Not yet reviewed"
            }
        }

        var color: Color {
            switch self {
            case .pension: return RiverheadTheme.brandCoral
            case .unconfirmed: return RiverheadTheme.brandGold
            case .active: return RiverheadTheme.brandSky
            case .none: return RiverheadTheme.brandMint
            case .review: return .secondary
            }
        }
    }

    private struct Official: Identifiable {
        let id = UUID()
        let name: String
        let office: String
        let party: String
        let status: PensionStatus
        let background: String
        let pension: String
        let sources: String
    }

    private let officials: [Official] = [
        .init(
            name: "James M. Wooten",
            office: "Town Clerk",
            party: "R",
            status: .pension,
            background: "Retired Riverhead Town police officer (retired after 23 years) and a former Town Councilman (12 years, term-limited).",
            pension: "Collects a New York State Police & Fire Retirement System (PFRS) pension. The Empire Center's SeeThroughNY reported it at about $45,556 in 2015, while he was serving on the Town Board; the current figure (with cost-of-living adjustments) is public on SeeThroughNY.",
            sources: "RiverheadLOCAL, “Former councilman James Wooten returns to Riverhead Town Hall” (Dec. 2020) · Riverhead News-Review, “Town Board member calls for a raise” (Dec. 2015) — cites SeeThroughNY pension of $45,556 · Empire Center, SeeThroughNY pension database."
        ),
        .init(
            name: "Denise Merrifield",
            office: "Councilwoman",
            party: "R",
            status: .pension,
            background: "Retired in 2018 after about 30 years as a Suffolk County prosecutor — Assistant District Attorney, 11 years in the Homicide Bureau, and Deputy Bureau Chief of the Child Abuse & Domestic Violence Bureau. Now also an adjunct law professor.",
            pension: "As a 30-year county employee who retired in 2018, she collects a New York State & Local Employees' Retirement System (ERS) pension. The amount is public on SeeThroughNY.",
            sources: "Rocky Point Rotary, “From Courtroom to Council: Denise Merrifield’s Path to Leadership” · Committee to Elect Denise Merrifield — candidate biography · Empire Center, SeeThroughNY pension database."
        ),
        .init(
            name: "Sean M. Walter",
            office: "Town Justice",
            party: "R/C",
            status: .unconfirmed,
            background: "Attorney; a former Riverhead Deputy Town Attorney (2000s) and former Town Supervisor (elected four times, served 2010–2017). Elected Town Justice in 2020.",
            pension: "Has substantial elected and appointed public service that can earn NYS retirement credit, but he remains in public office (Town Justice) and in private law practice, so whether he is currently drawing a pension is not confirmed here.",
            sources: "RiverheadLOCAL, “Sean Walter sworn in as Riverhead town justice” (Nov. 2020) · seanwalterlaw.com — attorney biography."
        ),
        .init(
            name: "Lori M. Hulse",
            office: "Town Justice",
            party: "R",
            status: .unconfirmed,
            background: "Attorney and Town Justice since 2016. Formerly a Senior Trial Attorney in the Suffolk County District Attorney's Office (1998–2002), a deputy bureau chief in the Kings County DA's office, and an assistant town attorney in Southold.",
            pension: "Has prior public-sector legal service that can earn NYS retirement credit, but she remains a sitting judge, so whether she is currently drawing a pension is not confirmed here.",
            sources: "RiverheadLOCAL, “Lori Hulse resigns from school board to take oath as Riverhead Town justice” (Jan. 2016) · Riverhead News-Review candidate coverage."
        ),
        .init(
            name: "Mike Zaleski",
            office: "Superintendent of Highways",
            party: "R",
            status: .active,
            background: "A career Highway Department employee — about 30 years, including deputy superintendent — before being elected Superintendent in 2021. Named a 2024 Public Servant of the Year.",
            pension: "Still an active public employee, so he is building toward a pension rather than collecting one.",
            sources: "Riverhead News-Review, “2024 Public Servants of the Year: Mike Zaleski and the Riverhead Highway Department.”"
        ),
        .init(
            name: "Laurie A. Zaneski",
            office: "Receiver of Taxes",
            party: "R",
            status: .active,
            background: "Worked in the Receiver of Taxes office beginning in 2003 (and as deputy before that), then elected Receiver of Taxes in 2012.",
            pension: "Still an active public employee, so she is building toward a pension rather than collecting one.",
            sources: "Riverhead News-Review / RiverheadLOCAL receiver-of-taxes candidate coverage (2019, 2023)."
        ),
        .init(
            name: "Jerry (Jerome) Halpin",
            office: "Supervisor",
            party: "D",
            status: .none,
            background: "Pastor of North Shore Christian Church for about 22 years and roughly 30 years in non-profit leadership; a political newcomer with no prior government-employee career. Cut his own supervisor salary in his first act in office.",
            pension: "No New York public pension identified.",
            sources: "RiverheadLOCAL, “Pastor Jerry Halpin will be sworn in as town supervisor” (Dec. 31, 2025) · Riverhead News-Review, “Jerry Halpin sworn in… slashes own salary” (Jan. 2026)."
        ),
        .init(
            name: "Kenneth Rothwell",
            office: "Councilman",
            party: "R",
            status: .none,
            background: "A licensed funeral director who owns the largest funeral business on the East End; a longtime volunteer firefighter. Private-sector career.",
            pension: "No public pension identified (a private business owner, not a government retiree).",
            sources: "RiverheadLOCAL, “Meet Riverhead Town’s new councilman, Kenneth Rothwell” (Jan. 2021)."
        ),
        .init(
            name: "Robert Kern",
            office: "Councilman",
            party: "R",
            status: .none,
            background: "Owns a marketing and branding company; former operations manager at Martha Clara Vineyards and past president of the Riverhead Chamber of Commerce. Private-sector career.",
            pension: "No public pension identified.",
            sources: "Riverhead News-Review / Patch candidate profiles — Bob Kern (2021, 2025)."
        ),
        .init(
            name: "Joann Waski",
            office: "Councilwoman",
            party: "R",
            status: .none,
            background: "President of Peconic Abstract, Inc., a Riverhead title-insurance company. Private-sector career. (Her husband is a retired Riverhead police detective — a separate household matter, not her pension.)",
            pension: "No public pension identified.",
            sources: "joannwaski.com — biography · Riverhead News-Review candidate coverage (2023, 2025)."
        ),
        .init(
            name: "Laverne D. Tennenberg",
            office: "Assessor (Chair)",
            party: "—",
            status: .review,
            background: "Elected member of the Board of Assessors.",
            pension: "Not researched in depth for this page.",
            sources: "Town of Riverhead — Elected Department Heads."
        ),
        .init(
            name: "Dána Brown",
            office: "Assessor",
            party: "—",
            status: .review,
            background: "Elected member of the Board of Assessors.",
            pension: "Not researched in depth for this page.",
            sources: "Town of Riverhead — Elected Department Heads."
        ),
        .init(
            name: "Meredith Lipinsky",
            office: "Assessor",
            party: "—",
            status: .review,
            background: "Elected member of the Board of Assessors.",
            pension: "Not researched in depth for this page.",
            sources: "Town of Riverhead — Elected Department Heads."
        ),
    ]

    private var orderedOfficials: [Official] {
        let rank: (PensionStatus) -> Int = { status in
            switch status {
            case .pension: return 0
            case .unconfirmed: return 1
            case .active: return 2
            case .none: return 3
            case .review: return 4
            }
        }
        return officials.sorted { rank($0.status) < rank($1.status) }
    }

    private var pensionCount: Int { officials.filter { $0.status == .pension }.count }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Elected Officials & Public Pensions")
                        .font(.headline)
                    Text("Some of Riverhead's elected officials spent long careers in government, retired, and now serve in elected office while collecting a New York State pension. This page reviews every current elected official and says plainly which ones do — a straightforward transparency question, since both the pension and the salary are public money.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("It's legal — this is disclosure, not an accusation", systemImage: "checkmark.shield")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.brandNavy)
                    Text("Under New York law, an elected office is generally exempt from the earnings caps (Retirement and Social Security Law §§211–212) that limit other public retirees who return to government work — so a retiree can hold elected office and keep a full pension. Several of these officials had long, decorated public-service careers.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("At A Glance") {
                HStack {
                    statTile(value: "\(officials.count)", label: "Officials reviewed")
                    statTile(value: "\(pensionCount)", label: "Collect a pension", color: RiverheadTheme.brandCoral)
                    statTile(value: "2", label: "Still-active employees", color: RiverheadTheme.brandSky)
                }
                .padding(.vertical, 4)
            }

            Section("Officials") {
                ForEach(orderedOfficials) { official in
                    officialRow(official)
                }
            }

            Section("Coming Up: The 2026 Supervisor Race") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Riverhead's next Supervisor election is in November 2026: Republican councilman Kenneth Rothwell (nominated by the Riverhead GOP in February 2026) against incumbent Democrat Jerry Halpin, who won the seat by 37 votes in 2025. New York's shift toward even-year local elections is what puts this contest on the 2026 ballot so soon after the last one.")
                        .font(.subheadline)
                    Text("Sources: Riverhead News-Review, “Riverhead GOP nominate Kenneth Rothwell for town supervisor” (Feb. 2026) · NYS Board of Elections, even-year local-elections guidance (2025).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Notes") {
                Text("“Not confirmed” and “not yet reviewed” do not mean an official has no pension — only that public reporting did not settle it. Anyone can look up a specific retiree on SeeThroughNY. This app is not an official legal or pension authority; verify against source documents before relying on any figure.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Link(destination: URL(string: "https://www.seethroughny.net/pensions")!) {
                    Label("SeeThroughNY Pension Database", systemImage: "link")
                }
            }
        }
        .navigationTitle("Officials & Pensions")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statTile(value: String, label: String, color: Color = RiverheadTheme.brandNavy) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func officialRow(_ official: Official) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(official.name)
                        .font(.subheadline.weight(.bold))
                    Text(official.party == "—" ? official.office : "\(official.office) · \(official.party)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(official.status.label)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(official.status.color.opacity(0.15), in: Capsule())
                    .foregroundStyle(official.status.color)
            }

            Text(official.background)
                .font(.caption)
                .foregroundStyle(.primary)

            Text(official.pension)
                .font(.caption)
                .foregroundStyle(official.status == .pension ? RiverheadTheme.brandCoral : .secondary)
                .fontWeight(official.status == .pension ? .semibold : .regular)

            Text("Sources: \(official.sources)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack {
        OfficialsPensionsView()
    }
}
