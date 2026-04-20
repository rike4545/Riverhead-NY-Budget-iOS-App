//
//  ContractImpactModels.swift
//  Riverhead NY Budget App
//
//  Shared models for contract impact estimation.
//  Keep these types declared ONCE in the target to avoid "Invalid redeclaration" errors.
//
//  Swift 6 • iOS 17+
//

import Foundation

// MARK: - Labor Group

public enum LaborGroup: String, CaseIterable, Codable, Hashable, Identifiable {
    case pba
    case soa
    case csea
    case exempt

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .pba: return "PBA"
        case .soa: return "SOA"
        case .csea: return "CSEA"
        case .exempt: return "Exempt"
        }
    }
}

// MARK: - Wage Action

/// Wage action applied to a group's base payroll for a given year.
/// Notes:
/// - `flat` is interpreted as dollars **per FTE** (so it scales with headcount).
public enum WageAction: Codable, Hashable {
    case percent(Double, note: String? = nil)
    case flat(Double, note: String? = nil) // per FTE
    case percentPlusFlat(Double, flatPerFTE: Double, note: String? = nil)

    public var note: String? {
        switch self {
        case .percent(_, let note): return note
        case .flat(_, let note): return note
        case .percentPlusFlat(_, _, let note): return note
        }
    }

    public func apply(toBasePayroll basePayroll: Double, fte: Double) -> Double {
        let base = max(0, basePayroll)
        let headcount = max(0, fte)

        switch self {
        case .percent(let pct, _):
            return base * (1.0 + pct)

        case .flat(let perFTE, _):
            return base + (perFTE * headcount)

        case .percentPlusFlat(let pct, let flatPerFTE, _):
            return (base * (1.0 + pct)) + (flatPerFTE * headcount)
        }
    }

    // Codable for enum with associated values
    private enum Kind: String, Codable { case percent, flat, percentPlusFlat }
    private enum CodingKeys: String, CodingKey { case kind, a, b, note }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decode(Kind.self, forKey: .kind)
        let note = try c.decodeIfPresent(String.self, forKey: .note)

        switch kind {
        case .percent:
            let a = try c.decode(Double.self, forKey: .a)
            self = .percent(a, note: note)

        case .flat:
            let a = try c.decode(Double.self, forKey: .a)
            self = .flat(a, note: note)

        case .percentPlusFlat:
            let a = try c.decode(Double.self, forKey: .a) // pct
            let b = try c.decode(Double.self, forKey: .b) // flatPerFTE
            self = .percentPlusFlat(a, flatPerFTE: b, note: note)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .percent(let pct, let note):
            try c.encode(Kind.percent, forKey: .kind)
            try c.encode(pct, forKey: .a)
            try c.encodeIfPresent(note, forKey: .note)

        case .flat(let perFTE, let note):
            try c.encode(Kind.flat, forKey: .kind)
            try c.encode(perFTE, forKey: .a)
            try c.encodeIfPresent(note, forKey: .note)

        case .percentPlusFlat(let pct, let flatPerFTE, let note):
            try c.encode(Kind.percentPlusFlat, forKey: .kind)
            try c.encode(pct, forKey: .a)
            try c.encode(flatPerFTE, forKey: .b)
            try c.encodeIfPresent(note, forKey: .note)
        }
    }
}

// MARK: - Group Assumptions

public struct GroupAssumptions: Identifiable, Codable, Hashable {
    public var id: UUID = UUID()

    public var group: LaborGroup
    public var baseYear: Int
    public var basePayroll: Double
    public var fte: Double

    /// Multipliers applied to base payroll for each projected year.
    /// Example: overtimeRate = 0.08 means overtime adds ~8% of base payroll.
    public var overtimeRate: Double
    public var otherCompRate: Double
    public var otherCompFlatPerFTE: Double

    /// Benefits modeled as flat per-FTE in the base year, with optional inflation.
    public var benefitsPerFTE: Double
    public var benefitsInflationRate: Double

    /// Used when contract catalog has no explicit action for that year.
    public var fallbackWageGrowth: Double

    public init(
        id: UUID = UUID(),
        group: LaborGroup,
        baseYear: Int,
        basePayroll: Double,
        fte: Double,
        overtimeRate: Double,
        otherCompRate: Double,
        otherCompFlatPerFTE: Double,
        benefitsPerFTE: Double,
        benefitsInflationRate: Double,
        fallbackWageGrowth: Double
    ) {
        self.id = id
        self.group = group
        self.baseYear = baseYear
        self.basePayroll = basePayroll
        self.fte = fte
        self.overtimeRate = overtimeRate
        self.otherCompRate = otherCompRate
        self.otherCompFlatPerFTE = otherCompFlatPerFTE
        self.benefitsPerFTE = benefitsPerFTE
        self.benefitsInflationRate = benefitsInflationRate
        self.fallbackWageGrowth = fallbackWageGrowth
    }

    /// Prevents negative or NaN values from polluting projections.
    public func sanitized() -> GroupAssumptions {
        var g = self
        func clean(_ x: Double) -> Double { x.isFinite ? x : 0 }
        g.basePayroll = max(0, clean(g.basePayroll))
        g.fte = max(0, clean(g.fte))

        g.overtimeRate = max(0, clean(g.overtimeRate))
        g.otherCompRate = max(0, clean(g.otherCompRate))
        g.otherCompFlatPerFTE = max(0, clean(g.otherCompFlatPerFTE))

        g.benefitsPerFTE = max(0, clean(g.benefitsPerFTE))
        g.benefitsInflationRate = max(0, clean(g.benefitsInflationRate))

        g.fallbackWageGrowth = max(0, clean(g.fallbackWageGrowth))
        return g
    }
}

// MARK: - Result

public struct YearResult: Identifiable, Hashable {
    public var year: Int
    public var groupTotalCost: [LaborGroup: Double]
    public var totalPersonnelCost: Double

    public var yoyPersonnelDelta: Double?
    public var yoyPersonnelPct: Double?

    public var totalBudgetCost: Double?
    public var yoyBudgetDelta: Double?
    public var yoyBudgetPct: Double?

    public var id: Int { year }
}
