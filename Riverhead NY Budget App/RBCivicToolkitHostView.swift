//
//  RBCivicToolkitHostView.swift
//  Riverhead NY Budget App
//
//  Regenerated — clean host wrapper that relies on the app-level EnvironmentObject.
//  Swift 6 • iOS 17+
//

import SwiftUI

@MainActor
public struct RBCivicToolkitHostView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            GrossEarningsNewsdayView()
        }
    }
}

#Preview {
    RBCivicToolkitHostView()
        .environmentObject(RBCivicToolkitStore())
}
