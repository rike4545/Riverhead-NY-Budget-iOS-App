//
//  BudgetDataBootstrapper.swift
//  Riverhead NY Budget App
//
//  One-call warm-up for the bundled 2026 CSV + historical PDF parsing.
//  Use from app startup or from ContentView.task { ... }.
//
//  Swift 6 • iOS 17+
//

import Foundation

@MainActor
enum BudgetDataBootstrapper {
    private static var didWarmUp: Bool = false
    private static var warmUpTask: Task<Void, Never>?

    static func warmUp(bundle: Bundle = .main) {
        Task(priority: .utility) {
            await warmUpAsync(bundle: bundle)
        }
    }

    static func warmUpAsync(bundle: Bundle = .main) async {
        if didWarmUp { return }
        if let warmUpTask {
            await warmUpTask.value
            return
        }

        let task = Task(priority: .utility) {
            // 2026 flat table CSV
            if Riverhead2026BudgetShift.lastLoadCount == 0 {
                _ = try? Riverhead2026BudgetShift.load()
            }

            // Historical PDFs (2021→2025)
            _ = BudgetHistoryShift.ensureLoaded(bundle: bundle)
        }

        let holder = Task(priority: .utility) { await task.value }
        warmUpTask = holder
        await holder.value
        warmUpTask = nil
        didWarmUp = true
    }
}
