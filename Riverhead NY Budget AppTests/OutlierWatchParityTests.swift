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
}
