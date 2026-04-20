//
//  RBBudgetExplorerView.swift
//  Riverhead NY Budget App
//
//  FIX:
//  - Resolves "Type of expression is ambiguous..." in outlineSection by using
//    OutlineGroup over the roots array and providing an OPTIONAL children keyPath.
//  - Adds childrenOpt shim for RBBudgetNode so OutlineGroup matches SwiftUI initializer.
//
//  Swift 6 • iOS 17+
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

@MainActor
struct RBBudgetExplorerView: View {

    @StateObject private var store = RBBudgetExplorerStore()

    @State private var query: String = ""
    @State private var selectedYear: Int? = nil

    @State private var showingImporter: Bool = false
    @State private var showingTemplateShare: Bool = false
    @State private var showingExportShare: Bool = false
    @State private var shareURL: URL?

    var body: some View {
        NavigationStack {
            List {
                headerSection
                yearPickerSection
                outlineSection
                templateSection

                if let err = store.errorMessage {
                    Section("Error") {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Budget Explorer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingImporter = true
                        } label: {
                            Label("Import JSON…", systemImage: "square.and.arrow.down")
                        }

                        Button(role: .destructive) {
                            store.clearDataset()
                        } label: {
                            Label("Clear dataset", systemImage: "trash")
                        }

                        Divider()

                        Button {
                            shareTemplate()
                        } label: {
                            Label("Share template JSON", systemImage: "doc")
                        }

                        Button {
                            shareExport()
                        } label: {
                            Label("Export current dataset", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                do {
                    let urls = try result.get()
                    guard let url = urls.first else { return }
                    Task { await store.importFromFile(url: url) }
                } catch {
                    store.errorMessage = error.localizedDescription
                }
            }
            .sheet(isPresented: $showingTemplateShare) {
                if let shareURL {
                    ShareSheet(url: shareURL)
                }
            }
            .sheet(isPresented: $showingExportShare) {
                if let shareURL {
                    ShareSheet(url: shareURL)
                }
            }
            .onAppear {
                if selectedYear == nil {
                    selectedYear = store.availableYears.last
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {

                HStack {
                    Image(systemName: store.source.systemImage)
                        .foregroundStyle(.secondary)

                    Text("Dataset: \(store.source.label)")
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    if let t = store.lastLoadedAt {
                        Text(t, format: .dateTime.year().month().day().hour().minute())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                TextField("Search…", text: $query)
                    .textFieldStyle(.roundedBorder)

                if store.nodes.isEmpty {
                    Text("Import a JSON budget tree to explore funds, departments, and line items.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(store.nodes.count) root item(s) • \(store.availableYears.count) year(s)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var yearPickerSection: some View {
        Section("Year") {
            if store.availableYears.isEmpty {
                Text("No years available yet.")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Year", selection: Binding(
                    get: { selectedYear },
                    set: { selectedYear = $0 }
                )) {
                    ForEach(store.availableYears, id: \.self) { y in
                        Text(String(y)).tag(Optional(y))
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var outlineSection: some View {
        Section("Tree") {
            if store.nodes.isEmpty {
                Text("No data loaded.")
                    .foregroundStyle(.secondary)
            } else {
                OutlineGroup(roots, children: \.childrenOpt) { node in
                    NavigationLink {
                        RBBudgetNodeDetailView(node: node, year: selectedYear)
                    } label: {
                        BudgetNodeRow(node: node, year: selectedYear)
                    }
                }
            }
        }
    }

    private var templateSection: some View {
        Section("Template") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Use this template to create a compatible JSON file.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    Text(store.jsonTemplate)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(10)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .frame(minHeight: 120)

                Button {
                    shareTemplate()
                } label: {
                    Label("Share template JSON", systemImage: "doc.on.doc")
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Derived

    private var roots: [RBBudgetNode] {
        store.search(query: query)
    }

    // MARK: - Share actions

    private func shareTemplate() {
        do {
            let url = try store.templateJSONURL()
            shareURL = url
            showingTemplateShare = true
        } catch {
            store.errorMessage = error.localizedDescription
        }
    }

    private func shareExport() {
        do {
            let url = try store.exportCurrentDatasetURL()
            shareURL = url
            showingExportShare = true
        } catch {
            store.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - OutlineGroup compatibility

private extension RBBudgetNode {
    /// OutlineGroup wants optional children so it can treat leaves as `nil`.
    var childrenOpt: [RBBudgetNode]? { children.isEmpty ? nil : children }
}

// MARK: - Row

private struct BudgetNodeRow: View {
    let node: RBBudgetNode
    let year: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(node.name)
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: 12)

                if let amt = amountForYear {
                    Text(amt, format: .currency(code: "USD"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            Text(node.subtitleText ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var amountForYear: Double? {
        guard let year else { return nil }
        let amt = node.amountsByYear[year] ?? 0
        return amt == 0 ? nil : amt
    }
}

// MARK: - Detail

private struct RBBudgetNodeDetailView: View {
    let node: RBBudgetNode
    let year: Int?

    var body: some View {
        List {
            Section("Summary") {
                Text(node.name)
                    .font(.title3.weight(.semibold))
                Text(node.kind.displayName)
                    .foregroundStyle(.secondary)

                if let notes = node.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(notes)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Amounts") {
                let years = node.amountsByYear.keys.sorted()
                if years.isEmpty {
                    Text("No amounts for this node.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(years, id: \.self) { y in
                        LabeledContent(String(y)) {
                            Text((node.amountsByYear[y] ?? 0), format: .currency(code: "USD"))
                        }
                    }
                }
            }

            if !node.children.isEmpty {
                Section("Children") {
                    ForEach(node.children) { c in
                        BudgetNodeRow(node: c, year: year)
                    }
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Share sheet wrapper

private struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
