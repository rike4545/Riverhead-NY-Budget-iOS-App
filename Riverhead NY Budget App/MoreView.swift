//
//  MoreView.swift
//  Riverhead NY Budget App
//
//  Improvements:
//  - Removes dependency on RiverheadURLs (uses official site links directly)
//  - Adds "News & Events" and "Taxes & Payments" entry points
//  - Keeps your existing visual style + cards
//
//  Swift 6 • iOS 17+
//

import SwiftUI

struct MoreView: View {
    @Environment(\.colorScheme) private var scheme

    // Official Riverhead site entry points
    private let servicesURL = URL(string: "https://www.townofriverheadny.gov/101/Services")!
    private let onlinePaymentsURL = URL(string: "https://www.townofriverheadny.gov/164/Online-Payments-Services")!
    private let departmentsURL = URL(string: "https://www.townofriverheadny.gov/31/Departments")!
    private let governmentURL = URL(string: "https://www.townofriverheadny.gov/27/Government")!
    private let quickLinksURL = URL(string: "https://www.townofriverheadny.gov/159/Quick-Links")!
    private let socialMediaURL = URL(string: "https://www.townofriverheadny.gov/246/Social-Media-Platforms-Live-Streams")!
    private let channel22URL = URL(string: "https://www.townofriverheadny.gov/462/Channel-22---Live-Streams-and-Video-Arch")!
    private let contactURL = URL(string: "https://www.townofriverheadny.gov/142/Contact")!
    private let calendarURL = URL(string: "https://www.townofriverheadny.gov/calendar.aspx")!
    private let newsFlashURL = URL(string: "https://www.townofriverheadny.gov/CivicAlerts.asp?CID=1")!
    private let financialReportsURL = URL(string: "https://www.townofriverheadny.gov/206/Financial-Reports")!
    private let receiverOfTaxesURL = URL(string: "https://www.townofriverheadny.gov/189/Receiver-of-Taxes")!
    private let receiverTaxArchiveURL = URL(string: "https://www.townofriverheadny.gov/Archive.aspx?AMID=37")!
    private let seeThroughNYURL = URL(string: "https://www.seethroughny.net/")!
    private let oscFinancialToolkitURL = URL(string: "https://www.osc.ny.gov/local-government/financial-toolkit")!
    private let townHallCommitteesURL = URL(string: "https://www.townofriverheadny.gov/240/Town-Hall-Committees")!
    private let downtownRevitalizationCommitteeURL = URL(string: "https://www.townofriverheadny.gov/261/Downtown-Revitalization-Committee")!
    private let sponsoredShopSimonURL = URL(string: "http://click.linksynergy.com/fs-bin/click?id=rG4d7/djvVM&offerid=1949172&type=3&subid=0")!
    private let sponsoredWisprURL = URL(string: "https://ref.wisprflow.ai/bryan-c")!
    private let sponsoredTryCentsURL = URL(string: "https://comfrt.com/KLAIRE11")!
    private let sponsoredTryCentsReferralCode = "KLAIRE11"
    private let sponsoredTeslaFiURL = URL(string: "https://comfrt.com/KLAIRE11")!
    private let sponsoredTeslaFiReferralCode = "KLAIRE11"
    private let appFeedbackURL = URL(string: "https://qualtricsxmm8q5gxrhq.qualtrics.com/jfe/form/SV_1TvkCrIKgaEYHPM")!

    private var discountSections: [DiscountOfferSection] {
        [
            DiscountOfferSection(
                title: "Shopping",
                subtitle: "Outlet and retail savings links that fit occasional resident use.",
                systemImage: "bag.fill",
                tint: .orange,
                offers: [
                    DiscountOffer(
                        title: "SHOP SIMON",
                        subtitle: "Formerly Shop Premium Outlets",
                        detail: "Outlet shopping offers and seasonal promo campaigns.",
                        url: sponsoredShopSimonURL,
                        badge: "Affiliate link"
                    )
                ]
            ),
            DiscountOfferSection(
                title: "Productivity",
                subtitle: "Low-friction software tools and writing helpers.",
                systemImage: "keyboard.fill",
                tint: RiverheadTheme.brandSky,
                offers: [
                    DiscountOffer(
                        title: "Wispr Flow",
                        subtitle: "Voice-to-text productivity tool",
                        detail: "Referral entry for a dictation-focused workflow app.",
                        url: sponsoredWisprURL,
                        badge: "Affiliate link"
                    )
                ]
            ),
            DiscountOfferSection(
                title: "Household Services",
                subtitle: "Offers tied to everyday convenience services.",
                systemImage: "house.fill",
                tint: RiverheadTheme.brandMint,
                offers: [
                    DiscountOffer(
                        title: "Personal laundry delivery",
                        subtitle: "Linked offer currently labeled in the app as a laundry referral",
                        detail: "Open the partner link and apply the code at checkout if eligible.",
                        url: sponsoredTryCentsURL,
                        badge: "Referral code",
                        code: sponsoredTryCentsReferralCode
                    )
                ]
            ),
            DiscountOfferSection(
                title: "Driving & EV",
                subtitle: "Auto-related referral entry currently included in the app.",
                systemImage: "car.fill",
                tint: RiverheadTheme.brandTeal,
                offers: [
                    DiscountOffer(
                        title: "TeslaFi",
                        subtitle: "Vehicle analytics and charging-history tracking",
                        detail: "Use the app's saved referral code when the destination supports it.",
                        url: sponsoredTeslaFiURL,
                        badge: "Referral code",
                        code: sponsoredTeslaFiReferralCode
                    )
                ]
            )
        ]
    }

    var body: some View {
        List {
            moreHeader
            startSection
            civicOversightSection
            budgetAnalysisSection
            officialTownLinksSection
            newsMediaSection
            contactSection
            discountsSection
            appFeedbackSection
            aboutSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .contentMargins(.bottom, 18, for: .scrollContent)
        .tint(RiverheadTheme.accent)
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.inline)
        .adMobBannerPlacement(showDebugPlaceholder: false)
    }

    // MARK: - Sections

    private var startSection: some View {
        Section("Start") {
            NavigationLink {
                CivicImprovementsHubView()
            } label: {
                Label("Civic Command Center", systemImage: "sparkle.magnifyingglass")
            }

            NavigationLink {
                StartHereView()
            } label: {
                Label("Start Here", systemImage: "arrow.triangle.branch")
            }

            NavigationLink {
                UniversalSearchView()
            } label: {
                Label("Search the App", systemImage: "magnifyingglass")
            }

            NavigationLink {
                SourceTrailView()
            } label: {
                Label("Source Trail", systemImage: "checkmark.seal")
            }

            NavigationLink {
                AskAIView()
            } label: {
                Label("Ask AI", systemImage: "sparkles")
            }

            NavigationLink {
                NewsAndEventsView()
            } label: {
                Label("News & Events", systemImage: "newspaper.fill")
            }

            NavigationLink {
                ECode360ScrapeView()
            } label: {
                Label("Town Code (eCode360)", systemImage: "doc.text.magnifyingglass")
            }
        }
    }

    private var civicOversightSection: some View {
        Section("Civic & Oversight") {
            NavigationLink {
                CouncilScorecardView()
            } label: {
                Label("Council Scorecard", systemImage: "checklist.checked")
            }

            NavigationLink {
                PluralityGovernanceView()
            } label: {
                Label("Plurality & Oversight", systemImage: "person.3.sequence.fill")
            }

            NavigationLink {
                RiverheadCommitteesView()
            } label: {
                Label("Committee Browser", systemImage: "person.3.sequence")
            }

            NavigationLink {
                ProcurementPolicyWatchView()
            } label: {
                Label("Procurement Watch", systemImage: "doc.text.magnifyingglass")
            }

            navCard(
                title: "Downtown Revitalization Committee",
                subtitle: "Official agendas, minutes, members, liaisons, and mission",
                icon: "building.columns.circle.fill",
                destination: WebContentView(url: downtownRevitalizationCommitteeURL, title: "Downtown Committee")
            )

            NavigationLink {
                RiverheadCampaignContributionsView()
            } label: {
                Label("Campaign Donation Ethics", systemImage: "checkmark.shield")
            }

            NavigationLink {
                LegalDefamationAnalysisView()
            } label: {
                Label("Defamation Risk Analysis", systemImage: "exclamationmark.bubble")
            }

            NavigationLink {
                ResidentActionToolkitView()
            } label: {
                Label("Resident Action Toolkit", systemImage: "person.line.dotted.person")
            }
        }
    }

    private var budgetAnalysisSection: some View {
        Section("Budget Analysis") {
            NavigationLink {
                BudgetScorecardView()
            } label: {
                Label("Budget Scorecard", systemImage: "gauge.with.dots.needle.67percent")
            }

            NavigationLink {
                BudgetSignalsView()
            } label: {
                Label("Budget Signals", systemImage: "waveform.path.ecg")
            }

            NavigationLink {
                BudgetExplainersView()
            } label: {
                Label("Plain-English Budget Explainers", systemImage: "text.book.closed.fill")
            }

            NavigationLink {
                RiverheadDebtSavingsView()
            } label: {
                Label("Debt Savings View", systemImage: "building.columns.circle.fill")
            }

            NavigationLink {
                BudgetDiffView()
            } label: {
                Label("What Changed?", systemImage: "arrow.left.arrow.right")
            }

            NavigationLink {
                BudgetPDFSearchView()
            } label: {
                Label("PDF Search", systemImage: "doc.text.magnifyingglass")
            }

            NavigationLink {
                SavedScenariosView()
            } label: {
                Label("Saved Scenarios", systemImage: "tray.full")
            }

            NavigationLink {
                SnowRemovalOverrunView()
            } label: {
                Label("Snow Budget Overrun", systemImage: "snowflake")
            }

            NavigationLink {
                ContractScheduleIncreaseView()
            } label: {
                Label("Contract Raise View", systemImage: "list.bullet.rectangle")
            }

            NavigationLink {
                DepartmentSpendForecastView()
            } label: {
                Label("Dept Spend Forecast", systemImage: "building.2.crop.circle")
            }

            NavigationLink {
                DepartmentExpenseExplorerView()
            } label: {
                Label("Department Expense Explorer", systemImage: "building.columns.circle")
            }

            NavigationLink {
                RebalancedSpendingView()
            } label: {
                Label("Rebalanced Spending", systemImage: "arrow.left.arrow.right.circle")
            }

            NavigationLink {
                BudgetAccuracyWatchlistView()
            } label: {
                Label("Budget Accuracy Watch List", systemImage: "exclamationmark.triangle")
            }

            NavigationLink {
                SalaryComparisonView()
            } label: {
                Label("Town Salary Comparison", systemImage: "dollarsign.square.fill")
            }

            NavigationLink {
                RetirementWaiversView()
            } label: {
                Label("Retirement Waivers (NY)", systemImage: "person.text.rectangle.fill")
            }
        }
    }

    private var moreHeader: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color.white.opacity(0.16), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Riverhead shortcuts")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Official links, local tools, scorecards, and app info in one place.")
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.82))
                    }
                }

                HStack(spacing: 8) {
                    headerPill("Town services", "building.2.fill")
                    headerPill("Budget", "chart.pie.fill")
                    headerPill("Media", "play.tv.fill")
                }
            }
            .padding(14)
            .background(RiverheadTheme.headerGradient)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: RiverheadTheme.cardShadow(scheme, elevated: true), radius: 14, x: 0, y: 8)
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 10, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }

    private var officialTownLinksSection: some View {
        Section("Official Town Links") {
            navCard(
                title: "Services",
                subtitle: "Forms, resources, community programs",
                icon: "wrench.and.screwdriver.fill",
                destination: WebContentView(url: servicesURL, title: "Services")
            )

            navCard(
                title: "Online Payments & Services",
                subtitle: "Pay fees, request records, report concerns",
                icon: "creditcard.fill",
                destination: WebContentView(url: onlinePaymentsURL, title: "Online Payments")
            )

            navCard(
                title: "Departments",
                subtitle: "Browse offices and districts",
                icon: "building.2.fill",
                destination: WebContentView(url: departmentsURL, title: "Departments")
            )

            navCard(
                title: "Government",
                subtitle: "Boards, meetings, elected officials",
                icon: "building.columns.fill",
                destination: WebContentView(url: governmentURL, title: "Government")
            )

            navCard(
                title: "Town Hall Committees",
                subtitle: "Official committee, board, council, forum, and task-force index",
                icon: "person.3.sequence.fill",
                destination: WebContentView(url: townHallCommitteesURL, title: "Town Hall Committees")
            )

            navCard(
                title: "Quick Links",
                subtitle: "Popular shortcuts from the Town site",
                icon: "link.circle.fill",
                destination: WebContentView(url: quickLinksURL, title: "Quick Links")
            )

            navCard(
                title: "Financial Reports",
                subtitle: "Official audits, AFR updates, CPF financials, and budget history",
                icon: "chart.bar.doc.horizontal.fill",
                destination: WebContentView(url: financialReportsURL, title: "Financial Reports")
            )

            navCard(
                title: "OSC Financial Toolkit",
                subtitle: "NYS Comptroller guidance for local-government fiscal health",
                icon: "checkmark.shield.fill",
                destination: WebContentView(url: oscFinancialToolkitURL, title: "OSC Financial Toolkit")
            )

            navCard(
                title: "SeeThroughNY",
                subtitle: "Public payroll, pensions, contracts, spending, and benchmarks",
                icon: "eye.fill",
                destination: WebContentView(url: seeThroughNYURL, title: "SeeThroughNY")
            )

            navCard(
                title: "Receiver of Taxes",
                subtitle: "Payment windows, FAQs, and office info",
                icon: "doc.text.fill",
                destination: WebContentView(url: receiverOfTaxesURL, title: "Receiver of Taxes")
            )

            navCard(
                title: "Tax Rate Archive",
                subtitle: "Official annual tax-rate PDFs from 2013-14 through 2025-26",
                icon: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                destination: WebContentView(url: receiverTaxArchiveURL, title: "Tax Rate Archive")
            )
        }
    }

    private var newsMediaSection: some View {
        Section("News & Media") {
            navCard(
                title: "News Flash",
                subtitle: "Official Town notices and alerts",
                icon: "megaphone.fill",
                destination: WebContentView(url: newsFlashURL, title: "News Flash")
            )

            navCard(
                title: "Calendar",
                subtitle: "Meetings and community events",
                icon: "calendar",
                destination: WebContentView(url: calendarURL, title: "Calendar")
            )

            NavigationLink {
                LocalNewsEconomyView()
            } label: {
                Label("Local News & Town Snapshot", systemImage: "newspaper.fill")
            }

            NavigationLink {
                FunnySidenoteView()
            } label: {
                Label("Funny Sidenote", systemImage: "play.rectangle.on.rectangle.fill")
            }

            navCard(
                title: "Channel 22",
                subtitle: "Live streams and video archives",
                icon: "play.tv.fill",
                destination: WebContentView(url: channel22URL, title: "Channel 22")
            )

            navCard(
                title: "Social Media",
                subtitle: "Official platforms and live-stream links",
                icon: "person.2.fill",
                destination: WebContentView(url: socialMediaURL, title: "Social Media")
            )

            NavigationLink {
                RoadsDashboardView()
            } label: {
                Label("Roads Dashboard", systemImage: "road.lanes")
            }
        }
    }

    private var contactSection: some View {
        Section("Contact") {
            navCard(
                title: "Contact Us",
                subtitle: "Town Hall address, phone, and directory",
                icon: "phone.fill",
                destination: WebContentView(url: contactURL, title: "Contact")
            )

            NavigationLink {
                ContactView()
            } label: {
                Label("In-App Contact Card", systemImage: "person.crop.circle.fill")
            }
        }
    }

    private var appFeedbackSection: some View {
        Section("App Feedback") {
            navCard(
                title: "App Feedback",
                subtitle: "Share feedback about this app",
                icon: "square.and.pencil",
                destination: WebContentView(url: appFeedbackURL, title: "App Feedback")
            )
        }
    }

    private var discountsSection: some View {
        Section("Savings & Offers") {
            NavigationLink {
                DiscountsHubView(sections: discountSections)
            } label: {
                Label("Discounts & Offers", systemImage: "tag.circle.fill")
            }

            Text("Organized by category so referral codes, partner links, and app-support offers stay easy to review or remove later.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            NavigationLink {
                AboutAppView()
            } label: {
                Label("About This App", systemImage: "info.circle")
            }
        }
    }

    // MARK: - Components

    @ViewBuilder
    private func navCard<Destination: View>(
        title: String,
        subtitle: String,
        icon: String,
        destination: Destination
    ) -> some View {
        let tint = RiverheadTheme.townAccent(for: title)

        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 34, height: 34, alignment: .center)
                    .foregroundStyle(tint)
                    .background(tint.opacity(scheme == .dark ? 0.22 : 0.13), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(RiverheadTheme.textPrimary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(tint.opacity(0.7))
            }
            .padding(.vertical, 10)
        }
    }

    private func headerPill(_ text: String, _ icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.16), in: Capsule())
            .foregroundStyle(Color.white.opacity(0.92))
    }
}

private struct DiscountOfferSection: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let offers: [DiscountOffer]
}

private struct DiscountOffer: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let detail: String
    let url: URL
    let badge: String
    let code: String?

    init(
        title: String,
        subtitle: String,
        detail: String,
        url: URL,
        badge: String,
        code: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.detail = detail
        self.url = url
        self.badge = badge
        self.code = code
    }
}

private struct DiscountsHubView: View {
    @Environment(\.colorScheme) private var scheme

    let sections: [DiscountOfferSection]

    var body: some View {
        List {
            introSection

            ForEach(sections) { section in
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: section.systemImage)
                                .font(.headline)
                                .foregroundStyle(section.tint)
                                .frame(width: 34, height: 34)
                                .background(section.tint.opacity(scheme == .dark ? 0.24 : 0.12), in: Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(section.title)
                                    .font(.headline)
                                    .foregroundStyle(RiverheadTheme.textPrimary)
                                Text(section.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        ForEach(section.offers) { offer in
                            Link(destination: offer.url) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(offer.title)
                                            .font(.headline)
                                            .foregroundStyle(RiverheadTheme.textPrimary)
                                        Spacer()
                                        Text(offer.badge)
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(section.tint.opacity(scheme == .dark ? 0.26 : 0.14), in: Capsule())
                                            .foregroundStyle(section.tint)
                                    }

                                    Text(offer.subtitle)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.secondary)

                                    Text(offer.detail)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)

                                    if let code = offer.code {
                                        Label("Code: \(code)", systemImage: "number.square.fill")
                                            .font(.footnote.weight(.semibold))
                                            .foregroundStyle(section.tint)
                                    }
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RiverheadTheme.Surface.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(RiverheadTheme.softBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }

            Section {
                Label("These links support the app, but they sit in one optional place rather than throughout the product.", systemImage: "info.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Label("Always confirm final pricing and any code eligibility on the destination site before using an offer.", systemImage: "checkmark.shield.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Discounts & Offers")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var introSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("A lightweight place for savings links, referral codes, and partner offers that are already part of the app.")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.88))

                HStack(spacing: 8) {
                    introPill("Affiliate links", icon: "link")
                    introPill("Referral codes", icon: "tag.fill")
                    introPill("Grouped by category", icon: "square.grid.2x2.fill")
                }
            }
            .padding(16)
            .background(RiverheadTheme.headerGradient)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }

    private func introPill(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.16), in: Capsule())
            .foregroundStyle(Color.white.opacity(0.94))
    }
}
