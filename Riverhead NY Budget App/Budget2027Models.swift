import SwiftUI

// MARK: - Flow enums

enum ScenarioPreset: String, CaseIterable, Identifiable {
    case holdLine
    case recommended
    case serviceBuildout

    var id: String { rawValue }

    var title: String {
        switch self {
        case .holdLine: return "Hold line"
        case .recommended: return "Best plan"
        case .serviceBuildout: return "Service buildout"
        }
    }

    var detail: String {
        switch self {
        case .holdLine: return "Lower levy, lower expansion, tighter reserve use."
        case .recommended: return "Best-practice recurring package with service investments protected."
        case .serviceBuildout: return "Carries more staffing and pressure openly."
        }
    }
}

enum BudgetFlowStage: String, CaseIterable, Identifiable {
    case overview
    case recurring
    case oneTime
    case result

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "1. Starting point"
        case .recurring: return "2. Recurring plan"
        case .oneTime: return "3. Capital & reserves"
        case .result: return "4. Read the result"
        }
    }

    var shortTitle: String {
        switch self {
        case .overview: return "Start"
        case .recurring: return "Recurring"
        case .oneTime: return "Capital"
        case .result: return "Result"
        }
    }

    var detail: String {
        switch self {
        case .overview: return "See the baseline and the current FY27 package before changing anything."
        case .recurring: return "Adjust taxes, savings, labor growth, and service investments."
        case .oneTime: return "Test the fleet purchase, reserve target, and any one-time support."
        case .result: return "Read whether the package is structurally balanced and what it means."
        }
    }

    var systemImage: String {
        switch self {
        case .overview: return "list.clipboard.fill"
        case .recurring: return "slider.horizontal.3"
        case .oneTime: return "car.side.fill"
        case .result: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Status types

enum BudgetSimulationStatus {
    case balanced
    case tight
    case gap

    var title: String {
        switch self {
        case .balanced: return "Recurring balance"
        case .tight: return "Tight scenario"
        case .gap: return "Structural gap"
        }
    }

    var message: String {
        switch self {
        case .balanced: return "Recurring revenues and savings currently cover recurring uses."
        case .tight: return "The scenario is close, but still vulnerable to slippage or underbudgeted pressure."
        case .gap: return "Recurring uses are still outrunning recurring money."
        }
    }

    var icon: String {
        switch self {
        case .balanced: return "checkmark.seal.fill"
        case .tight: return "exclamationmark.circle.fill"
        case .gap: return "xmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .balanced: return .green
        case .tight: return .orange
        case .gap: return .red
        }
    }
}

enum FiscalConditionStatus {
    case stable
    case watch
    case warning

    var title: String {
        switch self {
        case .stable: return "Stable"
        case .watch: return "Watch"
        case .warning: return "Warning"
        }
    }

    var detail: String {
        switch self {
        case .stable:
            return "The current 2027 settings read as structurally supportable under the app's scenario assumptions."
        case .watch:
            return "The package is workable, but one or more warning indicators suggest Riverhead would need close monthly monitoring."
        case .warning:
            return "The scenario still presents a clear fiscal warning signal and likely needs a stronger recurring correction package."
        }
    }

    var icon: String {
        switch self {
        case .stable: return "checkmark.shield.fill"
        case .watch: return "exclamationmark.triangle.fill"
        case .warning: return "xmark.shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .stable: return .green
        case .watch: return .orange
        case .warning: return .red
        }
    }
}

enum DistrictSnapshotStatus {
    case stable
    case watch
    case warning

    var title: String {
        switch self {
        case .stable: return "Stable"
        case .watch: return "Watch"
        case .warning: return "Reserve watch"
        }
    }

    var color: Color {
        switch self {
        case .stable: return .green
        case .watch: return .orange
        case .warning: return .red
        }
    }
}

// MARK: - Display types

struct FiscalConditionIndicator: Identifiable {
    let id = UUID()
    let title: String
    let status: FiscalConditionStatus
    let detail: String
}

struct DistrictSnapshot: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let appropriations: Double?
    let assignedPressure: Double
    let assignedSupport: Double
    let sharedGap: Double
    let status: DistrictSnapshotStatus
    let detail: String
}

struct BudgetShowcaseSection: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let tint: Color
    let rows: [BudgetShowcaseRow]
}

struct BudgetShowcaseRow: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let amount: Double
    let direction: BudgetShowcaseDirection

    var displayAmount: String {
        if direction == .guardrail && amount == 0 {
            return "Off"
        }
        if direction == .guardrail && amount > 0 && title.contains("Reserve target") {
            return amount.formatted(.currency(code: "USD"))
        }
        let prefix: String = {
            switch direction {
            case .offset:
                return "+"
            case .cost, .investment:
                return "-"
            case .guardrail:
                return amount > 0 ? "-" : ""
            }
        }()
        return "\(prefix)\(amount.formatted(.currency(code: "USD")))"
    }
}

enum BudgetShowcaseDirection {
    case cost
    case offset
    case investment
    case guardrail

    var icon: String {
        switch self {
        case .cost:
            return "arrow.up.circle.fill"
        case .offset:
            return "arrow.down.circle.fill"
        case .investment:
            return "hammer.fill"
        case .guardrail:
            return "shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .cost:
            return .orange
        case .offset:
            return .green
        case .investment:
            return RiverheadTheme.brandSky
        case .guardrail:
            return RiverheadTheme.gold
        }
    }
}

struct FY27ChangeLine: Identifiable {
    let id = UUID()
    let title: String
    let valueText: String
    let detail: String
}

struct FY27ChangeGroup: Identifiable {
    let title: String
    let subtitle: String
    let lines: [FY27ChangeLine]

    var id: String { title }
}

// MARK: - Scenario model data

enum Budget2027ScenarioModel {
    static let defaultAutomaticCOLAPercent = 2.5
    static let defaultLevyGrowthPercent = 2.0
    static let defaultOtherRecurringPressure = Budget2027PensionPressureModel.midpointIncrease
    static let defaultRecurringSavings = 806_431.97
    static let defaultRecurringRevenueAddsExcludingLevy = 61_500.00
    static let illustrativeCurrentLevyBase = 48_639_479.00
    static let taxCapLevelLevyYield = illustrativeCurrentLevyBase * 0.02
    static let pensionPressureAboveTwoPercentLevy = Budget2027PensionPressureModel.midpointIncrease - taxCapLevelLevyYield

    static let modeledPBAIncreaseAtDefaultCOLA = 354_689.61
    static let modeledSOAIncreaseAtDefaultCOLA = 68_773.45
    static let modeledCSEAIncrease = 484_395.46
    static let modeledNonContractIncreaseAtDefaultCOLA = 28_868.58

    static let pbaBasePayroll = modeledPBAIncreaseAtDefaultCOLA / (defaultAutomaticCOLAPercent / 100)
    static let soaBasePayroll = modeledSOAIncreaseAtDefaultCOLA / (defaultAutomaticCOLAPercent / 100)
    static let nonContractBasePayroll = modeledNonContractIncreaseAtDefaultCOLA / (defaultAutomaticCOLAPercent / 100)

    static let buildingDepartmentHeadcountInvestment = 180_000.00
    static let onlinePlatformUpdateCost = 85_000.00
    static let codeEnforcementOfficerCost = 70_249.89
    static let deputyTownClerkCost = 58_661.49
    static let policeOfficerCost = 72_066.67
    static let electedRaisePackageCost = 24_688.00
    static let plannedFleetPurchaseCost = 336_000.00

    struct COLABreakout {
        let pbaPressure: Double
        let soaPressure: Double
        let cseaPressure: Double
        let nonContractPressure: Double

        var unionPressure: Double {
            pbaPressure + soaPressure + cseaPressure
        }

        var totalAutomaticPressure: Double {
            unionPressure + nonContractPressure
        }
    }

    static func colaBreakout(percent: Double) -> COLABreakout {
        let safePercent = max(percent, 0)
        return COLABreakout(
            pbaPressure: pbaBasePayroll * safePercent,
            soaPressure: soaBasePayroll * safePercent,
            cseaPressure: modeledCSEAIncrease,
            nonContractPressure: nonContractBasePayroll * safePercent
        )
    }
}

struct Budget2027TaxCapOffset: Identifiable {
    let title: String
    let amount: Double
    let isStretch: Bool

    var id: String { title }
}

enum Budget2027TaxCapOffsetModel {
    static let policeUniformOTActual2024 = 1_401_354.00
    static let policeUniformOTBudget2024 = 1_000_000.00
    static let policeUniformOTAdopted2026 = 1_000_000.00
    static let policeUniformOTVariance = policeUniformOTActual2024 - policeUniformOTBudget2024
    static let policeOvertimeRecoveryTarget = 250_000.00
    static let policeOvertimeRecoveryShare = policeOvertimeRecoveryTarget / policeUniformOTVariance

    static let healthcareContributionSavings = 85_565.71
    static let overtimeControlSavings = policeOvertimeRecoveryTarget
    static let civilianVacancyFactorSavings = 124_158.19
    static let targetedRetirementRefillSavings = 291_300.00
    static let exemptRaiseHoldSavings = 23_094.86
    static let electedRaiseHoldSavings = 22_278.92
    static let recurringRevenueAdds = 61_500.00
    static let stretchRevenueAndCostRecovery = 250_000.00

    static let offsets: [Budget2027TaxCapOffset] = [
        .init(title: "Police Uniform OT recovery target", amount: overtimeControlSavings, isStretch: false),
        .init(title: "Targeted retirement refill control", amount: targetedRetirementRefillSavings, isStretch: false),
        .init(title: "1% civilian vacancy factor", amount: civilianVacancyFactorSavings, isStretch: false),
        .init(title: "20% healthcare contribution policy", amount: healthcareContributionSavings, isStretch: false),
        .init(title: "Hold exempt and elected raises", amount: exemptRaiseHoldSavings + electedRaiseHoldSavings, isStretch: false),
        .init(title: "Base recurring revenue adds", amount: recurringRevenueAdds, isStretch: false),
        .init(title: "Stretch fees, rentals, and cost recovery", amount: stretchRevenueAndCostRecovery, isStretch: true)
    ]

    static let baseOffsetPackage =
        healthcareContributionSavings +
        overtimeControlSavings +
        civilianVacancyFactorSavings +
        targetedRetirementRefillSavings +
        exemptRaiseHoldSavings +
        electedRaiseHoldSavings +
        recurringRevenueAdds

    static let totalOffsetPackage = baseOffsetPackage + stretchRevenueAndCostRecovery
}

enum Budget2027PoliceWorkloadModel {
    static let march2026CriminalIncidents = 167
    static let march2025CriminalIncidents = 144
    static let march2026TotalIncidents = 2_994
    static let march2025TotalIncidents = 2_922
    static let march2026NonCriminalIncidents = 2_827
    static let march2025NonCriminalIncidents = 2_778
    static let march2026DomesticIncidents = 60
    static let march2025DomesticIncidents = 60
    static let march2026Accidents = 114
    static let march2025Accidents = 123
    static let march2026Summonses = 1_042
    static let march2025Summonses = 1_076
    static let march2026CriminalCharges = 82
    static let march2026Arrests = 77
    static let march2026HeldForArraignment = 47
}

enum Budget2027PensionPressureModel {
    static let pfrs2026Budget = 6_633_131.00
    static let pfrsEstimateLow = 7_700_000.00
    static let pfrsEstimateHigh = 8_000_000.00

    static let a01ERS2026Budget = 2_268_352.00
    static let a01ERSEstimateLow = 2_500_000.00
    static let a01ERSEstimateHigh = 2_600_000.00

    static let da1ERS2026Budget = 447_917.00
    static let da1ERSEstimateLow = 490_000.00
    static let da1ERSEstimateHigh = 520_000.00

    static let utilityERS2026Budget = 499_000.00
    static let utilityERSEstimateLow = 540_000.00
    static let utilityERSEstimateHigh = 570_000.00

    static let total2026Base =
        pfrs2026Budget +
        a01ERS2026Budget +
        da1ERS2026Budget +
        utilityERS2026Budget

    static let totalEstimateLow = 11_200_000.00
    static let totalEstimateHigh = 11_700_000.00
    static let lowIncrease = 1_400_000.00
    static let highIncrease = 1_850_000.00
    static let midpointIncrease = (lowIncrease + highIncrease) / 2

    static let totalEstimateLowText = "$11.2M"
    static let totalEstimateHighText = "$11.7M"
    static let increaseLowText = "$1.4M"
    static let increaseHighText = "$1.85M"
}

enum Budget2026AdoptedGeneralFundModel {
    static let retirementNonUniform = 2_268_352.00
    static let retirementUniformPolice = 6_633_131.00
    static let retirementTotal = retirementNonUniform + retirementUniformPolice

    static let healthInsuranceNonUniform = 5_503_333.00
    static let healthInsuranceBuybackNonUniform = 629_046.00
    static let healthInsuranceUniformPolice = 3_971_332.00
    static let healthInsuranceTotal =
        healthInsuranceNonUniform +
        healthInsuranceBuybackNonUniform +
        healthInsuranceUniformPolice

    static let ficaNonUniform = 1_157_504.00
    static let ficaUniformPolice = 1_334_471.00
    static let ficaTotal = ficaNonUniform + ficaUniformPolice
}
