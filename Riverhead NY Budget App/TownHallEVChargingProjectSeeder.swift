//
//  TownHallEVChargingProjectSeeder.swift
//  Riverhead NY Budget App
//
//  Ensures a Town Hall EV charging concept appears in Capital Projects.
//

import Foundation

@MainActor
extension RBCivicToolkitStore {

    /// Adds a Town Hall EV charging concept into `capitalProjects` if it isn't already present.
    /// Returns true only when a new record is inserted.
    @discardableResult
    func ensureTownHallEVChargingProjectPresent() -> Bool {
        let alreadyThere = capitalProjects.contains { project in
            let name = project.name.localizedLowercase
            return name.contains("town hall") && (name.contains("supercharger") || name.contains("ev charging"))
        }
        guard !alreadyThere else { return false }

        let notes = """
        Inserted by app to model a Town Hall public EV-charging concept.

        Concept:
        • Convert a 12-space portion of the Town Hall parking lot into a public EV charging plaza
        • Use the site as a visible clean-transportation and downtown-visitor amenity
        • Keep it in the capital plan as a one-time project, not a recurring operating add

        Site concept:
        • Location: Riverhead Town Hall, 4 West Second Street
        • Working program: 12 EV-designated parking spaces in the Town Hall lot
        • Fast-charging concept: Tesla Supercharger for Business host-site discussion

        Source guidance:
        • NYSERDA Charge Ready NY 2.0 describes public-facility Level 2 rebates for networked stations at public locations
        • Publicly owned facilities are shown at $4,000 per single-port station or $8,000 per two-port station, with a minimum of four ports per site
        • Public-facility eligibility guidance describes locations open to the general public with at least 20 parking spaces
        • Long Island Business News reported on March 6, 2026 that PSEG Long Island's 2026 Business First programs include EV charging incentives of up to $45,000 per Level 2 or DC fast charger plug and up to $100,000 for infrastructure upgrades, plus a separate fleet make-ready path up to $200,000
        • Tesla's Supercharger for Business page lists V4 posts, open-protocol support, optional payment terminal, and cabinet sharing up to 8 posts per cabinet

        Budget framing:
        • Do not assume NYSERDA's public Level 2 rebate automatically funds a Tesla DC fast-charging buildout; treat those as separate pathways until a specific project design is chosen
        • A realistic Town approach is to test a host-site partnership for fast charging while separately evaluating whether adjacent public Level 2 ports qualify for NYSERDA support and whether PSEG Long Island make-ready incentives can reduce the local utility-upgrade share
        • Any local share should be treated as one-time capital, with utility-upgrade cost and site-design review shown on the project sheet before approval

        Sources:
        • NYSERDA EV charging station programs: https://www.nyserda.ny.gov/PutEnergyToWork/Energy-Technology-and-Solutions/Renewables-and-Clean-Technologies/Electric-Vehicles-Charging-Stations
        • NYSERDA Charge Ready NY 2.0 factsheet: https://www.nyserda.ny.gov/-/media/Project/Nyserda/Files/Programs/Charge-Ready/Charge-Ready-NY-2-Rebate-Level-2-Charging-Stations.pdf
        • LIBN on PSEG Long Island Business First grants (March 6, 2026): https://libn.com/2026/03/06/pseg-li-offers-new-round-of-business-grants/
        • Tesla Supercharger for Business: https://www.tesla.com/supercharger-for-business
        """

        capitalProjects.append(
            CapitalProject(
                name: "Town Hall EV Charging Plaza — 12-Space Concept",
                status: .planned,
                budget: nil,
                fundingSource: "Tesla host-site partnership / utility coordination / possible NYSERDA-supported public Level 2 component",
                category: "Energy / Parking / Public Access",
                department: "Town Hall Operations / Planning / Town Board",
                address: "4 West Second Street, Riverhead, NY 11901",
                coordinate: .init(lat: 40.91734, lon: -72.66298),
                notes: notes,
                url: "https://www.tesla.com/supercharger-for-business",
                sources: [
                    .init(title: "NYSERDA EV charging stations", url: "https://www.nyserda.ny.gov/PutEnergyToWork/Energy-Technology-and-Solutions/Renewables-and-Clean-Technologies/Electric-Vehicles-Charging-Stations"),
                    .init(title: "NYSERDA Charge Ready NY 2.0 factsheet", url: "https://www.nyserda.ny.gov/-/media/Project/Nyserda/Files/Programs/Charge-Ready/Charge-Ready-NY-2-Rebate-Level-2-Charging-Stations.pdf"),
                    .init(title: "PSEG Long Island Business First grants (LIBN, March 6, 2026)", url: "https://libn.com/2026/03/06/pseg-li-offers-new-round-of-business-grants/"),
                    .init(title: "Tesla Supercharger for Business", url: "https://www.tesla.com/supercharger-for-business")
                ]
            )
        )

        return true
    }
}
