//
//  BudgetLiveParityView.swift
//  Riverhead NY Budget App
//
//  Mirrors every user-facing route in Riverhead Budget Live's current SiteNav.
//  The live web implementation remains the parity fallback so newly-added web
//  tools stay usable while route-by-route native SwiftUI parity continues.
//

import SwiftUI

struct BudgetLiveRoute: Identifiable, Hashable, Sendable {
    let title: String
    let path: String
    let systemImage: String
    let detail: String

    var id: String { path }

    var url: URL {
        URL(string: "https://rike4545.github.io/Riverhead-NY-Budget-Web-App\(path)")!
    }
}

enum BudgetLiveRouteGroup: String, CaseIterable, Identifiable, Sendable {
    case startHere = "Start Here"
    case explore = "Explore"
    case government = "Government"
    case research = "Research"
    case evidence = "Evidence"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .startHere: "rectangle.grid.2x2.fill"
        case .explore: "chart.bar.xaxis"
        case .government: "building.columns.fill"
        case .research: "magnifyingglass.circle.fill"
        case .evidence: "checkmark.seal.fill"
        }
    }
}

enum BudgetLiveParityCatalog {
    /// Routes that now open a native SwiftUI implementation from this parity hub.
    /// All other routes continue to use the live web fallback.
    static let nativePaths: Set<String> = [
        "/tax-bill/",
        "/payroll/",
        "/search/",
        "/meetings/",
        "/funds/",
        "/programs/",
        "/compare/",
        "/general-fund/",
        "/workforce-by-title/",
        "/board-elections/",
        "/outliers/"
    ]

    static let routes: [BudgetLiveRouteGroup: [BudgetLiveRoute]] = [
        .startHere: [
            .init(title: "My Taxes", path: "/tax-bill/", systemImage: "house.and.flag.fill", detail: "Estimate a property tax bill from assessed value."),
            .init(title: "Payroll", path: "/payroll/", systemImage: "person.text.rectangle.fill", detail: "Explore employee earnings, salary comparisons, and payroll history."),
            .init(title: "Board Votes", path: "/meetings/", systemImage: "checklist.checked", detail: "Review Town Board votes resolution by resolution."),
            .init(title: "Search", path: "/search/", systemImage: "magnifyingglass", detail: "Search the unified public-record index.")
        ],
        .explore: [
            .init(title: "Where Your Levy Goes", path: "/taxpayer-impact/", systemImage: "dollarsign.arrow.circlepath", detail: "See how the property-tax levy is allocated."),
            .init(title: "What Changed", path: "/what-changed/", systemImage: "arrow.left.arrow.right", detail: "Review the biggest changes in the current budget."),
            .init(title: "Financial Health", path: "/analytics/", systemImage: "waveform.path.ecg", detail: "Explore financial-health indicators and trends."),
            .init(title: "Budget Overview", path: "/funds/", systemImage: "building.columns", detail: "Drill into funds, departments, categories, and account lines."),
            .init(title: "Program Budget", path: "/programs/", systemImage: "square.grid.3x3.fill", detail: "Explore spending by program and service area."),
            .init(title: "Budget Compare", path: "/compare/", systemImage: "chart.bar.doc.horizontal", detail: "Compare adopted fund appropriations across 2020–2026."),
            .init(title: "General Fund", path: "/general-fund/", systemImage: "chart.line.uptrend.xyaxis", detail: "Review the long-run General Fund history."),
            .init(title: "Annual Report", path: "/annual-report/", systemImage: "doc.text.magnifyingglass", detail: "Explore the Town's annual financial report in searchable form."),
            .init(title: "Tax Cap", path: "/tax-cap/", systemImage: "percent", detail: "Understand the New York property-tax cap and Riverhead history."),
            .init(title: "Reserves & Fund Balance", path: "/reserves/", systemImage: "banknote.fill", detail: "Review reserve policy, fund balance, draw-down modeling, and peers."),
            .init(title: "Capital & Debt", path: "/capital-debt/", systemImage: "building.2.crop.circle", detail: "Review debt, amortization, BANs, bonds, and financing scenarios."),
            .init(title: "Town Square", path: "/town-square/", systemImage: "building.2.fill", detail: "Review the Town Square project, financing, and source record."),
            .init(title: "Road Spending", path: "/road-spending/", systemImage: "road.lanes", detail: "Explore road and highway spending context."),
            .init(title: "Community Preservation Fund", path: "/community-preservation-fund/", systemImage: "leaf.fill", detail: "Review CPF revenues, obligations, and policy context."),
            .init(title: "Community Housing Plan", path: "/housing-plan/", systemImage: "house.lodge.fill", detail: "Explore the Town's community housing plan and fiscal context."),
            .init(title: "Community", path: "/community/", systemImage: "person.3.fill", detail: "See population, assessment, tax-base, and community context.")
        ],
        .government: [
            .init(title: "Resident Answers", path: "/answers/", systemImage: "questionmark.bubble.fill", detail: "Plain-language answers to common resident questions."),
            .init(title: "Workforce by Title", path: "/workforce-by-title/", systemImage: "person.3.sequence.fill", detail: "Explore the municipal workforce grouped by job title."),
            .init(title: "Officials & Pensions", path: "/officials/", systemImage: "person.crop.rectangle.stack.fill", detail: "Review elected and appointed officials with pension context."),
            .init(title: "2026 Buyout", path: "/buyout/", systemImage: "person.badge.minus", detail: "Review the early-retirement incentive and realistic savings cases."),
            .init(title: "Supervisors & Council History", path: "/town-history/", systemImage: "clock.arrow.circlepath", detail: "Review Riverhead's supervisor and council history."),
            .init(title: "Board Elections", path: "/board-elections/", systemImage: "checkmark.rectangle.stack.fill", detail: "Explore Town Board election history and context."),
            .init(title: "Campaign Finance", path: "/campaign-finance/", systemImage: "dollarsign.circle.fill", detail: "Load current NYS campaign-finance filings and donor context."),
            .init(title: "Candidate Watch", path: "/candidate-watch/", systemImage: "eye.fill", detail: "Review current candidate information and sourced claims."),
            .init(title: "Candidate Proposals", path: "/candidate-cost-benefit/", systemImage: "scale.3d", detail: "Review candidate proposals through a cost-benefit lens.")
        ],
        .research: [
            .init(title: "Start Here", path: "/guide/", systemImage: "signpost.right.and.left.fill", detail: "A guided entry point to the platform and its sources."),
            .init(title: "2027 Prediction", path: "/predict-2027/", systemImage: "chart.line.uptrend.xyaxis.circle.fill", detail: "Explore the forward projection for the next adopted budget."),
            .init(title: "Scenario Lab", path: "/scenarios/", systemImage: "slider.horizontal.3", detail: "Model alternative fiscal assumptions and tradeoffs."),
            .init(title: "2027 Spending Reduction", path: "/spending-reduction-2027/", systemImage: "scissors.circle.fill", detail: "Review sourced recurring spending-reduction candidates."),
            .init(title: "A Zero-Percent Year", path: "/zero-percent-2027/", systemImage: "0.circle.fill", detail: "Explore what a zero-percent levy-growth year would require."),
            .init(title: "Credit Rating", path: "/credit-rating/", systemImage: "seal.fill", detail: "Review the Town's credit rating and debt-capacity context."),
            .init(title: "Outlier Watch", path: "/outliers/", systemImage: "exclamationmark.triangle.fill", detail: "Flag large year-over-year fund swings worth a closer look."),
            .init(title: "Budget Accuracy", path: "/budget-accuracy/", systemImage: "scope", detail: "Compare budget assumptions with subsequent financial results."),
            .init(title: "Fiscal Impact", path: "/fiscal-impact/", systemImage: "doc.badge.gearshape.fill", detail: "Read Town Board fiscal-impact statements in resident-friendly form.")
        ],
        .evidence: [
            .init(title: "Source Library", path: "/sources/", systemImage: "books.vertical.fill", detail: "Open the source trail behind the platform's figures."),
            .init(title: "Downloads", path: "/downloads/", systemImage: "arrow.down.doc.fill", detail: "Download published datasets for independent analysis."),
            .init(title: "Data Quality & Freshness", path: "/data-quality/", systemImage: "checkmark.circle.badge.questionmark", detail: "Review refresh dates, data limitations, and quality checks."),
            .init(title: "Standards (GFOA)", path: "/gfoa/", systemImage: "checkmark.seal.fill", detail: "Compare Riverhead's budget presentation with GFOA standards."),
            .init(title: "Election Law Case", path: "/election-law-case/", systemImage: "scroll.fill", detail: "Review the sourced election-law case material."),
            .init(title: "Officials on Social Media", path: "/official-social-media/", systemImage: "bubble.left.and.bubble.right.fill", detail: "Review public-official social-media accountability context."),
            .init(title: "Know Your Rights (ICE)", path: "/know-your-rights/", systemImage: "person.badge.shield.checkmark.fill", detail: "Open the platform's sourced know-your-rights reference.")
        ]
    ]

    static let orderedRoutes: [BudgetLiveRoute] = BudgetLiveRouteGroup.allCases.flatMap { routes[$0, default: []] }
    static let routeCount = orderedRoutes.count

    static var hasUniquePaths: Bool {
        Set(orderedRoutes.map(\.path)).count == orderedRoutes.count
    }

    static func isNative(_ route: BudgetLiveRoute) -> Bool {
        nativePaths.contains(route.path)
    }
}

@MainActor
struct BudgetLiveParityView: View {
    @State private var searchText = ""

    private var normalizedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func visibleRoutes(in group: BudgetLiveRouteGroup) -> [BudgetLiveRoute] {
        let routes = BudgetLiveParityCatalog.routes[group, default: []]
        guard !normalizedSearch.isEmpty else { return routes }

        return routes.filter {
            $0.title.localizedCaseInsensitiveContains(normalizedSearch)
            || $0.detail.localizedCaseInsensitiveContains(normalizedSearch)
            || $0.path.localizedCaseInsensitiveContains(normalizedSearch)
        }
    }

    var body: some View {
        List {
            ForEach(BudgetLiveRouteGroup.allCases) { group in
                let groupRoutes = visibleRoutes(in: group)
                if !groupRoutes.isEmpty {
                    Section {
                        ForEach(groupRoutes) { route in
                            NavigationLink {
                                parityDestination(for: route)
                            } label: {
                                BudgetLiveParityRouteRow(route: route)
                            }
                        }
                    } header: {
                        Label(group.rawValue, systemImage: group.systemImage)
                    }
                }
            }

            if !normalizedSearch.isEmpty
                && BudgetLiveRouteGroup.allCases.allSatisfy({ visibleRoutes(in: $0).isEmpty }) {
                ContentUnavailableView.search(text: normalizedSearch)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Budget Live")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search \(BudgetLiveParityCatalog.routeCount) web features")
    }

    @ViewBuilder
    private func parityDestination(for route: BudgetLiveRoute) -> some View {
        switch route.path {
        case "/tax-bill/":
            NativeTaxBillParityView()
        case "/payroll/":
            NativePayrollParityView()
        case "/search/":
            NativeUnifiedSearchView()
        case "/meetings/":
            TownBoardVotesView()
        case "/funds/":
            FundDetailExplorerView()
        case "/programs/":
            NativeProgramBudgetView()
        case "/compare/":
            NativeBudgetCompareView()
        case "/general-fund/":
            NativeGeneralFundHistoryView()
        case "/workforce-by-title/":
            WorkforceByTitleView()
        case "/board-elections/":
            NativeBoardElectionsParityView()
        case "/outliers/":
            NativeOutlierWatchView()
        default:
            WebContentView(url: route.url, title: route.title)
        }
    }
}

private struct BudgetLiveParityRouteRow: View {
    let route: BudgetLiveRoute

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: route.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(RiverheadTheme.accent)
                .frame(width: 26, height: 26)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(route.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.textPrimary)

                    if BudgetLiveParityCatalog.isNative(route) {
                        Text("NATIVE")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(RiverheadTheme.brandTeal)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RiverheadTheme.brandTeal.opacity(0.10), in: Capsule())
                    }
                }

                Text(route.detail)
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(route.title)
        .accessibilityValue(route.detail)
        .accessibilityHint(
            BudgetLiveParityCatalog.isNative(route)
            ? "Opens the native iOS implementation."
            : "Opens the live Riverhead Budget Live feature inside the app."
        )
    }
}

#Preview {
    NavigationStack {
        BudgetLiveParityView()
            .environment(RBBudgetStore())
    }
}
