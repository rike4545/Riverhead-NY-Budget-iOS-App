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
        XCTAssertTrue(app.buttons["Start Here"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSearchAndScorecardAreReachable() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Civic"].tap()
        tapCatalogRow("Search", in: app)
        XCTAssertTrue(app.navigationBars["Search"].waitForExistence(timeout: 5))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        tapCatalogRow("Budget Scorecard", in: app)
        XCTAssertTrue(app.navigationBars["Budget Scorecard"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTrustAndPdfSearchAreReachable() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Civic"].tap()
        tapCatalogRow("PDF Search", in: app)
        XCTAssertTrue(app.navigationBars["PDF Search"].waitForExistence(timeout: 5))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        tapCatalogRow("Trust & Privacy", in: app)
        XCTAssertTrue(app.navigationBars["Trust & Privacy"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    /// Catalog rows on the Civic hub are NavigationLinks whose children are
    /// combined into a single accessibility element labelled with the row title
    /// (CivicImprovementsView.swift:712), so they surface as buttons rather than
    /// static text. Several sit below the fold — Trust & Privacy is the twelfth
    /// row — and XCUITest does not scroll to an element before tapping it, so
    /// scroll until the row is hittable rather than assuming it is on screen.
    @MainActor
    private func tapCatalogRow(_ title: String, in app: XCUIApplication) {
        let row = app.buttons[title]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "No catalog row labelled \(title)")

        var swipes = 0
        while !row.isHittable && swipes < 12 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(row.isHittable, "Catalog row \(title) never scrolled into view")
        row.tap()
    }

}
