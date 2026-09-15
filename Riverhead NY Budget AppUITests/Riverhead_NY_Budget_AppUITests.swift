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

    /// The tools directory is collapsed on launch — CivicImprovementsView.swift:350
    /// declares `@State private var showAllTools = false`, and line 740 builds the
    /// rows only `if showAllTools`. While it is closed the rows do not exist in the
    /// accessibility tree at all, so a missing row means "not expanded" rather than
    /// "mislabelled" or "off screen". It sits below the goal cards and the featured
    /// shortcuts, so reaching it means scrolling first.
    @MainActor
    private func expandAllTools(in app: XCUIApplication) {
        let toggle = app.buttons["All tools"]
        guard toggle.waitForExistence(timeout: 5) else { return }
        guard scrollUntilHittable(toggle, in: app) else { return }
        toggle.tap()
    }

    /// Catalog rows are NavigationLinks carrying .accessibilityElement(children:
    /// .combine) with .accessibilityLabel(item.title) (CivicImprovementsView.swift:803),
    /// so they surface as buttons labelled with the row title — once the directory
    /// that contains them has been opened.
    @MainActor
    private func tapCatalogRow(_ title: String, in app: XCUIApplication) {
        let row = app.buttons[title]
        if !row.exists {
            expandAllTools(in: app)
        }
        XCTAssertTrue(
            row.waitForExistence(timeout: 5),
            "No catalog row labelled \(title) after expanding the All tools directory"
        )
        XCTAssertTrue(
            scrollUntilHittable(row, in: app),
            "Catalog row \(title) exists but never scrolled into view"
        )
        row.tap()
    }

}
