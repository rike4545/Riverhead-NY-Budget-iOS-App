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
        XCTAssertTrue(app.staticTexts["Start Here"].exists)
    }

    @MainActor
    func testSearchAndScorecardAreReachable() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Civic"].tap()
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

        app.tabBars.buttons["Civic"].tap()
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
