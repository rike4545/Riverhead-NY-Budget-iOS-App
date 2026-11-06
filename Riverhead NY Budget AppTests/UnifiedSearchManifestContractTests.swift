import Foundation
import Testing
@testable import Riverhead_NY_Budget_App

/// The search manifest publishes a `sha256` per shard that the Swift decoder
/// had no property for. It now does, and it is used as a cache key: shards are
/// fetched with `.returnCacheDataElseLoad`, which on its own serves a cached
/// copy indefinitely and would keep answering searches from a superseded index.
struct UnifiedSearchManifestContractTests {
    @Test func manifestDecodesShardContentHashes() throws {
        let json = #"""
        {
          "version": 2,
          "total": 4752,
          "shards": {
            "line-item": {"url": "line-item.json", "count": 848, "bytes": 138482, "sha256": "0996b2e8f3940d20"},
            "payroll":   {"url": "payroll.json",   "count": 1228, "bytes": 273240, "sha256": "e342214319188fa6"}
          }
        }
        """#

        let manifest = try JSONDecoder().decode(
            RiverheadSearchManifest.self,
            from: Data(json.utf8)
        )

        #expect(manifest.version == 2)
        let lineItem = try #require(manifest.shards["line-item"])
        #expect(lineItem.sha256 == "0996b2e8f3940d20")
        #expect(lineItem.count == 848)
    }

    /// `sha256` is optional so that a manifest published before the hashes
    /// existed still loads. If this ever becomes non-optional, an older
    /// manifest throws and search returns nothing with no error on screen.
    @Test func olderManifestWithoutHashesStillDecodes() throws {
        let json = #"""
        {
          "version": 1,
          "total": 19,
          "shards": {"fund": {"url": "fund.json", "count": 19, "bytes": 2946}}
        }
        """#

        let manifest = try JSONDecoder().decode(
            RiverheadSearchManifest.self,
            from: Data(json.utf8)
        )

        let fund = try #require(manifest.shards["fund"])
        #expect(fund.sha256 == nil)
        #expect(fund.url == "fund.json")
    }
}
