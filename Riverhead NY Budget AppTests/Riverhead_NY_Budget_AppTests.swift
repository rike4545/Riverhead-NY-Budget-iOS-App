//
//  Riverhead_NY_Budget_AppTests.swift
//  Riverhead NY Budget AppTests
//

import Foundation
import Testing
@testable import Riverhead_NY_Budget_App

// MARK: - ContractImpactEngine

struct ContractImpactEngineTests {

    private let engine = ContractImpactEngine()

    /// The default engine is constructed with ContractCatalog.defaultWageActions(),
    /// so it carries Riverhead's real, executed union schedules — and the engine
    /// applies a contractual action in preference to fallbackWageGrowth, which it
    /// consults only for years no contract covers (ContractImpactEngine.swift:152).
    ///
    /// Tests below that are about the engine's own mechanics run against an empty
    /// catalog. Otherwise they are not testing fallback growth at all; they are
    /// accidentally asserting on the CSEA contract, and every raise the Town
    /// negotiates breaks them.
    private let bareEngine = ContractImpactEngine(wageActions: [:])

    private func singleGroup(
        payroll: Double = 1_000_000,
        fte: Double = 10,
        overtimeRate: Double = 0,
        benefitsPerFTE: Double = 0,
        benefitsInflationRate: Double = 0,
        fallbackGrowth: Double = 0
    ) -> GroupAssumptions {
        GroupAssumptions(
            group: .csea,
            baseYear: 2024,
            basePayroll: payroll,
            fte: fte,
            overtimeRate: overtimeRate,
            otherCompRate: 0,
            otherCompFlatPerFTE: 0,
            benefitsPerFTE: benefitsPerFTE,
            benefitsInflationRate: benefitsInflationRate,
            fallbackWageGrowth: fallbackGrowth
        )
    }

    @Test func estimateEmptyGroupsReturnsEmpty() {
        let results = engine.estimate(groups: [], startYear: 2024, endYear: 2026)
        #expect(results.isEmpty)
    }

    @Test func estimateInvertedYearRangeReturnsEmpty() {
        let g = singleGroup()
        let results = engine.estimate(groups: [g], startYear: 2026, endYear: 2024)
        #expect(results.isEmpty)
    }

    @Test func estimateSingleYearHasNoYoY() {
        let g = singleGroup(payroll: 500_000)
        let results = engine.estimate(groups: [g], startYear: 2024, endYear: 2024)
        #expect(results.count == 1)
        #expect(results[0].yoyPersonnelPct == nil)
        #expect(results[0].yoyPersonnelDelta == nil)
    }

    @Test func estimateNoGrowthHoldsConstant() {
        let g = singleGroup(payroll: 1_000_000, fallbackGrowth: 0)
        let results = bareEngine.estimate(groups: [g], startYear: 2024, endYear: 2027)
        #expect(results.count == 4)
        for r in results {
            #expect(abs(r.totalPersonnelCost - 1_000_000) < 1)
        }
    }

    /// The behaviour the Contract Cost Estimator actually ships, and the reason the
    /// tests above needed a bare engine: an executed contract governs, and the
    /// fallback is ignored for any year it covers. Figures are the CSEA CBA and the
    /// 2026-2029 MOA applied to $1,000,000 across 10 FTE.
    @Test func executedContractScheduleOverridesFallbackGrowth() {
        let g = singleGroup(payroll: 1_000_000, fallbackGrowth: 0.10)
        let results = engine.estimate(groups: [g], startYear: 2024, endYear: 2027)
        #expect(results.count == 4)
        #expect(abs(results[0].totalPersonnelCost - 1_000_000) < 1)   // base year
        #expect(abs(results[1].totalPersonnelCost - 1_020_000) < 1)   // 2025 +2.0%
        #expect(abs(results[2].totalPersonnelCost - 1_055_400) < 1)   // 2026 +2.0% + $1,500/FTE
        #expect(abs(results[3].totalPersonnelCost - 1_091_785) < 1)   // 2027 +2.5% + $1,000/FTE
    }

    @Test func estimateFallbackGrowthCompounds() {
        let g = singleGroup(payroll: 1_000_000, fallbackGrowth: 0.10)
        let results = bareEngine.estimate(groups: [g], startYear: 2024, endYear: 2026)
        // 2024: base = 1_000_000
        // 2025: 1_000_000 * 1.10 = 1_100_000
        // 2026: 1_100_000 * 1.10 = 1_210_000
        #expect(abs(results[0].totalPersonnelCost - 1_000_000) < 1)
        #expect(abs(results[1].totalPersonnelCost - 1_100_000) < 1)
        #expect(abs(results[2].totalPersonnelCost - 1_210_000) < 1)
    }

    @Test func estimateOvertimeRateAddsToBase() {
        let g = singleGroup(payroll: 1_000_000, overtimeRate: 0.10)
        let results = engine.estimate(groups: [g], startYear: 2024, endYear: 2024)
        // payroll + 10% OT = 1_100_000
        #expect(abs(results[0].totalPersonnelCost - 1_100_000) < 1)
    }

    @Test func estimateBenefitsInflateByYear() {
        let g = singleGroup(payroll: 0, fte: 10, benefitsPerFTE: 10_000, benefitsInflationRate: 0.06)
        let results = bareEngine.estimate(groups: [g], startYear: 2024, endYear: 2025)
        // 2024 (base year): 10 * 10_000 * 1.0 = 100_000
        // 2025 (1 year out): 100_000 * 1.06 = 106_000
        #expect(abs(results[0].totalPersonnelCost - 100_000) < 1)
        #expect(abs(results[1].totalPersonnelCost - 106_000) < 1)
    }

    @Test func estimateYoYDeltaIsCorrect() {
        let g = singleGroup(payroll: 1_000_000, fallbackGrowth: 0.05)
        let results = bareEngine.estimate(groups: [g], startYear: 2024, endYear: 2025)
        let delta = results[1].yoyPersonnelDelta ?? 0
        #expect(abs(delta - 50_000) < 1)
        let pct = results[1].yoyPersonnelPct ?? 0
        #expect(abs(pct - 0.05) < 0.001)
    }

    @Test func estimateZeroPayrollProducesZeroCost() {
        let g = singleGroup(payroll: 0, fte: 5)
        let results = bareEngine.estimate(groups: [g], startYear: 2024, endYear: 2026)
        for r in results {
            #expect(r.totalPersonnelCost == 0)
        }
    }

    @Test func estimateMultipleGroupsSumCorrectly() {
        let pba = GroupAssumptions(group: .pba, baseYear: 2024, basePayroll: 500_000, fte: 5,
                                   overtimeRate: 0, otherCompRate: 0, otherCompFlatPerFTE: 0,
                                   benefitsPerFTE: 0, benefitsInflationRate: 0, fallbackWageGrowth: 0)
        let csea = GroupAssumptions(group: .csea, baseYear: 2024, basePayroll: 300_000, fte: 3,
                                    overtimeRate: 0, otherCompRate: 0, otherCompFlatPerFTE: 0,
                                    benefitsPerFTE: 0, benefitsInflationRate: 0, fallbackWageGrowth: 0)
        let results = engine.estimate(groups: [pba, csea], startYear: 2024, endYear: 2024)
        #expect(abs(results[0].totalPersonnelCost - 800_000) < 1)
    }

    @Test func estimateTotalBudgetIncludesNonPersonnel() {
        let g = singleGroup(payroll: 1_000_000)
        let results = engine.estimate(groups: [g], startYear: 2024, endYear: 2024,
                                      baselineTotalBudget: 5_000_000)
        // nonPersonnelBase = 5_000_000 - 1_000_000 = 4_000_000
        // totalBudget = 4_000_000 + 1_000_000 = 5_000_000
        #expect(results[0].totalBudgetCost != nil)
        #expect(abs((results[0].totalBudgetCost ?? 0) - 5_000_000) < 1)
    }

    @Test func estimateWageActionPercentApplied() {
        var engineWithAction = ContractImpactEngine()
        engineWithAction.wageActions[.pba] = [2025: .percent(0.03)]
        let g = GroupAssumptions(group: .pba, baseYear: 2024, basePayroll: 1_000_000, fte: 10,
                                  overtimeRate: 0, otherCompRate: 0, otherCompFlatPerFTE: 0,
                                  benefitsPerFTE: 0, benefitsInflationRate: 0, fallbackWageGrowth: 0)
        let results = engineWithAction.estimate(groups: [g], startYear: 2024, endYear: 2025)
        #expect(abs(results[1].totalPersonnelCost - 1_030_000) < 1)
    }

    @Test func sanitizedCleansNegativeValues() {
        var g = singleGroup(payroll: -50_000, fte: -5, overtimeRate: -0.1)
        g = g.sanitized()
        #expect(g.basePayroll == 0)
        #expect(g.fte == 0)
        #expect(g.overtimeRate == 0)
    }

    @Test func sanitizedCleansNaN() {
        var g = singleGroup()
        g.basePayroll = Double.nan
        g.benefitsInflationRate = Double.nan
        g = g.sanitized()
        #expect(g.basePayroll == 0)
        #expect(g.benefitsInflationRate == 0)
    }
}

// MARK: - EarlyRetirementIncentive math

struct ERICalculationTests {

    @Test func breakEvenInfiniteWhenNoSavings() {
        // replacementRate 1.0, replacementSalaryFactor 1.0 → no gross savings
        let participants = 10.0
        let salary = 80_000.0
        let benefitsRate = 0.40
        let annualCurrentCost = participants * salary * (1 + benefitsRate)
        let replacementCost = participants * 1.0 * (salary * 1.0) * (1 + benefitsRate)
        let grossSavings = max(annualCurrentCost - replacementCost, 0)
        #expect(grossSavings == 0)
    }

    @Test func breakEvenCalculatesCorrectly() {
        let participants = 10.0
        let salary = 100_000.0
        let currentBenefits = 0.40
        let replacementRate = 0.75
        let replacementSalaryFactor = 0.72
        let replacementBenefits = 0.34
        let incentive = 30_000.0
        let leavePayout = 18_000.0

        let currentCost = participants * salary * (1 + currentBenefits)
        let replacementCount = participants * replacementRate
        let replacementSalary = salary * replacementSalaryFactor
        let replacementCost = replacementCount * replacementSalary * (1 + replacementBenefits)
        let grossSavings = max(currentCost - replacementCost, 0)
        let upfrontCost = participants * (incentive + leavePayout)
        let breakEven = upfrontCost / grossSavings

        #expect(grossSavings > 0)
        #expect(breakEven > 0)
        #expect(breakEven.isFinite)
        // With these inputs break-even should be well under 5 years
        #expect(breakEven < 5)
    }

    @Test func netSavingsNegativeBeforeBreakEven() {
        let grossSavings = 200_000.0
        let upfrontCost = 480_000.0
        let netAt1Year = (grossSavings * 1) - upfrontCost
        #expect(netAt1Year < 0)
    }

    @Test func netSavingsPositiveAfterBreakEven() {
        let grossSavings = 200_000.0
        let upfrontCost = 400_000.0
        let breakEven = upfrontCost / grossSavings  // 2.0 years
        let netAt3Years = (grossSavings * 3) - upfrontCost
        #expect(breakEven == 2.0)
        #expect(netAt3Years > 0)
    }
}

// MARK: - WageAction

struct WageActionTests {

    @Test func percentActionScalesPayroll() {
        let action = WageAction.percent(0.05)
        let result = action.apply(toBasePayroll: 1_000_000, fte: 10)
        #expect(abs(result - 1_050_000) < 0.01)
    }

    @Test func flatActionAddsPerFTE() {
        let action = WageAction.flat(1_000)
        let result = action.apply(toBasePayroll: 500_000, fte: 10)
        #expect(abs(result - 510_000) < 0.01)
    }

    @Test func percentPlusFlatCombinesCorrectly() {
        let action = WageAction.percentPlusFlat(0.02, flatPerFTE: 500)
        let result = action.apply(toBasePayroll: 1_000_000, fte: 10)
        // 1_000_000 * 1.02 + 500 * 10 = 1_020_000 + 5_000 = 1_025_000
        #expect(abs(result - 1_025_000) < 0.01)
    }

    @Test func negativePayrollClampedToZero() {
        let action = WageAction.percent(0.05)
        let result = action.apply(toBasePayroll: -10_000, fte: 5)
        // max(0, -10_000) * 1.05 = 0
        #expect(result == 0)
    }

    @Test func zeroFTEProducesZeroFlatLoads() {
        let action = WageAction.flat(5_000)
        let result = action.apply(toBasePayroll: 0, fte: 0)
        #expect(result == 0)
    }
}


// MARK: - Program budget (bundled shared-data contract)

/// programs.json is generated by the web app's ETL and synced into this bundle,
/// so it changes without anyone touching Swift. It is also what
/// NativeProgramBudgetView falls back to when the network copy is unreachable,
/// which makes it the offline path for the whole screen. These tests are the
/// tripwire for both: that it still decodes, still reconciles, and still
/// satisfies the identity rules the SwiftUI lists depend on.
struct ProgramBudgetContractTests {

    private var document: ProgramBudgetParityDocument? {
        ProgramBudgetParityClient.bundled()
    }

    @Test func bundledExtractDecodes() {
        #expect(document != nil)
    }

    @Test func schemaVersionIsTheOneThisAppWasWrittenAgainst() throws {
        #expect(try #require(document).schemaVersion == 1)
    }

    @Test func regroupingReconcilesToAdoptedAppropriations() throws {
        let reconciliation = try #require(document).reconciliation
        #expect(abs(reconciliation.variance) < 0.5)
        #expect(abs(reconciliation.computed - reconciliation.appropriations) < 0.5)
    }

    /// grandTotal is programs + debt + contingency, and transfers sit outside it
    /// by design. If that stops holding, the headline numbers are wrong.
    @Test func grandTotalIsProgramsPlusDebtPlusContingency() throws {
        let t = try #require(document).totals
        #expect(abs(t.grandTotal - (t.fullCost + t.debtService + t.contingency)) < 0.5)
        #expect(abs((t.grandTotal + t.interfundTransfers) - t.appropriations) < 0.5)
    }

    @Test func totalsAreTheSumOfTheProgramsAboveThem() throws {
        let document = try #require(document)
        #expect(abs(document.programs.reduce(0) { $0 + $1.fullCost } - document.totals.fullCost) < 0.5)
        #expect(abs(document.programs.reduce(0) { $0 + $1.earned } - document.totals.earned) < 0.5)
        #expect(abs(document.programs.reduce(0) { $0 + $1.net } - document.totals.net) < 0.5)
        #expect(document.programs.reduce(0) { $0 + $1.staff } == document.totals.staff)
    }

    @Test func eachProgramIsDirectPlusBenefits() throws {
        for p in try #require(document).programs {
            #expect(abs(p.fullCost - (p.direct + p.benefits)) < 0.5, "\(p.name) full cost")
            #expect(abs(p.net - (p.fullCost - p.earned)) < 0.5, "\(p.name) net")
        }
    }

    /// ForEach keys programs on `key` and departments on fund+code+name. A
    /// collision makes a real row unreachable on screen.
    @Test func programAndDepartmentIdentifiersAreUnique() throws {
        let document = try #require(document)
        let keys = document.programs.map(\.key)
        #expect(Set(keys).count == keys.count)
        for p in document.programs {
            let ids = p.departments.map(\.id)
            #expect(Set(ids).count == ids.count, "\(p.name) has a duplicate department id")
        }
    }

    /// The reason Revenue is not Identifiable: Riverhead runs two sewer districts
    /// and both file a line called "Sewer Rents". Keyed on the name, ForEach
    /// renders one and silently drops the other — so this asserts the data really
    /// does repeat a name, and that nothing has quietly started deduplicating it.
    @Test func revenueNamesRepeatAndAreNotUsedAsIdentity() throws {
        let document = try #require(document)
        let repeated = document.programs.contains { program in
            let names = program.topRevenues.map(\.name)
            return Set(names).count != names.count
        }
        #expect(repeated, "no program repeats a revenue name — if the ETL changed, re-check the position-keyed ForEach")
    }

    @Test func methodNoteTitlesAreUnique() throws {
        let titles = try #require(document).method.map(\.title)
        #expect(!titles.isEmpty)
        #expect(Set(titles).count == titles.count)
    }

    /// An unmapped payroll department means a headcount belongs to no program,
    /// so the staff totals on screen understate the workforce.
    @Test func everyPayrollDepartmentIsMappedToAProgram() throws {
        #expect(try #require(document).diagnostics.unmappedPayrollDepartments.isEmpty)
    }

    @Test func perResidentAndPerHouseholdDivideByTheCensusCounts() throws {
        let document = try #require(document)
        #expect(document.census.population > 0 && document.census.households > 0)
        #expect(abs(document.perResident.programs - document.totals.net / document.census.population) < 0.01)
        #expect(abs(document.perHousehold.programs - document.totals.net / document.census.households) < 0.01)
    }
}

// MARK: - Program budget: the fields the web page renders and this app did not

/// The published programs.json carries a five-year series, a set-aside total,
/// and a separate attribution for where the resident count comes from. The
/// native screen was decoding none of them, so four years of published history
/// and two source lines never reached anyone.
///
/// All three are optional on purpose: the copy bundled for offline use predates
/// them. That is the case these tests exist to pin, because making them
/// required would still pass a live-data check while silently killing the
/// offline path — the bundled decode would return nil and the screen would fall
/// back to the web view with nothing logged.
struct ProgramBudgetYearSeriesTests {

    /// A year entry carries less than a top-level program entry: no narrative,
    /// no departments, no revenues, and no contingency line in its totals.
    /// Decoding one as the top-level shape would throw on every year.
    private static let fixture = """
    {
      "schemaVersion": 1,
      "source": { "title": "T", "detail": "D", "url": "https://example.invalid/" },
      "payrollYear": 2025,
      "census": {
        "dataset": "ACS 2023 5-year",
        "source": { "title": "Census ACS", "url": "https://example.invalid/acs", "detail": "Five-year estimates." },
        "population": 36394,
        "populationSource": "Census SUB-EST2025, July 1, 2025",
        "households": 13678,
        "householdsMoe": 571,
        "medianHouseholdIncome": 93595
      },
      "programs": [],
      "totals": {
        "direct": 1, "benefits": 1, "fullCost": 2, "earned": 1, "net": 1, "staff": 3,
        "debtService": 1, "setAside": 826751, "contingency": 1, "interfundTransfers": 1,
        "townwideRevenue": 1, "grandTotal": 1, "appropriations": 1
      },
      "perResident": { "programs": 1, "debtService": 1, "everything": 1 },
      "perHousehold": { "programs": 1, "debtService": 1, "everything": 1, "shareOfMedianIncome": 1 },
      "reconciliation": { "computed": 1, "appropriations": 1, "variance": 0 },
      "method": [],
      "notCovered": { "title": "N", "body": "B" },
      "years": [
        {
          "year": 2023, "stage": "adopted", "label": "2023", "staffYear": 2023,
          "sources": {
            "supplement": { "title": "2024 Supplement", "url": "https://example.invalid/s" },
            "summary": { "title": "2023 Adopted", "url": "https://example.invalid/a" }
          },
          "totals": {
            "direct": 62763679, "benefits": 21513500, "fullCost": 84277179, "earned": 19672789,
            "net": 64604390, "staff": 566, "debtService": 8728100, "setAside": 3148021,
            "interfundTransfers": 7749400, "townwideRevenue": 84229911,
            "grandTotal": 96153300, "appropriations": 103902700
          },
          "perResident": { "programs": 1775.13, "debtService": 239.82, "everything": 2101.45 },
          "perHousehold": { "programs": 4723.23, "debtService": 638.11, "everything": 5591.49, "shareOfMedianIncome": 5.97 },
          "reconciliation": { "computed": 103902700, "appropriations": 103902700, "variance": 0 },
          "programs": [
            { "key": "3", "name": "Public Safety", "direct": 19683400, "benefits": 14082215.84,
              "fullCost": 33765615.84, "earned": 1914200, "net": 31851415.84, "recoveryPct": 5.66,
              "netPerResident": 875.18, "netPerHousehold": 2328.66, "staff": 176 }
          ]
        },
        {
          "year": 2027, "stage": "tentative", "label": "2027 proposed", "staffYear": 2026,
          "sources": {
            "supplement": { "title": "2027 Supplement", "url": "https://example.invalid/s27" },
            "summary": { "title": "2027 Tentative", "url": "https://example.invalid/t27" }
          },
          "totals": {
            "direct": 1, "benefits": 1, "fullCost": 2, "earned": 1, "net": 1, "staff": 1,
            "debtService": 1, "setAside": 1, "interfundTransfers": 1,
            "townwideRevenue": 1, "grandTotal": 1, "appropriations": 1
          },
          "perResident": { "programs": 1, "debtService": 1, "everything": 1 },
          "perHousehold": { "programs": 1, "debtService": 1, "everything": 1, "shareOfMedianIncome": 1 },
          "reconciliation": { "computed": 1, "appropriations": 1, "variance": 0 },
          "programs": []
        }
      ],
      "diagnostics": { "unmappedPayrollDepartments": [] }
    }
    """

    private func decoded() throws -> ProgramBudgetParityDocument {
        try JSONDecoder().decode(
            ProgramBudgetParityDocument.self,
            from: Data(Self.fixture.utf8)
        )
    }

    @Test func theYearSeriesDecodes() throws {
        let years = try #require(decoded().years)
        #expect(years.count == 2)
    }

    @Test func aTentativeYearIsMarkedProposed() throws {
        let years = try #require(decoded().years)
        let tentativeMatch = years.first { $0.year == 2027 }
        let adoptedMatch = years.first { $0.year == 2023 }
        let tentative = try #require(tentativeMatch)
        let adopted = try #require(adoptedMatch)
        #expect(tentative.isProposed)
        #expect(adopted.isProposed == false)
    }

    /// The per-year totals carry a set-aside and no contingency. If the two
    /// totals shapes are ever merged back together, this fails.
    @Test func perYearTotalsCarryTheSetAside() throws {
        let years = try #require(decoded().years)
        let match = years.first { $0.year == 2023 }
        let first = try #require(match)
        #expect(first.totals.setAside == 3148021)
        #expect(first.totals.staff == 566)
    }

    @Test func documentTotalsCarryTheSetAside() throws {
        let totals = try decoded().totals
        #expect(totals.setAside == 826751)
    }

    @Test func censusCarriesBothAttributions() throws {
        let census = try decoded().census
        #expect(census.source.title == "Census ACS")
        #expect(census.populationSource == "Census SUB-EST2025, July 1, 2025")
    }

    /// Every year's label should be non-empty, since it is what the screen
    /// shows as the row heading. Hoisted to a local because `#expect`
    /// decomposes its outermost call and would strip `allSatisfy`'s
    /// non-throwing guarantee.
    @Test func everyYearHasALabel() throws {
        let years = try #require(decoded().years)
        let allLabelled = years.allSatisfy { !$0.label.isEmpty }
        #expect(allLabelled)
    }

    /// The regression that matters most: the bundled copy predates all three
    /// fields, so it must still decode, with the new properties simply absent.
    @Test func theBundledCopyStillDecodesWithoutTheNewFields() throws {
        let bundled = try #require(ProgramBudgetParityClient.bundled())
        #expect(bundled.years == nil)
        #expect(bundled.totals.setAside == nil)
        #expect(bundled.census.populationSource == nil)
        #expect(bundled.census.source.title.isEmpty == false)
    }
}
