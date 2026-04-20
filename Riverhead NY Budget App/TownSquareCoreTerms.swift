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
    static let currentReportedHotelRoomsMax: Int = 80
    static let currentReportedCondoUnits: Int = 12
    static let currentReportedUndergroundParkingSpots: Int = 12
    static let currentReportedCompletionYear: Int = 2027

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

    /// Q&E packet “Uses of Funds” land acquisition line
    static let qeLandAcquisition: Double = 2_625_000.00

    /// Q&E budget includes an appraisal line item (signal only; not confirmation of an appraisal doc)
    static let qeSoftCostsIncludesAppraisalLineItem: Bool = true

    // MARK: - Derived

    static var downPaymentAmount: Double { purchasePrice * downPaymentRate }
    static var totalGrantCommitments: Double { grantCommitments.reduce(0, +) }

    // MARK: - Town-hosted sources

    static let mdaPublicURL: URL = URL.verified("https://www.townofriverheadny.gov/DocumentCenter/View/1197/Master-Developer-Agreement-PDF")
    static let qeDocumentsURL: URL = URL.verified("https://www.townofriverheadny.gov/DocumentCenter/View/2344/Town-Square-QE-Documents")
    static let qePresentationURL: URL = URL.verified("https://www.townofriverheadny.gov/DocumentCenter/View/2345/Town-Square-QE-Presentation")
    static let downtownRevitalizationHubURL: URL = URL.verified("https://www.townofriverheadny.gov/213/2896/Downtown-Revitalization-Projects")
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
}
