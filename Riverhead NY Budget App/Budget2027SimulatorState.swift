import Foundation
import Observation

@Observable
@MainActor
final class Budget2027SimulatorState {

    // MARK: - Scenario inputs

    var levyGrowthPercent: Double = Budget2027ScenarioModel.defaultLevyGrowthPercent
    var recurringRevenueAdds: Double = Budget2027ScenarioModel.defaultRecurringRevenueAddsExcludingLevy
    var otherRecurringPressure: Double = Budget2027ScenarioModel.defaultOtherRecurringPressure
    var recurringSavings: Double = Budget2027ScenarioModel.defaultRecurringSavings
    var automaticCOLAPercent: Double = Budget2027ScenarioModel.defaultAutomaticCOLAPercent
    var includeBuildingDepartmentInvestment: Bool = true
    var includeOnlinePlatformInvestment: Bool = true
    var includeTownClerkInvestment: Bool = true
    var additionalCodeEnforcementOfficers: Double = 2
    var additionalPoliceOfficers: Double = 2
    var includeElectedRaisePackage: Bool = false
    var includeCapitalFleetPurchase: Bool = true
    var activeStage: BudgetFlowStage = .overview
    var reserveTargetPercent: Double = 28.8
    var oneTimeDeployment: Double = 0
    var sampleAssessment: Double = 450_000

    // MARK: - Pure computed (no store dependency)

    var colaBreakout: Budget2027ScenarioModel.COLABreakout {
        Budget2027ScenarioModel.colaBreakout(percent: automaticCOLAPercent / 100)
    }

    var automaticPayrollPressure: Double { colaBreakout.totalAutomaticPressure }
    var modeledUnionPressure: Double { colaBreakout.unionPressure }
    var modeledNonContractCOLAPressure: Double { colaBreakout.nonContractPressure }

    var additionalRecurringInvestments: Double {
        var total = 0.0
        if includeBuildingDepartmentInvestment { total += Budget2027ScenarioModel.buildingDepartmentHeadcountInvestment }
        if includeOnlinePlatformInvestment     { total += Budget2027ScenarioModel.onlinePlatformUpdateCost }
        if includeTownClerkInvestment          { total += Budget2027ScenarioModel.deputyTownClerkCost }
        total += Double(Int(additionalCodeEnforcementOfficers)) * Budget2027ScenarioModel.codeEnforcementOfficerCost
        total += Double(Int(additionalPoliceOfficers)) * Budget2027ScenarioModel.policeOfficerCost
        return total
    }

    var electedRaisePackageCost: Double {
        includeElectedRaisePackage ? Budget2027ScenarioModel.electedRaisePackageCost : 0
    }

    var capitalFleetPurchaseCost: Double {
        includeCapitalFleetPurchase ? Budget2027ScenarioModel.plannedFleetPurchaseCost : 0
    }

    var totalRecurringUses: Double {
        automaticPayrollPressure + otherRecurringPressure + additionalRecurringInvestments + electedRaisePackageCost
    }

    var serviceInvestmentCount: Int {
        var count = 0
        if includeBuildingDepartmentInvestment { count += 1 }
        if includeOnlinePlatformInvestment     { count += 1 }
        if includeTownClerkInvestment          { count += 1 }
        count += Int(additionalCodeEnforcementOfficers)
        count += Int(additionalPoliceOfficers)
        return count
    }

    var activeStageSummaryTitle: String {
        switch activeStage {
        case .overview:  return "Start with the baseline"
        case .recurring: return "Build the recurring package"
        case .oneTime:   return "Handle capital and reserves separately"
        case .result:    return "Read the fiscal signal"
        }
    }

    var activeStageSummaryDetail: String {
        switch activeStage {
        case .overview:
            return "This step shows Riverhead's starting budget posture and the current FY27 package in plain English before any policy changes."
        case .recurring:
            return "This is where the real structural work happens: levy choices, recurring savings, recurring revenue, and recurring service commitments."
        case .oneTime:
            return "This step keeps one-time decisions honest by separating the fleet purchase and reserve deployment from the recurring operating test."
        case .result:
            return "This final step shows whether the scenario actually holds together and what warning signs remain."
        }
    }

    // MARK: - Preset application

    func applyRecommendedScenario() {
        levyGrowthPercent = Budget2027ScenarioModel.defaultLevyGrowthPercent
        recurringRevenueAdds = Budget2027ScenarioModel.defaultRecurringRevenueAddsExcludingLevy
        otherRecurringPressure = Budget2027ScenarioModel.defaultOtherRecurringPressure
        recurringSavings = Budget2027ScenarioModel.defaultRecurringSavings
        automaticCOLAPercent = Budget2027ScenarioModel.defaultAutomaticCOLAPercent
        includeBuildingDepartmentInvestment = true
        includeOnlinePlatformInvestment = true
        includeTownClerkInvestment = true
        additionalCodeEnforcementOfficers = 2
        additionalPoliceOfficers = 2
        includeElectedRaisePackage = false
        includeCapitalFleetPurchase = true
    }

    func applyScenarioPreset(
        _ preset: ScenarioPreset,
        currentReservePercent: Double,
        maxReserveTargetPercent: Double
    ) {
        switch preset {
        case .holdLine:
            levyGrowthPercent = 1.5
            recurringRevenueAdds = 40_000
            otherRecurringPressure = Budget2027PensionPressureModel.lowIncrease
            recurringSavings = 875_000
            automaticCOLAPercent = 2.0
            includeBuildingDepartmentInvestment = true
            includeOnlinePlatformInvestment = false
            includeTownClerkInvestment = false
            additionalCodeEnforcementOfficers = 1
            additionalPoliceOfficers = 1
            includeElectedRaisePackage = false
            includeCapitalFleetPurchase = true
            reserveTargetPercent = max(30.0, min(maxReserveTargetPercent, currentReservePercent))
            oneTimeDeployment = 0

        case .recommended:
            applyRecommendedScenario()
            reserveTargetPercent = 28.8
            oneTimeDeployment = 0

        case .serviceBuildout:
            levyGrowthPercent = 3.5
            recurringRevenueAdds = 250_000
            otherRecurringPressure = Budget2027PensionPressureModel.highIncrease
            recurringSavings = Budget2027ScenarioModel.defaultRecurringSavings
            automaticCOLAPercent = 3.0
            includeBuildingDepartmentInvestment = true
            includeOnlinePlatformInvestment = true
            includeTownClerkInvestment = true
            additionalCodeEnforcementOfficers = 3
            additionalPoliceOfficers = 3
            includeElectedRaisePackage = false
            includeCapitalFleetPurchase = true
            reserveTargetPercent = 25.0
            oneTimeDeployment = 0
        }
    }
}
