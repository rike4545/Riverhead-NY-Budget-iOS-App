//
//  ContractCatalog.swift
//  Riverhead NY Budget App
//
//  Contract wage actions (planning model).
//  NOTE: This file intentionally does NOT declare LaborGroup or WageAction.
//  Those should live in a single shared models file (e.g., ContractImpactModels.swift).
//

import Foundation

public enum ContractCatalog {

    /// Wage actions keyed by the year they take effect (moving prior-year payroll -> that year).
    /// Example: key 2025 means "apply this action to get from 2024 payroll to 2025 payroll."
    public static func defaultWageActions() -> [LaborGroup: [Int: WageAction]] {
        [
            .pba: [
                2023: .percent(0.06, note: "RiverheadLOCAL reported the July 25, 2023 PBA deal as +6.0% in 2023, retroactive to 1/1/2023."),
                2024: .percent(0.025, note: "RiverheadLOCAL reported the 2023-2026 PBA deal as +2.5% in 2024."),
                2025: .percent(0.025, note: "RiverheadLOCAL reported the 2023-2026 PBA deal as +2.5% in 2025."),
                2026: .percent(0.025, note: "RiverheadLOCAL reported the 2023-2026 PBA deal as +2.5% in 2026.")
            ],
            .soa: [
                2023: .percent(0.06, note: "Signed SOA MOA dated 12/13/2023: salary schedules increased 6.0% effective 7/30/2023."),
                2024: .percent(0.02, note: "Signed SOA MOA through 12/31/2026: +2.0% effective 1/1/2024."),
                2025: .percent(0.04, note: "Signed SOA MOA through 12/31/2026: +4.0% effective 1/1/2025."),
                2026: .percent(0.06, note: "Signed SOA MOA through 12/31/2026: +6.0% effective 1/1/2026.")
            ],
            .csea: [
                2026: .percentPlusFlat(0.02, flatPerFTE: 1500, note: "Approved CSEA MOA: +2.0% plus $1,500"),
                2027: .percentPlusFlat(0.025, flatPerFTE: 1000, note: "Approved CSEA MOA: +2.5% plus $1,000"),
                2028: .percentPlusFlat(0.03, flatPerFTE: 500, note: "Approved CSEA MOA: +3.0% plus $500"),
                2029: .percent(0.035, note: "Approved CSEA MOA: +3.5%")
            ],
            // ✅ Empty dictionary must be [:]
            .exempt: [:]
        ]
    }
}
