//
//  SettingsView.swift
//  Riverhead NY Budget App
//
//  App-wide settings: display preferences, property values, data management,
//  and the political-independence disclaimer.
//
//  Swift 6 · iOS 17+
//

import SwiftUI

@MainActor
struct SettingsView: View {

    // MARK: - Display
    @AppStorage("Riverhead.budgetMode")    private var budgetModeRaw: String   = BudgetAudienceMode.resident.rawValue
    @AppStorage("Riverhead.colorScheme")   private var colorSchemeRaw: String  = "system"

    // MARK: - My Property (shared with MyTaxesView)
    @AppStorage("tax_assessed_value")  private var assessedValue: Double  = 450_000
    @AppStorage("tax_exemptions")      private var exemptions: Double      = 0
    @AppStorage("tax_rate_per_1000")   private var ratePerThousand: Double = 61.9482

    // MARK: - Privacy
    @AppStorage(AnalyticsConsent.defaultsKey) private var analyticsEnabled: Bool = true

    // MARK: - Cached data (Council Scorecard)
    @AppStorage("council_scorecard_fetched_campaign_snapshots_json")  private var fetchedSnapshotsJSON: String  = ""
    @AppStorage("council_scorecard_previous_campaign_snapshots_json") private var previousSnapshotsJSON: String = ""
    @AppStorage("council_scorecard_filings_last_updated_iso")         private var filingsLastUpdatedISO: String  = ""
    @AppStorage("council_scorecard_user_ratings_json")                private var userRatingsJSON: String        = ""

    // MARK: - State
    @State private var showClearFilingsConfirm  = false
    @State private var showClearRatingsConfirm  = false
    @State private var clearedFilings           = false
    @State private var clearedRatings           = false
    @Environment(\.colorScheme) private var scheme

    private var budgetMode: BudgetAudienceMode {
        BudgetAudienceMode(rawValue: budgetModeRaw) ?? .resident
    }

    // MARK: - Body

    var body: some View {
        List {
            displaySection
            myPropertySection
            dataSection
            accessibilityTipsSection
            independenceSection
            aboutSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .tint(RiverheadTheme.accent)
        .confirmationDialog(
            "Clear cached campaign filings?",
            isPresented: $showClearFilingsConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear Filings Cache", role: .destructive) {
                fetchedSnapshotsJSON  = ""
                previousSnapshotsJSON = ""
                filingsLastUpdatedISO = ""
                clearedFilings = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes downloaded NY Open Data campaign-finance snapshots. Use Refresh on the Council Scorecard to re-fetch.")
        }
        .confirmationDialog(
            "Clear your scorecard ratings?",
            isPresented: $showClearRatingsConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear My Ratings", role: .destructive) {
                userRatingsJSON = ""
                clearedRatings = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes only the grades you personally assigned to board members. App-supplied grades are not affected.")
        }
    }

    // MARK: - Sections

    private var displaySection: some View {
        Section {
            // Appearance (color scheme)
            Picker(selection: $colorSchemeRaw) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            } label: {
                Label("Appearance", systemImage: "circle.lefthalf.filled")
            }
            .accessibilityLabel("Appearance setting")
            .accessibilityHint("Choose between system default, always light, or always dark mode.")

            // Budget detail level
            VStack(alignment: .leading, spacing: 6) {
                Label("Budget detail level", systemImage: "slider.horizontal.3")
                    .font(.subheadline.weight(.semibold))
                    .accessibilityLabel("Budget detail level setting")

                Picker("Budget detail level", selection: $budgetModeRaw) {
                    ForEach(BudgetAudienceMode.allCases) { mode in
                        Text(mode.label).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Budget detail level")
                .accessibilityHint("Resident shows plain-language summaries. Expert shows full numbers and analysis.")

                Text(budgetMode == .resident
                     ? "Plain-language summaries — recommended for most residents."
                     : "Full numbers, detailed analysis, and source trails.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Display")
        } footer: {
            Text("Appearance overrides the system setting just for this app. Budget detail level can also be changed from the toolbar inside the Budget tab.")
        }
    }

    private var myPropertySection: some View {
        Section {
            // Assessed value
            VStack(alignment: .leading, spacing: 4) {
                Label("Assessed value", systemImage: "house.fill")
                    .font(.subheadline.weight(.semibold))
                    .accessibilityHidden(true)

                HStack {
                    Text("Assessed value")
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("e.g. 450000", value: $assessedValue, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 130)
                        .accessibilityLabel("Assessed value in dollars")
                        .accessibilityHint("Enter your property's assessed value to calculate your estimated tax bill.")
                }
            }

            // Exemptions
            HStack {
                Text("Exemptions")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("e.g. 0", value: $exemptions, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 130)
                    .accessibilityLabel("Exemptions amount in dollars")
                    .accessibilityHint("Enter your total property tax exemption amount, such as STAR or veteran exemptions.")
            }

            // Tax rate
            HStack {
                Text("Town tax rate (per $1,000)")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("e.g. 61.95", value: $ratePerThousand, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 130)
                    .accessibilityLabel("Town tax rate per thousand dollars of assessed value")
                    .accessibilityHint("The current 2026 rate is approximately 61.95 per thousand dollars.")
            }

            // Live estimate
            let net = max(0, assessedValue - exemptions)
            let estimate = net / 1_000 * ratePerThousand
            HStack {
                Label("Estimated Town tax", systemImage: "dollarsign.circle.fill")
                    .foregroundStyle(RiverheadTheme.accent)
                Spacer()
                Text(estimate, format: .currency(code: "USD"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.accent)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Estimated Town tax: \(estimate.formatted(.currency(code: "USD")))")
        } header: {
            Text("My Property")
        } footer: {
            Text("These values are shared with the My Taxes screen. Changes here update estimates throughout the app. Always verify with your actual tax bill.")
        }
    }

    private var dataSection: some View {
        Section {
            // Analytics opt-out
            Toggle(isOn: $analyticsEnabled) {
                Label("Share anonymous usage analytics", systemImage: "chart.bar.xaxis")
            }
            .onChange(of: analyticsEnabled) { _, newValue in
                AnalyticsConsent.set(newValue)
            }
            .accessibilityLabel("Share anonymous usage analytics")
            .accessibilityHint("When on, the app sends anonymous, non-advertising usage data to help improve it. Turn off to stop all analytics collection.")

            // Campaign filings cache
            Button {
                showClearFilingsConfirm = true
            } label: {
                HStack {
                    Label(
                        clearedFilings ? "Filings cache cleared" : "Clear campaign filings cache",
                        systemImage: clearedFilings ? "checkmark.circle.fill" : "arrow.counterclockwise.circle"
                    )
                    .foregroundStyle(clearedFilings ? .green : .primary)
                    Spacer()
                    if !fetchedSnapshotsJSON.isEmpty {
                        Text("Cached")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .accessibilityLabel("Clear campaign filings cache")
            .accessibilityHint("Removes downloaded NY Open Data campaign finance snapshots. Use Refresh on the Council Scorecard to re-download.")
            .disabled(clearedFilings)

            // User ratings
            Button {
                showClearRatingsConfirm = true
            } label: {
                Label(
                    clearedRatings ? "Your ratings cleared" : "Clear my scorecard ratings",
                    systemImage: clearedRatings ? "checkmark.circle.fill" : "star.slash"
                )
                .foregroundStyle(clearedRatings ? .green : .primary)
            }
            .accessibilityLabel("Clear my Council Scorecard ratings")
            .accessibilityHint("Removes only the grades you personally assigned. App-supplied grades are not affected.")
            .disabled(clearedRatings)

            // Last filings update
            if !filingsLastUpdatedISO.isEmpty {
                HStack {
                    Label("Last filings refresh", systemImage: "clock")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(filingsLastUpdatedISO.prefix(10))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Last campaign filings refresh: \(filingsLastUpdatedISO.prefix(10))")
            }
        } header: {
            Text("Data & Privacy")
        } footer: {
            Text("Your property values, scorecard ratings, and cached filings stay on this device. If usage analytics is on, the app sends anonymous, non-advertising usage data (via Firebase) to help improve it — never linked to your identity, and with no advertising identifier. Campaign-finance data is fetched directly from NY Open Data (data.ny.gov).")
        }
    }

    private var accessibilityTipsSection: some View {
        Section {
            settingsTip(
                icon: "textformat.size",
                title: "Text size",
                detail: "This app respects your iOS text-size setting. Go to Settings → Display & Brightness → Text Size to adjust."
            )
            settingsTip(
                icon: "circle.lefthalf.filled",
                title: "Increase Contrast",
                detail: "Enable Settings → Accessibility → Display & Text Size → Increase Contrast for sharper borders and higher-contrast colors."
            )
            settingsTip(
                icon: "speaker.wave.2.fill",
                title: "VoiceOver",
                detail: "All screens are labelled for VoiceOver. Enable it in Settings → Accessibility → VoiceOver."
            )
            settingsTip(
                icon: "hand.raised.fill",
                title: "Reduce Motion",
                detail: "Enable Settings → Accessibility → Motion → Reduce Motion to minimize animations."
            )
        } header: {
            Text("Accessibility")
        } footer: {
            Text("Accessibility preferences are managed by iOS. Changes apply immediately across all apps.")
        }
    }

    private var independenceSection: some View {
        Section {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "hand.raised.fill")
                    .font(.title3)
                    .foregroundStyle(RiverheadTheme.accent)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Political Independence")
                        .font(.subheadline.weight(.semibold))
                    Text("This app is not endorsed by, financed by, affiliated with, or produced on behalf of any political campaign, candidate, political party, political action committee, or elected official. It is an independent, community-built civic tool. No candidate or campaign has paid for, directed, or approved any content in this app.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Political Independence. This app is not endorsed by, financed by, affiliated with, or produced on behalf of any political campaign, candidate, political party, political action committee, or elected official.")
        } header: {
            Text("Independence Disclaimer")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            NavigationLink { AboutAppView() } label: {
                Label("About This App", systemImage: "info.circle")
                    .accessibilityLabel("About This App")
            }

            HStack {
                Text("Version")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("App version \(appVersion)")
        }
    }

    // MARK: - Helpers

    private func settingsTip(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(RiverheadTheme.accent)
                .frame(width: 22)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(detail)")
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
