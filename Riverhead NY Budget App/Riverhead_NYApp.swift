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

#if canImport(FirebaseCore)
import FirebaseCore
#endif

@MainActor
private final class RiverheadAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        configureFirebaseIfPossible()
        return true
    }

    private func configureFirebaseIfPossible() {
        #if canImport(FirebaseCore)
        guard FirebaseApp.app() == nil else { return }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else { return }
        FirebaseApp.configure()
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
        }
    }
}
