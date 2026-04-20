//
//  ContractImpactEngine.swift
//  Riverhead NY Budget App
//
//  Created by Bryan on 1/15/26.
//


//
//  ContractImpactEngine.swift
//  Riverhead NY Budget App
//
//  Contract Impact Estimator engine
//  Swift 6 • iOS 17+
//
//  IMPORTANT:
//  - This file must NOT redeclare LaborGroup / WageAction / GroupAssumptions / YearResult.
//  - Those types should exist exactly once in your target.
//

import Foundation

public struct ContractImpactEngine {

    /// Wage actions by group and year (year = effective year for the move priorYear -> year).
    public var wageActions: [LaborGroup: [Int: WageAction]]

    public init(wageActions: [LaborGroup: [Int: WageAction]] = ContractCatalog.defaultWageActions()) {
        self.wageActions = wageActions
    }

    /// Estimate total personnel cost year-by-year.
    ///
    /// - Parameters:
    ///   - groups: Assumptions per labor group (baseline payroll, FTE, loads, benefits).
    ///   - startYear: First year to include in results.
    ///   - endYear: Last year to include in results.
    ///   - baselineTotalBudget: Optional. If provided, the engine will compute total budget impact
    ///     assuming non-personnel cost stays constant at (baselineTotalBudget - baselinePersonnelCostInBaseYears).
    ///   - assumeNonPersonnelConstant: If false, total budget impact is not computed even if baselineTotalBudget is provided.
    public func estimate(
        groups: [GroupAssumptions],
        startYear: Int,
        endYear: Int,
        baselineTotalBudget: Double? = nil,
        assumeNonPersonnelConstant: Bool = true
    ) -> [YearResult] {

        guard startYear <= endYear else { return [] }
        guard !groups.isEmpty else { return [] }

        // Map assumptions by group (last one wins if duplicates)
        let byGroup = Dictionary(uniqueKeysWithValues: groups.map { ($0.group, $0) })

        // Compute baseline "personnel" using each group's own baseYear/basePayroll.
        // This is a planning approximation for deriving non-personnel when total budget is supplied.
        let baselinePersonnel: Double = groups.reduce(0.0) { partial, g in
            partial + totalGroupCost(for: g, basePayroll: g.basePayroll, targetYear: g.baseYear)
        }

        let nonPersonnelBase: Double? = {
            guard assumeNonPersonnelConstant, let budget = baselineTotalBudget else { return nil }
            return max(0, budget - baselinePersonnel)
        }()

        var results: [YearResult] = []
        var priorPersonnel: Double? = nil
        var priorBudget: Double? = nil

        for year in startYear...endYear {
            var groupTotals: [LaborGroup: Double] = [:]

            for (group, g) in byGroup {
                let basePayrollForYear = rollForwardBasePayroll(
                    baseYear: g.baseYear,
                    basePayroll: g.basePayroll,
                    fte: g.fte,
                    group: group,
                    targetYear: year,
                    fallbackGrowth: g.fallbackWageGrowth
                )

                let total = totalGroupCost(for: g, basePayroll: basePayrollForYear, targetYear: year)
                groupTotals[group] = total
            }

            let personnel = groupTotals.values.reduce(0, +)

            let yoyPersonnelDelta: Double?
            let yoyPersonnelPct: Double?
            if let prior = priorPersonnel {
                yoyPersonnelDelta = personnel - prior
                yoyPersonnelPct = prior > 0 ? (personnel / prior - 1.0) : nil
            } else {
                yoyPersonnelDelta = nil
                yoyPersonnelPct = nil
            }

            let budgetTotal: Double? = {
                guard let nonPersonnelBase else { return nil }
                return nonPersonnelBase + personnel
            }()

            let yoyBudgetDelta: Double?
            let yoyBudgetPct: Double?
            if let priorB = priorBudget, let currentB = budgetTotal {
                yoyBudgetDelta = currentB - priorB
                yoyBudgetPct = priorB > 0 ? (currentB / priorB - 1.0) : nil
            } else {
                yoyBudgetDelta = nil
                yoyBudgetPct = nil
            }

            results.append(
                YearResult(
                    year: year,
                    groupTotalCost: groupTotals,
                    totalPersonnelCost: personnel,
                    yoyPersonnelDelta: yoyPersonnelDelta,
                    yoyPersonnelPct: yoyPersonnelPct,
                    totalBudgetCost: budgetTotal,
                    yoyBudgetDelta: yoyBudgetDelta,
                    yoyBudgetPct: yoyBudgetPct
                )
            )

            priorPersonnel = personnel
            priorBudget = budgetTotal
        }

        return results
    }

    // MARK: - Payroll roll-forward (wage actions)

    private func rollForwardBasePayroll(
        baseYear: Int,
        basePayroll: Double,
        fte: Double,
        group: LaborGroup,
        targetYear: Int,
        fallbackGrowth: Double
    ) -> Double {

        if targetYear <= baseYear { return basePayroll }

        var current = basePayroll

        // Apply actions for each year step from baseYear+1 -> targetYear
        for y in (baseYear + 1)...targetYear {

            if let action = wageActions[group]?[y] {
                current = action.apply(toBasePayroll: current, fte: fte)
                continue
            }

            if fallbackGrowth > 0 {
                current *= (1.0 + fallbackGrowth)
                continue
            }

            // No action, no fallback: keep current unchanged (do nothing).
        }

        return current
    }

    // MARK: - Total group cost

    private func totalGroupCost(for g: GroupAssumptions, basePayroll: Double, targetYear: Int) -> Double {
        // Benefits inflation from the group’s baseYear to the targetYear
        let yearsFromBase = max(0, targetYear - g.baseYear)
        let benefitsInflator = pow(1.0 + g.benefitsInflationRate, Double(yearsFromBase))
        let benefits = (g.benefitsPerFTE * g.fte) * benefitsInflator

        // Percent loads on base payroll
        let percentLoads = basePayroll * (g.overtimeRate + g.otherCompRate)

        // Flat loads per FTE
        let flatLoads = g.otherCompFlatPerFTE * g.fte

        return basePayroll + percentLoads + flatLoads + benefits
    }
}
