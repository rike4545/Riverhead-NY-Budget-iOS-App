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

struct BudgetLinesTests {

    @Test func linesReconcileToTheAdoptedSummary() {
        // budget-2027-preliminary-lines.json: the Preliminary the Board adopted unchanged.
        #expect(BudgetLines.file?.year == 2027)
        #expect(BudgetLines.isAdopted)
        #expect(BudgetLines.adoptedYear == 2027)
    }

    @Test func generalFundDepartmentsAddUpToItsAppropriations() {
        let total = BudgetLines.departments(fundCode: "A01").reduce(0) { $0 + $1.total }
        #expect(abs(total - 71_932_070) < 1)
    }

    @Test func generalFundChangeByGroupAddsUpToTheIncrease() {
        // 71,932,070 − 69,113,159 = 2,818,911
        let groups = BudgetLines.changeByGroup(fundCode: "A01")
        #expect(abs(groups.reduce(0) { $0 + $1.change } - 2_818_911) < 1)
        let personal = groups.first { $0.group == .personalServices }?.change ?? 0
        #expect(abs(personal - 1_926_098) < 1)
    }

    @Test func departmentRecordsMoveTo2027() {
        let police = DepartmentBudgetLensData.departmentRecords.first { $0.fundCode == "A01-3120" }
        #expect(police?.budgetYear == 2027)
        #expect(police?.adoptedTotal == 23_244_090)
        #expect(police?.priorAdoptedTotal == 22_388_906)
    }

    @Test func ledgerReadsThe2027Supplement() {
        #expect(SupplementData.currentLines?.supplementYear == 2027)
    }

    @Test func watchListReadsThe2027Supplement() {
        // budget-supplement/current-outliers.json and history.json on the website.
        #expect(SupplementData.outliers?.budgetYear == 2027)
        #expect((SupplementData.outliers?.overBudget.count ?? 0) > 0)
        #expect(SupplementData.history?.proposalYear == 2027)
        #expect(SupplementData.history?.supplementYears?.last == 2027)
    }
}

struct ModelVsAdopted2027Tests {

    @Test func comparesTheModelWithTheAdoptedBudget() throws {
        let rows = try #require(ModelVsAdopted2027.rows)
        #expect(rows.first?.adopted.contains("$66,516,005") == true)
        // NYS retirement lines 9010 and 9015, every fund: 9,926,436 → 10,492,625.
        #expect(rows.contains { $0.label.hasPrefix("NYS retirement") && $0.adopted.contains("566,189") })
    }
}

struct PoliceContracts2027DetailTests {

    @Test func stepChangesFollowTheSchedule() {
        let top = PoliceContracts2027.pbaOfficers[6]
        let changes = PoliceContracts2027.yearlyChanges(top)
        #expect(changes.count == 4)
        #expect(changes.first?.year == 2027)
        // 159,134.43 − 152,900.66, Appendix B page 205.
        #expect(abs((changes.first?.change ?? 0) - 6_233.77) < 0.01)
    }

    @Test func k9RatesAndHandlers() {
        #expect(PoliceContracts2027.k9.rates[1] == 8_349.39)
        #expect(!PoliceContracts2027.k9Officers.isEmpty)
    }

    @Test func longevityListsTheSeniorOfficers() {
        let people = PoliceContracts2027.longevityCandidates
        #expect(!people.isEmpty)
        // Nobody is paid before January 1, 2028.
        #expect(people.allSatisfy { $0.amount(in: 2027) == nil })
        // A top-step officer with 25 years gets 8% of 165,101.98 in 2028.
        let officer = people.first { $0.title == "Police Officer" && $0.amount(in: 2028) != nil }
        #expect(abs((officer?.amount(in: 2028)?.lowerBound ?? 0) - 13_208.16) < 0.01)
    }
}

struct PurchasingPowerTests {

    @Test func bundledFileLoadsAndAddsUp() throws {
        let doc = try #require(PurchasingPowerDocument.bundled)
        let s = doc.summary
        #expect(s.ahead + s.even + s.behind == s.people)
        #expect(doc.wageFloor.hourly == 17.0)
        #expect(!doc.sameTitle.isEmpty)
        // Every person's 2026 point is their 2026 salary.
        #expect(doc.people.allSatisfy { $0.series.last?.salary == $0.salary })
    }
}

struct PeerTitlePayTests {

    @Test func bundledFileLoads() throws {
        let doc = try #require(PeerTitlePayDocument.bundled)
        #expect(doc.points["start"] == 2022)
        #expect(doc.points["current"] == 2026)
        #expect(doc.titles.count == doc.summary.titles)
        // Every title has Riverhead's 2026 figure and at least one neighbour.
        #expect(doc.titles.allSatisfy { $0.towns["Riverhead"]?.current != nil && $0.towns.count >= 2 })
    }

    @Test func quotesTheNeighboursRecords() throws {
        let doc = try #require(PeerTitlePayDocument.bundled)
        let board = try #require(doc.titles.first { $0.title == "Town Board member" })
        // Southampton 2026 Salary Charts: Town Council (4), $84,451.
        #expect(board.towns["Southampton"]?.current?.median == 84_451)
        // Southold 2021 Preliminary Budget: Members of the Town Board (4), $37,598.
        #expect(board.towns["Southold"]?.start?.year == 2021)
        #expect(board.towns["Southold"]?.start?.median == 37_598)
    }
}
