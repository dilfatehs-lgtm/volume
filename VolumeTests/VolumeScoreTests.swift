import XCTest
@testable import Volume

@MainActor
final class VolumeScoreTests: VolumeTestCase {

    func testBodyweightSetScoresItsRepsAlone() {
        let session = makeSession(makeTemplate("Core"), on: now, sets: [(reps: 15, weight: nil)])
        XCTAssertEqual(VolumeScore.score(for: session, in: .pounds), 15)
    }

    func testZeroWeightIsTreatedAsBodyweightRatherThanZeroScore() {
        // A set of 12 reps at "0 lb" is a bodyweight set, and must score 12 — not 0.
        let session = makeSession(makeTemplate("Core"), on: now, sets: [(reps: 12, weight: 0)])
        XCTAssertEqual(VolumeScore.score(for: session, in: .pounds), 12)
    }

    func testWeightedSetsMultiplyAndSum() {
        let session = makeSession(makeTemplate("Push"), on: now,
                                  sets: [(reps: 8, weight: 135),
                                         (reps: 8, weight: 135),
                                         (reps: 6, weight: 145)])
        // 1080 + 1080 + 870
        XCTAssertEqual(VolumeScore.score(for: session, in: .pounds), 3030)
    }

    func testScoreConvertsIntoTheDisplayUnit() {
        let session = makeSession(makeTemplate("Push"), on: now,
                                  sets: [(reps: 10, weight: 100)], unit: .pounds)
        let inPounds = VolumeScore.score(for: session, in: .pounds)
        let inKilograms = VolumeScore.score(for: session, in: .kilograms)

        XCTAssertEqual(inPounds, 1000, accuracy: 0.001)
        XCTAssertEqual(inKilograms, 1000 * 0.45359237, accuracy: 0.001)
    }

    /// The property the whole app leans on: switching units rescales every score by the
    /// same factor, so "did I beat last time" can never flip because of a settings change.
    func testUnitChangePreservesOrdering() {
        let template = makeTemplate("Push")
        let lighter = makeSession(template, on: VolumeTestCase.date(2026, 7, 1),
                                  sets: [(reps: 10, weight: 100)])
        let heavier = makeSession(template, on: VolumeTestCase.date(2026, 7, 8),
                                  sets: [(reps: 10, weight: 110)])

        for unit in WeightUnit.allCases {
            XCTAssertGreaterThan(VolumeScore.score(for: heavier, in: unit),
                                 VolumeScore.score(for: lighter, in: unit),
                                 "Ordering must hold in \(unit.rawValue)")
        }
    }

    /// Weights are stored as typed, so a value entered in kg reads back exactly, with no
    /// round-trip drift through a canonical unit.
    func testWeightEnteredInKilogramsReadsBackExactly() {
        let session = makeSession(makeTemplate("Push"), on: now,
                                  sets: [(reps: 5, weight: 62.5)], unit: .kilograms)
        let set = session.entriesSorted[0].setsSorted[0]
        XCTAssertEqual(set.weight(in: .kilograms)!, 62.5, accuracy: 0.0000001)
    }

    func testMixedBodyweightAndWeightedSetsAddUp() {
        let session = makeSession(makeTemplate("Pull"), on: now,
                                  sets: [(reps: 8, weight: nil),      // 8
                                         (reps: 10, weight: 120)])    // 1200
        XCTAssertEqual(VolumeScore.score(for: session, in: .pounds), 1208)
    }

    func testFormattingGroupsAndDropsDecimals() {
        XCTAssertEqual(VolumeScore.format(12480.4), "12,480")
        XCTAssertEqual(VolumeScore.formatDelta(2340), "+2,340")
        XCTAssertEqual(VolumeScore.formatDelta(-820), "−820")
    }
}
