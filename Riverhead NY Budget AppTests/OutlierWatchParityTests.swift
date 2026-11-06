import Foundation
import Testing
@testable import Riverhead_NY_Budget_App

struct OutlierWatchParityTests {
    @Test func requiresBothWebThresholds() {
        #expect(OutlierWatchParityLogic.percentThreshold == 20)
        #expect(OutlierWatchParityLogic.dollarThreshold == 100_000)

        #expect(OutlierWatchParityLogic.isOutlier(dollarChange: 150_000, percentChange: 25))
        #expect(!OutlierWatchParityLogic.isOutlier(dollarChange: 90_000, percentChange: 25))
        #expect(!OutlierWatchParityLogic.isOutlier(dollarChange: 150_000, percentChange: 19.9))
        #expect(!OutlierWatchParityLogic.isOutlier(dollarChange: 150_000, percentChange: nil))
    }

    @Test func thresholdsUseAbsoluteChange() {
        #expect(OutlierWatchParityLogic.isOutlier(dollarChange: -250_000, percentChange: -30))
    }

    /// `OutlierHistoryDocument` is private to the view, so this mirrors the
    /// published shape the way the other contract tests do. It pins the five
    /// keys the drift check found unread: the per-fund span figures and the
    /// town-wide totals. The view derives year-over-year changes itself; these
    /// are first-to-last across the whole range, which is a different measure.
    @Test func fundAppropriationsHistoryCarriesSpanAndTownTotals() throws {
        let json = #"""
        {
          "source": {"title": "Adopted budgets", "url": "https://example.invalid/"},
          "note": "Normalized fund appropriations.",
          "years": [2020, 2026],
          "townTotals": {
            "2020": {"appropriations": 100390400, "fundCount": 19},
            "2026": {"appropriations": 121110904, "fundCount": 19}
          },
          "funds": [
            {
              "code": "A01",
              "name": "General Fund",
              "years": {"2020": {"appropriations": 51359400}, "2026": {"appropriations": 69113159}},
              "firstYear": 2020,
              "lastYear": 2026,
              "totalChange": 17753759,
              "totalChangePct": 34.6
            }
          ]
        }
        """#

        struct TownTotal: Decodable { let appropriations: Double; let fundCount: Int }
        struct FundYear: Decodable { let appropriations: Double }
        struct Fund: Decodable {
            let code: String
            let years: [String: FundYear]
            let firstYear: Int?
            let lastYear: Int?
            let totalChange: Double?
            let totalChangePct: Double?
        }
        struct File: Decodable {
            let years: [Int]
            let townTotals: [String: TownTotal]?
            let funds: [Fund]
        }

        let decoded = try JSONDecoder().decode(File.self, from: Data(json.utf8))

        let fund = try #require(decoded.funds.first)
        #expect(fund.firstYear == 2020)
        #expect(fund.lastYear == 2026)
        #expect(fund.totalChange == 17_753_759)
        #expect(fund.totalChangePct == 34.6)

        // The span figures must describe the same two endpoints the `years`
        // map carries, or the row would caption one range with another's total.
        let first = try #require(fund.years["2020"]?.appropriations)
        let last = try #require(fund.years["2026"]?.appropriations)
        #expect(abs((last - first) - 17_753_759) < 0.5)

        let totals = try #require(decoded.townTotals)
        #expect(totals["2020"]?.fundCount == 19)
        let townFirst = try #require(totals["2020"]?.appropriations)
        let townLast = try #require(totals["2026"]?.appropriations)
        #expect(townLast > townFirst)
    }

    /// Every added field is optional, so a payload published before they
    /// existed must still decode rather than taking the screen to its web
    /// fallback.
    @Test func historyWithoutSpanFieldsStillDecodes() throws {
        let json = #"""
        {"years": [2020], "funds": [{"code": "A01", "years": {"2020": {"appropriations": 1}}}]}
        """#

        struct FundYear: Decodable { let appropriations: Double }
        struct Fund: Decodable {
            let code: String
            let years: [String: FundYear]
            let firstYear: Int?
            let totalChangePct: Double?
        }
        struct File: Decodable { let funds: [Fund]; let townTotals: [String: [String: Double]]? }

        let decoded = try JSONDecoder().decode(File.self, from: Data(json.utf8))
        #expect(decoded.townTotals == nil)
        #expect(decoded.funds.first?.firstYear == nil)
        #expect(decoded.funds.first?.totalChangePct == nil)
    }
}
