//
//  RBSixSigmaPhase.swift
//  Riverhead NY Budget App
//
//  Created by Bryan on 1/21/26.
//


//
//  RBSixSigmaPhase.swift
//  Riverhead NY Budget App
//
//  Six Sigma core types (DMAIC) — MODELS ONLY
//  iOS 17+ • Swift 6
//
//  IMPORTANT:
//  - Do NOT define RBSixSigmaStore in this file.
//  - There should be exactly ONE RBSixSigmaStore in the target (RBSixSigmaStore.swift).
//

import Foundation

// MARK: - DMAIC Phase

public enum RBSixSigmaPhase: String, CaseIterable, Codable, Hashable {
    case define, measure, analyze, improve, control

    public var title: String {
        switch self {
        case .define: return "Define"
        case .measure: return "Measure"
        case .analyze: return "Analyze"
        case .improve: return "Improve"
        case .control: return "Control"
        }
    }

    /// Use valid SF Symbols to avoid runtime console spam.
    public var systemImage: String {
        switch self {
        case .define: return "flag.checkered"
        case .measure: return "ruler"
        case .analyze: return "magnifyingglass"
        case .improve: return "wand.and.stars"
        case .control: return "checkmark.seal"
        }
    }
}

// MARK: - Models

public struct RBSixSigmaMetric: Identifiable, Codable, Hashable {
    public var id: UUID = UUID()
    public var name: String
    public var unit: String
    public var baseline: Double?
    public var target: Double?
    public var current: Double?
    public var notes: String?
    public var updatedAt: Date = Date()

    public init(
        id: UUID = UUID(),
        name: String,
        unit: String = "",
        baseline: Double? = nil,
        target: Double? = nil,
        current: Double? = nil,
        notes: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.unit = unit
        self.baseline = baseline
        self.target = target
        self.current = current
        self.notes = notes
        self.updatedAt = updatedAt
    }
}

public struct RBSixSigmaRootCause: Identifiable, Codable, Hashable {
    public var id: UUID = UUID()
    public var statement: String
    public var evidence: String?
    public var impactScore: Int   // 1–5
    public var likelihoodScore: Int // 1–5
    public var tags: [String]

    public init(
        id: UUID = UUID(),
        statement: String,
        evidence: String? = nil,
        impactScore: Int = 3,
        likelihoodScore: Int = 3,
        tags: [String] = []
    ) {
        self.id = id
        self.statement = statement
        self.evidence = evidence
        self.impactScore = max(1, min(5, impactScore))
        self.likelihoodScore = max(1, min(5, likelihoodScore))
        self.tags = tags
    }

    public var priorityScore: Int { impactScore * likelihoodScore }
}

public enum RBSixSigmaImprovementStatus: String, CaseIterable, Codable, Hashable {
    case proposed, inProgress, blocked, done

    public var title: String {
        switch self {
        case .proposed: return "Proposed"
        case .inProgress: return "In Progress"
        case .blocked: return "Blocked"
        case .done: return "Done"
        }
    }
}

public struct RBSixSigmaImprovement: Identifiable, Codable, Hashable {
    public var id: UUID = UUID()
    public var title: String
    public var detail: String
    public var status: RBSixSigmaImprovementStatus
    public var costEstimate: Double?
    public var expectedAnnualSavings: Double?

    public init(
        id: UUID = UUID(),
        title: String,
        detail: String = "",
        status: RBSixSigmaImprovementStatus = .proposed,
        costEstimate: Double? = nil,
        expectedAnnualSavings: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.status = status
        self.costEstimate = costEstimate
        self.expectedAnnualSavings = expectedAnnualSavings
    }
}

public enum RBSixSigmaCadence: String, CaseIterable, Codable, Hashable {
    case daily, weekly, monthly, quarterly, yearly
    public var title: String { rawValue.capitalized }
}

public enum RBSixSigmaControlStatus: String, CaseIterable, Codable, Hashable {
    case open, done
    public var title: String { rawValue.capitalized }
}

public struct RBSixSigmaControlItem: Identifiable, Codable, Hashable {
    public var id: UUID = UUID()
    public var title: String
    public var owner: String
    public var cadence: RBSixSigmaCadence
    public var evidence: String
    public var status: RBSixSigmaControlStatus
    public var dueDate: Date?

    public init(
        id: UUID = UUID(),
        title: String,
        owner: String = "",
        cadence: RBSixSigmaCadence = .monthly,
        evidence: String = "",
        status: RBSixSigmaControlStatus = .open,
        dueDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.owner = owner
        self.cadence = cadence
        self.evidence = evidence
        self.status = status
        self.dueDate = dueDate
    }
}

public struct RBSixSigmaProject: Identifiable, Codable, Hashable {
    public var id: UUID = UUID()

    public var title: String
    public var owner: String
    public var department: String

    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()

    // Define
    public var problemStatement: String
    public var goalStatement: String
    public var scopeIn: String
    public var scopeOut: String

    public var phase: RBSixSigmaPhase

    // Measure / Analyze / Improve / Control
    public var metrics: [RBSixSigmaMetric]
    public var rootCauses: [RBSixSigmaRootCause]
    public var improvements: [RBSixSigmaImprovement]
    public var controls: [RBSixSigmaControlItem]

    public init(
        id: UUID = UUID(),
        title: String,
        owner: String = "",
        department: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        problemStatement: String = "",
        goalStatement: String = "",
        scopeIn: String = "",
        scopeOut: String = "",
        phase: RBSixSigmaPhase = .define,
        metrics: [RBSixSigmaMetric] = [],
        rootCauses: [RBSixSigmaRootCause] = [],
        improvements: [RBSixSigmaImprovement] = [],
        controls: [RBSixSigmaControlItem] = []
    ) {
        self.id = id
        self.title = title
        self.owner = owner
        self.department = department
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.problemStatement = problemStatement
        self.goalStatement = goalStatement
        self.scopeIn = scopeIn
        self.scopeOut = scopeOut
        self.phase = phase
        self.metrics = metrics
        self.rootCauses = rootCauses
        self.improvements = improvements
        self.controls = controls
    }
}
