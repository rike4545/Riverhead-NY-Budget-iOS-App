//
//  BudgetStagesTests.swift
//  Riverhead NY Budget AppTests
//
//  The app's budget, overview and tax screens read the newest adopted budget from
//  the bundled BudgetHistory/budget-stages.json, the website's own file. These
//  hold that file to the 2027 Adopted Budget's Summary page (adopted November 17,
//  2026, Resolution 2026-995, 5–0, unchanged from the Preliminary).
//

import Foundation
import Testing
@testable import Riverhead_NY_Budget_App

struct BudgetStagesTests {

    @Test func bundledFileLoads() {
        #expect(BudgetStages.file != nil)
        #expect(BudgetStages.adoptedYears.contains(2026))
    }

    @Test func newestAdoptedYearIsAtLeast2027() throws {
        let year = try #require(BudgetStages.currentYear)
        #expect(year >= 2027)
        #expect(BudgetStages.priorYear == year - 1)
    }

    @Test func adopted2027MatchesItsSummaryPage() throws {
        let doc = try #require(BudgetStages.doc(2027, .adopted))
        #expect(doc.totals.funds == 19)
        #expect(doc.totals.appropriations == 120_854_219)
        #expect(doc.totals.levy == 66_516_005)
        #expect(doc.totals.fundBalance == 5_825_000)

        let gf = try #require(doc.generalFund)
        #expect(gf.appropriations == 71_932_070)
        #expect(gf.levy == 53_784_658)
        #expect(gf.fundBalance == 880_000)

        let tw = try #require(doc.townWide)
        #expect(tw.levy == 62_238_344)
        #expect(tw.rate == 72.487)
        #expect(tw.fundRates?["A01"]?.rate == 62.71)
        #expect(tw.fundRates?["DA1"]?.rate == 8.893)
        #expect(tw.fundRates?["SL1"]?.rate == 0.884)
    }

    @Test func adoptedSeriesReachesTheNewestYear() throws {
        let series = BudgetStages.adoptedSeries(fund: "A01") { $0.appropriations }
        let last = try #require(series.last)
        #expect(last.year == BudgetStages.currentYear)
        #expect(series.contains { $0.year == 2026 && $0.value == 69_113_159 })
    }

    @MainActor @Test func storeUsesTheNewestAdoptedBudget() {
        let store = RBBudgetStore()
        #expect(store.fiscalYearTitle.hasPrefix(String(BudgetStages.currentYear ?? 0)))
        #expect(store.appropriations == BudgetStages.current?.generalFund?.appropriations)
        // The 2027 model tools keep their 2026 starting point.
        #expect(store.modelBaseAppropriations == 69_113_159)
        #expect(store.modelBaseRatePerThousand == 71.598)
    }
}
