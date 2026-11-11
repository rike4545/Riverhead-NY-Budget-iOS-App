//
//  Budget2027StatusTests.swift
//  Riverhead NY Budget AppTests
//
//  The Home card and the 2027 proposal screen take their wording from
//  Budget2027Status, which switches on the November 20, 2026 adoption deadline.
//

import Foundation
import Testing
@testable import Riverhead_NY_Budget_App

struct Budget2027StatusTests {
    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = h
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    @Test func beforeTheDeadlineItNamesThePreliminary() {
        let now = date(2026, 11, 11)
        #expect(Budget2027Status.isBeforeAdoptionDeadline(now))
        #expect(Budget2027Status.title(now) == "Read the 2027 Preliminary Budget")
        #expect(Budget2027Status.summary(now).contains("November 20, 2026"))
        #expect(!Budget2027Status.title(now).contains("Tentative"))
    }

    @Test func theDeadlineDayStillCountsAsBefore() {
        #expect(Budget2027Status.isBeforeAdoptionDeadline(date(2026, 11, 20, 18)))
    }

    @Test func afterTheDeadlineItStopsCallingItPreliminary() {
        let now = date(2026, 11, 21)
        #expect(!Budget2027Status.isBeforeAdoptionDeadline(now))
        #expect(Budget2027Status.title(now) == "Read the 2027 budget")
        #expect(Budget2027Status.shortStatus(now) == "Adoption deadline passed Nov 20")
    }

    @Test func itOpensTheWebsitesBudgetPage() {
        #expect(Budget2027Status.url.absoluteString.hasSuffix("/tentative-2027/"))
    }
}
