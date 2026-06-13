//
//  RBPropertyTaxEstimate.swift
//  Riverhead NY Budget App
//

import Foundation

struct RBPropertyTaxEstimate: Equatable {
    var assessedValue: Double
    var exemptions: Double
    var ratePerThousand: Double

    var sanitizedExemptions: Double { max(exemptions, 0) }
    var sanitizedRate: Double { max(ratePerThousand, 0) }
    var taxableAssessedValue: Double { max(assessedValue - sanitizedExemptions, 0) }
    var annualTax: Double { taxableAssessedValue / 1000.0 * sanitizedRate }
    var monthlyTax: Double { annualTax / 12.0 }
}

enum RBPropertyTaxRateSource: Equatable {
    case generalTown
    case generalTownAndHighway
    case custom

    var label: String {
        switch self {
        case .generalTown:
            return "2025-2026 Receiver of Taxes: General Town"
        case .generalTownAndHighway:
            return "2025-2026 Receiver of Taxes: General Town + Highway"
        case .custom:
            return "Custom user-entered rate"
        }
    }

    static func classify(
        rate: Double,
        generalTownRate: Double,
        highwayRate: Double
    ) -> RBPropertyTaxRateSource {
        if rate.isApproximately(generalTownRate) {
            return .generalTown
        }

        if rate.isApproximately(generalTownRate + highwayRate) {
            return .generalTownAndHighway
        }

        return .custom
    }
}

extension Double {
    func isApproximately(_ other: Double, tolerance: Double = 0.0001) -> Bool {
        abs(self - other) <= tolerance
    }
}
