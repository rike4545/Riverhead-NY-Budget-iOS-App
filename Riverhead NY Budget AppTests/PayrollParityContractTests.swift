import Foundation
import Testing
@testable import Riverhead_NY_Budget_App

struct PayrollParityContractTests {
    @Test func sharedPayrollBundleCoversCurrentWebYears() throws {
        guard let url = Bundle.main.url(forResource: "payroll-records", withExtension: "json") else {
            Issue.record("Missing payroll-records.json from test bundle")
            return
        }
        let data = try Data(contentsOf: url)
        struct File: Decodable { let count: Int; let records: [Row] }
        struct Row: Decodable { let y: Int }
        let decoded = try JSONDecoder().decode(File.self, from: data)
        #expect(decoded.count == decoded.records.count)
        #expect(decoded.count == 4_444)
        #expect(decoded.records.map(\.y).min() == 2018)
        #expect(decoded.records.map(\.y).max() == 2025)
    }

    @Test func actualPayrollContractDecodesCompactWebSchema() throws {
        let json = #"""
        {"count":1,"records":[{"y":2025,"n":"Example Employee","d":"Police","t":"Police Officer","c":"PBA","u":"PBA","r":100000,"o":25000,"g":130000,"f":"00123","k":[1000,2000,0,0,2000],"i":""}]}
        """#
        struct File: Decodable { let count: Int; let records: [Row] }
        struct Row: Decodable {
            let y: Int; let n: String; let d: String; let t: String; let c: String; let u: String
            let r: Double; let o: Double; let g: Double; let f: String?; let k: [Double]?; let i: String?
        }
        let decoded = try JSONDecoder().decode(File.self, from: Data(json.utf8))
        #expect(decoded.count == 1)
        #expect(decoded.records[0].g == 130_000)
        #expect(decoded.records[0].g - decoded.records[0].r - decoded.records[0].o == 5_000)
    }

    @Test func authorizedSalaryContractKeepsActualAndAuthorizedSeparate() throws {
        let json = #"""
        {"source":{"title":"Town Board resolution","url":"https://example.com"},"year":2026,"note":"Base salary only","count":1,"totalAuthorized":120000,"byGroup":[{"group":"PBA","headcount":1,"authorized":120000}],"records":[{"name":"Example Employee","grade":"","title":"Police Officer","department":"Police","group":"PBA","resolution":"2026-1","annual":120000,"hourly":null,"isStipend":false,"actualYear":2025,"actualRegular":110000,"actualOvertime":20000,"actualGross":135000}]}
        """#
        struct File: Decodable {
            struct Source: Decodable { let title: String; let url: String }
            struct Group: Decodable { let group: String; let headcount: Int; let authorized: Double }
            struct Row: Decodable { let annual: Double; let actualYear: Int?; let actualGross: Double? }
            let source: Source; let year: Int; let note: String; let count: Int; let totalAuthorized: Double; let byGroup: [Group]; let records: [Row]
        }
        let decoded = try JSONDecoder().decode(File.self, from: Data(json.utf8))
        #expect(decoded.records[0].annual == 120_000)
        #expect(decoded.records[0].actualGross == 135_000)
        #expect(decoded.records[0].actualYear == 2025)
    }
}
