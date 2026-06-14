import SwiftUI

@MainActor
struct BudgetSimulator2027View: View {
    @Environment(RBBudgetStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var sim = Budget2027SimulatorState()

    private var exactFY27Changes: [FY27ChangeLine] {
        var lines: [FY27ChangeLine] = [
            .init(
                title: "CSEA 2027 wage action",
                valueText: sim.colaBreakout.cseaPressure.formatted(.currency(code: "USD")),
                detail: "Fixed approved action of +2.5% plus $1,000 in 2027."
            ),
            .init(
                title: "PBA / SOA / non-contract fallback growth",
                valueText: (sim.colaBreakout.pbaPressure + sim.colaBreakout.soaPressure + sim.colaBreakout.nonContractPressure).formatted(.currency(code: "USD")),
                detail: "Modeled at \(String(format: "%.1f%%", sim.automaticCOLAPercent)) for post-2026 fallback planning."
            ),
            .init(
                title: "Recurring levy growth",
                valueText: levyYield.formatted(.currency(code: "USD")),
                detail: "Illustrative levy growth set at \(String(format: "%.1f%%", sim.levyGrowthPercent))."
            ),
            .init(
                title: "Other recurring revenue adds",
                valueText: sim.recurringRevenueAdds.formatted(.currency(code: "USD")),
                detail: "Fees, rentals, and other recurring non-levy adds."
            ),
            .init(
                title: "Recurring savings package",
                valueText: sim.recurringSavings.formatted(.currency(code: "USD")),
                detail: "Healthcare, overtime, vacancy, and refill discipline package."
            )
        ]

        if sim.otherRecurringPressure > 0 {
            lines.append(
                .init(
                    title: "Other recurring operating pressure",
                    valueText: sim.otherRecurringPressure.formatted(.currency(code: "USD")),
                    detail: "Insurance, pension, utility, or other non-payroll pressure carried in the scenario."
                )
            )
        }

        if sim.includeBuildingDepartmentInvestment {
            lines.append(
                .init(
                    title: "Building Department staffing investment",
                    valueText: Budget2027ScenarioModel.buildingDepartmentHeadcountInvestment.formatted(.currency(code: "USD")),
                    detail: "Recurring staffing support kept in the FY27 plan."
                )
            )
        }

        if sim.includeOnlinePlatformInvestment {
            lines.append(
                .init(
                    title: "Online platform modernization",
                    valueText: Budget2027ScenarioModel.onlinePlatformUpdateCost.formatted(.currency(code: "USD")),
                    detail: "Resident-facing online service and workflow upgrade."
                )
            )
        }

        if sim.includeTownClerkInvestment {
            lines.append(
                .init(
                    title: "Town Clerk staffing investment",
                    valueText: Budget2027ScenarioModel.deputyTownClerkCost.formatted(.currency(code: "USD")),
                    detail: "One added recurring staffing position."
                )
            )
        }

        if sim.additionalCodeEnforcementOfficers > 0 {
            lines.append(
                .init(
                    title: "Additional Code Enforcement Officers",
                    valueText: (Double(Int(sim.additionalCodeEnforcementOfficers)) * Budget2027ScenarioModel.codeEnforcementOfficerCost).formatted(.currency(code: "USD")),
                    detail: "\(Int(sim.additionalCodeEnforcementOfficers)) officer(s) in the FY27 recurring package."
                )
            )
        }

        if sim.additionalPoliceOfficers > 0 {
            lines.append(
                .init(
                    title: "Additional police officers",
                    valueText: (Double(Int(sim.additionalPoliceOfficers)) * Budget2027ScenarioModel.policeOfficerCost).formatted(.currency(code: "USD")),
                    detail: "\(Int(sim.additionalPoliceOfficers)) officer(s) in the FY27 recurring package."
                )
            )
        }

        lines.append(
            .init(
                title: "Supervisor + Town Board raise package",
                valueText: sim.includeElectedRaisePackage ? sim.electedRaisePackageCost.formatted(.currency(code: "USD")) : "$0",
                detail: sim.includeElectedRaisePackage
                    ? "Included as a discretionary elected-pay package."
                    : "Held out of the FY27 baseline in the best-plan version."
            )
        )

        lines.append(
            .init(
                title: "Planned capital fleet purchase",
                valueText: sim.includeCapitalFleetPurchase ? sim.capitalFleetPurchaseCost.formatted(.currency(code: "USD")) : "$0",
                detail: sim.includeCapitalFleetPurchase
                    ? "Four planned vehicles at $84,000 each: two for Building and two for Code Enforcement."
                    : "No building/code fleet purchase is currently included."
            )
        )

        lines.append(
            .init(
                title: "One-time reserve deployment",
                valueText: appliedOneTimeDeployment.formatted(.currency(code: "USD")),
                detail: appliedOneTimeDeployment > 0
                    ? "Used as one-time support above the selected reserve target."
                    : "No one-time reserve use in the current package."
            )
        )

        return lines
    }

    private var groupedFY27Changes: [FY27ChangeGroup] {
        let automaticTitles: Set<String> = [
            "CSEA 2027 wage action",
            "PBA / SOA / non-contract fallback growth",
            "Other recurring operating pressure"
        ]
        let recurringFixTitles: Set<String> = [
            "Recurring levy growth",
            "Other recurring revenue adds",
            "Recurring savings package",
            "Supervisor + Town Board raise package"
        ]
        let serviceTitles: Set<String> = [
            "Building Department staffing investment",
            "Online platform modernization",
            "Town Clerk staffing investment",
            "Additional Code Enforcement Officers",
            "Additional police officers"
        ]
        let oneTimeTitles: Set<String> = [
            "Planned capital fleet purchase",
            "One-time reserve deployment"
        ]

        let groups: [(String, String, Set<String>)] = [
            ("Automatic pressure", "These are the recurring pressures already sitting in the 2027 picture before the Town makes policy choices.", automaticTitles),
            ("Recurring fixes", "These are the recurring tools the model uses to pay for the plan or change the baseline.", recurringFixTitles),
            ("Service additions", "These are the visible staffing and service choices Riverhead is choosing to carry in FY27.", serviceTitles),
            ("One-time and capital", "These items affect reserve room or capital planning, not the recurring operating test by themselves.", oneTimeTitles)
        ]

        return groups.compactMap { title, subtitle, titles in
            let lines = exactFY27Changes.filter { titles.contains($0.title) }
            guard lines.isEmpty == false else { return nil }
            return FY27ChangeGroup(title: title, subtitle: subtitle, lines: lines)
        }
    }

    private var planShowcaseSections: [BudgetShowcaseSection] {
        var sections: [BudgetShowcaseSection] = []

        sections.append(
            .init(
                title: "Automatic 2027 cost pressure",
                subtitle: "These items are happening in the model before Riverhead adds new policy choices.",
                tint: .orange,
                rows: [
                    .init(
                        title: "Approved CSEA wage action",
                        detail: "+2.5% plus $1,000 for 2027.",
                        amount: sim.colaBreakout.cseaPressure,
                        direction: .cost
                    ),
                    .init(
                        title: "PBA / SOA fallback growth",
                        detail: "Planning growth tied to the selected fallback COLA.",
                        amount: sim.colaBreakout.pbaPressure + sim.colaBreakout.soaPressure,
                        direction: .cost
                    ),
                    .init(
                        title: "Non-contract COLA pressure",
                        detail: "Automatic salary adjustment for non-contract positions.",
                        amount: sim.colaBreakout.nonContractPressure,
                        direction: .cost
                    )
                ]
            )
        )

        sections.append(
            .init(
                title: "Recurring fixes and revenue",
                subtitle: "These are the recurring actions Riverhead is using to pay for the plan.",
                tint: .green,
                rows: [
                    .init(
                        title: "Levy growth in the scenario",
                        detail: "Illustrative recurring tax-levy support at \(String(format: "%.1f%%", sim.levyGrowthPercent)).",
                        amount: levyYield,
                        direction: .offset
                    ),
                    .init(
                        title: "Other recurring revenue adds",
                        detail: "Fees, rentals, and other non-levy recurring support.",
                        amount: sim.recurringRevenueAdds,
                        direction: .offset
                    ),
                    .init(
                        title: "Recurring savings package",
                        detail: "Healthcare, overtime, vacancy, and refill discipline.",
                        amount: sim.recurringSavings,
                        direction: .offset
                    )
                ]
            )
        )

        var serviceRows: [BudgetShowcaseRow] = []
        if sim.includeBuildingDepartmentInvestment {
            serviceRows.append(
                .init(
                    title: "Building Department staffing",
                    detail: "Recurring staffing support stays in the plan.",
                    amount: Budget2027ScenarioModel.buildingDepartmentHeadcountInvestment,
                    direction: .investment
                )
            )
        }
        if sim.includeOnlinePlatformInvestment {
            serviceRows.append(
                .init(
                    title: "Online platform modernization",
                    detail: "Resident-facing service and workflow upgrade.",
                    amount: Budget2027ScenarioModel.onlinePlatformUpdateCost,
                    direction: .investment
                )
            )
        }
        if sim.includeTownClerkInvestment {
            serviceRows.append(
                .init(
                    title: "Town Clerk staffing",
                    detail: "One additional recurring staffing position.",
                    amount: Budget2027ScenarioModel.deputyTownClerkCost,
                    direction: .investment
                )
            )
        }
        if sim.additionalCodeEnforcementOfficers > 0 {
            serviceRows.append(
                .init(
                    title: "Code Enforcement expansion",
                    detail: "\(Int(sim.additionalCodeEnforcementOfficers)) officer(s) added in the scenario.",
                    amount: Double(Int(sim.additionalCodeEnforcementOfficers)) * Budget2027ScenarioModel.codeEnforcementOfficerCost,
                    direction: .investment
                )
            )
        }
        if sim.additionalPoliceOfficers > 0 {
            serviceRows.append(
                .init(
                    title: "Police staffing expansion",
                    detail: "\(Int(sim.additionalPoliceOfficers)) officer(s) added in the scenario.",
                    amount: Double(Int(sim.additionalPoliceOfficers)) * Budget2027ScenarioModel.policeOfficerCost,
                    direction: .investment
                )
            )
        }
        if !serviceRows.isEmpty {
            sections.append(
                .init(
                    title: "Named service investments",
                    subtitle: "These are the visible service upgrades the current FY27 package is carrying.",
                    tint: RiverheadTheme.brandSky,
                    rows: serviceRows
                )
            )
        }

        var policyRows: [BudgetShowcaseRow] = [
            .init(
                title: "Building / Code vehicle purchase",
                detail: sim.includeCapitalFleetPurchase ? "Four planned capital vehicles: two for Building and two for Code Enforcement." : "No one-time fleet purchase in the current package.",
                amount: sim.capitalFleetPurchaseCost,
                direction: .guardrail
            ),
            .init(
                title: "Reserve target",
                detail: "Ending reserve policy target set at \(String(format: "%.1f%%", sim.reserveTargetPercent)).",
                amount: targetReserveDollars,
                direction: .guardrail
            ),
            .init(
                title: "One-time reserve deployment",
                detail: appliedOneTimeDeployment > 0 ? "One-time money is being used above the reserve target." : "No one-time reserve use in the current package.",
                amount: appliedOneTimeDeployment,
                direction: .guardrail
            )
        ]

        policyRows.append(
            .init(
                title: "Supervisor + Town Board raise package",
                detail: sim.includeElectedRaisePackage ? "Included as a discretionary recurring add." : "Held out of the baseline best-plan package.",
                amount: sim.electedRaisePackageCost,
                direction: .guardrail
            )
        )

        if sim.otherRecurringPressure > 0 {
            policyRows.insert(
                .init(
                    title: "Other operating pressure",
                    detail: "Insurance, pension, utility, or other recurring non-payroll pressure.",
                    amount: sim.otherRecurringPressure,
                    direction: .cost
                ),
                at: 0
            )
        }

        sections.append(
            .init(
                title: "Guardrails and policy choices",
                subtitle: "These settings shape how aggressive or cautious the FY27 package is.",
                tint: RiverheadTheme.gold,
                rows: policyRows
            )
        )

        return sections
    }

    private var maxReserveTargetPercent: Double {
        max(currentReservePercent, 15)
    }

    private var currentReservePercent: Double {
        guard store.appropriations > 0 else { return 0 }
        return (store.estimatedFundBalance / store.appropriations) * 100
    }

    private var currentLevyEstimate: Double {
        store.appropriations * 0.703
    }

    private var levyYield: Double {
        currentLevyEstimate * (sim.levyGrowthPercent / 100)
    }

    private var totalRecurringOffsets: Double {
        levyYield + sim.recurringRevenueAdds + sim.recurringSavings
    }

    private var recurringBalance: Double {
        totalRecurringOffsets - sim.totalRecurringUses
    }

    private var recurringGapMagnitude: Double {
        max(-recurringBalance, 0)
    }

    private var targetReserveDollars: Double {
        store.appropriations * (sim.reserveTargetPercent / 100)
    }

    private var availableOneTimeRoom: Double {
        max(store.estimatedFundBalance - targetReserveDollars, 0)
    }

    private var deployableOneTimeRoomAfterCapital: Double {
        max(availableOneTimeRoom - sim.capitalFleetPurchaseCost, 0)
    }

    private var appliedOneTimeDeployment: Double {
        min(sim.oneTimeDeployment, deployableOneTimeRoomAfterCapital)
    }

    private var endingReserveDollars: Double {
        max(store.estimatedFundBalance - appliedOneTimeDeployment - sim.capitalFleetPurchaseCost, 0)
    }

    private var endingReservePercent: Double {
        guard store.appropriations > 0 else { return 0 }
        return (endingReserveDollars / store.appropriations) * 100
    }

    private var finalBalanceAfterOneTime: Double {
        recurringBalance + appliedOneTimeDeployment
    }

    private var remainingReserveHeadroom: Double {
        max(deployableOneTimeRoomAfterCapital - appliedOneTimeDeployment, 0)
    }

    private var recurringCoverageRatio: Double {
        guard sim.totalRecurringUses > 0 else { return 1 }
        return min(max(totalRecurringOffsets / sim.totalRecurringUses, 0), 2)
    }

    private var oneTimeCoverageRatio: Double {
        guard recurringGapMagnitude > 0 else { return 0 }
        return min(appliedOneTimeDeployment / recurringGapMagnitude, 1)
    }

    private var sampleTownTaxChange: Double {
        let deltaRate = store.ratePerThousand * (sim.levyGrowthPercent / 100)
        return (sim.sampleAssessment / 1_000) * deltaRate
    }

    private var sampleTownTaxChangePer100k: Double {
        guard sim.sampleAssessment > 0 else { return 0 }
        return sampleTownTaxChange / (sim.sampleAssessment / 100_000)
    }

    private var isCompactPhoneLayout: Bool {
        horizontalSizeClass == .compact
    }

    private var isAccessibilityLayout: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private var pageHorizontalPadding: CGFloat {
        isCompactPhoneLayout ? 12 : 16
    }

    private var metricColumns: [GridItem] {
        let count: Int
        if isAccessibilityLayout {
            count = 1
        } else if isCompactPhoneLayout {
            count = 1
        } else {
            count = 2
        }
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: count)
    }

    private var heroMetricColumns: [GridItem] {
        let count: Int
        if isAccessibilityLayout {
            count = 1
        } else if isCompactPhoneLayout {
            count = 2
        } else {
            count = 3
        }
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: count)
    }

    private var showcaseMetricColumns: [GridItem] {
        let count: Int
        if isAccessibilityLayout || isCompactPhoneLayout {
            count = 1
        } else {
            count = 3
        }
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    private var recurringStatus: BudgetSimulationStatus {
        if recurringBalance >= 0 { return .balanced }
        if recurringBalance >= -250_000 { return .tight }
        return .gap
    }

    private var fiscalConditionStatus: FiscalConditionStatus {
        if recurringBalance < 0 && appliedOneTimeDeployment < recurringGapMagnitude {
            return .warning
        }
        if recurringBalance < 0 || endingReservePercent < sim.reserveTargetPercent || appliedOneTimeDeployment > 0 {
            return .watch
        }
        return .stable
    }

    private var structuralBalanceIndicator: FiscalConditionIndicator {
        if recurringBalance >= 250_000 {
            return .init(
                title: "Structural balance",
                status: .stable,
                detail: "Recurring revenues and savings exceed recurring uses by \(recurringBalance.formatted(.currency(code: "USD")))."
            )
        } else if recurringBalance >= 0 {
            return .init(
                title: "Structural balance",
                status: .watch,
                detail: "The recurring plan balances, but the margin is thin at only \(recurringBalance.formatted(.currency(code: "USD")))."
            )
        } else {
            return .init(
                title: "Structural balance",
                status: .warning,
                detail: "Recurring uses still exceed recurring offsets by \(abs(recurringBalance).formatted(.currency(code: "USD")))."
            )
        }
    }

    private var reserveIndicator: FiscalConditionIndicator {
        if endingReservePercent >= sim.reserveTargetPercent + 2 {
            return .init(
                title: "Reserve resilience",
                status: .stable,
                detail: "Ending reserves stay above target at \(String(format: "%.1f%%", endingReservePercent)) of appropriations."
            )
        } else if endingReservePercent >= sim.reserveTargetPercent {
            return .init(
                title: "Reserve resilience",
                status: .watch,
                detail: "Ending reserves stay on target, but only narrowly, at \(String(format: "%.1f%%", endingReservePercent))."
            )
        } else {
            return .init(
                title: "Reserve resilience",
                status: .warning,
                detail: "Ending reserves fall below the selected target at \(String(format: "%.1f%%", endingReservePercent))."
            )
        }
    }

    private var oneTimeIndicator: FiscalConditionIndicator {
        if appliedOneTimeDeployment == 0 {
            return .init(
                title: "One-time reliance",
                status: .stable,
                detail: "This scenario does not need one-time deployment to make its case."
            )
        } else if recurringBalance >= 0 {
            return .init(
                title: "One-time reliance",
                status: .watch,
                detail: "One-time deployment of \(appliedOneTimeDeployment.formatted(.currency(code: "USD"))) is optional rather than gap-closing."
            )
        } else if appliedOneTimeDeployment >= recurringGapMagnitude {
            return .init(
                title: "One-time reliance",
                status: .warning,
                detail: "One-time deployment is being used to close the recurring gap, which OSC would treat as a caution signal."
            )
        } else {
            return .init(
                title: "One-time reliance",
                status: .warning,
                detail: "Even after \(appliedOneTimeDeployment.formatted(.currency(code: "USD"))) of one-time use, a recurring gap remains."
            )
        }
    }

    private var serviceIndicator: FiscalConditionIndicator {
        if sim.additionalRecurringInvestments == 0 {
            return .init(
                title: "Service commitments",
                status: .watch,
                detail: "No named service investments are currently carried in the 2027 package."
            )
        } else if recurringBalance >= 0 {
            return .init(
                title: "Service commitments",
                status: .stable,
                detail: "The plan openly carries \(sim.serviceInvestmentCount) named investment choices while staying recurring-balanced."
            )
        } else {
            return .init(
                title: "Service commitments",
                status: .watch,
                detail: "The plan carries \(sim.serviceInvestmentCount) named investment choices, but the recurring funding base is not yet fully supporting them."
            )
        }
    }

    private var electedPayIndicator: FiscalConditionIndicator {
        if !sim.includeElectedRaisePackage {
            return .init(
                title: "Elected pay package",
                status: .stable,
                detail: "No supervisor or town-board raise package is included in this 2027 scenario."
            )
        } else if recurringBalance >= 0 {
            return .init(
                title: "Elected pay package",
                status: .watch,
                detail: "The scenario can still carry the modeled elected-pay package of \(sim.electedRaisePackageCost.formatted(.currency(code: "USD"))) a year, but it is a discretionary choice that should be disclosed separately."
            )
        } else {
            return .init(
                title: "Elected pay package",
                status: .warning,
                detail: "The modeled elected-pay package of \(sim.electedRaisePackageCost.formatted(.currency(code: "USD"))) is being tested while the recurring plan is not fully balanced."
            )
        }
    }

    private var fiscalConditionIndicators: [FiscalConditionIndicator] {
        [
            structuralBalanceIndicator,
            reserveIndicator,
            oneTimeIndicator,
            serviceIndicator,
            electedPayIndicator
        ]
    }

    var body: some View {
        @Bindable var sim = sim
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroCard
                flowNavigatorCard

                switch sim.activeStage {
                case .overview:
                    baselineCard
                    planShowcaseCard
                    exactChangesCard
                case .recurring:
                    recurringControlsCard
                    investmentControlsCard
                    electedPayTestCard
                case .oneTime:
                    reserveControlsCard
                case .result:
                    resultCard
                    fiscalConditionCard
                    districtSnapshotCard
                    departmentLensCard
                    hearingPromptsCard
                }
            }
            .padding(.horizontal, pageHorizontalPadding)
            .padding(.vertical, isCompactPhoneLayout ? 16 : 20)
        }
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("2027 Simulator")
        .navigationBarTitleDisplayMode(.inline)
        .adMobBannerPlacement(showDebugPlaceholder: true)
        .onChange(of: sim.reserveTargetPercent) { _, newValue in
            let updatedRoom = max(store.estimatedFundBalance - (store.appropriations * (newValue / 100)), 0)
            sim.oneTimeDeployment = min(sim.oneTimeDeployment, updatedRoom)
        }
        .onChange(of: sim.includeCapitalFleetPurchase) { _, _ in
            sim.oneTimeDeployment = min(sim.oneTimeDeployment, deployableOneTimeRoomAfterCapital)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top) {
                    heroHeaderText
                    Spacer(minLength: 12)
                    bestPlanBadge
                }

                VStack(alignment: .leading, spacing: 10) {
                    heroHeaderText
                    bestPlanBadge
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                compactBullet("Default package keeps Building and Code Enforcement in the plan while carrying modeled labor pressure.")
                compactBullet("Best-plan logic: recurring balance first, elected raises off, reserves only for one-time needs.")
            }

            LazyVGrid(columns: heroMetricColumns, spacing: 10) {
                heroStat("Recurring", recurringBalance.formatted(.currency(code: "USD")), recurringBalance >= 0 ? .green : .orange)
                heroStat("Reserve", String(format: "%.1f%%", endingReservePercent), RiverheadTheme.brandSky)
                heroStat("Tax / $100K", sampleTownTaxChangePer100k.formatted(.currency(code: "USD")), RiverheadTheme.gold)
            }

            LazyVGrid(columns: heroPillColumns, alignment: .leading, spacing: 8) {
                simulatorPill("Recurring first", systemImage: "arrow.triangle.branch")
                simulatorPill("Reserve discipline", systemImage: "banknote")
                simulatorPill("OSC-aligned", systemImage: "checkmark.shield")
                simulatorPill("Tax sensitivity", systemImage: "percent")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        RiverheadTheme.brandSky.opacity(0.24),
                        RiverheadTheme.brandTeal.opacity(0.20),
                        RiverheadTheme.cardBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(RadialGradient(colors: [RiverheadTheme.gold.opacity(0.22), .clear], center: .center, startRadius: 8, endRadius: 140))
                    .frame(width: 180, height: 180)
                    .offset(x: 120, y: -70)

                Circle()
                    .fill(RadialGradient(colors: [RiverheadTheme.brandSky.opacity(0.16), .clear], center: .center, startRadius: 8, endRadius: 120))
                    .frame(width: 150, height: 150)
                    .offset(x: -120, y: 70)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.55), RiverheadTheme.softBorder],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: RiverheadTheme.brandNavy.opacity(0.06), radius: 20, x: 0, y: 10)
    }

    private var heroHeaderText: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Interactive 2027 Budget Simulator")
                .font(.title2.weight(.bold))

            Text("Test the strongest FY27 plan: cover recurring costs, protect service investments, and keep reserves as a backstop.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var bestPlanBadge: some View {
        Text("BEST PLAN")
            .font(.caption.weight(.black))
            .tracking(0.8)
            .foregroundStyle(RiverheadTheme.primaryBlue)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.white.opacity(0.72))
            .clipShape(Capsule())
    }

    private func heroStat(_ title: String, _ value: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .tracking(0.6)

            Text(value)
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Capsule()
                .fill(tint.opacity(0.9))
                .frame(width: 28, height: 4)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var baselineCard: some View {
        simulatorCard(title: "Starting Point", subtitle: "The simulator uses the app’s current Riverhead baseline before any 2027 policy moves.") {
            LazyVGrid(columns: metricColumns, spacing: 12) {
                simulatorMetric("Budget year", value: store.fiscalYearTitle, tint: RiverheadTheme.accent)
                simulatorMetric("Appropriations", value: store.appropriations.formatted(.currency(code: "USD")), tint: RiverheadTheme.gold)
                simulatorMetric("Fund balance", value: store.estimatedFundBalance.formatted(.currency(code: "USD")), tint: .green)
                simulatorMetric("Reserve ratio", value: String(format: "%.1f%%", currentReservePercent), tint: RiverheadTheme.brandSky)
            }

            VStack(alignment: .leading, spacing: 8) {
                summaryRow("Automatic 2027 payroll pressure", value: sim.automaticPayrollPressure)
                summaryRow("Union salary pressure inside that total", value: sim.modeledUnionPressure)
                summaryRow("Approved CSEA 2027 action", value: sim.colaBreakout.cseaPressure)
                summaryRow("Non-contract COLA pressure", value: sim.modeledNonContractCOLAPressure)
                summaryRow("Published-rate pension pressure", value: Budget2027PensionPressureModel.midpointIncrease)
            }

            DisclosureGroup("More FY27 baseline context") {
                VStack(alignment: .leading, spacing: 8) {
                    summaryRow("2026 GF retirement base", value: Budget2026AdoptedGeneralFundModel.retirementTotal)
                    summaryRow("2026 GF health-insurance base", value: Budget2026AdoptedGeneralFundModel.healthInsuranceTotal)
                    summaryRow("Illustrative current levy base", value: currentLevyEstimate)

                    Text("The simulator treats the current levy base as an illustration anchored to the app’s 2026 adopted-budget posture. Its CSEA 2027 wage assumption now reflects the Town Board-approved 2026-2029 deal approved on December 16, 2025: 2.5% plus a $1,000 supplemental payment in 2027.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("The signed PBA contract and the signed SOA MOA both run through December 31, 2026, not 2027. The PBA contract's Article XXXVI salary schedules step from the 2023 schedule to +2.5% in 2024, +2.5% in 2025, and +2.5% in 2026. The SOA MOA's Articles XXVI and XXXII set the 2023-2026 term and increase Sergeant, Detective Sergeant, and Lieutenant schedules by 6% effective July 30, 2023, then +2% in 2024, +4% in 2025, and +6% in 2026. The automatic COLA control therefore treats 2027 PBA, SOA, and non-contract growth as a planning fallback while keeping the approved CSEA 2027 action fixed.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("Pension pressure is now included as a default recurring cost pressure because NYSLRS published the 2026 and 2027 annual invoice rates. PFRS is the largest driver: Tier 6 contributory 25-Year Plan 384 rises from 22.4% to 25.4%, while 20-Year Plan 384-d rises from 28.5% to 31.9%. ERS coordinated rates also rise: Tier 6 from 12.6% to 13.6%, Tier 5 from 16.3% to 18.1%, and Tiers 3/4 from 19.3% to 21.1%. The app uses a townwide planning range of $1.4M to $1.85M above 2026, with a midpoint of $1.625M.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("OSC explains that NYSLRS spreads investment gains or losses above or below the 5.9% assumed return over 8 years. That smoothing makes the 2027 rate increase a lagged cost already visible before budget adoption, not a surprise operating event.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
            .font(.subheadline.weight(.semibold))
        }
    }

    private var flowNavigatorCard: some View {
        simulatorCard(title: "How To Read The 2027 Plan", subtitle: "Move through the budget in order so the choices feel like one connected story instead of separate widgets.") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(BudgetFlowStage.allCases) { stage in
                        Button {
                            sim.activeStage = stage
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: stage.systemImage)
                                    .font(.footnote.weight(.semibold))
                                Text(stage.shortTitle)
                                    .font(.footnote.weight(.semibold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(sim.activeStage == stage ? RiverheadTheme.accent.opacity(0.18) : RiverheadTheme.Surface.inset)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(sim.activeStage == stage ? RiverheadTheme.accent.opacity(0.45) : RiverheadTheme.softBorder, lineWidth: 1)
                            )
                            .foregroundStyle(sim.activeStage == stage ? RiverheadTheme.accent : RiverheadTheme.textPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(sim.activeStageSummaryTitle)
                    .font(.headline)

                Text(sim.activeStageSummaryDetail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(BudgetFlowStage.allCases) { stage in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: sim.activeStage == stage ? "checkmark.circle.fill" : stage.systemImage)
                                .foregroundStyle(sim.activeStage == stage ? RiverheadTheme.accent : .secondary)
                                .frame(width: 18)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(stage.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(stage.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(10)
                        .background(sim.activeStage == stage ? RiverheadTheme.accent.opacity(0.08) : RiverheadTheme.Surface.inset.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }

                HStack(spacing: 10) {
                    if let previousStage = previousStage {
                        Button("Back", systemImage: "chevron.left") {
                            sim.activeStage = previousStage
                        }
                        .buttonStyle(.bordered)
                    }

                    if let nextStage = nextStage {
                        Button("Continue", systemImage: "chevron.right") {
                            sim.activeStage = nextStage
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(RiverheadTheme.accent)
                    }
                }
            }
        }
    }

    private var recurringControlsCard: some View {
        simulatorCard(title: "Recurring Budget Controls", subtitle: "Use these to see whether the 2027 plan balances with recurring money, not just reserve draws.") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Quick presets")
                    .font(.subheadline.weight(.semibold))

                ForEach(ScenarioPreset.allCases) { preset in
                    Button {
                        sim.applyScenarioPreset(preset, currentReservePercent: currentReservePercent, maxReserveTargetPercent: maxReserveTargetPercent)
                    } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preset.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(preset.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(RiverheadTheme.accent)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RiverheadTheme.Surface.inset)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            sliderBlock(
                title: "Property-tax levy growth",
                value: $sim.levyGrowthPercent,
                range: 0...8,
                step: 0.1,
                display: String(format: "%.1f%%", sim.levyGrowthPercent),
                detail: "Illustrative recurring levy yield: \(levyYield.formatted(.currency(code: "USD"))). OSC's levy-limit formula applies to the total levy, not directly to assessments or tax rates. It starts with the prior-year levy, reserve offset, tax-base growth factor, allowable levy growth factor, and prior vs. coming-year PILOTs, then adjusts for carryover capped at 1.5% and narrow exclusions such as pension-rate jumps above two points and qualifying tort judgments. The annual TBGF inputs themselves are published by the Department of Taxation and Finance."
            )

            taxCapRiskCallout

            sliderBlock(
                title: "Automatic COLA / fallback growth",
                value: $sim.automaticCOLAPercent,
                range: 0...6,
                step: 0.1,
                display: String(format: "%.1f%%", sim.automaticCOLAPercent),
                detail: "This updates 2027 fallback growth for PBA, SOA, and non-contract staff automatically. The default uses a 2.5% planning COLA to avoid understating post-2026 salary pressure. CSEA keeps the Town Board-approved 2027 action of +2.5% plus $1,000."
            )

            sliderBlock(
                title: "Other recurring revenue adds",
                value: $sim.recurringRevenueAdds,
                range: 0...3_000_000,
                step: 25_000,
                display: sim.recurringRevenueAdds.formatted(.currency(code: "USD")),
                detail: "Best-plan default is the non-levy recurring add package: fees, rentals, and small surplus recovery outside the tax-cap levy."
            )

            sliderBlock(
                title: "Other recurring cost pressure",
                value: $sim.otherRecurringPressure,
                range: 0...3_000_000,
                step: 25_000,
                display: sim.otherRecurringPressure.formatted(.currency(code: "USD")),
                detail: "Use for inflation, insurance, pensions, utilities, or other non-payroll pressure layered on top of salary and benefit growth. The default now includes a published-rate pension midpoint of \(Budget2027PensionPressureModel.midpointIncrease.formatted(.currency(code: "USD"))) from the NYSLRS 2026/2027 rate schedules. The townwide pension bill is estimated at \(Budget2027PensionPressureModel.totalEstimateLowText) to \(Budget2027PensionPressureModel.totalEstimateHighText), up \(Budget2027PensionPressureModel.increaseLowText) to \(Budget2027PensionPressureModel.increaseHighText) before new hires or new contract settlements."
            )

            sliderBlock(
                title: "Recurring savings package",
                value: $sim.recurringSavings,
                range: 0...3_000_000,
                step: 25_000,
                display: sim.recurringSavings.formatted(.currency(code: "USD")),
                detail: "Best-plan default treats savings as a phased implementation package, not a one-year guarantee. Administrative items can start sooner: freeze discretionary exempt/elected raises, require overtime plans and quarterly recovery review, carry a civilian vacancy factor, and refill selected retirements more selectively. Contract-sensitive items, especially any broader health-premium contribution changes or work-rule adjustments for represented staff, would likely need successor bargaining, MOAs, or side letters rather than appearing fully in year one."
            )

            Text("Plain-English note: this savings package is not a hidden layoff setting. The OT portion assumes tighter scheduling, written departmental overtime plans, and quarterly recovery targets in pressure areas. The vacancy and refill portions assume normal turnover and more selective backfilling, not across-the-board staff cuts. The full modeled amount should be read as a transition target that may phase in over more than one budget year if bargaining or policy adoption takes time.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var taxCapRiskCallout: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Tax-Cap Risk: Override Conversation Likely", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RiverheadTheme.brandCoral)

            Text("Short answer: very possibly, yes. A normal 2.0% levy increase on the app's current Riverhead levy base yields about \(Budget2027ScenarioModel.taxCapLevelLevyYield.formatted(.currency(code: "USD"))), while the published-rate pension increase alone is estimated at \(Budget2027PensionPressureModel.increaseLowText) to \(Budget2027PensionPressureModel.increaseHighText) townwide.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 6) {
                summaryRow("2.0% levy room", value: Budget2027ScenarioModel.taxCapLevelLevyYield, highlight: RiverheadTheme.brandSky)
                summaryRow("Pension pressure midpoint", value: Budget2027PensionPressureModel.midpointIncrease, highlight: RiverheadTheme.brandCoral)
                summaryRow("Pension gap before other costs", value: Budget2027ScenarioModel.pensionPressureAboveTwoPercentLevy, highlight: .orange)
            }

            Text("A final legal answer depends on the OSC tax-cap worksheet: tax-base growth, PILOT changes, carryover, reserve offsets, transfer adjustments, and narrow exclusions. But on the current trend, Riverhead is headed toward a tax-cap override discussion unless it offsets several hundred thousand dollars to more than $1M of recurring pressure through cuts, recurring revenue, fund-balance use, or formula room.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text("Police OT As A Real Offset Lever")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("The strongest near-term offset to revisit is Police Uniform OT. The 2024 actual was \(Budget2027TaxCapOffsetModel.policeUniformOTActual2024.formatted(.currency(code: "USD"))) against a \(Budget2027TaxCapOffsetModel.policeUniformOTBudget2024.formatted(.currency(code: "USD"))) budget, a \(Budget2027TaxCapOffsetModel.policeUniformOTVariance.formatted(.currency(code: "USD"))) overrun, while the adopted 2026 line remains at \(Budget2027TaxCapOffsetModel.policeUniformOTAdopted2026.formatted(.currency(code: "USD"))).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 6) {
                    summaryRow("2024 Uniform OT overrun", value: Budget2027TaxCapOffsetModel.policeUniformOTVariance, highlight: RiverheadTheme.brandCoral)
                    summaryRow("Modeled recoverable target", value: Budget2027TaxCapOffsetModel.policeOvertimeRecoveryTarget, highlight: .green)
                    HStack {
                        Text("Share of overrun recovered")
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 8)
                        Text(Budget2027TaxCapOffsetModel.policeOvertimeRecoveryShare.formatted(.percent.precision(.fractionLength(1))))
                            .monospacedDigit()
                            .foregroundStyle(RiverheadTheme.brandSky)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }

                Text("The March activity report is the workload guardrail. Criminal incidents rose to \(Budget2027PoliceWorkloadModel.march2026CriminalIncidents) from \(Budget2027PoliceWorkloadModel.march2025CriminalIncidents), total incidents rose to \(Budget2027PoliceWorkloadModel.march2026TotalIncidents.formatted()) from \(Budget2027PoliceWorkloadModel.march2025TotalIncidents.formatted()), and domestic incidents stayed high at \(Budget2027PoliceWorkloadModel.march2026DomesticIncidents). At the same time, accidents and summonses fell. That mixed picture argues for OT cause coding, not a blind cut.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 6) {
                    countSummaryRow("Criminal incidents", current: Budget2027PoliceWorkloadModel.march2026CriminalIncidents, prior: Budget2027PoliceWorkloadModel.march2025CriminalIncidents, highlight: RiverheadTheme.brandCoral)
                    countSummaryRow("Total incidents", current: Budget2027PoliceWorkloadModel.march2026TotalIncidents, prior: Budget2027PoliceWorkloadModel.march2025TotalIncidents, highlight: .orange)
                    countSummaryRow("Vehicle accidents", current: Budget2027PoliceWorkloadModel.march2026Accidents, prior: Budget2027PoliceWorkloadModel.march2025Accidents, highlight: .green)
                    countSummaryRow("Summonses issued", current: Budget2027PoliceWorkloadModel.march2026Summonses, prior: Budget2027PoliceWorkloadModel.march2025Summonses, highlight: .green)
                }

                Text("This should not be booked as an automatic cut. It only becomes a credible recurring offset if the Police Department publishes monthly OT by cause, separates unavoidable coverage from discretionary assignments, audits court/recall/training/event OT, and shows a staffing/scheduling plan that captures part of the variance without reducing minimum patrol coverage. Because Riverhead completed its NIBRS transition in July 2024, the app treats the March offense mix as useful workload context, not a perfect long-run trend by itself.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(RiverheadTheme.Surface.inset.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Recurring Offsets To Counter The Risk")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)

                ForEach(Budget2027TaxCapOffsetModel.offsets) { offset in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(offset.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 8)
                        Text(offset.amount.formatted(.currency(code: "USD")))
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(offset.isStretch ? RiverheadTheme.brandGold : .green)
                    }
                }

                Divider().opacity(0.35)

                summaryRow("Practical offset package", value: Budget2027TaxCapOffsetModel.totalOffsetPackage, highlight: .green)

                Text("Base management actions total about \(Budget2027TaxCapOffsetModel.baseOffsetPackage.formatted(.currency(code: "USD"))). Adding a more aggressive recurring revenue and service-cost-recovery target can push the package just over \(Budget2027TaxCapOffsetModel.totalOffsetPackage.formatted(.currency(code: "USD"))). That is enough to counter a large share of the pension-driven cap risk without treating fund balance as the recurring fix.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(RiverheadTheme.Surface.inset.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RiverheadTheme.brandCoral.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(RiverheadTheme.brandCoral.opacity(0.22), lineWidth: 1)
        )
    }

    private var exactChangesCard: some View {
        simulatorCard(title: "Exact FY27 Changes", subtitle: "This is the itemized list of what the current FY27 scenario is actually doing.") {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(groupedFY27Changes) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(group.title)
                                .font(.subheadline.weight(.semibold))
                            Text(group.subtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        ForEach(group.lines) { line in
                            VStack(alignment: .leading, spacing: 4) {
                                ViewThatFits(in: .horizontal) {
                                    HStack(alignment: .top) {
                                        Text(line.title)
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Text(line.valueText)
                                            .font(.subheadline.weight(.semibold))
                                            .monospacedDigit()
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(line.title)
                                            .font(.subheadline.weight(.semibold))
                                        Text(line.valueText)
                                            .font(.subheadline.weight(.semibold))
                                            .monospacedDigit()
                                    }
                                }

                                Text(line.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RiverheadTheme.Surface.inset)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
            }
        }
    }

    private var planShowcaseCard: some View {
        simulatorCard(title: "2027 Plan at a Glance", subtitle: "This turns the current scenario into a friendlier budget story: what is driving costs, what is paying for the plan, and what service changes residents would actually feel.") {
            LazyVGrid(columns: showcaseMetricColumns, spacing: 12) {
                simulatorMetric("Recurring fixes", value: totalRecurringOffsets.formatted(.currency(code: "USD")), tint: .green)
                simulatorMetric("Service adds", value: sim.additionalRecurringInvestments.formatted(.currency(code: "USD")), tint: RiverheadTheme.brandSky)
                simulatorMetric("Payroll pressure", value: sim.automaticPayrollPressure.formatted(.currency(code: "USD")), tint: .orange)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(planShowcaseSections) { section in
                    showcaseSection(section)
                }
            }
        }
    }

    private var investmentControlsCard: some View {
        simulatorCard(title: "Targeted 2027 Investments", subtitle: "Carry the named service investments openly instead of hiding them inside a generic placeholder.") {
            investmentToggle(
                title: "Building Department staffing investment",
                isOn: $sim.includeBuildingDepartmentInvestment,
                amount: Budget2027ScenarioModel.buildingDepartmentHeadcountInvestment,
                detail: "Keeps the baseline Building Department headcount increase in the recurring plan."
            )

            investmentToggle(
                title: "Online platform modernization",
                isOn: $sim.includeOnlinePlatformInvestment,
                amount: Budget2027ScenarioModel.onlinePlatformUpdateCost,
                detail: "Carries the resident-facing workflow and online-service upgrade cost."
            )

            investmentToggle(
                title: "Town Clerk staffing investment",
                isOn: $sim.includeTownClerkInvestment,
                amount: Budget2027ScenarioModel.deputyTownClerkCost,
                detail: "Uses the current deputy town clerk proxy for one added recurring position."
            )

            stepperBlock(
                title: "Additional Code Enforcement Officers",
                value: $sim.additionalCodeEnforcementOfficers,
                range: 0...4,
                step: 1,
                detail: "Uses the current ordinance/code staff planning cost per officer.",
                amountPerUnit: Budget2027ScenarioModel.codeEnforcementOfficerCost
            )

            stepperBlock(
                title: "Additional police officers",
                value: $sim.additionalPoliceOfficers,
                range: 0...4,
                step: 1,
                detail: "Uses the app’s current entry-level police officer planning proxy.",
                amountPerUnit: Budget2027ScenarioModel.policeOfficerCost
            )

            Divider().opacity(0.25)

            Text("These are explicit service adds. In the app's best-plan logic, Riverhead is trying to control avoidable OT and refill costs while still choosing to add visible staffing in Building, Code Enforcement, the Town Clerk's office, and policing.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            summaryRow("Total recurring investments", value: sim.additionalRecurringInvestments, highlight: .orange)
        }
    }

    private var electedPayTestCard: some View {
        simulatorCard(title: "Elected Raise Test", subtitle: "This lets you test whether Riverhead could afford a discretionary Supervisor and Town Board raise package in 2027.") {
            investmentToggle(
                title: "Include Supervisor + Town Board raise package",
                isOn: $sim.includeElectedRaisePackage,
                amount: Budget2027ScenarioModel.electedRaisePackageCost,
                detail: "Illustrative recurring package based on the 2025 reported proposal: about +$10,000 for the Supervisor and about +$3,672 for each of four Town Board seats, or roughly \(Budget2027ScenarioModel.electedRaisePackageCost.formatted(.currency(code: "USD"))) a year before any fringe spillover."
            )

            Text("Town Law §27 says the town board fixes town salaries, but board-member compensation cannot simply be set above the preliminary-budget hearing notice unless the Town uses the required budget or local-law path for that fiscal year. In policy terms, this simulator treats elected raises as discretionary and separate from the 2027 service and labor package.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if sim.includeElectedRaisePackage {
                summaryRow("Modeled elected-pay package", value: sim.electedRaisePackageCost, highlight: .orange)
            }
        }
    }

    private var reserveControlsCard: some View {
        simulatorCard(title: "Reserve Policy & One-Time Tools", subtitle: "This section shows how much one-time room exists if Riverhead resets reserves toward a 2027 target.") {
            investmentToggle(
                title: "Planned capital fleet purchase",
                isOn: $sim.includeCapitalFleetPurchase,
                amount: Budget2027ScenarioModel.plannedFleetPurchaseCost,
                detail: "One-time planned purchase of four vehicles at $84,000 each: two for Building Department and two for Code Enforcement."
            )

            sliderBlock(
                title: "Reserve target",
                value: $sim.reserveTargetPercent,
                range: 15...maxReserveTargetPercent,
                step: 0.1,
                display: String(format: "%.1f%%", sim.reserveTargetPercent),
                detail: "Current reserve ratio is about \(String(format: "%.1f%%", currentReservePercent)). OSC's Accounting and Reporting Manual treats unrestricted fund balance, assigned appropriations, and legally restricted reserves as different buckets, so this target is a policy gauge for Riverhead's flexible cushion, not a proxy for every reserve on the books."
            )

            sliderBlock(
                title: "One-time deployment",
                value: Binding(
                    get: { sim.oneTimeDeployment },
                    set: { sim.oneTimeDeployment = min($0, deployableOneTimeRoomAfterCapital) }
                ),
                range: 0...max(deployableOneTimeRoomAfterCapital, 1),
                step: 25_000,
                display: appliedOneTimeDeployment.formatted(.currency(code: "USD")),
                detail: "Available one-time room above target after the planned fleet purchase: \(deployableOneTimeRoomAfterCapital.formatted(.currency(code: "USD"))). Gross room above target is \(availableOneTimeRoom.formatted(.currency(code: "USD"))). This is policy headroom, not an OSC excess-levy reserve; any tax levy collected above the legal limit would have to be set aside and used to offset the following year's levy. OSC's Reserve Funds guide also says reserve money should not be a parking lot for excess cash and should move only under a clear legal purpose and board action."
            )

            sliderBlock(
                title: "Sample assessment",
                value: $sim.sampleAssessment,
                range: 250_000...1_500_000,
                step: 10_000,
                display: sim.sampleAssessment.formatted(.currency(code: "USD")),
                detail: "This only changes the example Town-tax impact line below."
            )

            Text("Best practice test: use one-time money for corrections, debt reduction, transition costs, or properly budgeted capital needs, not to hide recurring operating gaps. OSC's toolkit and financial-condition guidance similarly point local governments toward reserve discipline first, monthly or periodic variance review, and early corrective action when trend lines weaken. The Accounting and Reporting Manual also separates capital-project financing from operating funds, while OSC's Reserve Funds guide says boards should keep written plans, periodic reports, and clear public resolutions for reserve transfers. The tax-cap reserve bulletin is even tighter: if a levy is found to be above the legal limit, the excess must be reserved and carried into the next year as an offset, not treated as flexible cash.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var resultCard: some View {
        simulatorCard(title: "Simulation Result", subtitle: "A balanced 2027 plan should clear the recurring test before any one-time reserve deployment is counted.") {
            LazyVGrid(columns: metricColumns, spacing: 12) {
                simulatorMetric("Recurring gap still open", value: recurringGapMagnitude.formatted(.currency(code: "USD")), tint: recurringGapMagnitude == 0 ? .green : .orange)
                simulatorMetric("Final position after one-time", value: finalBalanceAfterOneTime.formatted(.currency(code: "USD")), tint: finalBalanceAfterOneTime >= 0 ? .green : .red)
                simulatorMetric("Reserve headroom left", value: remainingReserveHeadroom.formatted(.currency(code: "USD")), tint: RiverheadTheme.brandSky)
                simulatorMetric("Town tax per $100K", value: sampleTownTaxChangePer100k.formatted(.currency(code: "USD")), tint: RiverheadTheme.gold)
            }

            HStack(spacing: 10) {
                statusBadge(recurringStatus)
                Text(recurringStatus.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                comparisonBar(
                    title: "Recurring coverage",
                    leadingLabel: "Offsets",
                    leadingValue: totalRecurringOffsets,
                    trailingLabel: "Uses",
                    trailingValue: sim.totalRecurringUses,
                    progress: recurringCoverageRatio,
                    tint: recurringBalance >= 0 ? .green : .orange
                )

                comparisonBar(
                    title: "One-time gap coverage",
                    leadingLabel: "One-time deployment",
                    leadingValue: appliedOneTimeDeployment,
                    trailingLabel: "Recurring gap",
                    trailingValue: recurringGapMagnitude,
                    progress: oneTimeCoverageRatio,
                    tint: appliedOneTimeDeployment >= recurringGapMagnitude && recurringGapMagnitude > 0 ? .green : RiverheadTheme.brandSky
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                summaryRow("Recurring offsets", value: totalRecurringOffsets)
                summaryRow("Recurring uses", value: sim.totalRecurringUses)
                summaryRow("Recurring balance", value: recurringBalance, highlight: recurringBalance >= 0 ? .green : .orange)
                summaryRow("Planned capital fleet purchase", value: sim.capitalFleetPurchaseCost)
                summaryRow("Applied one-time deployment", value: appliedOneTimeDeployment)
                summaryRow("Ending reserve level", value: endingReserveDollars)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Ending reserve ratio: \(String(format: "%.1f%%", endingReservePercent))")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("Sample Town-tax effect on a \(sim.sampleAssessment.formatted(.currency(code: "USD"))) assessment: about \(sampleTownTaxChange.formatted(.currency(code: "USD"))) of annual Town-tax change at the selected levy growth rate.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Balance Test")
                    .font(.headline)

                Text(balanceTestNarrative)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("What This Suggests")
                    .font(.headline)

                suggestionCallout(
                    title: recurringBalance >= 0 ? "The plan is close to workable" : "The plan still needs a correction",
                    detail: resultSuggestion,
                    systemImage: recurringBalance >= 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                    tint: recurringBalance >= 0 ? .green : .orange
                )
            }
        }
    }

    private var hearingPromptsCard: some View {
        simulatorCard(title: "Questions This Simulator Helps You Ask", subtitle: "Use these in hearings, work sessions, or board discussions.") {
            VStack(alignment: .leading, spacing: 10) {
                promptLine("Start with recurring pressure", text: "How much of the 2027 increase is recurring payroll or benefits pressure before new policy choices are added?")
                promptLine("Check service protection", text: "Does the package keep Building, Code Enforcement, and other named investments in the recurring plan without leaning on reserves?")
                promptLine("Separate recurring from one-time", text: "What portion of the package is actually balanced with recurring money rather than reserve draws?")
                promptLine("Explain reserve use clearly", text: "If reserves are used, what exact imbalance or debt pressure are they correcting, and what remains after that use?")
                promptLine("Translate the levy choice", text: "What levy growth level is being assumed, and what does that mean for a typical Riverhead homeowner?")
                promptLine("Use the OSC warning lens", text: "If the plan still leans on one-time tools, would OSC's fiscal-stress lens read that as prudent transition management or a structural warning sign?")
                promptLine("Keep discretionary raises last", text: "If elected raises are being considered, are they fully supported after union pressure, COLA fallout, and the Building and Code Enforcement investments are already covered?")
            }
        }
    }

    private var fiscalConditionCard: some View {
        simulatorCard(title: "Fiscal Condition Scorecard", subtitle: "This translates the scenario into OSC-style warning signals instead of leaving the analysis in prose.") {
            HStack(spacing: 10) {
                Label(fiscalConditionStatus.title, systemImage: fiscalConditionStatus.icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(fiscalConditionStatus.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(fiscalConditionStatus.color.opacity(0.12))
                    .clipShape(Capsule())

                Text(fiscalConditionStatus.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(fiscalConditionIndicators) { indicator in
                    fiscalConditionRow(indicator)
                }
            }

            Text("OSC's Financial Condition Analysis guide recommends tracking recurring revenue coverage, reserve position, debt and expenditure trends, and budget-to-actual variances over multiple years. This scorecard is a scenario-level first step, not a substitute for a full 5-to-10-year trend review.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var districtSnapshotCard: some View {
        simulatorCard(title: "2027 District Snapshot", subtitle: "Brookhaven-style structural discipline starts by checking whether each major operating district can stand on its own.") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(districtSnapshots) { snapshot in
                    districtSnapshotRow(snapshot)
                }
            }

            Text("This is a first-pass district view. The simulator's recurring math still rolls up to one combined 2027 package, but this card makes clear which funds are carrying payroll and service pressure and which enterprise-style funds need their own reserve and rate story.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var departmentLensCard: some View {
        simulatorCard(title: "Department + Rebalance Lens", subtitle: "Open the new department explorer and rebalance screen when you want to move from town-wide FY27 story to account-level pressure points.") {
            LazyVGrid(columns: showcaseMetricColumns, spacing: 12) {
                departmentLensMetricCard(
                    title: "Matched functions",
                    value: "\(DepartmentBudgetLensData.departmentRecords.filter { $0.salaryBase != nil }.count)",
                    detail: "Departments with both staffing and adopted-total context."
                )

                departmentLensMetricCard(
                    title: "Expense watch list",
                    value: "\(DepartmentBudgetLensData.rebalancedSpending.filter { $0.direction == .tighten }.count)",
                    detail: "Accounts worth tightening or monitoring harder."
                )

                departmentLensMetricCard(
                    title: "Service restore list",
                    value: "\(DepartmentBudgetLensData.rebalancedSpending.filter { $0.direction == .strengthen }.count)",
                    detail: "Accounts that may be too lean for service expectations."
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Top FY26 rebalance pressure points")
                    .font(.subheadline.weight(.semibold))

                ForEach(Array(DepartmentBudgetLensData.rebalancedSpending.filter { $0.direction == .tighten }.sorted { $0.change > $1.change }.prefix(3))) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.orange.opacity(0.8))
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.account)
                                .font(.footnote.weight(.semibold))
                            Text("\(item.fundFunction) • \(item.change.formatted(.currency(code: "USD")))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            VStack(spacing: 10) {
                NavigationLink {
                    DepartmentExpenseExplorerView()
                } label: {
                    budgetLensNavigationRow(
                        title: "Open Department Expense Explorer",
                        subtitle: "See staffing, salary base, adopted totals, and non-salary layers together.",
                        icon: "building.columns.circle.fill",
                        tint: .blue
                    )
                }

                NavigationLink {
                    RebalancedSpendingView()
                } label: {
                    budgetLensNavigationRow(
                        title: "Open Rebalanced Spending",
                        subtitle: "See which FY26 accounts look heavy, lean, or worth closer monitoring.",
                        icon: "arrow.left.arrow.right.circle.fill",
                        tint: .orange
                    )
                }
            }

            Text("These tools are rooted in Riverhead's 2026 staffing files and the adopted budget, so they help the FY27 simulator move from broad scenario math into specific departments and account lines.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var balanceTestNarrative: String {
        if recurringBalance >= 0 {
            return "This scenario clears the recurring-budget test. One-time deployment, if any, can be framed as optional transition or correction money rather than a crutch."
        } else if appliedOneTimeDeployment >= abs(recurringBalance) {
            return "This scenario only balances if one-time reserves are used to close a recurring operating gap. That can buy time, but it does not fully solve the structural problem."
        } else {
            return "This scenario remains structurally out of balance even after the selected reserve deployment. It likely needs more recurring revenue, more savings, smaller investments, or a different levy choice."
        }
    }

    private var resultSuggestion: String {
        if recurringBalance >= 250_000 && endingReservePercent >= sim.reserveTargetPercent {
            return "This mix gives Riverhead room to cover salary pressure, preserve the reserve target, and still carry the service investments openly."
        } else if recurringBalance >= 0 {
            return "This is a workable middle-path scenario. The next question is whether one-time deployment is correcting a real imbalance, debt burden, or transition cost."
        } else if appliedOneTimeDeployment > 0 {
            return "This package still leans on one-time money. The safer adjustment would be more recurring savings, more stable revenue, or trimming new recurring commitments."
        } else {
            return "This setting reads as a warning light. Riverhead would likely need a stronger recurring package or a clearer levy choice before it could responsibly move into 2027."
        }
    }

    @ViewBuilder
    private func departmentLensMetricCard(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(RiverheadTheme.textPrimary)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RiverheadTheme.Surface.card.opacity(0.95))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(RiverheadTheme.softBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func budgetLensNavigationRow(title: String, subtitle: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(tint.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.20), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func simulatorCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .topLeading) {
                RiverheadTheme.cardBackground
                LinearGradient(
                    colors: [Color.white.opacity(0.18), .clear],
                    startPoint: .topLeading,
                    endPoint: .center
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RiverheadTheme.softBorder, lineWidth: 1)
        )
        .shadow(color: RiverheadTheme.brandNavy.opacity(0.04), radius: 12, x: 0, y: 6)
    }

    private func simulatorMetric(_ title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            Capsule()
                .fill(tint.opacity(0.85))
                .frame(width: 34, height: 5)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [tint.opacity(0.10), RiverheadTheme.Surface.inset],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tint.opacity(0.14), lineWidth: 1)
        )
    }

    private var heroPillColumns: [GridItem] {
        let count = isAccessibilityLayout ? 1 : (horizontalSizeClass == .compact ? 2 : 4)
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
    }

    private var previousStage: BudgetFlowStage? {
        guard let currentIndex = BudgetFlowStage.allCases.firstIndex(of: sim.activeStage), currentIndex > 0 else {
            return nil
        }
        return BudgetFlowStage.allCases[currentIndex - 1]
    }

    private var nextStage: BudgetFlowStage? {
        guard let currentIndex = BudgetFlowStage.allCases.firstIndex(of: sim.activeStage),
              currentIndex < BudgetFlowStage.allCases.count - 1 else {
            return nil
        }
        return BudgetFlowStage.allCases[currentIndex + 1]
    }

    private func compactBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(RiverheadTheme.accent.opacity(0.85))
                .frame(width: 6, height: 6)
                .padding(.top, 6)

            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func sliderBlock(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        display: String,
        detail: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(display)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }

            Slider(value: value, in: range, step: step)

            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(RiverheadTheme.Surface.inset.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func investmentToggle(
        title: String,
        isOn: Binding<Bool>,
        amount: Double,
        detail: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: isOn) {
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(isOn.wrappedValue ? amount.formatted(.currency(code: "USD")) : "$0")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }
            }

            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(RiverheadTheme.Surface.inset.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func stepperBlock(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        detail: String,
        amountPerUnit: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Stepper(value: value, in: range, step: step) {
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(Int(value.wrappedValue))")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }
            }

            Text("\((Double(Int(value.wrappedValue)) * amountPerUnit).formatted(.currency(code: "USD"))) total")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)

            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(RiverheadTheme.Surface.inset.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func summaryRow(_ label: String, value: Double, highlight: Color = .primary) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value.formatted(.currency(code: "USD")))
                .monospacedDigit()
                .foregroundStyle(highlight)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }

    private func countSummaryRow(_ label: String, current: Int, prior: Int, highlight: Color = .primary) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text("\(current.formatted()) vs. \(prior.formatted())")
                .monospacedDigit()
                .foregroundStyle(highlight)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }

    private func simulatorPill(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(RiverheadTheme.primaryBlue)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.60))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func statusBadge(_ status: BudgetSimulationStatus) -> some View {
        Label(status.title, systemImage: status.icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(status.color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func promptLine(_ title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "questionmark.circle.fill")
                .foregroundStyle(RiverheadTheme.accent)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(RiverheadTheme.Surface.inset.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func suggestionCallout(title: String, detail: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(tint.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func showcaseSection(_ section: BudgetShowcaseSection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top) {
                    showcaseHeaderText(section)
                    Spacer(minLength: 12)
                    showcaseAccent(section)
                }

                VStack(alignment: .leading, spacing: 8) {
                    showcaseHeaderText(section)
                    showcaseAccent(section)
                }
            }

            ForEach(section.rows) { row in
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: row.direction.icon)
                            .foregroundStyle(row.direction.color)
                            .frame(width: 18)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(row.title)
                                .font(.subheadline.weight(.semibold))
                            Text(row.detail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 12)

                        Text(row.displayAmount)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(row.direction.color)
                            .monospacedDigit()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: row.direction.icon)
                                .foregroundStyle(row.direction.color)
                                .frame(width: 18)

                            Text(row.title)
                                .font(.subheadline.weight(.semibold))
                        }

                        Text(row.displayAmount)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(row.direction.color)
                            .monospacedDigit()

                        Text(row.detail)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(RiverheadTheme.Surface.inset.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [section.tint.opacity(0.08), RiverheadTheme.Surface.inset.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(section.tint.opacity(0.14), lineWidth: 1)
        )
    }

    private func showcaseHeaderText(_ section: BudgetShowcaseSection) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(section.title)
                .font(.subheadline.weight(.semibold))
            Text(section.subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func showcaseAccent(_ section: BudgetShowcaseSection) -> some View {
        Capsule()
            .fill(section.tint.opacity(0.88))
            .frame(width: 26, height: 6)
            .padding(.top, 6)
    }

    private func comparisonBar(
        title: String,
        leadingLabel: String,
        leadingValue: Double,
        trailingLabel: String,
        trailingValue: Double,
        progress: Double,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(leadingLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(leadingValue.formatted(.currency(code: "USD")))
                        .font(.footnote.weight(.semibold))
                        .monospacedDigit()
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(trailingLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(trailingValue.formatted(.currency(code: "USD")))
                        .font(.footnote.weight(.semibold))
                        .monospacedDigit()
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(RiverheadTheme.softBorder.opacity(0.45))
                    Capsule()
                        .fill(tint.opacity(0.85))
                        .frame(width: max(min(geo.size.width * min(progress, 1), geo.size.width), 10))
                }
            }
            .frame(height: 12)
        }
        .padding(12)
        .background(RiverheadTheme.Surface.inset)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func fiscalConditionRow(_ indicator: FiscalConditionIndicator) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: indicator.status.icon)
                .foregroundStyle(indicator.status.color)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 4) {
                Text(indicator.title)
                    .font(.subheadline.weight(.semibold))
                Text(indicator.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(indicator.status.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(indicator.status.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(indicator.status.color.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(12)
        .background(RiverheadTheme.Surface.inset)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func districtSnapshotRow(_ snapshot: DistrictSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(snapshot.title)
                        .font(.subheadline.weight(.semibold))
                    Text(snapshot.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(snapshot.status.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(snapshot.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(snapshot.status.color.opacity(0.12))
                    .clipShape(Capsule())
            }

            if let appropriations = snapshot.appropriations {
                HStack {
                    Text("Latest appropriations in app")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(appropriations.formatted(.currency(code: "USD")))
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                }
            }

            HStack {
                Text("Assigned 2027 pressure")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(snapshot.assignedPressure.formatted(.currency(code: "USD")))
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
            }

            HStack {
                Text("Assigned shared support")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(snapshot.assignedSupport.formatted(.currency(code: "USD")))
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
            }

            HStack {
                Text("Shared-package gap")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(snapshot.sharedGap.formatted(.currency(code: "USD")))
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(snapshot.sharedGap >= 0 ? .green : .orange)
            }

            Text(snapshot.detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(RiverheadTheme.Surface.inset)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var districtSnapshots: [DistrictSnapshot] {
        let templates: [(String, String, String, String)] = [
            ("A01", "A01 General Fund", "Core tax-supported operating fund", "This is where the modeled 2027 police pressure, levy choices, and named service investments land most directly."),
            ("DA1", "DA1 Highway Fund", "Separate operating district", "Highway should be checked separately for overtime, fuel, equipment timing, and storm volatility even if the town-wide package looks balanced."),
            ("ES1", "ES1 Riverhead Sewer District", "Known reserve-watch fund", "ES1 already reads as a reserve-watch fund in the app's 2026 review, so 2027 should show whether rates and recurring support are carrying operations."),
            ("ES3", "ES3 Calverton Sewer District", "Known reserve-dependent fund", "ES3 was already flagged for fund-balance dependence in 2026, so it should remain on the structural watchlist until recurring support is clearer."),
            ("EW1", "EW1 Water District", "Rate and reserve watch", "EW1 should show clearly whether rate support, operating savings, or temporary reserve use is carrying the 2027 plan.")
        ]

        return templates.map { code, title, subtitle, detail in
            let appropriations = latestAppropriation(forFundCodePrefix: code)
            let assignedPressure = districtAssignedPressure(forFundCodePrefix: code, appropriations: appropriations)
            let assignedSupport = districtAssignedSupport(forFundCodePrefix: code, appropriations: appropriations)
            let sharedGap = assignedSupport - assignedPressure

            return DistrictSnapshot(
                title: title,
                subtitle: subtitle,
                appropriations: appropriations,
                assignedPressure: assignedPressure,
                assignedSupport: assignedSupport,
                sharedGap: sharedGap,
                status: districtStatus(forFundCodePrefix: code, sharedGap: sharedGap),
                detail: detail
            )
        }
    }

    private func latestAppropriation(forFundCodePrefix prefix: String) -> Double? {
        guard let fundName = store.funds.first(where: { $0.hasPrefix(prefix) }) else { return nil }
        return store.valueSeries(for: fundName, metric: .appropriations)
            .max(by: { $0.year < $1.year })?
            .value
    }

    private var districtAppropriationTotal: Double {
        ["A01", "DA1", "ES1", "ES3", "EW1"]
            .compactMap { latestAppropriation(forFundCodePrefix: $0) }
            .reduce(0, +)
    }

    private func districtWeight(for appropriations: Double?) -> Double {
        guard let appropriations, districtAppropriationTotal > 0 else { return 0 }
        return appropriations / districtAppropriationTotal
    }

    private func districtAssignedPressure(forFundCodePrefix prefix: String, appropriations: Double?) -> Double {
        let weight = districtWeight(for: appropriations)
        let allocatablePressure = sim.colaBreakout.cseaPressure + sim.colaBreakout.nonContractPressure + sim.otherRecurringPressure
        let sharedPressure = allocatablePressure * weight

        if prefix == "A01" {
            return sharedPressure + sim.colaBreakout.pbaPressure + sim.colaBreakout.soaPressure + sim.additionalRecurringInvestments
        }
        return sharedPressure
    }

    private func districtAssignedSupport(forFundCodePrefix prefix: String, appropriations: Double?) -> Double {
        let weight = districtWeight(for: appropriations)
        let sharedSupport = sim.recurringSavings * weight

        if prefix == "A01" {
            return sharedSupport + levyYield + sim.recurringRevenueAdds
        }
        return sharedSupport
    }

    private func districtStatus(forFundCodePrefix prefix: String, sharedGap: Double) -> DistrictSnapshotStatus {
        if sharedGap >= 0 {
            return .stable
        }
        if prefix == "ES1" || prefix == "ES3" || prefix == "EW1" {
            return .warning
        }
        return sharedGap >= -250_000 ? .watch : .warning
    }
}

