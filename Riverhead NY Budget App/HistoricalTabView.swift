//
//  HistoricalTabView.swift
//  Riverhead NY Budget App
//
//  Swift 6 / iOS 17+
//
//  • Lists Tentative / Preliminary / Adopted / Audit (and Capital if you add it)
//  • Quick filters by type (multi-select menu)
//  • Search by title, type label, or year
//  • "This Year" quick links + grouped history by year
//  • Snapshot section with total docs + span of years
//

import SwiftUI
import Observation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
struct HistoricalTabView: View {
    @Environment(RBBudgetStore.self) private var store
    @Environment(\.colorScheme) private var scheme

    @State private var selectedDoc: RiverheadBudgetDoc?
    @State private var searchText: String = ""
    @State private var typeFilters: Set<RiverheadBudgetDoc.DocType> = [] // empty = all

    // Explicit ordering to avoid relying on allCases sort
    private let docTypesOrdered: [RiverheadBudgetDoc.DocType] = [
        .tentative,
        .preliminary,
        .adopted,
        .capital,
        .audit
    ]

    var body: some View {
        NavigationStack {
            List {
                let allDocs = store.documents
                let filteredDocs = filtered(allDocs)

                // Snapshot (always if any docs exist)
                if !allDocs.isEmpty {
                    snapshotSection(allDocs: allDocs, filteredDocs: filteredDocs)
                }

                // This Year quick links (respects filters/search)
                if !store.quickLinks.isEmpty {
                    let quick = filtered(store.quickLinks)
                    if !quick.isEmpty {
                        Section("This Year") {
                            ForEach(quick) { doc in
                                DocRow(doc: doc) { selectedDoc = doc }
                            }
                        }
                    }
                }

                // Grouped history (respects filters/search)
                let groups = groupedByYear(filteredDocs)
                if groups.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No matching documents",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("Try clearing filters or changing your search.")
                        )
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                    }
                } else {
                    ForEach(groups) { group in
                        Section("\(group.year)") {
                            ForEach(group.docs) { doc in
                                DocRow(doc: doc) { selectedDoc = doc }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(RiverheadTheme.Surface.page.ignoresSafeArea())
            .navigationTitle("Budget History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RiverheadTheme.Surface.card, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    filterMenu
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search by title, type, or year"
            )
            .sheet(item: $selectedDoc) { doc in
                WebContentView(url: doc.url)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Snapshot

    private func snapshotSection(
        allDocs: [RiverheadBudgetDoc],
        filteredDocs: [RiverheadBudgetDoc]
    ) -> some View {
        let years = allDocs.map(\.year)
        let minYear = years.min()
        let maxYear = years.max()
        let totalCount = allDocs.count
        let filteredCount = filteredDocs.count

        return Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("Snapshot")
                    .font(.headline)

                if let minYear, let maxYear {
                    Text("Covers budgets from \(minYear)–\(maxYear).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Budget documents loaded.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Label {
                        Text("\(totalCount) total document\(totalCount == 1 ? "" : "s")")
                    } icon: {
                        Image(systemName: "doc.on.doc")
                    }
                    .font(.caption)

                    if filteredCount != totalCount {
                        Label {
                            Text("\(filteredCount) match current filters")
                        } icon: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Filter Menu

    private var filterMenu: some View {
        Menu {
            // Toggleable multi-select entries
            ForEach(docTypesOrdered, id: \.self) { t in
                let isOn = typeFilters.contains(t)
                Button {
                    if isOn {
                        typeFilters.remove(t)
                    } else {
                        typeFilters.insert(t)
                    }
                } label: {
                    Label(
                        t.displayName,
                        systemImage: isOn ? "checkmark.circle.fill" : "circle"
                    )
                }
            }

            if !typeFilters.isEmpty {
                Divider()
                Button(role: .destructive) {
                    typeFilters.removeAll()
                } label: {
                    Label("Clear Filters", systemImage: "xmark.circle")
                }
            }
        } label: {
            Image(systemName: typeFilters.isEmpty
                  ? "line.3.horizontal.decrease.circle"
                  : "line.3.horizontal.decrease.circle.fill")
        }
        .tint(RiverheadTheme.accent)
        .accessibilityLabel("Filter by document type")
    }

    // MARK: - Filtering & Grouping

    private func filtered(_ docs: [RiverheadBudgetDoc]) -> [RiverheadBudgetDoc] {
        var out = docs

        // Type filters
        if !typeFilters.isEmpty {
            out = out.filter { typeFilters.contains($0.type) }
        }

        // Search
        let raw = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty {
            let q = raw.lowercased()
            out = out.filter {
                $0.title.lowercased().contains(q) ||
                $0.type.displayName.lowercased().contains(q) ||
                String($0.year).contains(q)
            }
        }

        return out
    }

    private struct YearGroup: Identifiable {
        let year: Int
        let docs: [RiverheadBudgetDoc]
        var id: Int { year }
    }

    private func groupedByYear(_ docs: [RiverheadBudgetDoc]) -> [YearGroup] {
        let dict = Dictionary(grouping: docs, by: { $0.year })
        return dict.keys
            .sorted(by: >)
            .map { year in
                let list = (dict[year] ?? []).sorted { lhs, rhs in
                    if typeOrder(lhs.type) != typeOrder(rhs.type) {
                        return typeOrder(lhs.type) < typeOrder(rhs.type)
                    }
                    return lhs.title < rhs.title
                }
                return YearGroup(year: year, docs: list)
            }
    }

    private func typeOrder(_ t: RiverheadBudgetDoc.DocType) -> Int {
        switch t {
        case .tentative:   return 0
        case .preliminary: return 1
        case .adopted:     return 2
        case .capital:     return 3
        case .audit:       return 4
        }
    }
}

// MARK: - Row

private struct DocRow: View {
    let doc: RiverheadBudgetDoc
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: doc.type.iconName)
                    .font(.title3)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(doc.title)
                            .font(.body.weight(.semibold))
                            .lineLimit(2)

                        TypeBadge(type: doc.type)
                    }

                    HStack(spacing: 10) {
                        if let p = doc.published {
                            Label {
                                Text(p, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } icon: {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let mb = doc.sizeMB {
                            Label {
                                Text(String(format: "%.1f MB", mb))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } icon: {
                                Image(systemName: "arrow.down.doc")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .foregroundStyle(.secondary)
            }
        }
        .contextMenu {
            ShareLink(item: doc.url) {
                Label("Share Link", systemImage: "square.and.arrow.up")
            }

            Button {
                #if canImport(UIKit)
                UIPasteboard.general.string = doc.url.absoluteString
                #endif
            } label: {
                Label("Copy Link", systemImage: "doc.on.doc")
            }
        }
    }
}

// MARK: - Type Badge

private struct TypeBadge: View {
    let type: RiverheadBudgetDoc.DocType

    var body: some View {
        Text(type.displayName)
            .font(.caption2.weight(.semibold))
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .background(type.badgeFill, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(type.badgeStroke, lineWidth: 0.6)
            )
            .foregroundStyle(type.badgeText)
    }
}

// MARK: - DocType helpers

private extension RiverheadBudgetDoc.DocType {
    var displayName: String {
        switch self {
        case .tentative:   return "Tentative"
        case .preliminary: return "Preliminary"
        case .adopted:     return "Adopted"
        case .capital:     return "Capital"
        case .audit:       return "Audit"
        }
    }

    var iconName: String {
        switch self {
        case .tentative:   return "doc.text"
        case .preliminary: return "doc.text.magnifyingglass"
        case .adopted:     return "checkmark.seal"
        case .capital:     return "building.columns"
        case .audit:       return "doc.text.fill"
        }
    }

    var badgeFill: Color {
        switch self {
        case .tentative:   return .blue.opacity(0.14)
        case .preliminary: return .teal.opacity(0.14)
        case .adopted:     return .green.opacity(0.16)
        case .capital:     return .orange.opacity(0.16)
        case .audit:       return .purple.opacity(0.14)
        }
    }

    var badgeStroke: Color {
        switch self {
        case .tentative:   return .blue.opacity(0.35)
        case .preliminary: return .teal.opacity(0.35)
        case .adopted:     return .green.opacity(0.40)
        case .capital:     return .orange.opacity(0.38)
        case .audit:       return .purple.opacity(0.35)
        }
    }

    var badgeText: Color {
        switch self {
        case .tentative:   return .blue
        case .preliminary: return .teal
        case .adopted:     return .green
        case .capital:     return .orange
        case .audit:       return .purple
        }
    }
}

// MARK: - Preview

#Preview {
    HistoricalTabView()
        .environment(RBBudgetStore())
}
