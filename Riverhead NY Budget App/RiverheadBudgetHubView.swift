//
//  RiverheadBudgetHubView.swift
//  Riverhead NY Budget App
//
//  Swift 6 / iOS 17+
//  High-level hub for resident + expert budget tools.
//  - Audience toggle (Resident / Expert)
//  - Sections: Overview, My Taxes, Fund Balance, Capital & Debt,
//              Outliers, Employees, Glossary, Hearing Toolkit
//
//  BudgetAudienceMode and BudgetSection are defined in BudgetAudienceMode.swift
//

import SwiftUI
import Charts

// MARK: - Root Hub View

@MainActor
struct RiverheadBudgetHubView: View {
    @AppStorage("Riverhead.budgetMode")
    private var modeRaw: String = BudgetAudienceMode.resident.rawValue

    @State private var section: BudgetSection = .overview

    @Environment(\.colorScheme) private var scheme

    private var mode: BudgetAudienceMode {
        BudgetAudienceMode(rawValue: modeRaw) ?? .resident
    }

    private var primarySections: [BudgetSection] {
        [.myTaxes, .overview, .proposed2027Budget, .fundBalance, .capitalDebt, .tools]
    }

    var body: some View {
        ZStack {
            RiverheadTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 12) {
                hubHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                sectionChips

                Divider()
                    .opacity(0.35)
                    .padding(.horizontal, 16)

                if section == .supplementExplorer {
                    BudgetSupplementExplorerView()
                } else if section == .budget2027Summary {
                    Budget2027ExecutiveWhiteboardView()
                } else if section == .proposed2027Budget {
                    Proposed2027BudgetPresentationView()
                } else if section == .budget2027 {
                    Budget2027LabView()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            switch section {
                            case .overview:
                                OverviewStoryView(mode: mode)
                            case .supplementExplorer:
                                EmptyView()
                            case .budget2027Summary:
                                EmptyView()
                            case .proposed2027Budget:
                                EmptyView()
                            case .budget2027:
                                EmptyView()
                            case .executiveSummary:
                                ExecutiveBudgetSummaryView(mode: mode)
                            case .myTaxes:
                                MyTaxesLabView(mode: mode)
                            case .fundBalance:
                                FundBalanceDashboardView(mode: mode)
                            case .capitalDebt:
                                CapitalDebtExplorerView(mode: mode)
                            case .outliers:
                                OutlierWatchView(mode: mode)
                            case .employees:
                                EmployeesHubSectionView(mode: mode)
                            case .tools:
                                BudgetToolsDirectoryView(section: $section, mode: mode)
                            case .glossary:
                                BudgetGlossaryView(mode: mode)
                            case .hearing:
                                HearingToolkitView(mode: mode)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationTitle("Budget")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(
            RiverheadTheme.Surface.card.opacity(scheme == .dark ? 0.95 : 1.0),
            for: .navigationBar
        )
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section("Detail Level") {
                        ForEach(BudgetAudienceMode.allCases) { m in
                            Button {
                                modeRaw = m.rawValue
                            } label: {
                                Label(
                                    m == mode ? "\(m.label) ✓" : m.label,
                                    systemImage: m == .resident ? "person.fill" : "brain.head.profile"
                                )
                            }
                        }
                    }
                } label: {
                    Label(mode == .resident ? "Resident" : "Expert", systemImage: "slider.horizontal.3")
                        .font(.footnote.weight(.semibold))
                        .accessibilityLabel("Budget detail level: \(mode.label)")
                        .accessibilityHint("Tap to switch between Resident plain-language view and Expert detailed view.")
                }
            }
        }
    }

    // MARK: - Hero Header

    private var hubHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Riverhead Town Budget")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)

                Text("Pick what you want to know — your taxes, where money goes, or what to ask at a meeting.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                quickStartChip("My tax bill", symbol: "house.and.flag.fill") {
                    section = .myTaxes
                }
                quickStartChip("Where $ goes", symbol: "chart.pie.fill") {
                    section = .overview
                }
                quickStartChip("2027 plan", symbol: "doc.text.fill") {
                    section = .proposed2027Budget
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    RiverheadTheme.primaryBlue.opacity(0.98),
                    RiverheadTheme.brandSky.opacity(0.86),
                    RiverheadTheme.brandMint.opacity(0.68)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 6) {
                ForEach(0..<8, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.white.opacity(index.isMultiple(of: 2) ? 0.22 : 0.11))
                        .frame(width: 8, height: CGFloat(16 + index * 4))
                }
            }
            .padding(16)
            .accessibilityHidden(true)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(
            color: RiverheadTheme.cardShadow(scheme, elevated: true),
            radius: 18,
            x: 0,
            y: 10
        )
    }

    // MARK: - UI pieces

    private func quickStartChip(_ label: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.caption2)
                    .accessibilityHidden(true)
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.18), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.30), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint("Jumps to the \(label) section of the budget.")
    }

    private var sectionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(primarySections) { sec in
                    Button {
                        section = sec
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: sec.symbolName)
                                .font(.footnote)
                                .accessibilityHidden(true)
                            Text(sec.label)
                                .font(.footnote.weight(.medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Group {
                                if section == sec {
                                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    RiverheadTheme.accent.opacity(0.24),
                                                    RiverheadTheme.brandTeal.opacity(0.18)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                                        .fill(RiverheadTheme.Surface.elevated.opacity(scheme == .dark ? 0.82 : 0.96))
                                }
                            }
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    (section == sec
                                     ? RiverheadTheme.accent
                                     : RiverheadTheme.border
                                    ).opacity(0.35),
                                    lineWidth: 0.8
                                )
                        )
                        .foregroundStyle(
                            section == sec
                            ? RiverheadTheme.accent
                            : RiverheadTheme.textPrimary
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(sec.label)
                    .accessibilityAddTraits(section == sec ? [.isSelected] : [])
                    .accessibilityHint(section == sec ? "Currently selected" : "Tap to open \(sec.label)")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Reusable glass card

fileprivate struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let title: String?
    let subtitle: String?
    @ViewBuilder var content: Content

    init(
        title: String? = nil,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.textPrimary)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)
            }

            content
        }
        .padding(14)
        .background(
            (reduceTransparency
             ? AnyShapeStyle(RiverheadTheme.Surface.card)
             : AnyShapeStyle(scheme == .dark ? .ultraThinMaterial : .regularMaterial)),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.border.opacity(scheme == .dark ? 0.35 : 0.2))
        )
        .shadow(color: .black.opacity(scheme == .dark ? 0.25 : 0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Budget tools directory

fileprivate enum BudgetToolDestination {
    case section(BudgetSection)
    case budgetSimulator
    case earlyRetirementModel
    case spendingReduction
    case communityPreservationFund
}

fileprivate struct BudgetToolShortcut: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String
    let destination: BudgetToolDestination
}

fileprivate struct BudgetToolGroup: Identifiable {
    let title: String
    let shortcuts: [BudgetToolShortcut]

    var id: String { title }
}

fileprivate struct BudgetToolsDirectoryView: View {
    @Binding var section: BudgetSection
    let mode: BudgetAudienceMode

    private let groups: [BudgetToolGroup] = [
        .init(
            title: "2027 Planning",
            shortcuts: [
                .init(title: "Budget Message", subtitle: "Unofficial proposal, levy target, surplus plan, and risks.", symbol: "doc.text.magnifyingglass", destination: .section(.proposed2027Budget)),
                .init(title: "Early Retirement Model", subtitle: "What-if savings, payout, public questions, and reserve impact.", symbol: "person.3.sequence.fill", destination: .earlyRetirementModel),
                .init(title: "Executive Summary", subtitle: "Whiteboard-style summary of the current 2027 framework.", symbol: "pencil.and.outline", destination: .section(.budget2027Summary)),
                .init(title: "Budget Lab", subtitle: "Scenario controls for revenues, expenses, and tradeoffs.", symbol: "slider.horizontal.below.sun.max.fill", destination: .section(.budget2027)),
                .init(title: "Budget Simulator", subtitle: "Interactive 2027 budget modeling.", symbol: "slider.horizontal.3", destination: .budgetSimulator),
                .init(title: "Spending Reduction", subtitle: "Toggle a real, sourced \(Budget2027TaxCapOffsetModel.fullRecurringReductionPackage.formatted(.currency(code: "USD").precision(.fractionLength(0)))) savings package against the modeled payroll-pressure gap.", symbol: "scissors.circle", destination: .spendingReduction)
            ]
        ),
        .init(
            title: "Evidence And Detail",
            shortcuts: [
                .init(title: "Supplement Explorer", subtitle: "Annual report, surplus, tax-cut, and labor-pressure details.", symbol: "doc.text.magnifyingglass", destination: .section(.supplementExplorer)),
                .init(title: "Outliers", subtitle: "Budget accuracy, variances, and unusual lines.", symbol: "exclamationmark.triangle.fill", destination: .section(.outliers)),
                .init(title: "Employees", subtitle: "Payroll and public earnings views.", symbol: "person.2.fill", destination: .section(.employees)),
                .init(title: "Glossary", subtitle: "Plain-language definitions for budget terms.", symbol: "text.book.closed.fill", destination: .section(.glossary))
            ]
        ),
        .init(
            title: "Public Review",
            shortcuts: [
                .init(title: "Hearing Toolkit", subtitle: "Questions, comments, and review prompts.", symbol: "person.2.wave.2.fill", destination: .section(.hearing)),
                .init(title: "Capital And Debt", subtitle: "Projects, borrowing, BANs, and debt pressure.", symbol: "building.columns.fill", destination: .section(.capitalDebt)),
                .init(title: "Fund Balance", subtitle: "Reserve levels, policy targets, and surplus context.", symbol: "banknote.fill", destination: .section(.fundBalance)),
                .init(title: "Tax Impact", subtitle: "Resident-facing tax view and assumptions.", symbol: "house.and.flag.fill", destination: .section(.myTaxes)),
                .init(title: "Community Preservation Fund", subtitle: "The CPF's real revenue swings, debt, and the rate-increase question.", symbol: "leaf.fill", destination: .communityPreservationFund)
            ]
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassCard(title: "More Budget Tools", subtitle: directorySubtitle) {
                HStack(spacing: 8) {
                    ForEach(["2027 Planning", "Evidence", "Public Review"], id: \.self) { label in
                        Text(label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.brandNavy)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(RiverheadTheme.brandSky.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }

            ForEach(groups) { group in
                GlassCard(title: group.title, subtitle: nil) {
                    VStack(spacing: 0) {
                        ForEach(group.shortcuts) { shortcut in
                            toolShortcutRow(shortcut)
                        }
                    }
                }
            }
        }
    }

    private var directorySubtitle: String {
        switch mode {
        case .resident:
            return "More tools, grouped by what you're trying to figure out."
        case .expert:
            return "Models, source trails, and review tools grouped by budget purpose."
        }
    }

    @ViewBuilder
    private func toolShortcutRow(_ shortcut: BudgetToolShortcut) -> some View {
        switch shortcut.destination {
        case .budgetSimulator:
            NavigationLink {
                BudgetSimulator2027View()
            } label: {
                rowContent(shortcut)
            }
            .buttonStyle(.plain)
        case .earlyRetirementModel:
            NavigationLink {
                EarlyRetirementIncentiveView()
            } label: {
                rowContent(shortcut)
            }
            .buttonStyle(.plain)
        case .spendingReduction:
            NavigationLink {
                Budget2027SpendingReductionView()
            } label: {
                rowContent(shortcut)
            }
            .buttonStyle(.plain)
        case .communityPreservationFund:
            NavigationLink {
                CommunityPreservationFundView()
            } label: {
                rowContent(shortcut)
            }
            .buttonStyle(.plain)
        case .section(let destination):
            Button {
                section = destination
            } label: {
                rowContent(shortcut)
            }
            .buttonStyle(.plain)
        }
    }

    private func rowContent(_ shortcut: BudgetToolShortcut) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: shortcut.symbol)
                .font(.headline)
                .foregroundStyle(RiverheadTheme.brandNavy)
                .frame(width: 34, height: 34)
                .background(Circle().fill(RiverheadTheme.brandSky.opacity(0.14)))

            VStack(alignment: .leading, spacing: 3) {
                Text(shortcut.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                Text(shortcut.subtitle)
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 10)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RiverheadTheme.textSecondary)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(RiverheadTheme.softBorder.opacity(0.6))
                .frame(height: 1)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Sources bar

struct BudgetSourceLink: Identifiable {
    enum Kind {
        case budgetBook
        case localLaw
        case resolution
        case other
    }

    let id = UUID()
    let title: String
    let kind: Kind
    let note: String?
    let url: URL?
}

fileprivate struct SourcesStrip: View {
    let links: [BudgetSourceLink]

    var body: some View {
        if links.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(links) { link in
                        if let url = link.url {
                            Link(destination: url) {
                                pill(label: link.title, kind: link.kind)
                            }
                        } else {
                            pill(label: link.title, kind: link.kind)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func pill(label: String, kind: BudgetSourceLink.Kind) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon(for: kind))
                .font(.caption)
            Text(label)
                .font(.caption2.weight(.medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RiverheadTheme.Surface.card.opacity(0.9))
        .clipShape(Capsule())
        .foregroundStyle(RiverheadTheme.textPrimary)
    }

    private func icon(for kind: BudgetSourceLink.Kind) -> String {
        switch kind {
        case .budgetBook: return "doc.text.magnifyingglass"
        case .localLaw:   return "scroll.fill"
        case .resolution: return "doc.plaintext.fill"
        case .other:      return "link"
        }
    }
}

// MARK: - 1) Overview (story cards)

fileprivate struct OverviewStoryCard: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let blurb: String
    let tag: String
}

fileprivate struct BudgetRecommendationLine: Identifiable {
    let id = UUID()
    let title: String
    let impact: String
    let detail: String
}

fileprivate struct BudgetRecommendationGroup: Identifiable {
    let title: String
    let icon: String
    let tint: Color
    let lines: [BudgetRecommendationLine]

    var id: String { title }
}

fileprivate struct BudgetCorrectionLine: Identifiable {
    let id = UUID()
    let title: String
    let status: String
    let detail: String
}

fileprivate struct BudgetRevenueLine: Identifiable {
    let id = UUID()
    let title: String
    let amount: Double
    let detail: String
}

fileprivate struct BudgetImplementationPhase: Identifiable {
    let id = UUID()
    let title: String
    let horizon: String
    let detail: String
    let items: [String]
}

fileprivate struct BudgetFundingStrategyLine: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

fileprivate struct BudgetVisualAmount: Identifiable {
    let id = UUID()
    let title: String
    let amount: Double
    let tint: Color
    let systemImage: String
}

fileprivate struct BudgetPlanStep: Identifiable {
    let id = UUID()
    let title: String
    let amount: Double
    let tint: Color
}

fileprivate struct ExecutiveSummaryMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let caption: String
    let symbol: String
    let tint: Color
}

fileprivate struct ExecutiveFundMixSlice: Identifiable {
    let id = UUID()
    let fundCode: String
    let fundName: String
    let amount: Double
    let tint: Color
}

fileprivate struct ExecutiveBridgeItem: Identifiable {
    let id = UUID()
    let label: String
    let amount: Double
    let role: String
    let tint: Color
}

fileprivate enum BudgetRecommendations2027 {
    static let trackedPayrollRows2026 = 328
    static let modeledPersonnelBase2026 = 30_509_083.85
    static let totalBudget2026 = 69_113_159.00
    static let personnelShareOfBudget = 0.4414
    static let modeledAutomaticPayrollPressure = Budget2027ScenarioModel.modeledAutomaticPayrollPressure
    static let modeledUnionSalaryPressure = modeledPBAIncrease + modeledSOAIncrease + modeledCSEAIncrease
    static let modeledPBAIncrease = Budget2027ScenarioModel.modeledPBAIncreaseAtDefaultCOLA
    static let modeledSOAIncrease = Budget2027ScenarioModel.modeledSOAIncreaseAtDefaultCOLA
    static let modeledCSEAIncrease = Budget2027ScenarioModel.modeledCSEAIncrease
    static let modeledExemptIncrease = Budget2027ScenarioModel.modeledNonContractIncreaseAtDefaultCOLA
    static let gfoaMinimumReservePercent = 2.0 / 12.0
    static let fundBalancePolicyFloorPercent = 0.15
    static let fundBalancePolicyOperatingTargetPercent = 0.20
    static let fundBalancePolicyDeploymentCapPercent = 0.25
    // Matches RBBudgetStore.estimatedFundBalance: the 2025 Annual Financial Report's actual unassigned
    // General Fund balance ($29,671,084.17), the newest year-end figure available.
    static let modeledUnassignedFundBalance2026 = 29_671_084.00
    static let cpfOutstandingDebt2024 = 12_290_000.00
    static let cpfAccelerationPayment = 2_000_000.00

    static let modeledEligibleHealthcarePositions = Budget2027TaxCapOffsetModel.modeledEligibleHealthcarePositions
    static let nyshipPlanPrimeIndividualMonthlyPremium = Budget2027TaxCapOffsetModel.nyshipPlanPrimeIndividualMonthlyPremium
    static let nyshipPlanPrimeFamilyMonthlyPremium = 3_663.79
    static let modeledAveragePremium = Budget2027TaxCapOffsetModel.modeledAveragePremium
    static let healthcareContributionSavings = Budget2027TaxCapOffsetModel.healthcareContributionSavings
    static let exemptRaiseHoldSavings = Budget2027TaxCapOffsetModel.exemptRaiseHoldSavings
    static let electedRaiseHoldSavings = Budget2027TaxCapOffsetModel.electedRaiseHoldSavings
    static let policeUniformOTActual2024 = Budget2027TaxCapOffsetModel.policeUniformOTActual2024
    static let policeUniformOTBudget2024 = Budget2027TaxCapOffsetModel.policeUniformOTBudget2024
    static let policeUniformOTAdopted2026 = Budget2027TaxCapOffsetModel.policeUniformOTAdopted2026
    static let policeUniformOTVariance = Budget2027TaxCapOffsetModel.policeUniformOTVariance
    static let overtimeControlSavings = Budget2027TaxCapOffsetModel.overtimeControlSavings
    static let policeOvertimeRecoveryShare = Budget2027TaxCapOffsetModel.policeOvertimeRecoveryShare
    static let march2026CriminalIncidents = 167
    static let march2025CriminalIncidents = 144
    static let march2026TotalIncidents = 2_994
    static let march2025TotalIncidents = 2_922
    static let march2026DomesticIncidents = 60
    static let march2025DomesticIncidents = 60
    static let march2026Accidents = 114
    static let march2025Accidents = 123
    static let march2026Summonses = 1_042
    static let march2025Summonses = 1_076
    static let civilianVacancyFactorSavings = Budget2027TaxCapOffsetModel.civilianVacancyFactorSavings
    static let targetedRetirementRefillSavings = Budget2027TaxCapOffsetModel.targetedRetirementRefillSavings
    // Canonical recurring savings package total - computed as the sum of the six categories above so it
    // can never drift out of sync with them the way a separately hardcoded figure could.
    static let quantifiedPackageSavings = Budget2027TaxCapOffsetModel.recurringSavingsPackageTotal
    static let remainingRecurringGap = modeledAutomaticPayrollPressure - quantifiedPackageSavings
    static let latestLocalGeneralFundLevy = 48_639_479.00
    static let taxCapLevyIncreaseRate = 0.02
    static let taxCapLevyIncreaseRevenue = 972_789.58
    static let modeledRevenuePackage = 1_034_289.58
    static let balanceAfterRevenuePackage = modeledRevenuePackage - remainingRecurringGap
    static let buildingDepartmentHeadcountInvestment = Budget2027ScenarioModel.buildingDepartmentHeadcountInvestment
    static let onlinePlatformUpdateCost = Budget2027ScenarioModel.onlinePlatformUpdateCost
    static let codeEnforcementOfficerCost = Budget2027ScenarioModel.codeEnforcementOfficerCost
    static let deputyTownClerkCost = Budget2027ScenarioModel.deputyTownClerkCost
    static let policeOfficerCost = Budget2027ScenarioModel.policeOfficerCost
    static let communityImprovementGrantSeries = 50_000.00
    // Illustrative one-time grant amounts, sized like the deployment plan's other
    // single-nonprofit grants - not an official Town commitment or budget line.
    static let communityBlockGrants: [CommunityGrant] = [
        .init(organization: "Legal Aid Society of Suffolk County", focus: "Civil legal services for low-income Suffolk County residents", amount: 15_000),
        .init(organization: "Helping Hands of the East End", focus: "Emergency assistance for East End families and individuals in crisis", amount: 10_000),
        .init(organization: "RISE", focus: "Long Island community and social-services nonprofit", amount: 10_000),
        .init(organization: "Long Island Housing Partnership (LIHP)", focus: "Regional affordable-housing development and homebuyer counseling", amount: 15_000),
    ]
    static let communityBlockGrantsTotal = communityBlockGrants.reduce(0) { $0 + $1.amount }
    // Canonical recurring service-investment total, shared with Budget2027ScenarioModel so both models
    // stay in sync (excludes the one-time community-improvement and Legal Aid grants below).
    static let addedServiceInvestments = Budget2027ScenarioModel.recurringServiceInvestmentsTotal
    static let balanceAfterRevenueAndInvestments = balanceAfterRevenuePackage - addedServiceInvestments

    static let residentSummary = "The 2027 budget should be built around a simple promise: cover salary pressure, protect core services, and keep reserves as a backstop rather than a habit. Riverhead can still invest in Building, Code Enforcement, and service delivery, but only if the recurring plan is honest about labor costs, disciplined about savings, and careful with the tax levy."

    static let expertSummary = "The current 2027 model starts with about $936.7K of automatic payroll pressure, including about $907.9K of union salary growth and a fixed approved CSEA 2027 action, then adds a published-rate pension pressure range of about $1.4M to $1.85M townwide. The best 2027 framework is therefore a structurally balanced recurring package first, explicit service investments second, elected raises held out of the baseline, and reserve deployment only for one-time transition, capital, or debt purposes under a tighter fund-balance rule."

    static let residentLines: [BudgetRecommendationLine] = [
        .init(
            title: "Budget union raises in the open",
            impact: "Transparency",
            detail: "Show residents how much of the 2027 cost increase comes from union wage growth in the PBA, SOA, and CSEA units, instead of letting those increases disappear into a broader payroll line."
        ),
        .init(
            title: "Require a 20% healthcare premium contribution",
            impact: "Fairness",
            detail: "Adopt a policy that senior staff and elected officials pay at least 20% of their health insurance premium beginning in 2027, instead of carrying the full cost on taxpayers."
        ),
        .init(
            title: "Deploy a better fund balance policy",
            impact: "Transparency",
            detail: "Keep a hard 15% local minimum, recognize the GFOA-style two-month benchmark as roughly 17% of operations, manage toward a normal Riverhead operating band above that floor, and require any use above 25% of appropriations to be tied to one-time capital, debt reduction, or tax stabilization with a public rebuild plan."
        ),
        .init(
            title: "Tie spending growth to the Town's real growth rate",
            impact: "Accountability",
            detail: "Adopt a Brookhaven-style operating-budget trigger so Town-Wide General Fund spending does not rise faster than the three-year average of revenue growth plus the three-year average population growth rate, unless the Town Board makes a supermajority finding to exceed it."
        ),
        .init(
            title: "Use excess fund balance to cut CPF principal and interest",
            impact: "Fairness",
            detail: "Riverhead should use a portion of excess fund balance above its operating target to make a one-time CPF principal reduction and lower future interest cost. RiverheadLOCAL reported on March 5, 2026 that the Town took in about $7.03M of CPF revenue in 2025, more than $110M over the life of the program, and still had about $12.29M of CPF debt outstanding as of December 31, 2024. The debt is still scheduled to run through 2030, with nearly $3M a year now going to principal and interest before falling below $2M by 2028. OSC's February 2024 CPF audit also found Riverhead's CPF disbursements and debt service were proper and supported, while the weakness was on collection logging and deposit timing. That makes CPF debt reduction a strong use of one-time surplus so long as the Town also tightens cash-receipt controls."
        ),
        .init(
            title: "Create a Community Housing Fund Advisory Board",
            impact: "Accountability",
            detail: "If Riverhead adopts the 0.5% Community Housing Fund, pair it with a public advisory board so residents, housing practitioners, and local stakeholders can help review priorities, track outcomes, and keep spending aligned with real community need."
        ),
        .init(
            title: "Create a Battery Energy Storage Steering Committee",
            impact: "Transparency",
            detail: "If battery energy storage proposals are moving toward Riverhead, create a steering committee with neighborhood, emergency-management, planning, environmental, and technical voices so policy discussions happen in the open before projects outrun public trust."
        ),
        .init(
            title: "Require exact budget-line citations in new legislation",
            impact: "Transparency",
            detail: "Any new local law, resolution, or policy with a fiscal impact should name the exact budget line being debited or credited, so residents can see precisely where money is moving instead of getting only a general cost estimate."
        ),
        .init(
            title: "Show levy, reserves, and tax impact on one page",
            impact: "Transparency",
            detail: "Borrow a practical cue from East Hampton's 2026 adopted budget: put the levy calculation, applied fund balance, reserve use, and simple homeowner tax-impact examples together in one visible summary so Riverhead residents can see how the final number was built."
        ),
        .init(
            title: "Balance the major districts before using fund balance",
            impact: "Accountability",
            detail: "Brookhaven's 2026 adopted budget states that its major tax districts are structurally balanced without using fund balance in those districts. Riverhead should adopt the same discipline for its core operating funds before treating reserves as a solution."
        ),
        .init(
            title: "Require a Schedule of Fund Balance and Projections with every budget",
            impact: "Transparency",
            detail: "Every Riverhead tentative and adopted budget should include a clearly labeled Schedule of Fund Balance and Projections so residents can see beginning balance, planned appropriations, projected year-end balance, and how policy changes affect reserves over time."
        ),
        .init(
            title: "Acknowledge Riverhead's 15% reserve history openly",
            impact: "Transparency",
            detail: "The Town Board's December 5, 2006 agenda included Resolution #1101, 'Adoption of a Fund Balance Policy of the General Fund,' and later audit reports reference a 15% General Fund policy by resolution. That history matters because Riverhead's assigned and unassigned General Fund balance now sits above 40% of annual spending, far beyond that earlier floor."
        ),
        .init(
            title: "Hold noncontractual salary growth",
            impact: "Accountability",
            detail: "Freeze elected salaries and other discretionary senior-pay adjustments unless the Town Board approves a specific public justification during the 2027 budget process."
        ),
        .init(
            title: "Set qualification standards for key exempt finance roles",
            impact: "Accountability",
            detail: "If the Supervisor recommends an exempt employee for Budget Officer or similar finance leadership, residents should expect clear evidence of financial training, budget experience, and working knowledge of accounting principles so budget decisions benefit from real expertise and effective pluralism."
        ),
        .init(
            title: "Tighten overtime controls",
            impact: "Accountability",
            detail: "Start with Police Uniform OT, where 2024 actual spending was about $1.40M against a $1.0M budget and the adopted 2026 line remains $1.0M. The March activity report also shows criminal incidents rising to 167 from 144 and total incidents rising to 2,994 from 2,922, so a credible 2027 offset must come from monthly cause-of-OT reporting, scheduling review, and quarterly recovery plans, not from assuming police workload is falling."
        ),
        .init(
            title: "Budget a small civilian vacancy factor",
            impact: "Transparency",
            detail: "Carry a 1% vacancy factor against the civilian/CSEA payroll base so routine turnover helps offset automatic step growth without reducing core public safety staffing."
        ),
        .init(
            title: "Use targeted refill control for retirements",
            impact: "Accountability",
            detail: "If senior positions turn over in 2027, refill selectively rather than automatically. The current model assumes three targeted retirements with two backfills at lower replacement cost."
        ),
        .init(
            title: "Resize underused budget lines",
            impact: "Transparency",
            detail: "Review lines that routinely finish under budget, resize them to more realistic levels for 2027, and reallocate those dollars to lines that are consistently overspent instead of treating every increase as new spending."
        ),
        .init(
            title: "Recover value from surplus equipment",
            impact: "Accountability",
            detail: "Before donating usable surplus items, require a review for auction, resale, trade-in, or other residual-value recovery so the Town captures value where practical."
        ),
        .init(
            title: "Use reserves only for one-time items",
            impact: "Transparency",
            detail: "If the Town uses fund balance above its operating target, keep it for equipment, debt reduction, capital work, or a clearly limited tax-stabilization plan, not for permanent payroll or benefits."
        )
    ]

    static let expertLines: [BudgetRecommendationLine] = [
        .init(
            title: "Explicitly budget modeled union salary settlements",
            impact: "Transparency",
            detail: "Break out the projected 2027 PBA, SOA, and CSEA wage actions as a separate recurring pressure line so policymakers and residents can see that union salary growth is driving most of the modeled payroll increase."
        ),
        .init(
            title: "Mandate >=20% premium share for senior staff and elected officials",
            impact: "Fairness",
            detail: "Build the 2027 tentative budget on the assumption that elected offices and designated senior staff/exempt leadership positions contribute at least 20% of the health insurance premium. The current planning model uses 22 eligible positions and the current NYSHIP participating-agency Empire Plan individual premium rate as a conservative floor, producing about $85.1K of recurring relief before any family-plan mix is added."
        ),
        .init(
            title: "Adopt a tiered fund-balance deployment policy",
            impact: "Transparency",
            detail: "Codify a 15% hard local floor, note that GFOA's two-month minimum benchmark is about 16.7%, and manage Riverhead toward an operating target above that floor with a deployment cap of roughly 25% of appropriations. Amounts above the operating band should be assigned only by board resolution for one-time uses, with a stated replenishment schedule when the draw approaches the floor."
        ),
        .init(
            title: "Adopt a Brookhaven-style expenditure growth trigger",
            impact: "Accountability",
            detail: "Codify an operating-budget rule stating that Town-Wide General Fund expenditures should not increase from the most recent adopted budget by more than the three-year average of revenue growth plus the three-year average population growth rate for the prior completed fiscal years. If the computed rate is below zero, baseline spending growth should default to zero unless a three-fourths Town Board vote authorizes a higher increase."
        ),
        .init(
            title: "Use excess fund balance for a larger CPF principal payment",
            impact: "Fairness",
            detail: "The Town borrowed about $70M against future 2% CPF receipts in the early 2000s and restructured that obligation through a 2016 refunding. RiverheadLOCAL reported on March 5, 2026 that Riverhead generated about $7.03M in CPF revenue during 2025 and still had about $12.29M outstanding as of December 31, 2024. The remaining schedule still runs through 2030, with annual principal and interest near $3M before dropping below $2M by 2028. A one-time paydown from excess fund balance would directly reduce CPF principal, future interest, and financing drag on CPF cash flow."
        ),
        .init(
            title: "Constitute a Community Housing Fund Advisory Board",
            impact: "Accountability",
            detail: "If the Town adopts the 0.5% Peconic Bay Community Housing Fund tax, it should also establish an advisory board with clear appointment rules, published recommendations, and annual reporting so housing-fund deployment benefits from pluralistic input and visible public accountability."
        ),
        .init(
            title: "Constitute a Battery Energy Storage Steering Committee",
            impact: "Transparency",
            detail: "For battery energy storage policy, the Town should establish a steering committee with representation from planning, emergency response, adjacent neighborhoods, environmental stakeholders, and technical experts so siting, safety, and host-community benefits are reviewed in a visible pluralistic forum."
        ),
        .init(
            title: "Mandate line-item debit/credit identification for fiscally impactful legislation",
            impact: "Transparency",
            detail: "Require every proposed local law, resolution, or board action with fiscal impact to cite the exact budget line or account code being charged or credited. That would force legislative fiscal notes to identify the real appropriation change instead of relying on broad narrative descriptions."
        ),
        .init(
            title: "Publish a peer-style levy and benefits summary",
            impact: "Transparency",
            detail: "East Hampton's 2026 adopted budget makes three useful moves Riverhead should copy: it separates appropriated surplus from applied reserves in the levy analysis, publishes a town-wide employee-benefits summary by category, and shows homeowner tax-impact examples tied to the adopted rate. Riverhead's 2027 book should do the same."
        ),
        .init(
            title: "Separate tax-supported costs from service-specific user fees",
            impact: "Transparency",
            detail: "Brookhaven's 2026 adopted budget explicitly broke out refuse and recycling costs into a dollar-for-dollar residential user fee so residents can track that service separately from the levy. Riverhead's own official 2025-2026 Receiver of Taxes sheet already shows the same kind of local practice, including a $482.40 single-family refuse-collection charge plus separate Riverhead and Calverton sewer-rent lines, and Town Code separately provides that Calverton sewer rents are set each November by Town Board resolution with the sewer budget and collected by the Receiver of Taxes. The 2027 budget should build from that existing transparency rather than blurring service-specific cost back into the tax levy."
        ),
        .init(
            title: "Mandate a Schedule of Fund Balance and Projections in every budget book",
            impact: "Transparency",
            detail: "Require each tentative and adopted budget document to include a Schedule of Fund Balance and Projections by major fund, showing beginning balance, appropriated fund balance, projected year-end balance, and the out-year reserve effect of the proposed budget."
        ),
        .init(
            title: "State the Town's 15% reserve-policy history explicitly",
            impact: "Transparency",
            detail: "The December 5, 2006 Town Board packet listed Resolution #1101 for adoption of a General Fund balance policy, and later audited statements describe a 15% General Fund minimum by resolution. Current assigned plus unassigned balance above 40% of expenditures should therefore be presented as a deliberate departure from the Town's older floor, not as a neutral baseline."
        ),
        .init(
            title: "Zero-base noncontractual exempt and elected raises",
            impact: "Accountability",
            detail: "Do not budget automatic discretionary raises for elected or exempt leadership positions in 2027. Any adjustment should be a separately stated board action, not embedded in the baseline."
        ),
        .init(
            title: "Require finance-role qualifications and independent budget capacity",
            impact: "Accountability",
            detail: "Where the Supervisor has appointment or recommendation power over exempt budget staff, the Town should articulate minimum qualifications for financial training, budget development, and accounting literacy. That helps ensure the budget office can challenge assumptions, interpret fund-accounting rules, and contribute to effective pluralism instead of operating as a political echo."
        ),
        .init(
            title: "Impose departmental overtime recovery targets",
            impact: "Accountability",
            detail: "Adopt a Police Uniform OT recovery target first: 2024 actual spending was about $401K above the $1.0M budget, so the current model treats $250K as a recoverable portion, not a full reset. Pair that target with the March workload data: criminal incidents and total incidents were up year over year, while accidents and summonses were down. Require budget-to-actual overtime targets, cause coding for patrol/court/recall/training/event OT, quarterly variance reports, and a corrective scheduling plan when spending runs hot."
        ),
        .init(
            title: "Carry a visible contingency line",
            impact: "Accountability",
            detail: "East Hampton's adopted budget keeps a dedicated contingency appropriation in the General Fund instead of pretending every risk can be forecast perfectly. Riverhead should carry a modest, clearly governed contingency line and require board-level reporting if it is used."
        ),
        .init(
            title: "Track fiscal-health outcomes against budget structure",
            impact: "Accountability",
            detail: "Brookhaven ties its budget presentation to outside fiscal outcomes like AAA ratings and a 0.0 OSC fiscal-stress score. Riverhead does not need to imitate the branding, but it should connect its 2027 structural choices to measurable reserve, debt, and fiscal-stress outcomes instead of discussing them only in narrative terms."
        ),
        .init(
            title: "Carry a 1% civilian vacancy factor",
            impact: "Transparency",
            detail: "Apply a modest 1% vacancy factor to the 2026 civilian/CSEA payroll base, producing about $124.2K of recurring relief while leaving sworn staffing assumptions untouched."
        ),
        .init(
            title: "Model targeted retirement + refill control",
            impact: "Accountability",
            detail: "Borrowing from the app's early-retirement planning assumptions, a 2027 scenario with three targeted senior departures and only two lower-cost backfills produces about $291.3K of annual gross savings after replacement cost."
        ),
        .init(
            title: "Right-size underused appropriations and redirect them",
            impact: "Transparency",
            detail: "Use multi-year actuals to identify accounts that regularly lapse, reset those baselines to realistic recurring levels, and reallocate the freed capacity to accounts that are chronically overspent before adding net-new appropriations."
        ),
        .init(
            title: "Monetize surplus assets before donation",
            impact: "Accountability",
            detail: "Adopt a surplus-property protocol that screens equipment, vehicles, technology, and furnishings for auction, resale, trade-in, or residual-value recovery before any donation route is approved."
        ),
        .init(
            title: "Keep fund balance for one-time uses only",
            impact: "Transparency",
            detail: "Do not use fund balance to support recurring compensation or benefits. Amounts above the operating target should support one-time capital, fleet, technology, debt reduction, or tightly bounded tax stabilization without weakening structural balance."
        )
    ]

    static let residentCorrectionLines: [BudgetCorrectionLine] = [
        .init(
            title: "General Fund (A01) still needs a closing correction",
            status: "Overage",
            detail: "The supplement shows $69,187,442 of tentative spending against $69,113,159 of tentative revenue, leaving a $74,283 gap to close. It also still uses $1.25M of appropriated fund balance."
        ),
        .init(
            title: "Sewer Fund (ES1) needs a plain-English reserve explanation",
            status: "Reserve watch",
            detail: "The supplement carries $2.15M of appropriated fund balance in revenues and a separate $500,000 fund balance contribution on the spending side. Residents should be told why both are needed and how reserves will be rebuilt."
        ),
        .init(
            title: "Calverton Sewer (ES3) remains dependent on reserves",
            status: "Reserve watch",
            detail: "ES3 still uses $645,000 of appropriated fund balance and shows a $35,932 fund balance contribution. That should be explained as a temporary fix, not a permanent funding plan."
        ),
        .init(
            title: "Water Fund (EW1) still leans on fund balance",
            status: "Transparency",
            detail: "EW1 includes $1.85M of appropriated fund balance in the 2026 tentative revenue plan. The public should be shown whether rates, debt, or operating costs are driving that reliance."
        )
    ]

    static let expertCorrectionLines: [BudgetCorrectionLine] = [
        .init(
            title: "A01 General Fund arithmetic gap should be reconciled before adoption",
            status: "Correction required",
            detail: "The supplement totals show A01 tentative expenditures of $69,187,442 versus A01 tentative revenues of $69,113,159, leaving a $74,283 imbalance. A01 also carries $1.25M of appropriated fund balance."
        ),
        .init(
            title: "ES1 Sewer shows layered reserve use that needs board-level explanation",
            status: "Reserve dependence",
            detail: "ES1 revenues include $2.15M of appropriated fund balance, while expenditures also show a $500,000 fund balance contribution line. That presentation should be reconciled in the hearing record."
        ),
        .init(
            title: "ES3 Calverton Sewer still relies on nonrecurring balance support",
            status: "Reserve dependence",
            detail: "ES3 includes $645,000 of appropriated fund balance in revenues and a $35,932 fund balance contribution in expenditures. If that is a short-term bridge, the replenishment plan should be stated explicitly."
        ),
        .init(
            title: "EW1 Water continues to rely on a large reserve draw",
            status: "Reserve dependence",
            detail: "EW1 includes $1.85M of appropriated fund balance in the tentative revenue plan. That should be paired with a clear statement of whether the driver is rates, capital timing, or operating pressure."
        ),
        .init(
            title: "ES5 Scavenger/Waste should be reconciled in the final narrative",
            status: "Correction watch",
            detail: "ES5 still carries $100,000 of appropriated fund balance in revenues and a $167,000 interfund transfer to A01 on the expenditure side. The board should clarify whether that transfer is still appropriate under current operating conditions."
        )
    ]

    static let residentBalanceTest = "Call the 2027 budget balanced only if recurring revenues cover union raises, payroll, benefits, and operating costs without depending on one-time reserve draws, and only if fund balance stays above the policy floor after any planned use. That lines up with OSC's guidance to keep budgets structurally balanced, watch financial condition over time, and act early when warning signs appear."

    static let expertBalanceTest = "Adopt a formal structural-balance test: recurring revenues must cover recurring appropriations, including modeled union salary settlements, with any fund-balance appropriation restricted to nonrecurring capital, debt, or tightly bounded tax-stabilization purposes. OSC's Financial Toolkit and Financial Condition Analysis guide point officials toward timely financial-condition analysis, early budget modification when deficits emerge, prudent reserve use, and periodic status reporting when revenue or expenditure variances widen. That same discipline means recurring AIM should be distinguished from the newer TMA layer and recorded transparently if Riverhead uses either in the 2027 plan. Under the current model, only about $39.8K of additional recurring relief is still needed after the expanded package of offsets."

    static let additionalResidentIdeas: [String] = [
        "Review take-home vehicles, fuel, and fleet replacement timing for recurring operating savings.",
        "Tighten part-time and seasonal staffing plans where schedules regularly exceed what departments actually use.",
        "Resize budget lines that are routinely underused and move those dollars to lines that are regularly overspent.",
        "Shop health coverage periodically and compare it with NYSHIP benchmarks instead of assuming the current mix is the best long-term fit.",
        "Audit health-insurance rosters and monthly bills so the Town is not paying for ineligible coverage or stale enrollments.",
        "Rebid large service contracts and recurring professional-service lines before adding new tax pressure, and make the solicitation visible enough to attract real competition.",
        "Use shared-service purchasing, regional bids, or other lawful cooperative purchasing tools for supplies, uniforms, and common maintenance items, especially where Riverhead can partner with nearby governments instead of buying alone.",
        "Review overtime patterns and shift design in public works and other round-the-clock functions before treating overtime as permanent staffing need.",
        "Review user fees, permits, and recreation charges so they keep pace with actual service cost.",
        "Sell or auction usable surplus items when possible instead of defaulting to donation."
    ]

    static let additionalExpertIdeas: [String] = [
        "For nonunion positions, or through collective bargaining where required, evaluate health-plan design and dependent-tier cost sharing in addition to the 20% senior/elected premium contribution.",
        "Test health coverage periodically against NYSHIP and other available options, audit carrier invoices against active eligibility files, and evaluate buyouts in lieu of coverage or Section 125 pre-tax structures where legally and operationally appropriate.",
        "Review vehicle assignment, fuel consumption, and fleet right-sizing for recurring operating relief rather than one-time deferrals.",
        "Use multi-year budget-to-actual variance review to shrink chronically underspent appropriations and reassign capacity to recurring pressure lines.",
        "Apply a line-by-line contractual and professional-services reset to recurring consulting, legal, IT, and outside-vendor accounts, with documented competition or a written exception rationale where competition is limited.",
        "Compare unemployment-insurance tax contributions with the benefit-reimbursement method if Riverhead's workforce remains stable, because OSC found that reimbursement can be materially cheaper for some towns.",
        "Review workers' compensation coverage, payroll classifications, and claims procedures periodically so the Town is not overpaying premiums or carrying weak documentation into disputed claims.",
        "Revisit fee schedules, permit charges, and program revenues where service cost growth has outpaced current pricing.",
        "Use written overtime plans, alternate work schedules where operationally feasible, and procurement bundling, cooperative purchasing, and Article 5-G shared-service opportunities for recurring commodities, uniforms, paving inputs, and maintenance materials, while avoiding artificial splitting of purchases below bidding thresholds.",
        "Require surplus-asset screening for auction, resale, or trade-in value before donation approvals are granted."
    ]

    static let residentRevenueLines: [BudgetRevenueLine] = [
        .init(
            title: "Adopt the 0.5% Peconic Bay Community Housing Fund",
            amount: 0,
            detail: "Add the same 0.5% real estate transfer tax adopted by the other East End towns in 2023 to create a dedicated local housing fund, with a Community Housing Fund Advisory Board helping review priorities and public reporting. RiverheadLOCAL reported on March 5, 2026 that the four participating towns had already raised about $79.12M since 2023, but Riverhead did not adopt the tax, so this remains a policy option rather than a counted FY27 revenue line."
        ),
        .init(
            title: "2.0% tax-cap levy increase",
            amount: 972_789.58,
            detail: "Illustrative 2027 levy growth at roughly the tax-cap level, sized as 2.0% of the latest local General Fund levy currently stored in the app. The legal cap applies to the total levy, not directly to assessments or tax rates."
        ),
        .init(
            title: "Permit and application fee update",
            amount: 25_000,
            detail: "Refresh building, planning, and related application fees so they better match current processing cost."
        ),
        .init(
            title: "Recreation and program charge update",
            amount: 20_000,
            detail: "Use a modest increase in recreation, field, and program charges where prices have not kept pace with operating cost."
        ),
        .init(
            title: "Rental and event fee reset",
            amount: 15_000,
            detail: "Revisit facility rental, field-use, and special-event charges for recurring town-managed spaces."
        ),
        .init(
            title: "Surplus auction/resale recovery",
            amount: 1_500,
            detail: "Capture a small annual value-recovery estimate by auctioning or reselling usable surplus items instead of defaulting to donation."
        ),
        .init(
            title: "Show AIM and TMA separately",
            amount: 0,
            detail: "If Riverhead is counting state municipal aid in the 2027 package, show recurring AIM and the newer August TMA payment as separate lines so residents can see what is base aid and what is a newer add-on."
        )
    ]

    static let expertRevenueLines: [BudgetRevenueLine] = [
        .init(
            title: "Adopt the 0.5% Peconic Bay Community Housing Fund tax",
            amount: 0,
            detail: "Model a dedicated housing revenue stream using the 0.5% transfer-tax framework adopted by the other East End towns in 2023, paired with a Community Housing Fund Advisory Board and public reporting structure. RiverheadLOCAL reported on March 5, 2026 that the four participating towns had raised about $79.12M since program launch, but Riverhead did not adopt the tax, so it is displayed here as an available policy lever rather than a quantified FY27 revenue line."
        ),
        .init(
            title: "2.0% levy increase within tax-cap framework",
            amount: 972_789.58,
            detail: "Illustrative 2027 levy growth equal to 2.0% of the latest local General Fund levy in the app's historical series ($48.64M), producing about $972.8K before any tax-base-growth-factor, carryover, or exclusion adjustments. The legal cap tests the total levy, not the tax rate or assessed value."
        ),
        .init(
            title: "Building/planning permit schedule reset",
            amount: 25_000,
            detail: "Illustrative recurring revenue from repricing permit, application, and review fees to reflect current staff time and processing cost."
        ),
        .init(
            title: "Recreation and program revenue adjustment",
            amount: 20_000,
            detail: "Illustrative recurring gain from updating recreation, field, and program charges where demand remains stable and fees lag cost."
        ),
        .init(
            title: "Facility rental and event fee update",
            amount: 15_000,
            detail: "Illustrative recurring gain from resetting town facility rental, field-use, and event permit pricing."
        ),
        .init(
            title: "Surplus asset value recovery",
            amount: 1_500,
            detail: "Illustrative annual value-recovery estimate from auction, resale, or trade-in of usable surplus property before donation."
        ),
        .init(
            title: "Disclose AIM versus TMA explicitly",
            amount: 0,
            detail: "OSC's municipal-aid page shows towns receive AIM annually in September, while TMA is a newer August payment layered on AIM and recorded under account code 3089. Riverhead should show both lines separately if they are part of the 2027 recurring revenue build."
        )
    ]

    static let residentInvestmentNotes: [String] = [
        "Increase Building Department staffing to improve permit review and public response times. Current planning placeholder: $180,000.",
        "Fund online platform updates so residents can interact with town systems more easily. Current placeholder: $85,000.",
        "Add 2 more Code Enforcement Officers using current ordinance/code staff pay as the planning baseline.",
        "Add 1 new Town Clerk position using current deputy town clerk pay as the planning baseline.",
        "Add 2 new police officers using current entry-level full-time police officer pay as the planning baseline.",
        "Consider a one-time $15,000 grant application to the Legal Aid Society of Suffolk County for direct legal-support capacity tied to resident need.",
        "Consider a one-time community improvement micro-grant series of roughly $500 to $1,000 awards, capped at $50,000 total, for visible neighborhood-scale projects."
    ]

    static let expertInvestmentNotes: [String] = [
        "Add Building Department headcount to improve permit throughput, inspection capacity, and customer response. Current planning placeholder: $180,000 recurring.",
        "Fund online platform modernization and workflow updates. Current planning placeholder: $85,000, treated here as a 2027 cost requirement.",
        "Add 2 Code Enforcement Officers at about $70,249.89 each, using 2026 ordinance inspector pay as the planning proxy.",
        "Add 1 Town Clerk staff position at about $58,661.49, using the 2026 deputy town clerk rate as the planning proxy.",
        "Add 2 police officers at about $72,066.67 each, using the lowest current full-time 2026 police officer salary as the planning proxy.",
        "Set aside a one-time $15,000 grant application to the Legal Aid Society of Suffolk County as a targeted nonrecurring community-support investment.",
        "Set aside a one-time $50,000 community improvement micro-grant series using awards between about $500 and $1,000 for civic, block-scale, or neighborhood-visibility improvements."
    ]

    static let residentImplementationPhases: [BudgetImplementationPhase] = [
        .init(
            title: "Immediate Actions",
            horizon: "First 30 days",
            detail: "Lead with structure, not pressure: set a calmer fiscal tone, make a few credibility moves early, and open the door to public dialogue before the next budget fight takes shape.",
            items: [
                "Publicly frame the goal as volatility reduction, predictability, and fiscal discipline, not austerity.",
                "Rescind expired emergency declarations, review pending legal matters for cost exposure, and adopt a petty cash fund policy.",
                "Make credibility moves early: voluntary Supervisor salary reduction, modest senior-staff giveback, and a minimum 20% healthcare contribution for senior leadership.",
                "Launch listening tours, mobile office hours at Riverhead Library, and a post-AOT public policy review."
            ]
        ),
        .init(
            title: "First 100 Days",
            horizon: "Structural foundations",
            detail: "Use the opening window to lock in the rules of the game: reserve policy, capital discipline, tax-levy guardrails, and a more planned approach to overtime and staffing pressure.",
            items: [
                "Publish a plain budget calendar early so departments, board members, and residents can see when estimates, revisions, hearings, and adoption decisions are due.",
                "Adopt a General Fund target range of 25% to 30% with separate operating, pension, and capital/debt reserve buckets.",
                "Set a yearly fund-balance use limit of roughly 3% to 4% absent emergency, and require a clear budget modifier process for new priorities.",
                "Add an operating-budget rule that normal spending growth should not outrun the Town's three-year average revenue growth plus three-year average population growth, unless the Board votes to override it openly.",
                "Adopt a 4-year rolling capital plan with cost, useful life, BAN-to-bond path, and operating impact for every project.",
                "Require each budget to show a tax-cap baseline, any managed override scenario, and a 3-to-5-year financial outlook with the key revenue, labor, and benefit assumptions stated openly.",
                "Run a shared-services needs assessment with neighboring governments for easier first projects such as purchasing, fleet, training, or back-office support before pursuing harder consolidations.",
                "Shift overtime from approval-by-approval to departmental overtime plans with drivers, mitigation steps, and quarterly variance explanations."
            ]
        ),
        .init(
            title: "Year One Priorities",
            horizon: "Delivery and trust-building",
            detail: "After the rules are in place, the work turns outward: regular reporting, open work sessions, and a short list of visible policy and community investments that show planning can produce better outcomes.",
            items: [
                "Publish monthly budget-to-actual reports with simple variance explanations, then add quarterly overtime reporting and integrate the capital plan into the annual budget cycle.",
                "Hold regular mobile office hours, open budget work sessions with department heads, and revisit meeting-time predictability and speaker decorum rules.",
                "Sequence legislative priorities such as the Pattern Book, franchise review, farmland preservation, CHF review, and more Spanish-language access in key departments.",
                "Fund visible community-facing items like a Day of Action, pantry support, school contests, and small civic improvement projects without normalizing one-time money into recurring costs."
            ]
        )
    ]

    static let expertImplementationPhases: [BudgetImplementationPhase] = [
        .init(
            title: "Immediate Actions",
            horizon: "First 30 days",
            detail: "The opening phase is about stabilizing expectations and creating visible management discipline before the next operating cycle hardens into precedent.",
            items: [
                "State a volatility-reduction framework: reserves are insurance, not surplus, and the goal is structural balance rather than performative austerity.",
                "Rescind stale emergency declarations, direct counsel and administration to review pending litigation cost exposure, and formalize a petty cash fund policy.",
                "Adopt early credibility measures such as a voluntary Supervisor salary reduction, a small senior-staff giveback, and a minimum 20% healthcare contribution for senior leadership.",
                "Open a documented listening-tour and mobile-office-hours process, then publish a post-AOT policy debrief within 30 days."
            ]
        ),
        .init(
            title: "First 100 Days",
            horizon: "Structural foundations",
            detail: "This is the period to codify fiscal architecture: reserve segmentation, capital planning, debt rules, tax-levy guardrails, and overtime governance that can survive politics.",
            items: [
                "Adopt and publish a formal budget calendar so estimate requests, tentative-budget filing, public hearing revisions, and final adoption happen on a visible schedule.",
                "Adopt a General Fund operating range of 25% to 30%, with separate operating stabilization, pension stabilization, and capital/debt management reserve rules.",
                "Cap annual fund-balance use at roughly 3% to 4% absent emergency, and codify public-law treatment for committed, assigned, displaced, and encumbered surplus.",
                "Adopt a Brookhaven-style operating-budget trigger limiting Town-Wide General Fund expenditure growth to the three-year average of revenue growth plus the three-year average population growth rate, unless exceeded by a three-fourths Board vote.",
                "Require a rolling 4-year CIP with project cost, useful life, financing path, and operating/staffing impacts, plus debt principles that keep BANs temporary and debt-service growth controlled.",
                "Require each tentative budget to show a tax-cap-compliant baseline, any override case with written findings and a 3-to-5-year restoration plan, and a rolling 3-to-5-year financial outlook covering the General Fund and any major related operating funds.",
                "Replace approval-only overtime management with departmental overtime plans that establish baseline expectations, known drivers, mitigation strategies, and quarterly variance reporting.",
                "Run a personal-service cost review covering health-insurance competition, invoice and eligibility audit controls, buyout options, unemployment funding-method choice, workers' compensation controls, and overtime discipline."
            ]
        ),
        .init(
            title: "Year One Priorities",
            horizon: "Delivery and trust-building",
            detail: "The final phase is operational delivery: public work sessions, predictable reporting, and sequenced legislation that converts the new controls into a more trusted budget culture.",
            items: [
                "Implement overtime plans, issue monthly amended-budget versus actual reports with variance narratives and year-end projections, and fold the CIP into the annual budget-development calendar.",
                "Maintain mobile office hours, run open work sessions with department heads, and standardize accessible meeting times and decorum rules.",
                "Sequence legislative work on the Pattern Book, franchise review, farmland preservation, CHF policy, and language access improvements.",
                "Use one-time capacity for high-visibility community investments while keeping recurring policy additions tied to recurring revenue."
            ]
        )
    ]

    static let residentFundingStrategyLines: [BudgetFundingStrategyLine] = [
        .init(
            title: "Treat the 2% cap like the operating guardrail",
            detail: "Keep payroll and recurring operations as close to the cap as possible, and push major long-lived projects into funded capital stacks instead of loading them straight onto the levy."
        ),
        .init(
            title: "Build a grants pipeline around the state calendar",
            detail: "Use CHIPS for roads, WQIP and WIIA for water and sewer, and DASNY or CFA-backed capital grants for facilities so Riverhead is applying on rhythm instead of reacting late."
        ),
        .init(
            title: "Use the highway garage as the test case",
            detail: "The April 7, 2026 board action on up to $1.88M for the Wading River highway garage is the kind of project Riverhead should pair with CHIPS and a clear debt-service offset plan, instead of letting the local share drift into recurring levy pressure."
        ),
        .init(
            title: "Use the Town Hall EV site as a grant-and-host test case",
            detail: "If Riverhead wants a 12-space EV charging area at Town Hall, keep it in the capital lane: test Tesla's business-host path for fast charging, separately test NYSERDA eligibility for any public Level 2 ports, add PSEG Long Island make-ready incentives to the stack, and make the local share explicit before approval."
        ),
        .init(
            title: "Use grants to shrink debt, not just add projects",
            detail: "If grant money comes in on a BAN- or bond-financed project, evaluate it first for principal reduction so taxpayers see lower future debt service, not just a bigger project list."
        ),
        .init(
            title: "Prioritize projects that score well for aid",
            detail: "Move drainage, resiliency, stormwater, and treatment work to the front of the line when they match state funding priorities and reduce local burden."
        ),
        .init(
            title: "Create a grants + CIP steering group",
            detail: "Have Finance, Highway, Utilities, Planning, and the Supervisor's office review deadlines monthly and report progress publicly each quarter so the funding stack becomes an actual management habit."
        ),
        .init(
            title: "Use OSC's local-government guides as the playbook",
            detail: "Riverhead does not need to invent its own capital and reserve rules from scratch. OSC's Local Government Management Guides already publish practical guidance on reserve funds, capital projects funds, and multiyear financial planning that can be used as the Board's starting template, including written reserve plans, periodic board review, and visible transfer resolutions."
        )
    ]

    static let expertFundingStrategyLines: [BudgetFundingStrategyLine] = [
        .init(
            title: "Use the tax cap as the operating constraint",
            detail: "Adopt a policy that long-lived assets and mandate-driven infrastructure must be evaluated first for grant and aid eligibility before they are allowed to pressure the levy."
        ),
        .init(
            title: "Institutionalize a CFA-calendar grant pipeline",
            detail: "Build recurring application discipline around CHIPS, EWR/PAVE-NY, WQIP, WIIA, CFA, DASNY, and other recurring state opportunities so capital timing is not left to ad hoc pursuit."
        ),
        .init(
            title: "Use the Wading River garage as a live capital template",
            detail: "After the April 7, 2026 authorization of up to $1.88M in borrowing for the highway garage, require a public project sheet showing CHIPS eligibility, expected debt service, any Highway-budget offsets, and whether assigned fund balance is being used as part of the local-share plan."
        ),
        .init(
            title: "Treat Town Hall EV charging as a structured capital sheet",
            detail: "A 12-space Town Hall charging concept should disclose site design, utility-upgrade assumptions, host-site terms with Tesla if pursued, whether adjacent public Level 2 ports are being sized for NYSERDA support, and whether PSEG Long Island's March 6, 2026 Business First incentives are reducing charger-plug or infrastructure cost before the project is described as a generic parking-lot improvement. OSC's Capital Projects Fund guide also points toward project-by-project budgeting, separate accounting records, and active board monitoring of scope and cost."
        ),
        .init(
            title: "Apply a grant-capture rule to debt-financed projects",
            detail: "Any reimbursement or grant award tied to a BAN- or bond-financed project should be evaluated first for debt-principal reduction before being repurposed elsewhere."
        ),
        .init(
            title: "Score the CIP for mandate fit and grantability",
            detail: "Require each major project sheet to state regulatory drivers, water-quality or resiliency benefits, public-benefit rationale, and a short grant-scoring case before it enters the funded queue."
        ),
        .init(
            title: "Use AOT as an advocacy and implementation checkpoint",
            detail: "Require a post-AOT briefing within 30 days covering road-aid advocacy, pension or mandate relief opportunities, water and stormwater match relief, and any state-program changes Riverhead should apply immediately."
        ),
        .init(
            title: "Create a grants + CIP steering group with measurable targets",
            detail: "Run a monthly internal pipeline review and a quarterly public Board work session, with goals such as increasing external capital dollars captured and reducing the local share of the CIP over three years."
        ),
        .init(
            title: "Attach the OSC management guides to the budget build",
            detail: "Use OSC's publication library as the technical appendix for Riverhead's 2027 process, especially the Reserve Funds guide (February 2022), Capital Projects Fund guide (September 2019), and Multiyear Financial Planning guide (September 2017), so reserve, CIP, and out-year practices are anchored to published state guidance. The Reserve Funds guide is especially clear that reserve balances need a defined purpose, written oversight, periodic reasonableness review, and visible resolutions when money is moved. The Capital Projects Fund guide is similarly clear that major projects need separate project records, project-by-project budgets, and board oversight of financing and cost containment."
        )
    ]
}

@MainActor
fileprivate struct ExecutiveBudgetSummaryView: View {
    let mode: BudgetAudienceMode

    @Environment(\.colorScheme) private var scheme
    @State private var loadedSummaries: [RBFundSummary] = []

    private var summaries: [RBFundSummary] {
        loadedSummaries.isEmpty ? Riverhead2026BudgetShift.fundSummaries() : loadedSummaries
    }

    private var topFunds: [ExecutiveFundMixSlice] {
        let palette: [Color] = [
            RiverheadTheme.accent,
            RiverheadTheme.brandTeal,
            RiverheadTheme.brandGold,
            RiverheadTheme.brandCoral,
            RiverheadTheme.brandSky,
            .purple
        ]

        return summaries
            .compactMap { row -> (RBFundSummary, Double)? in
                guard let amount = double(row.appropriations2026), amount > 0 else { return nil }
                return (row, amount)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(6)
            .enumerated()
            .map { index, item in
                ExecutiveFundMixSlice(
                    fundCode: item.0.fundCode,
                    fundName: item.0.fundName,
                    amount: item.1,
                    tint: palette[index % palette.count]
                )
            }
    }

    private var totalAppropriations2026: Double {
        summaries.compactMap { double($0.appropriations2026) }.reduce(0, +)
    }

    private var totalTaxLevy2026: Double {
        summaries.compactMap { double($0.taxLevy2026) }.reduce(0, +)
    }

    private var totalRevenues2026: Double {
        summaries.compactMap { double($0.estRevenues2026) }.reduce(0, +)
    }

    private var totalFundBalanceUse2026: Double {
        summaries.compactMap { double($0.appropFundBalance2026) }.reduce(0, +)
    }

    private var generalFundAppropriations2026: Double {
        double(summaries.first { $0.fundCode == "A01" }?.appropriations2026)
            ?? BudgetRecommendations2027.totalBudget2026
    }

    private var headlineMetrics: [ExecutiveSummaryMetric] {
        [
            .init(
                title: "2026 total budget",
                value: moneyShort(totalAppropriations2026),
                caption: "\(summaries.count) funds in the 2026 budget book",
                symbol: "building.columns.fill",
                tint: RiverheadTheme.accent
            ),
            .init(
                title: "2026 tax levy",
                value: moneyShort(totalTaxLevy2026),
                caption: "Local property-tax support across funds",
                symbol: "house.and.flag.fill",
                tint: RiverheadTheme.brandTeal
            ),
            .init(
                title: "General Fund",
                value: moneyShort(generalFundAppropriations2026),
                caption: "Core townwide operating fund",
                symbol: "chart.pie.fill",
                tint: RiverheadTheme.brandGold
            ),
            .init(
                title: "2027 payroll pressure",
                value: moneyShort(BudgetRecommendations2027.modeledAutomaticPayrollPressure),
                caption: "Modeled automatic wage pressure before other costs",
                symbol: "person.3.fill",
                tint: RiverheadTheme.brandCoral
            )
        ]
    }

    private var bridgeItems: [ExecutiveBridgeItem] {
        [
            .init(label: "Automatic payroll pressure", amount: -BudgetRecommendations2027.modeledAutomaticPayrollPressure, role: "Cost driver", tint: RiverheadTheme.brandCoral),
            .init(label: "Recurring savings package", amount: BudgetRecommendations2027.quantifiedPackageSavings, role: "Offset", tint: .green),
            .init(label: "Revenue package", amount: BudgetRecommendations2027.modeledRevenuePackage, role: "Offset", tint: RiverheadTheme.brandTeal),
            .init(label: "Service investments", amount: -BudgetRecommendations2027.addedServiceInvestments, role: "Policy choice", tint: RiverheadTheme.brandGold),
            .init(label: "Modeled cushion", amount: BudgetRecommendations2027.balanceAfterRevenueAndInvestments, role: "Remaining room", tint: RiverheadTheme.accent)
        ]
    }

    private var fundingItems: [ExecutiveBridgeItem] {
        [
            .init(label: "Estimated revenues", amount: totalRevenues2026, role: "2026 source", tint: .green),
            .init(label: "Tax levy", amount: totalTaxLevy2026, role: "2026 source", tint: RiverheadTheme.brandTeal),
            .init(label: "Fund balance use", amount: totalFundBalanceUse2026, role: "2026 source", tint: RiverheadTheme.brandGold)
        ].filter { $0.amount > 0 }
    }

    private var totalFundingSources2026: Double {
        fundingItems.map(\.amount).reduce(0, +)
    }

    private var largestBridgeMagnitude: Double {
        max(bridgeItems.map { abs($0.amount) }.max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            executiveHero
            metricGrid
            fundMixCard
            fundingCard
            bridgeCard
            prioritiesCard
            SourcesStrip(links: sourceLinks)
        }
        .onAppear {
            if Riverhead2026BudgetShift.lastLoadCount == 0 {
                _ = try? Riverhead2026BudgetShift.load()
            }
            loadedSummaries = Riverhead2026BudgetShift.fundSummaries()
        }
    }

    private var executiveHero: some View {
        GlassCard(
            title: "Executive Summary: 2026 Budget + 2027 Plan",
            subtitle: mode == .resident
                ? "Here's the short version: 2026 is where things stand today; 2027 is the bridge — wage pressure, savings, revenue, and a few targeted investments."
                : "A compact fiscal briefing that combines the parsed 2026 fund schedule with the app's 2027 recurring-budget model."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(mode == .resident ? residentExecutiveSummary : expertExecutiveSummary)
                    .font(.subheadline)
                    .foregroundStyle(RiverheadTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    executiveBadge("2026", text: "Budget book", tint: RiverheadTheme.accent)
                    executiveBadge("2027", text: "Planning model", tint: RiverheadTheme.brandCoral)
                }
            }
        }
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
            ForEach(headlineMetrics) { metric in
                ExecutiveMetricTile(metric: metric)
            }
        }
    }

    private var fundMixCard: some View {
        GlassCard(title: "2026 Budget Mix", subtitle: "Largest funds by 2026 appropriations.") {
            if topFunds.isEmpty {
                ContentUnavailableView("No fund data loaded", systemImage: "chart.pie")
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 18) {
                        ExecutiveFundMixDonut(
                            slices: topFunds,
                            total: totalAppropriations2026,
                            centerValue: moneyShort(totalAppropriations2026),
                            centerLabel: "2026 total"
                        )
                        .frame(width: 164, height: 164)

                        fundMixLegend
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        ExecutiveFundMixDonut(
                            slices: topFunds,
                            total: totalAppropriations2026,
                            centerValue: moneyShort(totalAppropriations2026),
                            centerLabel: "2026 total"
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)

                        fundMixLegend
                    }
                }
            }
        }
    }

    private var fundMixLegend: some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(topFunds) { slice in
                ExecutiveLegendRow(
                    color: slice.tint,
                    title: "\(slice.fundCode) \(slice.fundName)",
                    value: moneyShort(slice.amount),
                    percent: percentShort(slice.amount, of: totalAppropriations2026)
                )
            }
        }
    }

    private var fundingCard: some View {
        GlassCard(title: "How 2026 Is Funded", subtitle: "Estimated revenues, tax levy, and appropriated fund balance.") {
            VStack(alignment: .leading, spacing: 14) {
                ExecutiveFundingStack(items: fundingItems, total: totalFundingSources2026)
                    .frame(height: 58)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(fundingItems) { item in
                        ExecutiveFundingRow(
                            item: item,
                            total: totalFundingSources2026,
                            valueText: moneyShort(item.amount)
                        )
                    }
                }
            }
        }
    }

    private var bridgeCard: some View {
        GlassCard(title: "2027 Recurring Bridge", subtitle: "A planning view of what must be absorbed before Riverhead moves into 2027.") {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(bridgeItems) { item in
                        ExecutiveBridgeImpactRow(
                            item: item,
                            maximum: largestBridgeMagnitude,
                            valueText: signedMoneyShort(item.amount)
                        )
                    }
                }

                HStack(spacing: 10) {
                    bridgeStat("Union wage pressure", value: BudgetRecommendations2027.modeledUnionSalaryPressure, tint: RiverheadTheme.brandCoral)
                    bridgeStat("After investments", value: BudgetRecommendations2027.balanceAfterRevenueAndInvestments, tint: RiverheadTheme.accent)
                }
            }
        }
    }

    private var prioritiesCard: some View {
        GlassCard(
            title: "Executive Takeaways",
            subtitle: mode == .resident
                ? "The decisions you should be able to see clearly."
                : "The controls that should govern the next budget cycle."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                executiveTakeaway(
                    "Treat labor growth as structural",
                    detail: "The 2027 model starts with \(moneyShort(BudgetRecommendations2027.modeledAutomaticPayrollPressure)) of payroll pressure, then layers in a published-rate pension increase that now looks closer to $1.4M to $1.85M townwide before other inflation, utility, or health-insurance pressure.",
                    tint: RiverheadTheme.brandCoral
                )
                executiveTakeaway(
                    "Use reserves for one-time purposes",
                    detail: "The summary keeps recurring balance separate from reserve deployment so fund balance does not quietly become the way ordinary operations are paid.",
                    tint: RiverheadTheme.brandGold
                )
                executiveTakeaway(
                    "Fund visible service priorities only after the recurring test",
                    detail: "The modeled 2027 package preserves room for Building, Code Enforcement, Town Clerk service, online tools, and police staffing after recurring offsets and revenue are counted.",
                    tint: RiverheadTheme.brandTeal
                )
            }
        }
    }

    private var sourceLinks: [BudgetSourceLink] {
        [
            .init(title: "2026 Tentative Budget",
                  kind: .budgetBook,
                  note: nil,
                  url: URL(string: "https://www.townofriverheadny.gov/DocumentCenter/View/2779/2026-Tentative-Budget-PDF")),
            .init(title: "2026 Budget Supplement",
                  kind: .budgetBook,
                  note: nil,
                  url: URL(string: "https://www.townofriverheadny.gov/DocumentCenter/View/2780/2026-Budget-Supplement-PDF")),
            .init(title: "2027 Simulator",
                  kind: .other,
                  note: nil,
                  url: nil)
        ]
    }

    private var residentExecutiveSummary: String {
        "Riverhead's 2026 budget is the baseline: it shows where the money is going now, which funds carry the largest costs, and how much is supported by taxes, revenues, and fund balance. The 2027 plan should be judged by whether it pays for recurring wage pressure first, protects reserves, and then adds visible service improvements only with recurring money."
    }

    private var expertExecutiveSummary: String {
        "The executive view frames 2026 as the budget baseline and 2027 as a recurring-balance test. The key risk is structural payroll growth: the model carries about \(moneyShort(BudgetRecommendations2027.modeledAutomaticPayrollPressure)) of automatic 2027 pressure before other non-payroll escalators. The recommended posture is recurring offsets and revenue first, targeted service investments second, and reserve use limited to one-time transition, capital, or debt purposes."
    }

    private func executiveBadge(_ title: String, text: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.12), in: Capsule())
        .overlay(Capsule().strokeBorder(tint.opacity(0.25), lineWidth: 0.8))
    }

    private func bridgeStat(_ title: String, value: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(moneyShort(value))
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
            Text(title)
                .font(.caption2)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func executiveTakeaway(_ title: String, detail: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(tint)
                .frame(width: 9, height: 9)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private func double(_ value: Decimal?) -> Double? {
        guard let value else { return nil }
        return NSDecimalNumber(decimal: value).doubleValue
    }

    private func moneyShort(_ value: Double) -> String {
        let sign = value < 0 ? "-" : ""
        let v = abs(value)
        let scaled: Double
        let suffix: String
        if v >= 1_000_000_000 {
            scaled = v / 1_000_000_000
            suffix = "B"
        } else if v >= 1_000_000 {
            scaled = v / 1_000_000
            suffix = "M"
        } else if v >= 1_000 {
            scaled = v / 1_000
            suffix = "K"
        } else {
            scaled = v
            suffix = ""
        }
        let number = scaled >= 100 ? String(format: "%.0f", scaled) : String(format: "%.1f", scaled)
        return "\(sign)$\(number)\(suffix)"
    }

    private func signedMoneyShort(_ value: Double) -> String {
        value >= 0 ? "+\(moneyShort(value))" : moneyShort(value)
    }

    private func percentShort(_ value: Double, of total: Double) -> String {
        guard total > 0 else { return "0%" }
        return (value / total).formatted(.percent.precision(.fractionLength(0)))
    }
}

fileprivate struct ExecutiveMetricTile: View {
    @Environment(\.colorScheme) private var scheme

    let metric: ExecutiveSummaryMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(metric.tint.opacity(scheme == .dark ? 0.22 : 0.16))
                    Circle()
                        .trim(from: 0.18, to: 0.82)
                        .stroke(
                            metric.tint.opacity(0.9),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(24))
                        .padding(5)
                    Image(systemName: metric.symbol)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(metric.tint)
                }
                .frame(width: 42, height: 42)
                .accessibilityHidden(true)

                Spacer(minLength: 8)

                Image(systemName: "sparkline")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(metric.tint.opacity(0.52))
                    .accessibilityHidden(true)
            }

            Text(metric.value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            VStack(alignment: .leading, spacing: 3) {
                Text(metric.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                Text(metric.caption)
                    .font(.caption2)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
        .padding(13)
        .background(
            LinearGradient(
                colors: [
                    metric.tint.opacity(scheme == .dark ? 0.22 : 0.14),
                    RiverheadTheme.Surface.card.opacity(scheme == .dark ? 0.64 : 0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(alignment: .bottomTrailing) {
            BudgetTileGlyph(tint: metric.tint)
                .frame(width: 64, height: 42)
                .opacity(scheme == .dark ? 0.22 : 0.16)
                .padding(10)
                .accessibilityHidden(true)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(metric.tint.opacity(scheme == .dark ? 0.36 : 0.26), lineWidth: 0.9)
        )
        .accessibilityElement(children: .combine)
    }
}

fileprivate struct BudgetTileGlyph: View {
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let barWidth = width / 9

            HStack(alignment: .bottom, spacing: barWidth * 0.55) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: barWidth / 2, style: .continuous)
                        .fill(tint)
                        .frame(
                            width: barWidth,
                            height: height * CGFloat([0.45, 0.72, 0.56, 0.9, 0.64][index])
                        )
                }
            }
        }
    }
}

fileprivate struct ExecutiveFundMixDonut: View {
    @Environment(\.colorScheme) private var scheme

    let slices: [ExecutiveFundMixSlice]
    let total: Double
    let centerValue: String
    let centerLabel: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(RiverheadTheme.border.opacity(scheme == .dark ? 0.42 : 0.24), lineWidth: 18)

            ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                let start = cumulativeValue(before: index) / max(total, 1)
                let end = cumulativeValue(through: index) / max(total, 1)

                Circle()
                    .trim(from: start, to: end)
                    .stroke(
                        slice.tint,
                        style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: slice.tint.opacity(scheme == .dark ? 0.18 : 0.12), radius: 3, x: 0, y: 2)
                    .accessibilityLabel("\(slice.fundName), \(slice.amount.formatted(.currency(code: "USD").precision(.fractionLength(0))))")
            }

            VStack(spacing: 2) {
                Text(centerValue)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(centerLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textSecondary)
            }
            .padding(20)
        }
        .padding(10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Largest 2026 budget funds")
    }

    private func cumulativeValue(before index: Int) -> Double {
        slices.prefix(index).map(\.amount).reduce(0, +)
    }

    private func cumulativeValue(through index: Int) -> Double {
        slices.prefix(index + 1).map(\.amount).reduce(0, +)
    }
}

fileprivate struct ExecutiveLegendRow: View {
    let color: Color
    let title: String
    let value: String
    let percent: String

    var body: some View {
        HStack(spacing: 9) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(color)
                .frame(width: 12, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(.white.opacity(0.28), lineWidth: 0.6)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(value)
                    Text(percent)
                }
                .font(.caption2.monospacedDigit())
                .foregroundStyle(RiverheadTheme.textSecondary)
            }
        }
    }
}

fileprivate struct ExecutiveFundingStack: View {
    @Environment(\.colorScheme) private var scheme

    let items: [ExecutiveBridgeItem]
    let total: Double

    var body: some View {
        GeometryReader { proxy in
            let safeTotal = max(total, 1)
            let width = proxy.size.width
            let barHeight: CGFloat = 24

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 3) {
                    ForEach(items) { item in
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [item.tint.opacity(0.95), item.tint.opacity(0.66)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: max(width * item.amount / safeTotal - 2, 8), height: barHeight)
                            .accessibilityLabel("\(item.label), \(item.amount.formatted(.currency(code: "USD").precision(.fractionLength(0))))")
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(RiverheadTheme.background.opacity(scheme == .dark ? 0.42 : 0.72))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(RiverheadTheme.border.opacity(0.45), lineWidth: 0.8)
                )

                HStack {
                    Text("Funding sources")
                    Spacer()
                    Text(total.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                        .monospacedDigit()
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(RiverheadTheme.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

fileprivate struct ExecutiveFundingRow: View {
    let item: ExecutiveBridgeItem
    let total: Double
    let valueText: String

    private var share: Double {
        guard total > 0 else { return 0 }
        return min(max(item.amount / total, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Label(item.label, systemImage: item.labelSymbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(valueText)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(item.tint)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(RiverheadTheme.border.opacity(0.22))
                    Capsule()
                        .fill(item.tint.opacity(0.88))
                        .frame(width: max(proxy.size.width * share, 8))
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .combine)
    }
}

fileprivate struct ExecutiveBridgeImpactRow: View {
    @Environment(\.colorScheme) private var scheme

    let item: ExecutiveBridgeItem
    let maximum: Double
    let valueText: String

    private var share: Double {
        min(max(abs(item.amount) / max(maximum, 1), 0), 1)
    }

    private var isOffset: Bool {
        item.amount >= 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label(item.label, systemImage: isOffset ? "plus.circle.fill" : "minus.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(valueText)
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(isOffset ? .green : RiverheadTheme.brandCoral)
            }

            GeometryReader { proxy in
                let center = proxy.size.width * 0.46
                let available = proxy.size.width * 0.46
                let barWidth = max(available * share, 9)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(RiverheadTheme.border.opacity(scheme == .dark ? 0.22 : 0.18))
                        .frame(height: 12)
                    Rectangle()
                        .fill(RiverheadTheme.border.opacity(0.48))
                        .frame(width: 1.2, height: 18)
                        .offset(x: center)
                    Capsule()
                        .fill(item.tint.opacity(0.9))
                        .frame(width: barWidth, height: 12)
                        .offset(x: isOffset ? center : center - barWidth)
                }
            }
            .frame(height: 18)

            Text(item.role)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(RiverheadTheme.textSecondary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(item.tint.opacity(scheme == .dark ? 0.12 : 0.07))
        )
        .accessibilityElement(children: .combine)
    }
}

fileprivate extension ExecutiveBridgeItem {
    var labelSymbol: String {
        switch label {
        case "Estimated revenues":
            return "arrow.down.forward.circle.fill"
        case "Tax levy":
            return "house.and.flag.fill"
        case "Fund balance use":
            return "banknote.fill"
        default:
            return amount >= 0 ? "plus.circle.fill" : "minus.circle.fill"
        }
    }
}

fileprivate struct BudgetAmountDonut: View {
    @Environment(\.colorScheme) private var scheme

    let items: [BudgetVisualAmount]
    let total: Double
    let centerValue: String
    let centerLabel: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(RiverheadTheme.border.opacity(scheme == .dark ? 0.42 : 0.24), lineWidth: 16)

            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let start = cumulativeValue(before: index) / max(total, 1)
                let end = cumulativeValue(through: index) / max(total, 1)

                Circle()
                    .trim(from: start, to: end)
                    .stroke(
                        item.tint,
                        style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .accessibilityLabel("\(item.title), \(item.amount.formatted(.currency(code: "USD").precision(.fractionLength(0))))")
            }

            VStack(spacing: 2) {
                Text(centerValue)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(centerLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textSecondary)
            }
            .padding(18)
        }
        .padding(9)
        .accessibilityElement(children: .combine)
    }

    private func cumulativeValue(before index: Int) -> Double {
        items.prefix(index).map(\.amount).reduce(0, +)
    }

    private func cumulativeValue(through index: Int) -> Double {
        items.prefix(index + 1).map(\.amount).reduce(0, +)
    }
}

fileprivate struct BudgetVisualBarRow: View {
    let item: BudgetVisualAmount
    let maximum: Double
    let valueText: String

    private var share: Double {
        min(max(item.amount / max(maximum, 1), 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Image(systemName: item.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(item.tint)
                    .frame(width: 18)

                Text(item.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 6)

                Text(valueText)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(item.tint)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(RiverheadTheme.border.opacity(0.20))
                    Capsule()
                        .fill(item.tint.opacity(0.86))
                        .frame(width: max(proxy.size.width * share, 8))
                }
            }
            .frame(height: 7)
        }
        .accessibilityElement(children: .combine)
    }
}

fileprivate struct BudgetPlanStepRow: View {
    let step: BudgetPlanStep
    let maximum: Double
    let valueText: String

    private var isPositive: Bool {
        step.amount >= 0
    }

    private var share: Double {
        min(max(abs(step.amount) / max(maximum, 1), 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(step.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(valueText)
                    .font(.caption2.monospacedDigit().weight(.bold))
                    .foregroundStyle(isPositive ? .green : RiverheadTheme.brandCoral)
            }

            GeometryReader { proxy in
                let center = proxy.size.width * 0.48
                let available = proxy.size.width * 0.46
                let width = max(available * share, 8)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(RiverheadTheme.border.opacity(0.18))
                        .frame(height: 10)
                    Rectangle()
                        .fill(RiverheadTheme.border.opacity(0.46))
                        .frame(width: 1, height: 16)
                        .offset(x: center)
                    Capsule()
                        .fill(step.tint.opacity(0.88))
                        .frame(width: width, height: 10)
                        .offset(x: isPositive ? center : center - width)
                }
            }
            .frame(height: 16)
        }
        .accessibilityElement(children: .combine)
    }
}

@MainActor
fileprivate struct OverviewStoryView: View {
    let mode: BudgetAudienceMode

    @Environment(RBBudgetStore.self) private var store

    // Cards differ by mode: resident gets plain-language questions; expert gets fiscal metrics.
    private var residentCards: [OverviewStoryCard] {
        [
            .init(symbol: "chart.line.uptrend.xyaxis",
                  title: "Is the Town living within its means?",
                  blurb: "The 2026 tentative budget totals $69.1 million — up from $64.9M in 2025. Levy growth is subject to NY's 2% property tax cap.",
                  tag: "Big picture"),
            .init(symbol: "banknote.fill",
                  title: "Is the savings account healthy?",
                  blurb: "Riverhead's 2025 Annual Financial Report shows the General Fund finished 2025 with about $33.4M in fund balance and total governmental funds ended 2025 at about $76.55M, leaving Riverhead with a large cushion well above the 15% policy floor.",
                  tag: "Fund balance"),
            .init(symbol: "list.bullet.rectangle.fill",
                  title: "What's changing in 2026?",
                  blurb: "Police personal services (+$1.65M), employee benefits (+$1.12M), and a one-time Ambulance District equipment purchase (+$610K) are the biggest drivers.",
                  tag: "Changes"),
            .init(symbol: "person.2.wave.2.fill",
                  title: "For tonight's hearing…",
                  blurb: "Ask about recurring vs one-time costs, how much fund balance is being used and whether the policy surplus will be maintained.",
                  tag: "Hearing"),
            .init(symbol: "checkmark.seal.fill",
                  title: "What should a balanced 2027 budget include?",
                  blurb: BudgetRecommendations2027.residentSummary,
                  tag: "2027")
        ]
    }

    private var expertCards: [OverviewStoryCard] {
        [
            .init(symbol: "chart.bar.fill",
                  title: "2026 Tentative: $69,113,159 appropriations",
                  blurb: "+6.5% over 2025 adopted ($64,895,000). General Fund carries most of the growth via personal services and benefits. Tax cap compliance: verify levy does not exceed the calculated limit.",
                  tag: "Fiscal summary"),
            .init(symbol: "banknote.fill",
                  title: "Fund balance: $29,671,084 unassigned",
                  blurb: "Riverhead's 2025 Annual Financial Report shows the General Fund ended 2025 with about $33.4M in fund balance and total governmental funds rose to about $76.55M. That still reads as a very large operating cushion relative to Riverhead's 15% floor and 20% upper target.",
                  tag: "Fund balance"),
            .init(symbol: "arrow.up.right.circle.fill",
                  title: "Key cost drivers",
                  blurb: "Personnel (Police +6.8%, Highway +4.9%) and benefits (+5.4%) are structural. Ambulance equipment (+108%) is one-time. Confirm exclusions from the tax cap base.",
                  tag: "Appropriations"),
            .init(symbol: "scroll.fill",
                  title: "Debt & capital posture",
                  blurb: "No new long-term bonds proposed in the 2026 tentative. Debt service appropriations remain modest. BANs outstanding in Capital Fund should be monitored for conversion.",
                  tag: "Debt"),
            .init(symbol: "checkmark.seal.fill",
                  title: "2027 balanced-budget package",
                  blurb: BudgetRecommendations2027.expertSummary,
                  tag: "2027")
        ]
    }

    private var cards: [OverviewStoryCard] {
        mode == .resident ? residentCards : expertCards
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassCard(
                title: "Budget story at a glance",
                subtitle: mode == .resident
                    ? "A few quick cards that walk you through the big questions, in plain language."
                    : "Key fiscal metrics for the 2026 Tentative Budget. Tap a section chip above to drill deeper."
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(cards) { card in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: card.symbol)
                                .font(.title3)
                                .foregroundStyle(RiverheadTheme.accent)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(card.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(RiverheadTheme.textPrimary)
                                    Spacer()
                                    Text(card.tag.uppercased())
                                        .font(.caption2.weight(.bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(RiverheadTheme.Surface.card.opacity(0.9))
                                        .clipShape(Capsule())
                                }
                                Text(card.blurb)
                                    .font(.footnote)
                                    .foregroundStyle(RiverheadTheme.textSecondary)
                            }
                        }

                        if card.id != cards.last?.id {
                            Divider().opacity(0.2)
                        }
                    }
                }
            }

            SourcesStrip(links: [
                .init(title: "2026 Tentative Budget",
                      kind: .budgetBook,
                      note: nil,
                      url: URL(string: "https://www.townofriverheadny.gov/DocumentCenter/View/2779/2026-Tentative-Budget-PDF")),
                .init(title: "2026 Budget Supplement",
                      kind: .budgetBook,
                      note: nil,
                      url: URL(string: "https://www.townofriverheadny.gov/DocumentCenter/View/2780/2026-Budget-Supplement-PDF"))
            ])
        }
    }
}

// MARK: - 2) My Taxes Lab

struct PropertyTaxEstimate {
    let currentBill: Double
    let priorBill: Double
    let levyImpact: Double
    let assessmentImpact: Double
}

struct PropertyTaxScenario {
    var marketValue: Double
    var inVillage: Bool
    var levyChangePercent: Double
}

fileprivate enum PropertyTaxEngine {
    // Riverhead 2026 Adopted Budget, rate table p. 6 ("Total Town Wide") — the Town's own
    // published rate is per $1,000 of ASSESSED value, not full market value:
    // General Fund 61.948 + Highway 8.695 + Street Lighting 0.955 = 71.598.
    // Suffolk County towns assess residential property at a small fraction of full market
    // value rather than at 100%; MyTaxesView.swift's sourced Receiver of Taxes sheet cites a
    // 7.44% residential assessment ratio, which this reuses to convert a resident's market
    // value into an assessed value before applying the real rate.
    //
    // A prior version of this calculator assumed ~$2.25 per $1,000 of full market value, which
    // does not reconcile with the Town's published numbers — converting the real rate via the
    // residential assessment ratio gives ~$5.33 per $1,000 of full value, more than double.
    //
    // Basic STAR is a New York SCHOOL tax exemption (RPTL 425) and does not reduce this
    // Town-only bill, so unlike an earlier version, it is not modeled here.
    static let totalTownWideRatePerThousandAssessed: Double = 71.598
    static let residentialAssessmentRatio: Double = 0.0744

    static func estimate(for scenario: PropertyTaxScenario) -> PropertyTaxEstimate {
        let assessedValue = max(scenario.marketValue, 0.0) * residentialAssessmentRatio
        let assessedThousand = assessedValue / 1_000.0

        // Current-year bill already reflects the levy change baked into the 2026 rate.
        let currentBill = assessedThousand * totalTownWideRatePerThousandAssessed

        // Back-calculate prior-year bill by removing the levy change.
        let priorBill = currentBill / (1.0 + scenario.levyChangePercent / 100.0)

        let levyImpact = currentBill - priorBill

        return .init(currentBill: currentBill,
                     priorBill: priorBill,
                     levyImpact: levyImpact,
                     assessmentImpact: 0.0)
    }

    static func billForAlternativeLevy(
        priorBill: Double,
        altLevyChangePercent: Double
    ) -> Double {
        // ("what if last year's bill had grown by X% instead of the actual amount?") is answered
        // by applying the alternative levy change to the same prior-year baseline bill. Takes
        // priorBill directly rather than a scenario so callers that already have an estimate()
        // result don't pay for computing it twice.
        priorBill * (1.0 + altLevyChangePercent / 100.0)
    }
}

@MainActor
fileprivate struct MyTaxesLabView: View {
    let mode: BudgetAudienceMode

    @Environment(RBBudgetStore.self) private var store

    @State private var marketValue: Double = 550_000.0
    @State private var inVillage: Bool = false
    @State private var levyChangePercent: Double = 3.0
    @State private var altLevyChangePercent: Double = 1.0

    private var scenario: PropertyTaxScenario {
        .init(marketValue: marketValue,
              inVillage: inVillage,
              levyChangePercent: levyChangePercent)
    }

    var body: some View {
        let estimate = PropertyTaxEngine.estimate(for: scenario)
        let altBill = PropertyTaxEngine.billForAlternativeLevy(
            priorBill: estimate.priorBill,
            altLevyChangePercent: altLevyChangePercent
        )

        VStack(alignment: .leading, spacing: 16) {
            GlassCard(
                title: "My sample tax bill",
                subtitle: mode == .resident
                    ? "Enter your property value and see how the 2026 town levy affects your bill. This estimates the General Fund, Highway, and Street Lighting charges together — not county, school, or special-district taxes, and not a school-tax STAR exemption, which doesn't apply to these town charges."
                    : "2026 Total Town Wide rate: $71.598 per $1,000 of assessed value (General Fund $61.948 + Highway $8.695 + Street Lighting $0.955, per the 2026 Adopted Budget). Market value is converted to assessed value using the 7.44% residential assessment ratio. Adjust levy change to model different adoption scenarios."
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Market value")
                        Spacer()
                        Text(marketValue, format: .currency(code: "USD"))
                            .fontWeight(.semibold)
                    }
                    Slider(value: $marketValue,
                           in: 200_000.0...1_200_000.0,
                           step: 10_000.0)

                    Toggle("Inside a village", isOn: $inVillage)

                    HStack {
                        Text("2026 levy change vs 2025")
                        Spacer()
                        Text("\(levyChangePercent, specifier: "%.1f")%")
                            .fontWeight(.semibold)
                    }
                    Slider(value: $levyChangePercent, in: -2.0...6.0, step: 0.5)

                    if mode == .expert {
                        Text("NY property tax cap formula: prior levy, reserve offset, TBGF, allowable levy growth factor, PILOT adjustments, carryover, and exclusions. OSC's March 2026 table shows the 2026 calendar-year inflation factor at 2.64%, which still yields a 1.0200 allowable levy growth factor.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Divider().opacity(0.3)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("This year (town portion only)")
                            Spacer()
                            Text(estimate.currentBill, format: .currency(code: "USD"))
                                .font(.title3.weight(.semibold))
                        }

                        HStack {
                            Text("Last year (estimated)")
                            Spacer()
                            Text(estimate.priorBill, format: .currency(code: "USD"))
                        }
                        .foregroundStyle(RiverheadTheme.textSecondary)

                        HStack {
                            Text("Change vs last year")
                            Spacer()
                            let diff = estimate.currentBill - estimate.priorBill
                            let sign = diff >= 0 ? "+" : "–"
                            Text("\(sign)\(abs(diff), format: .currency(code: "USD"))")
                                .foregroundStyle(diff >= 0 ? .orange : .green)
                        }
                        .font(.subheadline.weight(.semibold))

                        Text(
                            mode == .resident
                            ? "This is only the Town's portion of your bill. County, school, and special district levies are separate."
                            : "Total Town Wide rate $71.598/$1,000 assessed (2026 adopted). About \(estimate.levyImpact, format: .currency(code: "USD")) of the change is attributable to the proposed levy increase."
                        )
                        .font(.caption)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                    }
                }
            }

            GlassCard(
                title: "What-if: different levy change?",
                subtitle: mode == .resident
                    ? "See how your bill would change if the Town adopted a smaller or larger levy increase."
                    : "Model alternative adoption scenarios — useful for comparing the cap limit vs a tax freeze vs a higher increase."
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Alternative levy change")
                        Spacer()
                        Text("\(altLevyChangePercent, specifier: "%.1f")%")
                            .fontWeight(.semibold)
                    }
                    Slider(value: $altLevyChangePercent, in: -2.0...6.0, step: 0.5)

                    let bill = altBill
                    let baseBill = estimate.currentBill
                    let diff = bill - baseBill

                    HStack {
                        Text("If the levy changed by \(altLevyChangePercent, specifier: "%.1f")%…")
                        Spacer()
                    }
                    .font(.footnote.weight(.semibold))

                    HStack {
                        Text("Your sample bill would be")
                        Spacer()
                        Text(bill, format: .currency(code: "USD"))
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("vs proposed scenario")
                        Spacer()
                        let sign = diff >= 0 ? "+" : "–"
                        Text("\(sign)\(abs(diff), format: .currency(code: "USD"))")
                            .foregroundStyle(diff >= 0 ? .orange : .green)
                    }
                    .font(.subheadline)
                }
            }

            SourcesStrip(links: [
                .init(title: "2026 Tentative Budget – Tax Cap section",
                      kind: .budgetBook,
                      note: nil,
                      url: URL(string: "https://www.townofriverheadny.gov/DocumentCenter/View/2779/2026-Tentative-Budget-PDF"))
            ])
        }
    }
}

// MARK: - 3) Fund Balance Dashboard

struct FundBalanceSnapshot: Identifiable {
    enum Health { case healthy, watch, atRisk }

    let id = UUID()
    let fundName: String
    let expenditures: Double
    let totalFundBalance: Double
    let unassigned: Double
    let policyMinimumPercent: Double // e.g. 0.15

    var percentOfExpenditures: Double {
        expenditures == 0 ? 0 : totalFundBalance / expenditures
    }

    var health: Health {
        if percentOfExpenditures >= policyMinimumPercent * 1.15 {
            return .healthy
        } else if percentOfExpenditures >= policyMinimumPercent {
            return .watch
        } else {
            return .atRisk
        }
    }
}

struct CommunityGrant: Identifiable {
    let id = UUID()
    let organization: String
    let focus: String
    let amount: Double
}

fileprivate struct FundBalanceDeploymentOption: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let amount: Double
    let detail: String
}

fileprivate struct PeerFundBalanceBenchmark: Identifiable {
    let id = UUID()
    let town: String
    let percent: Double
    let detail: String
}

fileprivate struct PeerAlignmentScenario: Identifiable {
    let id = UUID()
    let label: String
    let percent: Double
    let targetBalance: Double
    let deploymentCapacity: Double
    let detail: String
}

@MainActor
fileprivate struct FundBalanceDashboardView: View {
    let mode: BudgetAudienceMode

    @Environment(RBBudgetStore.self) private var store

    private let targetReservePercent = 0.288

    // Real 2026 Tentative Budget figures from RBBudgetStore.
    // General Fund: appropriations $69,113,159 · estimated unassigned fund balance $29,671,084.
    // Policy: 15% minimum, 20% upper target.
    private var snapshots: [FundBalanceSnapshot] {
        [
            .init(
                fundName: "General Fund",
                expenditures: store.appropriations,          // $69,113,159
                totalFundBalance: store.estimatedFundBalance, // $29,671,084
                unassigned: store.estimatedFundBalance,
                policyMinimumPercent: store.fundBalancePolicy.minimumPercent  // 0.15
            )
        ]
    }

    private var currentUnassigned: Double { store.estimatedFundBalance }
    private var targetUnassignedAt288: Double { store.appropriations * targetReservePercent }
    private var deployableAbove288: Double { max(0, currentUnassigned - targetUnassignedAt288) }

    private var deploymentOptions: [FundBalanceDeploymentOption] {
        [
            .init(
                number: 1,
                title: "Clean up the current General Fund mismatch",
                amount: 74_283,
                detail: "Use one-time money first to close the current A01 imbalance identified in the 2026 supplement before calling anything else balanced."
            ),
            .init(
                number: 2,
                title: "Crush BAN interest before it compounds",
                amount: 1_233_750,
                detail: "The 2026 adopted budget shows BAN interest in the Debt Service Fund at about $1.234M. A one-time reserve deployment here directly reduces financing drag."
            ),
            .init(
                number: 3,
                title: "Retire BAN principal early",
                amount: 1_025_000,
                detail: "The adopted V01 debt schedule also carries about $1.025M of BAN principal. Paying that down reduces rollover risk and future interest exposure."
            ),
            .init(
                number: 4,
                title: "Use excess fund balance for CPF debt reduction",
                amount: BudgetRecommendations2027.cpfAccelerationPayment,
                detail: "Riverhead's CPF debt began as roughly $70M borrowed against future fund revenue, was refunded in 2016, and RiverheadLOCAL reported about $12.29M still outstanding as of December 31, 2024. Using some excess fund balance for a one-time CPF principal payment should lower future interest cost and shorten the payoff path."
            ),
            .init(
                number: 5,
                title: "File a round of community block grants",
                amount: BudgetRecommendations2027.communityBlockGrantsTotal,
                detail: "Reserve one-time grant applications to four community-service nonprofits serving Riverhead and the East End as targeted community-support investments that do not create a recurring operating obligation. See the breakdown below."
            ),
            .init(
                number: 6,
                title: "Launch a community improvement micro-grant series",
                amount: BudgetRecommendations2027.communityImprovementGrantSeries,
                detail: "Reserve one-time funding for a visible run of small grants of about $500 to $1,000 each, up to $50,000 total, for block-scale beautification, civic ideas, or neighborhood improvement projects."
            ),
            .init(
                number: 7,
                title: "Fund a visible innovation and service package",
                amount: BudgetRecommendations2027.addedServiceInvestments,
                detail: "This covers the app's current improvement package: building capacity, online modernization, added code enforcement, one Town Clerk position, and two police positions."
            )
        ]
    }

    private var remainingAfterDeploymentOptions: Double {
        max(0, deployableAbove288 - deploymentOptions.reduce(0) { $0 + $1.amount })
    }

    private var peerBenchmarks: [PeerFundBalanceBenchmark] {
        [
            .init(
                town: "Riverhead target",
                percent: targetReservePercent,
                detail: "Modeled target for this plan: 28.8% of the General Fund budget after one-time deployment."
            ),
            .init(
                town: "Brookhaven",
                percent: 60_023_184 / 154_611_894,
                detail: "Brookhaven's 2026 adopted General Town Wide unreserved fund balance is about $60.0M against about $154.6M of budgeted expenditures, or roughly 38.8%."
            ),
            .init(
                town: "Smithtown",
                percent: 24_099_593 / 60_384_813,
                detail: "Smithtown's 2026 tentative General Fund projected fund balance is about $24.1M against roughly $60.4M of projected annual scale, or about 39.9%."
            ),
            .init(
                town: "East Hampton",
                percent: (29_709_031 + 19_034_693) / 86_782_601,
                detail: "East Hampton's 2026 adopted General Fund projection totals about $48.7M across whole-town and part-town balances against roughly $86.8M of General Fund appropriations, or about 56.2%."
            ),
            .init(
                town: "Southampton policy",
                percent: 0.17,
                detail: "Southampton's 2026 adopted financial policy sets a general-fund reserve structure of 10% restricted plus at least 7% unallocated, for a 17% benchmark."
            )
        ]
    }

    private var peerAlignmentScenarios: [PeerAlignmentScenario] {
        let allPeerAverage = peerBenchmarks
            .filter { $0.town != "Riverhead target" }
            .map(\.percent)
            .reduce(0, +) / 4

        return [
            scenario(label: "Match Brookhaven", percent: 60_023_184 / 154_611_894,
                     detail: "A Brookhaven-style posture would still leave Riverhead with a large cushion and only modest one-time deployment capacity."),
            scenario(label: "Match Smithtown", percent: 24_099_593 / 60_384_813,
                     detail: "A Smithtown-style posture lands close to Brookhaven and still preserves most of Riverhead's current reserve strength."),
            scenario(label: "Match East Hampton", percent: (29_709_031 + 19_034_693) / 86_782_601,
                     detail: "An East Hampton-style posture would require Riverhead to hold more back than it has now, so it reads as a high-reserve outlier rather than a practical deployment target."),
            scenario(label: "Match Southampton policy", percent: 0.17,
                     detail: "A Southampton-style policy floor would release a very large amount of one-time money, but it is much leaner than Riverhead's current posture and likely too aggressive as a first reset."),
            scenario(label: "Match average of peers", percent: allPeerAverage,
                     detail: "Using the simple average of Brookhaven, Smithtown, East Hampton, and Southampton lands Riverhead near 38.0%, still notably above the current 28.8% target.")
        ]
    }

    private func scenario(label: String, percent: Double, detail: String) -> PeerAlignmentScenario {
        let targetBalance = store.appropriations * percent
        return .init(
            label: label,
            percent: percent,
            targetBalance: targetBalance,
            deploymentCapacity: currentUnassigned - targetBalance,
            detail: detail
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassCard(
                title: "Policy compliance at a glance",
                subtitle: mode == .resident
                    ? "How the Town's savings stack up against its own reserve rules."
                    : "Unassigned fund balance vs. adopted 15% minimum and 20% upper target."
            ) {
                VStack(spacing: 10) {
                    ForEach(snapshots) { snap in
                        FundBalanceCardView(snapshot: snap, mode: mode)
                        if snap.id != snapshots.last?.id {
                            Divider().opacity(0.25)
                        }
                    }

                    if mode == .expert, let upper = store.targetUpper {
                        Divider().opacity(0.2)
                        HStack {
                            Text("Policy upper target (20%)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(upper, format: .currency(code: "USD"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        let surplus = store.estimatedFundBalance - upper
                        HStack {
                            Text("Surplus above upper target")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(surplus, format: .currency(code: "USD"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(surplus >= 0 ? .green : .orange)
                        }
                        Text("A balance above the upper target may be a candidate for appropriation to reduce the levy or fund one-time capital.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            GlassCard(
                title: mode == .resident ? "28.8% Reserve Reset" : "Deployment Scenario: 41.1% to 28.8%",
                subtitle: mode == .resident
                    ? "A playful one-time-money plan: keep a big cushion, use the rest on purpose, and show what still fits after the serious bills are paid."
                    : "Modeled from the 2026 adopted General Fund balance. This scenario lowers unassigned fund balance to 28.8% of appropriations and then sequences one-time deployments."
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Current unassigned balance")
                        Spacer()
                        Text(currentUnassigned, format: .currency(code: "USD"))
                            .fontWeight(.semibold)
                    }
                    .font(.footnote)

                    HStack {
                        Text("28.8% target balance")
                        Spacer()
                        Text(targetUnassignedAt288, format: .currency(code: "USD"))
                            .fontWeight(.semibold)
                    }
                    .font(.footnote)

                    HStack {
                        Text("Available for one-time deployment")
                        Spacer()
                        Text(deployableAbove288, format: .currency(code: "USD"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.accent)
                    }

                    Text(mode == .resident
                         ? "Think of this as a small numbered list of good uses for one-time money: fix the mismatch, reduce avoidable debt cost, help the CPF get lighter faster, then see what remains for better public service."
                         : "The point is to convert surplus cushion into intentional one-time uses rather than letting excess reserves sit without a deployment policy, while visibly lowering future financing drag.")
                        .font(.caption)
                        .foregroundStyle(RiverheadTheme.textSecondary)

                    Divider().opacity(0.25)

                    ForEach(deploymentOptions) { option in
                        HStack(alignment: .top, spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(RiverheadTheme.accent.opacity(0.14))
                                    .frame(width: 28, height: 28)
                                Text("\(option.number)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(RiverheadTheme.accent)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(option.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(RiverheadTheme.textPrimary)
                                    Spacer()
                                    Text(option.amount, format: .currency(code: "USD"))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(RiverheadTheme.gold)
                                }
                                Text(option.detail)
                                    .font(.caption)
                                    .foregroundStyle(RiverheadTheme.textSecondary)
                            }
                        }

                        if option.id != deploymentOptions.last?.id {
                            Divider().opacity(0.18)
                        }
                    }

                    Divider().opacity(0.25)

                    HStack {
                        Text("Still available after these deployments")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(remainingAfterDeploymentOptions, format: .currency(code: "USD"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }

                    Text(mode == .resident
                         ? "That remaining amount is room for future innovation, policy pilots, downtown improvements, technology upgrades, or other one-time public investments without dropping below the 28.8% target."
                         : "Remaining capacity could be assigned by board resolution to innovation, policy modernization, programmatic pilots, or additional debt reduction while preserving a materially stronger reserve position than the current policy floor.")
                        .font(.caption2)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                }
            }

            GlassCard(
                title: "Community block grants — who would get funded",
                subtitle: "The breakdown behind deployment option #5 above: four nonprofits serving Riverhead and the East End. These amounts are the app's own illustrative sizing, not an official Town budget line or commitment."
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(BudgetRecommendations2027.communityBlockGrants) { grant in
                        HStack(alignment: .top, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(grant.organization)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RiverheadTheme.textPrimary)
                                Text(grant.focus)
                                    .font(.caption)
                                    .foregroundStyle(RiverheadTheme.textSecondary)
                            }
                            Spacer()
                            Text(grant.amount, format: .currency(code: "USD"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RiverheadTheme.gold)
                        }
                        if grant.id != BudgetRecommendations2027.communityBlockGrants.last?.id {
                            Divider().opacity(0.18)
                        }
                    }
                }
            }

            GlassCard(
                title: mode == .resident ? "How 28.8% compares nearby" : "Peer reserve comparison",
                subtitle: mode == .resident
                    ? "Riverhead's target lands below what Brookhaven and Smithtown are doing today, but above Southampton's official policy."
                    : "Peer check using official 2026 documents where available. Brookhaven and Smithtown are shown as current budget-position benchmarks; Southampton is shown as an adopted policy benchmark."
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(peerBenchmarks) { peer in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(peer.town)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RiverheadTheme.textPrimary)
                                Spacer(minLength: 8)
                                Text(peer.percent, format: .percent.precision(.fractionLength(1)))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(peer.town == "Riverhead target" ? RiverheadTheme.accent : RiverheadTheme.gold)
                            }

                            Text(peer.detail)
                                .font(.caption)
                                .foregroundStyle(RiverheadTheme.textSecondary)
                        }

                        if peer.id != peerBenchmarks.last?.id {
                            Divider().opacity(0.18)
                        }
                    }

                    Divider().opacity(0.25)

                    Text(mode == .resident
                         ? "Benchmark note: GFOA guidance commonly points to at least two months of regular operating spending or revenue in unrestricted fund balance, which is about 16.7% to 17%. That helps explain why Southampton's 17% policy reads more like a minimum floor than a default Riverhead target."
                         : "Benchmark note: GFOA best practice sets a minimum unrestricted General Fund balance of no less than two months of regular revenues or expenditures, or about 16.7%. That supports reading 17% as a floor benchmark, while Riverhead's operating target can reasonably sit above it because local reserve needs are not one-size-fits-all.")
                        .font(.caption2)
                        .foregroundStyle(RiverheadTheme.textSecondary)

                    Divider().opacity(0.25)

                    Text(mode == .resident
                         ? "That makes 28.8% a middle path: still a strong cushion, but less oversized than some peers and still well above Southampton's published floor."
                         : "Inference from the cited documents: a 28.8% Riverhead target would remain conservatively above Southampton's adopted policy benchmark while moving materially below Brookhaven and Smithtown's current reserve posture.")
                        .font(.caption2)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                }
            }

            GlassCard(
                title: mode == .resident ? "What if Riverhead matched its peers?" : "Peer-alignment scenarios",
                subtitle: mode == .resident
                    ? "See how much one-time room Riverhead would have if it matched a neighboring town's reserve levels — or the average of them all."
                    : "Scenario math using Riverhead's current General Fund balance and peer percentages from official 2026 documents or adopted policy."
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(peerAlignmentScenarios) { peer in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(peer.label)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RiverheadTheme.textPrimary)
                                Spacer(minLength: 8)
                                Text(peer.percent, format: .percent.precision(.fractionLength(1)))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(RiverheadTheme.gold)
                            }

                            HStack {
                                Text("Target balance")
                                    .font(.caption)
                                    .foregroundStyle(RiverheadTheme.textSecondary)
                                Spacer()
                                Text(peer.targetBalance, format: .currency(code: "USD"))
                                    .font(.caption.weight(.semibold))
                            }

                            HStack {
                                Text(peer.deploymentCapacity >= 0 ? "One-time room created" : "Additional reserve needed")
                                    .font(.caption)
                                    .foregroundStyle(RiverheadTheme.textSecondary)
                                Spacer()
                                Text(abs(peer.deploymentCapacity), format: .currency(code: "USD"))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(peer.deploymentCapacity >= 0 ? .green : .orange)
                            }

                            Text(peer.detail)
                                .font(.caption)
                                .foregroundStyle(RiverheadTheme.textSecondary)
                        }

                        if peer.id != peerAlignmentScenarios.last?.id {
                            Divider().opacity(0.18)
                        }
                    }

                    Divider().opacity(0.25)

                    Text(mode == .resident
                         ? "Ideal guidance: treat 17% like a GFOA-style minimum floor, not the automatic target. East Hampton's 56.2% reads like a high-cushion outlier, and Brookhaven's value is less about a reserve target than its discipline: major districts balanced without fund balance, visible estimated fund balances, and service-specific user-fee transparency. For Riverhead, a practical operating range is still roughly 25% to 32%, with 28.8% as a strong middle path that leaves room for debt reduction and one-time public improvements."
                         : "Guidance: Southampton functions more like a GFOA-aligned minimum-policy benchmark, while East Hampton reads as a high-reserve outlier. For Riverhead, a board-adopted operating range around 25% to 32%, with deployment above that range restricted to one-time uses, appears more defensible than copying either extreme. The peer value is in the operating practices: East Hampton offers a visible levy-analysis sheet, fund-balance projections, all-funds employee-benefit summary, contingency line, and homeowner tax-impact examples, while Brookhaven shows structurally balanced major districts without fund balance, estimated fund-balance pages up front, and service-specific user-fee disclosure.")
                        .font(.caption2)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                }
            }

            GlassCard(
                title: mode == .resident
                    ? "What if the Town uses some savings?"
                    : "Scenario: draw-down impact on policy compliance",
                subtitle: mode == .resident
                    ? "See how using reserves for tax relief or a project would affect the cushion."
                    : "How much of the unassigned balance can be drawn before breaching the 15% minimum floor."
            ) {
                ScenarioFundBalanceStrip(snapshots: snapshots)
            }

            SourcesStrip(links: [
                .init(title: "2026 Tentative Budget",
                      kind: .budgetBook,
                      note: nil,
                      url: URL(string: "https://www.townofriverheadny.gov/DocumentCenter/View/2779/2026-Tentative-Budget-PDF")),
                .init(title: "2026 Budget Supplement",
                      kind: .budgetBook,
                      note: nil,
                      url: URL(string: "https://www.townofriverheadny.gov/DocumentCenter/View/2780/2026-Budget-Supplement-PDF"))
            ])
        }
    }
}

fileprivate struct FundBalanceCardView: View {
    let snapshot: FundBalanceSnapshot
    let mode: BudgetAudienceMode


    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(snapshot.fundName)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(tag(for: snapshot.health))
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(tagColor(for: snapshot.health).opacity(0.14))
                    .foregroundStyle(tagColor(for: snapshot.health))
                    .clipShape(Capsule())
            }

            HStack {
                Text(mode == .resident ? "Current savings (unassigned)" : "Unassigned fund balance")
                Spacer()
                Text(snapshot.unassigned, format: .currency(code: "USD"))
                    .fontWeight(mode == .expert ? .semibold : .regular)
            }
            .font(.footnote)

            if mode == .expert {
                HStack {
                    Text("Annual appropriations")
                    Spacer()
                    Text(snapshot.expenditures, format: .currency(code: "USD"))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            let pct = snapshot.percentOfExpenditures
            let min = snapshot.policyMinimumPercent

            VStack(alignment: .leading, spacing: 4) {
                let total = max(pct, min * 2.0)
                ProgressView(value: pct, total: total)
                HStack {
                    Text("\(pct, format: .percent.precision(.fractionLength(1))) of annual expenses")
                        .font(.caption)
                    Spacer()
                    Text("Policy min: \(min, format: .percent.precision(.fractionLength(0)))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if mode == .resident {
                Text(snapshot.health == .healthy
                    ? "The savings cushion is above the Town's minimum policy target — a good sign."
                    : snapshot.health == .watch
                    ? "Reserves are near the policy minimum. Watch for further draw-downs."
                    : "Reserves are below the policy minimum. Ask the Town about its plan to replenish.")
                    .font(.caption2)
                    .foregroundStyle(tagColor(for: snapshot.health))
            }
        }
    }


    private func tag(for health: FundBalanceSnapshot.Health) -> String {
        switch health {
        case .healthy: return "Healthy"
        case .watch:   return "Watch"
        case .atRisk:  return "At risk"
        }
    }

    private func tagColor(for health: FundBalanceSnapshot.Health) -> Color {
        switch health {
        case .healthy: return .green
        case .watch:   return .orange
        case .atRisk:  return .red
        }
    }
}

fileprivate struct ScenarioFundBalanceStrip: View {
    let snapshots: [FundBalanceSnapshot]

    @State private var selectedFundIndex: Int = 0
    @State private var drawDownAmount: Double = 0.0

    private var selected: FundBalanceSnapshot {
        snapshots[min(selectedFundIndex, snapshots.count - 1)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Fund", selection: $selectedFundIndex) {
                ForEach(snapshots.indices, id: \.self) { idx in
                    Text(snapshots[idx].fundName).tag(idx)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text("Use for capital / tax relief")
                Spacer()
                Text(drawDownAmount, format: .currency(code: "USD"))
                    .fontWeight(.semibold)
            }
            Slider(value: $drawDownAmount,
                   in: 0.0...selected.unassigned,
                   step: 50_000.0)

            let newTotal = selected.totalFundBalance - drawDownAmount
            let newPct = selected.expenditures == 0 ? 0.0 : newTotal / selected.expenditures

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("After use, reserve would be")
                    Spacer()
                    Text(newTotal, format: .currency(code: "USD"))
                }
                .font(.footnote)

                let total = max(newPct, selected.policyMinimumPercent * 2.0)
                ProgressView(value: newPct, total: total)

                HStack {
                    Text("\(newPct, format: .percent.precision(.fractionLength(1))) of annual expenses")
                        .font(.caption)
                    Spacer()
                    Text("Policy min: \(selected.policyMinimumPercent, format: .percent.precision(.fractionLength(0)))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(
                    newPct >= selected.policyMinimumPercent
                    ? "This scenario keeps you at or above the policy minimum."
                    : "This scenario would drop reserves below the policy minimum; long-term sustainability may be at risk."
                )
                .font(.caption)
                .foregroundStyle(newPct >= selected.policyMinimumPercent ? .green : .red)
            }
        }
    }
}

// MARK: - 4) Capital & Debt Explorer

struct DebtInstrument: Identifiable {
    enum Kind { case ban, serialBond, other }

    let id = UUID()
    let name: String
    let kind: Kind
    let outstanding: Double
    let yearsRemaining: Int
    let ratePercent: Double
}

enum CapitalFundingChoice: String, CaseIterable, Identifiable {
    case useCash
    case banThenBond
    case bondNow

    var id: String { rawValue }

    var label: String {
        switch self {
        case .useCash:     return "Use fund balance"
        case .banThenBond: return "BAN then bond"
        case .bondNow:     return "Bond now"
        }
    }
}

@MainActor
fileprivate struct CapitalDebtExplorerView: View {
    let mode: BudgetAudienceMode

    // 2026 Tentative Budget – debt service summary from the budget document.
    // The 2026 tentative budget includes debt service appropriations across multiple funds.
    // These figures are sourced from the 2026 Budget Supplement (published Oct 1, 2025).
    private var debt: [DebtInstrument] {
        [
            .init(name: "General Fund Bonds & Notes",
                  kind: .serialBond,
                  outstanding: 4_200_000.0,
                  yearsRemaining: 10,
                  ratePercent: 2.80),
            .init(name: "Highway Fund Debt Service",
                  kind: .serialBond,
                  outstanding: 2_100_000.0,
                  yearsRemaining: 8,
                  ratePercent: 3.10),
            .init(name: "Capital Fund BANs",
                  kind: .ban,
                  outstanding: 900_000.0,
                  yearsRemaining: 1,
                  ratePercent: 3.50)
        ]
    }

    @State private var projectCost: Double = 2_000_000.0
    @State private var fundingChoice: CapitalFundingChoice = .banThenBond
    @State private var assumedInterestRate: Double = 3.5
    @State private var termYears: Double = 10.0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassCard(
                title: "Current debt picture",
                subtitle: mode == .resident
                    ? "What the Town owes on bonds and notes right now, and how long it'll take to pay off."
                    : "Outstanding principal by debt type. Debt service appropriations appear across General, Highway, and Capital funds in the 2026 tentative budget."
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(debt) { item in
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.subheadline.weight(.semibold))
                                Text(kindLabel(for: item.kind))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(item.outstanding, format: .currency(code: "USD"))
                                    .font(.subheadline.weight(.semibold))
                                Text("\(item.yearsRemaining) yrs @ \(item.ratePercent, specifier: "%.1f")%")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if item.id != debt.last?.id {
                            Divider().opacity(0.25)
                        }
                    }

                    if mode == .expert {
                        Divider().opacity(0.2)
                        Text("Total outstanding: \(debt.reduce(0) { $0 + $1.outstanding }, format: .currency(code: "USD")). BANs must be converted to long-term bonds or paid off within their term. Review the 2026 Budget Supplement for the full debt schedule.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            GlassCard(
                title: mode == .resident ? "How would a new project affect my taxes?" : "Project funding lab",
                subtitle: mode == .resident
                    ? "Try out different project costs and see what that would add to the Town's yearly debt payments."
                    : "Model BAN vs. bond vs. cash funding and compare annual payment vs. total financing cost."
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Project cost")
                        Spacer()
                        Text(projectCost, format: .currency(code: "USD"))
                            .fontWeight(.semibold)
                    }
                    Slider(value: $projectCost,
                           in: 500_000.0...15_000_000.0,
                           step: 250_000.0)

                    Picker("Funding", selection: $fundingChoice) {
                        ForEach(CapitalFundingChoice.allCases) { choice in
                            Text(choice.label).tag(choice)
                        }
                    }
                    .pickerStyle(.segmented)

                    if fundingChoice != .useCash {
                        HStack {
                            Text("Interest rate")
                            Spacer()
                            Text("\(assumedInterestRate, specifier: "%.2f")%")
                        }
                        Slider(value: $assumedInterestRate, in: 2.5...6.0, step: 0.25)

                        HStack {
                            Text("Term")
                            Spacer()
                            Text("\(Int(termYears)) years")
                        }
                        Slider(value: $termYears, in: 5.0...20.0, step: 1.0)
                    }

                    Divider().opacity(0.3)

                    let summary = summarizeScenario()

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Approx. annual impact")
                            Spacer()
                            Text(summary.annualImpact, format: .currency(code: "USD"))
                                .font(.headline.weight(.semibold))
                        }

                        HStack {
                            Text("Total financing cost over life")
                            Spacer()
                            Text(summary.totalCost, format: .currency(code: "USD"))
                        }
                        .font(.footnote)

                        Text(summary.caption)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if mode == .expert {
                            Text("Annual debt service becomes a recurring appropriation. For bond financing, the Town Board must pass a bond resolution and file with OSC.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            SourcesStrip(links: [
                .init(title: "2026 Tentative Budget",
                      kind: .budgetBook,
                      note: nil,
                      url: URL(string: "https://www.townofriverheadny.gov/DocumentCenter/View/2779/2026-Tentative-Budget-PDF")),
                .init(title: "2026 Budget Supplement",
                      kind: .budgetBook,
                      note: nil,
                      url: URL(string: "https://www.townofriverheadny.gov/DocumentCenter/View/2780/2026-Budget-Supplement-PDF"))
            ])
        }
    }

    private func kindLabel(for kind: DebtInstrument.Kind) -> String {
        switch kind {
        case .ban:        return "Bond anticipation note (BAN)"
        case .serialBond: return "Serial bond"
        case .other:      return "Other debt"
        }
    }

    private func summarizeScenario() -> (annualImpact: Double, totalCost: Double, caption: String) {
        switch fundingChoice {
        case .useCash:
            return (
                annualImpact: 0.0,
                totalCost: projectCost,
                caption: "Using fund balance avoids new debt service but reduces the unassigned reserve cushion."
            )

        case .banThenBond:
            let banYears: Double = 2.0
            let remainingYears = max(termYears - banYears, 5.0)
            let r = assumedInterestRate / 100.0
            let banInterest = projectCost * r * banYears
            let n = remainingYears
            let factor = pow(1.0 + r, n)
            let annualPayment = r == 0.0 ? projectCost / n : projectCost * (r * factor) / (factor - 1.0)
            let total = banInterest + annualPayment * n

            return (
                annualImpact: annualPayment,
                totalCost: total,
                caption: "BANs provide short-term flexibility, then convert to a long-term bond. NY law limits BANs to 5 years."
            )

        case .bondNow:
            let r = assumedInterestRate / 100.0
            let n = termYears
            let factor = pow(1.0 + r, n)
            let annualPayment = r == 0.0 ? projectCost / n : projectCost * (r * factor) / (factor - 1.0)
            let total = annualPayment * n

            return (
                annualImpact: annualPayment,
                totalCost: total,
                caption: "Bonding now locks in a level annual payment and keeps fund balance intact."
            )
        }
    }
}

// MARK: - 5) Outlier Watch

struct BudgetOutlier: Identifiable {
    let id = UUID()
    let department: String
    let category: String
    let changeDollars: Double
    let changePercent: Double
    let isOneTime: Bool
}

@MainActor
fileprivate struct OutlierWatchView: View {
    let mode: BudgetAudienceMode

    // 2026 vs 2025 adopted budget changes — sourced from the 2026 Tentative Budget and Supplement.
    // These are the largest year-over-year appropriation changes by department/category.
    private var sampleOutliers: [BudgetOutlier] {
        [
            .init(department: "Police",
                  category: "Personal Services",
                  changeDollars: 1_652_000.0,
                  changePercent: 6.8,
                  isOneTime: false),
            .init(department: "General Fund – Employee Benefits",
                  category: "Benefits",
                  changeDollars: 1_120_000.0,
                  changePercent: 5.4,
                  isOneTime: false),
            .init(department: "Ambulance District",
                  category: "Equipment & Capital",
                  changeDollars: 610_000.0,
                  changePercent: 108.0,
                  isOneTime: true),
            .init(department: "Highway",
                  category: "Personal Services",
                  changeDollars: 480_000.0,
                  changePercent: 4.9,
                  isOneTime: false),
            .init(department: "Parks & Recreation",
                  category: "Contractual",
                  changeDollars: 195_000.0,
                  changePercent: 16.2,
                  isOneTime: false)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassCard(
                title: "What changed the most?",
                subtitle: mode == .resident
                    ? "Which departments' spending jumped the most from 2025 to 2026."
                    : "Year-over-year appropriation changes by department. Source: 2026 Tentative Budget vs. 2025 Adopted Budget."
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(sampleOutliers) { item in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.department)
                                    .font(.subheadline.weight(.semibold))
                                Text(item.category)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(item.changeDollars, format: .currency(code: "USD"))
                                    .font(.footnote.weight(.semibold))
                                Text("+\(item.changePercent, specifier: "%.1f")%")
                                    .font(.caption2)
                                    .foregroundStyle(item.isOneTime ? .orange : .secondary)
                            }
                        }

                        if item.isOneTime {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                                Text(mode == .resident
                                    ? "One-time purchase — this cost should not repeat next year."
                                    : "One-time capital/equipment item. Confirm funding source (cash, BAN, or bond) and that it is not recurring in the baseline.")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }

                        if item.id != sampleOutliers.last?.id {
                            Divider().opacity(0.25)
                        }
                    }
                }
            }

            GlassCard(
                title: mode == .resident ? "Questions to ask" : "Analytical talking points",
                subtitle: mode == .resident
                    ? "Plain-language questions you can ask about the biggest budget moves."
                    : "Technically-framed questions for budget hearings and OSC compliance review."
            ) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(sampleOutliers.prefix(mode == .expert ? 5 : 3)) { item in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(RiverheadTheme.accent)
                            if mode == .resident {
                                Text("For **\(item.department)**: What is driving the \(item.changePercent, specifier: "%.1f")% increase in **\(item.category)**, and is it a one-time cost or will it grow each year?")
                                    .font(.caption)
                            } else {
                                Text("**\(item.department)** – \(item.category): +$\(item.changeDollars / 1_000, specifier: "%.0f")K (+\(item.changePercent, specifier: "%.1f")%). \(item.isOneTime ? "Identify funding source and confirm exclusion from recurring baseline." : "Confirm whether driven by contractual step increases, new FTEs, or benefit cost pass-throughs.")")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }

            SourcesStrip(links: [
                .init(title: "2026 Tentative Budget",
                      kind: .budgetBook,
                      note: nil,
                      url: URL(string: "https://www.townofriverheadny.gov/DocumentCenter/View/2779/2026-Tentative-Budget-PDF")),
                .init(title: "2025 Adopted Budget",
                      kind: .budgetBook,
                      note: nil,
                      url: URL(string: "https://www.townofriverheadny.gov/DocumentCenter/View/243/2025-Adopted-Budget-PDF"))
            ])
        }
    }
}

// MARK: - 6) Glossary

struct GlossaryTerm: Identifiable {
    let id = UUID()
    let term: String
    let shortDefinition: String
    let longExplanation: String
    let tags: [String]
}

@MainActor
fileprivate struct BudgetGlossaryView: View {
    let mode: BudgetAudienceMode

    @State private var query: String = ""

    // Resident mode: plain definitions. Expert mode: adds technical depth + NY-specific context.
    private var terms: [GlossaryTerm] {
        let base: [GlossaryTerm] = [
            .init(term: "Appropriated Fund Balance",
                  shortDefinition: "Savings intentionally used to balance the budget.",
                  longExplanation: mode == .resident
                    ? "When the Town uses existing savings as a revenue source in the budget, it is called appropriated fund balance. It can lower the tax levy but reduces the reserve cushion. That is different from an excess tax-levy reserve, which State guidance says must be set aside and used to offset the following year's levy."
                    : "Appropriated fund balance is a non-recurring revenue. Using it to balance a budget creates a structural gap in future years. GASB 54 classifies it as an assignment or as an explicit appropriation of unassigned balance. OSC flags over-reliance on one-time revenues as a fiscal stress indicator, separately requires any excess levy over the legal cap to be deferred into a dedicated interest-bearing reserve and applied as a next-year levy offset, and treats statutory reserves as legally constrained balances rather than a generic spending pool. OSC's Reserve Funds guide also warns that reserves should not be used as a parking lot for excess cash without a defined statutory purpose.",
                  tags: ["fund balance", "revenues"]),
            .init(term: "Bond Anticipation Note (BAN)",
                  shortDefinition: "Short-term borrowing that precedes a long-term bond.",
                  longExplanation: mode == .resident
                    ? "A BAN is temporary borrowing, typically up to 5 years, used to finance a project while the Town decides on permanent long-term financing."
                    : "Under NY Local Finance Law, BANs are limited to 5 years (2 for assessable improvements). Interest is paid annually; principal is rolled or converted to serial bonds. Outstanding BANs appear in the Capital Fund and must be monitored to avoid forced conversion at unfavorable rates.",
                  tags: ["debt", "capital", "BAN"]),
            .init(term: "Rate per Thousand",
                  shortDefinition: "The tax rate applied per $1,000 of assessed or full value.",
                  longExplanation: mode == .resident
                    ? "Your tax bill equals your taxable property value ÷ 1,000 × the rate per thousand. In Suffolk County, rates are applied to full market value."
                    : "Suffolk County uses a full-value (equalized) assessment system. The town-wide rate is the levy divided by the total taxable full value of all parcels in the district. Rate changes can differ from levy changes if the tax base grows or shrinks.",
                  tags: ["tax", "levy", "rate"]),
            .init(term: "Unassigned Fund Balance",
                  shortDefinition: "The freely spendable portion of the Town's reserves.",
                  longExplanation: mode == .resident
                    ? "This is the Town's main savings cushion — money not restricted for a specific purpose. Riverhead's policy requires keeping at least 15% of appropriations in this account. The Town's 2025 Annual Financial Report shows the General Fund finished 2025 with about $29.67M in unassigned fund balance, which is why reserve policy is such a live question. It is not the same thing as an excess tax-levy reserve, which would be legally earmarked for the next year's levy offset."
                    : "Under GASB 54, unassigned fund balance is the residual after restricted, committed, and assigned amounts. Riverhead's adopted policy sets a 15% floor and 20% upper target. The Town's 2025 Annual Financial Report shows the General Fund finished 2025 with about $29.67M in unassigned fund balance and total governmental funds ended 2025 at about $76.55M, reinforcing that Riverhead is operating with a cushion well above its policy floor. That general cushion should not be confused with the separate OSC reserve for an excess tax levy, which is legally committed to the following year's tax-cap offset, or with other statutory reserves that the Accounting and Reporting Manual treats as restricted fund balance.",
                  tags: ["fund balance", "policy", "GASB 54"]),
            .init(term: "Capital Projects Fund",
                  shortDefinition: "The fund used for major one-time construction and acquisition work.",
                  longExplanation: mode == .resident
                    ? "Big one-time building or site projects should usually be tracked outside the regular operating budget so residents can see the full project cost and financing plan clearly."
                    : "OSC's Accounting and Reporting Manual states that capital projects funds account for financial resources used for the acquisition or construction of capital facilities and other capital assets. OSC's Capital Projects Fund guide goes further: if a project extends beyond one year, it should be accounted for in a capital projects fund, a separate fund should generally be established for each authorized project, and detailed project records should be maintained so the board can monitor financing, expenditures, encumbrances, and overruns. That is why one-time items like Town Hall EV charging, garage projects, or major facility upgrades should be shown with their own financing path instead of being blurred into recurring operating spending.",
                  tags: ["capital", "funds", "budgeting"]),
            .init(term: "AIM / TMA",
                  shortDefinition: "State municipal aid that should be shown clearly in the budget.",
                  longExplanation: mode == .resident
                    ? "AIM is New York's regular municipal aid for towns and is paid in September. TMA is a newer extra state payment on top of AIM. If Riverhead uses either one in the budget, the two should be shown separately so people can tell what is regular aid and what is the temporary add-on."
                    : "OSC's municipal-aid page states that towns receive AIM annually in September. It also states that the 2025-26 Enacted State Budget continues Temporary Municipal Assistance (TMA), paid in August, in the same proportional share of aggregate AIM and recorded with account code 3089. For 2027 modeling, Riverhead should distinguish recurring AIM from the newer TMA layer instead of collapsing both into a generic state-aid line.",
                  tags: ["state aid", "revenues", "AIM", "TMA"]),
            .init(term: "OSC Management Guides",
                  shortDefinition: "Practical state guidance for reserve, capital, and multiyear budget decisions.",
                  longExplanation: mode == .resident
                    ? "The Comptroller's office publishes plain-language guides that local governments can use when they set reserve rules, plan capital projects, or build a longer-term budget plan."
                    : "OSC's Local Government Publications library includes management guides directly relevant to Riverhead's 2027 work, including Financial Condition Analysis, Understanding the Budget Process, Reserve Funds (February 2022), Capital Projects Fund (September 2019), Capital Assets (July 2024), Multiyear Financial Planning (September 2017), Seeking Competition in Procurement, Shared Services in Local Government, and Personal Service Cost Containment. Those guides provide a stronger technical base for policy design than ad hoc local practice alone. The financial-condition guide defines fiscal health as the ability to fund recurring expenditures with recurring revenues while maintaining services, recommends reviewing environmental, financial, and organizational indicators over roughly a 5-to-10-year horizon, and points to budget-to-actual variances, debt levels, and recurring revenue/expenditure trends as practical warning signals. The budget-process guide says budgeting is a team effort led by the budget officer, built on a formal calendar, department estimate forms, realistic assumptions, a balanced tentative budget, public hearing review, and monthly budget-to-actual monitoring after adoption. The Reserve Funds guide specifically calls for a written reserve plan, periodic board review of reasonableness, and transparent resolutions when reserve money is transferred. The Multiyear Financial Planning guide defines a best-practice 3-to-5-year outlook built from historical trends, explicit assumptions, all relevant major funds, and annual updates when conditions change. The procurement guide emphasizes board-adopted procurement policies, broad solicitation, lawful cooperative purchasing, and avoiding artificial contract splitting to bypass thresholds. The shared-services guide points to Article 5-G authority, early needs assessment, broad inclusion of stakeholders, and starting with simpler projects to build momentum. The personal-service guide adds more specific labor-cost levers: periodic health-plan competition with NYSHIP as a benchmark, cash payments in lieu of coverage where lawful, Section 125 pre-tax savings, invoice and eligibility checks on health-insurance bills, review of whether unemployment reimbursement is cheaper than tax contributions for a stable workforce, workers' compensation classification and claims controls, and written overtime plans with alternate schedule analysis where service delivery allows.",
                  tags: ["OSC", "guidance", "capital", "reserves"]),
            .init(term: "Financial Condition",
                  shortDefinition: "Whether the Town can sustain services with recurring revenues and healthy reserves over time.",
                  longExplanation: mode == .resident
                    ? "Financial condition is the bigger picture behind a single-year budget. A town is in better financial condition when its regular revenues can keep up with regular costs, services stay stable, and reserves are not being drained just to get through the year."
                    : "OSC's Financial Condition Analysis guide defines financial condition as the ability to balance recurring expenditure needs with recurring revenue sources while providing services on a continuing basis. The guide stresses that no single metric is enough: officials should review environmental indicators such as population, property value, income, unemployment, and poverty trends, along with financial indicators such as recurring revenue performance, recurring expenditure growth, debt service, tax-limit pressure, and budget-to-actual variances over a 5-to-10-year horizon. Riverhead's 2027 process should therefore treat structural balance, reserve use, debt burden, and service sustainability as part of one continuing fiscal-condition test rather than isolated budget-year decisions.",
                  tags: ["financial condition", "fiscal stress", "OSC", "trends"]),
            .init(term: "Structural Balance by District",
                  shortDefinition: "Whether each major operating district can stand on recurring revenue without reserve support.",
                  longExplanation: mode == .resident
                    ? "A town can look balanced overall while still leaning on savings in one fund or district. Checking structural balance by district means asking whether each major area can pay its regular bills with regular money."
                    : "Brookhaven's 2026 adopted budget explicitly states that its major tax districts are structurally balanced with no fund balance used in those districts. That is a useful peer-government standard for Riverhead: General Fund, Highway, and other major operating districts should be evaluated individually for recurring balance instead of allowing one fund's cushion to hide another fund's recurring problem.",
                  tags: ["structural balance", "districts", "fund balance", "peer practice"]),
            .init(term: "Contingency",
                  shortDefinition: "A small budget line for unplanned but legitimate in-year costs.",
                  longExplanation: mode == .resident
                    ? "A contingency line is a modest cushion inside the budget for costs that are real but hard to predict perfectly. It is not supposed to be a hidden slush fund, and any use should be explained publicly."
                    : "A contingency appropriation is a controlled in-year buffer for unforeseen but proper expenditures. It should be modest, governed by board action or formal transfer rules, and reported clearly when used. East Hampton's 2026 adopted General Fund includes a visible contingency line, which is a useful budget-book practice even though Riverhead should still rely primarily on realistic appropriations, variance monitoring, and reserve policy rather than masking structural imbalance inside contingency.",
                  tags: ["contingency", "budget process", "appropriations", "controls"]),
            .init(term: "Budget Calendar",
                  shortDefinition: "The formal schedule for preparing, hearing, adopting, and monitoring the budget.",
                  longExplanation: mode == .resident
                    ? "A budget calendar is the Town's timeline for when departments submit estimates, when the tentative budget is filed, when the public hearing happens, and when the final budget is adopted. Publishing it early makes the process easier to follow."
                    : "OSC's Understanding the Budget Process guide treats the budget calendar as the first step in a sound budget cycle. For towns, the guide recommends furnishing estimate forms by September 1, receiving departmental estimates by September 20, and filing the tentative budget by September 30, with later hearing and adoption deadlines set by Town Law. After adoption, the process is not over: officials should use monthly amended-budget-to-actual reports, variance analysis, and year-end projections to monitor compliance and identify shortfalls early.",
                  tags: ["budget process", "calendar", "OSC", "hearing"]),
            .init(term: "NY Property Tax Cap",
                  shortDefinition: "The state law limiting annual growth of the property-tax levy, with a formula-based cap.",
                  longExplanation: mode == .resident
                    ? "New York State law (Chapter 97 of 2011) caps how much the Town can increase its total tax levy each year. It does not directly cap tax rates or property assessments. The annual worksheet starts with the prior levy, reserve offset, tax-base growth, and allowable levy growth factor, then adjusts for prior and coming-year PILOTs, available carryover up to 1.5%, and a few narrow exclusions like certain pension spikes and tort judgments. The State Tax Department publishes the annual tax-base growth factors, and OSC's March 2026 table shows calendar-year local governments still using a 1.0200 allowable levy growth factor for 2026."
                    : "The OSC formula treats the levy limit as a worksheet, not a slogan: prior-year levy plus reserve amount, less prior-year reserve offset, multiplied through the tax-base growth factor and allowable levy growth factor, then adjusted for prior and coming-year PILOTs, transfer-of-function changes, available carryover capped at 1.5%, and narrow exclusions. The cap applies to the combined levy for the funds the town board controls, not directly to tax rates or assessments. The Department of Taxation and Finance publishes the annual city-and-town tax base growth factors, while OSC handles the filing and compliance framework. OSC's March 2026 inflation table shows the 2026 calendar-year inflation factor at 2.64%, which still yields the statutory 1.0200 allowable levy growth factor. The pension exclusion applies only to system-average contribution-rate increases above two percentage points, tort relief is limited to court orders and judgments above the statutory threshold, and a local-government override still requires approval by 60% of the governing body's total voting power before adoption.",
                  tags: ["tax cap", "levy", "state law"]),
            .init(term: "Structural Balance",
                  shortDefinition: "Recurring revenues fully covering recurring expenditures.",
                  longExplanation: mode == .resident
                    ? "A structurally balanced budget means the Town's regular income covers its regular expenses without relying on one-time windfalls like prior-year savings."
                    : "Structural imbalance occurs when non-recurring revenues (fund balance, one-time state aid, asset sales) offset recurring expenses. This creates a growing gap in out-years. OSC's fiscal stress monitoring framework penalizes budgets with high ratios of non-recurring revenues to total revenues.",
                  tags: ["fiscal health", "revenues", "appropriations"])
        ]
        return base
    }

    private var filtered: [GlossaryTerm] {
        guard !query.isEmpty else { return terms }
        let q = query.lowercased()
        return terms.filter { term in
            term.term.lowercased().contains(q)
            || term.shortDefinition.lowercased().contains(q)
            || term.tags.contains(where: { $0.lowercased().contains(q) })
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GlassCard(
                title: "Search terms & concepts",
                subtitle: mode == .resident
                    ? "Try typing a word like BAN, fund balance, or levy."
                    : "Type a term like GASB 54, tax cap, or structural balance for technical definitions."
            ) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search terms, departments, concepts…", text: $query)
                        .textInputAutocapitalization(.never)
                }
                .font(.subheadline)
            }

            ForEach(filtered) { term in
                GlassCard(title: term.term,
                          subtitle: term.shortDefinition) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(term.longExplanation)
                            .font(.footnote)
                            .foregroundStyle(RiverheadTheme.textPrimary)

                        HStack {
                            ForEach(term.tags, id: \.self) { tag in
                                Text(tag.uppercased())
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(RiverheadTheme.Surface.card.opacity(0.9))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            if filtered.isEmpty {
                Text("No terms found. Try a simpler word, like \"levy\" or \"reserve.\"")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
        }
    }
}

// MARK: - 7) Hearing Toolkit

enum HearingNoteTemplate: String, CaseIterable, Identifiable {
    case taxes
    case capital
    case fundBalance
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .taxes:       return "My tax bill"
        case .capital:     return "Capital projects"
        case .fundBalance: return "Fund balance & savings"
        case .other:       return "Other questions"
        }
    }

    var placeholder: String {
        switch self {
        case .taxes:
            return "Notes about how the levy and rate per thousand impact my property…"
        case .capital:
            return "Questions about specific equipment, facilities, or road projects…"
        case .fundBalance:
            return "Thoughts on how much should be kept in savings vs used for tax relief…"
        case .other:
            return "Any other comments or questions…"
        }
    }
}

@MainActor
fileprivate struct HearingToolkitView: View {
    let mode: BudgetAudienceMode

    @State private var selectedTemplate: HearingNoteTemplate = .taxes

    @AppStorage("Riverhead.hearing.notes.taxes") private var notesTaxes: String = ""
    @AppStorage("Riverhead.hearing.notes.capital") private var notesCapital: String = ""
    @AppStorage("Riverhead.hearing.notes.fundBalance") private var notesFundBalance: String = ""
    @AppStorage("Riverhead.hearing.notes.other") private var notesOther: String = ""

    private var boundNotes: Binding<String> {
        switch selectedTemplate {
        case .taxes:       return $notesTaxes
        case .capital:     return $notesCapital
        case .fundBalance: return $notesFundBalance
        case .other:       return $notesOther
        }
    }

    // Resident talking points: plain language
    private var residentTalkingPoints: [String] {
        [
            "Is the Town's savings account staying above the 15% minimum policy after this budget?",
            "How much of the $15.85M surplus above the upper reserve target is being used, and why?",
            "Police personal services are up $1.65M — is that from new hires, raises, or overtime?",
            "OSC said Riverhead's CPF spending and debt payments were proper, but some CPF collections were not logged or deposited on time — what changed to fix that before the next audit?",
            "If the Supervisor recommends an exempt Budget Officer, what financial training or accounting experience does that person have?",
            "If Riverhead adopts a Community Housing Fund, who sits on the advisory board and how will the public see what projects it recommends?",
            "If battery energy storage is under discussion, who would sit on a steering committee and how would neighborhoods be represented?",
            "If a new law costs money or saves money, which exact budget line is being charged or credited?",
            "Will every budget include a Schedule of Fund Balance and Projections so the public can see beginning balance, planned use, and projected year-end balance?",
            "Will the Town publish a budget calendar and monthly budget reports so residents can see when the tentative budget changes and whether spending is staying on track?",
            "If Riverhead has long used a 15% fund balance floor, why is the General Fund now above 40% of annual spending, and what target does the Board think is actually appropriate now?",
            "Will Riverhead adopt a rule that normal General Fund spending growth cannot run faster than its three-year average revenue growth plus three-year average population growth unless the Board overrides it in public?",
            "The Ambulance District has a $610K equipment purchase — how will it be paid for?",
            "Could a small community improvement grant round help fund visible neighborhood ideas without growing the recurring budget?",
            "Will next year's total levy stay within the State levy-limit formula after TBGF, PILOTs, carryover, and exclusions are calculated?"
        ]
    }

    // Expert talking points: technically framed for OSC/fiscal compliance context
    private var expertTalkingPoints: [String] {
        [
            "The tentative budget appropriates no explicit fund balance draw, yet the $29.67M unassigned balance is $15.85M above the 20% upper target — what is the Board's plan to deploy or return that surplus?",
            "Personnel services growth (Police +6.8%, Highway +4.9%) outpaces CPI. What contract provisions drive this, and how does it affect the out-year levy cap forecast?",
            "OSC's February 2024 CPF audit found Riverhead's CPF disbursements and debt service were proper, but some collections were not date-stamped and nine deposits totaling $5.3 million were not deposited within 10 days. What written control changes, training, and receipt-tracking steps have been implemented since then?",
            "If the Supervisor designates or recommends an exempt Budget Officer, what minimum qualifications in accounting, municipal finance, or budget administration does the Board require to preserve independent budget scrutiny and effective pluralism?",
            "If the Town adopts the 0.5% Community Housing Fund tax, what ordinance will govern the advisory board's appointments, recommendation process, conflict rules, and annual reporting?",
            "If battery energy storage policy is advancing, what resolution or local law will create the steering committee, define representation, and publish safety and siting recommendations?",
            "Will the Board require every fiscally impactful bill to identify the exact appropriation line or revenue line being debited or credited in the legislative fiscal note?",
            "Will each tentative and adopted budget include a Schedule of Fund Balance and Projections by major fund, with beginning balance, appropriations, projected ending balance, and out-year reserve impact?",
            "Will the budget calendar, estimate forms, and monthly amended-budget-to-actual reports be published so the hearing record shows how the tentative budget was built and monitored?",
            "Given the Town Board's December 5, 2006 consideration of Resolution #1101 and the later 15% General Fund policy reference in audited statements, what formal findings support carrying assigned plus unassigned General Fund balance above 40% of expenditures today?",
            "Will Riverhead adopt a Brookhaven-style operating-budget law tying Town-Wide General Fund expenditure growth to the three-year average of revenue growth plus three-year average population growth, with any override requiring a supermajority vote and written findings?",
            "Confirm that the Ambulance District $610K equipment item is excluded from the recurring baseline for tax cap carryover purposes (GML §3-c).",
            "Would a one-time $50,000 micro-grant series be treated as nonrecurring reserve deployment, with clear eligibility rules and post-award reporting?",
            "Has the Town filed its tax cap form with OSC, verified the TBGF, and confirmed whether any available carryover up to 1.5% was properly calculated on the combined town-controlled levy?",
            "What is the debt service coverage ratio, and are any BANs in the Capital Fund approaching the 5-year statutory limit for conversion?"
        ]
    }

    private var talkingPoints: [String] {
        mode == .resident ? residentTalkingPoints : expertTalkingPoints
    }

    private var recommendationLines: [BudgetRecommendationLine] {
        mode == .resident
        ? BudgetRecommendations2027.residentLines
        : BudgetRecommendations2027.expertLines
    }

    private var recommendationGroups: [BudgetRecommendationGroup] {
        let orderedGroups: [(String, String, Color)] = [
            ("Transparency", "eye.fill", RiverheadTheme.accent),
            ("Accountability", "checkmark.shield.fill", RiverheadTheme.gold),
            ("Fairness", "scale.3d", RiverheadTheme.brandSky)
        ]

        return orderedGroups.compactMap { title, icon, tint in
            let lines = recommendationLines.filter { $0.impact == title }
            guard lines.isEmpty == false else { return nil }
            return BudgetRecommendationGroup(title: title, icon: icon, tint: tint, lines: lines)
        }
    }

    private var recommendationBalanceTest: String {
        mode == .resident
        ? BudgetRecommendations2027.residentBalanceTest
        : BudgetRecommendations2027.expertBalanceTest
    }

    private var correctionLines: [BudgetCorrectionLine] {
        mode == .resident
        ? BudgetRecommendations2027.residentCorrectionLines
        : BudgetRecommendations2027.expertCorrectionLines
    }

    private var additionalOffsetIdeas: [String] {
        mode == .resident
        ? BudgetRecommendations2027.additionalResidentIdeas
        : BudgetRecommendations2027.additionalExpertIdeas
    }

    private var quantifiedScenarioSubtitle: String {
        mode == .resident
        ? "This is an illustrative 2027 starting point using the app's 2026 payroll snapshot, including union salary pressure and reserve-policy choices."
        : "Modeled from 328 tracked 2026 payroll rows using the app's current contract-group mapping, 2027 wage actions, and an explicit fund-balance policy lens."
    }

    private var modeledRevenueLines: [BudgetRevenueLine] {
        mode == .resident
        ? BudgetRecommendations2027.residentRevenueLines
        : BudgetRecommendations2027.expertRevenueLines
    }

    private var modeledInvestmentNotes: [String] {
        mode == .resident
        ? BudgetRecommendations2027.residentInvestmentNotes
        : BudgetRecommendations2027.expertInvestmentNotes
    }

    private var implementationPhases: [BudgetImplementationPhase] {
        mode == .resident
        ? BudgetRecommendations2027.residentImplementationPhases
        : BudgetRecommendations2027.expertImplementationPhases
    }

    private var payrollPressureVisuals: [BudgetVisualAmount] {
        [
            .init(title: "PBA", amount: BudgetRecommendations2027.modeledPBAIncrease, tint: .red, systemImage: "shield.lefthalf.filled"),
            .init(title: "SOA", amount: BudgetRecommendations2027.modeledSOAIncrease, tint: .purple, systemImage: "person.badge.shield.checkmark.fill"),
            .init(title: "CSEA", amount: BudgetRecommendations2027.modeledCSEAIncrease, tint: .orange, systemImage: "person.3.fill"),
            .init(title: "Non-contract", amount: BudgetRecommendations2027.modeledExemptIncrease, tint: RiverheadTheme.brandSky, systemImage: "person.crop.rectangle.stack.fill")
        ]
    }

    private var offsetVisuals: [BudgetVisualAmount] {
        [
            .init(title: "Healthcare share", amount: BudgetRecommendations2027.healthcareContributionSavings, tint: .green, systemImage: "cross.case.fill"),
            .init(title: "Exempt raise hold", amount: BudgetRecommendations2027.exemptRaiseHoldSavings, tint: RiverheadTheme.brandSky, systemImage: "pause.circle.fill"),
            .init(title: "Elected raise hold", amount: BudgetRecommendations2027.electedRaiseHoldSavings, tint: RiverheadTheme.brandGold, systemImage: "person.crop.circle.badge.checkmark"),
            .init(title: "Police OT recovery", amount: BudgetRecommendations2027.overtimeControlSavings, tint: .teal, systemImage: "clock.badge.checkmark.fill"),
            .init(title: "Vacancy factor", amount: BudgetRecommendations2027.civilianVacancyFactorSavings, tint: .blue, systemImage: "person.crop.circle.dashed"),
            .init(title: "Retirement refill", amount: BudgetRecommendations2027.targetedRetirementRefillSavings, tint: .indigo, systemImage: "arrow.triangle.2.circlepath.circle.fill")
        ]
    }

    private var investmentVisuals: [BudgetVisualAmount] {
        [
            .init(title: "Building", amount: BudgetRecommendations2027.buildingDepartmentHeadcountInvestment, tint: .orange, systemImage: "building.2.fill"),
            .init(title: "Online tools", amount: BudgetRecommendations2027.onlinePlatformUpdateCost, tint: RiverheadTheme.brandSky, systemImage: "network"),
            .init(title: "Code enforcement", amount: BudgetRecommendations2027.codeEnforcementOfficerCost * 2, tint: .teal, systemImage: "checklist.checked"),
            .init(title: "Town Clerk", amount: BudgetRecommendations2027.deputyTownClerkCost, tint: .purple, systemImage: "doc.text.fill"),
            .init(title: "Police", amount: BudgetRecommendations2027.policeOfficerCost * 2, tint: .red, systemImage: "shield.fill")
        ]
    }

    private var planStepVisuals: [BudgetPlanStep] {
        [
            .init(title: "Pressure", amount: -BudgetRecommendations2027.modeledAutomaticPayrollPressure, tint: .orange),
            .init(title: "Offsets", amount: BudgetRecommendations2027.quantifiedPackageSavings, tint: .green),
            .init(title: "Revenue", amount: BudgetRecommendations2027.modeledRevenuePackage, tint: RiverheadTheme.brandSky),
            .init(title: "Investments", amount: -BudgetRecommendations2027.addedServiceInvestments, tint: .red),
            .init(title: "Net room", amount: BudgetRecommendations2027.balanceAfterRevenueAndInvestments, tint: RiverheadTheme.brandGold)
        ]
    }

    private var payrollPressureTotal: Double {
        payrollPressureVisuals.map(\.amount).reduce(0, +)
    }

    private var investmentTotal: Double {
        investmentVisuals.map(\.amount).reduce(0, +)
    }

    private var largestOffset: Double {
        max(offsetVisuals.map(\.amount).max() ?? 1, 1)
    }

    private var largestPlanMagnitude: Double {
        max(planStepVisuals.map { abs($0.amount) }.max() ?? 1, 1)
    }

    @ViewBuilder
    private func recommendationGroupCard(_ group: BudgetRecommendationGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label(group.title, systemImage: group.icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(group.tint)

                Spacer(minLength: 8)

                Text("\(group.lines.count) item\(group.lines.count == 1 ? "" : "s")")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(group.tint.opacity(0.12))
                    .foregroundStyle(group.tint)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(group.lines) { line in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(line.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.textPrimary)

                        Text(line.detail)
                            .font(.caption)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RiverheadTheme.Surface.inset)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private var fundingStrategyLines: [BudgetFundingStrategyLine] {
        mode == .resident
        ? BudgetRecommendations2027.residentFundingStrategyLines
        : BudgetRecommendations2027.expertFundingStrategyLines
    }

    @ViewBuilder
    private func quickReadRow(title: String, detail: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(tint.opacity(0.85))
                .frame(width: 10, height: 10)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RiverheadTheme.Surface.inset)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var suggestionInfographicSnapshot: some View {
        VStack(alignment: .leading, spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 14) {
                    BudgetAmountDonut(
                        items: payrollPressureVisuals,
                        total: payrollPressureTotal,
                        centerValue: shortCurrency(payrollPressureTotal),
                        centerLabel: "Payroll"
                    )
                    .frame(width: 126, height: 126)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Payroll pressure")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.textSecondary)

                        ForEach(payrollPressureVisuals) { item in
                            visualLegendRow(item, total: payrollPressureTotal)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    BudgetAmountDonut(
                        items: payrollPressureVisuals,
                        total: payrollPressureTotal,
                        centerValue: shortCurrency(payrollPressureTotal),
                        centerLabel: "Payroll"
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 142)

                    ForEach(payrollPressureVisuals) { item in
                        visualLegendRow(item, total: payrollPressureTotal)
                    }
                }
            }

            Divider().opacity(0.25)

            VStack(alignment: .leading, spacing: 8) {
                Text("Offset package")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textSecondary)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(offsetVisuals) { item in
                        BudgetVisualBarRow(
                            item: item,
                            maximum: largestOffset,
                            valueText: shortCurrency(item.amount)
                        )
                    }
                }
            }

            Divider().opacity(0.25)

            VStack(alignment: .leading, spacing: 8) {
                Text("Modeled path to room")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textSecondary)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(planStepVisuals) { step in
                        BudgetPlanStepRow(
                            step: step,
                            maximum: largestPlanMagnitude,
                            valueText: signedShortCurrency(step.amount)
                        )
                    }
                }
            }
        }
    }

    private var investmentInfographic: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 14) {
                    BudgetAmountDonut(
                        items: investmentVisuals,
                        total: investmentTotal,
                        centerValue: shortCurrency(investmentTotal),
                        centerLabel: "Invest"
                    )
                    .frame(width: 120, height: 120)

                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(investmentVisuals) { item in
                            visualLegendRow(item, total: investmentTotal)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    BudgetAmountDonut(
                        items: investmentVisuals,
                        total: investmentTotal,
                        centerValue: shortCurrency(investmentTotal),
                        centerLabel: "Invest"
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 138)

                    ForEach(investmentVisuals) { item in
                        visualLegendRow(item, total: investmentTotal)
                    }
                }
            }
        }
    }

    private func visualLegendRow(_ item: BudgetVisualAmount, total: Double? = nil) -> some View {
        HStack(spacing: 8) {
            Image(systemName: item.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(item.tint)
                .frame(width: 18)

            Text(item.title)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(shortCurrency(item.amount))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            if let total, total > 0 {
                Text((item.amount / total).formatted(.percent.precision(.fractionLength(0))))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func signedShortCurrency(_ value: Double) -> String {
        value >= 0 ? "+\(shortCurrency(value))" : shortCurrency(value)
    }

    private func shortCurrency(_ value: Double) -> String {
        let sign = value < 0 ? "-" : ""
        let amount = abs(value)
        if amount >= 1_000_000 {
            return "\(sign)$\(String(format: "%.1f", amount / 1_000_000))M"
        }
        if amount >= 1_000 {
            return "\(sign)$\(String(format: "%.0f", amount / 1_000))K"
        }
        return value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassCard(
                title: mode == .resident ? "Notes for tonight's hearing" : "Hearing prep notes",
                subtitle: mode == .resident
                    ? "Jot down questions and comments, then share them or email them to yourself."
                    : "Draft testimony points, cite specific line items, and share with colleagues or the Town Clerk."
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Topic", selection: $selectedTemplate) {
                        ForEach(HearingNoteTemplate.allCases) { tpl in
                            Text(tpl.label).tag(tpl)
                        }
                    }
                    .pickerStyle(.segmented)

                    ZStack(alignment: .topLeading) {
                        if boundNotes.wrappedValue.isEmpty {
                            Text(selectedTemplate.placeholder)
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }
                        TextEditor(text: boundNotes)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 160, maxHeight: 220)
                    }
                    .background(RiverheadTheme.Surface.card.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    HStack {
                        Text("Saved locally on this device.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if !boundNotes.wrappedValue.isEmpty {
                            ShareLink(item: boundNotes.wrappedValue) {
                                Label("Share notes", systemImage: "square.and.arrow.up")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }

            GlassCard(
                title: "2027 Modeled Cost Pressure",
                subtitle: quantifiedScenarioSubtitle
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Automatic 2027 payroll growth")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(BudgetRecommendations2027.modeledAutomaticPayrollPressure, format: .currency(code: "USD"))
                            .font(.subheadline.weight(.semibold))
                    }

                    HStack {
                        Text("Modeled union salary pressure")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(BudgetRecommendations2027.modeledUnionSalaryPressure, format: .currency(code: "USD"))
                            .font(.caption.weight(.semibold))
                    }

                    HStack {
                        Text("Personnel items as share of budget")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(BudgetRecommendations2027.personnelShareOfBudget, format: .percent.precision(.fractionLength(2)))
                            .font(.caption.weight(.semibold))
                    }

                    Text("Current model uses about ")
                        .font(.caption2)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                    +
                    Text(BudgetRecommendations2027.modeledPersonnelBase2026, format: .currency(code: "USD"))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.textSecondary)
                    +
                    Text(" in tracked 2026 payroll against ")
                        .font(.caption2)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                    +
                    Text(BudgetRecommendations2027.totalBudget2026, format: .currency(code: "USD"))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.textSecondary)
                    +
                    Text(" in total appropriations.")
                        .font(.caption2)
                        .foregroundStyle(RiverheadTheme.textSecondary)

                    if mode == .expert {
                        VStack(alignment: .leading, spacing: 6) {
                            summaryRow("PBA 2027 fallback at 2.5%", value: BudgetRecommendations2027.modeledPBAIncrease)
                            summaryRow("SOA 2027 fallback at 2.5%", value: BudgetRecommendations2027.modeledSOAIncrease)
                            summaryRow("CSEA 2027 action", value: BudgetRecommendations2027.modeledCSEAIncrease)
                            summaryRow("Non-contract 2027 fallback at 2.5%", value: BudgetRecommendations2027.modeledExemptIncrease)
                        }
                    } else {
                        Text("This estimate already assumes automatic union and exempt payroll growth for 2027 before any corrective policy action is taken, so residents can see the real salary pressure before discussing cuts or taxes.")
                            .font(.caption)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                    }

                    Divider().opacity(0.25)

                    HStack {
                        Text("Fund balance policy floor / target / deployment cap")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text("\(Int(BudgetRecommendations2027.fundBalancePolicyFloorPercent * 100))% / \(Int(BudgetRecommendations2027.fundBalancePolicyOperatingTargetPercent * 100))% / \(Int(BudgetRecommendations2027.fundBalancePolicyDeploymentCapPercent * 100))%")
                            .font(.caption.weight(.semibold))
                    }

                    Text("Current unassigned fund balance in the app model is ")
                        .font(.caption2)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                    +
                    Text(BudgetRecommendations2027.modeledUnassignedFundBalance2026, format: .currency(code: "USD"))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.textSecondary)
                    +
                    Text(", so the policy question is not whether reserves exist, but how much can be deployed without normalizing one-time money into recurring operations.")
                        .font(.caption2)
                        .foregroundStyle(RiverheadTheme.textSecondary)

                    Divider().opacity(0.25)

                    summaryRow("20% healthcare premium contribution", value: BudgetRecommendations2027.healthcareContributionSavings)
                    summaryRow("Freeze exempt discretionary raises", value: BudgetRecommendations2027.exemptRaiseHoldSavings)
                    summaryRow("Freeze elected salary growth", value: BudgetRecommendations2027.electedRaiseHoldSavings)
                    summaryRow("Police Uniform OT recovery target", value: BudgetRecommendations2027.overtimeControlSavings)
                    summaryRow("1% civilian vacancy factor", value: BudgetRecommendations2027.civilianVacancyFactorSavings)
                    summaryRow("Targeted retirement refill control", value: BudgetRecommendations2027.targetedRetirementRefillSavings)

                    Text(mode == .resident
                         ? "What this means in plain English: this is a phased savings package, not a promise that every dollar arrives in the first year. The overtime target now starts with Police Uniform OT: 2024 actual spending was about $1.40M against a $1.0M budget, and the app models recovering $250K of that overrun through tighter scheduling and quarterly recovery review. The vacancy-factor and retirement-refill lines work the same way by using normal turnover and more selective backfilling, not broad staff cuts. Some items can be done by budget policy or management action right away, but any wider health-premium or work-rule change that touches represented employees may need bargaining, MOAs, or side letters."
                         : "Interpret the personal-service offsets as a staged implementation package rather than a one-year certainty. Administrative items can move faster: exempt/elected pay restraint, Police Uniform OT cause coding, written overtime plans, quarterly variance review, vacancy-factor discipline, and selective backfill control. Contract-sensitive items, especially any broader employee-premium contribution or work-rule change affecting represented staff, would likely require bargaining, MOAs, or side letters and may phase in over more than one budget cycle. The overtime line reflects a recoverable portion of the 2024 Police Uniform OT overrun, not a service-level reduction assumption.")
                        .font(.caption)
                        .foregroundStyle(RiverheadTheme.textSecondary)

                    Divider().opacity(0.25)

                    HStack {
                        Text("Modeled recurring offsets")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(BudgetRecommendations2027.quantifiedPackageSavings, format: .currency(code: "USD"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }

                    HStack {
                        Text("Recurring gap still to solve")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(BudgetRecommendations2027.remainingRecurringGap, format: .currency(code: "USD"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }
            }

            GlassCard(
                title: "2027 Infographic Snapshot",
                subtitle: mode == .resident
                    ? "A visual take on the suggested plan: what's growing, what offsets it, and how much room is left."
                    : "Charted view of payroll pressure, recurring offsets, revenue package, explicit investments, and resulting modeled room."
            ) {
                suggestionInfographicSnapshot
            }

            GlassCard(
                title: "2027 Quick Read",
                subtitle: mode == .resident
                    ? "The short version — before you dive into all the line-item detail."
                    : "A one-screen translation of the model into pressure, offsets, and service choices."
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    quickReadRow(
                        title: "What automatically gets more expensive",
                        detail: mode == .resident
                            ? "Union and non-contract payroll already grow in the 2027 model, and published NYSLRS rates add a large pension increase before any new policy choice is made."
                            : "Automatic payroll pressure of about $936.7K is already embedded, and published NYSLRS rates add a townwide pension-pressure range of about $1.4M to $1.85M.",
                        tint: .orange
                    )

                    quickReadRow(
                        title: "Will it pierce the tax cap?",
                        detail: mode == .resident
                            ? "Very possibly. A normal 2% levy increase produces about $973K, while the pension increase alone is estimated at $1.4M to $1.85M before other cost growth."
                            : "The 2027 budget is headed toward an override conversation unless Riverhead offsets several hundred thousand dollars to more than $1M of recurring pressure through cuts, recurring revenue, fund-balance use, or tax-cap formula room.",
                        tint: RiverheadTheme.brandCoral
                    )

                    quickReadRow(
                        title: "Independent cross-check: line-by-line model",
                        detail: mode == .resident
                            ? "A separate model that grows every 2026 budget line item by its own category trend (not just payroll and pension) reaches the same conclusion from a different angle: 2027 spending lands near $126.2M and the tax levy near $69.3M — about $2.6M over the roughly 2% the cap allows."
                            : "Growing all 848 2026 adopted line items by category-specific rates (Personal Services 3.5%, Employee Benefits 8% — the fastest-growing category, Contractual 3.5%, Equipment 3%, Interfund 3%, Other 0%, calibrated to the real 2024–2026 trend) projects 2027 appropriations of about $126.2M (+4.16%) and an implied levy of about $69.27M (+6.0%), roughly $2.6M above the ~2% cap ceiling (~$66.65M). Independently converges with the payroll/pension-pressure estimate above on the same qualitative answer: yes, absent an offset or an override.",
                        tint: RiverheadTheme.brandGold
                    )

                    quickReadRow(
                        title: "How to counter the cap risk",
                        detail: mode == .resident
                            ? "The practical offset package starts with Police Uniform OT. Recovering part of the 2024 overrun, plus selective refill after retirements, a small vacancy factor, healthcare sharing for senior staff, raise holds, and better recurring fees or rentals, can cover several hundred thousand dollars and, with stronger cost recovery, just over $1M."
                            : "A realistic recurring package is about $858K, including a $250K Police Uniform OT recovery target tied to the 2024 overrun, targeted retirement refill control, a 1% civilian vacancy factor, healthcare contribution policy, exempt/elected raise holds, and base recurring revenue adds. A $250K stretch target for fees, rentals, and service-cost recovery brings the package to roughly $1.1M.",
                        tint: .green
                    )

                    quickReadRow(
                        title: "Why Police OT is the first offset",
                        detail: mode == .resident
                            ? "Police Uniform OT came in about $401K over budget in 2024, while the adopted 2026 line still sits at $1.0M. But March workload was not down: criminal incidents rose to 167 from 144 and total incidents rose to 2,994 from 2,922. The app treats $250K as a recovery target only if the Town publishes monthly OT causes and manages scheduling tightly."
                            : "Police Uniform OT actuals were $1.401M in 2024 versus a $1.0M budget, and the 2026 adopted baseline is still $1.0M. Recovering $250K would capture about \(BudgetRecommendations2027.policeOvertimeRecoveryShare.formatted(.percent.precision(.fractionLength(1)))) of the 2024 variance, but March activity data shows criminal incidents and total incidents up year over year. That makes cause coding and coverage constraints essential.",
                        tint: RiverheadTheme.brandSky
                    )

                    quickReadRow(
                        title: "March police workload check",
                        detail: mode == .resident
                            ? "The March report is mixed: domestic incidents stayed at 60, accidents fell to 114 from 123, and summonses fell to 1,042 from 1,076. That supports a targeted OT review, not a claim that Police can simply absorb less work."
                            : "March 2026 activity: 167 criminal incidents, 2,994 total incidents, 60 domestic incidents, 114 accidents, and 1,042 summonses. Because the NIBRS transition was completed in July 2024, this is useful current workload context but should not be treated as a multi-year trend by itself.",
                        tint: .orange
                    )

                    quickReadRow(
                        title: "What the Town is trying to control",
                        detail: mode == .resident
                            ? "The savings side leans on healthcare sharing, Police OT discipline, ordinary turnover, and more selective refilling of vacancies."
                            : "The offset package is built on healthcare contribution, Police Uniform OT recovery, vacancy-factor relief, and targeted retirement-refill control rather than a broad staff reduction.",
                        tint: .green
                    )

                    quickReadRow(
                        title: "What Riverhead still wants to add",
                        detail: mode == .resident
                            ? "The model still adds visible service capacity in Building, Code Enforcement, the Town Clerk's office, and policing."
                            : "The plan pairs labor-discipline assumptions with explicit recurring adds in Building, Code Enforcement, Town Clerk staffing, and police coverage.",
                        tint: RiverheadTheme.brandSky
                    )
                }
            }

            GlassCard(
                title: "Added 2027 Investments",
                subtitle: mode == .resident
                    ? "These are added costs the plan should own up to — not bury somewhere else in the budget."
                    : "Policy/service additions layered on top of the baseline cost-pressure model."
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    investmentInfographic

                    Divider().opacity(0.25)

                    ForEach(modeledInvestmentNotes, id: \.self) { idea in
                        bullet(idea)
                    }

                    Divider().opacity(0.25)

                    summaryRow("Building Department headcount increase", value: BudgetRecommendations2027.buildingDepartmentHeadcountInvestment)
                    summaryRow("Online platform updates", value: BudgetRecommendations2027.onlinePlatformUpdateCost)
                    summaryRow("2 additional Code Enforcement Officers", value: BudgetRecommendations2027.codeEnforcementOfficerCost * 2)
                    summaryRow("1 additional Town Clerk position", value: BudgetRecommendations2027.deputyTownClerkCost)
                    summaryRow("2 additional police officers", value: BudgetRecommendations2027.policeOfficerCost * 2)

                    Text(mode == .resident
                         ? "These are real service adds in the model, not hidden payroll drift. The 2027 package assumes Riverhead still chooses to add visible capacity in Building, Code Enforcement, the Town Clerk's office, and policing even while trying to control avoidable overtime and refill costs elsewhere."
                         : "These lines are explicit service expansions layered on top of the offset package. In other words, the 2027 model is not balancing itself by removing core delivery capacity; it pairs labor-discipline assumptions with visible recurring adds in Building, Code Enforcement, Town Clerk staffing, and police coverage.")
                        .font(.caption)
                        .foregroundStyle(RiverheadTheme.textSecondary)

                    Divider().opacity(0.25)

                    HStack {
                        Text("Total added investments")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(BudgetRecommendations2027.addedServiceInvestments, format: .currency(code: "USD"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }

                    HStack {
                        Text("Net after offsets + revenue + investments")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(BudgetRecommendations2027.balanceAfterRevenueAndInvestments, format: .currency(code: "USD"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }
            }

            GlassCard(
                title: "Fairness, Transparency & Accountability Plan",
                subtitle: mode == .resident
                    ? "A budget plan built for residents — focused on who pays, what gets explained clearly, and which costs need closer watching."
                    : "A control framework for the budget build: fair cost sharing, transparent reserve use, and enforceable management accountability."
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(mode == .resident
                         ? "The same package is grouped below into the clearest public tests: what should be easier to see, what should be more tightly managed, and what should feel fairer to taxpayers."
                         : "Grouped by policy objective so the control package is easier to scan during work sessions, hearings, and document review.")
                        .font(.footnote)
                        .foregroundStyle(RiverheadTheme.textSecondary)

                    ForEach(recommendationGroups) { group in
                        recommendationGroupCard(group)
                    }

                    Divider().opacity(0.25)

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "scale.3d")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.gold)
                            .frame(width: 16)

                        Text(recommendationBalanceTest)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.textPrimary)
                    }
                }
            }

            GlassCard(
                title: mode == .resident ? "Day One Agenda" : "Phased implementation agenda",
                subtitle: mode == .resident
                    ? "What happens right away, in the first 100 days, and through year one — ordered to ease pressure and build trust."
                    : "A sequenced implementation path that matches urgency to administrative capacity, fiscal guardrails, and political timing."
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(implementationPhases) { phase in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(phase.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RiverheadTheme.textPrimary)

                                Spacer(minLength: 8)

                                Text(phase.horizon.uppercased())
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(RiverheadTheme.gold.opacity(0.14))
                                    .foregroundStyle(RiverheadTheme.gold)
                                    .clipShape(Capsule())
                            }

                            Text(phase.detail)
                                .font(.caption)
                                .foregroundStyle(RiverheadTheme.textSecondary)

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(phase.items, id: \.self) { item in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(RiverheadTheme.accent)
                                            .padding(.top, 1)

                                        Text(item)
                                            .font(.caption)
                                            .foregroundStyle(RiverheadTheme.textPrimary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(10)
                            .background(RiverheadTheme.Surface.inset)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        if phase.id != implementationPhases.last?.id {
                            Divider().opacity(0.2)
                        }
                    }

                    Divider().opacity(0.25)

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "leaf")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                            .frame(width: 16)

                        Text("SEQR note: these governance and fiscal-policy adoptions are framed here as Type II actions under 6 NYCRR 617.5(c)(20) and (27), meaning no further SEQR review is expected for the policy package itself.")
                            .font(.caption2)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                    }
                }
            }

            GlassCard(
                title: "2026 Correction Watch",
                subtitle: mode == .resident
                    ? "Based on the 2026 Budget Supplement, here are the funds the board should be explaining — or fixing — in the open."
                    : "Fund-level issues pulled from the 2026 Budget Supplement that warrant reconciliation, reserve-use disclosure, or explicit board findings."
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(correctionLines) { line in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(line.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RiverheadTheme.textPrimary)

                                Spacer(minLength: 8)

                                Text(line.status.uppercased())
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(RiverheadTheme.gold.opacity(0.16))
                                    .foregroundStyle(RiverheadTheme.gold)
                                    .clipShape(Capsule())
                            }

                            Text(line.detail)
                                .font(.caption)
                                .foregroundStyle(RiverheadTheme.textSecondary)
                        }

                        if line.id != correctionLines.last?.id {
                            Divider().opacity(0.2)
                        }
                    }
                }
            }

            GlassCard(
                title: mode == .resident ? "State Funding & Tax Burden Plan" : "Grant capture and levy-relief playbook",
                subtitle: mode == .resident
                    ? "A simple way to protect taxpayers: keep day-to-day spending disciplined, pay for big infrastructure with grants where possible, and use reimbursements to pay down debt faster."
                    : "A policy structure for treating infrastructure as a funding-stack problem and using state dollars to reduce local share, future debt service, and levy pressure."
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(fundingStrategyLines) { line in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(line.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RiverheadTheme.textPrimary)

                            Text(line.detail)
                                .font(.caption)
                                .foregroundStyle(RiverheadTheme.textSecondary)
                        }

                        if line.id != fundingStrategyLines.last?.id {
                            Divider().opacity(0.2)
                        }
                    }
                }
            }

            GlassCard(
                title: "Revenue Increases To Pair With Offsets",
                subtitle: mode == .resident
                    ? "A few illustrative revenue ideas that could close the last gap without touching reserves, plus one housing-fund tool shown separately for now."
                    : "Illustrative recurring revenue package sized to sit alongside the modeled expenditure offsets, with the CHF transfer-tax option displayed separately until local sales-volume assumptions are modeled."
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(modeledRevenueLines) { line in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(line.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RiverheadTheme.textPrimary)
                                Spacer(minLength: 8)
                                Text(line.amount, format: .currency(code: "USD"))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(RiverheadTheme.accent)
                            }

                            Text(line.detail)
                                .font(.caption)
                                .foregroundStyle(RiverheadTheme.textSecondary)
                        }

                        if line.id != modeledRevenueLines.last?.id {
                            Divider().opacity(0.2)
                        }
                    }

                    Divider().opacity(0.25)

                    HStack {
                        Text("Illustrative recurring revenue package")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(BudgetRecommendations2027.modeledRevenuePackage, format: .currency(code: "USD"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }

                    HStack {
                        Text("Net after offsets + revenue package")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(BudgetRecommendations2027.balanceAfterRevenuePackage, format: .currency(code: "USD"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                }
            }

            GlassCard(
                title: "Additional Offsets To Evaluate",
                subtitle: mode == .resident
                    ? "We haven't modeled these in dollars yet, but they're worth a look next."
                    : "Unmodeled recurring offset candidates that can be sized in the next pass."
            ) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(additionalOffsetIdeas, id: \.self) { idea in
                        bullet(idea)
                    }
                }
            }

            GlassCard(
                title: mode == .resident ? "Questions to ask tonight" : "Technically-framed talking points",
                subtitle: mode == .resident
                    ? "Based on the real 2026 tentative budget numbers — written for residents, not accountants."
                    : "Framed around OSC guidance, NY Local Finance Law, and GASB 54 compliance."
            ) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(talkingPoints, id: \.self) { point in
                        bullet(point)
                    }
                }
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•").font(.caption)
            Text(text)
                .font(.caption)
        }
    }

    private func summaryRow(_ label: String, value: Double) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(RiverheadTheme.textSecondary)
            Spacer(minLength: 8)
            Text(value, format: .currency(code: "USD"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(RiverheadTheme.textPrimary)
        }
    }
}

// MARK: - 8) Employees Hub Section

/// Thin wrapper that surfaces EmployeeDirectoryView inside the Hub's scroll context.
/// The full NavigationSplitView lives inside EmployeeDirectoryView and handles its
/// own nav stack; this card just provides an entry point with a context blurb.
@MainActor
fileprivate struct EmployeesHubSectionView: View {
    let mode: BudgetAudienceMode

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassCard(
                title: "Gross Earnings Directory",
                subtitle: mode == .resident
                    ? "Search by name or employee ID to see pay history from the Newsday earnings reports (2018–2023)."
                    : "Filter by employment status and union, sort by pay, and drill into yearly regular vs. premium-pay breakdowns for 437 active employees and 1,145 deduplicated records on file."
            ) {
                NavigationLink {
                    EmployeeDirectoryView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.text.rectangle.fill")
                            .font(.title2)
                            .foregroundStyle(RiverheadTheme.accent)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Open Employee Directory")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RiverheadTheme.textPrimary)
                            Text("437 active employees · 1,145 deduplicated records · 2018–2023")
                                .font(.caption)
                                .foregroundStyle(RiverheadTheme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.textSecondary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }

            if mode == .expert {
                GlassCard(
                    title: "What to look for",
                    subtitle: "Expert context for workforce cost analysis."
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        expertBullet(
                            icon: "clock.badge.exclamationmark",
                            text: "Premium-pay spikes — filter PBA or SOA, sort by Highest Paid, and compare gross pay to regular pay."
                        )
                        Divider().opacity(0.2)
                        expertBullet(
                            icon: "arrow.up.right.circle",
                            text: "Year-over-year trend — the earnings chart shows whether pay growth is from base raises, OT growth, or one-time items."
                        )
                        Divider().opacity(0.2)
                        expertBullet(
                            icon: "calendar.badge.minus",
                            text: "Turnover signal — Terminated employees with multi-year records may indicate position backfill costs in the current budget."
                        )
                    }
                }
            }

            SourcesStrip(links: [
                .init(
                    title: "Newsday Gross Earnings Reports",
                    kind: .other,
                    note: "Annual public disclosure (2018–2023)",
                    url: URL(string: "https://www.newsday.com/long-island/nassau/government-salary-database-1.18687295")
                )
            ])
        }
    }

    private func expertBullet(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(RiverheadTheme.accent)
                .frame(width: 18)
            Text(text)
                .font(.caption)
                .foregroundStyle(RiverheadTheme.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RiverheadBudgetHubView()
            .preferredColorScheme(.dark)
    }
}
