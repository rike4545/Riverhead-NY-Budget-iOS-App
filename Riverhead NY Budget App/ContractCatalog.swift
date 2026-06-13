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
                2023: .percent(0.06, note: "Signed PBA contract, Article XXXI/XXXVI: term runs 1/1/2023-12/31/2026; 2023 salary schedule is the first contract-year schedule."),
                2024: .percent(0.025, note: "Signed PBA contract, Article XXXVI: 2024 salary schedule is +2.5% over the 2023 schedule."),
                2025: .percent(0.025, note: "Signed PBA contract, Article XXXVI: 2025 salary schedule is +2.5% over the 2024 schedule."),
                2026: .percent(0.025, note: "Signed PBA contract, Article XXXVI: 2026 salary schedule is +2.5% over the 2025 schedule.")
            ],
            .soa: [
                2023: .percent(0.06, note: "SOA base agreement Article I covers Sergeants, Detective Sergeants, and Lieutenants; signed SOA MOA Articles XXVI/XXXII set the 1/1/2023-12/31/2026 term and increased those schedules 6.0% effective 7/30/2023."),
                2024: .percent(0.02, note: "Signed SOA MOA, Article XXXII: 2024 salary schedules are +2.0% over the 7/30/2023 schedules."),
                2025: .percent(0.04, note: "Signed SOA MOA, Article XXXII: 2025 salary schedules are +4.0% over the 2024 schedules."),
                2026: .percent(0.06, note: "Signed SOA MOA, Article XXXII: 2026 salary schedules are +6.0% over the 2025 schedules.")
            ],
            .csea: [
                2023: .percentPlusFlat(0.05, flatPerFTE: 1500, note: "Executed CSEA CBA 2023-2025, Article 15: +5.0% retroactive to 1/1/2023 plus a one-time, non-recurring $1,500 salary-schedule adjustment."),
                2024: .percent(0.02, note: "Executed CSEA CBA 2023-2025, Article 15: +2.0% effective 1/1/2024 on the adjusted 2023 salary schedule."),
                2025: .percent(0.02, note: "Executed CSEA CBA 2023-2025, Article 15: +2.0% effective 1/1/2025 on the 2024 salary schedule."),
                2026: .percentPlusFlat(0.02, flatPerFTE: 1500, note: "Town Board-approved CSEA MOA for 2026-2029, approved 12/16/2025: +2.0% plus $1,500 supplemental payment."),
                2027: .percentPlusFlat(0.025, flatPerFTE: 1000, note: "Town Board-approved CSEA MOA for 2026-2029, approved 12/16/2025: +2.5% plus $1,000 supplemental payment."),
                2028: .percentPlusFlat(0.03, flatPerFTE: 500, note: "Town Board-approved CSEA MOA for 2026-2029, approved 12/16/2025: +3.0% plus $500 supplemental payment."),
                2029: .percent(0.035, note: "Town Board-approved CSEA MOA for 2026-2029, approved 12/16/2025: +3.5%.")
            ],
            // ✅ Empty dictionary must be [:]
            .exempt: [:]
        ]
    }
}
