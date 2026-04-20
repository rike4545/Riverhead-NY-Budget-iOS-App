//
//  BudgetSlice.swift
//  Riverhead NY Budget App
//
//  Core value model for budget “slices” (line items or rolled-up groups).
//

import Foundation

/// High-level categories for grouping slices.
public enum BudgetCategory: String, Codable, CaseIterable, Identifiable {
    case revenue
    case expense
    case fundBalanceAdjustment
    case capital
    case debtService
    case grants
    case other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .revenue:               return "Revenue"
        case .expense:               return "Expense"
        case .fundBalanceAdjustment: return "Fund Balance Adj."
        case .capital:               return "Capital"
        case .debtService:           return "Debt Service"
        case .grants:                return "Grants"
        case .other:                 return "Other"
        }
    }
}

/// A single budget slice (line or roll-up).
public struct BudgetSlice: Identifiable, Codable, Hashable {
    public let id: UUID
    public var label: String
    public var amount: Double           // positive for inflow, negative for outflow
    public var category: BudgetCategory
    public var notes: String?

    public init(
        id: UUID = UUID(),
        label: String,
        amount: Double,
        category: BudgetCategory,
        notes: String? = nil
    ) {
        self.id = id
        self.label = label
        self.amount = amount
        self.category = category
        self.notes = notes
    }
}

// MARK: - Convenience

public extension BudgetSlice {
    /// Returns `amount` formatted with the current locale’s currency.
    var formattedAmount: String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        return nf.string(from: amount as NSNumber) ?? "\(amount)"
    }
}

/// Collection helpers for arrays of `BudgetSlice`.
public extension Array where Element == BudgetSlice {
    /// Sum of all slice amounts.
    var totalAmount: Double {
        reduce(0) { $0 + $1.amount }
    }

    /// Totals by category.
    var totalsByCategory: [(category: BudgetCategory, total: Double)] {
        Dictionary(grouping: self, by: { $0.category })
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.category.displayName < $1.category.displayName }
    }

    /// Returns a new array sorted by absolute magnitude (descending), then label.
    func sortedByMagnitude() -> [BudgetSlice] {
        sorted {
            let a = abs($0.amount), b = abs($1.amount)
            return (a == b) ? ($0.label < $1.label) : (a > b)
        }
    }
}

// MARK: - Sample Data (optional)

public enum BudgetSampleData {
    public static let example: [BudgetSlice] = [
        .init(label: "Real Property Taxes", amount: 46_250_000, category: .revenue),
        .init(label: "Sales & Use Tax",     amount: 13_800_000, category: .revenue),
        .init(label: "Police Department",   amount: -22_450_000, category: .expense),
        .init(label: "Public Works",        amount: -12_900_000, category: .expense),
        .init(label: "Debt Service",        amount: -4_250_000,  category: .debtService),
        .init(label: "Fund Balance (Use)",  amount:  1_500_000,  category: .fundBalanceAdjustment, notes: "Use of unassigned")
    ]
}
