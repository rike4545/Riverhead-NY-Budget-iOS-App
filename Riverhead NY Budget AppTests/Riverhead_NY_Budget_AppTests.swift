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
