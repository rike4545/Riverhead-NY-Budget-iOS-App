//
//  MainTabView.swift
//  Riverhead NY Budget App
//
//  Root tab container. Referenced by RootView.
//  All stores flow in from Riverhead_NYApp via environment injection:
//    - RBBudgetStore         (@Observable  → .environment)
//    - RBCivicToolkitStore   (ObservableObject → .environmentObject)
//    - RBSixSigmaStore       (ObservableObject → .environmentObject)
//
//  Swift 5 language mode • iOS 26+
//
//  Bars are deliberately left unstyled. On iOS 26 the system draws the tab bar
//  and navigation bar in Liquid Glass; any UIKit appearance proxy set here would
//  replace that material with a flat fill and the app would look like it had
//  never been rebuilt. The previous version of this file did exactly that.
//
//  Note that nothing here calls a Liquid Glass API by name. The bars get the
//  material from the SDK because nothing overrides them any more, which is the
//  whole adoption. .glassEffect and .tabBarMinimizeBehavior were tried and then
//  removed: they were written without an SDK to check them against, and an
//  unverifiable API call is not worth the build.
//

import SwiftUI

@MainActor
struct MainTabView: View {
    private enum AppTab: String, Hashable {
        case home
        case budget
        case discover
        case toolkits
        case more

        var title: String {
            switch self {
            case .home:
                return "Home"
            case .budget:
                return "Budget"
            case .discover:
                return "Civic"
            case .toolkits:
                return "Tools"
            case .more:
                return "More"
            }
        }

        var systemImage: String {
            switch self {
            case .home:
                return "house.fill"
            case .budget:
                return "chart.bar.doc.horizontal"
            case .discover:
                return "sparkle.magnifyingglass"
            case .toolkits:
                return "person.2.badge.gearshape"
            case .more:
                return "ellipsis.circle"
            }
        }
    }

    @AppStorage("Riverhead.selectedTab") private var selectedTabRaw: String = AppTab.home.rawValue
    @Environment(RBBudgetStore.self) private var budgetStore
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @State private var hasPreparedBudgetData = false
    @State private var isPreparingBudgetData = false

    var body: some View {
        TabView(selection: selectedTab) {
            Tab(AppTab.home.title, systemImage: AppTab.home.systemImage, value: AppTab.home) {
                NavigationStack {
                    HomeView()
                }
            }

            Tab(AppTab.budget.title, systemImage: AppTab.budget.systemImage, value: AppTab.budget) {
                NavigationStack {
                    RiverheadBudgetHubView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Menu {
                                    NavigationLink {
                                        WebContentView(
                                            url: URL(string: "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/tentative-2027/")!,
                                            title: "2027 Tentative Budget"
                                        )
                                    } label: {
                                        Label("2027 Tentative Budget", systemImage: "doc.text")
                                    }
                                    NavigationLink {
                                        BudgetLiveParityView()
                                    } label: {
                                        Label("Browse all topics", systemImage: "square.grid.2x2")
                                    }
                                } label: {
                                    Label("More budget topics", systemImage: "line.3.horizontal")
                                }
                            }
                        }
                }
            }

            Tab(AppTab.discover.title, systemImage: AppTab.discover.systemImage, value: AppTab.discover) {
                NavigationStack {
                    CivicImprovementsHubView()
                }
            }

            Tab(AppTab.toolkits.title, systemImage: AppTab.toolkits.systemImage, value: AppTab.toolkits) {
                NavigationStack {
                    CivicToolkitsHubView()
                }
            }

            Tab(AppTab.more.title, systemImage: AppTab.more.systemImage, value: AppTab.more) {
                NavigationStack {
                    MoreView()
                }
            }
        }
        .tint(RiverheadTheme.accent)
        .task {
            await prepareBudgetDataIfNeeded()
        }
        .overlay(alignment: .top) {
            if isPreparingBudgetData {
                startupBanner
                    .padding(.top, 8)
            }
        }
    }

    private var selectedTab: Binding<AppTab> {
        Binding(
            get: { AppTab(rawValue: selectedTabRaw) ?? .home },
            set: { selectedTabRaw = $0.rawValue }
        )
    }

    // A floating pill over scrolling content is the textbook case for Liquid Glass,
    // and .glassEffect(.regular, in: Capsule()) would replace the material, border
    // and shadow below with one call. It is not used here because it was written
    // without an SDK to verify it against; the material version is what shipped
    // before and is known to build. Worth revisiting on a machine with Xcode 26.
    private var startupBanner: some View {
        Label("Loading budget data", systemImage: "arrow.trianglehead.2.clockwise")
            .font(.footnote.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                reduceTransparency
                ? AnyShapeStyle(RiverheadTheme.Surface.card)
                : AnyShapeStyle(.ultraThinMaterial),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .strokeBorder(RiverheadTheme.softBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Loading budget data")
            .accessibilityHint("Budget data is warming up in the background.")
            .accessibilityAddTraits(.updatesFrequently)
    }

    private func prepareBudgetDataIfNeeded() async {
        guard !hasPreparedBudgetData else { return }

        hasPreparedBudgetData = true
        isPreparingBudgetData = true
        await BudgetDataBootstrapper.warmUpAsync()
        budgetStore.refreshFromLoadedData()
        isPreparingBudgetData = false
    }
}

#Preview {
    MainTabView()
        .environmentObject(RBCivicToolkitStore())
        .environmentObject(RBSixSigmaStore())
        .environment(RBBudgetStore())
}
