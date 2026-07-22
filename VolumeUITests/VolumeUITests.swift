import XCTest

/// End-to-end smoke test for the flow the whole app exists for: start a workout, log
/// sets, cross the score to beat, see the celebration, finish, read the summary.
///
/// Also captures a screenshot of each tab. Run with:
///   xcodebuild test -scheme Volume -only-testing:VolumeUITests \
///     -destination 'platform=iOS Simulator,name=iPhone 16'
final class VolumeUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
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

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func tapTab(_ name: String) {
        let tab = app.tabBars.buttons[name]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "Missing \(name) tab")
        tab.tap()
    }

    /// Scrolls the main scroll view up a few times.
    ///
    /// Deliberately unconditional rather than looping on `isHittable`: XCUITest reports
    /// an element as hittable when it's clipped by the scroll view or sitting under the
    /// pinned finish bar, so a tap "succeeds" while landing on nothing.
    private func scrollDown(_ times: Int = 2) {
        let scrollView = app.scrollViews.firstMatch
        let target: XCUIElement = scrollView.exists ? scrollView : app
        for _ in 0..<times {
            target.swipeUp()
        }
    }

    /// Matches any element type by label prefix.
    ///
    /// The celebration overlay is a single combined accessibility element — that's the
    /// right VoiceOver design (one announcement, not six fragments), so the test adapts
    /// to it rather than the app being made worse to suit the test.
    private func element(labelStartingWith prefix: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", prefix))
            .firstMatch
    }

    func testEveryTabRenders() {
        XCTAssertTrue(app.buttons["Start workout"].waitForExistence(timeout: 20),
                      "Home should offer Start workout")
        capture("01-Home")

        // Sample data leaves the current week partially complete on purpose.
        XCTAssertTrue(app.staticTexts["RECORDS IN A ROW"].exists
                      || app.staticTexts["RECORD IN A ROW"].exists)

        tapTab("Calendar")
        XCTAssertTrue(app.navigationBars["Calendar"].waitForExistence(timeout: 10))
        capture("02-Calendar")

        tapTab("Records")
        XCTAssertTrue(app.navigationBars["Records"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["YOUR WORKOUTS"].exists, "Records should list each workout")
        capture("03-Records")

        tapTab("Settings")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Follows your device"].exists,
                      "Appearance should offer Automatic, described as following the device")
        XCTAssertTrue(app.staticTexts["3 days a week"].exists, "Weekly goal picker missing")
        capture("04-Settings")
    }

    func testBeatingTheScoreCelebratesAndSummarises() {
        let start = app.buttons["Start workout"]
        XCTAssertTrue(start.waitForExistence(timeout: 20))
        start.tap()

        // Each template card shows its own last score before you commit to it.
        let pushCard = app.buttons.containing(
            NSPredicate(format: "label BEGINSWITH %@", "Push")
        ).firstMatch
        XCTAssertTrue(pushCard.waitForExistence(timeout: 10), "Push template card missing")
        capture("05-PickWorkout")
        pushCard.tap()

        // "Repeat last time" reproduces the previous session exactly — so the score lands
        // level with the target and one extra set is enough to pass it.
        let repeatButton = app.buttons["Repeat last time"]
        XCTAssertTrue(repeatButton.waitForExistence(timeout: 10))
        capture("06-ActiveWorkoutEmpty")
        repeatButton.tap()

        capture("07-ActiveWorkoutMatched")
        scrollDown()

        let logSet = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Log set")
        ).firstMatch
        XCTAssertTrue(logSet.waitForExistence(timeout: 10), "No Log set button")
        logSet.tap()

        // Transient by design, so check for it immediately...
        let celebration = element(labelStartingWith: "New record")
        let appeared = celebration.waitForExistence(timeout: 5)
        // ...but let the scale-and-fade entrance finish before the screenshot. Capturing
        // the instant it exists catches it half-transparent, which is useless as an App
        // Store asset. Well inside the ~3.2s auto-dismiss.
        Thread.sleep(forTimeInterval: 0.7)
        capture("08-NewRecord")
        if !appeared {
            let dump = XCTAttachment(string: app.debugDescription)
            dump.name = "hierarchy-when-celebration-missing"
            dump.lifetime = .keepAlways
            add(dump)
        }
        XCTAssertTrue(appeared, "Passing the score to beat must trigger the celebration")
        celebration.tap()

        let finish = app.buttons["Finish workout"]
        XCTAssertTrue(finish.waitForExistence(timeout: 10))
        capture("09-ActiveWorkoutBeaten")
        finish.tap()

        // The confirmation dialog repeats the button label, so target the sheet's copy.
        let confirm = app.sheets.buttons["Finish workout"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "Finish confirmation missing")
        confirm.tap()

        XCTAssertTrue(app.staticTexts["NEW RECORD 🔥"].waitForExistence(timeout: 10),
                      "Summary should report the record")
        capture("10-Summary")

        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Start workout"].waitForExistence(timeout: 10),
                      "Finishing should return Home")
        capture("11-HomeAfterRecord")
    }

    /// The paywall gates the whole app, so it has to work with real StoreKit data.
    /// Prices, periods and trial eligibility all come from `Products.storekit`, attached
    /// to the scheme's Run action.
    func testPaywallShowsRealStoreKitPrices() {
        app.terminate()
        // No -VolumeUnlock: reset clears the DEBUG bypass so the real paywall appears.
        app.launchArguments = ["-VolumeResetData", "-VolumeSkipOnboarding"]
        app.launch()

        let headline = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "Beat your score")
        ).firstMatch
        XCTAssertTrue(headline.waitForExistence(timeout: 20), "Paywall headline missing")
        capture("14-Paywall")

        // Each value prop is one combined accessibility element (title + detail), so match
        // on the prefix rather than the title as a standalone string.
        XCTAssertTrue(element(labelStartingWith: "One number per workout").exists)
        XCTAssertTrue(element(labelStartingWith: "A target every session").exists)
        XCTAssertTrue(app.buttons["Restore"].exists, "Restore purchases must always be reachable")
        XCTAssertTrue(app.links["Terms"].exists || app.buttons["Terms"].exists)
        XCTAssertTrue(app.links["Privacy"].exists || app.buttons["Privacy"].exists)

        // Assert whichever state is actually on screen — both must be correct, and a
        // paywall that dead-ends is the more dangerous of the two. Matching on the period
        // wording rather than an exact amount, because StoreKit snaps to real App Store
        // price points ($5.00 becomes $4.99) and localises per storefront.
        let yearlyPrice = app.staticTexts.matching(
            NSPredicate(format: "label ENDSWITH %@", "a year")
        ).firstMatch

        // Wait rather than check instantly: the paywall renders as soon as it's on screen,
        // but StoreKit fills the prices in a moment later. Checking immediately raced it.
        if yearlyPrice.waitForExistence(timeout: 10) {
            XCTAssertTrue(app.staticTexts.matching(
                NSPredicate(format: "label ENDSWITH %@", "a month")
            ).firstMatch.exists, "Monthly price missing")
            XCTAssertTrue(app.buttons["Try free for 7 days"].exists,
                          "Trial-first framing missing — check the introductory offer")
            XCTAssertFalse(app.staticTexts["Prices couldn't be loaded"].exists)

            // Yearly is preselected as the better value, and both plans must be reachable
            // without scrolling — a paywall hiding the cheaper option isn't offering a choice.
            let yearlyRow = element(labelStartingWith: "Yearly,")
            let monthlyRow = element(labelStartingWith: "Monthly,")
            XCTAssertTrue(yearlyRow.isSelected, "Yearly should be preselected")
            XCTAssertTrue(monthlyRow.isHittable,
                          "Monthly plan should be visible without scrolling")
        } else {
            XCTAssertTrue(app.staticTexts["Prices couldn't be loaded"].exists,
                          "With no products the paywall must explain itself")
            XCTAssertTrue(app.buttons["Try again"].exists, "No way to retry")
            XCTAssertFalse(app.buttons["Subscribe"].isEnabled,
                           "Subscribe must be disabled when there's nothing to buy")
        }
    }

    /// Regression: a logged set used to land in the store but not appear in the list
    /// until some unrelated tap forced a redraw. Nothing is tapped between logging and
    /// asserting here, so a stale view fails the test.
    func testLoggedSetAppearsImmediately() {
        let start = app.buttons["Start workout"]
        XCTAssertTrue(start.waitForExistence(timeout: 20))
        start.tap()

        let pushCard = app.buttons.containing(
            NSPredicate(format: "label BEGINSWITH %@", "Push")
        ).firstMatch
        XCTAssertTrue(pushCard.waitForExistence(timeout: 10))
        pushCard.tap()

        let addExercise = app.buttons["Add exercise"]
        XCTAssertTrue(addExercise.waitForExistence(timeout: 10))
        addExercise.tap()

        let bench = app.buttons["Barbell Bench Press"]
        XCTAssertTrue(bench.waitForExistence(timeout: 10), "Exercise picker didn't open")
        bench.tap()

        let logSet = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Log set")
        ).firstMatch
        XCTAssertTrue(logSet.waitForExistence(timeout: 10))
        scrollDown()

        logSet.tap()
        XCTAssertTrue(element(labelStartingWith: "Set 1,").waitForExistence(timeout: 3),
                      "A logged set must appear in the list straight away")

        logSet.tap()
        XCTAssertTrue(element(labelStartingWith: "Set 2,").waitForExistence(timeout: 3),
                      "The second set must appear straight away too")
    }

    /// A brand-new workout has nothing to beat, so it shows no ring and says so.
    func testCreatingANewWorkoutShowsNoTarget() {
        let start = app.buttons["Start workout"]
        XCTAssertTrue(start.waitForExistence(timeout: 20))
        start.tap()

        let newWorkout = app.buttons["New workout"]
        XCTAssertTrue(newWorkout.waitForExistence(timeout: 10))
        newWorkout.tap()

        let field = app.textFields["Workout name"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Back")

        let create = app.buttons["Create and start"]
        XCTAssertTrue(create.waitForExistence(timeout: 5))
        create.tap()

        XCTAssertTrue(
            app.staticTexts["First time doing Back. Today sets the score to beat."]
                .waitForExistence(timeout: 10),
            "A first-ever workout should explain that it sets the score to beat"
        )
        capture("15-FirstTimeWorkout")
    }

    /// Logging a workout you forgot to log, from the day you actually did it.
    func testAddingAWorkoutOnAPastDay() {
        XCTAssertTrue(app.buttons["Start workout"].waitForExistence(timeout: 20))
        tapTab("Calendar")

        // Last month, so every day on screen is safely in the past.
        let previousMonth = app.buttons["Previous month"]
        XCTAssertTrue(previousMonth.waitForExistence(timeout: 10))
        previousMonth.tap()

        let freeDay = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "no workout")
        ).firstMatch
        XCTAssertTrue(freeDay.waitForExistence(timeout: 10), "Expected a day with no workout")
        freeDay.tap()

        let addButton = app.buttons["Add a workout on this day"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        capture("16-CalendarAddWorkout")
        addButton.tap()

        // The picker should already be pointing at the chosen day, not at now.
        let dateRow = app.buttons["Workout date and time"]
        XCTAssertTrue(dateRow.waitForExistence(timeout: 10), "Date row missing from the picker")
        let pickerDate = dateRow.value as? String ?? ""
        XCTAssertFalse(pickerDate.hasPrefix("Now"),
                       "Arriving from a past day should pre-set the date, got \(pickerDate)")

        let pushCard = app.buttons.containing(
            NSPredicate(format: "label BEGINSWITH %@", "Push")
        ).firstMatch
        XCTAssertTrue(pushCard.waitForExistence(timeout: 10))
        pushCard.tap()

        // The workout itself shows the date, so it's obvious you're logging into the past.
        XCTAssertTrue(app.buttons["Workout date and time"].waitForExistence(timeout: 10),
                      "A backdated workout should show its date")
        capture("17-BackdatedWorkout")

        let repeatButton = app.buttons["Repeat last time"]
        XCTAssertTrue(repeatButton.waitForExistence(timeout: 10))
        repeatButton.tap()

        let finish = app.buttons["Finish workout"]
        XCTAssertTrue(finish.waitForExistence(timeout: 10))
        finish.tap()
        let confirm = app.sheets.buttons["Finish workout"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()

        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 10))
        done.tap()

        // Back on the calendar, on the same day, which now has a workout.
        XCTAssertTrue(app.buttons["Add another workout on this day"].waitForExistence(timeout: 10),
                      "The workout should have landed on the day that was selected")
    }

    func testDarkModeRenders() {
        XCTAssertTrue(app.buttons["Start workout"].waitForExistence(timeout: 20))
        tapTab("Settings")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))

        app.buttons["Dark"].firstMatch.tap()
        tapTab("Home")
        XCTAssertTrue(app.buttons["Start workout"].waitForExistence(timeout: 10))
        capture("12-HomeDark")

        tapTab("Records")
        capture("13-RecordsDark")

        // Appearance is a persisted preference, so restore it or every later test runs
        // against whatever this one left behind.
        tapTab("Settings")
        // The row's label includes its subtitle ("Automatic, Follows your device"),
        // so match on the prefix rather than the exact string.
        let automatic = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Automatic")
        ).firstMatch
        XCTAssertTrue(automatic.waitForExistence(timeout: 10))
        automatic.tap()
    }
}
