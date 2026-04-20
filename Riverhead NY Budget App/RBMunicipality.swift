//
//  RBMunicipality.swift
//  Riverhead NY Budget App
//

import Foundation

public enum RBMunicipality: String, CaseIterable, Codable, Identifiable {
    case riverhead, brookhaven, southold, eastHampton, smithtown
    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .riverhead:   return "Town of Riverhead"
        case .brookhaven:  return "Town of Brookhaven"
        case .southold:    return "Town of Southold"
        case .eastHampton: return "Town of East Hampton"
        case .smithtown:   return "Town of Smithtown"
        }
    }
}
