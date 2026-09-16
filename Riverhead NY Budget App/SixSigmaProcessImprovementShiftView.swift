//
//  SixSigmaProcessImprovementShiftView 2.swift
//  Riverhead NY Budget App
//
//  Created by Bryan on 1/21/26.
//


//
//  SixSigmaProcessImprovementShiftView.swift
//  Riverhead NY Budget App
//
//  Visual polish pass (cards + DMAIC chips + safer SwiftUI composition)
//  iOS 17+ • Swift 6
//
//  Requires RBSixSigmaStore injected via EnvironmentObject:
//      .environmentObject(RBSixSigmaStore(...))
//  Accessed via:
//      @EnvironmentObject var store: RBSixSigmaStore
//

import SwiftUI
import UIKit

@MainActor
struct SixSigmaProcessImprovementShiftView: View {

    @EnvironmentObject private var store: RBSixSigmaStore

    @State private var searchText: String = ""
    @State private var selectedPhase: RBSixSigmaPhase? = nil
    @State private var showingCreate = false

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView {
                    LazyVStack(spacing: 14) {
                        headerCard
                        projectsHeaderRow

                        if filteredProjects.isEmpty {
                            RBSS_EmptyStateView(
                                title: "No projects found",
                                message: "Try changing the phase filter or search."
                            )
                            .padding(.top, 6)
                        } else {
                            ForEach(filteredProjects, id: \.id) { project in
                                NavigationLink {
                                    RBSS_ProjectDetailView(projectID: project.id)
                                } label: {
                                    RBSS_ProjectCard(
                                        project: project,
                                        progress: dmaicProgress(for: project),
                                        symbolName: safePhaseSymbol(project.phase)
                                    )
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button {
                                        selectedPhase = project.phase
                                    } label: {
                                        Label(
                                            "Filter to \(project.phase.title)",
                                            systemImage: safePhaseSymbol(project.phase)
                                        )
                                    }

                                    Button(role: .destructive) {
                                        store.deleteProject(id: project.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        store.deleteProject(id: project.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.bottom, 18)
                        }
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Six Sigma")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreate = true
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel("Add Project")
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                RBSS_ProjectEditorSheet(mode: .create) { newProject in
                    store.addProject(newProject)
                }
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(.systemGroupedBackground),
                Color(.secondarySystemGroupedBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var headerCard: some View {
        RBSS_HeaderCard(
            projectCount: store.projects.count,
            countsByPhase: countsByPhase(store.projects),
            selectedPhase: $selectedPhase,
            safeSymbol: safePhaseSymbol,
            inProgressCount: inProgressCount(from: store.projects)
        )
        .padding(.horizontal, 16)
    }

    private var projectsHeaderRow: some View {
        HStack {
            Text("Projects")
                .font(.title3.weight(.semibold))
            Spacer()
            RBSS_Pill(text: "\(filteredProjects.count)", icon: "number")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
    }

    private var filteredProjects: [RBSixSigmaProject] {
        let phaseFiltered: [RBSixSigmaProject] = {
            guard let phase = selectedPhase else { return store.projects }
            return store.projects.filter { $0.phase == phase }
        }()

        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return phaseFiltered.sorted { $0.updatedAt > $1.updatedAt } }

        let lower = q.lowercased()
        return phaseFiltered
            .filter {
                $0.title.lowercased().contains(lower) ||
                $0.owner.lowercased().contains(lower) ||
                $0.department.lowercased().contains(lower) ||
                $0.problemStatement.lowercased().contains(lower) ||
                $0.goalStatement.lowercased().contains(lower)
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private func countsByPhase(_ projects: [RBSixSigmaProject]) -> [RBSixSigmaPhase: Int] {
        var dict: [RBSixSigmaPhase: Int] = [:]
        for p in projects { dict[p.phase, default: 0] += 1 }
        return dict
    }

    private func inProgressCount(from projects: [RBSixSigmaProject]) -> Int {
        let phases: Set<RBSixSigmaPhase> = [.define, .measure, .analyze, .improve]
        return projects.reduce(0) { $0 + (phases.contains($1.phase) ? 1 : 0) }
    }

    private func dmaicProgress(for project: RBSixSigmaProject) -> Double {
        let phases = RBSixSigmaPhase.allCases
        guard let idx = phases.firstIndex(of: project.phase) else { return 0 }
        let total = Double(max(phases.count - 1, 1))
        return min(1, max(0, Double(idx) / total))
    }

    private func safePhaseSymbol(_ phase: RBSixSigmaPhase) -> String {
        let preferred = phase.systemImage
        if UIImage(systemName: preferred) != nil { return preferred }
        switch phase {
        case .define: return "flag.checkered"
        case .measure: return "ruler"
        case .analyze: return "magnifyingglass"
        case .improve: return "wand.and.stars"
        case .control: return "checkmark.seal"
        }
    }
}

// MARK: - Header

private struct RBSS_HeaderCard: View {

    let projectCount: Int
    let countsByPhase: [RBSixSigmaPhase: Int]
    @Binding var selectedPhase: RBSixSigmaPhase?

    let safeSymbol: (RBSixSigmaPhase) -> String
    let inProgressCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                        .frame(width: 44, height: 44)

                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 18, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("DMAIC Tracker")
                        .font(.headline.weight(.semibold))
                    Text("Define • Measure • Analyze • Improve • Control")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                stat(title: "Projects", value: "\(projectCount)", icon: "folder")
                stat(title: "In Progress", value: "\(inProgressCount)", icon: "clock")
                stat(title: "Control", value: "\(countsByPhase[.control] ?? 0)", icon: safeSymbol(.control))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    phaseChip(title: "All", icon: "line.3.horizontal.decrease.circle", isSelected: selectedPhase == nil) {
                        selectedPhase = nil
                    }

                    ForEach(RBSixSigmaPhase.allCases, id: \.self) { phase in
                        let count = countsByPhase[phase] ?? 0
                        phaseChip(
                            title: phase.title,
                            icon: safeSymbol(phase),
                            count: count,
                            isSelected: selectedPhase == phase
                        ) {
                            selectedPhase = phase
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("Tip: Add a baseline + target early. It keeps progress measurable and helps explain tradeoffs.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private func stat(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func phaseChip(
        title: String,
        icon: String,
        count: Int? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                if let count {
                    Text("\(count)")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(isSelected ? 0.20 : 0.08), in: Capsule())
                        .foregroundStyle(isSelected ? .primary : .secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.06), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.08), lineWidth: 1)
            )
            .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Project Card

private struct RBSS_ProjectCard: View {

    let project: RBSixSigmaProject
    let progress: Double
    let symbolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                        .frame(width: 44, height: 44)

                    Image(systemName: symbolName)
                        .font(.system(size: 18, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(project.title)
                        .font(.headline.weight(.semibold))
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        RBSS_Pill(text: project.phase.title, icon: "tag")
                        if !project.department.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            RBSS_Pill(text: project.department, icon: "building.2")
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }

            ProgressView(value: clamp01(progress), total: 1.0)

            HStack {
                if !project.owner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Label(project.owner, systemImage: "person")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Label("Unassigned", systemImage: "person")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Text("Updated \(project.updatedAt, style: .date)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private func clamp01(_ v: Double) -> Double { min(1, max(0, v)) }
}

// MARK: - Detail (read-only)

@MainActor
private struct RBSS_ProjectDetailView: View {

    @EnvironmentObject private var store: RBSixSigmaStore
    let projectID: UUID

    var body: some View {
        let project = store.projects.first(where: { $0.id == projectID })

        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let p = project {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(p.title)
                            .font(.title3.weight(.semibold))

                        HStack(spacing: 8) {
                            RBSS_Pill(text: p.phase.title, icon: "tag")
                            if !p.department.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                RBSS_Pill(text: p.department, icon: "building.2")
                            }
                            if !p.owner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                RBSS_Pill(text: p.owner, icon: "person")
                            }
                        }

                        Text("Updated \(p.updatedAt, style: .date)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )

                    RBSS_TextBlock(title: "Problem", text: p.problemStatement)
                    RBSS_TextBlock(title: "Goal", text: p.goalStatement)
                    RBSS_TextBlock(title: "Scope In", text: p.scopeIn)
                    RBSS_TextBlock(title: "Scope Out", text: p.scopeOut)

                } else {
                    RBSS_EmptyStateView(title: "Project not found", message: "It may have been deleted.")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Project")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Editor (minimal create)

@MainActor
private struct RBSS_ProjectEditorSheet: View {

    enum Mode { case create }

    let mode: Mode
    let onSave: (RBSixSigmaProject) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var owner: String = ""
    @State private var department: String = ""
    @State private var phase: RBSixSigmaPhase = .define

    @State private var problem: String = ""
    @State private var goal: String = ""
    @State private var scopeIn: String = ""
    @State private var scopeOut: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Project title", text: $title)
                    TextField("Owner", text: $owner)
                    TextField("Department", text: $department)

                    Picker("Phase", selection: $phase) {
                        ForEach(RBSixSigmaPhase.allCases, id: \.self) { p in
                            Text(p.title).tag(p)
                        }
                    }
                }

                Section("Define") {
                    RBSS_FormTextEditor(title: "Problem statement", text: $problem)
                    RBSS_FormTextEditor(title: "Goal statement", text: $goal)
                    RBSS_FormTextEditor(title: "Scope in", text: $scopeIn)
                    RBSS_FormTextEditor(title: "Scope out", text: $scopeOut)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let now = Date()
                        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        let project = RBSixSigmaProject(
                            title: trimmedTitle.isEmpty ? "Untitled Project" : trimmedTitle,
                            owner: owner,
                            department: department,
                            createdAt: now,
                            updatedAt: now,
                            problemStatement: problem,
                            goalStatement: goal,
                            scopeIn: scopeIn,
                            scopeOut: scopeOut,
                            phase: phase
                        )
                        onSave(project)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Small UI helpers

private struct RBSS_Pill: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption2.weight(.semibold))
            Text(text).font(.caption.weight(.semibold)).lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.primary.opacity(0.05), in: Capsule())
        .foregroundStyle(.secondary)
    }
}

private struct RBSS_TextBlock: View {
    let title: String
    let text: String

    var body: some View {
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(text).foregroundStyle(.secondary).textSelection(.enabled)
            }
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

private struct RBSS_FormTextEditor: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            TextEditor(text: $text)
                .frame(minHeight: 80)
        }
        .padding(.vertical, 4)
    }
}

private struct RBSS_EmptyStateView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(title).font(.headline.weight(.semibold))
            Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        SixSigmaProcessImprovementShiftView()
    }
    .environmentObject(
        RBSixSigmaStore(
            backend: RBSixSigmaStore.Backend.inMemory,
            seedIfEmpty: true
        )
    )
}
