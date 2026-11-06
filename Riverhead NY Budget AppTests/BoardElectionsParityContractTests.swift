import Foundation
import Testing
@testable import Riverhead_NY_Budget_App

/// Pins the two fields the parity drift check found the web app publishing and
/// `BoardElectionsParityDocument.PriorElection` ignoring: the uncertified-result
/// `status`, and structured `turnout`.
///
/// Both are optional in the Swift model, and that is the behaviour most worth a
/// test: the 2026 cycle publishes `status` and no `turnout`, every earlier cycle
/// publishes `turnout` and no `status`. A non-optional either way would throw
/// the whole document out and drop the screen back to its web fallback without
/// a crash or a log — the failure this project has already had once.
struct BoardElectionsParityContractTests {
    private func decodePriorElection(_ json: String) throws -> BoardElectionsParityDocument.PriorElection {
        try JSONDecoder().decode(
            BoardElectionsParityDocument.PriorElection.self,
            from: Data(json.utf8)
        )
    }

    @Test func uncertifiedCycleCarriesStatusAndNoTurnout() throws {
        let election = try decodePriorElection(#"""
        {
          "year": 2026,
          "status": "Unofficial — not yet certified",
          "turnoutNote": "Results are unofficial until the Board of Elections certifies them.",
          "races": [
            {
              "office": "Supervisor",
              "seats": 1,
              "winners": [{"name": "Example Winner", "party": "D", "votes": 4200}],
              "runnersUp": [{"name": "Example Runner-up", "party": "R/C", "votes": 3900}]
            }
          ]
        }
        """#)

        #expect(election.year == 2026)
        #expect(election.status == "Unofficial — not yet certified")
        #expect(election.turnout == nil)
        #expect(election.races.count == 1)
    }

    @Test func certifiedCycleCarriesTurnoutAndNoStatus() throws {
        let election = try decodePriorElection(#"""
        {
          "year": 2025,
          "turnoutNote": "7,879 of 24,429 registered voters cast a ballot.",
          "turnout": {"ballots": 7879, "registered": 24429},
          "races": []
        }
        """#)

        #expect(election.status == nil)
        let turnout = try #require(election.turnout)
        #expect(turnout.ballots == 7879)
        #expect(turnout.registered == 24429)
    }

    @Test func turnoutPercentageMatchesThePublishedProse() throws {
        let election = try decodePriorElection(#"""
        {
          "year": 2025,
          "turnoutNote": "7,879 of 24,429 registered voters cast a ballot in the supervisor race (32.3%).",
          "turnout": {"ballots": 7879, "registered": 24429},
          "races": []
        }
        """#)

        // The note rounds to 32.3%; the computed value must agree with the
        // web app's own prose rather than drifting from it.
        let percentage = try #require(election.turnout?.percentage)
        #expect(abs(percentage - 32.25) < 0.01)
        #expect(String(format: "%.1f", percentage) == "32.3")
    }

    @Test func zeroRegisteredVotersYieldsNoPercentageRatherThanInfinity() throws {
        let election = try decodePriorElection(#"""
        {
          "year": 2019,
          "turnoutNote": "Registered total not reported.",
          "turnout": {"ballots": 0, "registered": 0},
          "races": []
        }
        """#)

        #expect(election.turnout?.percentage == nil)
    }

    @Test func aCycleWithNeitherFieldStillDecodes() throws {
        let election = try decodePriorElection(#"""
        {"year": 2017, "turnoutNote": "No structured turnout published.", "races": []}
        """#)

        #expect(election.year == 2017)
        #expect(election.status == nil)
        #expect(election.turnout == nil)
    }
}
