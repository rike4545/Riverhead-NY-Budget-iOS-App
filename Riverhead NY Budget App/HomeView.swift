//
//  HomeView.swift
//  Riverhead NY Budget App
//
//  Resident-facing home screen for the combined civic + budget app.
//  - Color system aligned with the official Town of Riverhead website
//  - Quick links: Channel 22, News & Events, Departments, Code Enforcement
//  - Budget tools: Overview, My Taxes, Expert (2026 Adopted Budget context)
//  - Strong “unofficial helper” messaging
//

import SwiftUI

@MainActor
struct HomeView: View {
    @Environment(\.openURL) private var openURL
    @Environment(RBBudgetStore.self) private var store
    @Environment(\.colorScheme) private var scheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isPadLayout: Bool { horizontalSizeClass == .regular }

    // MARK: - External URLs

    private let townWebsiteURL = URL(string: "https://www.townofriverheadny.gov/")!

    // Channel 22 – Live Streams & Video Archives (correct URL)
    private let channel22URL = URL(
        string: "https://www.townofriverheadny.gov/462/Channel-22---Live-Streams-and-Video-Arch"
    )!

    private let codeEnforcementURL = URL(
        string: "https://www.townofriverheadny.gov/FormCenter/Code-Enforcement-10/Online-Code-Enforcement-Violation-Compla-53"
    )!

    // MARK: - Body

    var body: some View {
        ZStack {
            pageBackground
                .ignoresSafeArea()

            ScrollView {
                if isPadLayout {
                    VStack(spacing: 20) {
                        heroHeader

                        HStack(alignment: .top, spacing: 16) {
                            VStack(spacing: 16) {
                                dataStatusSection
                                quickLinksSection
                            }
                            .frame(maxWidth: .infinity, alignment: .top)

                            VStack(spacing: 16) {
                                budgetSection
                                infoSection
                                disclaimerSection
                            }
                            .frame(maxWidth: .infinity, alignment: .top)
                        }
                    }
                    .frame(maxWidth: 1120)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                } else {
                    LazyVStack(spacing: 20) {
                        heroHeader
                        dataStatusSection
                        quickLinksSection
                        budgetSection
                        infoSection
                        disclaimerSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
        }
    }

    // MARK: - Hero

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(RiverheadTheme.headerGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            scheme == .dark
                            ? Color.black.opacity(0.48)
                            : Color.black.opacity(0.16)
                        )
                )
                .overlay(alignment: .topTrailing) {
                    VStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { row in
                            HStack(spacing: 8) {
                                ForEach(0..<4, id: \.self) { column in
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(Color.white.opacity((row + column).isMultiple(of: 2) ? 0.18 : 0.08))
                                        .frame(width: 24, height: 8)
                                }
                            }
                        }
                    }
                    .padding(18)
                    .accessibilityHidden(true)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(RiverheadTheme.softBorder.opacity(0.95), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 10) {
                Text("Riverhead NY")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.white)

                Text("Unofficial civic & budget companion for Town residents.")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.95))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(RiverheadTheme.brandGold)

                    Text("Not an official Town app. Always verify with the Town website and adopted budget.")
                        .font(.footnote)
                        .foregroundStyle(Color.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundStyle(RiverheadTheme.brandGold)

                    Text("Start fast: services, taxes, and clear budget facts in one place.")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
        }
        .accessibilityElement(children: .contain)
        .shadow(
            color: RiverheadTheme.cardShadow(scheme, elevated: true),
            radius: 22,
            x: 0,
            y: 12
        )
    }

    
    // MARK: - Data Status

    private var dataStatusSection: some View {
        let docs = store.documents
        let fundCount = store.funds.count
        let years = docs.map(\.year)
        let minYear = years.min()
        let maxYear = years.max()

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Data Status", icon: "checkmark.seal.fill")

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: docs.isEmpty ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundStyle(docs.isEmpty ? Color.orange : Color.green)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(docs.isEmpty ? "Budget documents not loaded yet" : "\(docs.count) budget documents available")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(primaryText)

                        if let minYear, let maxYear, !docs.isEmpty {
                            Text("Coverage: \(minYear)–\(maxYear)")
                                .font(.footnote)
                                .foregroundStyle(secondaryText)
                        } else if docs.isEmpty {
                            Text("If this persists, confirm the documents list is seeded in RBBudgetStore.")
                                .font(.footnote)
                                .foregroundStyle(secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer()
                }

                if !docs.isEmpty {
                    Label(
                        fundCount == 0
                        ? "Fund summaries are still loading in the background."
                        : "\(fundCount) fund summaries ready for charts and drill-downs.",
                        systemImage: fundCount == 0 ? "clock.badge" : "chart.xyaxis.line"
                    )
                    .font(.footnote)
                    .foregroundStyle(secondaryText)
                }

                sourceConfidenceRow

                NavigationLink {
                    HistoricalTabView()
                } label: {
                    Label("Browse Budget History", systemImage: "clock.arrow.circlepath")
                        .font(.footnote.weight(.medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .tint(RiverheadTheme.accent)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(cardBorder, lineWidth: 1)
            )
            .shadow(
                color: .black.opacity(scheme == .dark ? 0.35 : 0.07),
                radius: 8,
                x: 0,
                y: 3
            )
        }
    }

// MARK: - Town Services

    private var quickLinksSection: some View {
        let columns = [GridItem(.adaptive(minimum: horizontalSizeClass == .compact ? 280 : 220), spacing: 12)]

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Town Services", icon: "building.2.fill")

            LazyVGrid(columns: columns, spacing: 12) {
                externalQuickCard(
                    title: "Watch\nChannel 22",
                    subtitle: "Town meetings & shows.",
                    systemImage: "tv.fill",
                    accentOverride: RiverheadTheme.brandNavy
                ) {
                    openURL(channel22URL)
                }

                internalQuickCard(
                    title: "News & Events",
                    subtitle: "Hearings, meetings, notices.",
                    systemImage: "megaphone.fill"
                ) {
                    NewsAndEventsView()
                }

                internalQuickCard(
                    title: "Departments",
                    subtitle: "Find the right office or contact.",
                    systemImage: "list.bullet.rectangle.portrait"
                ) {
                    DepartmentsView()
                }

                internalQuickCard(
                    title: "Contact Town Hall",
                    subtitle: "Addresses and phone numbers.",
                    systemImage: "phone.fill"
                ) {
                    ContactView()
                }

                externalFullWidthCard(
                    title: "Report a Code Concern",
                    subtitle: "File a complaint directly with Code Enforcement.",
                    systemImage: "exclamationmark.bubble.fill",
                    accentOverride: RiverheadTheme.brandSky
                ) {
                    openURL(codeEnforcementURL)
                }
            }
        }
    }

    // MARK: - Budget Tools

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Start With Your Goal", icon: "figure.walk.motion")

            Text("Choose the path that matches what you are trying to do. The deeper tools are still here, but residents should not have to know the app map before getting an answer.")
                .font(.footnote)
                .foregroundStyle(secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                internalFullWidthCard(
                    title: "Translate budget words into pictures",
                    subtitle: "Whiteboard-style explainers for levy, reserves, fund balance, debt, and recurring costs.",
                    systemImage: "rectangle.on.rectangle.angled",
                    accentOverride: RiverheadTheme.brandMint
                ) {
                    BudgetExplainersView()
                }

                internalFullWidthCard(
                    title: "What does this mean for my tax bill?",
                    subtitle: "Estimate the Town portion, see a simple receipt, and understand what drives the number.",
                    systemImage: "house.and.flag.fill",
                    accentOverride: RiverheadTheme.brandTeal
                ) {
                    MyTaxesView()
                }

                internalFullWidthCard(
                    title: "Where is the money going?",
                    subtitle: "Start with the budget hub for spending, reserves, debt, payroll, and source documents.",
                    systemImage: "chart.pie.fill",
                    accentOverride: RiverheadTheme.brandSky
                ) {
                    RiverheadBudgetHubView()
                }

                internalFullWidthCard(
                    title: "What should I ask at a meeting?",
                    subtitle: "Turn budget signals into plain-language hearing questions and follow-up checks.",
                    systemImage: "person.wave.2.fill",
                    accentOverride: RiverheadTheme.brandGold
                ) {
                    Budget2027LabView()
                }
            }

            budgetSnapshotCard
            moreBudgetToolsDisclosure
        }
    }

    private var budgetSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.seal.text.page.fill")
                    .font(.title3)
                    .foregroundStyle(RiverheadTheme.brandMint)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(scheme == .dark ? Color.white.opacity(0.08) : Color.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Know what kind of number you are seeing")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(primaryText)

                    Text("This app mixes official documents, extracted tables, and local modeling. Treat modeled values as decision support, then verify final figures with the Town source.")
                        .font(.footnote)
                        .foregroundStyle(secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    sourceBadge("Official docs", icon: "building.columns.fill", tint: RiverheadTheme.brandNavy)
                    sourceBadge("Extracted data", icon: "tablecells.fill", tint: RiverheadTheme.brandSky)
                    sourceBadge("App model", icon: "function", tint: RiverheadTheme.brandGold)
                }

                VStack(alignment: .leading, spacing: 8) {
                    sourceBadge("Official docs", icon: "building.columns.fill", tint: RiverheadTheme.brandNavy)
                    sourceBadge("Extracted data", icon: "tablecells.fill", tint: RiverheadTheme.brandSky)
                    sourceBadge("App model", icon: "function", tint: RiverheadTheme.brandGold)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(cardBorder, lineWidth: 1)
        )
        .shadow(
            color: RiverheadTheme.cardShadow(scheme),
            radius: 8,
            x: 0,
            y: 3
        )
    }

    private var moreBudgetToolsDisclosure: some View {
        DisclosureGroup {
            VStack(spacing: 10) {
                internalFullWidthCard(
                    title: "Ask AI",
                    subtitle: "Get plain-English help with budget questions and hearing prep.",
                    systemImage: "sparkles.rectangle.stack.fill",
                    accentOverride: RiverheadTheme.brandGold
                ) {
                    AskAIView()
                }

                internalFullWidthCard(
                    title: "Budget Signals",
                    subtitle: "See funds and departments that deserve a closer look.",
                    systemImage: "waveform.path.ecg.rectangle",
                    accentOverride: RiverheadTheme.brandCoral
                ) {
                    BudgetSignalsView()
                }

                internalFullWidthCard(
                    title: "Off-Balance Liabilities",
                    subtitle: "Review hidden or delayed costs that can become budget pressure.",
                    systemImage: "exclamationmark.triangle.fill",
                    accentOverride: RiverheadTheme.brandGold
                ) {
                    OffBalanceLiabilitiesView()
                }

                internalFullWidthCard(
                    title: "Procurement Watch",
                    subtitle: "Check professional-service, sole-source, and master developer exceptions.",
                    systemImage: "doc.text.magnifyingglass",
                    accentOverride: RiverheadTheme.brandCoral
                ) {
                    ProcurementPolicyWatchView()
                }

                internalFullWidthCard(
                    title: "Budget Overview",
                    subtitle: "Town-wide 2026 Adopted Budget snapshot and key trends.",
                    systemImage: "chart.pie.fill",
                    accentOverride: RiverheadTheme.brandSky
                ) {
                    BudgetOverviewShiftView()
                }

                internalFullWidthCard(
                    title: "Budget Supplement Explorer",
                    subtitle: "See the 2026 supplement as changes, request gaps, and 2027 scenario prompts.",
                    systemImage: "doc.text.magnifyingglass",
                    accentOverride: RiverheadTheme.brandMint
                ) {
                    BudgetSupplementExplorerView()
                }

                internalFullWidthCard(
                    title: "2027 Executive Summary",
                    subtitle: "A simpler whiteboard view of the potential 2027 budget story.",
                    systemImage: "pencil.and.outline",
                    accentOverride: RiverheadTheme.brandNavy
                ) {
                    Budget2027ExecutiveWhiteboardView()
                }

                internalFullWidthCard(
                    title: "Expert View",
                    subtitle: "Optional deeper context when you want more detail.",
                    systemImage: "brain.head.profile",
                    accentOverride: RiverheadTheme.brandNavy
                ) {
                    ExpertTabView()
                }
            }
            .padding(.top, 8)
        } label: {
            Label("More budget tools", systemImage: "wrench.and.screwdriver.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(primaryText)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(cardBorder, lineWidth: 1)
        )
        .tint(RiverheadTheme.accent)
        .shadow(
            color: RiverheadTheme.cardShadow(scheme),
            radius: 8,
            x: 0,
            y: 3
        )
    }

    // MARK: - Official Resources

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Official Resources", icon: "link")

            VStack(alignment: .leading, spacing: 8) {
                Text("Town of Riverhead Website")
                    .font(.headline)
                    .foregroundStyle(primaryText)

                Text("When in doubt, check the official website for adopted budgets, legal notices, calendars, and forms.")
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    openURL(townWebsiteURL)
                } label: {
                    Label("Open townofriverheadny.gov", systemImage: "safari")
                        .font(.footnote.weight(.medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(RiverheadTheme.accent)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(cardBorder, lineWidth: 1)
            )
            .shadow(
                color: .black.opacity(scheme == .dark ? 0.4 : 0.08),
                radius: 10,
                x: 0,
                y: 4
            )
        }
    }

    // MARK: - Disclaimer

    private var disclaimerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Important")
                .font(.caption.bold())
                .foregroundStyle(RiverheadTheme.gold)

            Text("""
This app is a **community-built, unofficial helper**. It does not issue bills, collect payments, or record official filings. Do not rely on it for legal deadlines or final dollar amounts.

Use it to share, analyze, and compare public data from governmental entities throughout New York, especially the Town of Riverhead. The information comes from official government sources and public transparency resources, but the developer cannot guarantee data accuracy or completeness.

Always confirm with:
• Your actual tax bill and receipts  
• The Town’s adopted budget documents  
• The original agency source or responsible government office
""")
            .font(.caption)
            .foregroundStyle(secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(cardBorder, lineWidth: 1)
        )
        .shadow(
            color: .black.opacity(scheme == .dark ? 0.4 : 0.06),
            radius: 8,
            x: 0,
            y: 3
        )
    }

    // MARK: - Shared Helpers (scheme-aware colors)

    @ViewBuilder
    private var pageBackground: some View {
        if isPadLayout {
            ZStack {
                LinearGradient(
                    colors: scheme == .dark
                    ? [
                        Color(red: 0.06, green: 0.09, blue: 0.12),
                        Color(red: 0.10, green: 0.14, blue: 0.18),
                        Color(red: 0.16, green: 0.13, blue: 0.10)
                    ]
                    : [
                        Color(red: 0.50, green: 0.63, blue: 0.75),
                        Color(red: 0.71, green: 0.80, blue: 0.86),
                        Color(red: 0.88, green: 0.84, blue: 0.75)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        Color.white.opacity(scheme == .dark ? 0.05 : 0.18),
                        .clear
                    ],
                    center: .top,
                    startRadius: 30,
                    endRadius: 700
                )
            }
        } else {
            ZStack {
                RiverheadTheme.backgroundGradient

                LinearGradient(
                    colors: [
                        RiverheadTheme.brandNavy.opacity(scheme == .dark ? 0.22 : 0.14),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    private var primaryText: Color {
        scheme == .dark ? Color(white: 0.97) : Color(white: 0.08)
    }

    private var secondaryText: Color {
        scheme == .dark ? Color(white: 0.82) : Color(white: 0.35)
    }

    private var cardFill: Color {
        if isPadLayout {
            return scheme == .dark
            ? Color.white.opacity(0.10)
            : Color.white.opacity(0.82)
        }

        return scheme == .dark
        ? Color(white: 0.12)           // dark tiles in dark mode
            : RiverheadTheme.Surface.elevated
    }

    private var cardBorder: Color {
        if isPadLayout {
            return scheme == .dark
            ? Color.white.opacity(0.22)
            : Color.white.opacity(0.72)
        }

        return scheme == .dark
        ? Color.white.opacity(0.16)
        : RiverheadTheme.softBorder.opacity(0.6)
    }

    private var iconCircleFillDark: Color {
        Color.white.opacity(0.09)
    }

    private var iconCircleFillLight: Color {
        Color.white
    }

    private func cardGradient(accent: Color, prominent: Bool) -> LinearGradient {
        LinearGradient(
            colors: [
                cardFill,
                accent.opacity(scheme == .dark ? (prominent ? 0.18 : 0.12) : (prominent ? 0.12 : 0.07)),
                RiverheadTheme.brandGold.opacity(scheme == .dark ? 0.05 : 0.035)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(RiverheadTheme.accent)
            Text(title)
                .font(.headline)
                .foregroundStyle(primaryText)
            Spacer()
        }
    }

    private var sourceConfidenceRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                sourceBadge("Official links", icon: "link.badge.plus", tint: RiverheadTheme.brandNavy)
                sourceBadge("Local cache", icon: "externaldrive.fill", tint: RiverheadTheme.brandMint)
            }

            VStack(alignment: .leading, spacing: 8) {
                sourceBadge("Official links", icon: "link.badge.plus", tint: RiverheadTheme.brandNavy)
                sourceBadge("Local cache", icon: "externaldrive.fill", tint: RiverheadTheme.brandMint)
            }
        }
    }

    private func sourceBadge(_ title: String, icon: String, tint: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(primaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(tint.opacity(scheme == .dark ? 0.18 : 0.12))
            )
            .overlay(
                Capsule()
                    .strokeBorder(tint.opacity(scheme == .dark ? 0.36 : 0.22), lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(title)
    }

    /// Internal navigation card (half-width)
    private func internalQuickCard<Destination: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        accentOverride: Color? = nil,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            cardContents(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage,
                prominent: false,
                accentOverride: accentOverride
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    /// External action card (half-width)
    private func externalQuickCard(
        title: String,
        subtitle: String,
        systemImage: String,
        accentOverride: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            cardContents(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage,
                prominent: false,
                accentOverride: accentOverride
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    /// Internal navigation card (full-width)
    private func internalFullWidthCard<Destination: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        accentOverride: Color? = nil,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            cardContents(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage,
                prominent: true,
                accentOverride: accentOverride
            )
        }
        .buttonStyle(.plain)
    }

    /// External action card (full-width)
    private func externalFullWidthCard(
        title: String,
        subtitle: String,
        systemImage: String,
        accentOverride: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            cardContents(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage,
                prominent: true,
                accentOverride: accentOverride
            )
        }
        .buttonStyle(.plain)
    }

    /// Shared card layout
    private func cardContents(
        title: String,
        subtitle: String,
        systemImage: String,
        prominent: Bool,
        accentOverride: Color?
    ) -> some View {
        let accentColor = accentOverride ?? (prominent ? RiverheadTheme.accent : secondaryText)
        let iconCircleFill = scheme == .dark ? iconCircleFillDark : iconCircleFillLight

        return HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(accentColor.opacity(prominent ? 0.95 : 0.55))
                .frame(width: 4)
                .padding(.vertical, 2)

            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .padding(8)
                .background(
                    Circle()
                        .fill(iconCircleFill)
                        .shadow(color: accentColor.opacity(scheme == .dark ? 0.18 : 0.12), radius: 8, x: 0, y: 4)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryText)
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(secondaryText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(accentColor.opacity(0.7))
                .padding(.top, 8)
        }
        .padding(14)
        .frame(minHeight: prominent ? (isPadLayout ? 84 : 88) : (isPadLayout ? 96 : 108), alignment: .topLeading)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardGradient(accent: accentColor, prominent: prominent))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(cardBorder, lineWidth: 1)
        )
        .shadow(
            color: RiverheadTheme.cardShadow(scheme, elevated: prominent),
            radius: prominent ? 12 : 8,
            x: 0,
            y: prominent ? 6 : 4
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeView()
            .preferredColorScheme(.dark)
    }
}
