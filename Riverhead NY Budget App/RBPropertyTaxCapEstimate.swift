//
//  RBPropertyTaxCapEstimate.swift
//  Riverhead NY Budget App
//

import Foundation

struct RBPropertyTaxCapEstimate: Equatable {
    var priorYearLevy: Double
    var cpiPercent: Double
    var taxBaseGrowthFactor: Double

    var sanitizedPriorYearLevy: Double { max(priorYearLevy, 0) }
    var sanitizedTaxBaseGrowthFactor: Double { max(taxBaseGrowthFactor, 0) }

    var allowableGrowthPercent: Double {
        min(0.02, max(0.0, cpiPercent / 100.0))
    }

    var illustrativeLevyLimit: Double {
        sanitizedPriorYearLevy * sanitizedTaxBaseGrowthFactor * (1.0 + allowableGrowthPercent)
    }

    var levyChangeAmount: Double {
        illustrativeLevyLimit - sanitizedPriorYearLevy
    }
}
