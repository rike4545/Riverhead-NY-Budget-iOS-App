import Testing
@testable import Riverhead_NY_Budget_App

/// The proposed 2027-2030 police schedules follow the pattern the agenda packet
/// shows, and the incentive payout lines add up to the transfer. Mirrors
/// web/scripts/verify-police-stipulations.mjs.
struct PoliceContracts2027Tests {

    @Test func everyScheduleRowRises3Point75PercentAYear() {
        let salaries = PoliceContracts2027.pbaOfficers + PoliceContracts2027.pbaDetectives + PoliceContracts2027.soaRanks
        for row in salaries {
            let r = row.rates
            #expect(r.count == 5)
            let steps = [(r[1] - PoliceContracts2027.bodycam2027) / r[0], r[2] / r[1], r[3] / r[2], r[4] / r[3]]
            for s in steps { #expect(abs(s - 1 - PoliceContracts2027.impliedRaise) < 0.00002, "\(row.title)") }
        }
        for row in PoliceContracts2027.nightDifferential {
            let r = row.rates
            for i in 0..<4 { #expect(abs(r[i + 1] / r[i] - 1 - PoliceContracts2027.impliedRaise) < 0.00002, "\(row.title)") }
        }
    }

    @Test func topStepOfficerMatchesThePacket() {
        let top = PoliceContracts2027.pbaOfficers.last!
        #expect(top.rates.first == 152_900.66)
        #expect(top.rates.last == 177_716.80)
    }

    @Test func payoutLinesAddToTheTransfer() {
        let sum = PoliceContracts2027.payoutLines.reduce(0) { $0 + $1.amount }
        #expect(sum == PoliceContracts2027.payoutsFromFundBalance)
    }

    @Test func cseaComparisonMatchesTheWebsite() {
        // The website's payroll page: $68,564.79 (shown as $68,565) reaches about $76,504 by 2029;
        // $100 becomes about $112 (police) and $109 (CSEA) by 2029.
        #expect(PoliceContracts2027.cseaSalary(from: PoliceContracts2027.cseaTypical2026, by: 2029).rounded() == 76_504)
        #expect(PoliceContracts2027.policePer100(by: 2029).rounded() == 112)
        #expect(PoliceContracts2027.policePer100(by: 2030).rounded() == 116)
        #expect(PoliceContracts2027.cseaPer100(by: 2029).rounded() == 109)
    }

    @Test func approvedNovember17() {
        #expect(PoliceContracts2027.adopted == true)
        #expect(PoliceContracts2027.statusLabel == "Approved by the Town Board on November 17, 2026, 5–0")
    }
}
