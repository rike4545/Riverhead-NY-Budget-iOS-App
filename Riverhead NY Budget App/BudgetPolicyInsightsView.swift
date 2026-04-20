//
//  BudgetPolicyInsightsView.swift
//  Riverhead NY Budget App
//
//  Created by Bryan on 12/13/25.
//


//
//  BudgetPolicyInsightsView.swift
//  Riverhead NY Budget App
//
//  Policy Focus Points (Energy + Housing)
//
//  Depends on models from EnergyFocusArea.swift:
//   - EnergyFocusArea
//   - EnergyUrgency
//   - EnergyPolicyAction
//   - EnergyFundingProgram
//
//  NOTE:
//  Cablevision franchise agreement = Internet/Phone affordability policy,
//  and should live in a separate ConnectivityPolicyInsightsView (not here).
//
//  Swift 6 • iOS 17+
//

import SwiftUI
import UIKit
import Foundation

@MainActor
struct BudgetPolicyInsightsView: View {

    // MARK: - Init

    /// Labeled init prevents ambiguous `init()` warnings and keeps call sites flexible.
    init(initialFocus: EnergyFocusArea = .all) {
        _focus = State(initialValue: initialFocus)
    }

    // MARK: - Environment

    @Environment(\.colorScheme) private var scheme

    // MARK: - State

    @State private var focus: EnergyFocusArea
    @State private var urgency: EnergyUrgency? = nil
    @State private var query: String = ""
    @State private var showCopiedToast: Bool = false
    @State private var hideCopiedToastTask: Task<Void, Never>?

    // MARK: - Data

    private let actions: [EnergyPolicyAction] = EnergyPolicyInsightsData.actions
    private let programs: [EnergyFundingProgram] = EnergyPolicyInsightsData.programs

    private var filteredActions: [EnergyPolicyAction] {
        actions
            .filter { item in
                if focus != .all, item.area != focus { return false }
                if let u = urgency, item.urgency != u { return false }

                let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !q.isEmpty else { return true }

                let haystack = [
                    item.title,
                    item.whyItMatters,
                    item.recommendedActions.joined(separator: " "),
                    item.nextSteps.joined(separator: " "),
                    item.fundingMatches.joined(separator: " ")
                ]
                .joined(separator: " ")
                .lowercased()

                return haystack.contains(q.lowercased())
            }
            .sorted { a, b in
                let rank: (EnergyUrgency) -> Int = { $0 == .now ? 0 : ($0 == .next ? 1 : 2) }
                if rank(a.urgency) != rank(b.urgency) { return rank(a.urgency) < rank(b.urgency) }
                if a.area.rawValue != b.area.rawValue { return a.area.rawValue < b.area.rawValue }
                return a.title < b.title
            }
    }

    private var shareText: String {
        EnergyPolicyInsightsData.shareText(actions: actions, programs: programs)
    }

    // MARK: - Background

    @ViewBuilder
    private var pageBackground: some View {
        if scheme == .dark {
            Color.black
        } else {
            RiverheadTheme.Surface.page
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                headerCard
                filtersCard

                if focus == .funding {
                    fundingSection
                } else {
                    actionsSection
                }

                notesCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationTitle("Policy Focus Points")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, prompt: "Search energy, housing, income, rents, grants…")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ShareLink(item: shareText) {
                        Label("Share Summary", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        UIPasteboard.general.string = shareText
                        hideCopiedToastTask?.cancel()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
                            showCopiedToast = true
                        }
                        hideCopiedToastTask = Task {
                            try? await Task.sleep(for: .seconds(1.2))
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                showCopiedToast = false
                            }
                        }
                    } label: {
                        Label("Copy Summary", systemImage: "doc.on.doc")
                    }

                    Divider()

                    Button(role: .destructive) {
                        focus = .all
                        urgency = nil
                        query = ""
                    } label: {
                        Label("Reset Filters", systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .overlay(alignment: .top) {
            if showCopiedToast {
                ToastBanner(text: "Copied")
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(RiverheadTheme.accent.opacity(0.16))
                        .frame(width: 40, height: 40)
                    Image(systemName: "bolt.badge.a")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(RiverheadTheme.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Policy Focus Points")
                        .font(.headline)
                        .foregroundStyle(RiverheadTheme.textPrimary)

                    Text("Energy + housing affordability: why costs are high, what Riverhead can do locally, and which programs can help pay for solutions.")
                        .font(.subheadline)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                Pill(text: "Explainer", systemImage: "bolt.circle")
                Pill(text: "Town actions", systemImage: "building.columns")
                Pill(text: "Housing", systemImage: "house.fill")
                Pill(text: "Funding", systemImage: "banknote")
            }
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Filters

    private var filtersCard: some View {
        VStack(alignment: .leading, spacing: 10) {

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(EnergyFocusArea.allCases) { area in
                        FilterChip(
                            title: area.rawValue,
                            systemImage: area.icon,
                            isSelected: focus == area
                        ) {
                            focus = area
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Urgency")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                UrgencyPicker(selected: $urgency)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Policy Actions & Recommendations")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Spacer()

                Text("\(filteredActions.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(Capsule())
            }

            LazyVStack(spacing: 12) {
                ForEach(filteredActions) { item in
                    ActionCard(item: item)
                }

                if filteredActions.isEmpty {
                    ContentUnavailableView(
                        "No matches",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different focus area, urgency, or search term.")
                    )
                    .padding(.top, 10)
                }
            }
        }
    }

    // MARK: - Funding

    private var fundingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New York State Funding Matches")
                .font(.title3.weight(.semibold))
                .foregroundStyle(RiverheadTheme.textPrimary)

            Text("Use these to fund audits, efficiency, solar/storage, and water/wastewater energy reductions. Confirm current eligibility and deadlines.")
                .font(.subheadline)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVStack(spacing: 12) {
                ForEach(programs) { p in
                    FundingCard(program: p)
                }
            }
        }
    }

    // MARK: - Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notes")
                .font(.headline)
                .foregroundStyle(RiverheadTheme.textPrimary)

            Text("This is a civic-facing summary (not legal/engineering advice). Procurement rules, interconnection, permitting, and engineering constraints apply. Coordinate with Town staff/counsel before final commitments.")
                .font(.subheadline)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}

// MARK: - Data (Energy-only)

private enum EnergyPolicyInsightsData {

    static let actions: [EnergyPolicyAction] = [

        .init(
            area: .explainer,
            urgency: .now,
            title: "Why Long Island electricity is expensive (plain-English overview)",
            whyItMatters: "Most bills are a stack: supply + delivery + riders/taxes. On Long Island, peak demand, constrained imports, fuel exposure, and resilience/hardening spending can all push costs higher.",
            recommendedActions: [
                "Explain the bill stack: Supply (energy) + Delivery (grid) + Adders (riders/taxes).",
                "Teach peak reality: a few hot hours can drive outsized system costs.",
                "Clarify what’s Town-local vs what’s set by utilities/state regulation."
            ],
            nextSteps: [
                "Publish a 1-page Town explainer/FAQ residents can share.",
                "Pair education with measurable Town actions (below)."
            ],
            fundingMatches: [
                "NYSERDA Clean Energy Communities",
                "NYSERDA FlexTech"
            ]
        ),

        .init(
            area: .explainer,
            urgency: .next,
            title: "Track kWh, peak kW, and cost/kWh (not just total dollars)",
            whyItMatters: "If you only track total spend, you can’t see what’s driving it. Peak kW and demand-driven costs can dominate certain accounts.",
            recommendedActions: [
                "Track facility-level kWh, peak kW (where available), and cost/kWh monthly.",
                "Create an ‘actions + verified savings’ ledger for accountability.",
                "Identify the top 10 Town meters by annual spend and target them first."
            ],
            nextSteps: [
                "Start with Town Hall, DPW, parks, and major pump loads.",
                "Use results to pick 3 high-ROI projects for the next budget cycle."
            ],
            fundingMatches: [
                "NYSERDA FlexTech"
            ]
        ),

        .init(
            area: .housingIncome,
            urgency: .now,
            title: "Household income map should drive housing affordability targets",
            whyItMatters: "Riverhead’s median household income is about $81,977, with neighborhood medians ranging from roughly $34,337 to $147,176. Higher-income areas are more common in the northeast, while lower-income areas are more common in the west. This spread means “one-size” affordability targets will miss the households most stretched. Source: https://bestneighborhood.org/household-income-riverhead-ny/",
            recommendedActions: [
                "Target affordability bands to local income reality (not just regional averages). Prioritize options for households in the lower-income west-side areas.",
                "Use mixed-income requirements: set aside units affordable to lower-income households while allowing workforce and moderate-income units to cross-subsidize.",
                "Align zoning to income reality: smaller-lot homes, ADUs, and duplex/triplex options to expand supply at lower price points."
            ],
            nextSteps: [
                "Map Town-owned or underused parcels near jobs/transit for mixed-income housing pilots.",
                "Pair affordability targets with faster approvals for projects that meet income-based set‑asides.",
                "Track rent-burden locally (share paying >30% of income on housing) as a core KPI."
            ],
            fundingMatches: []
        ),

        .init(
            area: .housingIncome,
            urgency: .next,
            title: "Riverhead-specific inventory strategy + smart policies",
            whyItMatters: "With a wide income range across neighborhoods, Riverhead needs a realistic, phased plan that expands supply without overloading infrastructure or services.",
            recommendedActions: [
                "Phase 1 (0–18 months): allow by‑right ADUs and duplex/triplex conversions on existing lots near Village core and hamlet centers, with owner‑occupancy rules to prevent speculative flips.",
                "Phase 2 (18–36 months): pre‑zone 3–4 mixed‑income sites on Town‑owned or underused parcels (parking lots, surplus facilities) near transit and jobs; use expedited approvals for projects with income‑based set‑asides.",
                "Phase 3 (36+ months): require inclusionary zoning in larger projects (mix of lower‑income + workforce tiers) and allow modest density bonuses when affordability targets are met.",
                "Pair zoning changes with infrastructure readiness: water/sewer capacity checks and targeted capital upgrades so growth is serviceable.",
                "Preservation toolkit: rehab grants/loans and code‑compliance assistance to keep existing lower‑cost housing viable."
            ],
            nextSteps: [
                "Adopt a “small wins” inventory target (e.g., 30–60 units/year from ADUs + conversions) before scaling larger rezonings.",
                "Publish an annual housing scorecard: units added by income tier, geography, and affordability duration."
            ],
            fundingMatches: []
        ),

        .init(
            area: .townActions,
            urgency: .now,
            title: "Peak reduction playbook for Town facilities (the ‘few hottest days’ strategy)",
            whyItMatters: "Peak hours are expensive. Small reductions at municipal sites can lower bills and support system-wide affordability.",
            recommendedActions: [
                "Pre-cool buildings; stagger HVAC starts; shift non-critical loads off late-afternoon peaks.",
                "Tune setpoints/schedules; use smart controls where feasible.",
                "Create a ‘heat-wave day’ checklist: what can be reduced, who approves, what’s protected."
            ],
            nextSteps: [
                "Pilot at 2–3 buildings and measure before/after peaks.",
                "Write an SOP and train staff."
            ],
            fundingMatches: [
                "NYSERDA FlexTech",
                "Clean Energy Communities"
            ]
        ),

        .init(
            area: .townActions,
            urgency: .next,
            title: "Solar on Town facilities (stabilize part of operating costs)",
            whyItMatters: "Municipal solar reduces grid purchases and can make a portion of costs more predictable; bundling sites can improve economics.",
            recommendedActions: [
                "Prioritize big roofs, DPW yards, and parking canopies (site-dependent).",
                "Bundle multiple sites into one procurement to reduce soft costs.",
                "Plan interconnection early to avoid schedule/cost surprises."
            ],
            nextSteps: [
                "Build a shortlist of candidate sites (area, photos, shading notes).",
                "Run feasibility and decide procurement pathway."
            ],
            fundingMatches: [
                "NYSERDA NY-Sun"
            ]
        ),

        .init(
            area: .townActions,
            urgency: .next,
            title: "Battery storage for peak shaving + critical operations",
            whyItMatters: "Storage can reduce peak-driven costs and support critical operations; sizing for peak shaving first often improves economics.",
            recommendedActions: [
                "Target sites with high peaks or critical operations.",
                "Define primary use-case (peak shaving) + secondary (resilience).",
                "Coordinate siting/safety/permitting early."
            ],
            nextSteps: [
                "Define critical loads and minimum runtime targets.",
                "Assess permitting/fire code requirements early."
            ],
            fundingMatches: [
                "NYSERDA Energy Storage"
            ]
        ),

        .init(
            area: .townActions,
            urgency: .next,
            title: "Reduce water/sewer energy intensity (pumps, aeration, controls)",
            whyItMatters: "Water and wastewater systems can be large municipal energy users. Efficiency saves every month without reducing services.",
            recommendedActions: [
                "Optimize pump schedules; add VFDs; replace inefficient motors.",
                "Tune controls/process optimization (e.g., aeration).",
                "Bundle improvements with planned capital upgrades."
            ],
            nextSteps: [
                "Benchmark energy per volume pumped/treated.",
                "Pick top 2 energy-consuming processes and phase improvements."
            ],
            fundingMatches: [
                "NYS EFC WIIA",
                "SRF (CWSRF/DWSRF)"
            ]
        )
    ]

    static let programs: [EnergyFundingProgram] = [
        .init(
            name: "NYSERDA — FlexTech",
            purpose: "Cost-shared studies: energy audits, feasibility, retro-commissioning, and planning.",
            goodFor: ["Municipal audits", "Peak reduction feasibility", "Grant-ready scoping"],
            link: URL(string: "https://www.nyserda.ny.gov/All-Programs/FlexTech-Program")
        ),
        .init(
            name: "NYSERDA — Clean Energy Communities (CEC)",
            purpose: "Municipal clean-energy actions and grant support (eligibility varies).",
            goodFor: ["Action-based pathways", "Municipal energy planning", "Community programs"],
            link: URL(string: "https://www.nyserda.ny.gov/All-Programs/Clean-Energy-Communities")
        ),
        .init(
            name: "NYSERDA — NY-Sun",
            purpose: "Solar incentives/support (sector/region rules apply).",
            goodFor: ["Municipal rooftop solar", "Bundled site deployments"],
            link: URL(string: "https://www.nyserda.ny.gov/All-Programs/NY-Sun")
        ),
        .init(
            name: "NYSERDA — Energy Storage",
            purpose: "Incentives for qualified storage projects that support peak reduction and grid flexibility.",
            goodFor: ["Battery peak shaving", "Solar + storage packages", "Critical facility support"],
            link: URL(string: "https://www.nyserda.ny.gov/All-Programs/Energy-Storage")
        ),
        .init(
            name: "NYS EFC — WIIA & SRF",
            purpose: "Grants (WIIA) and low-cost financing (SRF) for water/wastewater projects.",
            goodFor: ["Pumps/VFDs", "Controls/process optimization", "System upgrades"],
            link: URL(string: "https://efc.ny.gov/")
        )
    ]

    static func shareText(actions: [EnergyPolicyAction], programs: [EnergyFundingProgram]) -> String {
        var out: [String] = []
        out.append("RIVERHEAD NY BUDGET APP — POLICY FOCUS POINTS")
        out.append("")
        out.append("Top ‘Do Now’ items:")
        let top = actions.filter { $0.urgency == .now }
        for a in top.prefix(10) {
            out.append("• \(a.area.rawValue): \(a.title)")
        }
        out.append("")
        out.append("NYS funding starting points:")
        for p in programs {
            out.append("• \(p.name) — \(p.purpose)")
        }
        out.append("")
        out.append("Note: Summary only; confirm eligibility/deadlines and coordinate with Town staff/counsel.")
        return out.joined(separator: "\n")
    }
}

// MARK: - Components

private struct ActionCard: View {
    @Environment(\.colorScheme) private var scheme
    let item: EnergyPolicyAction
    @State private var expanded: Bool = false

    private var cardFill: Color {
        scheme == .dark ? Color(red: 10/255, green: 14/255, blue: 20/255) : RiverheadTheme.Surface.card
    }

    private var borderColor: Color {
        scheme == .dark ? Color.white.opacity(0.14) : RiverheadTheme.border.opacity(0.25)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(item.urgency.tint.opacity(0.15))
                        .frame(width: 38, height: 38)

                    Image(systemName: item.area.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(item.urgency.tint)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(item.title)
                            .font(.headline)
                            .foregroundStyle(RiverheadTheme.textPrimary)

                        Spacer(minLength: 10)

                        Badge(text: item.urgency.rawValue, tint: item.urgency.tint)
                    }

                    Text(item.whyItMatters)
                        .font(.subheadline)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        Badge(text: item.area.rawValue, tint: .gray)
                        if !item.fundingMatches.isEmpty {
                            Badge(text: "Has NYS Match", tint: .green)
                        }
                    }
                }
            }

            if expanded {
                Divider().opacity(0.5)

                if !item.recommendedActions.isEmpty {
                    BulletSection(title: "Recommended actions", bullets: item.recommendedActions)
                }
                if !item.nextSteps.isEmpty {
                    BulletSection(title: "Next steps", bullets: item.nextSteps)
                }
                if !item.fundingMatches.isEmpty {
                    BulletSection(title: "Funding matches", bullets: item.fundingMatches)
                }
            }

            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    expanded.toggle()
                }
            } label: {
                HStack {
                    Text(expanded ? "Show less" : "Show details")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RiverheadTheme.accent)
                .padding(.top, 2)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(cardFill))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(borderColor))
        .shadow(color: .black.opacity(scheme == .dark ? 0.45 : 0.12), radius: 12, x: 0, y: 6)
    }
}

private struct FundingCard: View {
    @Environment(\.colorScheme) private var scheme
    let program: EnergyFundingProgram

    private var cardFill: Color {
        scheme == .dark ? Color(red: 10/255, green: 14/255, blue: 20/255) : RiverheadTheme.Surface.card
    }

    private var borderColor: Color {
        scheme == .dark ? Color.white.opacity(0.14) : RiverheadTheme.border.opacity(0.25)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "banknote.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(RiverheadTheme.accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text(program.name)
                        .font(.headline)
                        .foregroundStyle(RiverheadTheme.textPrimary)

                    Text(program.purpose)
                        .font(.subheadline)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !program.goodFor.isEmpty {
                BulletSection(title: "Good for", bullets: program.goodFor)
            }

            if let link = program.link {
                Link(destination: link) {
                    Label("Open program page", systemImage: "arrow.up.right.square")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.accent)
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(cardFill))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(borderColor))
        .shadow(color: .black.opacity(scheme == .dark ? 0.45 : 0.12), radius: 12, x: 0, y: 6)
    }
}

private struct BulletSection: View {
    let title: String
    let bullets: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RiverheadTheme.textPrimary)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(bullets, id: \.self) { b in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.secondary.opacity(0.6))
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)

                        Text(b)
                            .font(.subheadline)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

private struct Badge: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.14))
            .foregroundStyle(tint)
            .clipShape(Capsule())
    }
}

private struct Pill: View {
    let text: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.06))
        .foregroundStyle(.secondary)
        .clipShape(Capsule())
    }
}

private struct FilterChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? RiverheadTheme.accent.opacity(0.16) : Color.primary.opacity(0.06))
            .foregroundStyle(isSelected ? RiverheadTheme.accent : Color.secondary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct UrgencyPicker: View {
    @Binding var selected: EnergyUrgency?

    var body: some View {
        HStack(spacing: 8) {
            Button { selected = nil } label: {
                Text("All")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(selected == nil ? RiverheadTheme.accent.opacity(0.16) : Color.primary.opacity(0.06))
                    .foregroundStyle(selected == nil ? RiverheadTheme.accent : Color.secondary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            ForEach(EnergyUrgency.allCases) { u in
                Button {
                    selected = (selected == u ? nil : u)
                } label: {
                    Text(u.rawValue)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background((selected == u) ? u.tint.opacity(0.18) : Color.primary.opacity(0.06))
                        .foregroundStyle((selected == u) ? u.tint : Color.secondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ToastBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 10, y: 6)
    }
}

#Preview {
    NavigationStack {
        BudgetPolicyInsightsView(initialFocus: .explainer)
    }
    .preferredColorScheme(.light)
}
