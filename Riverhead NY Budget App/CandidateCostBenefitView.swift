//
//  CandidateCostBenefitView.swift
//  Riverhead NY Budget App
//
//  A neutral, even-handed cost–benefit look at every stated platform plank in the
//  November 3, 2026 Town Supervisor race — each with a benefit, a cost, and a
//  tradeoff, tied to the Town's own budget figures — plus a non-partisan fiscal
//  view of the Town's repeated tax increases. Companion to CandidateWatchView
//  (which reports each candidate in their own words). Ported from the web edition.
//
//  This is analysis of stated positions, weighed evenly — not an endorsement or a
//  prediction.
//
//  Swift 6 / iOS 17+
//

import SwiftUI

private struct CBPlank: Identifiable {
    let proposal: String
    let benefit: String
    let cost: String
    let tradeoff: String
    var id: String { proposal }
}

private struct CBCandidate: Identifiable {
    let name: String
    let partyLabel: String
    let isDem: Bool
    let incumbent: Bool
    let background: String
    let planks: [CBPlank]
    let sources: String
    var id: String { name }
}

private enum CandidateCBData {
    static let electionLine = "November 3, 2026 · Town Supervisor · the only Town seat on this ballot"
    static let disclaimer = "This is analysis of each candidate's stated positions, weighed evenly. Costs and benefits are estimates tied to the Town's own figures, not campaign estimates or predictions of what will actually be proposed. Every plank is shown with both a benefit and a cost."

    static let candidates: [CBCandidate] = [
        CBCandidate(
            name: "Jerome (Jerry) Halpin",
            partyLabel: "Democrat",
            isDem: true,
            incumbent: true,
            background: "Incumbent Supervisor; won by 37 votes in November 2025 running against the 2025 budget's 7.89% tax increase.",
            planks: [
                CBPlank(
                    proposal: "Keep a tight lid on Town spending.",
                    benefit: "Directly attacks the ~$2.32M by which this app’s September model projected the 2027 levy over a 2% increase (the adopted levy came in under that line). The app already identifies ~$2.1M in firm, individually-sourced recurring trims — so “hold the line” is not an empty slogan here; the line items exist.",
                    cost: "Most of the budget base is personnel and mandated costs (pension, debt service, insurance) a freeze can't touch. Real restraint means audits, held vacancies, and deferred equipment — each trading a dollar saved for a service or a delayed repair.",
                    tradeoff: "The two largest cost drivers — the PBA and SOA contracts — expire 12/31/2026 and settle through binding arbitration, not a Supervisor's pen. Much of the 2027 payroll pressure is locked until those settle."
                ),
                CBPlank(
                    proposal: "Grow new tax dollars through economic development instead of raising the levy.",
                    benefit: "Every $1M of new non-property-tax revenue offsets the cap-busting levy dollar-for-dollar with no service cut and no rate increase — the cleanest way to close the gap.",
                    cost: "Development is a multi-year lever; it does little for the 2027 gap that lands first. New rooftops and commercial space also bring their own service and infrastructure costs.",
                    tradeoff: "Sits in direct tension with the next plank (preserve rural character and open space). Land preserved is land off the tax roll; land developed is open space lost. The platform wants both."
                ),
                CBPlank(
                    proposal: "Support businesses while preserving rural character and open space.",
                    benefit: "Open-space preservation is popular and largely funded by the dedicated Peconic Bay CPF — not the general levy — and the Town just retired its CPF land-preservation debt five years early.",
                    cost: "Preserved parcels leave the tax roll permanently and can carry stewardship costs; CPF dollars are restricted and voter-defined, so they can't plug the operating gap.",
                    tradeoff: "The “business support + preservation” pairing is a genuine balancing act: each acre preserved is one not generating new commercial assessment."
                ),
                CBPlank(
                    proposal: "Build a stable budget that doesn't over-tax young families and seniors.",
                    benefit: "Frames the goal as recurring balance rather than one-time patches — the fiscally honest target, consistent with staying under the tax cap year over year.",
                    cost: "“Stable” is an outcome, not a mechanism: it still needs either the trims or the new revenue. If neither fully lands, the only lever left is fund balance — $28.8M of the $33.3M General Fund balance is unassigned and actually flexible (2025 audit) — and that is one-time money that can't fund a recurring gap twice.",
                    tradeoff: "Protecting specific groups from tax increases can mean shifting cost to fees or districts, which are less visible but land on the same households."
                ),
            ],
            sources: "votejerryhalpin.com; Riverhead News-Review (Feb. 2026)."
        ),
        CBCandidate(
            name: "Kenneth Rothwell",
            partyLabel: "Republican · Conservative",
            isDem: false,
            incumbent: false,
            background: "Current Town Councilman (since 2021) and licensed funeral director; Republican and Conservative nominee for Supervisor.",
            planks: [
                CBPlank(
                    proposal: "Lower the cost of taxes — the campaign's stated top issue.",
                    benefit: "Direct, immediately felt relief for every property owner, and the Town has a large cushion to work from: a $33.3M General Fund balance, of which $28.8M is unassigned and actually available (2025 audit).",
                    cost: "An actual levy cut (versus merely holding growth) would have widened the ~$2.32M cap gap in this app’s September model rather than closing it — the reduction has to be found on top of the gap. Funding a cut from reserves spends one-time money on a recurring obligation.",
                    tradeoff: "The NY tax cap already caps levy growth at ~2%; the fiscal distance between “hold at the cap” and “actually lower” is large, and this plank must be squared with the new-spending planks below."
                ),
                CBPlank(
                    proposal: "Make each Town department more self-sustaining.",
                    benefit: "Moving costs onto fee-for-service and enterprise/district funding shifts them off the general levy — the model the Town already uses for its sewer, water, and refuse districts.",
                    cost: "A “self-sustaining” district still charges the same residents; it moves the cost, it doesn't erase it (the ES5 scavenger-waste line already jumped ~38% in one year). Core services — police, roads — can't be fee-funded.",
                    tradeoff: "District charges are cap-exempt, so this can quietly raise total household cost even as the headline levy falls — the opposite of transparent."
                ),
                CBPlank(
                    proposal: "Expand clean-water access (cites the Manorville project).",
                    benefit: "A concrete public-health benefit for households on contaminated private wells, and often substantially grant-, state-, or CPF-water-quality-funded rather than levy-funded.",
                    cost: "Water-main extension and district formation are capital-intensive and add debt service and district charges for connected properties; the local share still has to be financed.",
                    tradeoff: "The Peconic Bay CPF's water-quality allocation is limited and voter-defined; it can fund pieces of this but not an open-ended program."
                ),
                CBPlank(
                    proposal: "Expand veterans programs and support police and first responders.",
                    benefit: "Services for veterans and sustained public-safety staffing — broadly supported, and public safety is the Town's core function.",
                    cost: "This is net-new recurring spending, and it points at the Town's single largest controllable cost: police. Uniform overtime already ran ~$1.4M in 2024, over budget. Expanding here pulls directly against the tax-cut and self-sustaining planks.",
                    tradeoff: "“Lower taxes” and “expand police/veterans spending” can only coexist with an explicit offset elsewhere; the platform doesn't yet name that offset."
                ),
                CBPlank(
                    proposal: "Attract high-tech development for a sustainable tax base.",
                    benefit: "High-value commercial assessment is the same base-growth lever in Halpin's platform — potentially the largest long-run offset to levy pressure.",
                    cost: "The incentives that attract such development (PILOTs, IDA abatements) defer the very tax revenue they promise, sometimes for years; and the Town's recent record on non-competitive deals (Petrocelli Town Square) is a caution on execution.",
                    tradeoff: "Same development-versus-preservation tension both candidates face, plus a governance question: on what terms, and through what procurement process, the incentives are granted."
                ),
            ],
            sources: "friendsofkenrothwell.com; Riverhead News-Review (Feb. 2026)."
        ),
    ]

    static let common = [
        "Both run on tax-base growth over levy increases, and both promise spending restraint — on fiscal strategy they are more alike than different.",
        "Both face the same unnamed constraint: the ~$2.32M by which this app’s September model projected the 2027 levy over a 2% increase, and the PBA/SOA contracts expiring 12/31/2026 (settled on November 17, 2026: 3.75% a year plus $500 in 2027).",
    ]
    static let divergence = [
        "The incumbent's platform is mostly “hold and grow” — restraint plus development — which maps onto the identified trims but is slow on the revenue side.",
        "The challenger adds concrete new-spending planks (veterans, police, clean water) alongside an explicit tax cut, which sharpens the appeal but requires naming an offset the platform hasn't yet specified.",
        "Both share the development-versus-open-space tension; neither has reconciled it in dollar terms.",
    ]
    static let scorecard = "Neither platform, as stated, closed the ~$2.32M cap gap in this app’s September model on paper. That is the honest scorecard: the ideas are directionally sound, but the arithmetic to hit the cap still has to be shown."

    // Beyond the campaigns — a neutral fiscal observer's view.
    static let neutralIntro = "Set the campaigns aside. Riverhead has leaned on above-cap levy increases and cap overrides in several recent years — a 7.89% levy increase in the 2025 budget, and override laws for the 2023, 2024, 2025 and 2026 budgets. When a town overrides the cap that often, the issue is usually structural: recurring costs are outgrowing recurring revenue, and the gap is closed late, at adoption, rather than planned for."
    static let history = [
        "2025 adopted budget: ~7.89% tax-levy increase.",
        "Tax-cap override laws adopted for the 2023, 2024, 2025 and 2026 budgets.",
        "2027, as adopted November 17, 2026: the levy across all funds rose 1.79%, under a 2% line. This app’s September model had projected it about $2.32M over.",
    ]
    static let principles: [(String, String)] = [
        ("Fund recurring costs with recurring revenue", "The most common structural error is patching an operating gap with one-time money — appropriated fund balance, one-off sales. It balances this year and guarantees the same gap next year. A simple rule — reserves only for one-time or emergency needs — prevents the cliff."),
        ("Adopt a rolling multi-year forecast", "A 3–5 year projection of revenues, payroll, pension, and debt turns a surprise at adoption into a problem seen 18 months out, when small corrections still work."),
        ("Set — and respect — a fund-balance target", "The $33.3M General Fund balance — $28.8M of it unassigned (2025 audit) — is a genuine strength; GFOA guidance is to hold at least ~two months of operating expenditures. That cushion is for emergencies and cash flow, not for buying down recurring costs."),
        ("Treat a cap override as an exception, decided in the open", "A deliberate override local law, adopted in public with the 60% vote on the record and a stated reason, is very different from backing into an increase. Overriding routinely is how the discipline erodes."),
        ("Go at the real cost drivers, with the data", "The 2026 retirement incentive, police-overtime normalization, and the audited line-item increases in the Budget Supplement are where the recurring dollars are. Prepare early and with comparables for the PBA/SOA arbitrations expiring 12/31/2026."),
        ("Diversify revenue honestly — but don't bank it early", "Economic development, cost-aligned fees, and grants are legitimate offsets. The discipline is timing: base growth is real but slow, so it belongs in the multi-year plan, not as a same-year plug."),
    ]
    static let citizen = "As a resident, the highest-leverage moves are unglamorous: show up at the budget and cap-override hearings before the vote (not after); ask for the multi-year forecast and a written fund-balance policy; and push back specifically when one-time money is used to fund a recurring cost."
    static let sources = "Framing follows GFOA best practices and NY State Comptroller (OSC) fiscal-stress guidance. Local figures are from the Town's adopted budgets and this app's parsed datasets."
}

struct CandidateCostBenefitView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Candidate proposals: cost & benefit")
                        .font(.headline)
                    Text(CandidateCBData.electionLine)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.brandNavy)
                    Text(CandidateCBData.disclaimer)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }

            ForEach(CandidateCBData.candidates) { c in
                candidateSection(c)
            }

            synthesisSection
            neutralSection
        }
        .navigationTitle("Cost & Benefit")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func candidateSection(_ c: CBCandidate) -> some View {
        Section {
            ForEach(Array(c.planks.enumerated()), id: \.element.id) { idx, p in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(idx + 1)").font(.caption.weight(.black)).foregroundStyle(.secondary)
                        Text(p.proposal).font(.subheadline.weight(.bold))
                    }
                    cbLine("Benefit", p.benefit, .green)
                    cbLine("Cost", p.cost, .red)
                    cbLine("Tradeoff", p.tradeoff, RiverheadTheme.brandGold)
                }
                .padding(.vertical, 4)
            }
        } header: {
            HStack(spacing: 8) {
                Text(c.name)
                Text(c.incumbent ? "Incumbent" : "Challenger")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background((c.isDem ? Color.blue : Color.red).opacity(0.14), in: Capsule())
                    .foregroundStyle(c.isDem ? Color.blue : Color.red)
            }
        } footer: {
            Text("\(c.background)  Platform sources: \(c.sources)")
        }
    }

    private func cbLine(_ label: String, _ text: String, _ tint: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.caption2.weight(.bold))
                .frame(width: 66, alignment: .center)
                .padding(.vertical, 3)
                .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 6))
                .foregroundStyle(tint)
            Text(text)
                .font(.caption)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var synthesisSection: some View {
        Section {
            Text("What they share").font(.caption.weight(.bold)).foregroundStyle(.green)
            ForEach(CandidateCBData.common, id: \.self) { Text("• \($0)").font(.caption).foregroundStyle(RiverheadTheme.textSecondary) }
            Text("Where they differ").font(.caption.weight(.bold)).foregroundStyle(RiverheadTheme.brandGold).padding(.top, 4)
            ForEach(CandidateCBData.divergence, id: \.self) { Text("• \($0)").font(.caption).foregroundStyle(RiverheadTheme.textSecondary) }
            Text(CandidateCBData.scorecard)
                .font(.footnote.weight(.medium))
                .padding(.top, 4)
                .fixedSize(horizontal: false, vertical: true)
        } header: {
            Text("Where the platforms converge — and diverge")
        }
    }

    @ViewBuilder
    private var neutralSection: some View {
        Section {
            Text(CandidateCBData.neutralIntro)
                .font(.footnote).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(CandidateCBData.history, id: \.self) { h in
                Text(h).font(.caption2.weight(.semibold))
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(RiverheadTheme.brandGold.opacity(0.14), in: Capsule())
                    .foregroundStyle(RiverheadTheme.brandGold)
            }
            ForEach(Array(CandidateCBData.principles.enumerated()), id: \.offset) { idx, p in
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(idx + 1). \(p.0)").font(.subheadline.weight(.semibold))
                    Text(p.1).font(.caption).foregroundStyle(RiverheadTheme.textSecondary).fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)
            }
            Text("And as a resident: \(CandidateCBData.citizen)")
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
            Text(CandidateCBData.sources).font(.caption2).foregroundStyle(.secondary)
        } header: {
            Text("Beyond the campaigns: a neutral fiscal view")
        }
    }
}

#Preview {
    NavigationStack { CandidateCostBenefitView() }
}
