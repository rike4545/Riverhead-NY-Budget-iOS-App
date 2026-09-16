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
        #expect(decoded.levyFunds.reduce(0) { $0 + $1.taxLevy2026 } == decoded.levyTotal)
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
