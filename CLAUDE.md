# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Volume is an iPhone workout logger: log sets, get one number (volume score), beat it next
time. See `README.md` for product behaviour and the App Store / CloudKit setup the owner
still has to do. This file covers what you need to change the code safely.

## Commands

```bash
# Build
xcodebuild -project Volume.xcodeproj -scheme Volume \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# All tests (66 unit + 7 UI)
xcodebuild -project Volume.xcodeproj -scheme Volume \
  -destination 'platform=iOS Simulator,name=iPhone 16' test

# One target, one class, or one test
-only-testing:VolumeTests
-only-testing:VolumeTests/StreakTests
-only-testing:VolumeTests/RecordStreakTests/testFallingShortResetsTheStreak

# Run in the simulator (see DEBUG launch arguments below)
xcrun simctl install "iPhone 16" <DerivedData>/Build/Products/Debug-iphonesimulator/Volume.app
xcrun simctl launch "iPhone 16" com.volume.app -VolumeResetData -VolumeSampleData -VolumeSkipOnboarding -VolumeUnlock
```

UI-test screenshots are `XCTAttachment`s; extract with
`xcrun xcresulttool export attachments --path <bundle>.xcresult --output-path <dir>`
(pass `-resultBundlePath` when running).

DEBUG launch arguments (`VolumeStore.applyDebugLaunchArguments`): `-VolumeResetData`
(wipes data **and** the onboarding/unlock flags, applied first), `-VolumeSampleData`,
`-VolumeSkipOnboarding`, `-VolumeUnlock`.

## Architecture

**Everything is derived, nothing is cached.** Scores, both streaks, personal bests,
calendar dots and charts are all computed from `WorkoutSession.date` and the set data at
read time. This is why backdating and unit switching "just work" — and why adding a stored
aggregate would break them. Don't introduce one.

**One comparison identity.** `WorkoutSession.comparisonKey` (template identity, falling back
to the snapshotted name for sessions orphaned by a deleted template) decides what a session
is measured against. `SessionHistory`, `StreakCalculator` and `WorkoutRecords` all key off
it. A renamed template keeps its history; a deleted one keeps its sessions.

**One definition of "beat".** `StreakCalculator.outcomes(sessions:unit:)` produces the
per-session `.beat / .missed / .neutral` list. The current streak, best-ever streak and each
workout's PR count all derive from it, and `ActiveWorkoutModel`'s celebration uses the same
`liveScore > scoreToBeat` rule. If you add a fourth consumer, derive it from `outcomes` —
two definitions drifting apart means confetti that contradicts the number on Home.

Layers: `Model/` (SwiftData + container), `Core/` (pure logic — score, units, streaks,
records, lookups, settings, haptics), `DesignSystem/` (shared views), then one folder per
screen. `Core/` has no view code and is where nearly all the testable behaviour lives.

## Invariants that look like bugs but aren't

Tests pin all of these. If one fails after your change, the change is wrong, not the test.

- **First-ever session of a template is `.neutral`** — it neither extends nor resets the
  record streak. Trying a new workout must not be punished.
- **The in-progress week never breaks the week streak.** Only completed weeks are judged.
  Without this every user's streak reads as broken every Monday morning.
- **Week goals are forward-only** (`WeeklyGoal` is append-only, dated, never overwritten) so
  changing the goal can't rewrite past weeks. **Backdating a workout deliberately does**
  change streaks. Goals are commitments; workouts are facts.
- **Distinct days, not sessions**, count toward the weekly goal.
- **Equal is not beating.** `>`, never `>=`.
- **Weights are stored as typed with their unit** (`weightValue` + `weightUnitRaw`), never
  canonicalised. Scores convert at display time only.
- **`0` weight means bodyweight** and scores as `reps`, not `0`.
- Delete rules: deleting a template or library exercise **nullifies** (history survives via
  `templateNameSnapshot` / `nameSnapshot`); only deleting a session cascades.

## Platform gotchas

- **CloudKit terminates the process** when the entitlement is missing, and `ModelContainer`
  does *not* throw on a `.private` config, so a try/catch fallback never fires. `VolumeStore`
  gates on `canUseCloudKit` **before** choosing the configuration. Simulator builds are
  unsigned (`CODE_SIGNING_ALLOWED[sdk=iphonesimulator*] = NO`, so the project builds with no
  team) and therefore local-only; device builds always get CloudKit.
- **SwiftData to-many relationships don't reliably notify observers.** Always mutate through
  the parent array (`entry.sets = (entry.sets ?? []) + [set]`), not just the child's
  back-reference, and `ActiveWorkoutModel.changeCount` is read in the workout views to
  guarantee redraws. Without both, a logged set doesn't appear until an unrelated tap.
- **A deleted object still appears in its parent's relationship** until the context
  processes the change. Snapshot survivors *before* deleting, or reindexing skips a number.
- **CloudKit schema rules** (no `@Attribute(.unique)`, every property defaulted or optional,
  every relationship optional with an explicit inverse) fail at runtime, not compile time.
  See the header of `Model/Models.swift`.
- The project uses **Xcode 16 file-system-synchronized groups**, so new files under
  `Volume/` are picked up automatically. `Info.plist` and `Volume.entitlements` are excluded
  from build phases via `membershipExceptions` in the pbxproj — keep them there.
- **StoreKit tests use `SKTestSession`**, not the scheme's `StoreKitConfigurationFileReference`
  (which applies to Run but not `xcodebuild test`). `Products.storekit` is at the repo root
  and bundled into the unit-test target.
- UI tests: several views are single combined accessibility elements for VoiceOver, so
  `staticTexts["Some Title"]` won't match. Use the label-prefix helpers in the test file.
  `waitForExistence` does not imply hittable — scroll explicitly.

## Settled decisions — don't re-propose

- **No split picker or muscle-group taxonomy.** The template name a user invents ("Pull",
  "Upper", "Maria's Tuesday Workout") already carries that meaning. The near-duplicate
  naming nudge in `TemplateNameMatcher` handles the one real failure case.
- **No cardio in the exercise library.** "One rep of treadmill" produces a meaningless score.
- **No advice, coaching, plans, rest timers, social, login, or Health integration.** Stats
  that are facts about the log (personal bests, PR counts, last score) are fine; anything
  that tells the user what to *do* is not. 7 days a week is selectable with no commentary.
- **Records tab replaced a chart-first Progress tab.** Streaks and PRs lead; the line lives
  one tap in, always scoped to a single workout (an "all workouts" line mixes magnitudes and
  means nothing).
- Accent is orange (`#FF6B1A` / `#FF7F33`); appearance defaults to Automatic, which passes
  `nil` to `preferredColorScheme` so the system keeps control.
