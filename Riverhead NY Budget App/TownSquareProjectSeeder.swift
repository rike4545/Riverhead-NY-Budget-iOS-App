//
//  TownSquareProjectSeeder2.swift
//  Riverhead NY Budget App
//
//  Created by Bryan on 1/21/26.
//


//
//  TownSquareProjectSeeder.swift
//  Riverhead NY Budget App
//
//  Adds a real Town Square record into RBCivicToolkitStore.capitalProjects
//  if it isn't already present (idempotent).
//
//  Swift 6 • iOS 17+
//

import Foundation

@MainActor
public extension RBCivicToolkitStore {

    /// Safe to call repeatedly; it won't duplicate the record.
    func ensureTownSquareProjectPresent() {
        let key = "Town Square"
        if capitalProjects.contains(where: { $0.name.localizedCaseInsensitiveContains(key) }) { return }

        // Keep this simple + compatible with the initializer you already use in insertDemoSeedIfEmpty().
        // (name/status/budget/fundingSource/category/department/address/coordinate/notes)
        let notes = """
        Town Square project (seeded so it appears under Capital Projects).

        Key docs:
        • Groundbreaking coverage (News-Review): https://riverheadnewsreview.timesreview.com/2025/12/130647/riverhead-breaks-ground-on-32-6m-town-square-project-to-revitalize-downtown/
        • Downtown grants coverage (RiverheadLOCAL): https://riverheadlocal.com/2025/12/30/riverhead-secures-more-than-4m-in-state-grants-for-downtown-projects/
        • Executed Master Developer Agreement (Town PDF): https://www.townofriverheadny.gov/DocumentCenter/View/1197/Master-Developer-Agreement-PDF
        • Q&E packet hub (Town PDF list): https://www.townofriverheadny.gov/DocumentCenter/View/2344/Town-Square-QE-Documents

        Separate late-2025 downtown grant reporting said Riverhead secured just over $3.5M for The Vue sewer, water, and road infrastructure and another $675K for the riverfront amphitheater.

        Related in-app tools:
        • BAN Impact
        • Q&E Budget Math
        • Sweetheart Deal Audit
        """

        let project = CapitalProject(
            name: "Town Square — Downtown Revitalization",
            status: .construction,
            budget: 32_600_000,
            fundingSource: "DRI / state grants / federal RAISE / BAN / local share",
            category: "Downtown Revitalization",
            department: "Town Board / Community Development",
            address: "Riverhead, NY",
            coordinate: .init(lat: 40.9173, lon: -72.6629),
            notes: notes
        )

        capitalProjects.append(project)
    }
}
