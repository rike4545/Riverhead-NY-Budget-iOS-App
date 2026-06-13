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
        XCTAssertTrue(app.tabBars.buttons["Discover"].exists)
        XCTAssertTrue(app.tabBars.buttons["Toolkits"].exists)
        XCTAssertTrue(app.tabBars.buttons["More"].exists)

        app.tabBars.buttons["Discover"].tap()
        XCTAssertTrue(app.staticTexts["Find the right civic move faster"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Start with my goal"].exists)
    }

    @MainActor
    func testSearchAndScorecardAreReachable() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Discover"].tap()
        app.staticTexts["Search"].tap()
        XCTAssertTrue(app.navigationBars["Search"].waitForExistence(timeout: 5))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.staticTexts["Budget Scorecard"].tap()
        XCTAssertTrue(app.navigationBars["Budget Scorecard"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTrustAndPdfSearchAreReachable() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Discover"].tap()
        app.staticTexts["PDF Search"].tap()
        XCTAssertTrue(app.navigationBars["PDF Search"].waitForExistence(timeout: 5))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.staticTexts["Trust & Privacy"].tap()
        XCTAssertTrue(app.navigationBars["Trust & Privacy"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
