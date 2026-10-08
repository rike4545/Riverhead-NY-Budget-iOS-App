import Foundation
import Testing
@testable import Riverhead_NY_Budget_App

struct CandidateWatchParityContractTests {
    /// The published web/public/data/candidate-watch.json, with the prose
    /// fields shortened and each candidate's platform and sources cut to one
    /// entry. Every field the model interprets is verbatim.
    ///
    /// Both candidates are kept because they differ in the way that matters:
    /// one carries a partyLabel and the other does not. A fixture with only one
    /// of them would pass against a model that got the fallback backwards.
    private static let canonical = #"""
    {
     "title": "2026 Town Campaign Candidate Watch",
     "asOf": "2026",
     "intro": "Who's running for Riverhead Town office in the November 2026 general election,…",
     "electionCalendar": {
      "filingDeadlineMajorParties": "April 6, 2026",
      "filingDeadlineIndependents": "June 15, 2026",
      "filingDeadlineOtherParties": "July 2026",
      "primary": "June 23, 2026",
      "generalElection": "November 3, 2026"
     },
     "legend": {
      "bold": "Active Candidate",
      "asterisk": "Incumbent",
      "note": "Incumbent party listed first."
     },
     "races": [
      {
       "office": "Town Supervisor",
       "candidates": [
        {
         "name": "Jerome (Jerry) Halpin",
         "party": "D",
         "partyLabel": "Democratic line · not enrolled in a party",
         "incumbent": true,
         "active": true,
         "website": "https://www.votejerryhalpin.com/",
         "socialMedia": [
          {
           "platform": "Facebook",
           "url": "https://www.facebook.com/p/Vote-Jerry-Halpin-61573816546076/"
          }
         ],
         "background": "Co-founder and former lead pastor of North Shore Christian Church in Riverhead…",
         "platform": [
          "Keep a tight lid on town spending."
         ],
         "sources": [
          "votejerryhalpin.com — campaign website."
         ]
        },
        {
         "name": "Kenneth Rothwell",
         "party": "R/C",
         "incumbent": false,
         "active": true,
         "website": "https://www.friendsofkenrothwell.com/",
         "socialMedia": [
          {
           "platform": "Facebook",
           "url": "https://www.facebook.com/p/Friends-of-Ken-Rothwell-Riverhead-Town-Council-100065600135011/"
          }
         ],
         "background": "Current Town Councilman (appointed Jan. 2021, elected since) and licensed…",
         "platform": [
          "Lower the cost of taxes — the campaign's stated top issue."
         ],
         "sources": [
          "friendsofkenrothwell.com — campaign website."
         ]
        }
       ]
      }
     ],
     "noRaceNote": "No Town Council seats are on the ballot in November 2026. Bob Kern and Kenneth Rothwell won three-year…"
    }
    """#

    private static func decoded() throws -> CandidateWatchParityDocument {
        try JSONDecoder().decode(CandidateWatchParityDocument.self, from: Data(canonical.utf8))
    }

    @Test func realCanonicalDocumentDecodes() throws {
        let d = try Self.decoded()
        #expect(d.title == "2026 Town Campaign Candidate Watch")
        #expect(d.races.count == 1)
        #expect(d.races[0].office == "Town Supervisor")
        #expect(d.races[0].candidates.count == 2)
        #expect(d.electionCalendar.generalElection == "November 3, 2026")
        #expect(!d.noRaceNote.isEmpty)
    }

    /// partyLabel is absent on one of the two candidates in the real file. The
    /// web page's own type omits it and reads it back as
    /// `partyLabel ?? spelledOutPartyName`, so a model requiring it would fail
    /// to decode the canonical document outright.
    @Test func absentPartyLabelFallsBackToTheSpelledOutBallotLine() throws {
        let d = try Self.decoded()
        let rothwell = try #require(d.races[0].candidates.first { $0.name.contains("Rothwell") })
        #expect(rothwell.partyLabel == nil)
        #expect(rothwell.party == "R/C")
        // A reader should never be shown a bare "R/C".
        #expect(rothwell.partyDisplay == "Republican · Conservative")
    }

    /// The label in the document wins over the spelled-out code, and this is
    /// the case that makes it matter: one candidate is on the Democratic line
    /// without being enrolled in a party. Rendering "Democrat" would state
    /// something about a real person that the source deliberately does not.
    @Test func presentPartyLabelWinsOverTheSpelledOutCode() throws {
        let d = try Self.decoded()
        let halpin = try #require(d.races[0].candidates.first { $0.name.contains("Halpin") })
        #expect(halpin.party == "D")
        #expect(halpin.partyDisplay == "Democratic line · not enrolled in a party")
        #expect(halpin.partyDisplay != "Democrat")
    }

    @Test func partyCodesAreSpelledOutAndUnknownCodesSurvive() {
        #expect(CandidateParty.spelledOut("D") == "Democrat")
        #expect(CandidateParty.spelledOut("R") == "Republican")
        #expect(CandidateParty.spelledOut("R/C") == "Republican · Conservative")
        #expect(CandidateParty.spelledOut("C") == "Conservative")
        // An unrecognised line shows as itself rather than vanishing, which is
        // the fallback the web page takes too.
        #expect(CandidateParty.spelledOut("WF") == "WF")
        #expect(CandidateParty.spelledOut("") == "")
    }

    /// The legend records that the incumbent's party is listed first, so the
    /// document's order is the display order. Nothing may sort this list.
    @Test func candidateOrderIsPreservedWithTheIncumbentFirst() throws {
        let d = try Self.decoded()
        let names = d.races[0].candidates.map(\.name)
        #expect(names == ["Jerome (Jerry) Halpin", "Kenneth Rothwell"])
        #expect(d.races[0].candidates.first?.incumbent == true)
        #expect(d.races[0].candidates.last?.incumbent == false)
    }

    /// Decoded but deliberately not rendered, because the web page does not
    /// render them either. Pinned so that stays a decision rather than drift.
    @Test func legendAndActiveDecodeEvenThoughNeitherIsRendered() throws {
        let d = try Self.decoded()
        #expect(d.legend.bold == "Active Candidate")
        #expect(d.legend.asterisk == "Incumbent")
        #expect(!d.legend.note.isEmpty)
        // Hoisted out of #expect deliberately. The macro decomposes its
        // outermost call to build a failure message, and when that call is a
        // `rethrows` method taking a closure the expansion loses its
        // non-throwing-ness: `$0.allSatisfy($1)` then "can throw, but it is
        // not marked with 'try'". Nested under an operator it is fine, which
        // is why `map(\.status) == [...]` compiles elsewhere in these tests.
        let everyCandidateIsActive = d.races[0].candidates.allSatisfy(\.active)
        #expect(everyCandidateIsActive)
    }

    @Test func campaignLinksAreUsableURLs() throws {
        let d = try Self.decoded()
        for candidate in d.races[0].candidates {
            #expect(URL(string: candidate.website) != nil)
            for social in candidate.socialMedia {
                #expect(URL(string: social.url) != nil)
                #expect(!social.platform.isEmpty)
            }
        }
    }
}
