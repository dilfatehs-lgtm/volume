# App Store Connect — everything to paste

Draft values for the listing. Character limits noted; all current values are within them.

---

## App information

| Field | Value | Limit |
|---|---|---|
| **Name** | `Volume: Workout Log` | 30 (using 19) |
| **Subtitle** | `Beat your last score` | 30 (using 20) |
| **Bundle ID** | `com.hibeamgroup.volume` | — |
| **Primary category** | Health & Fitness | — |
| **Secondary category** | *(leave empty)* | — |
| **Support URL** | `https://dilfatehs-lgtm.github.io/volume/` | — |
| **Privacy Policy URL** | `https://dilfatehs-lgtm.github.io/volume/privacy.html` | — |

The home-screen name stays **Volume**; the longer name is only for the store, where names
must be globally unique.

## Promotional text (170 max — editable without a new build)

```
Log your sets. Get one number. Beat it next time. No coaching, no plans, no noise — just the
number that tells you whether you're getting stronger.
```

## Description (4000 max)

```
Volume is a workout logger with one job: show you a single number for how much work you
did, and make beating it next time feel good.

Log your reps and weight. Volume multiplies them out across every set and gives you one
score for the session. Next time you do that workout, that score is already sitting there
as your target.

HOW IT WORKS

• Log sets in seconds — big buttons, a full-size number pad, one-handed between sets
• Every workout gets one volume score: reps × weight, added up
• Start each session with last time's score as the target to beat
• Pass it and you'll know about it

BUILT AROUND YOUR WORKOUTS, NOT OURS

You name your own workouts — Push, Leg Day, Tuesday, whatever you call them. Volume always
compares like for like, so your Pull day is measured against your last Pull day and never
against yesterday's Legs. There's no split to pick and no muscle-group taxonomy to fight.

TWO STREAKS

• Records in a row — every workout you beat adds one
• Weekly streak — set your own target of 1 to 7 days a week

WHAT ELSE

• 50+ exercises built in, or add your own
• Warm-up sets are logged but don't inflate your score
• Personal bests and PR counts for every workout
• Calendar of everything you've logged, with backdating for sessions you forgot
• Charts per workout, over 3 months to all time
• Pounds or kilograms, switch anytime
• Syncs across your devices through your own iCloud — no account, no sign-up
• Full dark mode

WHAT IT DOESN'T DO

No coaching. No AI. No workout plans. No rest timers. No social feed. No login. Volume
doesn't tell you what to do — it keeps the log and shows you the number.

SUBSCRIPTION

Volume is US$4.99/month or US$49.99/year, with a 7-day free trial. Your data is never deleted if
you stop subscribing.
```

## Every remaining field, answered

**Version 1.0 page**

| Field | Answer |
|---|---|
| Version | `1.0` |
| Copyright | `2026 Dilfateh Singh Shergill` (no © — Apple adds it) |
| Support URL | `https://dilfatehs-lgtm.github.io/volume/` |
| Marketing URL | same, or leave empty (optional) |
| Routing App Coverage File | empty — maps apps only |

**App Review Information**

| Field | Answer |
|---|---|
| Sign-in required | **Unticked** — there is no login |
| First / Last name | Dilfateh / Shergill |
| Phone | your real mobile |
| Email | `dilfatehs@gmail.com` |
| Notes | the review-notes block further down this file |
| Attachment | empty |

**Version Release** — *Manually release this version*, so going live is your call rather
than automatic the moment review passes. Phased Release off (it only applies to updates).

**General ▸ App Information**

| Field | Answer |
|---|---|
| Content Rights | **No** third-party content |
| License Agreement | Apple's **Standard EULA** (the default) |

The custom Terms are hosted and linked inside the app, which is what satisfies the
subscription-disclosure requirement; Apple's standard agreement on top is normal.

**Pricing and Availability**

| Field | Answer |
|---|---|
| Price | **Free** — the download is free, revenue comes from the subscription |
| Availability | All countries |
| Pre-Orders | Off |

Setting a price here would make the app paid *and* subscription-gated.

**IDFA question at submission** — "Does this app use the Advertising Identifier?" → **No.**
No ad SDK, no tracking, nothing in the binary that touches it.

## Keywords (100 max, comma-separated, no spaces)

```
gym,lifting,strength,sets,reps,progressive,overload,weightlifting,tracker,barbell,PR,log
```

Don't repeat words already in the name or subtitle — they're indexed anyway.

## What's New (first release)

```
First release.
```

---

## App Privacy — answer "No" to data collection

Select **Data Not Collected**. It is accurate: no analytics, no third-party SDKs, no
account. Workouts live on the device and in the user's *own* private CloudKit database,
which is their storage, not data collected by you. This matches `Volume/PrivacyInfo.xcprivacy`.

## Age rating

All questionnaire answers are **None** / **No**. Expected result: **4+**.

## EU Digital Services Act — trader status

**Declare as a trader.** Selling a subscription is commercial activity, so the DSA
definition applies (acting "for purposes relating to his or her trade, business, craft or
profession") even as a sole individual.

Entered under App Store Connect ▸ **Business** ▸ Trader Status: legal name, **street
address**, phone and email.

> **Apple publishes all of it on your EU App Store listing**, visible to anyone, and
> verifies it — so it can't be fabricated. The decision here was to use the home address.
> If that becomes uncomfortable once the app is public, the fix is a virtual office or
> registered-agent address (~$10–30/month), updated in the same place. Declining to declare
> removes the app from all EU storefronts.

Not legal advice — worth a word with an accountant if your circumstances change.

---

## Subscriptions

Create one **subscription group** — suggested reference name `Volume Pro`.

| Product ID | Reference name | Duration | Price | Intro offer |
|---|---|---|---|---|
| `com.volume.pro.monthly` | Volume Pro Monthly | 1 month | US$4.99 | 7 days free |
| `com.volume.pro.annual` | Volume Pro Annual | 1 year | US$49.99 | 7 days free |

Each needs a localized **display name** and **description**, plus a review screenshot (any
paywall screenshot works — `AppStore/screenshots-6.9/` has them).

These must match `Products.storekit` and `SubscriptionManager.monthlyID/annualID` exactly.
`VolumeTests/SubscriptionTests.swift` asserts the IDs, prices and trial length, so drift
fails the test suite rather than shipping a paywall with nothing to sell.

> **Do Agreements, Tax, and Banking first.** Until the Paid Apps agreement is active,
> `Product.products(for:)` returns an empty array and the paywall shows "Prices couldn't be
> loaded" with nothing explaining why.

---

## Screenshots

`AppStore/screenshots-6.9/` — six at **1320 × 2868**, the required 6.9" size, captured from
the real app with real data by the UI test suite.

| Order | File | Shows |
|---|---|---|
| 1 | `1-home.png` | Start Workout, streak, weekly goal |
| 2 | `2-new-record.png` | The celebration |
| 3 | `3-summary.png` | Post-workout summary with the delta |
| 4 | `4-records.png` | Records tab, PRs per workout |
| 5 | `5-calendar.png` | Month view |
| 6 | `6-active-workout.png` | Logging a set |

Regenerate any time with:

```bash
xcodebuild test -scheme Volume -only-testing:VolumeUITests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -resultBundlePath shots.xcresult
xcrun xcresulttool export attachments --path shots.xcresult --output-path out
```

6.9" is the only size Apple now requires; it scales the rest.

---

## Review notes (paste into App Review Information)

```
Volume has no account system, so no demo credentials are needed.

The entire app is behind an auto-renewing subscription with a 7-day free trial. The paywall
appears after the six onboarding screens. Please use a sandbox Apple Account to start the
trial and access the app.

The app gives no fitness, medical or training advice. It records the sets and reps the user
enters and multiplies them into a single "volume score" for comparison against their own
previous sessions.

Workout data is stored on device and in the user's own private CloudKit database. We collect
no data whatsoever.
```

---

## Still needed before submitting

- [ ] Push the repo to GitHub and turn on Pages (see SUBMISSION-STEPS.md), so all three
      URLs go live. They are already written into the app and the values above.
- [ ] Paid Apps agreement active
- [ ] Archive and upload a **Release** build, then TestFlight it to your own phone
- [ ] Sandbox-test purchase → trial → restore end to end
