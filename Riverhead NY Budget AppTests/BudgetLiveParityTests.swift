import Foundation
import Testing
@testable import Riverhead_NY_Budget_App

struct BudgetLiveParityCatalogTests {
    @Test func routeCatalogMatchesCurrentWebNavigation() {
        #expect(BudgetLiveParityCatalog.routeCount == 45)
        #expect(BudgetLiveParityCatalog.hasUniquePaths)
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/programs/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/compare/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/general-fund/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/meetings/"))
        #expect(BudgetLiveParityCatalog.orderedRoutes.map(\.path).contains("/workforce-by-title/"))
    }

    @Test func coreBudgetRoutesAreRegisteredAsNative() {
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/search/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/meetings/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/funds/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/programs/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/compare/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/general-fund/"))
        #expect(BudgetLiveParityCatalog.nativePaths.contains("/workforce-by-title/"))
    }

    @Test func routeGroupsStillTotalFortyFive() {
        let groupedCount = BudgetLiveRouteGroup.allCases.reduce(into: 0) { total, group in
            total += BudgetLiveParityCatalog.routes[group, default: []].count
        }
        #expect(groupedCount == 45)
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
