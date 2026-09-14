//
//  Riverhead_NY_Budget_AppTests.swift
//  Riverhead NY Budget AppTests
//

import Testing
@testable import Riverhead_NY_Budget_App

// MARK: - ContractImpactEngine

struct ContractImpactEngineTests {

    private let engine = ContractImpactEngine()

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
        let results = engine.estimate(groups: [g], startYear: 2024, endYear: 2027)
        #expect(results.count == 4)
        for r in results {
            #expect(abs(r.totalPersonnelCost - 1_000_000) < 1)
        }
    }

    @Test func estimateFallbackGrowthCompounds() {
        let g = singleGroup(payroll: 1_000_000, fallbackGrowth: 0.10)
        let results = engine.estimate(groups: [g], startYear: 2024, endYear: 2026)
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
        let results = engine.estimate(groups: [g], startYear: 2024, endYear: 2025)
        // 2024 (base year): 10 * 10_000 * 1.0 = 100_000
        // 2025 (1 year out): 100_000 * 1.06 = 106_000
        #expect(abs(results[0].totalPersonnelCost - 100_000) < 1)
        #expect(abs(results[1].totalPersonnelCost - 106_000) < 1)
    }

    @Test func estimateYoYDeltaIsCorrect() {
        let g = singleGroup(payroll: 1_000_000, fallbackGrowth: 0.05)
        let results = engine.estimate(groups: [g], startYear: 2024, endYear: 2025)
        let delta = results[1].yoyPersonnelDelta ?? 0
        #expect(abs(delta - 50_000) < 1)
        let pct = results[1].yoyPersonnelPct ?? 0
        #expect(abs(pct - 0.05) < 0.001)
    }

    @Test func estimateZeroPayrollProducesZeroCost() {
        let g = singleGroup(payroll: 0, fte: 5)
        let results = engine.estimate(groups: [g], startYear: 2024, endYear: 2026)
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
/// so it changes without anyone touching Swift. These tests are the tripwire for
/// that: they check the file still decodes, still reconciles, and still satisfies
/// the identity rules the SwiftUI lists depend on.
struct ProgramBudgetDataTests {

    /// Hosted tests read from the app bundle, but fall back to whichever bundle
    /// actually carries the resource so the suite does not depend on hosting.
    private var budget: ProgramBudget? {
        ProgramBudgetData.current
            ?? Bundle.allBundles.compactMap(ProgramBudgetData.load(from:)).first
    }

    @Test func bundledExtractDecodes() {
        #expect(budget != nil)
    }

    @Test func schemaVersionIsTheOneThisAppWasWrittenAgainst() throws {
        let budget = try #require(budget)
        #expect(budget.schemaVersion == ProgramBudgetData.supportedSchemaVersion)
    }

    @Test func regroupingReconcilesToAdoptedAppropriations() throws {
        let budget = try #require(budget)
        #expect(budget.reconciliation.balances)
        #expect(abs(budget.reconciliation.computed - budget.reconciliation.appropriations) < 0.5)
    }

    /// grandTotal is programs + debt + contingency, and transfers sit outside it
    /// by design. If that ever stops holding, the headline numbers are wrong.
    @Test func grandTotalIsProgramsPlusDebtPlusContingency() throws {
        let t = try #require(budget).totals
        #expect(abs(t.grandTotal - (t.fullCost + t.debtService + t.contingency)) < 0.5)
        #expect(abs((t.grandTotal + t.interfundTransfers) - t.appropriations) < 0.5)
    }

    @Test func totalsAreTheSumOfTheProgramsAboveThem() throws {
        let budget = try #require(budget)
        let fullCost = budget.programs.reduce(0) { $0 + $1.fullCost }
        let earned = budget.programs.reduce(0) { $0 + $1.earned }
        let net = budget.programs.reduce(0) { $0 + $1.net }
        let staff = budget.programs.reduce(0) { $0 + $1.staff }
        #expect(abs(fullCost - budget.totals.fullCost) < 0.5)
        #expect(abs(earned - budget.totals.earned) < 0.5)
        #expect(abs(net - budget.totals.net) < 0.5)
        #expect(staff == budget.totals.staff)
    }

    @Test func eachProgramIsDirectPlusBenefits() throws {
        for p in try #require(budget).programs {
            #expect(abs(p.fullCost - (p.direct + p.benefits)) < 0.5, "\(p.name) full cost")
            #expect(abs(p.net - (p.fullCost - p.earned)) < 0.5, "\(p.name) net")
        }
    }

    /// Every program key maps to a colour and a row. A duplicate would make one
    /// of them unreachable in the list.
    @Test func programKeysAreUnique() throws {
        let keys = try #require(budget).programs.map(\.key)
        #expect(Set(keys).count == keys.count)
    }

    /// ForEach over departments is keyed on fund+code. A collision inside one
    /// program silently drops a real department from the screen.
    @Test func departmentIdentifiersAreUniqueWithinEachProgram() throws {
        for p in try #require(budget).programs {
            let ids = p.departments.map(\.id)
            #expect(Set(ids).count == ids.count, "\(p.name) has a duplicate department id")
        }
    }

    @Test func methodNoteTitlesAreUnique() throws {
        let titles = try #require(budget).method.map(\.title)
        #expect(Set(titles).count == titles.count)
        #expect(!titles.isEmpty)
    }

    /// An unmapped payroll department means a headcount belongs to no program,
    /// so the staff totals on screen understate the workforce.
    @Test func everyPayrollDepartmentIsMappedToAProgram() throws {
        #expect(try #require(budget).diagnostics.unmappedPayrollDepartments.isEmpty)
    }

    @Test func perResidentAndPerHouseholdDivideByTheCensusCounts() throws {
        let budget = try #require(budget)
        let population = Double(budget.census.population)
        let households = Double(budget.census.households)
        #expect(population > 0 && households > 0)
        #expect(abs(budget.perResident.programs - budget.totals.net / population) < 0.01)
        #expect(abs(budget.perHousehold.programs - budget.totals.net / households) < 0.01)
    }
}

// MARK: - Program budget formatting

struct ProgramBudgetFormatTests {

    @Test func tensOfMillionsGetOneDecimal() {
        #expect(ProgramBudgetFormat.compactUSD(43_538_559) == "$43.5M")
    }

    @Test func singleMillionsGetTwoDecimals() {
        #expect(ProgramBudgetFormat.compactUSD(2_168_743) == "$2.17M")
    }

    /// Health's benefit share is $1,958. Formatting everything as millions
    /// rendered that as "$0.00M", which reads as a bug rather than a small
    /// number — so small values stay in plain dollars.
    @Test func smallRealNumbersAreNotRenderedAsZeroMillions() {
        let formatted = ProgramBudgetFormat.compactUSD(1_958)
        #expect(!formatted.contains("M"))
        #expect(!formatted.contains("K"))
        #expect(formatted.contains("1"))
    }

    @Test func thousandsStepDownToK() {
        #expect(ProgramBudgetFormat.compactUSD(15_000) == "$15K")
    }

    @Test func percentDefaultsToWholeNumbers() {
        #expect(ProgramBudgetFormat.percent(5.813_697) == "6%")
        #expect(ProgramBudgetFormat.percent(7.118_849, digits: 1) == "7.1%")
    }

    /// Text(_:) would group an interpolated Int, turning 2025 into "2,025".
    @Test func yearsReachTextAsPlainStrings() {
        #expect(ProgramBudgetFormat.year(2025) == "2025")
    }
}
