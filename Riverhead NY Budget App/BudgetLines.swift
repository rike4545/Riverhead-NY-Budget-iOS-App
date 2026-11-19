//
//  BudgetLines.swift
//  Riverhead NY Budget App
//
//  Every account line of the newest budget the website has parsed line by line,
//  from the bundled BudgetHistory/budget-<year>-preliminary-lines.json (synced daily
//  from the website). For 2027 that is the Preliminary Budget, which the Town Board
//  adopted unchanged on November 17, 2026 (Resolution 2026-995, 5–0), with the 2026
//  Adopted Budget beside each line.
//
//  The lines are shown as the adopted budget only when they add up to that year's
//  adopted Summary page fund by fund (`isAdopted`). Otherwise screens keep the 2026
//  book bundled in the app.
//

import Foundation

struct BudgetLineRecord: Decodable, Hashable, Sendable {
    let account: String
    let fund: String
    let kind: String
    let name: String
    let page: Int?
    /// The prior year's adopted figure (2026 for the 2027 file).
    let adopted: Double?
    let request: Double?
    let tentative: Double?
    let preliminary: Double?

    var isExpenditure: Bool { kind == "expenditure" }

    /// "A01-3-3120-101-UNI-00000" → ["A01", "3", "3120", "101", "UNI", "00000"].
    private var parts: [String] { account.split(separator: "-").map(String.init) }
    var functionCode: String { parts.count > 2 ? parts[2] : "" }
    var objectCode: String { parts.count > 3 ? parts[3] : "" }
}

struct BudgetLinesSource: Decodable, Hashable, Sendable {
    let title: String
    let url: String
}

struct BudgetLinesFile: Decodable, Sendable {
    let year: Int
    let stage: String
    let source: BudgetLinesSource
    let lines: [BudgetLineRecord]
}

/// One value column of an account line, labelled with its year and stage.
struct BudgetLineValue: Hashable, Sendable {
    let label: String
    let value: Double?
    let isPrimary: Bool
}

/// An account line, from either the newest line file or the bundled 2026 book.
struct BudgetAccountLine: Identifiable, Hashable, Sendable {
    var id: String { accountNumber }
    let fundCode: String
    let functionCode: String
    let objectCode: String
    let accountNumber: String
    let description: String
    let page: Int?
    let columns: [BudgetLineValue]

    var primary: Double? { columns.first(where: \.isPrimary)?.value }
}

/// A department (function code) of one fund, with its account lines.
struct BudgetDepartment: Identifiable, Hashable, Sendable {
    var id: String { "\(fundCode)-\(functionCode)" }
    let fundCode: String
    let functionCode: String
    let name: String
    let year: Int
    let accounts: [BudgetAccountLine]

    var total: Double { accounts.compactMap(\.primary).reduce(0, +) }
}

enum BudgetLines {
    /// The newest line file in the bundle: the newest adopted year's, else none.
    static let file: BudgetLinesFile? = {
        guard let year = BudgetStages.currentYear else { return nil }
        for name in ["budget-\(year)-adopted-lines", "budget-\(year)-preliminary-lines"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "BudgetHistory")
                ?? Bundle.main.url(forResource: name, withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode(BudgetLinesFile.self, from: data) {
                return decoded
            }
        }
        return nil
    }()

    /// The adopted figure of each line: the Preliminary's, which the Board adopted unchanged.
    static func value(_ line: BudgetLineRecord) -> Double? { line.preliminary }

    /// True when the lines add up to the year's adopted Summary page in every fund, to the dollar.
    static let isAdopted: Bool = {
        guard let file, let doc = BudgetStages.doc(file.year, .adopted) else { return false }
        var spend: [String: Double] = [:]
        for line in file.lines where line.isExpenditure {
            spend[line.fund, default: 0] += value(line) ?? 0
        }
        guard !doc.funds.isEmpty else { return false }
        return doc.funds.allSatisfy { code, fund in abs((spend[code] ?? 0) - fund.appropriations) < 1 }
    }()

    /// The year the lines describe when they are the adopted budget, else nil.
    static var adoptedYear: Int? { isAdopted ? file?.year : nil }

    /// Where the lines come from, in words, for a source note.
    static var sourceNote: String? {
        guard let file, isAdopted else { return nil }
        return "\(file.source.title): the \(file.year) budget the Town Board adopted unchanged\(BudgetStages.adoptionNote(file.year).map { ", " + $0 } ?? "")."
    }

    /// The departments of one fund in the adopted line file, spending lines only.
    /// Names come from the 2026 book where it has the same function, else the lines' own prefix.
    static func departments(fundCode: String, namesByFunction: [String: String] = [:]) -> [BudgetDepartment] {
        guard let file, isAdopted else { return [] }
        let year = file.year
        let lines = file.lines.filter { $0.isExpenditure && $0.fund.caseInsensitiveCompare(fundCode) == .orderedSame }
        let grouped = Dictionary(grouping: lines, by: \.functionCode)
        return grouped.keys.sorted().map { fn in
            let rows = grouped[fn] ?? []
            let accounts = rows.map { line in
                BudgetAccountLine(
                    fundCode: line.fund,
                    functionCode: fn,
                    objectCode: line.objectCode,
                    accountNumber: line.account,
                    description: line.name,
                    page: line.page,
                    columns: [
                        BudgetLineValue(label: "\(year - 1) Adopted", value: line.adopted, isPrimary: false),
                        BudgetLineValue(label: "\(year) Department request", value: line.request, isPrimary: false),
                        BudgetLineValue(label: "\(year) Tentative", value: line.tentative, isPrimary: false),
                        BudgetLineValue(label: "\(year) Adopted", value: value(line), isPrimary: true),
                    ]
                )
            }
            let prefix = rows.first.map { String($0.name.split(separator: "-").first ?? "").trimmingCharacters(in: .whitespaces) } ?? fn
            return BudgetDepartment(fundCode: fundCode.uppercased(), functionCode: fn,
                                    name: namesByFunction[fn] ?? prefix, year: year, accounts: accounts)
        }
    }

    /// Every line by account number, for the adopted line file.
    static let byAccount: [String: BudgetLineRecord] = {
        guard let file, isAdopted else { return [:] }
        return Dictionary(file.lines.map { ($0.account, $0) }, uniquingKeysWith: { first, _ in first })
    }()

    /// A department's spending in the prior and newest adopted years, summed over its functions.
    /// `key` is "A01-3120" or "ES1-8110/8130".
    static func departmentTotals(key: String) -> (prior: Double, current: Double)? {
        guard let file, isAdopted else { return nil }
        let parts = key.split(separator: "-", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        let functions = Set(parts[1].split(separator: "/").map(String.init))
        let lines = file.lines.filter { $0.isExpenditure && $0.fund == parts[0] && functions.contains($0.functionCode) }
        guard !lines.isEmpty else { return nil }
        return (lines.reduce(0) { $0 + ($1.adopted ?? 0) }, lines.reduce(0) { $0 + (value($1) ?? 0) })
    }

    // MARK: - What moved from the prior adopted year

    enum CostGroup: String, CaseIterable {
        case personalServices = "Personal services (pay)"
        case benefits = "Employee benefits"
        case contractual = "Contractual and other"
        case equipment = "Equipment"
        case transfersAndDebt = "Transfers and debt service"
    }

    /// A spending line's group, from its account code: function 9000–9499 is benefits,
    /// 9500 and up transfers and debt; otherwise object 1xx is pay, 2xx equipment, the rest contractual.
    static func group(_ line: BudgetLineRecord) -> CostGroup {
        let fn = line.functionCode, ob = line.objectCode
        if fn.hasPrefix("9") { return fn < "9500" ? .benefits : .transfersAndDebt }
        if ob.hasPrefix("1") { return .personalServices }
        if ob.hasPrefix("2") { return .equipment }
        return .contractual
    }

    /// The change in one fund's spending from the prior adopted year, by group, largest first.
    static func changeByGroup(fundCode: String = "A01") -> [(group: CostGroup, change: Double)] {
        guard let file, isAdopted else { return [] }
        var out: [CostGroup: Double] = [:]
        for line in file.lines where line.isExpenditure && line.fund == fundCode {
            out[group(line), default: 0] += (value(line) ?? 0) - (line.adopted ?? 0)
        }
        return out.map { ($0.key, $0.value) }.sorted { abs($0.change) > abs($1.change) }
    }

    /// The change in one fund's spending on one function from the prior adopted year.
    static func change(fundCode: String, functionCode: String, group: CostGroup? = nil) -> Double? {
        guard let file, isAdopted else { return nil }
        let lines = file.lines.filter {
            $0.isExpenditure && $0.fund == fundCode && $0.functionCode == functionCode && (group == nil || self.group($0) == group)
        }
        guard !lines.isEmpty else { return nil }
        return lines.reduce(0) { $0 + (value($1) ?? 0) - ($1.adopted ?? 0) }
    }
}
