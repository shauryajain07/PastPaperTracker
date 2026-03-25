import XCTest

final class PastPaperTrackerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOfflineFallbackIsVisibleWithoutSupabaseConfig() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["Continue Offline"].waitForExistence(timeout: 5))
    }

    func testCanEnterOfflineMode() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Continue Offline"].tap()

        XCTAssertTrue(app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Tests"].exists)
        XCTAssertTrue(app.tabBars.buttons["Mistakes"].exists)
    }
}
