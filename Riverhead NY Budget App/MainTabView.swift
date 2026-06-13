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
//  Swift 6 • iOS 17+
//

import SwiftUI
import UIKit

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
                return "Discover"
            case .toolkits:
                return "Toolkits"
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

    init() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        tabAppearance.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.055, green: 0.079, blue: 0.106, alpha: 0.94)
            : UIColor(red: 0.920, green: 0.956, blue: 0.965, alpha: 0.94)
        }
        tabAppearance.shadowColor = UIColor.black.withAlphaComponent(0.10)
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.098, green: 0.325, blue: 0.482, alpha: 1.0)
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(red: 0.098, green: 0.325, blue: 0.482, alpha: 1.0)
        ]
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.553, green: 0.729, blue: 0.745, alpha: 0.70)
            : UIColor(red: 0.306, green: 0.459, blue: 0.584, alpha: 0.70)
        }
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor { trait in
                trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.553, green: 0.729, blue: 0.745, alpha: 0.70)
                : UIColor(red: 0.306, green: 0.459, blue: 0.584, alpha: 0.70)
            }
        ]
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        navAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        navAppearance.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.055, green: 0.079, blue: 0.106, alpha: 0.92)
            : UIColor(red: 0.928, green: 0.958, blue: 0.966, alpha: 0.92)
        }
        navAppearance.shadowColor = UIColor.black.withAlphaComponent(0.08)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(red: 0.098, green: 0.325, blue: 0.482, alpha: 1.0)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(red: 0.098, green: 0.325, blue: 0.482, alpha: 1.0)
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }

    var body: some View {
        TabView(selection: selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label(AppTab.home.title, systemImage: AppTab.home.systemImage)
            }
            .tag(AppTab.home)

            NavigationStack {
                RiverheadBudgetHubView()
            }
            .tabItem {
                Label(AppTab.budget.title, systemImage: AppTab.budget.systemImage)
            }
            .tag(AppTab.budget)

            NavigationStack {
                CivicImprovementsHubView()
            }
            .tabItem {
                Label(AppTab.discover.title, systemImage: AppTab.discover.systemImage)
            }
            .tag(AppTab.discover)

            NavigationStack {
                CivicToolkitsHubView()
            }
            .tabItem {
                Label(AppTab.toolkits.title, systemImage: AppTab.toolkits.systemImage)
            }
            .tag(AppTab.toolkits)

            NavigationStack {
                MoreView()
            }
            .tabItem {
                Label(AppTab.more.title, systemImage: AppTab.more.systemImage)
            }
            .tag(AppTab.more)
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
