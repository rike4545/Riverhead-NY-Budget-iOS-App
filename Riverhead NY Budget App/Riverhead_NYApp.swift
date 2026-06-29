//
//  Riverhead_NYApp.swift
//  Riverhead NY Budget App
//
//  Compile-safe app entrypoint.
//  Injects:
//    - RBCivicToolkitStore as EnvironmentObject (ObservableObject)
//    - RBSixSigmaStore as EnvironmentObject (ObservableObject)
//    - RBBudgetStore via Observation environment (if your store is @Observable)
//
//  NOTE ON YOUR COMPILER ERROR:
//  If you previously wrote `$civicStore.ensureTownSquareProjectPresent()` anywhere,
//  remove the `$` - `$civicStore` is a Binding/projection and cannot call methods.
//
//  Swift 6 - iOS 17+
//

import SwiftUI
import AppTrackingTransparency

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@MainActor
private final class RiverheadAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        configureFirebaseIfPossible()
        // GAD starts after ATT is resolved (see requestTrackingAndStartAds).
        // We call start here as well so ads can load on iOS < 14 or if ATT
        // is already determined (e.g., returning users).
        configureGoogleMobileAdsIfPossible()
        return true
    }

    // Called from the scene after the first frame has appeared so the ATT
    // prompt has a visible window to attach to.
    func requestTrackingAndStartAds() {
        guard #available(iOS 14, *) else {
            configureGoogleMobileAdsIfPossible()
            return
        }
        let status = ATTrackingManager.trackingAuthorizationStatus
        guard status == .notDetermined else {
            // Already determined — nothing to prompt, GAD already started.
            return
        }
        ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
            // Re-start (or confirm start) after the user responds.
            // GADMobileAds.start is idempotent.
            DispatchQueue.main.async {
                self?.configureGoogleMobileAdsIfPossible()
            }
        }
    }

    private func configureFirebaseIfPossible() {
        #if canImport(FirebaseCore)
        guard FirebaseApp.app() == nil else { return }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else { return }
        FirebaseApp.configure()
        #endif
    }

    private func configureGoogleMobileAdsIfPossible() {
        #if canImport(GoogleMobileAds)
        guard Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") != nil else { return }
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        #endif
    }
}

@main
@MainActor
struct Riverhead_NYApp: App {
    @UIApplicationDelegateAdaptor(RiverheadAppDelegate.self) private var appDelegate

    @StateObject private var civicStore = RBCivicToolkitStore()

    // Needed for SixSigmaProcessImprovementShiftView (@EnvironmentObject RBSixSigmaStore)
    @StateObject private var sixSigmaStore = RBSixSigmaStore()

    // If RBBudgetStore is @Observable, `.environment(budgetStore)` is correct.
    // If it is ObservableObject, switch this to @StateObject + .environmentObject.
    @State private var budgetStore = RBBudgetStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(civicStore)
                .environmentObject(sixSigmaStore)
                .environment(budgetStore)
                .onAppear {
                    // Delay one frame so the window is visible before the ATT sheet appears.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        appDelegate.requestTrackingAndStartAds()
                    }
                }
        }
    }
}
