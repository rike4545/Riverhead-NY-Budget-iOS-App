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
    private let sponsoredShopSimonURL = URL(string: "http://click.linksynergy.com/fs-bin/click?id=rG4d7/djvVM&offerid=1949172&type=3&subid=0")!
    private let sponsoredWisprURL = URL(string: "https://ref.wisprflow.ai/bryan-c")!
    private let sponsoredTryCentsURL = URL(string: "https://app.trycents.com/refer/OWFh/36bfb9c6")!
    private let appFeedbackURL = URL(string: "https://qualtricsxmm8q5gxrhq.qualtrics.com/jfe/form/SV_1TvkCrIKgaEYHPM")!

    var body: some View {
        NavigationStack {
            List {
                quickAccessSection
                townServicesSection
                councilScorecardSection
                insightsSection
                newsAndEventsSection
                taxesAndPaymentsSection
                mediaSection
                contactSection
                sponsoredSection
                appFeedbackSection
                aboutSection
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
        }
        .adMobBannerPlacement(showDebugPlaceholder: true)
    }

    // MARK: - Sections

    private var quickAccessSection: some View {
        Section("Quick Access") {
            NavigationLink {
                AskAIView()
            } label: {
                Label("Ask AI", systemImage: "sparkles")
            }

            NavigationLink {
                ECode360ScrapeView()
            } label: {
                Label("Town Code (eCode360)", systemImage: "doc.text.magnifyingglass")
            }

            NavigationLink {
                NewsAndEventsView()
            } label: {
                Label("News & Events", systemImage: "newspaper.fill")
            }

            NavigationLink {
                CouncilScorecardView()
            } label: {
                Label("Council Scorecard", systemImage: "checklist.checked")
            }

            NavigationLink {
                SnowRemovalOverrunView()
            } label: {
                Label("Snow Budget Overrun", systemImage: "snowflake")
            }

            navCard(
                title: "Town Feedback",
                subtitle: "Official Town contact and feedback channels",
                icon: "envelope.fill",
                destination: WebContentView(url: contactURL, title: "Town Feedback")
            )

        }
    }

    private var townServicesSection: some View {
        Section("Town Services") {
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
                title: "Quick Links",
                subtitle: "Popular shortcuts from the Town site",
                icon: "link.circle.fill",
                destination: WebContentView(url: quickLinksURL, title: "Quick Links")
            )
        }
    }

    private var insightsSection: some View {
        Section("Insights") {
            navCard(
                title: "Financial Reports",
                subtitle: "Official audits, AFR updates, CPF financials, and budget history",
                icon: "chart.bar.doc.horizontal.fill",
                destination: WebContentView(url: financialReportsURL, title: "Financial Reports")
            )

            NavigationLink {
                RoadsDashboardView()
            } label: {
                Label("Roads Dashboard", systemImage: "road.lanes")
            }

            NavigationLink {
                BudgetExplainersView()
            } label: {
                Label("Plain-English Budget Explainers", systemImage: "text.book.closed.fill")
            }

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

    private var newsAndEventsSection: some View {
        Section("News & Events") {
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
        }
    }

    private var councilScorecardSection: some View {
        Section("Civic Scorecards") {
            NavigationLink {
                CouncilScorecardView()
            } label: {
                Label("Council Scorecard", systemImage: "checklist.checked")
            }
        }
    }

    private var taxesAndPaymentsSection: some View {
        Section("Taxes & Payments") {
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

    private var mediaSection: some View {
        Section("Media") {
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

    private var sponsoredSection: some View {
        Section("Sponsored") {
            AdMobBannerContainerView(
                adUnitID: AdMobConfig.bannerAdUnitID,
                showDebugPlaceholder: true
            )
                .padding(.vertical, 4)

            #if DEBUG
            HStack {
                Label(AdMobConfig.isUsingTestBanner ? "Google Ad: Test Mode" : "Google Ad: Live Mode", systemImage: "wrench.and.screwdriver")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if !AdMobConfig.isUsingTestBanner {
                AdMobBannerContainerView(
                    adUnitID: AdMobConfig.testBannerAdUnitID,
                    showDebugPlaceholder: true
                )
                    .padding(.vertical, 4)
            }
            #endif

            Link(destination: sponsoredShopSimonURL) {
                HStack(spacing: 10) {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SHOP SIMON (formerly Shop Premium Outlets)")
                            .font(.headline)
                        Text("Affiliate link")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }

            Link(destination: sponsoredWisprURL) {
                HStack(spacing: 10) {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wispr Flow")
                            .font(.headline)
                        Text("Affiliate link")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }

            Link(destination: sponsoredTryCentsURL) {
                HStack(spacing: 10) {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Try Personal Laundry Delivery Service")
                            .font(.headline)
                        Text("Local service ad")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }
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
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 30, alignment: .center)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 10)
        }
    }
}
