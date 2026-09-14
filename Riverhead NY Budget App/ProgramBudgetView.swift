//
//  ProgramBudgetView.swift
//  Riverhead NY Budget App
//
//  What the Town does, and what it costs. A budget organised by fund answers an
//  accountant's question; this one answers a resident's — the same 2026 adopted
//  dollars, regrouped into the seven services New York's Uniform System of
//  Accounts says the Town performs, with pension and health insurance pushed
//  back onto the programs whose staff earned them.
//
//  Every figure comes from bundled programs.json, published by the web app's
//  ETL as a contract for the native clients. This file formats and explains; it
//  does not compute a single allocation, which is what keeps the three editions
//  from disagreeing about what Police costs.
//
//  Swift 6 / iOS 17+
//

import SwiftUI

// MARK: - Formatting

enum ProgramBudgetFormat {
    /// Whole dollars, grouped.
    static func usd(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    /// Steps down through M / K / plain dollars so a small real number reads as
    /// itself. Health's benefit share is $1,958 — rendering everything in
    /// millions turns that into "$0.00M", which looks like a bug rather than a
    /// small number. Same rule as the web edition, on purpose.
    static func compactUSD(_ value: Double) -> String {
        let magnitude = abs(value)
        if magnitude >= 1_000_000 {
            let millions = value / 1_000_000
            return magnitude < 10_000_000
                ? String(format: "$%.2fM", millions)
                : String(format: "$%.1fM", millions)
        }
        if magnitude >= 10_000 {
            let thousands = Int((value / 1_000).rounded())
            return "$\(thousands.formatted())K"
        }
        return usd(value)
    }

    static func percent(_ value: Double, digits: Int = 0) -> String {
        digits == 0
            ? String(format: "%.0f%%", value)
            : String(format: "%.1f%%", value)
    }

    /// SwiftUI's Text(_:) applies locale-aware grouping to interpolated numeric
    /// values, so a year has to reach it as a plain string or 2026 renders as
    /// "2,026".
    static func year(_ value: Int) -> String { String(value) }

    /// One hue per program, held stable so a service reads as the same colour on
    /// the overview bar and on its own screen.
    static func tone(for key: String) -> Color {
        switch key {
        case "3": return RiverheadTheme.brandSky
        case "8": return RiverheadTheme.brandTeal
        case "1": return RiverheadTheme.brandNavy
        case "5": return RiverheadTheme.brandGold
        case "7": return RiverheadTheme.brandMint
        case "4": return RiverheadTheme.brandSand
        default:  return RiverheadTheme.brandBlue
        }
    }
}

// MARK: - Shared chrome

private struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let title: String?
    let subtitle: String?
    @ViewBuilder var content: Content

    init(title: String? = nil, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
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
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

/// One headline number with its label and a line of context under it.
private struct ProgramStatTile: View {
    let label: String
    let value: String
    var note: String?
    var valueColor: Color = RiverheadTheme.textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.caption2.weight(.heavy))
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(valueColor)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            if let note {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RiverheadTheme.Surface.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// How much of a service the people who use it pay for, and how much everyone
/// else does. Both ends are labelled because either number alone misleads.
private struct CostRecoveryMeter: View {
    let recoveryPct: Double
    let tone: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ProgressView(value: min(max(recoveryPct, 0), 100), total: 100)
                .progressViewStyle(.linear)
                .tint(tone)
            HStack(alignment: .firstTextBaseline) {
                Text("\(ProgramBudgetFormat.percent(recoveryPct)) paid by the people who use it")
                Spacer(minLength: 8)
                Text("\(ProgramBudgetFormat.percent(max(0, 100 - recoveryPct))) carried by taxes")
            }
            .font(.caption2)
            .foregroundStyle(RiverheadTheme.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Cost recovery \(ProgramBudgetFormat.percent(recoveryPct)) from fees")
    }
}

// MARK: - Overview

struct ProgramBudgetView: View {
    private let budget = ProgramBudgetData.current

    private let tileColumns = [GridItem(.adaptive(minimum: 148), spacing: 10)]

    var body: some View {
        ZStack {
            RiverheadTheme.backgroundGradient.ignoresSafeArea()

            if let budget {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        introCard(budget)
                        headlineCard(budget)
                        programsCard(budget)
                        scaleCard(budget)
                        limitsCard(budget)
                        methodCard(budget)
                        sourcesFooter(budget)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            } else {
                ContentUnavailableView(
                    "Program budget unavailable",
                    systemImage: "chart.pie",
                    description: Text("The bundled program-budget extract could not be read.")
                )
            }
        }
        .navigationTitle("Program Budget")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Intro

    private func introCard(_ budget: ProgramBudget) -> some View {
        GlassCard(
            title: "What the Town does, and what it costs",
            subtitle: "The \(budget.source.title) regrouped into services rather than funds — full cost including pension and health insurance, fees earned back, and what each service leaves for the tax levy."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("A budget organised by fund answers an accountant's question. This one reorganises the same dollars by what the Town does with them — and the classification isn't ours. New York's Uniform System of Accounts already assigns every municipal dollar to a function, and Riverhead codes to it on both the spending and the revenue side. The Town's own coding was regrouped; nothing was reclassified.")
                    .font(.subheadline)
                    .foregroundStyle(RiverheadTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider().opacity(0.25)

                definitionRow("Full cost", "Not just the department line. Pension and health insurance are pushed back onto the programs whose staff earned them, so Police costs what Police actually costs.")
                definitionRow("Earns back", "Fees paid by the people who use the service — permits, water bills, beach passes. Not taxes.")
                definitionRow("Not covered by fees", "What property and sales taxes, mortgage tax, PILOTs and state aid have to carry. A costly service with high recovery can ask less of you than a cheap one that charges nobody.")

                reconciliationLine(budget.reconciliation)

                // The data files sync independently of the Swift that reads
                // them, so the contract version is worth checking out loud.
                if ProgramBudgetData.isNewerThanApp {
                    Label {
                        Text("This extract was generated against a newer version of the shared data contract (schema \(ProgramBudgetFormat.year(budget.schemaVersion))) than this app build understands (schema \(ProgramBudgetFormat.year(ProgramBudgetData.supportedSchemaVersion))). Anything it added is not shown here.")
                            .font(.caption)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(RiverheadTheme.brandGold)
                    }
                }
            }
        }
    }

    private func definitionRow(_ term: String, _ meaning: String) -> some View {
        (Text("\(term). ").font(.caption.weight(.bold)).foregroundColor(RiverheadTheme.brandNavy)
            + Text(meaning).font(.caption).foregroundColor(RiverheadTheme.textSecondary))
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Rearranging a budget is where a tool like this can mislead without
    /// meaning to, so the arithmetic check is on screen rather than assumed.
    private func reconciliationLine(_ reconciliation: ProgramBudgetReconciliation) -> some View {
        let balances = reconciliation.balances
        let symbol = balances ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
        let tint = balances ? RiverheadTheme.brandMint : RiverheadTheme.brandCoral
        let text = balances
            ? "Programs + debt service + contingency + interfund transfers reconcile to the dollar against \(ProgramBudgetFormat.usd(reconciliation.appropriations)) of total adopted appropriations."
            : "The regrouping is off by \(ProgramBudgetFormat.usd(reconciliation.variance)) against total adopted appropriations."

        return Label {
            Text(text)
                .font(.caption)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: symbol).foregroundStyle(tint)
        }
    }

    // MARK: Headline numbers

    private func headlineCard(_ budget: ProgramBudget) -> some View {
        let totals = budget.totals
        return GlassCard(title: "The whole picture") {
            LazyVGrid(columns: tileColumns, spacing: 10) {
                ProgramStatTile(
                    label: "Cost of services",
                    value: ProgramBudgetFormat.compactUSD(totals.fullCost),
                    note: "\(budget.programs.count) programs · \(totals.staff.formatted()) staff"
                )
                ProgramStatTile(
                    label: "Earned back in fees",
                    value: ProgramBudgetFormat.compactUSD(totals.earned),
                    note: "\(ProgramBudgetFormat.percent(totals.recoveryPct)) recovery",
                    valueColor: RiverheadTheme.brandTeal
                )
                ProgramStatTile(
                    label: "Not covered by fees",
                    value: ProgramBudgetFormat.compactUSD(totals.net),
                    note: "carried by taxes and general revenue",
                    valueColor: RiverheadTheme.accent
                )
                ProgramStatTile(
                    label: "Per resident, services",
                    value: ProgramBudgetFormat.usd(budget.perResident.programs),
                    note: "\(budget.census.population.formatted()) residents"
                )
                ProgramStatTile(
                    label: "Per household, all in",
                    value: ProgramBudgetFormat.usd(budget.perHousehold.everything),
                    note: "\(ProgramBudgetFormat.percent(budget.perHousehold.shareOfMedianIncome, digits: 1)) of median income",
                    valueColor: RiverheadTheme.brandGold
                )
                ProgramStatTile(
                    label: "Debt service",
                    value: ProgramBudgetFormat.compactUSD(totals.debtService),
                    note: "outside the programs above"
                )
            }
        }
    }

    // MARK: Programs

    private func programsCard(_ budget: ProgramBudget) -> some View {
        GlassCard(
            title: "What each service costs, once benefits are counted",
            subtitle: "Full cost — the department's own appropriation plus the pension, health insurance and payroll taxes for the people who deliver it. Tap a service for what it buys, what it charges for, and where the money sits."
        ) {
            VStack(spacing: 0) {
                ForEach(budget.programs) { program in
                    NavigationLink {
                        ProgramBudgetDetailView(program: program, budget: budget)
                    } label: {
                        programRow(program, largest: largestFullCost(budget))
                    }
                    .buttonStyle(.plain)

                    if program.id != budget.programs.last?.id {
                        Divider().opacity(0.2).padding(.vertical, 8)
                    }
                }
            }
        }
    }

    private func largestFullCost(_ budget: ProgramBudget) -> Double {
        max(budget.programs.map(\.fullCost).max() ?? 1, 1)
    }

    private func programRow(_ program: ProgramBudgetProgram, largest: Double) -> some View {
        let tone = ProgramBudgetFormat.tone(for: program.key)
        return VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(program.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                Spacer(minLength: 8)
                Text(ProgramBudgetFormat.compactUSD(program.fullCost))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(tone)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(RiverheadTheme.textSecondary)
            }

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(RiverheadTheme.Surface.card)
                    .frame(height: 8)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(tone)
                            .frame(width: geo.size.width * (program.fullCost / largest), height: 8)
                    }
            }
            .frame(height: 8)

            Text(rowCaption(program))
                .font(.caption2)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(program.name), \(ProgramBudgetFormat.compactUSD(program.fullCost)) full cost")
    }

    /// Kept out of the view body so the type-checker never has to reason about
    /// a chain of interpolations and ternaries inside a Text.
    private func rowCaption(_ program: ProgramBudgetProgram) -> String {
        var parts = [
            "earns \(ProgramBudgetFormat.percent(program.recoveryPct)) back",
            "\(ProgramBudgetFormat.usd(program.netPerResident)) per resident after fees",
        ]
        if program.staff > 0 {
            parts.append("\(program.staff.formatted()) staff")
        } else {
            parts.append("no Town staff")
        }
        return parts.joined(separator: " · ")
    }

    // MARK: Scale, not a bill

    private func scaleCard(_ budget: ProgramBudget) -> some View {
        GlassCard(
            title: "What it costs per person, and per household",
            subtitle: "Riverhead has \(budget.census.population.formatted()) residents in \(budget.census.households.formatted()) households, median household income \(ProgramBudgetFormat.usd(Double(budget.census.medianHouseholdIncome)))."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: tileColumns, spacing: 10) {
                    ProgramStatTile(
                        label: "Services, per resident",
                        value: ProgramBudgetFormat.usd(budget.perResident.programs)
                    )
                    ProgramStatTile(
                        label: "Services, per household",
                        value: ProgramBudgetFormat.usd(budget.perHousehold.programs),
                        valueColor: RiverheadTheme.accent
                    )
                    ProgramStatTile(
                        label: "Debt service, per household",
                        value: ProgramBudgetFormat.usd(budget.perHousehold.debtService)
                    )
                    ProgramStatTile(
                        label: "All in, per household",
                        value: ProgramBudgetFormat.usd(budget.perHousehold.everything),
                        note: "\(ProgramBudgetFormat.percent(budget.perHousehold.shareOfMedianIncome, digits: 1)) of median household income",
                        valueColor: RiverheadTheme.brandGold
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Label("This is not your tax bill", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(RiverheadTheme.brandCoral)
                    Text("Commercial and industrial property carries a large share of the levy, fees carry another, and some of this cost never touches a household directly. What you actually owe depends on your assessment — work that out in My Taxes.")
                        .font(.caption)
                        .foregroundStyle(RiverheadTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(RiverheadTheme.brandCoral.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text("Source: \(budget.census.source.title) — \(budget.census.dataset). The household count carries a margin of error of ±\(budget.census.householdsMoe.formatted()), so treat per-household figures as approximate.")
                    .font(.caption2)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: The honest limit

    private func limitsCard(_ budget: ProgramBudget) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(budget.notCovered.title, systemImage: "questionmark.circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RiverheadTheme.brandNavy)
            Text(budget.notCovered.body)
                .font(.footnote)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RiverheadTheme.brandGold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: Method

    private func methodCard(_ budget: ProgramBudget) -> some View {
        GlassCard(
            title: "How this was built",
            subtitle: "Rearranging a budget is exactly where a transparency tool can mislead without meaning to, so every decision that moved a dollar is written down."
        ) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(budget.method) { note in
                    DisclosureGroup {
                        Text(note.body)
                            .font(.caption)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                    } label: {
                        Text(note.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .tint(RiverheadTheme.accent)
                }

                if !budget.diagnostics.unmappedPayrollDepartments.isEmpty {
                    Divider().opacity(0.25).padding(.vertical, 4)
                    Text("Unmapped payroll departments: \(budget.diagnostics.unmappedPayrollDepartments.joined(separator: ", ")). Their headcount is not counted in any program above.")
                        .font(.caption2)
                        .foregroundStyle(RiverheadTheme.brandCoral)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: Sources

    private func sourcesFooter(_ budget: ProgramBudget) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Source: \(budget.source.title). \(budget.source.detail ?? "")")
                .font(.caption2)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let url = budget.source.link {
                Link("Open the adopted budget ↗", destination: url)
                    .font(.caption2.weight(.bold))
            }

            Text("Staff counts are the \(ProgramBudgetFormat.year(budget.payrollYear)) payroll. Figures are regrouped from the Town's own account-level detail by the shared ETL that also feeds the web edition, so the two cannot disagree.")
                .font(.caption2)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - One service

struct ProgramBudgetDetailView: View {
    let program: ProgramBudgetProgram
    let budget: ProgramBudget

    private let tileColumns = [GridItem(.adaptive(minimum: 140), spacing: 10)]

    private var tone: Color { ProgramBudgetFormat.tone(for: program.key) }

    var body: some View {
        ZStack {
            RiverheadTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summaryCard
                    narrativeCard
                    buysCard
                    departmentsCard
                    revenuesCard
                    footnote
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryCard: some View {
        GlassCard(
            title: program.plain,
            subtitle: "\(program.functionLabel) · \(program.departments.count) departments"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: tileColumns, spacing: 10) {
                    ProgramStatTile(
                        label: "Full cost",
                        value: ProgramBudgetFormat.compactUSD(program.fullCost),
                        note: "\(ProgramBudgetFormat.compactUSD(program.direct)) + \(ProgramBudgetFormat.compactUSD(program.benefits)) benefits",
                        valueColor: tone
                    )
                    ProgramStatTile(
                        label: "Earns back",
                        value: ProgramBudgetFormat.compactUSD(program.earned),
                        note: "\(ProgramBudgetFormat.percent(program.recoveryPct)) of cost",
                        valueColor: RiverheadTheme.brandTeal
                    )
                    ProgramStatTile(
                        label: "Not covered by fees",
                        value: ProgramBudgetFormat.compactUSD(program.net),
                        valueColor: RiverheadTheme.accent
                    )
                    ProgramStatTile(
                        label: "Per resident",
                        value: ProgramBudgetFormat.usd(program.netPerResident),
                        note: "after fees"
                    )
                    ProgramStatTile(
                        label: "Per household",
                        value: ProgramBudgetFormat.usd(program.netPerHousehold),
                        note: "after fees"
                    )
                    ProgramStatTile(
                        label: "Staff",
                        value: program.staff > 0 ? program.staff.formatted() : "—",
                        note: program.staff > 0
                            ? "\(ProgramBudgetFormat.year(budget.payrollYear)) headcount"
                            : "no Town payroll coded here"
                    )
                }

                CostRecoveryMeter(recoveryPct: program.recoveryPct, tone: tone)
            }
        }
    }

    private var narrativeCard: some View {
        GlassCard(title: "What this actually is") {
            Text(program.narrative)
                .font(.subheadline)
                .foregroundStyle(RiverheadTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var buysCard: some View {
        GlassCard(title: "What it buys") {
            VStack(alignment: .leading, spacing: 6) {
                // Indexed rather than keyed on the string: a repeated line would
                // silently collapse into one bullet under `id: \.self`.
                ForEach(Array(program.buys.enumerated()), id: \.offset) { _, item in
                    Label {
                        Text(item)
                            .font(.caption)
                            .foregroundStyle(RiverheadTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 5))
                            .foregroundStyle(tone)
                    }
                }
            }
        }
    }

    private var departmentsCard: some View {
        GlassCard(
            title: "Biggest pieces",
            subtitle: "The Town's own departments and account codes, largest first."
        ) {
            VStack(spacing: 6) {
                ForEach(program.departments.prefix(8)) { department in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(department.name)
                                .font(.caption)
                                .foregroundStyle(RiverheadTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("\(department.fund) \(department.code)")
                                .font(.caption2)
                                .foregroundStyle(RiverheadTheme.textSecondary)
                        }
                        Spacer(minLength: 8)
                        Text(ProgramBudgetFormat.compactUSD(department.amount))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.textPrimary)
                    }
                }

                if program.departments.count > 8 {
                    Text("…and \(program.departments.count - 8) more departments")
                        .font(.caption2)
                        .foregroundStyle(RiverheadTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var revenuesCard: some View {
        GlassCard(
            title: program.topRevenues.isEmpty ? "It charges for nothing" : "What it charges for",
            subtitle: program.topRevenues.isEmpty
                ? nil
                : "Revenue the Town codes to this function group — fees paid by the people who use the service."
        ) {
            if program.topRevenues.isEmpty {
                Text("No fee revenue is coded to this function, so the tax levy carries all of it.")
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 6) {
                    // Riverhead runs two sewer districts, and both of their
                    // revenue lines are called "Sewer Rents". Keyed on the name,
                    // ForEach would render one and quietly drop $839,757 of the
                    // other — so these are keyed on position instead.
                    ForEach(Array(program.topRevenues.enumerated()), id: \.offset) { _, revenue in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(revenue.name)
                                .font(.caption)
                                .foregroundStyle(RiverheadTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Text(ProgramBudgetFormat.compactUSD(revenue.amount))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RiverheadTheme.brandTeal)
                        }
                    }
                }
            }
        }
    }

    private var footnote: some View {
        Text("Source: \(budget.source.title). Benefits are allocated by the Town's own uniformed/non-uniformed account split, not by an estimate made here. Per-resident and per-household figures are the scale of this service against the people in the Town — not a bill.")
            .font(.caption2)
            .foregroundStyle(RiverheadTheme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
