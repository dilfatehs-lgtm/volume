# Volume

A workout logger with one job: show you a big number for how much work you did, and make
beating last time's number feel good.

No advice, no coaching, no plans, no social, no login. Just the log and the score.

---

## Run it

```bash
open Volume.xcodeproj
```

Pick the **Volume** scheme and an iPhone simulator, then Run. Nothing else to configure —
no team, no signing, no accounts. It builds and runs as-is.

**Requirements:** Xcode 16+, iOS 17.0+ deployment target. iPhone only, portrait only.
Zero third-party dependencies.

### Seeing it with data immediately

The first launch is empty by design. Two ways to fill it:

- **Settings ▸ Developer ▸ Load 10 weeks of sample data** (DEBUG builds only)
- **Launch arguments** — *Product ▸ Scheme ▸ Edit Scheme ▸ Run ▸ Arguments*:

  | Argument | Effect |
  |---|---|
  | `-VolumeSampleData` | 10 weeks of Push/Pull/Legs history |
  | `-VolumeSkipOnboarding` | Skip the 6-step tour |
  | `-VolumeUnlock` | Bypass the paywall |
  | `-VolumeResetData` | Wipe everything and re-seed the exercise library |

The sample data is shaped to exercise the interesting cases: interleaved workouts (so
per-workout comparison is visibly correct), a deliberate dip every sixth session (so the
record streak actually resets), two bodyweight exercises, and a **partially complete
current week** so you can see that an unfinished week doesn't break the week streak.

### Tests

```bash
xcodebuild test -scheme Volume -destination 'platform=iOS Simulator,name=iPhone 16'
```

- **VolumeTests** (66 unit tests) — score maths, unit conversion, per-workout comparison,
  both streaks and their best-ever counterparts, personal bests and PR counts,
  forward-only goal history, backdating, the celebration trigger, and the StoreKit products
  (via `SKTestSession`).
- **VolumeUITests** (7 tests) — end-to-end: start a workout, repeat last time, log a set,
  cross the score to beat, see the celebration, finish, read the summary. Plus creating a
  new workout, backdating one from the Calendar, real StoreKit prices on the paywall, and a
  screenshot of every tab in light and dark.

---

## What you need to set up

### 1. Your identity (2 minutes)

Find and replace `com.hibeamgroup.volume` if you want a different bundle id. It appears in:

| File | What |
|---|---|
| `Volume.xcodeproj/project.pbxproj` | `PRODUCT_BUNDLE_IDENTIFIER` (Debug + Release) |
| `Volume/Volume.entitlements` | `iCloud.com.hibeamgroup.volume` container id |
| `Volume/Model/VolumeStore.swift` | `cloudKitContainerID` |

Then set your team: select the **Volume** target ▸ *Signing & Capabilities* ▸ Team.

### 2. iCloud sync (CloudKit)

The entitlements file is complete and ready. On your end:

1. **Apple Developer portal** ▸ Identifiers ▸ your App ID ▸ enable **iCloud**, and create
   the container `iCloud.com.hibeamgroup.volume`.
2. In Xcode, *Signing & Capabilities* should now show **iCloud ▸ CloudKit** with that
   container ticked, plus **Background Modes ▸ Remote notifications** (already in
   `Info.plist`).
3. Run on a **real device** signed into iCloud. SwiftData creates the CloudKit schema
   automatically from the model on first run.
4. When you're ready to ship: **CloudKit Console ▸ Schema ▸ Deploy to Production**. This
   is easy to forget and sync silently fails in production without it.

**Why the simulator says "not syncing":** this project ships with
`CODE_SIGNING_ALLOWED[sdk=iphonesimulator*] = NO` so it builds with no team configured.
Unsigned builds get no entitlements, and CloudKit *terminates the process* when it finds
the entitlement missing — so `VolumeStore` deliberately uses a local store there. Device
builds are always signed, so they always get CloudKit. To test sync in the simulator: set
your team, delete that build setting, and add `VOLUME_CLOUDKIT_IN_SIMULATOR` to the
target's *Active Compilation Conditions*.

Your data is never lost either way — the local store keeps working and Settings tells the
user which mode they're in.

**Model changes and CloudKit:** every property must be optional or have a default, every
relationship must be optional with an explicit inverse, and `@Attribute(.unique)` is
banned. Breaking any of these fails at runtime, not compile time. See the notes at the top
of `Volume/Model/Models.swift`.

### 3. Subscriptions (StoreKit 2)

Placeholder products, already wired and working locally via `Products.storekit` (attached
to the scheme's Run action, so the paywall shows real prices in the simulator):

| Product ID | Price | Period | Trial |
|---|---|---|---|
| `com.volume.pro.monthly` | US$5 | 1 month | 7 days free |
| `com.volume.pro.annual` | US$50 | 1 year | 7 days free |

To use real products:

1. **App Store Connect** ▸ your app ▸ Subscriptions ▸ create a subscription **group**
   (e.g. "Volume Pro") containing both products, each with a 7-day free **Introductory
   Offer**.
2. Change the IDs in **`Volume/Subscription/SubscriptionManager.swift`**
   (`monthlyID` / `annualID`) — that's the only place in code they appear.
3. Update `Products.storekit` to match, so local testing and `SubscriptionTests` keep
   working. It's bundled into the test target, so the tests assert your real IDs, prices
   and trial length — change an ID in one place and not the other and they fail.
4. Complete *Agreements, Tax, and Banking*, or products return empty with no error.

The paywall reads prices, periods and trial eligibility from StoreKit, so it adapts to
whatever you configure — the savings badge only appears when both real prices are known.

**Replace before submitting:** the Terms and Privacy URLs in
`Volume/Subscription/PaywallView.swift` (`LegalLinks`) point at placeholder addresses.
App Review rejects submissions without working links.

---

## How it works

### The score

```
set     →  weight ? reps × weight : reps        (bodyweight sets count their reps)
exercise →  Σ sets
session  →  Σ exercises
```

Computed in whatever unit you're currently displaying, everywhere — live score, score to
beat, calendar, chart, streaks. Switching lb ↔ kg rescales every number by the same
factor, so "did I beat last time" can never flip because of a settings change.

Weights are stored **as typed, with the unit they were typed in** rather than converted to
a canonical unit. Type `135 lb`, always read back exactly `135 lb`.

### Comparisons, and why there's no split picker

A session is only ever measured against an earlier session of the **same workout**. Tap
*Pull* and you're compared against your last *Pull*, never against yesterday's *Legs*.

That means the app never needs to know what a "split" is. A bro-split user makes "Arm
Day"/"Chest Day", an upper/lower user makes "Upper"/"Lower", a PPL user makes
"Push"/"Pull"/"Legs" — everyone gets correct comparisons for free, because they named
their split into existence just by naming their workouts. Adding a muscle-group taxonomy
would layer a second classification on top of names that already carry the meaning, and
strand anyone whose workout is called "Maria's Tuesday Workout".

The one real hazard is splitting one workout across two names ("Leg Day" and later
"Legs"), which silently restarts its history. Creating a close-matching name offers *"Use
existing 'Leg Day'?"* as the primary button — a naming nudge, not a classification system.

### Backdating

People log on the couch, not at the rack. A workout can be given any past date and time
from three places: the date row at the top of the Start Workout sheet (reads "Now" by
default, so the common path is still two taps), **"Add a workout on this day"** under any
past day in the Calendar, and the date row when editing an already-logged workout. Future
dates are blocked — they'd scramble the ordering every comparison depends on.

Backdating recomputes everything, because nothing is cached: a session dropped into a gap
becomes the target for whatever follows it, and takes its own target from what precedes it.

That means backdating can *change your streaks* — filling in a week you actually trained
repairs the week streak, and slotting in a strong forgotten session can break the record
streak because the workout after it no longer beats what now comes before. Both are
correct. **Goals are commitments, so they can't be moved retroactively; workouts are facts,
so correcting them counts.**

### The two streaks

**🔥 Records in a row** — consecutive workouts that beat their own score to beat. The
first-ever session of a workout is *neutral*: it neither extends nor resets the streak, so
trying something new is never punished. The rule is identical to the celebration trigger,
so every 🔥 moment is worth exactly +1.

**Week streak** — consecutive weeks hitting your self-set goal (1–7 days, default 3).

- **Distinct days count, not sessions.** Two workouts on one Saturday is 1 day.
- **The in-progress week never breaks it.** Only completed weeks are judged; the current
  one shows as live progress. Without this, every streak would read as broken each Monday.
- **Week boundaries follow the device locale** (Sunday in the US, Monday in most of Europe).
- **Goal changes are forward-only.** Each change appends a dated `WeeklyGoal` instead of
  overwriting, and past weeks keep being judged by the goal that applied then — so
  lowering the goal can't manufacture a streak and raising it can't wipe one you earned.

### Exercise library

53 resistance exercises, seeded on first launch, each flagged weighted or bodyweight.
Users can add their own. Cardio is deliberately absent: "one rep of treadmill" doesn't fit
a `reps × weight` score, and including it would produce meaningless numbers. Add it as a
custom exercise if you want it.

Seeding is an idempotent slug-based upsert with a duplicate sweep, not a one-shot flag —
CloudKit forbids unique constraints, so a second device syncing an already-seeded library
would otherwise insert its own full copy.

---

## Layout

```
Volume/
├── Model/          6 @Model types, container + CloudKit fallback, library seed, sample data
├── Core/           score maths, units, streaks, comparison lookups, settings, haptics
├── DesignSystem/   theme, hero score, progress ring, confetti, celebration, buttons
├── ActiveWorkout/  the product: live score, set logging, celebration, summary
├── Home/  CalendarTab/  RecordsTab/  SettingsTab/
├── Onboarding/     6 steps, each animating a real component from the app
└── Subscription/   StoreKit 2 manager, paywall, resubscribe
```

Uses Xcode 16 file-system-synchronized groups: the target references the `Volume/` folder,
so files you add are picked up automatically without touching the project file.

## Deliberately not built

No advice, coaching, AI suggestions, rest timers or workout plans. No social, sharing or
friends. No login or accounts. No Apple Health. No iPad or watchOS target.
