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
Log your sets. Get one number. Beat it next time. Free, with no ads and no noise — just the
number that tells you whether you're getting stronger.
```

Change this on the day 1.1 is released, not before — until then the live build still has a
paywall.

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

FREE

Volume is free. No ads, no in-app purchases, and no data collected.

Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://dilfatehs-lgtm.github.io/volume/privacy.html
```

> **Keep the last two lines for 1.1.** They were added after the 22 July rejection, when
> Apple's automated check wanted the Standard EULA's URL in the description of any app
> offering auto-renewable subscriptions. The old subscriptions stay on sale until 1.1 is
> released, so 1.1 is reviewed while they still exist. The lines say nothing about
> subscriptions and cost nothing. They can go in a later version if you like.

## Every remaining field, answered

**Version 1.0 page**

| Field | Answer |
|---|---|
| Version | `1.1` |
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

Our own Terms are hosted and linked from Settings inside the app; Apple's standard
agreement on top is normal.

**Pricing and Availability**

| Field | Answer |
|---|---|
| Price | **Free**, with no in-app purchases from 1.1 |
| Availability | All countries |
| Pre-Orders | Off |

**IDFA question at submission** — "Does this app use the Advertising Identifier?" → **No.**
No ad SDK, no tracking, nothing in the binary that touches it.

## Keywords (100 max, comma-separated, no spaces)

```
gym,lifting,strength,sets,reps,progressive,overload,weightlifting,tracker,barbell,PR,log
```

Don't repeat words already in the name or subtitle — they're indexed anyway.

## What's New in 1.1

```
Volume is now completely free. No subscription, no trial, no ads — every feature, for
everyone.

If you subscribed: thank you for backing Volume early. Your subscription won't renew. You
can check, or cancel it yourself, in Settings ▸ your name ▸ Subscriptions.
```

The second paragraph is the one place the old subscription is mentioned on purpose. Volume
has no accounts and no email list, so release notes are the only way to tell paying
subscribers, and Apple asks developers to notify them when a subscription is discontinued.

---

## App Privacy — answer "No" to data collection

Select **Data Not Collected**. It is accurate: no analytics, no third-party SDKs, no
account. Workouts live on the device and in the user's *own* private CloudKit database,
which is their storage, not data collected by you. This matches `Volume/PrivacyInfo.xcprivacy`.

## Age rating

All questionnaire answers are **None** / **No**. Expected result: **4+**.

## EU Digital Services Act — trader status

**Declared as a trader** while Volume sold a subscription, since that's commercial activity
under the DSA definition (acting "for purposes relating to his or her trade, business, craft
or profession") even for a sole individual.

From 1.1 the app earns nothing, so **non-trader status may now fit**, and it would take your
address off the EU listing. It's your call, and it isn't automatic: if you ever charge again,
you'd have to switch back.

Entered under App Store Connect ▸ **Business** ▸ Trader Status: legal name, **street
address**, phone and email.

> **Apple publishes all of it on your EU App Store listing**, visible to anyone, and
> verifies it — so it can't be fabricated. The decision here was to use the home address.
> If that becomes uncomfortable once the app is public, the fix is a virtual office or
> registered-agent address (~$10–30/month), updated in the same place. Declining to declare
> removes the app from all EU storefronts.

Not legal advice — worth a word with an accountant if your circumstances change.

---

## Subscriptions — discontinued in 1.1

Version 1.0 sold `com.volume.pro.monthly` (US$4.99) and `com.volume.pro.annual` (US$49.99)
in the **Volume Pro** group, each with a 7-day free trial. From 1.1 the app is free and the
binary contains no StoreKit code at all.

The products still exist in App Store Connect. Apple never deletes an approved in-app
purchase; you can only **remove it from sale**, which stops new purchases and renewals.
Do that the day 1.1 is released, not before. The steps and the reason for that order are in
[SUBMISSION-STEPS.md](SUBMISSION-STEPS.md#going-free--version-11). Don't attach them to
any future submission.

---

## Screenshots

`AppStore/screenshots-6.9/` — six at **1320 × 2868**, the required 6.9" size, captured from
the real app with real data by the UI test suite.

| Order | File | Headline |
|---|---|---|
| 1 | `1-home.png` | Your whole workout, **one number** |
| 2 | `2-active-workout.png` | Log a set **in two taps** |
| 3 | `3-new-record.png` | Beat your score, **progressively overload** |
| 4 | `4-summary.png` | Set new **records** |
| 5 | `5-records.png` | Track your **progress** |
| 6 | `6-calendar.png` | Every session, **all in one place** |

Marketing composites: headline over the real device capture on a near-black background,
app in dark mode so the orange reads as the accent it is. Raw captures are kept in
`raw-captures/`. **Upload in numbered order** — only the first three show on the install
sheet and in search results.

Regenerate any time with:

```bash
# 1. capture (dark mode, so the composites match)
xcrun simctl ui "iPhone 17 Pro Max" appearance dark
xcodebuild test -scheme Volume -only-testing:VolumeUITests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -resultBundlePath shots.xcresult
xcrun xcresulttool export attachments --path shots.xcresult --output-path raw

# 2. composite headlines onto them
swift AppStore/make-screenshots.swift AppStore/raw-captures AppStore/screenshots-6.9
```

Headlines live at the top of `AppStore/make-screenshots.swift` — edit the `shots` array.

6.9" is the only size Apple now requires; it scales the rest.

---

## Review notes (paste into App Review Information)

```
Volume has no account system, so no demo credentials are needed.

Version 1.1 makes Volume completely free. The subscription and paywall from version 1.0 have
been removed, and the binary no longer offers or references any in-app purchase. After the
six onboarding screens the app opens directly. The two existing subscription products
(com.volume.pro.monthly and com.volume.pro.annual) are deliberately not part of this
submission; we will remove them from sale when this version is released.

The app gives no fitness, medical or training advice. It records the sets and reps the user
enters and multiplies them into a single "volume score" for comparison against their own
previous sessions.

Workout data is stored on device and in the user's own private CloudKit database. We collect
no data whatsoever.
```

---

## Still needed before submitting 1.1

See [SUBMISSION-STEPS.md](SUBMISSION-STEPS.md#going-free--version-11).
