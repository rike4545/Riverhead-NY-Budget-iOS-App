//
//  AnalyticsConsent.swift
//  Riverhead NY Budget App
//
//  Single source of truth for whether first-party Firebase Analytics collection
//  is enabled. The app collects only anonymous, unlinked usage analytics (no
//  ads, no advertising identifier) — but residents can turn even that off here.
//
//  Firebase persists the enabled flag itself, but we mirror it in UserDefaults
//  so the Settings toggle and any pre-Firebase code can read the choice without
//  importing Firebase.
//
//  Swift 6 · iOS 17+
//

import Foundation
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

enum AnalyticsConsent {
    /// UserDefaults key backing the Settings toggle (via @AppStorage).
    static let defaultsKey = "Riverhead.analyticsEnabled"

    /// Analytics is on unless the resident has explicitly opted out, matching
    /// the app's prior default behavior. Reading the raw object (not `bool(forKey:)`)
    /// lets us treat "never set" as the default rather than as `false`.
    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: defaultsKey) as? Bool ?? true
    }

    /// Push the stored preference into Firebase. Safe to call when Firebase is
    /// not linked or not configured — it simply does nothing.
    static func applyStoredPreference() {
        #if canImport(FirebaseAnalytics)
        Analytics.setAnalyticsCollectionEnabled(isEnabled)
        #endif
    }

    /// Persist a new choice and apply it immediately.
    static func set(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: defaultsKey)
        applyStoredPreference()
    }
}
