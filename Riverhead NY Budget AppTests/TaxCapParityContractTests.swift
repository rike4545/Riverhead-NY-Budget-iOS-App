import Foundation
import Testing
@testable import Riverhead_NY_Budget_App

struct TaxCapParityContractTests {
    /// The published web/public/data/tax-cap.json with the prose shortened and
    /// implications and sources cut to two each. Both year series are verbatim
    /// and complete, because the gaps between them are the point.
    private static let canonical = #"""
    {
     "title": "New York's property-tax cap and Riverhead's overrides",
     "capBasics": {
      "law": "Chapter 97 of the Laws of 2011, codified for towns at General…",
      "limit": "The tax cap limits the property-tax levy, not a home's tax rate. The…",
      "override": "A town can lawfully adopt a levy above its calculated levy limit if…"
     },
     "finding": {
      "headline": "Riverhead's independent auditor reported that the Town exceeded its…",
      "cause": "The auditor traced the issue to a tax-cap calculation error beginning…",
      "auditQuote": "The Town exceeded the 2% property tax cap for the year ended December…",
      "correction": "For 2023 and subsequent adopted budgets shown here, the Town used an…",
      "correctionQuoteYear": 2023
     },
     "implications": [
      {
       "title": "The 2% figure is not the final Riverhead levy limit",
       "text": "For 2027, OSC has set the allowable levy growth factor at 2% for…"
      },
      {
       "title": "An override is authorization, not an outcome",
       "text": "A 60% override local law preserves the Board's legal ability to adopt…"
      }
     ],
     "levyContext": {
      "note": "General Fund tax levy by year. This is directional growth context…",
      "rows": [
       {
        "year": 2017,
        "levy": 36254400,
        "pct": 4.81
       },
       {
        "year": 2018,
        "levy": 37322300,
        "pct": 2.95
       },
       {
        "year": 2019,
        "levy": 38848800,
        "pct": 4.09
       },
       {
        "year": 2020,
        "levy": 40070000,
        "pct": 3.14
       },
       {
        "year": 2021,
        "levy": 41784500,
        "pct": 4.28
       },
       {
        "year": 2022,
        "levy": 40489138,
        "pct": -3.1
       },
       {
        "year": 2024,
        "levy": 44524150,
        "pct": 9.97
       },
       {
        "year": 2025,
        "levy": 48639479,
        "pct": 9.24
       }
      ]
     },
     "capStatus": [
      {
       "year": "2018",
       "status": "over-no-law",
       "label": "Above levy limit — no override law"
      },
      {
       "year": "2019",
       "status": "over-no-law",
       "label": "Above levy limit — no override law"
      },
      {
       "year": "2020",
       "status": "over-no-law",
       "label": "Above levy limit — no override law"
      },
      {
       "year": "2021",
       "status": "over-no-law",
       "label": "Above levy limit — no override law"
      },
      {
       "year": "2022",
       "status": "over-no-law",
       "label": "Above levy limit — no override law (auditor-confirmed)"
      },
      {
       "year": "2023",
       "status": "over-with-law",
       "label": "Above levy limit — override local law adopted"
      },
      {
       "year": "2024",
       "status": "over-with-law",
       "label": "Above levy limit — override local law adopted"
      },
      {
       "year": "2025",
       "status": "over-with-law",
       "label": "Above levy limit — override local law adopted"
      },
      {
       "year": "2026",
       "status": "over-with-law",
       "label": "Above levy limit — override local law adopted"
      }
     ],
     "sources": [
      "Town of Riverhead 2022 Audited Basic Financial Statements (tax-cap compliance note).",
      "Town of Riverhead 2021 audited financial reporting (origin of the carried-forward calculation error, as described by the auditor)."
     ]
    }
    """#

    private static func decoded() throws -> TaxCapParityDocument {
        try JSONDecoder().decode(TaxCapParityDocument.self, from: Data(canonical.utf8))
    }

    @Test func realCanonicalDocumentDecodes() throws {
        let d = try Self.decoded()
        #expect(d.title == "New York's property-tax cap and Riverhead's overrides")
        #expect(d.capStatus.count == 9)
        #expect(d.levyContext.rows.count == 8)
        #expect(!d.capBasics.law.isEmpty)
        #expect(!d.finding.auditQuote.isEmpty)
    }

    /// `year` is an Int in levyContext.rows and a String in capStatus. The
    /// published file is shaped that way, and a model that unified them would
    /// fail to decode one side or the other.
    @Test func yearIsAnIntInOneSeriesAndAStringInTheOther() throws {
        let d = try Self.decoded()
        let firstLevyYear: Int = d.levyContext.rows[0].year
        let firstStatusYear: String = d.capStatus[0].year
        #expect(firstLevyYear == 2017)
        #expect(firstStatusYear == "2018")
    }

    /// The trap that would fail silently. The two series cover different years,
    /// so zipping or indexing one against the other misaligns every row after
    /// the first gap. This asserts the gaps so a future join breaks loudly.
    @Test func theTwoSeriesDoNotAlignAndMustNeverBeJoined() throws {
        let d = try Self.decoded()

        let levyYears = Set(d.levyContext.rows.map { String($0.year) })
        let statusYears = Set(d.capStatus.map(\.year))

        // A cap status with no levy row.
        #expect(d.capStatusYearsWithoutALevyRow.sorted() == ["2023", "2026"])
        // A levy row with no cap status.
        let levyOnly = levyYears.subtracting(statusYears)
        #expect(levyOnly == ["2017"])
        // And so the counts differ: 8 against 9.
        #expect(d.levyContext.rows.count != d.capStatus.count)
    }

    /// The finding of the page: every year on record is above the limit. The
    /// statuses differ only in whether an override law was adopted, so green
    /// means lawful rather than within the limit.
    @Test func everyRecordedYearIsAboveTheLimit() throws {
        let d = try Self.decoded()
        let allOver = d.everyYearIsAboveTheLimit
        #expect(allOver)
        #expect(d.yearsWithoutOverrideLaw == 5)
        #expect(d.yearsWithOverrideLaw == 4)
        #expect(d.yearsWithoutOverrideLaw + d.yearsWithOverrideLaw == d.capStatus.count)
    }

    /// Only two status codes appear, and both are mapped. An unmapped code
    /// would render grey with a neutral glyph rather than vanishing.
    @Test func statusCodesAreMappedAndUnknownOnesDegradeGracefully() throws {
        let d = try Self.decoded()
        let codes = Set(d.capStatus.map(\.status))
        #expect(codes == ["over-no-law", "over-with-law"])

        // Asserted through the glyph rather than the colour. Comparing two
        // SwiftUI Colors is not a guarantee worth leaning on, and the glyph is
        // the part a reader relies on when colour is not available to them.
        #expect(TaxCapStatus.symbol("over-no-law") == "xmark.circle.fill")
        #expect(TaxCapStatus.symbol("over-with-law") == "checkmark.circle.fill")
        #expect(TaxCapStatus.symbol("something-new") == "circle.fill")
    }

    /// Labels come from the document, not from a table in Swift, so the
    /// resident-facing wording follows the web page.
    @Test func labelsAreReadFromTheDocument() throws {
        let d = try Self.decoded()
        let first = try #require(d.capStatus.first)
        #expect(first.label == "Above levy limit — no override law")
        let auditorConfirmed = try #require(d.capStatus.first { $0.year == "2022" })
        #expect(auditorConfirmed.label.contains("auditor-confirmed"))
    }

    /// Decoded so the document round-trips, deliberately not rendered: the
    /// correction sentence already says 2023 in words.
    @Test func correctionQuoteYearDecodesEvenThoughItIsNotRendered() throws {
        let d = try Self.decoded()
        #expect(d.finding.correctionQuoteYear == 2023)
        #expect(d.finding.correction.contains("2023"))
    }

    @Test func dollarsAreWholeAndGrouped() {
        #expect(TaxCapFormatting.dollars(36_254_400) == "$36,254,400")
        #expect(TaxCapFormatting.dollars(0) == "$0")
    }

    /// The sign is explicit because one year in the series is a decrease, and
    /// a bare "3.10%" beside eight increases would read as one.
    @Test func percentCarriesItsSignToTwoPlaces() {
        #expect(TaxCapFormatting.signedPercent(4.81) == "+4.81%")
        #expect(TaxCapFormatting.signedPercent(-3.10) == "-3.10%")
        #expect(TaxCapFormatting.signedPercent(0) == "+0.00%")
    }

    /// 2022 is the auditor-confirmed year the Town exceeded the limit, and its
    /// levy fell. Compliance and levy growth are different things, which is
    /// why the view keeps the two series in separate sections.
    @Test func theAuditorConfirmedYearIsAlsoAYearTheLevyFell() throws {
        let d = try Self.decoded()
        let row2022 = try #require(d.levyContext.rows.first { $0.year == 2022 })
        #expect(row2022.pct < 0)
        let status2022 = try #require(d.capStatus.first { $0.year == "2022" })
        #expect(status2022.status == "over-no-law")
    }

    /// A year is a label, not a quantity. Grouping it would print "2,017".
    @Test func yearsAreNeverRenderedWithAGroupingSeparator() {
        #expect(TaxCapFormatting.year(2017) == "2017")
        #expect(TaxCapFormatting.year(2026) == "2026")
        let grouped = TaxCapFormatting.year(2017).contains(",")
        #expect(!grouped)
    }

    @Test func theFormulaIsFiveOrderedSteps() {
        #expect(TaxCapFormula.steps.count == 5)
        #expect(TaxCapFormula.steps.map(\.id) == [1, 2, 3, 4, 5])
        let everyStepHasText = TaxCapFormula.steps.allSatisfy { !$0.title.isEmpty && !$0.detail.isEmpty }
        #expect(everyStepHasText)
    }
}
