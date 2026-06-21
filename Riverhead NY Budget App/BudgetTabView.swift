//
//  BudgetTabView.swift
//  Riverhead NY Budget App
//
//  Created by Bryan on 1/20/26.
//


//
//  BudgetTabView.swift
//  Riverhead NY Budget App
//
//  Budget wrapper + resident toolkits.
//  Requires:
//    - .environment(RBBudgetStore())
//    - .environmentObject(RBCivicToolkitStore(...))
//
//  iOS 17+ • Swift 6
//

import SwiftUI
import Observation

@MainActor
struct BudgetTabView: View {

    @Environment(RBBudgetStore.self) private var store
    @EnvironmentObject private var toolkits: RBCivicToolkitStore

    enum Section: Hashable {
        case overview
        case myTaxes
        case deepDive
        case toolkits
    }

    @State private var selection: Section = .overview

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                Picker("Budget Section", selection: $selection) {
                    Text("Overview").tag(Section.overview)
                    Text("My Taxes").tag(Section.myTaxes)
                    Text("Deep Dive").tag(Section.deepDive)
                    Text("Toolkits").tag(Section.toolkits)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

                Divider()

                Group {
                    switch selection {
                    case .overview:
                        BudgetOverviewShiftView()

                    case .myTaxes:
                        MyTaxesView()

                    case .deepDive:
                        BudgetDeepDiveHubView()

                    case .toolkits:
                        CivicToolkitsHubView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Town Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        EnergyPolicyCostDriversView()
                    } label: {
                        Image(systemName: "bolt.badge.a")
                            .accessibilityLabel("Policy Focus Points")
                    }
                }
            }
        }
    }
}

@MainActor
private struct BudgetDeepDiveHubView: View {
    var body: some View {
        List {
            Section("Deep Dive") {
                NavigationLink { BudgetExplainersView() } label: {
                    Label("Plain-English Budget Explainers", systemImage: "rectangle.on.rectangle.angled")
                }
                NavigationLink { BudgetSupplementExplorerView() } label: {
                    Label("Budget Supplement Explorer", systemImage: "doc.text.magnifyingglass")
                }
                NavigationLink { Budget2027ExecutiveWhiteboardView() } label: {
                    Label("2027 Executive Summary", systemImage: "pencil.and.outline")
                }
                NavigationLink { Proposed2027BudgetPresentationView() } label: {
                    Label("Unofficial 2027 Budget Proposal", systemImage: "doc.text.magnifyingglass")
                }
                NavigationLink { Budget2027LabView() } label: {
                    Label("2027 Budget Lab", systemImage: "slider.horizontal.below.sun.max")
                }
                NavigationLink { BudgetSimulator2027View() } label: {
                    Label("2027 Budget Simulator", systemImage: "slider.horizontal.3")
                }
                NavigationLink { DepartmentExpenseExplorerView() } label: {
                    Label("Department Expense Explorer", systemImage: "building.columns.circle")
                }
                NavigationLink { RebalancedSpendingView() } label: {
                    Label("Rebalanced Spending", systemImage: "arrow.left.arrow.right.circle")
                }
                NavigationLink { BudgetAccuracyWatchlistView() } label: {
                    Label("Budget Accuracy Watch List", systemImage: "exclamationmark.triangle")
                }
                NavigationLink { ExpertTabView() } label: {
                    Label("Expert Tools", systemImage: "brain.head.profile")
                }
                NavigationLink { HistoricalTabView() } label: {
                    Label("Historical View", systemImage: "clock.arrow.circlepath")
                }
                NavigationLink { FundBalanceShiftView() } label: {
                    Label("Fund Balance 101", systemImage: "shield.checkerboard")
                }
                NavigationLink { RiverheadFundBalanceAuditView() } label: {
                    Label("Fund Balance Audit View", systemImage: "doc.badge.magnifyingglass")
                }
                NavigationLink { PeerReserveBenchmarkView() } label: {
                    Label("Peer Reserve Comparison", systemImage: "chart.bar.xaxis.ascending")
                }
                NavigationLink { ReserveFundBreakdownView() } label: {
                    Label("Reserve Fund Breakdown", systemImage: "square.3.layers.3d.down.right")
                }
                NavigationLink { FundBalanceTrendView() } label: {
                    Label("Reserve Trend (2014–2025)", systemImage: "chart.line.uptrend.xyaxis")
                }
                NavigationLink { TaxImpactCalculatorView() } label: {
                    Label("Tax Impact Calculator", systemImage: "dollarsign.circle")
                }

                // NEW
                NavigationLink { SixSigmaProcessImprovementShiftView() } label: {
                    Label("Process Improvement (Six Sigma)", systemImage: "arrow.triangle.2.circlepath.circle")
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
