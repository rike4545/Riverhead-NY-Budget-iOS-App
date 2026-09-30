import Foundation
import Testing
@testable import Riverhead_NY_Budget_App

struct TownHistoryParityContractTests {
    /// Trimmed from the published web/public/data/town-history.json, keeping the
    /// shapes that matter: a supervisor with no sourced party, and officeholders
    /// still serving (null termEnd). Both are real in the live document — one
    /// supervisor has a null party and five people across the two rosters have a
    /// null termEnd — and a model that required either would fail to decode the
    /// canonical file outright.
    private static let canonical = #"""
    {
     "title": "Supervisors & Council Members, 2004–2026",
     "asOf": "2026",
     "intro": "Who has held Riverhead's top elected offices over roughly the last two decades.",
     "scopeNote": "This is not a complete roster back to the Town's 1792 founding.",
     "supervisors": [
      {
       "name": "Phil Cardinale",
       "party": null,
       "termStart": "2004-01-01",
       "termEnd": "2010-01-01",
       "note": "Defeated by Sean Walter in the November 2009 election.",
       "sources": ["Riverhead News-Review (March 2012)."]
      },
      {
       "name": "Tim Hubbard",
       "party": "R",
       "termStart": "2024-01-01",
       "termEnd": null,
       "note": "Currently serving.",
       "sources": ["RiverheadLOCAL (Jan. 2024)."]
      }
     ],
     "councilMembers": [
      {
       "name": "Bob Kern",
       "party": "R",
       "termStart": "2024-01-01",
       "termEnd": null,
       "note": "Currently serving.",
       "sources": ["RiverheadLOCAL (Jan. 2024)."]
      }
     ]
    }
    """#

    private static func decoded() throws -> TownHistoryParityDocument {
        try JSONDecoder().decode(
            TownHistoryParityDocument.self,
            from: Data(canonical.utf8)
        )
    }

    @Test func canonicalDocumentDecodesWithNullPartyAndNullTermEnd() throws {
        let d = try Self.decoded()
        #expect(d.supervisors.count == 2)
        #expect(d.councilMembers.count == 1)

        let cardinale = try #require(d.supervisors.first { $0.name == "Phil Cardinale" })
        #expect(cardinale.party == nil)
        #expect(cardinale.termEnd == "2010-01-01")
        #expect(cardinale.isServing == false)
    }

    /// A null end date means still in office, not a missing record.
    @Test func nullTermEndMeansStillServing() throws {
        let d = try Self.decoded()
        let hubbard = try #require(d.supervisors.first { $0.name == "Tim Hubbard" })
        #expect(hubbard.termEnd == nil)
        #expect(hubbard.isServing)
    }

    @Test func termRangesReadFromTheYearOnly() {
        #expect(TownHistoryFormatting.term(start: "2004-01-01", end: "2010-01-01") == "2004 – 2010")
        #expect(TownHistoryFormatting.term(start: "2024-01-01", end: nil) == "2024 – present")
    }

    /// The year is taken from the leading component rather than parsed as a
    /// Date. A January 1 boundary run through a time-zone-aware parser is how
    /// "today" ended up computed in UTC elsewhere in this app, which rolled the
    /// date over at 8pm Eastern.
    @Test func januaryFirstBoundaryDoesNotShiftAYear() {
        #expect(TownHistoryFormatting.year("2010-01-01") == "2010")
        #expect(TownHistoryFormatting.year("2015-11-01") == "2015")
    }
}
