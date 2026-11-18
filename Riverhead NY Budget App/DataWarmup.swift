//
//  DataWarmup.swift
//  Riverhead NY Budget App
//
//  The largest bundled datasets (payroll-records.json, about 840 KB, and
//  supplement-lines.json, about 670 KB) are decoded lazily the first time a
//  screen reads them. That first read happened on the main thread, inside a
//  view's body, and froze the screen while it decoded. Warming them here, on a
//  low-priority background task right after launch, does the work before
//  anyone opens those screens. Each is a `static let`, which Swift initializes
//  exactly once and safely across threads, so a screen that gets there first
//  simply waits for the same single decode.
//

import Foundation

enum DataWarmup {
    static func start() {
        Task.detached(priority: .utility) {
            _ = PayrollData.rows.count
            _ = OvertimeStaffing.trends.count
            _ = OvertimeStaffing.individualCheck.recordsChecked
            _ = SeparationPay.summary
            _ = SupplementData.lines.count
            _ = SupplementData.outliers
            _ = SupplementData.reductions
            _ = SupplementData.history
        }
    }
}
