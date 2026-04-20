//
//  BudgetHistoryShift.swift
//  Riverhead NY Budget App
//
//  Parses prior-year SUMMARY tables directly from bundled PDFs (2021→2025)
//  and exposes typed accessors + historical series for levy/appropriations.
//
//  Regenerated with more robust parsing of SUMMARY tables and a simple
//  load/ensureLoaded cache.
//

import Foundation
import PDFKit

// MARK: - Public Models


// MARK: - Shift (static-only)

public enum BudgetHistoryShift {
    // Stored properties must be static inside an enum.
    private static var byYear: [Int: [BHFundYearRow]] = [:]

    /// Years successfully loaded from PDFs (sorted)
    public private(set) static var lastLoadedYears: [Int] = []

    /// Total number of parsed SUMMARY rows across all years.
    public private(set) static var totalRowsLoaded: Int = 0

    /// Whether we've successfully attempted loading already.
    private static var isLoaded: Bool = false

    // Update the filenames to match your bundle exactly.
    // These are relative to Bundle.resourceURL.
    private static let knownYearDocs: [(year: Int, filename: String)] = [
        (2021, "2021 Adopted Budget (PDF).pdf"),
        (2022, "2022 Tentative Budget (PDF).pdf"),
        (2023, "2023 Tentative Budget (PDF).pdf"),
        (2024, "2024 Adopted Budget (PDF).pdf"),
        (2025, "2025 Tentative Budget (PDF).pdf")
        // Add 2026 when you have a SUMMARY PDF:
        // (2026, "2026 Tentative Budget (PDF).pdf")
    ]

    // MARK: - Loading

    /// Force a reload of all known PDFs from the given bundle.
    /// Returns the total number of parsed SUMMARY rows.
    @discardableResult
    public static func load(bundle: Bundle = .main) -> Int {
        byYear.removeAll(keepingCapacity: true)
        lastLoadedYears.removeAll(keepingCapacity: true)
        totalRowsLoaded = 0
        isLoaded = false

        guard let bundleRoot = bundle.resourceURL else { return 0 }

        for (year, name) in knownYearDocs {
            let url = bundleRoot.appendingPathComponent(name)

            guard FileManager.default.fileExists(atPath: url.path),
                  let pdf = PDFDocument(url: url) else {
                continue
            }

            let text = extractAllText(pdf: pdf)
            let rows = parseSummaryRows(from: text, year: year)

            guard !rows.isEmpty else { continue }

            byYear[year] = rows
            lastLoadedYears.append(year)
            totalRowsLoaded += rows.count
        }

        lastLoadedYears.sort()
        isLoaded = !byYear.isEmpty
        return totalRowsLoaded
    }

    /// Convenience: load once, no-op on subsequent calls.
    @discardableResult
    public static func ensureLoaded(bundle: Bundle = .main) -> Int {
        if isLoaded { return totalRowsLoaded }
        return load(bundle: bundle)
    }

    // MARK: - Queries

    /// All parsed SUMMARY rows for a given year (empty if none).
    public static func rows(for year: Int, bundle: Bundle = .main) -> [BHFundYearRow] {
        ensureLoaded(bundle: bundle)
        return byYear[year] ?? []
    }

    /// All years for which we have parsed data (sorted).
    public static func availableYears(bundle: Bundle = .main) -> [Int] {
        ensureLoaded(bundle: bundle)
        return lastLoadedYears
    }

    /// Best-effort series by fund name (lenient matching).
    /// Returns year->Decimal for levy and appropriations.
    ///
    /// Matching strategy:
    ///  - If the displayName starts with something that looks like a fund code (e.g. "A", "DA", "DB1"),
    ///    we try to match by code.
    ///  - Otherwise we normalize fund names (remove "fund", "district", punctuation) and
    ///    match equality or substring.
    public static func historicalSeries(forFundName displayName: String,
                                        bundle: Bundle = .main)
    -> (levy: [Int: Decimal], app: [Int: Decimal]) {

        ensureLoaded(bundle: bundle)

        let target = normalize(displayName)
        let maybeCode = codeToken(from: displayName)

        var levy: [Int: Decimal] = [:]
        var app:  [Int: Decimal] = [:]

        for (year, rows) in byYear {
            if let row = rows.first(where: { r in
                if let code = maybeCode,
                   !code.isEmpty,
                   r.fundCode.caseInsensitiveCompare(code) == .orderedSame {
                    return true
                }

                let n = normalize(r.fundName)
                return n == target || n.contains(target) || target.contains(n)
            }) {
                if let L = row.taxLevy { levy[year] = L }
                if let A = row.appropriations { app[year] = A }
            }
        }
        return (levy, app)
    }

    /// Direct series lookup by fund code (e.g. "A", "DA", "DB", "SS").
    public static func historicalSeries(forFundCode code: String,
                                        bundle: Bundle = .main)
    -> (levy: [Int: Decimal], app: [Int: Decimal]) {

        ensureLoaded(bundle: bundle)

        let target = code.uppercased()
        var levy: [Int: Decimal] = [:]
        var app:  [Int: Decimal] = [:]

        for (year, rows) in byYear {
            if let row = rows.first(where: { r in
                r.fundCode.uppercased() == target
            }) {
                if let L = row.taxLevy { levy[year] = L }
                if let A = row.appropriations { app[year] = A }
            }
        }
        return (levy, app)
    }
}

// MARK: - Parsing (PDF → SUMMARY rows)

private func extractAllText(pdf: PDFDocument) -> String {
    var out = ""
    for i in 0..<pdf.pageCount {
        if let page = pdf.page(at: i), let s = page.string {
            out.append(s)
            out.append("\n\n")
        }
    }
    return out
}

/// Pull only the SUMMARY block(s) and parse fund rows.
///
/// This is intentionally defensive:
///  - Finds the first occurrence of "summary" (or "summary of funds").
///  - Locates a header row that looks like "Fund Description ...".
///  - Parses subsequent lines as fund rows until we hit a TOTAL/GRAND TOTAL or
///    a clearly non-row line after seeing some data.
///  - Dedupes by fund code (or normalized name if there is no code).
private func parseSummaryRows(from fullText: String, year: Int) -> [BHFundYearRow] {
    let lower = fullText.lowercased()

    // Prefer a more specific marker if present
    let summaryRange =
        lower.range(of: "summary of funds") ??
        lower.range(of: "summary of all funds") ??
        lower.range(of: "summary")

    guard let sumRange = summaryRange else { return [] }

    // Take everything from the first "summary" onward
    let tail = String(fullText[sumRange.lowerBound...])

    // Normalize lines
    let lines = tail
        .components(separatedBy: .newlines)
        .map {
            $0.replacingOccurrences(
                of: #"\s+"#,
                with: " ",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespaces)
        }
        .filter { !$0.isEmpty }

    // Find the header row (e.g. "FUND DESCRIPTION   APPROPRIATIONS   EST. REVENUES   ...")
    let headerIndex = lines.firstIndex(where: { line in
        let l = line.lowercased()
        return l.hasPrefix("fund") && l.contains("description")
    })

    // If we can't find a header, fall back to a simpler heuristic.
    if headerIndex == nil {
        return parseSummaryRowsFallback(lines: lines, year: year)
    }

    var rawRows: [BHFundYearRow] = []
    var started = false

    // Start AFTER the header row
    for line in lines[(headerIndex! + 1)...] {
        let l = line.lowercased()

        // Stop at totals/other sections once we already started seeing rows
        if started && (l.hasPrefix("total")
                       || l.contains("grand total")
                       || l.contains("summary of")) {
            break
        }

        // Some PDFs repeat "Fund Description..." mid-page; skip those
        if l.hasPrefix("fund") && l.contains("description") {
            continue
        }

        if let (code, name, numbers) = splitFundRow(line) {
            let take = Array(numbers.suffix(4))
            let A  = take.count >= 4 ? money(take[take.count - 4]) : nil
            let ER = take.count >= 3 ? money(take[take.count - 3]) : nil
            let FB = take.count >= 2 ? money(take[take.count - 2]) : nil
            let L  = take.count >= 1 ? money(take[take.count - 1]) : nil

            rawRows.append(BHFundYearRow(
                year: year,
                fundCode: code,
                fundName: name,
                appropriations: A,
                estRevenues: ER,
                appropFundBalance: FB,
                taxLevy: L
            ))

            started = true
        } else if started {
            // Once we've successfully parsed some rows, treat a non-parsable
            // line as the end of the table; this avoids overrunning into the
            // next section when layout is odd.
            break
        }
    }

    return dedupeFundRows(rawRows)
}

/// Fallback used if we can't find the header row cleanly.
/// This is closer to the original behavior but with safer stopping rules.
private func parseSummaryRowsFallback(lines: [String], year: Int) -> [BHFundYearRow] {
    var rawRows: [BHFundYearRow] = []
    var hitHeader = false

    for line in lines {
        let l = line.lowercased()

        if !hitHeader {
            if l.hasPrefix("fund") && l.contains("description") {
                hitHeader = true
            }
            continue
        }

        if l.hasPrefix("total") || l.contains("grand total") {
            break
        }

        if let (code, name, numbers) = splitFundRow(line) {
            let take = Array(numbers.suffix(4))
            let A  = take.count >= 4 ? money(take[take.count - 4]) : nil
            let ER = take.count >= 3 ? money(take[take.count - 3]) : nil
            let FB = take.count >= 2 ? money(take[take.count - 2]) : nil
            let L  = take.count >= 1 ? money(take[take.count - 1]) : nil

            rawRows.append(BHFundYearRow(
                year: year,
                fundCode: code,
                fundName: name,
                appropriations: A,
                estRevenues: ER,
                appropFundBalance: FB,
                taxLevy: L
            ))
        } else if !rawRows.isEmpty {
            break
        }
    }

    return dedupeFundRows(rawRows)
}

// Deduplicate by fund code (or normalized name if no code).
private func dedupeFundRows(_ rows: [BHFundYearRow]) -> [BHFundYearRow] {
    var seen = Set<String>()
    var unique: [BHFundYearRow] = []

    for r in rows {
        let key = r.fundCode.isEmpty
            ? normalize(r.fundName)
            : r.fundCode.uppercased()
        if seen.insert(key).inserted {
            unique.append(r)
        }
    }
    return unique
}

// MARK: - Row splitting helpers

/// Split a candidate SUMMARY line into (fundCode, fundName, numberTokens).
///
/// Handles cases like:
///   "A   GENERAL FUND        60,000,000   30,000,000   5,000,000   25,000,000"
///   "DA  HIGHWAY - TOWN-OUTSIDE-VILLAGE  ..."
///
/// Codes can be letters only ("A", "DA", "DB") or letters + digits ("SS1").
private func splitFundRow(_ line: String) -> (String, String, [String])? {
    let tokens = line.split(separator: " ").map(String.init)
    guard tokens.count >= 3 else { return nil }

    var code = ""
    var nameTokens: [String] = []
    var numberTokens: [String] = []

    var i = 0

    // More permissive code detection: 1–3 uppercase letters + optional 0–3 digits.
    if tokens[0].range(of: #"^[A-Z]{1,3}\d{0,3}$"#,
                        options: .regularExpression) != nil {
        code = tokens[0]
        i = 1
    }

    // Everything until the first "money-ish" token is treated as the description.
    while i < tokens.count {
        let t = tokens[i]
        if isMoneyish(t) {
            numberTokens = Array(tokens[i...])
            break
        } else {
            nameTokens.append(t)
            i += 1
        }
    }

    let name = nameTokens.joined(separator: " ").normalizedTitle()
    guard !name.isEmpty, !numberTokens.isEmpty else { return nil }
    return (code, name, numberTokens)
}

// MARK: - Text helpers

private func codeToken(from s: String) -> String? {
    let first = s.split(separator: " ").first.map(String.init) ?? ""
    return first.range(of: #"^[A-Z]{1,3}\d{0,3}$"#,
                       options: .regularExpression) != nil ? first : nil
}

private func normalize(_ s: String) -> String {
    s.lowercased()
        .replacingOccurrences(of: "district", with: "")
        .replacingOccurrences(of: "fund", with: "")
        .replacingOccurrences(of: "•", with: " ")
        .replacingOccurrences(of: "(", with: " ")
        .replacingOccurrences(of: ")", with: " ")
        .replacingOccurrences(of: "-", with: " ")
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func isMoneyish(_ s: String) -> Bool {
    s.range(of: #"^\(?\$?\d[\d,]*(\.\d+)?\)?$"#,
            options: .regularExpression) != nil
}

private func money(_ s: String?) -> Decimal? {
    guard var raw = s?.trimmingCharacters(in: .whitespacesAndNewlines),
          !raw.isEmpty else { return nil }

    var negative = false
    if raw.hasPrefix("(") && raw.hasSuffix(")") {
        negative = true
        raw = String(raw.dropFirst().dropLast())
    }

    raw = raw
        .replacingOccurrences(of: "$", with: "")
        .replacingOccurrences(of: ",", with: "")

    guard let d = Decimal(string: raw) else { return nil }
    return negative ? (d * Decimal(-1)) : d
}

private extension String {
    func normalizedTitle() -> String {
        let s = self.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
        return s.trimmingCharacters(in: CharacterSet(charactersIn: " .,:;-"))
    }
}
