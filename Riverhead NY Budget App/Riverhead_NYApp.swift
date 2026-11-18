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

// This app collects no analytics and contains no third-party SDKs. Firebase /
// Google Analytics was removed deliberately: it never logged a single event, so
// it produced no usable insight while adding an SDK, a network dependency, and
// App Privacy disclosures to a civic-transparency app.
@MainActor
private final class RiverheadAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        true
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
                .task { DataWarmup.start() }
        }
    }
}
