//  Tab.swift
//  Riverhead NY Budget App
//
//  Simple enum describing the sections of the Budget area.
//  No SwiftUI dependency — safe to use from any target.

import Foundation

enum BudgetTab: String, CaseIterable, Identifiable {
    case overview
    case myTaxes
    case deepDive
    case policies

    var id: Self { self }

    var title: String {
        switch self {
        case .overview:
            return "Overview"
        case .myTaxes:
            return "My Taxes"
        case .deepDive:
            return "Deep Dive"
        case .policies:
            return "Policies"
        }
    }

    var systemImageName: String {
        switch self {
        case .overview:
            return "chart.pie"
        case .myTaxes:
            return "doc.text.magnifyingglass"
        case .deepDive:
            return "chart.bar.xaxis"
        case .policies:
            return "doc.badge.gearshape"
        }
    }
}
