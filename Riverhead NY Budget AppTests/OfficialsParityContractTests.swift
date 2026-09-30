import Foundation
import Testing
@testable import Riverhead_NY_Budget_App

struct OfficialsParityContractTests {
    /// Five rows lifted from the published web/public/data/officials-pensions.json,
    /// one per status, with the prose fields shortened. Everything the model
    /// actually interprets — party, status, statusLabels, sources — is verbatim.
    ///
    /// The party values are the reason this is taken from the real file rather
    /// than invented. Three of the fourteen carry an em dash, which the web page
    /// explicitly suppresses, one reads "Unaffiliated" and one "R/C" — so a model
    /// treating party as a one-letter code would be wrong three ways at once.
    private static let canonical = #"""
    {
     "title": "Elected officials who also collect a public pension",
     "asOf": "2026",
     "intro": "Some of Riverhead's elected officials spent long careers in government, retired, and then…",
     "legalNote": "This is legal and fairly common. Under New York law, an elected office is generally…",
     "statusLabels": {
      "pension": "Collects a public pension",
      "active": "Career public employee — still working (accruing, not collecting)",
      "none": "No public pension identified",
      "unconfirmed": "Public-service background — pension status not confirmed",
      "review": "Not yet reviewed"
     },
     "officials": [
      {
       "name": "James M. Wooten",
       "office": "Town Clerk",
       "party": "R",
       "status": "pension",
       "background": "Retired Riverhead Town police officer on 7/4/2005 (retired after 23 years) and a former…",
       "pension": "Collects a New York State Police & Fire Retirement System (PFRS) pension. The Empire…",
       "sources": [
        "RiverheadLOCAL, “Former councilman James Wooten returns to Riverhead…"
       ]
      },
      {
       "name": "Sean M. Walter",
       "office": "Town Justice",
       "party": "R/C",
       "status": "unconfirmed",
       "background": "Attorney; a former Riverhead Deputy Town Attorney (2000s) and former Town Supervisor…",
       "pension": "Has substantial elected and appointed public service that can earn NYS retirement credit,…",
       "sources": [
        "RiverheadLOCAL, “Sean Walter sworn in as Riverhead town justice”…"
       ]
      },
      {
       "name": "Mike Zaleski",
       "office": "Superintendent of Highways",
       "party": "R",
       "status": "active",
       "background": "A career Highway Department employee — about 30 years, including deputy superintendent —…",
       "pension": "Still an active public employee, so he is building toward a pension rather than…",
       "sources": [
        "Riverhead News-Review, “2024 Public Servants of the Year: Mike…"
       ]
      },
      {
       "name": "Jerry (Jerome) Halpin",
       "office": "Supervisor",
       "party": "Unaffiliated",
       "status": "none",
       "background": "Pastor of North Shore Christian Church for about 22 years and roughly 30 years in…",
       "pension": "No New York public pension identified.",
       "sources": [
        "RiverheadLOCAL, “Pastor Jerry Halpin will be sworn in as town…"
       ]
      },
      {
       "name": "Laverne D. Tennenberg",
       "office": "Assessor (Chair)",
       "party": "—",
       "status": "review",
       "background": "Elected member of the Board of Assessors.",
       "pension": "Not researched in depth for this page.",
       "sources": [
        "Town of Riverhead — Elected Department Heads."
       ]
      }
     ],
     "sources": [
      "Town of Riverhead — Town Elected Department Heads (roster)."
     ],
     "note": "‘Not confirmed’ and ‘not yet reviewed’ do not mean an official has no pension — only that…"
    }
    """#

    private static func decoded() throws -> OfficialsParityDocument {
        try JSONDecoder().decode(OfficialsParityDocument.self, from: Data(canonical.utf8))
    }

    @Test func realCanonicalDocumentDecodes() throws {
        let d = try Self.decoded()
        #expect(d.title == "Elected officials who also collect a public pension")
        #expect(d.asOf == "2026")
        #expect(d.officials.count == 5)
        #expect(d.statusLabels.count == 5)
        #expect(!d.legalNote.isEmpty)
        #expect(!d.note.isEmpty)
    }

    /// An em dash is the published file's placeholder for "no party recorded",
    /// and the web page drops it with `o.party !== '—'`. Rendering it would put a
    /// lone dash in a capsule and imply a party called "—".
    @Test func emDashPartyIsTreatedAsAbsent() throws {
        let d = try Self.decoded()
        let assessor = try #require(d.officials.first { $0.name == "Laverne D. Tennenberg" })
        #expect(assessor.party == nil)

        // Multi-character parties are real and must survive intact.
        let walter = try #require(d.officials.first { $0.name == "Sean M. Walter" })
        #expect(walter.party == "R/C")
        let halpin = try #require(d.officials.first { $0.name == "Jerry (Jerome) Halpin" })
        #expect(halpin.party == "Unaffiliated")
    }

    @Test func blankAndWhitespaceOnlyPartiesAreAbsentToo() {
        #expect(OfficialsParityDocument.Official.meaningfulParty(nil) == nil)
        #expect(OfficialsParityDocument.Official.meaningfulParty("") == nil)
        #expect(OfficialsParityDocument.Official.meaningfulParty("   ") == nil)
        #expect(OfficialsParityDocument.Official.meaningfulParty("—") == nil)
        #expect(OfficialsParityDocument.Official.meaningfulParty(" R ") == "R")
    }

    /// The contract that will break first. Statuses are a closed set shared
    /// between the roster and `statusLabels`, and the web page reads the label
    /// straight out of the document — so adding a sixth status on the web side
    /// without adding its wording would ship a blank badge to every reader.
    @Test func everyStatusUsedHasWording() throws {
        let d = try Self.decoded()
        #expect(d.unlabelledStatuses.isEmpty)
        for official in d.officials {
            #expect(!d.label(for: official.status).isEmpty)
        }
    }

    /// The published document already happens to be stored in display order, so
    /// this deliberately feeds it in scrambled. Against the real file a sort that
    /// did nothing at all would pass.
    @Test func orderingFollowsTheWebPageAndIsStableWithinAStatus() {
        let scrambled = ["review", "none", "pension", "active", "none", "unconfirmed", "pension"]
        let sorted = OfficialsParityOrdering.sorted(scrambled.map(Self.stub))
        #expect(sorted.map(\.status) == ["pension", "pension", "unconfirmed", "active", "none", "none", "review"])

        // The web page relies on JavaScript's sort being stable, so two officials
        // sharing a status keep their document order. Swift's sort promises no
        // such thing, which is why position is the tiebreaker.
        let ties = ["none-first", "none-second", "none-third"].map { Self.stub("none", name: $0) }
        #expect(OfficialsParityOrdering.sorted(ties).map(\.name) == ["none-first", "none-second", "none-third"])
    }

    /// The web page's `ORDER.indexOf` returns -1 for an unrecognised status,
    /// which would float it above the officials who actually draw a pension.
    /// Sorting it last is the deliberate difference, and the label falls back to
    /// the raw code so the badge is never empty.
    @Test func unknownStatusSortsLastAndKeepsItsCodeAsALabel() throws {
        let rows = ["housing", "pension", "review"].map(Self.stub)
        #expect(OfficialsParityOrdering.sorted(rows).map(\.status) == ["pension", "review", "housing"])

        let d = try Self.decoded()
        #expect(d.label(for: "housing") == "housing")
        #expect(d.label(for: "pension") == "Collects a public pension")
    }

    /// The web page guards with `o.sources?.length > 0`, so an omitted list is
    /// something it already tolerates. One row without sources should not cost
    /// the reader the other thirteen.
    @Test func absentSourcesDecodeAsEmptyRatherThanFailing() throws {
        let json = #"""
        {"name":"A","office":"Assessor","party":"—","status":"review",
         "background":"b","pension":"p"}
        """#
        let official = try JSONDecoder().decode(
            OfficialsParityDocument.Official.self,
            from: Data(json.utf8)
        )
        #expect(official.sources.isEmpty)
        #expect(official.party == nil)
    }

    @Test func countsReadStraightOffTheRoster() throws {
        let d = try Self.decoded()
        #expect(d.pensionCount == 1)
        #expect(d.activeCount == 1)
        #expect(d.officials.count == 5)
    }

    private static func stub(_ status: String, name: String = "stub") -> OfficialsParityDocument.Official {
        let json = """
        {"name":"\(name)","office":"o","party":"R","status":"\(status)",
         "background":"b","pension":"p","sources":[]}
        """
        // A fixture this shape is decoded in a test that has already proven the
        // decoder works, so a failure here is a programming error, not data.
        return try! JSONDecoder().decode(
            OfficialsParityDocument.Official.self,
            from: Data(json.utf8)
        )
    }
}
