//
//  TownSquareLeaseAmendmentTerms.swift
//  Riverhead NY Budget App
//
//  Created by Bryan on 1/21/26.
//


//
//  TownSquareLeaseAmendmentTerms.swift
//  Riverhead NY Budget App
//
//  Encodes key financing + lease terms from the
//  “AMENDMENT TO LEASE PAYMENT PROVISION OF PRE-POSSESSION AND LEASE AGREEMENT”
//  for the Riverhead Town Square Hotel Project.
//
//  Swift 6 • iOS 17+
//

import Foundation

enum TownSquareLeaseAmendmentTerms {

    // MARK: - Core amounts (from the amendment text)

    /// “total estimated principal payment during 15 year period of $2,625,000”
    static let purchasePricePrincipal: Double = 2_625_000

    /// “down payment … $131,250”
    static let downPayment: Double = 131_250

    /// “outstanding purchase price less credit for down payment … $2,493,750”
    static let outstandingPurchasePriceIfNoCloseByMarch2027: Double = 2_493_750

    /// BAN year totals stated: principal + interest = $209,000 for Aug 15 2025–Aug 15 2026
    static let banYearPrincipalPaid: Double = 100_000
    static let banYearInterestCost: Double = 109_000
    static var banYearTotalCost: Double { banYearPrincipalPaid + banYearInterestCost } // 209,000

    // MARK: - Dates (as stated)

    static let banPeriodStart = DateComponents(calendar: gregorian, year: 2025, month: 8, day: 15)
    static let banPeriodEnd   = DateComponents(calendar: gregorian, year: 2026, month: 8, day: 15)

    /// “monthly lease payments … $17,500 … from … December 1, 2025 until August 1, 2026”
    static let prePossessionMonthlyLease: Double = 17_500
    static let prePossessionFirstDue = DateComponents(calendar: gregorian, year: 2025, month: 12, day: 1)
    static let prePossessionLastDue  = DateComponents(calendar: gregorian, year: 2026, month: 8, day: 1)

    /// “extended lease … $19,000 … commencing August 1, 2026 … until March 1, 2027”
    static let extendedMonthlyLease: Double = 19_000
    static let extendedFirstDue = DateComponents(calendar: gregorian, year: 2026, month: 8, day: 1)
    static let extendedLastDue  = DateComponents(calendar: gregorian, year: 2027, month: 3, day: 1)

    // MARK: - Long-term conversion (your requirement)

    /// You specified: 15 years @ 3.5%
    static let conversionTermYears: Int = 15
    static let conversionAnnualRate: Double = 0.035

    /// Typical muni cadence (also matches the numbers in the amendment pretty well)
    static let conversionPaymentsPerYear: Int = 2

    // MARK: - Derived metrics (nice for UI callouts)

    static var prePossessionPaymentCount: Int {
        countMonthlyPaymentsInclusive(from: prePossessionFirstDue, to: prePossessionLastDue)
    }

    static var extendedPaymentCount: Int {
        countMonthlyPaymentsInclusive(from: extendedFirstDue, to: extendedLastDue)
    }

    static var prePossessionTotalLease: Double {
        prePossessionMonthlyLease * Double(prePossessionPaymentCount)
    }

    static var extendedTotalLease: Double {
        extendedMonthlyLease * Double(extendedPaymentCount)
    }

    static var prePossessionAnnualizedLease: Double { prePossessionMonthlyLease * 12 }
    static var extendedAnnualizedLease: Double { extendedMonthlyLease * 12 }

    /// Level-payment (amortizing) estimate for the conversion debt.
    static var conversionPaymentPerPeriod: Double {
        DebtMath.levelPayment(
            principal: purchasePricePrincipal,
            annualRate: conversionAnnualRate,
            termYears: conversionTermYears,
            paymentsPerYear: conversionPaymentsPerYear
        )
    }

    static var conversionAnnualDebtService: Double {
        conversionPaymentPerPeriod * Double(conversionPaymentsPerYear)
    }

    static var conversionMonthlyEquivalent: Double {
        conversionAnnualDebtService / 12.0
    }

    static var conversionTotalPaid: Double {
        conversionPaymentPerPeriod * Double(conversionTermYears * conversionPaymentsPerYear)
    }

    static var conversionTotalInterest: Double {
        max(0, conversionTotalPaid - purchasePricePrincipal)
    }

    // MARK: - Helpers

    private static let gregorian = Calendar(identifier: .gregorian)

    /// Count “1st of each month” payments inclusive (e.g., Aug 1 through Mar 1 counts both endpoints).
    static func countMonthlyPaymentsInclusive(from start: DateComponents, to end: DateComponents) -> Int {
        guard
            let s = gregorian.date(from: start),
            let e = gregorian.date(from: end),
            s <= e
        else { return 0 }

        let comps = gregorian.dateComponents([.month], from: gregorian.startOfDay(for: s), to: gregorian.startOfDay(for: e))
        let months = comps.month ?? 0
        return max(0, months + 1)
    }

    enum DebtMath {
        static func levelPayment(principal: Double, annualRate: Double, termYears: Int, paymentsPerYear: Int) -> Double {
            guard principal > 0, annualRate >= 0, termYears > 0, paymentsPerYear > 0 else { return 0 }
            let n = Double(termYears * paymentsPerYear)
            let r = annualRate / Double(paymentsPerYear)
            if r == 0 { return principal / max(1, n) }
            let denom = 1 - pow(1 + r, -n)
            guard denom != 0 else { return 0 }
            return principal * r / denom
        }
    }
}
