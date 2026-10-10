import Foundation
import Testing
@testable import Riverhead_NY_Budget_App

struct BudgetLiveParityCatalogTests {
    @Test func routeCatalogMatchesCurrentWebNavigation() {
        #expect(BudgetLiveParityCatalog.routeCount == 54)
        #expect(BudgetLiveParityCatalog.hasUniquePaths)
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/programs/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/compare/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/general-fund/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/meetings/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/workforce-by-title/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/outliers/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/revenue/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/fund-balance-draws/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/management-compensation/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/police-crime/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/school-resource-officers/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/supervisor-promises/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/open-meetings/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/tentative-2027/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/budget-adoption/"))
    }

    @Test func coreBudgetRoutesAreRegisteredAsNative() {
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/tax-bill/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/road-spending/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/town-history/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/officials/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/candidate-watch/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/tax-cap/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/payroll/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/search/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/meetings/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/funds/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/programs/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/compare/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/general-fund/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/workforce-by-title/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/board-elections/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/outliers/"))

        // A deliberate tripwire. Adding a native route takes three edits —
        // nativePaths, a parityDestination case, and the routes table — and the
        // per-route assertions above cannot notice a path that was never added
        // to them, which is how /board-elections/ went untested. This fails on
        // the next route, which is the point: it forces the list to be updated
        // rather than quietly drifting behind the Set it is meant to mirror.
        #expect(BudgetLiveParityCatalog.nativePaths.count == 16)
    }

    /// A path can be marked native, badged as native in the hub, and still
    /// fall through parityDestination to the web view if the switch case was
    /// missed — three places have to be edited to add a route. This catches
    /// the half that is introspectable: a native path that is not a real
    /// route at all. The switch side is checked when the route is wired.
    @Test func everyNativePathIsADeclaredRoute() {
        let declared = Set(BudgetLiveParityCatalog.orderedRoutes.map(\.path))
        let orphans = BudgetLiveParityCatalog.nativePaths.subtracting(declared)
        #expect(orphans.isEmpty)
    }

    @Test func routeGroupsStillTotalFiftyFour() {
        let groupedCount = BudgetLiveRouteGroup.allCases.reduce(into: 0) { total, group in
            total += BudgetLiveParityCatalog.routes[group, default: []].count
        }
        #expect(groupedCount == 54)
    }

    @Test func programBudgetContractDecodes() throws {
        let json = #"""
        {
          "schemaVersion": 1,
          "source": {"title":"2026 Adopted Budget","detail":"Account-level detail","url":"https://example.com"},
          "payrollYear": 2025,
          "census": {
            "dataset":"ACS 2024",
            "source":{"title":"ignored by native decoder"},
            "population": 35000,
            "households": 14000,
            "householdsMoe": 500,
            "medianHouseholdIncome": 90000
          },
          "programs": [{
            "key":"3",
            "name":"Public Safety",
            "plain":"Police and related services.",
            "narrative":"Narrative",
            "buys":["Police"],
            "direct":30000000,
            "benefits":10000000,
            "fullCost":40000000,
            "earned":1000000,
            "net":39000000,
            "recoveryPct":2.5,
            "netPerResident":1114.28,
            "netPerHousehold":2785.71,
            "staff":150,
            "departments":[{"fund":"A01","code":"3120","name":"Police","amount":30000000}],
            "topRevenues":[{"name":"Police Fees","amount":1000000}]
          }],
          "totals": {
            "direct":30000000,"benefits":10000000,"fullCost":40000000,"earned":1000000,"net":39000000,
            "staff":150,"debtService":6000000,"contingency":0,"interfundTransfers":2000000,"townwideRevenue":50000000,
            "grandTotal":46000000,"appropriations":48000000
          },
          "perResident":{"programs":1114.28,"debtService":171.42,"everything":1285.70},
          "perHousehold":{"programs":2785.71,"debtService":428.57,"everything":3214.28,"shareOfMedianIncome":3.57},
          "reconciliation":{"computed":48000000,"appropriations":48000000,"variance":0},
          "method":[{"title":"Method","body":"Body"}],
          "notCovered":{"title":"Limits","body":"No performance measures."},
          "diagnostics":{"unmappedPayrollDepartments":[]}
        }
        """#

        let decoded = try JSONDecoder().decode(ProgramBudgetParityDocument.self, from: Data(json.utf8))
        #expect(decoded.schemaVersion == 1)
        #expect(decoded.programs.count == 1)
        #expect(decoded.programs[0].name == "Public Safety")
        #expect(decoded.reconciliation.variance == 0)
    }
}
