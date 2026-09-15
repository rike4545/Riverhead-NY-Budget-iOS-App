//
//  Riverhead_NY_Budget_AppUITests.swift
//  Riverhead NY Budget AppUITests
//

import XCTest

final class Riverhead_NY_Budget_AppUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testPrimaryTabsAndCommandCenterLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Budget"].exists)
        XCTAssertTrue(app.tabBars.buttons["Civic"].exists)
        XCTAssertTrue(app.tabBars.buttons["Tools"].exists)
        XCTAssertTrue(app.tabBars.buttons["More"].exists)

        app.tabBars.buttons["Civic"].tap()
        XCTAssertTrue(app.staticTexts["Start with the issue. Leave with a next step."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["All tools"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSearchAndScorecardAreReachable() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Civic"].tap()
        openCatalogRow("Search", in: app)
        XCTAssertTrue(app.navigationBars["Search"].waitForExistence(timeout: 5))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        openCatalogRow("Budget Scorecard", in: app)
        XCTAssertTrue(app.navigationBars["Budget Scorecard"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTrustAndPdfSearchAreReachable() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Civic"].tap()
        openCatalogRow("PDF Search", in: app)
        XCTAssertTrue(app.navigationBars["PDF Search"].waitForExistence(timeout: 5))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        openCatalogRow("Trust & Privacy", in: app)
        XCTAssertTrue(app.navigationBars["Trust & Privacy"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    /// Scrolls until `element` can be tapped, or gives up. Returns whether it is
    /// hittable, so callers can report which step actually failed.
    @MainActor
    @discardableResult
    private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        var swipes = 0
        while !element.isHittable && swipes < 12 {
            app.swipeUp()
            swipes += 1
        }
        return element.isHittable
    }

    /// Opens a catalog destination through the Civic Command Center's embedded
    /// search field (CivicImprovementsView.swift:485), which is the shortest
    /// deterministic path to any tool.
    ///
    /// The alternative — the "All tools" directory — is a poor test target: it
    /// is collapsed on launch (`showAllTools = false`, line 350) and its rows
    /// are built only `if showAllTools` (line 740), so they are absent from the
    /// accessibility tree until it is expanded, and the toggle itself sits
    /// below the goal and featured sections and has to be scrolled to first.
    ///
    /// The search field has none of that: it lives in the header hero at the
    /// top of the scroll view, so it is on screen the moment the tab appears.
    /// A non-empty query swaps `mainContent` for `searchResultsSection`
    /// (line 446), which means the featured cards are gone too and exactly one
    /// element carries the row's title as its label.
    @MainActor
    private func openCatalogRow(_ title: String, in app: XCUIApplication) {
        let field = app.textFields["Search tools and topics"]
        XCTAssertTrue(
            field.waitForExistence(timeout: 10),
            "Civic Command Center search field never appeared"
        )

        // Returning from a pushed destination leaves the previous query in place.
        let clear = app.buttons["Clear search"]
        if clear.exists { clear.tap() }

        field.tap()
        field.typeText(title)

        let row = app.buttons[title]
        XCTAssertTrue(
            row.waitForExistence(timeout: 5),
            "Searching for \"\(title)\" produced no result row labelled \(title)"
        )
        XCTAssertTrue(
            scrollUntilHittable(row, in: app),
            "Result row \(title) exists but never scrolled clear of the keyboard"
        )
        row.tap()
    }

}
