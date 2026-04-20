//
//  RBSixSigmaStore.swift
//  Riverhead NY Budget App
//
//  Created by Bryan on 1/21/26.
//


//
//  RBSixSigmaStore.swift
//  Riverhead NY Budget App
//
//  Six Sigma (DMAIC) store — ObservableObject + JSON persistence (no SwiftData).
//  iOS 17+ • Swift 6
//
//  IMPORTANT:
//  - Ensure there is ONLY ONE definition of `RBSixSigmaStore` in your target.
//  - Do NOT also define RBSixSigmaStore inside RBSixSigmaPhase.swift.
//

import Foundation
import Combine

@MainActor
final class RBSixSigmaStore: ObservableObject {

    enum Backend: Hashable {
        case fileSystem
        case inMemory
    }

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: - Published state

    @Published var projects: [RBSixSigmaProject] = []
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var lastLoadedAt: Date?
    @Published private(set) var lastSavedAt: Date?
    @Published private(set) var lastSaveError: String?

    // MARK: - Private

    private let backend: Backend
    private let seedIfEmpty: Bool

    private var pendingSaveTask: Task<Void, Never>?
    private var isLoadedOnce = false

    // MARK: - Init

    init(backend: Backend = Backend.fileSystem, seedIfEmpty: Bool = true) {
        self.backend = backend
        self.seedIfEmpty = seedIfEmpty
        load()
    }

    // MARK: - Load

    func load() {
        if backend == Backend.inMemory {
            loadState = .loaded
            isLoadedOnce = true
            lastLoadedAt = Date()
            if seedIfEmpty, projects.isEmpty {
                projects = Self.seedProjects()
            }
            return
        }

        loadState = .loading
        let url = fileURL

        Task.detached(priority: .utility) { [url] in
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let decoded = try decoder.decode([RBSixSigmaProject].self, from: data)

                await MainActor.run {
                    self.projects = decoded
                    self.loadState = .loaded
                    self.lastLoadedAt = Date()
                    self.isLoadedOnce = true

                    if self.seedIfEmpty, self.projects.isEmpty {
                        self.projects = Self.seedProjects()
                        self.scheduleSave()
                    }
                }
            } catch {
                let ns = error as NSError
                let isMissingFile = (ns.domain == NSCocoaErrorDomain && ns.code == NSFileReadNoSuchFileError)

                await MainActor.run {
                    self.projects = []
                    self.isLoadedOnce = true
                    self.lastLoadedAt = Date()

                    if isMissingFile {
                        self.loadState = .loaded
                        if self.seedIfEmpty {
                            self.projects = Self.seedProjects()
                            self.scheduleSave()
                        }
                    } else {
                        self.loadState = .failed(error.localizedDescription)
                    }
                }
            }
        }
    }

    // MARK: - Save

    func saveNow() {
        lastSaveError = nil

        if backend == Backend.inMemory {
            lastSavedAt = Date()
            return
        }

        // Prevent overwrite before first load completes.
        guard isLoadedOnce else { return }

        let snapshot = projects
        let url = fileURL

        Task.detached(priority: .utility) { [snapshot, url] in
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(snapshot)

                // ✅ FIX: include attributes: nil
                try FileManager.default.createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true,
                    attributes: nil
                )

                try data.write(to: url, options: [.atomic])

                await MainActor.run {
                    self.lastSavedAt = Date()
                    self.lastSaveError = nil
                }
            } catch {
                await MainActor.run {
                    self.lastSaveError = error.localizedDescription
                }
            }
        }
    }

    /// Debounced save (default ~350ms).
    func scheduleSave(debounceSeconds: Double = 0.35) {
        pendingSaveTask?.cancel()

        // Don’t schedule before initial load completes for file system backend.
        guard backend != Backend.fileSystem || isLoadedOnce else { return }

        pendingSaveTask = Task { [weak self] in
            guard let self else { return }
            let ns = UInt64(max(0, debounceSeconds) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: ns)
            if Task.isCancelled { return }
            await MainActor.run { self.saveNow() }
        }
    }

    // MARK: - CRUD

    func addProject(_ project: RBSixSigmaProject) {
        projects.insert(project, at: 0)
        scheduleSave()
    }

    func deleteProject(id: UUID) {
        projects.removeAll { $0.id == id }
        scheduleSave()
    }

    func deleteProjects(at offsets: IndexSet) {
        projects.remove(atOffsets: offsets)
        scheduleSave()
    }

    func withProject(id: UUID, _ mutate: (inout RBSixSigmaProject) -> Void) {
        guard let idx = projects.firstIndex(where: { $0.id == id }) else { return }
        mutate(&projects[idx])
        projects[idx].updatedAt = Date()
        scheduleSave()
    }

    func upsert(_ project: RBSixSigmaProject) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            projects[idx] = project
        } else {
            projects.insert(project, at: 0)
        }
        scheduleSave()
    }

    // MARK: - Export/Import

    func exportJSONString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(projects) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func importJSON(_ json: String, replace: Bool = false) {
        guard let data = json.data(using: .utf8) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode([RBSixSigmaProject].self, from: data) else { return }

        if replace {
            projects = decoded
        } else {
            var byID: [UUID: RBSixSigmaProject] = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })
            for p in decoded { byID[p.id] = p }
            projects = Array(byID.values).sorted(by: { $0.updatedAt > $1.updatedAt })
        }

        scheduleSave()
    }

    // MARK: - Persistence path

    private var fileURL: URL {
        RBAppDirectories.applicationSupportDirectory(appFolder: "RiverheadNY")
            .appendingPathComponent("rb_sixsigma_projects.json", isDirectory: false)
    }

    // MARK: - Seed

    private static func seedProjects() -> [RBSixSigmaProject] {
        let now = Date()
        return [
            RBSixSigmaProject(
                title: "Reduce peak electricity demand",
                owner: "Town Admin",
                department: "Facilities",
                createdAt: now,
                updatedAt: now,
                problemStatement: "Monthly demand peaks are driving avoidable energy charges and volatility.",
                goalStatement: "Reduce peak demand by 10–15% without reducing services.",
                scopeIn: "Town Hall + key facilities; operating schedule; basic controls",
                scopeOut: "Major capital rebuilds",
                phase: .define,
                metrics: [
                    RBSixSigmaMetric(name: "Peak kW", unit: "kW"),
                    RBSixSigmaMetric(name: "kWh / month", unit: "kWh")
                ]
            ),
            RBSixSigmaProject(
                title: "Shorten permit processing cycle time",
                owner: "Planning",
                department: "Planning / Building",
                createdAt: now,
                updatedAt: now,
                problemStatement: "Permit cycle times are inconsistent, creating uncertainty for residents and businesses.",
                goalStatement: "Cut average cycle time by 20% while maintaining quality/compliance.",
                scopeIn: "Intake → review → decision workflow",
                scopeOut: "Policy changes outside department control",
                phase: .define,
                metrics: [RBSixSigmaMetric(name: "Avg cycle time", unit: "days")]
            )
        ]
    }
}
