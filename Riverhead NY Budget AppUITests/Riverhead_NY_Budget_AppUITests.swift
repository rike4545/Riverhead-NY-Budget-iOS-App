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

        for title in ["Home", "Budget", "Civic", "Tools", "More"] {
            XCTAssertNotNil(
                tabElement(title, in: app),
                "No tab labelled \(title).\n\(app.debugDescription)"
            )
        }

        tapTab("Civic", in: app)
        XCTAssertTrue(app.staticTexts["Start with the issue. Leave with a next step."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["All tools"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSearchAndScorecardAreReachable() throws {
        let app = XCUIApplication()
        app.launch()

        tapTab("Civic", in: app)
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

        tapTab("Civic", in: app)
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

    /// Locates a primary tab without assuming which element type it resolves to.
    ///
    /// iOS 26 renders a SwiftUI `TabView` as a floating tab bar whose items are
    /// `_UIFloatingTabBarItemCell`, which XCUITest resolves as cells. The app
    /// then has no `TabBar` descendants at all, so `app.tabBars.buttons[title]`
    /// cannot match. CI on 8c1ef86 failed exactly that way:
    ///
    ///     Failed to tap "Civic" Button: No matches found for Descendants
    ///     matching type TabBar from input {( Application, pid: 9224 )}
    ///     Automation type mismatch: computed Button from legacy attributes
    ///     vs Cell from modern attribute ... "_UIFloatingTabBarItemCell"
    ///
    /// The classic tab bar is still what a local run against an older runtime
    /// produces, so all three shapes are tried rather than trading one
    /// assumption for another.
    @MainActor
    private func tabElement(_ title: String, in app: XCUIApplication) -> XCUIElement? {
        let shapes = [app.cells[title], app.buttons[title], app.tabBars.buttons[title]]
        return shapes.first { $0.waitForExistence(timeout: 2) }
    }

    @MainActor
    private func tapTab(_ title: String, in app: XCUIApplication) {
        guard let tab = tabElement(title, in: app) else {
            XCTFail("""
                No tab labelled "\(title)" as a cell, a button, or a tab-bar button.
                \(app.debugDescription)
                """)
            return
        }
        tab.tap()
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

        let row = [app.buttons[title], app.cells[title]]
            .first { $0.waitForExistence(timeout: 5) }
        guard let row else {
            XCTFail("""
                Searching for "\(title)" produced no result row labelled \(title).
                \(app.debugDescription)
                """)
            return
        }
        XCTAssertTrue(
            scrollUntilHittable(row, in: app),
            "Result row \(title) exists but never scrolled clear of the keyboard"
        )
        row.tap()
    }

}
