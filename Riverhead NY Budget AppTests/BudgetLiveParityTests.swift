import Testing
@testable import Riverhead_NY_Budget_App

struct BudgetLiveParityCatalogTests {
    @Test func routeCatalogMatchesCurrentWebNavigation() {
        #expect(BudgetLiveParityCatalog.routeCount == 45)
        #expect(BudgetLiveParityCatalog.hasUniquePaths)
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/programs/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/compare/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/general-fund/"))
    }

    @Test func coreHistoryRoutesAreRegisteredAsNative() {
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/funds/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/compare/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/general-fund/"))
        #expect(!BudgetLiveParityCatalog.nativePaths.contains("/programs/"))
    }

    @Test func routeGroupsStillTotalFortyFive() {
        let groupedCount = BudgetLiveRouteGroup.allCases.reduce(into: 0) { total, group in
            total += BudgetLiveParityCatalog.routes[group, default: []].count
        }
        #expect(groupedCount == 45)
    }
}
