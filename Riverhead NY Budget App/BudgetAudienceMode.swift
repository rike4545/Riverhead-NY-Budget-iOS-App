//
//  BudgetAudienceMode.swift
//  Riverhead NY Budget App
//
//  Shared enums for audience mode and hub sections.
//  Swift 6 / iOS 17+
//

import SwiftUI

/// Audience "lens" for the budget tools.
enum BudgetAudienceMode: String, CaseIterable, Identifiable {
    case resident
    case expert

    var id: String { rawValue }

    /// Short label for the segmented control.
    var label: String {
        switch self {
        case .resident: return "Resident"
        case .expert:   return "Expert"
        }
    }

    /// Short description shown under the mode picker.
    var subtitle: String {
        switch self {
        case .resident:
            return "Plain language & examples"
        case .expert:
            return "Detailed views & numbers"
        }
    }
}

/// High-level sections shown in the RiverheadBudgetHubView.
enum BudgetSection: String, CaseIterable, Identifiable {
    case overview
    case supplementExplorer
    case budget2027Summary
    case proposed2027Budget
    case budget2027
    case executiveSummary
    case myTaxes
    case fundBalance
    case capitalDebt
    case outliers
    case employees  // Newsday gross earnings directory (2018–2023)
    case tools
    case glossary
    case hearing

    var id: String { rawValue }

    /// Chip label in the horizontal section selector.
    var label: String {
        switch self {
        case .overview:           return "Summary"
        case .supplementExplorer: return "Line Changes"
        case .budget2027Summary:  return "2027 Outlook"
        case .proposed2027Budget: return "2027 Plan"
        case .budget2027:         return "Build a Budget"
        case .executiveSummary:   return "By the Numbers"
        case .myTaxes:            return "My Taxes"
        case .fundBalance:        return "Reserves"
        case .capitalDebt:        return "Projects & Debt"
        case .outliers:           return "Red Flags"
        case .employees:          return "Payroll"
        case .tools:              return "All Tools"
        case .glossary:           return "Glossary"
        case .hearing:            return "Ask at Meetings"
        }
    }

    /// SF Symbol used in the section chips.
    var symbolName: String {
        switch self {
        case .overview:           return "chart.pie.fill"
        case .supplementExplorer: return "doc.text.magnifyingglass"
        case .budget2027Summary:  return "pencil.and.outline"
        case .proposed2027Budget: return "doc.text.fill"
        case .budget2027:         return "slider.horizontal.below.sun.max.fill"
        case .executiveSummary:   return "chart.xyaxis.line"
        case .myTaxes:            return "house.and.flag.fill"
        case .fundBalance:        return "banknote.fill"
        case .capitalDebt:        return "building.columns.fill"
        case .outliers:           return "exclamationmark.triangle.fill"
        case .employees:          return "person.2.fill"
        case .tools:              return "square.grid.2x2.fill"
        case .glossary:           return "text.book.closed.fill"
        case .hearing:            return "person.2.wave.2.fill"
        }
    }
}
