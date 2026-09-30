import Foundation
import Testing
@testable import Riverhead_NY_Budget_App

struct RoadSpendingParityContractTests {
    /// The published document, copied from web/public/data/road-spending.json.
    ///
    /// Pinned to the real payload rather than a hand-written sample. The
    /// tax-bill screen shipped broken for exactly that reason: its only decode
    /// test used an invented literal carrying fields the canonical file had
    /// never had, so the suite stayed green while the screen 404'd on every
    /// launch.
    private static let canonical = #"""
    {
     "title": "Road spending per mile — Riverhead against the other Suffolk towns",
     "asOf": "Fiscal year 2024",
     "intro": "Every Suffolk County town files the same annual report to the State Comptroller using the same chart of accounts.",
     "spending": {
      "source": "NYS Office of the State Comptroller, Financial Data for Local Governments",
      "detail": "Annual financial report filings, fiscal year ending December 31, 2024.",
      "url": "https://www.osc.ny.gov/local-government/data"
     },
     "mileage": {
      "source": "NYS Department of Transportation, Highway Mileage: Beginning 2008",
      "detail": "Locally maintained centerline miles by municipality, 2020.",
      "url": "https://data.ny.gov/d/tccz-tc3t"
     },
     "towns": [
      { "town": "Smithtown", "highways": 19851243, "miles": 470.70, "perMile": 42174 },
      { "town": "Huntington", "highways": 31174857, "miles": 786.90, "perMile": 39617 },
      { "town": "Babylon", "highways": 17947081, "miles": 529.97, "perMile": 33864 },
      { "town": "Islip", "highways": 33487302, "miles": 997.98, "perMile": 33555 },
      { "town": "Brookhaven", "highways": 59800886, "miles": 1799.59, "perMile": 33230 },
      { "town": "Southampton", "highways": 12900129, "miles": 436.67, "perMile": 29542 },
      { "town": "Southold", "highways": 4793578, "miles": 200.41, "perMile": 23919 },
      { "town": "Riverhead", "highways": 4673787, "miles": 207.77, "perMile": 22495 },
      { "town": "Shelter Island", "highways": 1110721, "miles": 49.52, "perMile": 22430 },
      { "town": "East Hampton", "highways": 5347054, "miles": 285.58, "perMile": 18723 }
     ],
     "riverheadMix": [
      { "object": "Personal Services", "amount": 2722233 },
      { "object": "Equipment and Capital Outlay", "amount": 995678 },
      { "object": "Contractual", "amount": 955876 }
     ],
     "caveats": [
      "Low spending is not automatically good.",
      "Centerline miles, not lane miles."
     ]
    }
    """#

    @Test func canonicalRoadSpendingDocumentDecodes() throws {
        let decoded = try JSONDecoder().decode(
            RoadSpendingParityDocument.self,
            from: Data(Self.canonical.utf8)
        )

        #expect(decoded.towns.count == 10)
        #expect(decoded.riverheadMix.count == 3)
        #expect(decoded.spending.url == "https://www.osc.ny.gov/local-government/data")

        let riverhead = try #require(decoded.towns.first { $0.town == "Riverhead" })
        #expect(riverhead.perMile == 22495)
    }

    /// Riverhead is 8th of 10, and the screen says so from the data rather than
    /// from the order the file happens to arrive in.
    @Test func riverheadRanksEighthOfTenOnSpendPerMile() throws {
        let decoded = try JSONDecoder().decode(
            RoadSpendingParityDocument.self,
            from: Data(Self.canonical.utf8)
        )
        #expect(RoadSpendingRanking.rank(of: "Riverhead", in: decoded.towns) == 8)
    }

    /// Ranking must not depend on the published ordering.
    @Test func rankingIsIndependentOfDocumentOrder() throws {
        let decoded = try JSONDecoder().decode(
            RoadSpendingParityDocument.self,
            from: Data(Self.canonical.utf8)
        )
        let shuffled = decoded.towns.sorted { $0.town < $1.town }
        #expect(RoadSpendingRanking.rank(of: "Riverhead", in: shuffled) == 8)
        #expect(RoadSpendingRanking.rank(of: "Smithtown", in: shuffled) == 1)
        #expect(RoadSpendingRanking.rank(of: "East Hampton", in: shuffled) == 10)
    }

    @Test func unknownTownHasNoRank() throws {
        let decoded = try JSONDecoder().decode(
            RoadSpendingParityDocument.self,
            from: Data(Self.canonical.utf8)
        )
        #expect(RoadSpendingRanking.rank(of: "Oyster Bay", in: decoded.towns) == nil)
    }
}
