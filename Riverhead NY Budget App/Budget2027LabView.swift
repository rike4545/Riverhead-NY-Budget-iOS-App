import SwiftUI
import Charts

@MainActor
struct Budget2027LabView: View {
    @Environment(RBBudgetStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var scheme

    @State private var selectedPanel: Budget2027LabPanel = .scenario
    @State private var selectedPreset: Budget2027LabPreset = .bestPlan
    @State private var levyGrowthPercent = Budget2027LabModel.defaultLevyGrowthPercent
    @State private var recurringSavings = Budget2027LabModel.defaultRecurringSavings
    @State private var recurringRevenueAdds = Budget2027LabModel.defaultRecurringRevenueAdds
    @State private var otherRecurringPressure = Budget2027LabModel.defaultOtherRecurringPressure
    @State private var reserveTargetPercent = Budget2027LabModel.defaultReserveTargetPercent
    @State private var oneTimeUse = 0.0
    @State private var assessment = 450_000.0
    @State private var buildingInvestment = true
    @State private var platformInvestment = true
    @State private var clerkInvestment = true
    @State private var codeOfficers = 2.0
    @State private var policeOfficers = 2.0
    @State private var fleetPurchase = true
    @State private var electedRaisePackage = false
    @State private var customItems: [Budget2027CustomItem] = Budget2027CustomItem.seeded
    @State private var draftItemTitle = ""
    @State private var draftItemAmount = 0.0
    @State private var draftItemKind: Budget2027CustomItemKind = .recurringCost
    @State private var draftItemNote = ""

    private var scenario: Budget2027LabScenario {
        Budget2027LabScenario(
            store: store,
            levyGrowthPercent: levyGrowthPercent,
            recurringSavings: recurringSavings,
            recurringRevenueAdds: recurringRevenueAdds,
            otherRecurringPressure: otherRecurringPressure,
            reserveTargetPercent: reserveTargetPercent,
            oneTimeUse: oneTimeUse,
            assessment: assessment,
            buildingInvestment: buildingInvestment,
            platformInvestment: platformInvestment,
            clerkInvestment: clerkInvestment,
            codeOfficers: Int(codeOfficers),
            policeOfficers: Int(policeOfficers),
            fleetPurchase: fleetPurchase,
            electedRaisePackage: electedRaisePackage,
            customItems: customItems
        )
    }

    private var columns: [GridItem] {
        let count = horizontalSizeClass == .compact || dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    var body: some View {
        ZStack {
            RiverheadTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    presetPicker
                    panelPicker
                    dashboard

                    switch selectedPanel {
                    case .agent:
                        budgetAgent
                    case .scenario:
                        scenarioBuilder
                    case .taxes:
                        taxImpact
                    case .departments:
                        departmentImpacts
                    case .watchlist:
                        watchlist
                    case .hearing:
                        hearingMode
                    case .sources:
                        sourceTrail
                    }
                }
                .padding(.horizontal, horizontalSizeClass == .compact ? 12 : 16)
                .padding(.vertical, 18)
            }
        }
        .navigationTitle("2027 Budget Lab")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPreset) { _, preset in
            applyPreset(preset)
        }
    }

    private var header: some View {
        LabCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "slider.horizontal.below.sun.max.fill")
                        .font(.title2)
                        .foregroundStyle(RiverheadTheme.brandGold)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.18)))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("2027 Budget Lab")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)

                        Text("Build a scenario, check the tax impact, inspect department pressure, and leave with hearing-ready questions.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 8) {
                    labBadge("Interactive", icon: "hand.tap.fill")
                    labBadge("Plain English", icon: "text.bubble.fill")
                    labBadge("Source Aware", icon: "doc.text.magnifyingglass")
                }
            }
        } background: {
            RiverheadTheme.headerGradient
        }
        .shadow(color: RiverheadTheme.cardShadow(scheme, elevated: true), radius: 18, x: 0, y: 10)
    }

    private var presetPicker: some View {
        LabCard(title: "Scenario Presets", subtitle: "Start with a public-policy posture, then adjust the details.") {
            Picker("Scenario preset", selection: $selectedPreset) {
                ForEach(Budget2027LabPreset.allCases) { preset in
                    Text(preset.title).tag(preset)
                }
            }
            .pickerStyle(.segmented)

            Text(selectedPreset.detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var panelPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Budget2027LabPanel.allCases) { panel in
                    Button {
                        selectedPanel = panel
                    } label: {
                        Label(panel.title, systemImage: panel.icon)
                            .font(.footnote.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(selectedPanel == panel ? RiverheadTheme.brandSky.opacity(0.22) : RiverheadTheme.Surface.elevated)
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(selectedPanel == panel ? RiverheadTheme.brandSky : RiverheadTheme.softBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selectedPanel == panel ? RiverheadTheme.brandNavy : .primary)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var dashboard: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            metricTile(
                "Recurring result",
                value: scenario.recurringBalance.currencyText,
                detail: scenario.structuralStatus,
                icon: scenario.recurringBalance >= 0 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                tint: scenario.recurringBalance >= 0 ? .green : .orange
            )
            metricTile(
                "Tax impact",
                value: scenario.sampleTaxChange.currencyText,
                detail: "\(scenario.sampleTaxChangePer100K.currencyText) per $100K assessed value",
                icon: "house.and.flag.fill",
                tint: RiverheadTheme.brandSky
            )
            metricTile(
                "Ending reserves",
                value: String(format: "%.1f%%", scenario.endingReservePercent),
                detail: "\(scenario.endingReserveDollars.currencyText) after capital and one-time use",
                icon: "banknote.fill",
                tint: .green
            )
            metricTile(
                "Recurring coverage",
                value: String(format: "%.0f%%", scenario.recurringCoverageRatio * 100),
                detail: "Recurring offsets divided by recurring uses",
                icon: "gauge.with.dots.needle.67percent",
                tint: scenario.recurringCoverageRatio >= 1 ? .green : .red
            )
        }
    }

    private var scenarioBuilder: some View {
        VStack(alignment: .leading, spacing: 14) {
            LabCard(title: "Budget Trade-Off Sliders", subtitle: "These controls translate policy choices into recurring dollars.") {
                sliderRow("Levy growth", value: $levyGrowthPercent, range: 0...6, step: 0.25, suffix: "%", note: "Recurring property-tax support in the model.")
                sliderRow("Recurring savings", value: $recurringSavings, range: 0...1_500_000, step: 25_000, format: .currency, note: "Overtime, vacancy, refill discipline, healthcare, and procurement savings.")
                sliderRow("Other recurring revenue", value: $recurringRevenueAdds, range: 0...500_000, step: 10_000, format: .currency, note: "Fees, rentals, interest, and cost recovery that repeat.")
                sliderRow("Other operating pressure", value: $otherRecurringPressure, range: 0...2_500_000, step: 25_000, format: .currency, note: "Pension, insurance, utilities, or other baseline pressure.")
            }

            LabCard(title: "Service Choices", subtitle: "Toggle what the 2027 plan visibly funds.") {
                toggleRow("Building Department staffing", amount: Budget2027LabModel.buildingDepartmentInvestment, isOn: $buildingInvestment)
                toggleRow("Online platform modernization", amount: Budget2027LabModel.onlinePlatformCost, isOn: $platformInvestment)
                toggleRow("Town Clerk staffing", amount: Budget2027LabModel.deputyTownClerkCost, isOn: $clerkInvestment)
                stepperRow("Code Enforcement officers", value: $codeOfficers, amountPerUnit: Budget2027LabModel.codeOfficerCost)
                stepperRow("Police officers", value: $policeOfficers, amountPerUnit: Budget2027LabModel.policeOfficerCost)
                toggleRow("Supervisor + Town Board raise package", amount: Budget2027LabModel.electedRaisePackageCost, isOn: $electedRaisePackage)
            }

            LabCard(title: "Capital And Reserves", subtitle: "Separate one-time choices from recurring balance.") {
                toggleRow("Building / Code fleet purchase", amount: Budget2027LabModel.fleetPurchaseCost, isOn: $fleetPurchase)
                sliderRow("Reserve target", value: $reserveTargetPercent, range: 15...max(15, scenario.currentReservePercent), step: 0.5, suffix: "%", note: "Higher targets protect cushion but reduce deployable room.")
                sliderRow("One-time reserve use", value: $oneTimeUse, range: 0...max(0, scenario.deployableOneTimeRoom), step: 25_000, format: .currency, note: "Best used for one-time items, not recurring payroll.")
            }

            structuralMeter
        }
    }

    private var budgetAgent: some View {
        VStack(alignment: .leading, spacing: 14) {
            LabCard(title: "2027 Budget Agent", subtitle: "A compact planning agent turns the remembered labor actions, outlined service choices, and resident-added items into a draft budget package.") {
                VStack(alignment: .leading, spacing: 12) {
                    agentSummaryRow(
                        "Potential 2027 appropriation",
                        value: scenario.potentialAppropriation.currencyText,
                        detail: "Starts with the app's 2026 General Fund baseline and adds the modeled 2027 net spending package.",
                        icon: "doc.text.fill",
                        tint: RiverheadTheme.brandSky
                    )
                    agentSummaryRow(
                        "Recurring gap / surplus",
                        value: scenario.recurringBalance.currencyText,
                        detail: scenario.structuralStatus,
                        icon: scenario.recurringBalance >= 0 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                        tint: scenario.recurringBalance >= 0 ? .green : .orange
                    )
                    agentSummaryRow(
                        "Custom resident changes",
                        value: customItems.reduce(0) { $0 + $1.signedScenarioAmount }.currencyText,
                        detail: "\(customItems.count) added item(s) are included in this scenario.",
                        icon: "plus.forwardslash.minus",
                        tint: RiverheadTheme.brandTeal
                    )
                }
            }

            LabCard(title: "Agent Skill Card", subtitle: "Inspired by Perplexity's skill guidance: keep the routing small, keep heavy detail progressive, and track gotchas where the model is likely to mislead people.") {
                VStack(alignment: .leading, spacing: 10) {
                    skillLine("Load when", "A resident asks for a potential 2027 Town budget, contract impact, structural balance, or scenario trade-off.")
                    skillLine("Source order", "Use app baseline values first, then remembered contract actions, then outlined recommendations, then user-added items.")
                    skillLine("Gotcha", "Do not treat one-time reserve money as a recurring fix for payroll, benefits, or permanent staffing.")
                    skillLine("Eval question", "Can the draft explain what changed, what pays for it, and which assumptions still need official verification?")
                }
            }

            LabCard(title: "Draft Budget Package", subtitle: "The agent's current first-pass package, recomputed from the controls and custom additions.") {
                let recommendations = Budget2027AgentRecommendation.make(from: scenario)
                ForEach(recommendations.indices, id: \.self) { index in
                    let item = recommendations[index]
                    recommendationRow(item)
                    if index < recommendations.count - 1 {
                        Divider()
                    }
                }
            }

            customItemEditor
        }
    }

    private var taxImpact: some View {
        VStack(alignment: .leading, spacing: 14) {
            LabCard(title: "Personal Tax Impact", subtitle: "Estimate the Town portion of the change under this scenario.") {
                sliderRow("Assessed value", value: $assessment, range: 100_000...1_500_000, step: 25_000, format: .currency, note: "Use taxable assessed value for a tighter estimate.")

                LazyVGrid(columns: columns, spacing: 10) {
                    miniResult("Current Town estimate", value: scenario.currentTownTax.currencyText, tint: RiverheadTheme.brandSky)
                    miniResult("Annual change", value: scenario.sampleTaxChange.currencyText, tint: scenario.sampleTaxChange >= 0 ? .orange : .green)
                    miniResult("Monthly change", value: (scenario.sampleTaxChange / 12).currencyText, tint: RiverheadTheme.brandGold)
                    miniResult("Daily change", value: (scenario.sampleTaxChange / 365).currencyText, tint: RiverheadTheme.brandTeal)
                }
            }

            LabCard(title: "Scenario Comparison", subtitle: "The same home under three common public-budget postures.") {
                Chart(Budget2027LabPreset.allCases) { preset in
                    BarMark(
                        x: .value("Preset", preset.title),
                        y: .value("Tax change", taxChange(for: preset))
                    )
                    .foregroundStyle(preset.tint)
                    .annotation(position: .top) {
                        Text(taxChange(for: preset).currencyText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 210)
                .chartYAxisLabel("Annual change")
            }
        }
    }

    private var customItemEditor: some View {
        LabCard(title: "Add More Changes", subtitle: "Layer in another revenue, savings, recurring cost, or one-time item and the agent will include it immediately.") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Change type", selection: $draftItemKind) {
                    ForEach(Budget2027CustomItemKind.allCases) { kind in
                        Label(kind.title, systemImage: kind.icon).tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                TextField("Name the change", text: $draftItemTitle)
                    .textFieldStyle(.roundedBorder)

                TextField("Amount", value: $draftItemAmount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                TextField("Optional source or note", text: $draftItemNote, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)

                Button {
                    addCustomItem()
                } label: {
                    Label("Add to 2027 scenario", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(RiverheadTheme.brandSky)
                .disabled(draftItemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draftItemAmount <= 0)

                if customItems.isEmpty {
                    Text("No custom changes yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Divider()

                    ForEach(customItems) { item in
                        customItemRow(item)
                    }
                }
            }
        }
    }

    private var departmentImpacts: some View {
        VStack(alignment: .leading, spacing: 14) {
            LabCard(title: "Department Impact Lens", subtitle: "Each card ties 2027 choices to service meaning, risk, and questions.") {
                ForEach(Budget2027DepartmentImpact.make(from: scenario)) { item in
                    departmentCard(item)
                }
            }
        }
    }

    private var watchlist: some View {
        VStack(alignment: .leading, spacing: 14) {
            LabCard(title: "Budget Accuracy Scorecard", subtitle: "Use this before treating the 2027 baseline as realistic.") {
                ForEach(Budget2027WatchItem.items) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.icon)
                            .foregroundStyle(item.tint)
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                            Text(item.detail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(item.question)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RiverheadTheme.brandNavy)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if item.id != Budget2027WatchItem.items.last?.id {
                        Divider()
                    }
                }

                NavigationLink {
                    BudgetAccuracyWatchlistView()
                } label: {
                    Label("Open full accuracy watch list", systemImage: "exclamationmark.triangle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(RiverheadTheme.brandSky)
            }
        }
    }

    private var hearingMode: some View {
        VStack(alignment: .leading, spacing: 14) {
            LabCard(title: "Public Hearing Mode", subtitle: "Questions generated from the current scenario.") {
                ForEach(hearingQuestions.indices, id: \.self) { index in
                    Label {
                        Text(hearingQuestions[index])
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(RiverheadTheme.brandNavy))
                    }
                    .padding(.vertical, 3)
                }
            }

            LabCard(title: "Plain-English Talking Points", subtitle: "Short statements that help residents follow the trade-offs.") {
                ForEach(talkingPoints, id: \.self) { point in
                    Label(point, systemImage: "quote.bubble.fill")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                NavigationLink {
                    BudgetExplainersView()
                } label: {
                    Label("Open budget explainers", systemImage: "text.book.closed.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(RiverheadTheme.brandNavy)
            }
        }
    }

    private var sourceTrail: some View {
        VStack(alignment: .leading, spacing: 14) {
            LabCard(title: "Source Trail", subtitle: "Every major assumption should say where it came from and how firm it is.") {
                ForEach(Budget2027SourceTrail.sources) { source in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: source.icon)
                            .foregroundStyle(source.tint)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(source.title)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(source.confidence)
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(source.tint.opacity(0.16)))
                                    .foregroundStyle(source.tint)
                            }

                            Text(source.detail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if source.id != Budget2027SourceTrail.sources.last?.id {
                        Divider()
                    }
                }

                NavigationLink {
                    HistoricalTabView()
                } label: {
                    Label("Browse source documents", systemImage: "folder.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(RiverheadTheme.brandSky)
            }
        }
    }

    private var structuralMeter: some View {
        LabCard(title: "Structural Balance Meter", subtitle: "The key test: recurring costs should be paid with recurring offsets.") {
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: min(max(scenario.recurringCoverageRatio, 0), 1))
                    .tint(scenario.recurringCoverageRatio >= 1 ? .green : .orange)

                Text(scenario.structuralExplanation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    miniResult("Uses", value: scenario.totalRecurringUses.currencyText, tint: .red)
                    miniResult("Offsets", value: scenario.totalRecurringOffsets.currencyText, tint: .green)
                }
            }
        }
    }

    private var hearingQuestions: [String] {
        [
            "Which parts of this 2027 plan are recurring, and which parts rely on one-time reserve use?",
            "If the levy growth is \(String(format: "%.2f%%", levyGrowthPercent)), what services or savings are assumed to make the plan work?",
            "Does the budget show a tax-cap compliant baseline before any override discussion?",
            "What is the written rebuild plan if reserves are used above \(oneTimeUse.currencyText)?",
            "Which department additions are tied to measurable service outcomes, such as inspection speed, complaint resolution, or overtime reduction?",
            "Which 2025 or 2026 budget lines had actual spending patterns that should reset the 2027 baseline?"
        ]
    }

    private var talkingPoints: [String] {
        [
            "A balanced budget is stronger when recurring costs are covered by recurring revenue or recurring savings.",
            "Fund balance can smooth a year, but it should not quietly carry permanent payroll or benefits.",
            "The public deserves to see the service choice, the tax effect, and the source trail in the same place.",
            "A budget line that was repeatedly too low is not savings; it is a baseline problem."
        ]
    }

    private func metricTile(_ title: String, value: String, detail: String, icon: String, tint: Color) -> some View {
        LabCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(tint.opacity(0.14)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.title3.weight(.bold))
                        .minimumScaleFactor(0.72)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func sliderRow(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        suffix: String = "",
        format: SliderValueFormat = .number,
        note: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(format.text(value.wrappedValue, suffix: suffix))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RiverheadTheme.brandNavy)
            }

            Slider(value: value, in: range, step: step)
                .tint(RiverheadTheme.brandSky)

            Text(note)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func toggleRow(_ title: String, amount: Double, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(amount.currencyText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .toggleStyle(.switch)
    }

    private func stepperRow(_ title: String, value: Binding<Double>, amountPerUnit: Double) -> some View {
        Stepper(value: value, in: 0...6, step: 1) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(title): \(Int(value.wrappedValue))")
                    .font(.subheadline.weight(.semibold))
                Text((Double(Int(value.wrappedValue)) * amountPerUnit).currencyText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func miniResult(_ title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(tint.opacity(0.10)))
    }

    private func agentSummaryRow(_ title: String, value: String, detail: String, icon: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(Circle().fill(tint.opacity(0.12)))

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(value)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(tint)
                        .minimumScaleFactor(0.7)
                }

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func skillLine(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(RiverheadTheme.brandNavy)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func recommendationRow(_ item: Budget2027AgentRecommendation) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.icon)
                .foregroundStyle(item.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(item.amount.currencyText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(item.tint)
                }

                Text(item.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }

    private func customItemRow(_ item: Budget2027CustomItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.kind.icon)
                .foregroundStyle(item.kind.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(item.amount.currencyText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(item.kind.tint)
                }

                Text(item.kind.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button {
                customItems.removeAll { $0.id == item.id }
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.red)
            .accessibilityLabel("Remove \(item.title)")
        }
        .padding(.vertical, 6)
    }

    private func departmentCard(_ item: Budget2027DepartmentImpact) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: item.icon)
                    .foregroundStyle(item.tint)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(item.name)
                            .font(.headline)
                        Spacer()
                        Text(item.amount.currencyText)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(item.tint)
                    }

                    Text(item.meaning)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(item.question)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.brandNavy)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(item.tint.opacity(0.09)))
    }

    private func labBadge(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.white.opacity(0.18)))
    }

    private func taxChange(for preset: Budget2027LabPreset) -> Double {
        let rate = store.ratePerThousand * (preset.levyGrowthPercent / 100)
        return (assessment / 1_000) * rate
    }

    private func applyPreset(_ preset: Budget2027LabPreset) {
        levyGrowthPercent = preset.levyGrowthPercent
        recurringSavings = preset.recurringSavings
        recurringRevenueAdds = preset.recurringRevenueAdds
        otherRecurringPressure = preset.otherRecurringPressure
        reserveTargetPercent = preset.reserveTargetPercent
        buildingInvestment = preset.buildingInvestment
        platformInvestment = preset.platformInvestment
        clerkInvestment = preset.clerkInvestment
        codeOfficers = Double(preset.codeOfficers)
        policeOfficers = Double(preset.policeOfficers)
        fleetPurchase = preset.fleetPurchase
        electedRaisePackage = preset.electedRaisePackage
        oneTimeUse = 0
    }

    private func addCustomItem() {
        let cleanTitle = draftItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNote = draftItemNote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty, draftItemAmount > 0 else { return }

        customItems.append(
            Budget2027CustomItem(
                title: cleanTitle,
                amount: draftItemAmount,
                kind: draftItemKind,
                note: cleanNote
            )
        )

        draftItemTitle = ""
        draftItemAmount = 0
        draftItemNote = ""
    }
}

private struct LabCard<Content: View, Background: ShapeStyle>: View {
    @Environment(\.colorScheme) private var scheme

    let title: String?
    let subtitle: String?
    let content: Content
    let background: Background

    init(
        title: String? = nil,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content,
        background: () -> Background = { RiverheadTheme.Surface.elevated }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
        self.background = background()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if title != nil || subtitle != nil {
                VStack(alignment: .leading, spacing: 4) {
                    if let title {
                        Text(title)
                            .font(.headline)
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(background))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RiverheadTheme.softBorder, lineWidth: 1)
        )
        .shadow(color: RiverheadTheme.cardShadow(scheme), radius: 10, x: 0, y: 5)
    }
}

private enum Budget2027LabPanel: String, CaseIterable, Identifiable {
    case agent
    case scenario
    case taxes
    case departments
    case watchlist
    case hearing
    case sources

    var id: String { rawValue }

    var title: String {
        switch self {
        case .agent: return "Agent"
        case .scenario: return "Scenario"
        case .taxes: return "Taxes"
        case .departments: return "Departments"
        case .watchlist: return "Watchlist"
        case .hearing: return "Hearing"
        case .sources: return "Sources"
        }
    }

    var icon: String {
        switch self {
        case .agent: return "sparkles"
        case .scenario: return "slider.horizontal.3"
        case .taxes: return "house.and.flag.fill"
        case .departments: return "building.2.fill"
        case .watchlist: return "exclamationmark.triangle.fill"
        case .hearing: return "person.2.wave.2.fill"
        case .sources: return "doc.text.magnifyingglass"
        }
    }
}

private enum Budget2027LabPreset: String, CaseIterable, Identifiable {
    case taxCap
    case bestPlan
    case serviceBuildout

    var id: String { rawValue }

    var title: String {
        switch self {
        case .taxCap: return "Tax-cap"
        case .bestPlan: return "Best plan"
        case .serviceBuildout: return "Buildout"
        }
    }

    var detail: String {
        switch self {
        case .taxCap:
            return "Keeps levy growth near 2%, trims expansion, and asks savings to do more work."
        case .bestPlan:
            return "Carries core service investments while protecting recurring balance and reserves."
        case .serviceBuildout:
            return "Shows the fuller cost of staffing and service expansion before offsets catch up."
        }
    }

    var tint: Color {
        switch self {
        case .taxCap: return .green
        case .bestPlan: return RiverheadTheme.brandSky
        case .serviceBuildout: return .orange
        }
    }

    var levyGrowthPercent: Double {
        switch self {
        case .taxCap: return 2.0
        case .bestPlan: return 3.0
        case .serviceBuildout: return 4.5
        }
    }

    var recurringSavings: Double {
        switch self {
        case .taxCap: return 1_100_000
        case .bestPlan: return Budget2027LabModel.defaultRecurringSavings
        case .serviceBuildout: return 650_000
        }
    }

    var recurringRevenueAdds: Double {
        switch self {
        case .taxCap: return 140_000
        case .bestPlan: return Budget2027LabModel.defaultRecurringRevenueAdds
        case .serviceBuildout: return 90_000
        }
    }

    var otherRecurringPressure: Double {
        switch self {
        case .taxCap: return Budget2027LabModel.defaultOtherRecurringPressure
        case .bestPlan: return Budget2027LabModel.defaultOtherRecurringPressure
        case .serviceBuildout: return 1_550_000
        }
    }

    var reserveTargetPercent: Double {
        switch self {
        case .taxCap: return 30
        case .bestPlan: return Budget2027LabModel.defaultReserveTargetPercent
        case .serviceBuildout: return 24
        }
    }

    var buildingInvestment: Bool { self != .taxCap }
    var platformInvestment: Bool { true }
    var clerkInvestment: Bool { self != .taxCap }
    var codeOfficers: Int { self == .serviceBuildout ? 3 : (self == .taxCap ? 1 : 2) }
    var policeOfficers: Int { self == .serviceBuildout ? 3 : (self == .taxCap ? 1 : 2) }
    var fleetPurchase: Bool { self != .taxCap }
    var electedRaisePackage: Bool { self == .serviceBuildout }
}

private enum SliderValueFormat {
    case number
    case currency

    func text(_ value: Double, suffix: String = "") -> String {
        switch self {
        case .number:
            return String(format: "%.2f%@", value, suffix)
        case .currency:
            return value.currencyText
        }
    }
}

private enum Budget2027LabModel {
    static let defaultLevyGrowthPercent = 3.0
    static let defaultRecurringSavings = Budget2027TaxCapOffsetModel.recurringSavingsPackageTotal
    static let defaultRecurringRevenueAdds = Budget2027TaxCapOffsetModel.recurringRevenueAdds
    static let defaultOtherRecurringPressure = Budget2027PensionPressureModel.midpointIncrease
    static let defaultReserveTargetPercent = 28.8
    static let cseaPressure = Budget2027ScenarioModel.modeledCSEAIncrease
    static let pbaSOANonContractPressure = Budget2027ScenarioModel.modeledPBAIncreaseAtDefaultCOLA
        + Budget2027ScenarioModel.modeledSOAIncreaseAtDefaultCOLA
        + Budget2027ScenarioModel.modeledNonContractIncreaseAtDefaultCOLA
    static let buildingDepartmentInvestment = Budget2027ScenarioModel.buildingDepartmentHeadcountInvestment
    static let onlinePlatformCost = Budget2027ScenarioModel.onlinePlatformUpdateCost
    static let deputyTownClerkCost = Budget2027ScenarioModel.deputyTownClerkCost
    static let codeOfficerCost = Budget2027ScenarioModel.codeEnforcementOfficerCost
    static let policeOfficerCost = Budget2027ScenarioModel.policeOfficerCost
    static let electedRaisePackageCost = Budget2027ScenarioModel.electedRaisePackageCost
    static let fleetPurchaseCost = Budget2027ScenarioModel.plannedFleetPurchaseCost
}

private enum Budget2027CustomItemKind: String, CaseIterable, Identifiable {
    case recurringCost
    case recurringSavings
    case recurringRevenue
    case oneTimeCost

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recurringCost: return "Recurring cost"
        case .recurringSavings: return "Recurring savings"
        case .recurringRevenue: return "Recurring revenue"
        case .oneTimeCost: return "One-time cost"
        }
    }

    var icon: String {
        switch self {
        case .recurringCost: return "arrow.up.right.circle.fill"
        case .recurringSavings: return "scissors.circle.fill"
        case .recurringRevenue: return "plus.forwardslash.minus"
        case .oneTimeCost: return "calendar.badge.clock"
        }
    }

    var tint: Color {
        switch self {
        case .recurringCost: return .red
        case .recurringSavings: return .green
        case .recurringRevenue: return RiverheadTheme.brandSky
        case .oneTimeCost: return .orange
        }
    }
}

private struct Budget2027CustomItem: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var amount: Double
    var kind: Budget2027CustomItemKind
    var note: String

    var signedScenarioAmount: Double {
        switch kind {
        case .recurringCost, .oneTimeCost:
            return amount
        case .recurringSavings, .recurringRevenue:
            return -amount
        }
    }

    static let seeded: [Budget2027CustomItem] = [
        .init(
            title: "Monthly overtime review and refill discipline",
            amount: 250_000,
            kind: .recurringSavings,
            note: "Suggested recurring management control; should be verified against department actuals."
        ),
        .init(
            title: "Reset conservative recurring revenue lines",
            amount: 100_000,
            kind: .recurringRevenue,
            note: "Use recent actuals for repeatable fees, interest, rentals, and cost recovery."
        )
    ]
}

private struct Budget2027AgentRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let amount: Double
    let detail: String
    let icon: String
    let tint: Color

    @MainActor
    static func make(from scenario: Budget2027LabScenario) -> [Budget2027AgentRecommendation] {
        [
            .init(
                title: "Remembered contract pressure",
                amount: scenario.automaticPayrollPressure,
                detail: "Carries CSEA's 2027 approved +2.5% plus $1,000 action, plus public-safety and non-contract fallback growth for planning.",
                icon: "person.3.sequence.fill",
                tint: .red
            ),
            .init(
                title: "Outlined service investments",
                amount: scenario.serviceInvestmentTotal,
                detail: "Includes selected Building, Code, Police, Town Clerk, technology, and elected-pay choices.",
                icon: "building.2.fill",
                tint: RiverheadTheme.brandTeal
            ),
            .init(
                title: "Other operating pressure",
                amount: scenario.otherRecurringPressure,
                detail: "Keeps pension, insurance, utilities, and other baseline pressure visible instead of hiding it in one line.",
                icon: "gauge.with.dots.needle.67percent",
                tint: .orange
            ),
            .init(
                title: "Recurring offsets",
                amount: scenario.totalRecurringOffsets,
                detail: "Uses the selected levy growth, recurring revenue adds, recurring savings, and custom resident-added offsets.",
                icon: "arrow.down.right.circle.fill",
                tint: .green
            ),
            .init(
                title: "Capital and one-time package",
                amount: scenario.capitalTotal,
                detail: "Keeps fleet and other one-time items separate from the recurring structural-balance test.",
                icon: "car.side.fill",
                tint: RiverheadTheme.brandSky
            ),
            .init(
                title: "Agent verdict",
                amount: scenario.recurringBalance,
                detail: scenario.structuralExplanation,
                icon: scenario.recurringBalance >= 0 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                tint: scenario.recurringBalance >= 0 ? .green : .red
            )
        ]
    }
}

@MainActor
private struct Budget2027LabScenario {
    let store: RBBudgetStore
    let levyGrowthPercent: Double
    let recurringSavings: Double
    let recurringRevenueAdds: Double
    let otherRecurringPressure: Double
    let reserveTargetPercent: Double
    let oneTimeUse: Double
    let assessment: Double
    let buildingInvestment: Bool
    let platformInvestment: Bool
    let clerkInvestment: Bool
    let codeOfficers: Int
    let policeOfficers: Int
    let fleetPurchase: Bool
    let electedRaisePackage: Bool
    let customItems: [Budget2027CustomItem]

    var currentLevyEstimate: Double { store.appropriations * 0.703 }
    var levyYield: Double { currentLevyEstimate * (levyGrowthPercent / 100) }
    var automaticPayrollPressure: Double { Budget2027LabModel.cseaPressure + Budget2027LabModel.pbaSOANonContractPressure }

    var serviceInvestmentTotal: Double {
        var total = 0.0
        if buildingInvestment { total += Budget2027LabModel.buildingDepartmentInvestment }
        if platformInvestment { total += Budget2027LabModel.onlinePlatformCost }
        if clerkInvestment { total += Budget2027LabModel.deputyTownClerkCost }
        total += Double(codeOfficers) * Budget2027LabModel.codeOfficerCost
        total += Double(policeOfficers) * Budget2027LabModel.policeOfficerCost
        if electedRaisePackage { total += Budget2027LabModel.electedRaisePackageCost }
        return total
    }

    var capitalTotal: Double {
        (fleetPurchase ? Budget2027LabModel.fleetPurchaseCost : 0) + customOneTimeCosts
    }

    var customRecurringCosts: Double {
        customItems
            .filter { $0.kind == .recurringCost }
            .map(\.amount)
            .reduce(0, +)
    }

    var customRecurringSavings: Double {
        customItems
            .filter { $0.kind == .recurringSavings }
            .map(\.amount)
            .reduce(0, +)
    }

    var customRecurringRevenue: Double {
        customItems
            .filter { $0.kind == .recurringRevenue }
            .map(\.amount)
            .reduce(0, +)
    }

    var customOneTimeCosts: Double {
        customItems
            .filter { $0.kind == .oneTimeCost }
            .map(\.amount)
            .reduce(0, +)
    }

    var totalRecurringUses: Double {
        automaticPayrollPressure + otherRecurringPressure + serviceInvestmentTotal + customRecurringCosts
    }

    var totalRecurringOffsets: Double {
        levyYield + recurringSavings + recurringRevenueAdds + customRecurringSavings + customRecurringRevenue
    }

    var recurringBalance: Double {
        totalRecurringOffsets - totalRecurringUses
    }

    var recurringCoverageRatio: Double {
        guard totalRecurringUses > 0 else { return 1 }
        return totalRecurringOffsets / totalRecurringUses
    }

    var currentReservePercent: Double {
        guard store.appropriations > 0 else { return 0 }
        return (store.estimatedFundBalance / store.appropriations) * 100
    }

    var targetReserveDollars: Double {
        store.appropriations * (reserveTargetPercent / 100)
    }

    var availableOneTimeRoom: Double {
        max(store.estimatedFundBalance - targetReserveDollars, 0)
    }

    var deployableOneTimeRoom: Double {
        max(availableOneTimeRoom - capitalTotal, 0)
    }

    var appliedOneTimeUse: Double {
        min(oneTimeUse, deployableOneTimeRoom)
    }

    var endingReserveDollars: Double {
        max(store.estimatedFundBalance - capitalTotal - appliedOneTimeUse, 0)
    }

    var endingReservePercent: Double {
        guard store.appropriations > 0 else { return 0 }
        return (endingReserveDollars / store.appropriations) * 100
    }

    var currentTownTax: Double {
        (assessment / 1_000) * store.ratePerThousand
    }

    var sampleTaxChange: Double {
        let rateChange = store.ratePerThousand * (levyGrowthPercent / 100)
        return (assessment / 1_000) * rateChange
    }

    var sampleTaxChangePer100K: Double {
        guard assessment > 0 else { return 0 }
        return sampleTaxChange / (assessment / 100_000)
    }

    var netRecurringSpendingChange: Double {
        totalRecurringUses - recurringSavings - customRecurringSavings
    }

    var potentialAppropriation: Double {
        max(store.appropriations + netRecurringSpendingChange + capitalTotal, 0)
    }

    var structuralStatus: String {
        if recurringBalance >= 0 { return "Recurring plan covers recurring uses" }
        if recurringBalance > -250_000 { return "Close, but still structurally tight" }
        return "Recurring gap remains before one-time money"
    }

    var structuralExplanation: String {
        if recurringBalance >= 0 {
            return "This scenario passes the core structural test because recurring offsets cover recurring uses before reserves are touched."
        }
        return "This scenario still has a recurring gap of \(abs(recurringBalance).currencyText). One-time money can hide that for a year, but it does not fix the next budget."
    }
}

private struct Budget2027DepartmentImpact: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let meaning: String
    let question: String
    let icon: String
    let tint: Color

    static func make(from scenario: Budget2027LabScenario) -> [Budget2027DepartmentImpact] {
        [
            .init(
                name: "Building Department",
                amount: (scenario.buildingInvestment ? Budget2027LabModel.buildingDepartmentInvestment : 0) + (scenario.fleetPurchase ? Budget2027LabModel.fleetPurchaseCost / 2 : 0),
                meaning: "Adds staffing capacity and, if selected, two field vehicles for inspection-heavy work.",
                question: "What performance target improves: permit cycle time, inspection backlog, or complaint response?",
                icon: "hammer.fill",
                tint: RiverheadTheme.brandSky
            ),
            .init(
                name: "Code Enforcement",
                amount: Double(scenario.codeOfficers) * Budget2027LabModel.codeOfficerCost + (scenario.fleetPurchase ? Budget2027LabModel.fleetPurchaseCost / 2 : 0),
                meaning: "Shows the recurring cost of added officers separately from one-time vehicle support.",
                question: "Will new capacity be measured by cases closed, field coverage, or repeat-violation reduction?",
                icon: "checklist.checked",
                tint: RiverheadTheme.brandTeal
            ),
            .init(
                name: "Police",
                amount: Double(scenario.policeOfficers) * Budget2027LabModel.policeOfficerCost,
                meaning: "Carries new headcount while overtime and pension pressure remain separate budget tests.",
                question: "Does added staffing reduce overtime, improve coverage, or add service level without offset?",
                icon: "shield.lefthalf.filled",
                tint: .blue
            ),
            .init(
                name: "Town Clerk",
                amount: scenario.clerkInvestment ? Budget2027LabModel.deputyTownClerkCost : 0,
                meaning: "Tests one additional recurring position for resident-facing service volume.",
                question: "Which transaction or response-time metric proves the position is needed?",
                icon: "doc.on.doc.fill",
                tint: .purple
            ),
            .init(
                name: "Townwide Technology",
                amount: scenario.platformInvestment ? Budget2027LabModel.onlinePlatformCost : 0,
                meaning: "Funds modernization that should reduce friction for residents and staff workflows.",
                question: "Is this a one-year implementation cost, a recurring subscription, or both?",
                icon: "network",
                tint: RiverheadTheme.brandGold
            ),
            .init(
                name: "Town Board / Supervisor",
                amount: scenario.electedRaisePackage ? Budget2027LabModel.electedRaisePackageCost : 0,
                meaning: "Keeps discretionary elected-pay decisions visible instead of burying them in payroll growth.",
                question: "Should this be voted and explained separately from contractual workforce pressure?",
                icon: "person.crop.rectangle.stack.fill",
                tint: .orange
            )
        ]
    }
}

private struct Budget2027WatchItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let question: String
    let icon: String
    let tint: Color

    static let items: [Budget2027WatchItem] = [
        .init(
            title: "Police overtime baseline",
            detail: "The app's existing watchlist flags police uniform overtime as a recurring baseline issue, not just a one-year story.",
            question: "What is the 2027 overtime recovery plan and monthly reporting cadence?",
            icon: "clock.badge.exclamationmark.fill",
            tint: .orange
        ),
        .init(
            title: "Understated revenue risk",
            detail: "Interest and other revenues can make budgets look tighter than actual year-end results when recurring estimates are too conservative.",
            question: "Which revenue lines should be reset using recent actuals?",
            icon: "chart.line.uptrend.xyaxis",
            tint: .green
        ),
        .init(
            title: "One-time money carrying recurring cost",
            detail: "Reserve use can be responsible when matched to one-time costs. It becomes risky when it supports payroll or benefits.",
            question: "Which recurring costs remain after the one-time money disappears?",
            icon: "arrow.triangle.2.circlepath",
            tint: .red
        ),
        .init(
            title: "Capital-to-operating spillover",
            detail: "Vehicles, platforms, and facilities can add insurance, maintenance, subscription, and staffing costs after purchase.",
            question: "Where are the second-year operating costs shown?",
            icon: "car.side.fill",
            tint: RiverheadTheme.brandSky
        )
    ]
}

private struct Budget2027SourceTrail: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let confidence: String
    let icon: String
    let tint: Color

    static let sources: [Budget2027SourceTrail] = [
        .init(
            title: "2026 budget baseline",
            detail: "Uses the app's current 2026 appropriations, rate, and fund-balance store values as the starting point.",
            confidence: "High",
            icon: "doc.richtext.fill",
            tint: RiverheadTheme.brandSky
        ),
        .init(
            title: "Labor pressure",
            detail: "CSEA action, public safety fallback growth, and non-contract growth are modeled from the existing 2027 simulator assumptions.",
            confidence: "Medium",
            icon: "person.3.sequence.fill",
            tint: .orange
        ),
        .init(
            title: "Service investments",
            detail: "Building, code, police, clerk, technology, elected-pay, and fleet amounts mirror the existing planning assumptions in the simulator.",
            confidence: "Medium",
            icon: "building.2.fill",
            tint: RiverheadTheme.brandTeal
        ),
        .init(
            title: "Accuracy flags",
            detail: "Draws from the budget accuracy watchlist: overtime, revenue baselines, special consulting/event lines, and capital/operating classification questions.",
            confidence: "Review",
            icon: "exclamationmark.triangle.fill",
            tint: .red
        ),
        .init(
            title: "Tax impact",
            detail: "Illustrative estimate using the current app Town rate per $1,000 and the selected levy-growth percentage.",
            confidence: "Estimate",
            icon: "house.and.flag.fill",
            tint: .green
        )
    ]
}

private extension Double {
    var currencyText: String {
        formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

#Preview {
    NavigationStack {
        Budget2027LabView()
            .environment(RBBudgetStore())
    }
}
