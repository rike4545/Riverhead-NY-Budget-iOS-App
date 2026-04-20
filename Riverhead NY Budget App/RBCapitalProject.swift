//
//  RBCapitalProject.swift
//  Riverhead NY Budget App
//
//  Regenerated — self-contained model with shared types used across the app.
//  Swift 6 • iOS 17+
//

import Foundation

// MARK: - Shared Types (used by multiple modules)

public struct RBSourceRef: Identifiable, Codable, Hashable {
    public var id: UUID = UUID()
    public var title: String
    public var url: String

    public init(id: UUID = UUID(), title: String, url: String) {
        self.id = id
        self.title = title
        self.url = url
    }
}

public struct RBLatLon: Codable, Hashable {
    public var lat: Double
    public var lon: Double

    public init(lat: Double, lon: Double) {
        self.lat = lat
        self.lon = lon
    }
}

// MARK: - Capital Project

public struct RBCapitalProject: Identifiable, Codable, Hashable {
    public var id: UUID = UUID()

    public var name: String
    public var status: Status
    public var category: Category

    public var budget: Double?
    public var spent: Double?
    public var fundingSource: String

    /// Optional location fields (for map views / geocoding workflows)
    public var address: String
    public var coordinate: RBLatLon?

    public var startDate: Date?
    public var endDate: Date?

    public var sources: [RBSourceRef]

    public init(
        id: UUID = UUID(),
        name: String,
        status: Status = .planned,
        category: Category = .other,
        budget: Double? = nil,
        spent: Double? = nil,
        fundingSource: String = "",
        address: String = "",
        coordinate: RBLatLon? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        sources: [RBSourceRef] = []
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.category = category
        self.budget = budget
        self.spent = spent
        self.fundingSource = fundingSource
        self.address = address
        self.coordinate = coordinate
        self.startDate = startDate
        self.endDate = endDate
        self.sources = sources
    }

    // Matches the enum names your map view errors were expecting:
    public enum Status: String, Codable, CaseIterable, Identifiable {
        case planned = "Planned"
        case design = "In Design"
        case bid = "Bid"
        case construction = "Construction"
        case complete = "Complete"

        public var id: String { rawValue }
    }

    public enum Category: String, Codable, CaseIterable, Identifiable {
        case roads = "Roads"
        case water = "Water"
        case sewer = "Sewer"
        case buildings = "Buildings"
        case parks = "Parks"
        case publicSafety = "Public Safety"
        case technology = "Technology"
        case other = "Other"

        public var id: String { rawValue }
    }
}

// MARK: - Convenience

public extension RBCapitalProject {
    var percentSpent: Double? {
        guard let budget, budget > 0, let spent else { return nil }
        return min(max(spent / budget, 0), 1)
    }
}
