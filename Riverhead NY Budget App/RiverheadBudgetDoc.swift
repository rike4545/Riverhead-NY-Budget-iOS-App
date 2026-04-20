//
//  RiverheadBudgetDoc.swift
//  Riverhead NY Budget App
//
//  Created by Bryan on 10/15/25.
//


//
//  RiverheadBudgetDoc.swift
//  Riverhead NY Budget App
//

import Foundation

struct RiverheadBudgetDoc: Identifiable, Hashable {
    enum DocType: String, Codable, CaseIterable {
        case tentative, preliminary, adopted, capital, audit
    }

    let id: UUID
    let title: String
    let type: DocType
    let year: Int
    let url: URL
    let published: Date?
    let sizeMB: Double?

    init(
        id: UUID = UUID(),
        title: String,
        type: DocType,
        year: Int,
        url: URL,
        published: Date? = nil,
        sizeMB: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.year = year
        self.url = url
        self.published = published
        self.sizeMB = sizeMB
    }
}
