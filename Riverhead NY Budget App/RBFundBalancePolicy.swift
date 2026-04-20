//
//  RBFundBalancePolicy.swift
//  Riverhead NY Budget App
//
//  Fund balance policy model + helpers (GASB 54 style).
//  Swift 6 / iOS 17+
//
//  • RBFundBalancePolicy       – configuration for a single fund’s policy
//  • RBFundBalanceAssessment   – result of evaluating a fund vs that policy
//  • RiverheadFundBalancePolicyBook – presets for Riverhead usage
//

import Foundation

// MARK: - Policy Model

/// Fund balance policy for a fund (e.g., General Fund).
public struct RBFundBalancePolicy: Codable, Equatable, Sendable {
    /// Minimum unassigned fund balance as a share of next-year appropriations (e.g. 0.15 = 15%).
    public var minimumPercent: Double

    /// Optional upper target band (e.g. 0.25 = 25%). Use `nil` if no upper band.
    public var targetUpperPercent: Double?

    /// Years allowed to replenish when below minimum (optional).
    public var replenishYears: Int?

    /// Free-form notes (brief description of the policy).
    public var notes: String

    /// Optional citation URLs or short references.
    public var citations: [String]

    public init(
        minimumPercent: Double,
        targetUpperPercent: Double? = nil,
        replenishYears: Int? = nil,
        notes: String = "",
        citations: [String] = []
    ) {
        self.minimumPercent = minimumPercent
        self.targetUpperPercent = targetUpperPercent
        self.replenishYears = replenishYears
        self.notes = notes
        self.citations = citations
    }
}

// MARK: - Computation Helpers

public extension RBFundBalancePolicy {
    /// Dollar minimum required given appropriations.
    func minimumRequired(appropriations: Double) -> Double {
        max(0, appropriations * minimumPercent)
    }

    /// Dollar upper target given appropriations, if configured.
    func targetUpper(appropriations: Double) -> Double? {
        guard let up = targetUpperPercent else { return nil }
        return max(0, appropriations * up)
    }

    /// Builds an assessment snapshot comparing an (optional) unassigned balance to policy.
    ///
    /// - Parameters:
    ///   - unassigned: Unassigned fund balance (dollars), or `nil` if unknown.
    ///   - appropriations: Next-year appropriations / expenditures (dollars).
    func assess(unassigned: Double?, appropriations: Double) -> RBFundBalanceAssessment {
        let minReq = minimumRequired(appropriations: appropriations)
        let upper  = targetUpper(appropriations: appropriations)

        // If we don't have enough information, return a “metadata only” assessment.
        guard let ua = unassigned, appropriations > 0 else {
            return RBFundBalanceAssessment(
                percentOfExpenditures: nil,
                meetsPolicy: nil,
                gapPercentagePoints: nil,
                dollarsNeededToTarget: nil,
                minimumRequired: minReq,
                targetUpper: upper
            )
        }

        let pct = ua / appropriations               // e.g. 0.17 for 17%
        let meets = pct >= minimumPercent
        let gapPP = (pct - minimumPercent) * 100.0  // +2.3 means 2.3 points above min
        let needed = max(0, minReq - ua)

        return RBFundBalanceAssessment(
            percentOfExpenditures: pct,
            meetsPolicy: meets,
            gapPercentagePoints: gapPP,
            dollarsNeededToTarget: needed == 0 ? 0 : needed,
            minimumRequired: minReq,
            targetUpper: upper
        )
    }
}

/// Result of evaluating a fund against its policy.
public struct RBFundBalanceAssessment: Codable, Equatable, Sendable {
    /// Unassigned as a fraction of expenditures (0.15 = 15%). `nil` if unknown.
    public let percentOfExpenditures: Double?

    /// Whether the policy minimum is met. `nil` if inputs insufficient.
    public let meetsPolicy: Bool?

    /// Percentage points above/below the minimum (e.g., +2.3, -1.7). `nil` if unknown.
    public let gapPercentagePoints: Double?

    /// Dollars needed to reach the minimum target (0 if at/above). `nil` if unknown.
    public let dollarsNeededToTarget: Double?

    /// Echo of computed minimum (for UI display).
    public let minimumRequired: Double

    /// Echo of computed upper band, if any (for UI display).
    public let targetUpper: Double?
}

// MARK: - Riverhead Presets

/// Common presets for Riverhead (adjust as the Town updates policy).
///
/// These are *example* policy settings you can use to drive dashboards:
/// they are not legal advice and should always be checked against the
/// Town’s most recent adopted policies and resolutions.
public enum RiverheadFundBalancePolicyBook {

    /// Example policy for the **General Fund**.
    ///
    /// Uses a **15% minimum** of expenditures to reflect the “good practice”
    /// guideline you reference elsewhere in the app, with a nominal 25% upper
    /// band so dashboards can show “above band” conditions.
    public static func general() -> RBFundBalancePolicy {
        .init(
            minimumPercent: 0.15,
            targetUpperPercent: 0.25,
            replenishYears: 3,
            notes: "General Fund example: 15% minimum of next-year expenditures, with an illustrative 25% upper band and 3-year replenish window.",
            citations: []
        )
    }

    /// Example policy for **other operating funds** (Highway, special districts, etc.).
    ///
    /// Uses a 5% minimum and 15% upper band as a simple strawman; tune per fund
    /// if you later add a more detailed policy matrix.
    public static func otherOperating() -> RBFundBalancePolicy {
        .init(
            minimumPercent: 0.05,
            targetUpperPercent: 0.15,
            replenishYears: 3,
            notes: "Other operating funds example: 5% minimum of expenditures with a 15% upper band and 3-year replenish window.",
            citations: []
        )
    }
}
