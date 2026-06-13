//
//  TownSquareCoreTerms.swift
//  Riverhead NY Budget App
//
//  Created by Bryan on 1/21/26.
//


//
//  TownSquareCoreTerms.swift
//  Riverhead NY Budget App
//
//  Single source of truth for Town Square numbers + public document links.
//  Swift 6 • iOS 17+
//

import Foundation

enum TownSquareCoreTerms {

    // MARK: - Executed MDA (core numbers)

    /// Purchase price (MDA §3.04(a))
    static let purchasePrice: Double = 2_625_000.00

    /// Down payment rate (MDA §3.04(a))
    static let downPaymentRate: Double = 0.05

    /// Grant commitments listed (MDA §3.04(a)) — credited to the extent already paid to Town
    static let grantCommitments: [Double] = [360_000.00, 150_000.00, 150_000.00]

    /// O&M fee for Town Square (10 years) referenced in the executed MDA strategies section
    static let townSquareOMAnnualFee: Double = 150_000.00
    static let townSquareOMTermYears: Int = 10

    /// Program summary (executed MDA strategies section)
    static let hotelRoomsMax: Int = 76
    static let condoUnits: Int = 12
    static let mdaExecutionMonthYear = "August 2025"

    // MARK: - Later reported full-project scope

    /// Riverhead News-Review, December 12, 2025 groundbreaking coverage.
    /// These are kept separate from the executed-MDA terms so the app can distinguish
    /// acquisition math from the broader construction-phase project scope.
    static let currentReportedProjectCost: Double = 32_600_000.00
    static let currentReportedDRIGrant: Double = 10_000_000.00
    static let currentReportedAdditionalStateSupport: Double = 3_200_000.00
    static let currentReportedFederalRaiseGrant: Double = 24_000_000.00
    static let currentReportedCompletionYear: Int = 2027

    /// RiverheadLOCAL, May 14, 2026 site-plan coverage.
    /// Kept separate from both the executed MDA and earlier project reporting.
    static let latestHotelProposalRooms: Int = 94
    static let latestHotelProposalStories: Int = 5
    static let latestHotelProposalSquareFeet: Int = 69_738
    static let latestHotelProposalSuites: Int = 14
    static let latestHotelProposalRestaurantSeats: Int = 116
    static let latestHotelProposalRetailSquareFeet: Int = 2_900
    static let latestHotelProposalOnSiteParkingSpaces: Int = 9
    static let latestHotelProposalWaterGallonsPerDay: Int = 20_000
    static let latestHotelProposalWastewaterGallonsPerDay: Int = 16_568
    static let latestHotelProposalSEQRAFlowBenchmarkGallonsPerDay: Int = 35_000
    static let latestHotelProposalBrand = "Hilton Tapestry"
    static let latestHotelProposalPublicHearingDate = "June 10, 2026"

    /// The June 10, 2026 hearing is a SPECIAL meeting at 6:00 p.m. covering the site plan
    /// AND special permit together — not a regular Town Board night.
    static let latestHotelProposalHearingIsSpecialMeeting: Bool = true
    static let latestHotelProposalHearingTime = "6:00 p.m."

    /// Consultant rationale to scrutinize (J. Seeman, May 11 consistency review):
    /// SEQRA review limited on the theory that Town Square is a flood-mitigation project,
    /// so the hotel inherits a reduced-impact finding. Watch for segmentation under
    /// 6 NYCRR 617.3(g), and confirm Water/Sewer District letters of availability are filed.
    static let latestHotelSEQRALimitedReviewRationale =
        "Town Square treated as a flood-mitigation project; hotel SEQRA review limited on that basis."

    // MARK: - Science Center / museum-funding civic context

    static let scienceCenterBuildingAddress = "111 East Main Street"

    /// May 20, 2026 was the public HEARING on proposed condemnation.
    static let scienceCenterPublicHearingDate = "May 20, 2026"

    /// June 3, 2026: Town Board voted to BEGIN condemnation proceedings — the operative
    /// action, distinct from the May 20 hearing. Likely the trigger for the EDPL §207
    /// 30-day judicial-challenge window; confirm against the published §204 determination
    /// & findings before relying on the date.
    static let scienceCenterCondemnationVoteDate = "June 3, 2026"

    static let scienceCenterPetitionSignatureCount = 757

    static let longIslandMuseumPropositionAmount: Double = 500_000.00
    static let longIslandMuseumEstimatedHouseholdCost: Double = 34.00
    static let southoldMuseumPropositionAmount: Double = 183_155.00
    static let southoldMuseumEstimatedHouseholdCost: Double = 35.00
    static let rockyPointHistoricalAnnualLevy: Double = 35_000.00
    static let rockyPointHistoricalEstimatedHouseholdCost: Double = 5.66

    // MARK: - Broader downtown grant pipeline

    /// RiverheadLOCAL, December 30, 2025: more than $4M in state grants for downtown projects.
    static let vueInfrastructureGrant2025: Double = 3_500_000.00
    static let amphitheaterGrant2025: Double = 675_000.00
    static let amphitheaterEarlierStateAward2025: Double = 1_400_000.00
    static let amphitheaterSecuredSoFarLate2025: Double = 2_000_000.00
    static let amphitheaterAdditionalNeedEstimateLate2025: Double = 2_000_000.00

    // MARK: - Audited / AFR debt context

    /// 2022 audited financial statements: Town refunded this amount of BANs during 2022
    /// for the acquisition and improvement of land for the downtown Town Square project.
    static let refundedBANsDuring2022: Double = 5_000_000.00

    /// 2024 AFR update: remaining BAN balance for one Town Square property note.
    static let outstandingBANBalance2024: Double = 2_800_000.00

    /// 2024 AFR update: principal paid during 2024 on the remaining Town Square note.
    static let principalPaidOnOutstandingBAN2024: Double = 50_000.00

    /// 2024 AFR update: separate Town Square BAN retired during 2024.
    static let retiredTownSquareBAN2024: Double = 1_050_000.00

    static let townSquareBANIssueDate2021 = "8/15/2021"
    static let townSquareBANMaturityDate2025 = "8/15/2025"
    static let retiredTownSquareBANIssueDate2021 = "8/17/2021"
    static let retiredTownSquareBANMaturityDate2024 = "8/17/2024"

    // MARK: - Q&E evidence (used by budget + audit)

    /// Town Square Q&E packet budget summary dated 07-22-2025.
    static let qeBudgetDate = "July 22, 2025"
    static let qeTotalProjectCost: Double = 32_672_889.76
    static let qeConstructionLoan: Double = 19_603_733.86
    static let qeDeveloperEquity: Double = 12_069_155.90
    static let qeRestoreNYGrantAwarded2024: Double = 1_000_000.00

    /// Q&E packet “Uses of Funds” land acquisition line
    static let qeLandAcquisition: Double = 2_625_000.00
    static let qeHardCosts: Double = 26_079_289.76
    static let qeSoftCosts: Double = 3_365_600.00
    static let qeContingency: Double = 603_000.00

    /// Q&E development-budget page shows 76 hotel rooms + 12 condo units.
    static let qeHotelRooms: Int = 76
    static let qeCondoUnits: Int = 12

    /// Q&E budget includes an appraisal line item (signal only; not confirmation of an appraisal doc)
    static let qeSoftCostsIncludesAppraisalLineItem: Bool = true

    // MARK: - Derived

    static var downPaymentAmount: Double { purchasePrice * downPaymentRate }
    static var totalGrantCommitments: Double { grantCommitments.reduce(0, +) }

    // MARK: - Town-hosted sources

    static let mdaPublicURL: URL = URL.verified("https://www.townofriverheadny.gov/DocumentCenter/View/1197/Master-Developer-Agreement-PDF")
    static let qeDocumentsURL: URL = URL.verified("https://www.townofriverheadny.gov/DocumentCenter/View/2344/Town-Square-QE-Documents")
    static let qePresentationURL: URL = URL.verified("https://www.townofriverheadny.gov/DocumentCenter/View/2345/Town-Square-QE-Presentation")
    static let downtownRevitalizationHubURL: URL = URL.verified("https://www.townofriverheadny.gov/213/Downtown-Revitalization-Projects")
    static let downtownRevitalizationEffortsURL: URL = URL.verified("https://www.townofriverheadny.gov/210/Downtown-Revitalization-Efforts")
    static let downtownRevitalizationCommitteeURL: URL = URL.verified("https://www.townofriverheadny.gov/261/Downtown-Revitalization-Committee")
    static let historicDowntownPeconicRiverCorridorURL: URL = URL.verified("https://www.townofriverheadny.gov/208/Historic-Downtown-Peconic-River-Corridor")
    static let planningDepartmentURL: URL = URL.verified("https://www.townofriverheadny.gov/192/Planning")
    static let downtownVisionPlanURL: URL = URL.verified("https://www.townofriverheadny.gov/DocumentCenter/View/508/Vision-Plan-PDF")
    static let downtownPatternBookURL: URL = URL.verified("https://www.townofriverheadny.gov/DocumentCenter/View/464/Final-Pattern-Book-2021-01-12-PDF")
    static let railroadTODPlanURL: URL = URL.verified("https://www.townofriverheadny.gov/DocumentCenter/View/466/Railroad-Avenue-Transit-Oriented-Development-Plan-PDF")
    static let railroadTODRFQURL: URL = URL.verified("https://www.townofriverheadny.gov/DocumentCenter/View/461/Town-of-Riverhead-Railroad-Avenue-TOD-Redevelopment-RFQ-PDF")
    static let firstMileLastMileStudyURL: URL = URL.verified("https://www.townofriverheadny.gov/DocumentCenter/View/459/Town-of-Riverhead-2022-NYS-Metropolitan-Transportation-Authority-First-Mile-Last-Mile-Pilot-Study-PDF")
    static let eastMainUrbanRenewalPlanURL: URL = URL.verified("https://www.townofriverheadny.gov/DocumentCenter/View/438/Town-of-Riverhead-East-Main-Street-Urban-Renewal-Area-Plan-2008-Update-PDF")
    static let financialReportsURL: URL = URL.verified("https://townofriverheadny.gov/206/Financial-Reports")
    static let annualFinancialReport2024URL: URL = URL.verified("https://townofriverheadny.gov/DocumentCenter/View/246/2024-Annual-Financial-Report-Update-PDF")
    static let internalControl2016URL: URL = URL.verified("https://townofriverheadny.gov/DocumentCenter/View/295/2016-IAR-on-Internal-Control-GAAS-Report-PDF")
    static let groundbreakingArticleURL: URL = URL.verified("https://riverheadnewsreview.timesreview.com/2025/12/130647/riverhead-breaks-ground-on-32-6m-town-square-project-to-revitalize-downtown/")
    static let downtownGrantArticleURL: URL = URL.verified("https://riverheadlocal.com/2025/12/30/riverhead-secures-more-than-4m-in-state-grants-for-downtown-projects/")
    static let latestHotelPlanReviewArticleURL: URL = URL.verified("https://riverheadlocal.com/2026/05/14/petrocelli-hotel-plan-gets-warm-reception-from-riverhead-town-board/")
    static let latestHotelHearingNoticeURL: URL = URL.verified("https://riverheadny.portal.civicclerk.com/event/6609/files/attachment/2767")
    static let scienceCenterPetitionURL: URL = URL.verified("https://www.change.org/p/save-the-long-island-science-center-no-eminent-domain-in-riverhead")
    static let fundBalancePetitionURL: URL = URL.verified("https://www.change.org/p/revise-riverhead-s-outdated-fund-balance-policy")
    static let scienceCenterEminentDomainArticleURL: URL = URL.verified("https://riverheadlocal.com/2026/04/22/riverhead-sets-hearing-on-condemning-science-centers-building-in-3-2-vote/")
    static let scienceCenterWebsiteURL: URL = URL.verified("https://www.sciencecenterli.org/")
    static let longIslandMuseumVoteURL: URL = URL.verified("https://longislandmuseum.org/about-the-long-island-museum/vote2026/")
    static let southoldMuseumBudgetVoteURL: URL = URL.verified("https://www.southoldhistorical.org/budget-vote")
    static let rockyPointHistoricalBudgetVoteURL: URL = URL.verified("https://rockypointhistoricalsociety.org/news/")
    static let educationLaw253URL: URL = URL.verified("https://www.nysenate.gov/legislation/laws/EDN/253")
}
