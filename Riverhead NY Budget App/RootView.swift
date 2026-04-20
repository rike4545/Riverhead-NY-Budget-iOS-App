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
    var body: some View {
        MainTabView()
    }
}

#Preview {
    RootView()
        .environmentObject(RBCivicToolkitStore())
        .environmentObject(RBSixSigmaStore())
        .environment(RBBudgetStore())
}
