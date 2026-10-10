//
//  TaxCapParityView.swift
//  Riverhead NY Budget App
//
//  Native parity for Riverhead Budget Live's /tax-cap/ route.
//
//  Fetched from the published tax-cap.json. The subject is an auditor's
//  finding about the Town's statutory compliance, so the wording is the web
//  app's and not a paraphrase.
//
//  Document prose goes through Text(verbatim:) and accessibilityLabel(Text(
//  verbatim:)). A Text built from a string literal containing interpolation is
//  a LocalizedStringKey and gets markdown-parsed, so an asterisk or underscore
//  in published prose would silently restyle it — and the spoken label would
//  then differ from the visible text. Stating that here once rather than at
//  every call site, because a rule enforced by a comment per site gets missed.
//

import SwiftUI

struct TaxCapParityDocument: Decodable, Sendable {
    let title: String
    let capBasics: CapBasics
    let finding: Finding
    let implications: [Implication]
    let levyContext: LevyContext
    let capStatus: [CapStatusYear]
    let sources: [String]

    struct CapBasics: Decodable, Sendable {
        /// The statute and who publishes the formula. The web page does not
        /// render this field; `whatTheCapLimits(_:)` says why this view does.
        let law: String
        let limit: String
        let override: String
    }

    struct Finding: Decodable, Sendable {
        let headline: String
        let cause: String
        let auditQuote: String
        let correction: String
        /// 2023, which the `correction` sentence already states in words.
        /// Decoded so the document round-trips; not rendered, because printing
        /// it beside that sentence would just repeat it.
        ///
        /// Optional precisely because nothing renders it: a web-side cleanup
        /// dropping an unused key should not take the whole native screen down
        /// to a web view.
        let correctionQuoteYear: Int?
    }

    struct Implication: Decodable, Sendable {
        let title: String
        let text: String
    }

    struct LevyContext: Decodable, Sendable {
        /// The caveat, and it leads the section rather than following it: the
        /// note says this series cannot establish cap compliance.
        let note: String
        let rows: [LevyRow]
    }

    /// `year` is an Int here and a String in `capStatus`. That is how the
    /// published file is shaped, so each is modelled where it sits rather than
    /// coerced into a shared type that neither side actually uses.
    struct LevyRow: Decodable, Sendable {
        let year: Int
        let levy: Int
        let pct: Double
    }

    struct CapStatusYear: Decodable, Sendable {
        let year: String
        let status: String
        /// Resident-facing wording, carried in the document. The status codes
        /// map to colour and glyph in the web page's markup, but the words
        /// come from the data, so they are read rather than restated.
        let label: String
    }

    var yearsWithoutOverrideLaw: Int {
        capStatus.lazy.filter { $0.status == "over-no-law" }.count
    }

    var yearsWithOverrideLaw: Int {
        capStatus.lazy.filter { $0.status == "over-with-law" }.count
    }

    /// Every year in the published record is above the limit; the statuses
    /// differ only in whether an override law was adopted. The summary line is
    /// derived rather than asserted, so it cannot be wrong if a year is added.
    var everyYearIsAboveTheLimit: Bool {
        // The emptiness check is the point: allSatisfy is vacuously true on an
        // empty collection, and this sentence is a claim about a town's
        // statutory compliance. With no records it must not be made at all.
        !capStatus.isEmpty && capStatus.allSatisfy { $0.status.hasPrefix("over") }
    }

}

enum TaxCapStatus {
    struct Style: Sendable {
        let tint: Color
        /// Paired with the tint on purpose: a reader who does not get the
        /// colour still gets the mark.
        let symbol: String
    }

    /// Mirrors STATUS_STYLE in the web page's markup, which is not in the JSON.
    /// Red is "above the limit with no override law", green is "above the limit
    /// with one adopted" — lawful, which is not the same as within the limit.
    /// The section heading carries that distinction so colour never has to.
    ///
    /// One mapping rather than a switch per attribute: a third status code
    /// should not be addable in a way that gives it a colour but no glyph.
    static func style(_ status: String) -> Style {
        switch status {
        case "over-no-law":
            return Style(tint: .red, symbol: "xmark.circle.fill")
        case "over-with-law":
            return Style(tint: .green, symbol: "checkmark.circle.fill")
        default:
            return Style(tint: .secondary, symbol: "circle.fill")
        }
    }
}

/// The levy-limit formula, in the order the State Comptroller applies it.
///
/// Mirrored from the web page's markup rather than read from the JSON, because
/// it is not in any published file. It describes New York statute rather than
/// Riverhead's numbers, so it does not go stale the way a figure would — but it
/// will not follow an edit on the web side, and that is the trade.
///
/// It is carried because it is the page's actual argument: the familiar 2% is
/// one input among several, and a reader who takes 2% as the limit has the
/// wrong model of how the cap works.
///
/// This app also implements the sequence executably, in NYTaxCapInputs. These
/// steps are prose for a reader; that is arithmetic. If one changes, check the
/// other.
enum TaxCapFormula {
    struct Step: Identifiable, Sendable {
        let id: Int
        let title: String
        let detail: String
    }

    static let steps: [Step] = [
        .init(id: 1,
              title: "Start with the prior-year levy",
              detail: "OSC begins with the prior fiscal year levy, with specified reserve and tort adjustments where applicable."),
        .init(id: 2,
              title: "Apply tax-base growth",
              detail: "The Tax Department's tax-base-growth factor reflects quantity change such as new construction or newly taxable property."),
        .init(id: 3,
              title: "Apply PILOT and growth-factor inputs",
              detail: "Prior-year and coming-year PILOT receivables enter the formula, together with the allowable levy growth factor."),
        .init(id: 4,
              title: "Add available carryover",
              detail: "Unused levy-limit capacity from the prior year can carry forward, subject to the statutory limit."),
        .init(id: 5,
              title: "Apply transfers and exclusions",
              detail: "Transfers of function and qualifying retirement or tort exclusions can change the final adjusted levy limit.")
    ]
}

enum TaxCapFormatting {
    /// Whole dollars, as the web page formats this column.
    ///
    /// The locale is pinned. IntegerFormatStyle defaults to the device locale,
    /// so an unpinned `.number` prints "$36.254.400" in Germany and
    /// "$3,62,54,400" in en_IN — a US municipal figure that reads as a decimal
    /// to a US reader. These are United States dollars from a New York town's
    /// audited statements, so the grouping is fixed rather than localised. The
    /// repo pins the same way in MeetingsStore and CouncilScorecardView.
    /// Built once. Constructing the Locale and the format style per call made
    /// this the most expensive operation in the file, which is a poor trade for
    /// pinning the grouping. Statics are how the rest of the app holds
    /// formatters.
    private static let usGrouping: IntegerFormatStyle<Int> =
        .number.locale(Locale(identifier: "en_US_POSIX"))

    static func dollars(_ value: Int) -> String {
        "$" + value.formatted(usGrouping)
    }

    /// A year is a label, not a quantity: it must never pick up a grouping
    /// separator and print "2,017". Named rather than inlined so the intent is
    /// explicit and a regression is a failing test rather than a visual one.
    static func year(_ value: Int) -> String {
        String(value)
    }

    /// Signed, two decimals, matching the web table. The sign is explicit
    /// because one year in the series is a decrease, and a bare "3.10%" next
    /// to eight increases would read as one.
    static func signedPercent(_ value: Double) -> String {
        // "%+" would print "+0.00%" for a flat year, asserting a rise that did
        // not happen. Only a real increase gets a plus, which is how
        // BudgetHistoryParityViews already does it.
        let prefix = value > 0 ? "+" : ""
        return prefix + String(format: "%.2f%%", value)
    }
}

enum TaxCapParityClient {
    static let dataURL = URL(string: "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/data/tax-cap.json")!
    static let livePageURL = URL(string: "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/tax-cap/")!

    static func load() async throws -> TaxCapParityDocument {
        var request = URLRequest(url: dataURL)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(TaxCapParityDocument.self, from: data)
    }
}

@MainActor
struct NativeTaxCapParityView: View {
    @State private var document: TaxCapParityDocument?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let document {
                content(document)
            } else if loadFailed {
                WebContentView(url: TaxCapParityClient.livePageURL, title: "Tax Cap")
            } else {
                ProgressView("Loading the cap record…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Tax Cap")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard document == nil, !loadFailed else { return }
            do {
                document = try await TaxCapParityClient.load()
            } catch is CancellationError {
                // Leaving the view cancels the task. Treating that as a failure
                // would pin this screen to the web fallback for the life of the
                // view, on a working connection, with no way back.
            } catch {
                loadFailed = true
            }
        }
    }

    /// Rows with a rule between them and none above the first. Three sections
    /// spelled this out separately before.
    @ViewBuilder
    private func divided<Item, Row: View>(
        _ items: [Item],
        @ViewBuilder row: @escaping (Item) -> Row
    ) -> some View {
        ForEach(items.indices, id: \.self) { index in
            if index > items.startIndex { Divider() }
            row(items[index])
        }
    }

    private func content(_ data: TaxCapParityDocument) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header(data)
                complianceRecord(data)
                auditorFinding(data)
                whatTheCapLimits(data)
                formula()
                implications(data)
                levyGrowth(data)
                sources(data)
            }
            .padding(16)
        }
    }

    // MARK: - Sections

    /// The auditor's headline is the lede. It is the page's finding, and
    /// burying it under an explanation of the statute would invert the story.
    private func header(_ data: TaxCapParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.title)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            Text(data.finding.headline)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .riverheadCard(accentEdge: .red)
    }

    private func complianceRecord(_ data: TaxCapParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(data.capStatus.count == 1
                     ? "1 budget year on record"
                     : String(data.capStatus.count) + " budget years on record")
                    .font(.headline)
                // Derived, not asserted. Colour alone must not have to carry
                // "green means lawful, not within the limit", so the heading
                // says it in words.
                if data.everyYearIsAboveTheLimit {
                    Text("Every one is above the calculated levy limit. \(data.yearsWithoutOverrideLaw) without an override local law, \(data.yearsWithOverrideLaw) with one adopted.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            divided(data.capStatus, row: statusRow)
        }
        .riverheadCard()
    }

    private func statusRow(_ row: TaxCapParityDocument.CapStatusYear) -> some View {
        let style = TaxCapStatus.style(row.status)

        return HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: style.symbol)
                .font(.caption)
                .foregroundStyle(style.tint)
            Text(row.year)
                .font(.caption.weight(.bold))
                .monospacedDigit()
            Text(row.label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: "\(row.year): \(row.label)"))
    }

    private func auditorFinding(_ data: TaxCapParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("What the auditor found", systemImage: "doc.text.magnifyingglass")
                .font(.subheadline.weight(.semibold))

            Text(data.finding.cause)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)

            // Set as a quotation rather than body text: these are the
            // auditor's words about the Town's compliance, and the reader
            // should be able to see where the app stops and the source starts.
            HStack(alignment: .top, spacing: 10) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.35))
                    .frame(width: 2)
                Text(verbatim: "\u{201C}\(data.finding.auditQuote)\u{201D}")
                    .font(.caption.italic())
            }
            .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Later treatment")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(data.finding.correction)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 2)
        }
        .riverheadCard(accentEdge: .orange)
    }

    private func whatTheCapLimits(_ data: TaxCapParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What the cap actually limits")
                .font(.headline)

            // `limit` first: it corrects the common misreading, that the cap
            // caps a tax rate or that 2% is the limit.
            Text(data.capBasics.limit)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)

            labelled("The override", data.capBasics.override)

            // The web page does not render capBasics.law. Rendered here: it is
            // the statutory citation the rest of the page rests on, it is in
            // the canonical file, and an app built around provenance should
            // show the law it is citing rather than omit it for visual parity.
            labelled("The statute", data.capBasics.law)
        }
        .riverheadCard()
    }

    private func formula() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("How the limit is actually calculated")
                    .font(.headline)
                Text("The allowable growth factor is one input of several.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(TaxCapFormula.steps) { step in
                HStack(alignment: .top, spacing: 10) {
                    // Fixed-width numeral slot so every step's text shares a
                    // left edge regardless of the digit.
                    Text("\(step.id)")
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(RiverheadTheme.accent)
                        .frame(width: 18, alignment: .trailing)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title)
                            .font(.caption.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(step.detail)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .riverheadCard(accentEdge: RiverheadTheme.brandTeal)
    }

    private func implications(_ data: TaxCapParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What this means")
                .font(.headline)

            ForEach(Array(data.implications.enumerated()), id: \.offset) { index, item in
                if index > 0 { Divider() }
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.caption.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(item.text)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .riverheadCard()
    }

    /// Kept visually and verbally separate from the compliance record above.
    /// The document's own note says this series cannot establish compliance,
    /// and the record bears that out: 2022 is the auditor-confirmed year the
    /// Town exceeded the limit, and its levy fell by 3.10%.
    ///
    /// Which is also why no row here is tinted by its percentage. The web page
    /// emphasises rows above 2% inside a chart it labels as growth context;
    /// one card below a compliance record, that threshold reads as a verdict,
    /// and against the real data it is the wrong one. It leaves 2022 unmarked —
    /// the one auditor-confirmed breach, because the levy fell that year —
    /// while marking 2024 and 2025, which were lawful, and 2017, which has no
    /// compliance record at all. This page exists to establish that 2% is not
    /// the limit, so a 2% threshold must not be what tints its table.
    private func levyGrowth(_ data: TaxCapParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("General Fund levy growth")
                    .font(.headline)
                Text(data.levyContext.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            divided(data.levyContext.rows, row: levyRow)
        }
        .riverheadCard()
    }

    private func levyRow(_ row: TaxCapParityDocument.LevyRow) -> some View {
        // Formatted once each. These were computed twice per row — once for the
        // cell, once for the spoken label — which also let the two drift.
        let year = TaxCapFormatting.year(row.year)
        let dollars = TaxCapFormatting.dollars(row.levy)
        let percent = TaxCapFormatting.signedPercent(row.pct)

        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(year)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
            Spacer(minLength: 8)
            Text(dollars)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            // minWidth, not width: the six-character values align today, and a
            // future "+10.00%" should widen rather than truncate.
            Text(percent)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .frame(minWidth: 66, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: "\(year): levy \(dollars), change \(percent)"))
    }

    /// The web page replaces these with per-claim provenance components built
    /// in its markup. Rendered here from the data: these are the documents
    /// the finding rests on, and dropping them to match the web page's
    /// mechanism would cost the reader the sourcing.
    private func sources(_ data: TaxCapParityDocument) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Sources")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            ForEach(data.sources.indices, id: \.self) { index in
                Text(verbatim: data.sources[index])
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .riverheadCard()
    }

    private func labelled(_ label: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(body)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
