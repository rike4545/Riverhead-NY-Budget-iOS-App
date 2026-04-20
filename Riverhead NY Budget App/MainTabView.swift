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

@MainActor
struct MainTabView: View {
    private enum AppTab: String, Hashable {
        case home
        case budget
        case toolkits
        case more

        var title: String {
            switch self {
            case .home:
                return "Home"
            case .budget:
                return "Budget"
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
            case .toolkits:
                return "person.2.badge.gearshape"
            case .more:
                return "ellipsis.circle"
            }
        }
    }

    @AppStorage("Riverhead.selectedTab") private var selectedTabRaw: String = AppTab.home.rawValue
    @Environment(RBBudgetStore.self) private var budgetStore

    @State private var hasPreparedBudgetData = false
    @State private var isPreparingBudgetData = false

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
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(RiverheadTheme.softBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
            .accessibilityElement(children: .combine)
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
