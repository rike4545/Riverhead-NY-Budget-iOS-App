//
//  CivicToolkitsHubView.swift
//  Riverhead NY Budget App
//
//  Created by Bryan on 1/20/26.
//


//
//  CivicToolkitsHubView.swift
//  Riverhead NY Budget App
//
//  Compile-safe hub for civic tools.
//  - Avoids ForEach($store.array) binding inference issues
//  - Avoids calling missing toggleBroadbandResolved()
//  - Avoids referencing BroadbandIssue.issueType directly (uses introspection)
//
import SwiftUI
import MapKit
import UIKit

@MainActor
struct CivicToolkitsHubView: View {

    @EnvironmentObject private var store: RBCivicToolkitStore

    @State private var query: String = ""
    @State private var selectedBroadband: SelectedBroadbandIssue?
    @State private var showCopiedToast: Bool = false

    // MARK: - Types

    typealias BroadbandIssue = RBCivicToolkitStore.BroadbandIssue

    private struct RowItem: Identifiable {
        let id: UUID
        let issue: BroadbandIssue
    }

    private struct SelectedBroadbandIssue: Identifiable {
        let id: UUID
        let issue: BroadbandIssue
    }

    // MARK: - Data

    private var filteredBroadbandRows: [RowItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let issues = store.broadbandIssues

        guard !q.isEmpty else {
            return issues.map { RowItem(id: RBBroadbandIntrospector.id(from: $0), issue: $0) }
        }

        return issues
            .filter { issue in
                let hay = [
                    RBBroadbandIntrospector.title(from: issue),
                    RBBroadbandIntrospector.typeString(from: issue),
                    RBBroadbandIntrospector.detail(from: issue)
                ]
                .joined(separator: " ")
                .lowercased()

                return hay.contains(q)
            }
            .map { RowItem(id: RBBroadbandIntrospector.id(from: $0), issue: $0) }
    }

    private var shareText: String {
        let all = store.broadbandIssues
        let resolved = all.filter { RBBroadbandIntrospector.isResolved(from: $0) }.count
        let open = all.count - resolved

        var lines: [String] = []
        lines.append("RIVERHEAD • TOOLKITS SUMMARY")
        lines.append("Broadband issues: \(all.count) (Open \(open) • Resolved \(resolved))")
        lines.append("")

        for issue in all.prefix(30) {
            let title = RBBroadbandIntrospector.title(from: issue)
            let type  = RBBroadbandIntrospector.typeString(from: issue)
            let detail = RBBroadbandIntrospector.detail(from: issue)
            let status = RBBroadbandIntrospector.isResolved(from: issue) ? "Resolved" : "Open"

            lines.append("• \(title)")
            if !type.isEmpty { lines.append("  Type: \(type)") }
            lines.append("  Status: \(status)")
            if !detail.isEmpty { lines.append("  \(detail)") }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - View

    var body: some View {
        List {
            Section {
                header
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 10, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section("People & Earnings") {
                NavigationLink {
                    GrossEarningsNewsdayView()
                } label: {
                    Label("Gross Earnings (Newsday)", systemImage: "person.text.rectangle")
                }

                NavigationLink {
                    CouncilScorecardView()
                } label: {
                    Label("Town Board Scorecard", systemImage: "checkmark.seal.fill")
                }

                NavigationLink {
                    DepartmentsView()
                } label: {
                    Label("Town Departments", systemImage: "building.2.fill")
                }
            }

            Section("Budget Tools") {
                NavigationLink {
                    BudgetExplainersView()
                } label: {
                    Label("Budget Explainers", systemImage: "text.book.closed.fill")
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
                    BudgetPolicyInsightsView()
                } label: {
                    Label("Budget Policy Insights", systemImage: "lightbulb.fill")
                }

                NavigationLink {
                    SnowRemovalOverrunView()
                } label: {
                    Label("Snow Removal OT Overrun", systemImage: "snowflake")
                }

                NavigationLink {
                    ContractScheduleIncreaseView()
                } label: {
                    Label("Contract Schedule Increases", systemImage: "doc.text.magnifyingglass")
                }

                NavigationLink {
                    DepartmentSpendForecastView()
                } label: {
                    Label("Department Spend Forecast", systemImage: "chart.bar.xaxis")
                }

                NavigationLink {
                    ContractImpactEstimatorView()
                } label: {
                    Label("Contract Impact Estimator", systemImage: "chart.line.uptrend.xyaxis")
                }
            }

            Section("Capital & Infrastructure") {
                NavigationLink {
                    RBCapitalProjectsMapView()
                } label: {
                    Label("Capital Projects Map", systemImage: "map")
                }
            }

            Section("Cost of Living & Services") {
                NavigationLink {
                    CostOfLivingToolkitsView()
                } label: {
                    Label("Cost of Living Toolkits", systemImage: "cart.fill")
                }

                NavigationLink {
                    Channel22View()
                } label: {
                    Label("Channel 22 (Town TV)", systemImage: "tv.fill")
                }

                NavigationLink {
                    SixSigmaProcessImprovementShiftView()
                } label: {
                    Label("Process Improvement (Six Sigma)", systemImage: "arrow.triangle.2.circlepath.circle")
                }
            }

            Section("Broadband Tracker") {
                if filteredBroadbandRows.isEmpty {
                    ContentUnavailableView(
                        "No broadband issues",
                        systemImage: "wifi",
                        description: Text("No items match your search (or none added yet).")
                    )
                } else {
                    ForEach(filteredBroadbandRows) { row in
                        Button {
                            selectedBroadband = .init(id: row.id, issue: row.issue)
                        } label: {
                            BroadbandRow(issue: row.issue)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteBroadbandRows)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Toolkits")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, prompt: "Search broadband issues…")
        .sheet(item: $selectedBroadband) { sel in
            BroadbandDetailSheet(issue: sel.issue)
        }
        .toolbar(content: {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ShareLink(item: shareText) {
                        Label("Share Summary", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        UIPasteboard.general.string = shareText
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
                            showCopiedToast = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                showCopiedToast = false
                            }
                        }
                    } label: {
                        Label("Copy Summary", systemImage: "doc.on.doc")
                    }

                    Divider()

                    Button(role: .destructive) {
                        query = ""
                    } label: {
                        Label("Clear Search", systemImage: "xmark.circle")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share")
            }

            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        })
        .overlay(alignment: .top) {
            if showCopiedToast {
                ToastBanner(text: "Copied")
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .adMobBannerPlacement(showDebugPlaceholder: true)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.2.badge.gearshape")
                        .font(.title3.weight(.semibold))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Resident-friendly tools")
                        .font(.headline.weight(.semibold))
                    Text("Quick access to civic toolkit, maps, issue tracking, and process improvement.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                MiniPill(text: "Search", icon: "magnifyingglass")
                MiniPill(text: "Share", icon: "square.and.arrow.up")
                MiniPill(text: "Edit", icon: "pencil")
            }
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func deleteBroadbandRows(at offsets: IndexSet) {
        // Delete by IDs derived from the filtered list
        let idsToDelete: [UUID] = offsets.compactMap { idx in
            guard idx < filteredBroadbandRows.count else { return nil }
            return filteredBroadbandRows[idx].id
        }

        if idsToDelete.isEmpty { return }

        store.broadbandIssues.removeAll { issue in
            idsToDelete.contains(RBBroadbandIntrospector.id(from: issue))
        }
        store.scheduleSave()
    }

    private struct MiniPill: View {
        let text: String
        let icon: String

        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption.weight(.semibold))
                Text(text).font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.06))
            .foregroundStyle(.secondary)
            .clipShape(Capsule())
        }
    }
}

private struct ToastBanner: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 10, y: 6)
    }
}

// MARK: - Broadband Row + Detail

// MARK: - Broadband Row + Detail (compile-safe, reflection-based)

/// Reflection-based accessor for `RBCivicToolkitStore.BroadbandIssue` fields.
/// This keeps the UI resilient even if the model evolves (or if property names vary).
enum RBBroadbandIntrospector {

    static func id(from issue: Any) -> UUID {
        if let v: UUID = value(issue, keys: ["id", "uuid", "identifier"]) { return v }
        if let s: String = value(issue, keys: ["id", "uuid", "identifier"]), let u = UUID(uuidString: s) { return u }
        // Stable-ish fallback derived from text fields
        let seed = (title(from: issue) + "|" + typeString(from: issue) + "|" + detail(from: issue)).hashValue
        var bytes = withUnsafeBytes(of: seed.bigEndian, Array.init)
        bytes += Array(repeating: 0, count: max(0, 16 - bytes.count))
        bytes = Array(bytes.prefix(16))
        return UUID(uuid: (bytes[0],bytes[1],bytes[2],bytes[3],bytes[4],bytes[5],bytes[6],bytes[7],bytes[8],bytes[9],bytes[10],bytes[11],bytes[12],bytes[13],bytes[14],bytes[15]))
    }

    static func title(from issue: Any) -> String {
        if let v: String = value(issue, keys: ["title", "name", "issueTitle", "headline", "summaryTitle"]) { return v }
        if let provider: String = value(issue, keys: ["provider", "isp", "company"]) {
            let t = typeString(from: issue)
            return t.isEmpty ? provider : "\(provider) • \(t)"
        }
        return "Broadband issue"
    }

    static func typeString(from issue: Any) -> String {
        if let v: String = value(issue, keys: ["issueType", "type", "category", "kind"]) { return v }
        if let v: CustomStringConvertible = value(issue, keys: ["issueType", "type", "category", "kind"]) { return String(describing: v) }
        return ""
    }

    private static let df: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static func detail(from issue: Any) -> String {
        var lines: [String] = []

        if let status: String = value(issue, keys: ["agreementStatus", "statusText", "agreement"]) {
            let s = status.trimmingCharacters(in: .whitespacesAndNewlines)
            if !s.isEmpty { lines.append("Status: \(s)") }
        }

        if let expires: Date = value(issue, keys: ["expiresAt", "contractEnds", "expirationDate", "endDate"]) {
            lines.append("Contract ends: \(df.string(from: expires))")
        }

        if let key: Date = value(issue, keys: ["keyDate", "hearingDate", "targetDate", "date"]) {
            lines.append("Key date: \(df.string(from: key))")
        }

        if let goal: String = value(issue, keys: ["policyGoal", "goal", "objective"]) {
            let g = goal.trimmingCharacters(in: .whitespacesAndNewlines)
            if !g.isEmpty { lines.append("Policy goal: \(g)") }
        }

        if let comps: String = value(issue, keys: ["competitors", "competitorsCSV", "competitorList", "competitor"]) {
            let c = comps.trimmingCharacters(in: .whitespacesAndNewlines)
            if !c.isEmpty { lines.append("Competitors: \(c)") }
        }

        let notes: String = value(issue, keys: ["notes", "detail", "description"]) ?? ""
        let n = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !n.isEmpty {
            if !lines.isEmpty { lines.append("") }
            lines.append(n)
        }

        return lines.joined(separator: "\n")
    }

    static func isResolved(from issue: Any) -> Bool {
        if let v: Bool = value(issue, keys: ["resolved", "isResolved", "done", "closed"]) { return v }
        if let v: String = value(issue, keys: ["status", "state"]) {
            let s = v.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return s == "resolved" || s == "closed" || s == "done" || s == "complete"
        }
        return false
    }

    // MARK: - Reflection helper

    private static func value<T>(_ issue: Any, keys: [String]) -> T? {
        let mirror = Mirror(reflecting: issue)
        for child in mirror.children {
            guard let label = child.label else { continue }
            if keys.contains(label), let typed = child.value as? T { return typed }
        }
        // Walk up superclass chain (if any)
        if let sup = mirror.superclassMirror {
            for child in sup.children {
                guard let label = child.label else { continue }
                if keys.contains(label), let typed = child.value as? T { return typed }
            }
        }
        return nil
    }
}

private struct BroadbandRow: View {
    let issue: CivicToolkitsHubView.BroadbandIssue

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(RBBroadbandIntrospector.title(from: issue))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Spacer(minLength: 8)

                let resolved = RBBroadbandIntrospector.isResolved(from: issue)
                Text(resolved ? "Resolved" : "Open")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(resolved ? Color.green.opacity(0.18) : Color.orange.opacity(0.18))
                    )
                    .foregroundStyle(resolved ? Color.green : Color.orange)
            }

            let type = RBBroadbandIntrospector.typeString(from: issue)
            if !type.isEmpty {
                Text(type)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            let detail = RBBroadbandIntrospector.detail(from: issue)
            if !detail.isEmpty {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct BroadbandDetailSheet: View {
    let issue: CivicToolkitsHubView.BroadbandIssue
    @Environment(\.dismiss) private var dismiss

    private var shareText: String {
        let title = RBBroadbandIntrospector.title(from: issue)
        let type  = RBBroadbandIntrospector.typeString(from: issue)
        let detail = RBBroadbandIntrospector.detail(from: issue)
        let status = RBBroadbandIntrospector.isResolved(from: issue) ? "Resolved" : "Open"

        var lines: [String] = []
        lines.append("RIVERHEAD • BROADBAND ISSUE")
        lines.append("Title: \(title)")
        if !type.isEmpty { lines.append("Type: \(type)") }
        lines.append("Status: \(status)")
        if !detail.isEmpty { lines.append("") ; lines.append(detail) }
        return lines.joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(RBBroadbandIntrospector.title(from: issue))
                                .font(.title3.weight(.semibold))

                            let type = RBBroadbandIntrospector.typeString(from: issue)
                            if !type.isEmpty {
                                Text(type)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            let status = RBBroadbandIntrospector.isResolved(from: issue) ? "Resolved" : "Open"
                            Text("Status: \(status)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    let detail = RBBroadbandIntrospector.detail(from: issue)
                    if !detail.isEmpty {
                        GroupBox("Details") {
                            Text(detail)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    GroupBox("Actions") {
                        VStack(alignment: .leading, spacing: 10) {
                            ShareLink(item: shareText) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }

                            Button {
                                UIPasteboard.general.string = shareText
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Broadband Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            })
        }
    }
}
