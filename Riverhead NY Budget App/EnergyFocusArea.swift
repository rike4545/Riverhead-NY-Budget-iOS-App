//
//  EnergyFocusArea.swift
//  Riverhead NY Budget App
//
//  Energy-only models used by BudgetPolicyInsightsView.
//  Keep this file MODELS ONLY (no Views) to prevent scope/access issues.
//
//  Swift 6 • iOS 17+
//

import SwiftUI
import Foundation

// MARK: - Focus Areas

public enum EnergyFocusArea: String, CaseIterable, Identifiable, Codable, Hashable {
    case all = "All"
    case explainer = "Why Energy Costs Are High"
    case townActions = "Town Energy Actions"
    case housingIncome = "Housing Affordability & Income"
    case funding = "NYS Funding"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .explainer: return "bolt.circle"
        case .townActions: return "building.columns"
        case .housingIncome: return "house.fill"
        case .funding: return "banknote"
        }
    }
}

// MARK: - Urgency

public enum EnergyUrgency: String, CaseIterable, Identifiable, Codable, Hashable {
    case now = "Do Now"
    case next = "Next"
    case later = "Later"

    public var id: String { rawValue }

    public var tint: Color {
        switch self {
        case .now: return .red
        case .next: return .orange
        case .later: return .blue
        }
    }
}

// MARK: - Models

public struct EnergyPolicyAction: Identifiable, Hashable, Codable {
    public let id: UUID
    public let area: EnergyFocusArea
    public let urgency: EnergyUrgency
    public let title: String
    public let whyItMatters: String
    public let recommendedActions: [String]
    public let nextSteps: [String]
    public let fundingMatches: [String]

    public init(
        id: UUID = UUID(),
        area: EnergyFocusArea,
        urgency: EnergyUrgency,
        title: String,
        whyItMatters: String,
        recommendedActions: [String],
        nextSteps: [String],
        fundingMatches: [String]
    ) {
        self.id = id
        self.area = area
        self.urgency = urgency
        self.title = title
        self.whyItMatters = whyItMatters
        self.recommendedActions = recommendedActions
        self.nextSteps = nextSteps
        self.fundingMatches = fundingMatches
    }
}

public struct EnergyFundingProgram: Identifiable, Hashable, Codable {
    public let id: UUID
    public let name: String
    public let purpose: String
    public let goodFor: [String]
    public let link: URL?

    public init(
        id: UUID = UUID(),
        name: String,
        purpose: String,
        goodFor: [String],
        link: URL?
    ) {
        self.id = id
        self.name = name
        self.purpose = purpose
        self.goodFor = goodFor
        self.link = link
    }
}
