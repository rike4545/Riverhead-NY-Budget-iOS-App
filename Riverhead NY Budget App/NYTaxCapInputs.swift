//
//  NYTaxCapInputs.swift
//  Riverhead NY Budget App
//

import Foundation

// MARK: - Inputs

public struct NYTaxCapInputs: Codable, Equatable, Sendable {
    public var priorYearLevy: Double
    public var cpiPercent: Double          // e.g. 2.00 = 2%
    public var tbgf: Double                 // Tax Base Growth Factor (e.g. 1.0072)
    public var carryover: Double
    public var capitalExclusions: Double
    public var pilots: Double               // payments in lieu of taxes

    public init(
        priorYearLevy: Double,
        cpiPercent: Double,
        tbgf: Double,
        carryover: Double,
        capitalExclusions: Double,
        pilots: Double
    ) {
        self.priorYearLevy = priorYearLevy
        self.cpiPercent = cpiPercent
        self.tbgf = tbgf
        self.carryover = carryover
        self.capitalExclusions = capitalExclusions
        self.pilots = pilots
    }
}

// MARK: - Result

public struct NYTaxCapResult: Codable, Equatable, Sendable {
    public let levyLimit: Double
    public let overrideRequired: Bool

    // Optional debug components, useful for UI readouts
    public let cappedCPI: Double   // as a fraction (0.00 ... 0.02)
    public let base: Double        // priorYearLevy * tbgf
    public let growth: Double      // base * (1 + cappedCPI)

    public init(
        levyLimit: Double,
        overrideRequired: Bool,
        cappedCPI: Double,
        base: Double,
        growth: Double
    ) {
        self.levyLimit = levyLimit
        self.overrideRequired = overrideRequired
        self.cappedCPI = cappedCPI
        self.base = base
        self.growth = growth
    }
}

// MARK: - Calculator

public enum NYTaxCapCalculator {
    /// Simplified OSC-style sequence:
    /// base = priorYearLevy * TBGF
    /// cappedCPI = clamp(CPI, 0 ... 2)% -> fraction
    /// growth = base * (1 + cappedCPI)
    /// levyLimit = growth + carryover + capitalExclusions - PILOTs
    public static func compute(_ i: NYTaxCapInputs, proposedLevy: Double) -> NYTaxCapResult {
        let cappedCPI = min(max(i.cpiPercent, 0.0), 2.0) / 100.0
        let base = max(0, i.priorYearLevy) * i.tbgf
        let growth = base * (1.0 + cappedCPI)
        let levyLimit = max(0, growth + i.carryover + i.capitalExclusions - i.pilots)
        let override = proposedLevy > levyLimit

        return NYTaxCapResult(
            levyLimit: levyLimit,
            overrideRequired: override,
            cappedCPI: cappedCPI,
            base: base,
            growth: growth
        )
    }
}
