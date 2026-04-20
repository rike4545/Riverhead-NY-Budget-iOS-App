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
            // Branded gradient card tuned for dark + light
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(RiverheadTheme.headerGradient)
                .overlay(
                    // Stronger overlay so type is readable in both modes
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            scheme == .dark
                            ? Color.black.opacity(0.55)
                            : Color.black.opacity(0.22)
                        )
                )
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
                        .foregroundStyle(RiverheadTheme.brandSky)

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
            color: .black.opacity(scheme == .dark ? 0.6 : 0.25),
            radius: 18,
            x: 0,
            y: 10
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
            sectionHeader(title: "Town Budget Tools", icon: "chart.pie.fill")

            Text("Explore the Town budget, estimate your property tax bill, and see policy context based on the Town’s **2026 Adopted Budget**. These tools are for education and orientation, not for issuing official bills.")
                .font(.footnote)
                .foregroundStyle(secondaryText)
                .fixedSize(horizontal: false, vertical: true)

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
                    title: "Budget Overview",
                    subtitle: "Town-wide 2026 Adopted Budget snapshot and key trends.",
                    systemImage: "chart.pie.fill",
                    accentOverride: RiverheadTheme.brandSky
                ) {
                    BudgetOverviewShiftView()
                }

                internalFullWidthCard(
                    title: "My Taxes",
                    subtitle: "Estimate your Town property tax with a simple receipt.",
                    systemImage: "doc.text.magnifyingglass",
                    accentOverride: RiverheadTheme.brandTeal
                ) {
                    MyTaxesView()
                }

                internalFullWidthCard(
                    title: "2027 Budget Simulator",
                    subtitle: "Test levy, reserve, savings, and investment scenarios interactively.",
                    systemImage: "slider.horizontal.3",
                    accentOverride: RiverheadTheme.brandGold
                ) {
                    BudgetSimulator2027View()
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
        }
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

Always confirm with:
• Your actual tax bill and receipts  
• The Town’s adopted budget documents  
• The official Town website and staff
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
            ? Color.white.opacity(0.08)
            : Color.white.opacity(0.72)
        }

        return scheme == .dark
        ? Color(white: 0.12)           // dark tiles in dark mode
        : Color.white                  // white tiles in light mode
    }

    private var cardBorder: Color {
        if isPadLayout {
            return scheme == .dark
            ? Color.white.opacity(0.20)
            : Color.white.opacity(0.65)
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
        let shadowOpacity = scheme == .dark ? 0.45 : 0.10

        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(accentColor)
                .frame(width: 32, height: 32)
                .padding(8)
                .background(
                    Circle()
                        .fill(iconCircleFill)
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
        }
        .padding(14)
        .frame(minHeight: prominent ? (isPadLayout ? 84 : 88) : (isPadLayout ? 96 : 108), alignment: .topLeading)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(cardBorder, lineWidth: 1)
        )
        .shadow(
            color: .black.opacity(shadowOpacity),
            radius: prominent ? 10 : 7,
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
