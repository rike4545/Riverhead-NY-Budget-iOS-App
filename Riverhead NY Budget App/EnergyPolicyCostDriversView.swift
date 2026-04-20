//
//  EnergyPolicyCostDriversView.swift
//  Riverhead NY Budget App
//
//  Compatibility wrapper.
//  BudgetTabView references EnergyPolicyCostDriversView; the real implementation
//  lives in BudgetPolicyInsightsView (Energy-only policy + cost drivers).
//
//  Swift 6 • iOS 17+
//

import SwiftUI

@MainActor
struct EnergyPolicyCostDriversView: View {
    var body: some View {
        BudgetPolicyInsightsView(initialFocus: .all)
    }
}
