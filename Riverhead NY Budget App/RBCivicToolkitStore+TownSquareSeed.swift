//
//  RBCivicToolkitStore+TownSquareSeed.swift
//  Riverhead NY Budget App
//
//  Created by Bryan on 1/21/26.
//


//
//  RBCivicToolkitStore+TownSquareSeed.swift
//  Riverhead NY Budget App
//
//  Ensures the Town Square project appears in Capital Projects even if the upstream dataset omits it.
//  Swift 6 • iOS 17+
//

import Foundation

@MainActor
extension RBCivicToolkitStore {

    /// Adds a Town Square record into `capitalProjects` if it isn't already present.
    func ensureTownSquareProjectPresent() {
        let alreadyThere = capitalProjects.contains { p in
            p.name.localizedCaseInsensitiveContains("town square")
        }
        guard !alreadyThere else { return }

        let notes = """
        Inserted by app to bridge the gap between the Capital Projects dataset and the Town Square public record.

        Current reported buildout (Riverhead News-Review, December 12, 2025):
        • Total project cost: $32,600,000
        • Program: up to 80 Hilton Tapestry Collection hotel rooms, 12 condominium units, restaurant/retail space, and 12 underground parking spaces
        • Reported support: $10,000,000 DRI, $3,200,000 additional state support, and a referenced $24,000,000 federal RAISE grant
        • Reported construction timeline: groundbreaking in December 2025 with expected completion in 2027

        Key figures (Executed MDA / Town Square):
        • Purchase price: $2,625,000
        • Escrow deposit: 5% of purchase price
        • Grant commitment credits: $360,000 + $150,000 + $150,000 (credited against balance due at closing to the extent paid)
        • Town Square O&M fee: $150,000/year for 10 years (per separate Operation & Management Agreement)
        • 2022 audited statements say the Town refunded $5,000,000 of BANs for acquisition and improvement of land for the downtown Town Square project
        • 2024 AFR shows one Town Square BAN with a $2,800,000 ending balance after $50,000 principal paid, plus a separate $1,050,000 Town Square BAN retired during 2024

        Fund balance context:
        • If Town Square costs are paid from reserves instead of debt, the General Fund cushion falls immediately
        • Riverhead's policy floor used elsewhere in the app is 15% of operating appropriations
        • If an appropriation would reduce projected General Fund balance below that floor, the policy says the Town Board should approve it by resolution

        Town links:
        • Downtown revitalization hub: https://www.townofriverheadny.gov/213/2896/Downtown-Revitalization-Projects
        • MDA PDF: https://www.townofriverheadny.gov/DocumentCenter/View/1197/Master-Developer-Agreement-PDF
        • Q&E packet: https://www.townofriverheadny.gov/DocumentCenter/View/2344/Town-Square-QE-Documents
        • Q&E presentation: https://www.townofriverheadny.gov/DocumentCenter/View/2345/Town-Square-QE-Presentation
        • Vision plan: https://www.townofriverheadny.gov/DocumentCenter/View/508/Vision-Plan-PDF
        • Final pattern book: https://www.townofriverheadny.gov/DocumentCenter/View/464/Final-Pattern-Book-2021-01-12-PDF
        • Railroad Avenue TOD plan: https://www.townofriverheadny.gov/DocumentCenter/View/466/Railroad-Avenue-Transit-Oriented-Development-Plan-PDF
        • Railroad Avenue TOD RFQ: https://www.townofriverheadny.gov/DocumentCenter/View/461/Town-of-Riverhead-Railroad-Avenue-TOD-Redevelopment-RFQ-PDF
        • First Mile / Last Mile study: https://www.townofriverheadny.gov/DocumentCenter/View/459/Town-of-Riverhead-2022-NYS-Metropolitan-Transportation-Authority-First-Mile-Last-Mile-Pilot-Study-PDF
        • East Main Street Urban Renewal plan: https://www.townofriverheadny.gov/DocumentCenter/View/438/Town-of-Riverhead-East-Main-Street-Urban-Renewal-Area-Plan-2008-Update-PDF
        • 2024 AFR update: https://townofriverheadny.gov/DocumentCenter/View/246/2024-Annual-Financial-Report-Update-PDF
        • Groundbreaking coverage: https://riverheadnewsreview.timesreview.com/2025/12/130647/riverhead-breaks-ground-on-32-6m-town-square-project-to-revitalize-downtown/
        • Downtown grants coverage: https://riverheadlocal.com/2025/12/30/riverhead-secures-more-than-4m-in-state-grants-for-downtown-projects/
        """

        let project = CapitalProject(
            name: "Riverhead Town Square Project",
            status: .construction,
            budget: 32_600_000,
            fundingSource: "DRI / state grants / federal RAISE / BAN / local share",
            category: "Downtown Revitalization",
            department: "Town Board / Community Development",
            address: "Riverhead, NY (Town Square / Downtown)",
            coordinate: .init(lat: 40.9170, lon: -72.6620),
            notes: notes
        )

        capitalProjects.append(project)
    }
}
