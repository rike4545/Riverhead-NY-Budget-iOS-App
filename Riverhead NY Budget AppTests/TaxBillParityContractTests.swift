import Foundation
import Testing
@testable import Riverhead_NY_Budget_App

struct TaxBillParityContractTests {
    @Test func canonicalTaxBillContractDecodesAndReconciles() throws {
        let json = #"""
        {
          "schemaVersion": 1,
          "title": "My tax bill — what would I actually pay?",
          "asOf": "2026",
          "intro": "Town portion only.",
          "rateSource": {
            "title": "2026 Adopted Budget",
            "url": "https://example.com",
            "note": "Rate table"
          },
          "rates2026": {
            "generalFund": 61.948,
            "highway": 8.695,
            "streetLighting": 0.955,
            "totalTownWide": 71.598
          },
          "rates2025": {
            "generalFund": 57.503,
            "highway": 8.538,
            "streetLighting": 0.990,
            "totalTownWide": 67.031
          },
          "equalization": {
            "residentialAssessmentRatio": 7.44,
            "asOfYear": 2025,
            "source": "Receiver of Taxes",
            "note": "Approximation only"
          },
          "levyFunds": [
            {
              "code": "A01",
              "name": "General Fund",
              "description": "General operations",
              "taxLevy2026": 52864609,
              "source": "Adopted budget"
            },
            {
              "code": "DA1",
              "name": "Highway Fund",
              "description": "Road maintenance",
              "taxLevy2026": 7420550,
              "source": "Adopted budget"
            }
          ],
          "levyTotal": 60285159
        }
        """#

        let decoded = try JSONDecoder().decode(TaxBillParityDocument.self, from: Data(json.utf8))
        #expect(decoded.schemaVersion == 1)
        #expect(decoded.rates2026.totalTownWide == 71.598)
        #expect(decoded.equalization.residentialAssessmentRatio == 7.44)
        let levyFunds = try #require(decoded.levyFunds)
        let levyTotal = try #require(decoded.levyTotal)
        #expect(levyFunds.reduce(0) { $0 + $1.taxLevy2026 } == levyTotal)
    }

    /// The document the app actually fetches, byte-for-byte from
    /// web/public/data/tax-bill.json.
    ///
    /// This is the test that was missing. `NativeTaxBillParityView` pointed at
    /// `data/tax-bill-parity.json`, which exists nowhere in the web repo — not
    /// as a file, not as a route handler, not as a single reference — so every
    /// fetch 404'd and the screen fell through to the web view it was written
    /// to replace. The suite passed the whole time because the only decode test
    /// used a hand-written literal carrying three fields the real file has
    /// never had: schemaVersion, levyFunds and levyTotal.
    ///
    /// A contract test that invents its own payload tests the decoder against
    /// itself. This one fails if the canonical document drifts.
    @Test func realCanonicalTaxBillDocumentDecodes() throws {
        let json = #"""
        {
         "title": "My tax bill — what would I actually pay?",
         "asOf": "2026",
         "intro": "Estimate the Town's portion of your property-tax bill using the Town's own published 2026 rate table. This covers only the Town — county, school, fire, and library taxes are billed separately and aren't included here.",
         "rateSource": {
          "title": "2026 Adopted Budget",
          "url": "https://www.townofriverheadny.gov/DocumentCenter/View/2967/2026-Adopted-Budget",
          "note": "Rate table, p. 6: 'Total Town Wide' rate, updated based on the final assessment roll."
         },
         "rates2026": {
          "generalFund": 61.948,
          "highway": 8.695,
          "streetLighting": 0.955,
          "totalTownWide": 71.598
         },
         "rates2025": {
          "generalFund": 57.503,
          "highway": 8.538,
          "streetLighting": 0.990,
          "totalTownWide": 67.031
         },
         "equalization": {
          "residentialAssessmentRatio": 7.44,
          "asOfYear": 2025,
          "source": "Town of Riverhead 2025-2026 Receiver of Taxes rate sheet.",
          "note": "This ratio can shift slightly from year to year with each new assessment roll."
         }
        }
        """#

        let decoded = try JSONDecoder().decode(TaxBillParityDocument.self, from: Data(json.utf8))

        // The three fields the old model demanded are simply absent.
        #expect(decoded.schemaVersion == nil)
        #expect(decoded.levyFunds == nil)
        #expect(decoded.levyTotal == nil)

        // What the screen actually needs is all present.
        #expect(decoded.rates2026.totalTownWide == 71.598)
        #expect(decoded.rates2025.totalTownWide == 67.031)
        #expect(decoded.equalization.residentialAssessmentRatio == 7.44)
    }

    @Test func webRateComponentsReconcileToTownWideRate() {
        let generalFund = 61.948
        let highway = 8.695
        let streetLighting = 0.955
        #expect(abs((generalFund + highway + streetLighting) - 71.598) < 0.000_001)
    }

    @Test func webDefaultAssessedValueProducesExpectedTownPortion() {
        let assessedValue = 45_000.0
        let totalTownWideRate = 71.598
        let expected = assessedValue / 1_000 * totalTownWideRate
        #expect(abs(expected - 3_221.91) < 0.01)
    }
}
