//
//  PostAdoption2027Tests.swift
//  Riverhead NY Budget AppTests
//
//  The 2027 budget was adopted on November 17, 2026 (Resolution 2026-995) and
//  the PBA and SOA 2027-2030 stipulations were approved the same night
//  (Resolutions 2026-1020 and 2026-1021). These hold the app to those records
//  and to the website's September model, kept as it was made.
//

import Foundation
import Testing
@testable import Riverhead_NY_Budget_App

struct PostAdoption2027Tests {

    @Test func septemberModelMatchesTheWebsite() {
        // web/public/data/budget-2027-prediction-september.json, capGap
        #expect(CloseTheGap2027.capPiercingGap == 2_316_256)
        #expect(CloseTheGap2027.predictedLevy == 68_967_074)
        #expect(CloseTheGap2027.allowedLevy == 66_650_818)
        #expect(CloseTheGap2027.predictedLevy - CloseTheGap2027.allowedLevy == CloseTheGap2027.capPiercingGap)
    }

    @Test func outcomeArithmeticMatchesItsSummary() {
        #expect(CloseTheGap2027.Outcome.adoptedLevy == 66_516_005)
        #expect(CloseTheGap2027.Outcome.underReferenceLine == 134_813)
        #expect(CloseTheGap2027.Outcome.belowModel == 2_451_069)
        #expect(CloseTheGap2027.Outcome.summary.contains("$134,813"))
        #expect(CloseTheGap2027.Outcome.summary.contains("$2,451,069"))
    }

    @Test func policeContractsCarryTheApprovedTerms() {
        let actions = ContractCatalog.defaultWageActions()
        for group in [LaborGroup.pba, .soa] {
            guard case let .percentPlusFlat(pct, flat, _)? = actions[group]?[2027] else {
                Issue.record("\(group) 2027 should be 3.75% plus $500")
                continue
            }
            #expect(pct == 0.0375)
            #expect(flat == 500)
            for year in 2028...2030 {
                guard case let .percent(p, _)? = actions[group]?[year] else {
                    Issue.record("\(group) \(year) should be 3.75%")
                    continue
                }
                #expect(p == 0.0375)
            }
        }
    }

    @Test func noScreenStillCallsThePoliceContractsUnsettled() {
        let texts = [CloseTheGap2027.unionBreakdownEstimateNote] + CloseTheGap2027.unionBreakdown.compactMap(\.term)
        for t in texts { #expect(!t.contains("no successor yet public")) }
    }
}
