import XCTest

/// Drives the app slowly enough to film, one test per marketing clip. Not a test of
/// anything — a camera operator. See `Marketing/tiktok-scripts.md` for the shot list
/// these clips feed.
///
/// Never runs in the normal suite: every test skips unless the runner is launched with
/// MARKETING_FOOTAGE=1. Record the simulator while a clip runs:
///
///   xcrun simctl io <udid> recordVideo --codec h264 -f clip.mov &
///   TEST_RUNNER_MARKETING_FOOTAGE=1 xcodebuild test-without-building \
///     -only-testing:VolumeUITests/MarketingFootageUITests/clipBC_logSetsAndBeatTheScore ...
///   kill -INT %1
final class MarketingFootageUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["MARKETING_FOOTAGE"] == "1",
            "Footage capture only — launch with TEST_RUNNER_MARKETING_FOOTAGE=1"
        )
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-VolumeResetData",
            "-VolumeSampleData",
            "-VolumeSkipOnboarding",
            "-VolumeUnlock",
        ]
        app.launch()
    }

    /// Camera pause. The whole point of this file.
    private func hold(_ seconds: TimeInterval = 3) {
        Thread.sleep(forTimeInterval: seconds)
    }

    private func tapTab(_ name: String) {
        let tab = app.tabBars.buttons[name]
        XCTAssertTrue(tab.waitForExistence(timeout: 10))
        tab.tap()
    }

    private func element(labelStartingWith prefix: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", prefix))
            .firstMatch
    }

    /// Clip A — Home: score, streak, the one number.
    func clipA_homeScreen() {
        XCTAssertTrue(app.buttons["Start workout"].waitForExistence(timeout: 20))
        hold(4)
        app.scrollViews.firstMatch.swipeUp(velocity: .slow)
        hold(2.5)
        app.scrollViews.firstMatch.swipeDown(velocity: .slow)
        hold(3)
    }

    /// Clips B + C in one take — logging sets, the score climbing, the beat moment with
    /// confetti, and the NEW RECORD summary. The hero footage; cut as needed.
    func clipBC_logSetsAndBeatTheScore() {
        let start = app.buttons["Start workout"]
        XCTAssertTrue(start.waitForExistence(timeout: 20))
        hold(2)
        start.tap()

        let pushCard = app.buttons.containing(
            NSPredicate(format: "label BEGINSWITH %@", "Push")
        ).firstMatch
        XCTAssertTrue(pushCard.waitForExistence(timeout: 10))
        hold(2)
        pushCard.tap()

        // Score lands level with the target; one more set beats it.
        let repeatButton = app.buttons["Repeat last time"]
        XCTAssertTrue(repeatButton.waitForExistence(timeout: 10))
        hold(2)
        repeatButton.tap()
        hold(3)

        app.scrollViews.firstMatch.swipeUp(velocity: .slow)
        hold(1.5)

        let logSet = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Log set")
        ).firstMatch
        XCTAssertTrue(logSet.waitForExistence(timeout: 10))
        logSet.tap()

        // Let the celebration play out in full — never tap it away on camera.
        _ = element(labelStartingWith: "New record").waitForExistence(timeout: 5)
        hold(4)

        let finish = app.buttons["Finish workout"]
        XCTAssertTrue(finish.waitForExistence(timeout: 10))
        hold(1.5)
        finish.tap()
        let confirm = app.sheets.buttons["Finish workout"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()

        XCTAssertTrue(app.staticTexts["NEW RECORD 🔥"].waitForExistence(timeout: 10))
        hold(4)
        app.buttons["Done"].tap()
        hold(2)
    }

    /// Clip D — Records: streaks, PRs, and the per-workout chart.
    func clipD_recordsTab() {
        XCTAssertTrue(app.buttons["Start workout"].waitForExistence(timeout: 20))
        tapTab("Records")
        XCTAssertTrue(app.navigationBars["Records"].waitForExistence(timeout: 10))
        hold(4)
        app.scrollViews.firstMatch.swipeUp(velocity: .slow)
        hold(2.5)

        // Into a single workout's history and chart, if a row is on screen.
        let row = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Push")
        ).firstMatch
        if row.waitForExistence(timeout: 5) {
            row.tap()
            hold(5)
        }
    }

    /// Clip E — Calendar: dots for logged days, then backdating a forgotten workout.
    func clipE_calendarAndBackdate() {
        XCTAssertTrue(app.buttons["Start workout"].waitForExistence(timeout: 20))
        tapTab("Calendar")
        XCTAssertTrue(app.navigationBars["Calendar"].waitForExistence(timeout: 10))
        hold(4)

        app.buttons["Previous month"].tap()
        hold(2)

        let freeDay = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "no workout")
        ).firstMatch
        XCTAssertTrue(freeDay.waitForExistence(timeout: 10))
        freeDay.tap()
        hold(2)

        let addButton = app.buttons["Add a workout on this day"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
        hold(2)

        let pushCard = app.buttons.containing(
            NSPredicate(format: "label BEGINSWITH %@", "Push")
        ).firstMatch
        XCTAssertTrue(pushCard.waitForExistence(timeout: 10))
        pushCard.tap()
        hold(2.5)

        let repeatButton = app.buttons["Repeat last time"]
        XCTAssertTrue(repeatButton.waitForExistence(timeout: 10))
        repeatButton.tap()
        hold(2.5)

        let finish = app.buttons["Finish workout"]
        XCTAssertTrue(finish.waitForExistence(timeout: 10))
        finish.tap()
        let confirm = app.sheets.buttons["Finish workout"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()

        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 10))
        hold(2.5)
        done.tap()

        // Back on the calendar: the past day now carries its dot.
        hold(3.5)
    }

    /// Clip F — Settings: lb → kg, then Home showing every score converted.
    func clipF_unitSwitch() {
        XCTAssertTrue(app.buttons["Start workout"].waitForExistence(timeout: 20))
        hold(2.5)
        tapTab("Settings")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
        hold(2.5)

        let kg = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Kilograms")
        ).firstMatch
        XCTAssertTrue(kg.waitForExistence(timeout: 10), "Unit row missing")
        kg.tap()
        hold(2)

        tapTab("Home")
        XCTAssertTrue(app.buttons["Start workout"].waitForExistence(timeout: 10))
        hold(4)

        // Leave the simulator the way we found it.
        tapTab("Settings")
        app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Pounds")
        ).firstMatch.tap()
    }
}
