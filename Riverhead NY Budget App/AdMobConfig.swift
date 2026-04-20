import Foundation

enum AdMobConfig {
    static let appID = "ca-app-pub-9917450718827221~2743419962"
    static let productionBannerAdUnitID = "ca-app-pub-9917450718827221/4842861895"
    static let testBannerAdUnitID = "ca-app-pub-3940256099942544/2435281174"

    // Keep debug builds on Google's test inventory unless explicitly overridden.
    static var bannerAdUnitID: String {
        #if DEBUG
        if ProcessInfo.processInfo.environment["USE_LIVE_ADMOB"] == "1" {
            return productionBannerAdUnitID
        }
        return testBannerAdUnitID
        #else
        return productionBannerAdUnitID
        #endif
    }
}


extension AdMobConfig {
    static var isUsingTestBanner: Bool { bannerAdUnitID == testBannerAdUnitID }
}
