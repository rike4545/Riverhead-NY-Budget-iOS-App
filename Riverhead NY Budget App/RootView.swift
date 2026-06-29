//
//  RootView.swift
//  Riverhead NY Budget App
//
//  Simple root that relies on app-level store injection.
//  Swift 6 • iOS 17+
//

import SwiftUI

@MainActor
struct RootView: View {
    @AppStorage("Riverhead.colorScheme") private var colorSchemeRaw: String = "system"

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemeRaw {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil   // follows system
        }
    }

    var body: some View {
        MainTabView()
            .preferredColorScheme(preferredColorScheme)
    }
}

#Preview {
    RootView()
        .environmentObject(RBCivicToolkitStore())
        .environmentObject(RBSixSigmaStore())
        .environment(RBBudgetStore())
}
