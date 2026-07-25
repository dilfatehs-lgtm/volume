# Getting Volume onto the App Store — step by step

Do these in order. Steps 1 and 2 have no dependencies and can happen while step 3 processes,
which is the slow one.

Values to paste live in [LISTING.md](LISTING.md).

---

## Step 1 — Publish the legal pages (10 min)

Three URLs are already written into the app and the listing. They need to be live before
review, and this also gets your code off this Mac for the first time.

**1a. Create the repo** at [github.com/new](https://github.com/new)

| Field | Value |
|---|---|
| Repository name | `volume` |
| Visibility | **Public** — GitHub Pages needs it on the free tier |
| Initialise with README | **No** (leave every checkbox off) |

> The name must be `volume` exactly. The URLs baked into the app are
> `dilfatehs-lgtm.github.io/**volume**/…`. A different name means changing them in
> `PaywallView.swift` and re-uploading the build.

**1b. Connect and push** — tell Claude "the repo is created" and it runs:

```bash
git remote add origin https://github.com/dilfatehs-lgtm/volume.git
git branch -M main
git push -u origin main
```

You'll be asked for credentials. GitHub no longer accepts your account password here — use a
**personal access token** as the password: github.com ▸ Settings ▸ Developer settings ▸
Personal access tokens ▸ Tokens (classic) ▸ Generate new token ▸ tick **repo** ▸ copy it.

**1c. Turn on Pages** — repo ▸ **Settings** ▸ **Pages** (left sidebar)

- Source: **Deploy from a branch**
- Branch: **main**, folder: **/docs** ▸ **Save**

Wait 1–2 minutes, then check all three load:

- https://dilfatehs-lgtm.github.io/volume/ ← Support URL
- https://dilfatehs-lgtm.github.io/volume/privacy.html ← Privacy Policy URL
- https://dilfatehs-lgtm.github.io/volume/terms.html ← Terms / EULA

**They must return real pages, not 404s.** A dead legal link is a guaranteed rejection.

---

## Step 2 — Agreements, Tax, and Banking (20 min, plus Apple's review)

**This is the one that silently breaks everything if skipped.** Until the Paid Apps
agreement is *Active*, `Product.products(for:)` returns an empty array, and your paywall
shows "Prices couldn't be loaded" with nothing on screen explaining why. It looks like a bug
in the app. It isn't.

Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com) ▸ **Business**.
(Older guides call this "Agreements, Tax, and Banking".)

**2a. Accept the Paid Apps agreement**
Find **Paid Apps** in the agreements list ▸ **Request** ▸ read ▸ tick agree ▸ **Submit**.
Status moves to *Pending User Info*. You now have three sub-tasks, all required.

**2b. Contact info** — click **Set Up** next to Contacts and assign a person to each role.
As a solo developer, that's you for all of them: Legal, Financial, Marketing, Technical.

**2c. Bank account** — click **Set Up** next to Bank Accounts ▸ **Add Bank Account**.

You'll need your bank's routing number and account number, and the account holder name must
match your developer account name (**DILFATEH SINGH SHERGILL**, per your certificate). Apple
may take 1–2 days to verify.

**2d. Tax forms** — click **Set Up** next to Tax Forms.

You're registered in the US, so complete the **U.S. Tax Form (W-9)**. It asks for your legal
name, address, and SSN or EIN. As a sole proprietor, your SSN is fine.

> Apple withholds payments until tax forms are complete. This is also the step most likely to
> stall for a day or two, so start it early — hence doing it before the app record.

**Done when: Paid Apps status reads _Active_.** Check back; it isn't instant.

---

## Step 3 — Create the app record (10 min)

App Store Connect ▸ **Apps** ▸ **＋** ▸ **New App**

| Field | Value |
|---|---|
| Platforms | iOS |
| Name | `Volume: Workout Log` |
| Primary language | English (U.S.) |
| Bundle ID | `com.hibeamgroup.volume` (in the dropdown — created when we signed the build) |
| SKU | `volume-001` (internal only, never shown) |
| User Access | Full Access |

If the name is taken, add a word — `Volume: Workout Volume Log`. The home-screen name stays
**Volume** regardless.

Then fill the listing from [LISTING.md](LISTING.md): subtitle, promotional text,
description, keywords, the three URLs from step 1, and the six screenshots in
`screenshots-6.9/`.

Also complete, in the left sidebar:

- **App Privacy** ▸ **Data Not Collected** (accurate — see LISTING.md for why)
- **Age Rating** ▸ all answers None/No ▸ result 4+

---

## Step 4 — Create the subscriptions (15 min)

Your app ▸ **Subscriptions** ▸ **＋** to create a group, reference name `Volume Pro`.

Add two subscriptions inside it, exactly as in LISTING.md:

| Product ID | Duration | Price |
|---|---|---|
| `com.volume.pro.monthly` | 1 month | US$4.99 |
| `com.volume.pro.annual` | 1 year | US$49.99 |

For **each** one:
1. **Subscription Prices** ▸ set the price
2. **Introductory Offer** ▸ ＋ ▸ **Free** ▸ **1 week** ▸ all territories
3. **Localization** ▸ ＋ ▸ English (U.S.) ▸ display name (`Monthly` / `Annual`) and a
   description
4. **Review Information** ▸ upload a screenshot — any from `screenshots-6.9/` works

> The product IDs must match the app exactly. `VolumeTests/SubscriptionTests.swift` asserts
> the IDs, prices and trial length, so if these ever drift apart the test suite fails rather
> than you shipping a paywall with nothing to sell.

---

## Step 5 — Upload a build (Claude does most of this)

Claude archives a Release build and uploads it. You'll need an **app-specific password**
from [account.apple.com](https://account.apple.com) ▸ Sign-In and Security ▸ App-Specific
Passwords — your normal Apple password won't work for uploads.

Alternatively, in Xcode: Product ▸ **Archive** ▸ **Distribute App** ▸ **App Store Connect**.

Processing takes 15–60 minutes. **Export compliance is already declared** in `Info.plist`
(`ITSAppUsesNonExemptEncryption = false`), so you shouldn't be asked about encryption.

---

## Step 6 — TestFlight, and actually test the money (30 min — don't rush this)

Your app ▸ **TestFlight** ▸ add yourself under **Internal Testing** ▸ install via the
TestFlight app on your phone.

Then create a **Sandbox Apple Account**: App Store Connect ▸ **Users and Access** ▸
**Sandbox** ▸ **Test Accounts** ▸ ＋. Use an email you control that is *not* already an Apple
Account. On your phone: Settings ▸ Developer ▸ **Sandbox Apple Account** ▸ sign in.

Now test the whole money path, which **has never run for real** — every previous test used a
local StoreKit file:

- [ ] Paywall shows **$4.99** and **$49.99** from App Store Connect, not the local file
- [ ] "Subscribe" starts the 7-day trial when eligible and unlocks the app (the trial is
      named in the fineprint under the button, after the price — never on the button;
      that wording is a 3.1.2(c) rejection, see round 3)
- [ ] Force-quit and relaunch — still unlocked, no paywall flash
- [ ] **Restore purchases** works from a fresh install
- [ ] Settings ▸ Manage subscription opens Apple's sheet without oddities

Sandbox subscriptions renew on an accelerated clock (a 1-week trial expires in minutes), so
you can also watch it lapse and confirm the resubscribe screen appears **with your workouts
still intact**.

---

## Step 7 — Submit

App record ▸ **Add for Review** ▸ paste the review notes from LISTING.md ▸ **Submit**.

Typical review: 24–48 hours.

**Most common rejections for an app like this, and where each stands:**

| Risk | Status |
|---|---|
| Terms/Privacy links dead | Handled in step 1 — verify they load |
| No restore mechanism | Restore button is on the paywall |
| Price/terms not shown before purchase | Shown under the button |
| Subscription details missing from Terms | Written into terms.html |
| Privacy manifest missing | `PrivacyInfo.xcprivacy` ships in the bundle |
| Health claims | The app makes none, deliberately |

---

## After it's live

1. ~~CloudKit Console ▸ Schema ▸ Deploy to Production.~~ **Done 23 July 2026**, before
   approval — see the status block above.
2. Change `aps-environment` in `Volume/Volume.entitlements` from `development` to
   `production` if push-driven sync misbehaves in the live build. Not urgent: this only
   drives *how promptly* devices learn about each other's changes. With it wrong, records
   still sync on launch and on foreground, just less eagerly — degraded, not broken.

---

## STATUS: rejected 25 July 2026 — round 3, needs a new binary

Round 2 was reviewed on device (iPhone 17 Pro Max, iOS 26.5.2, and an iPad Air 11") and
rejected for two reasons. All four items returned as collateral again.

**3.1.2(c) — the trial was promoted more conspicuously than the price.** The CTA said
"Try free for 7 days" at button weight while the billed amount only appeared in secondary
plan-row text and the footnote. Apple requires the billed amount to be the most clear and
conspicuous pricing element, with trial/intro copy subordinate in position and size.

**2.1(b) — the resubscribe screen's Subscribe button was unresponsive.** Their sandbox
subscription expired on the accelerated clock (expected), the "Your subscription ended"
screen appeared (correct), and tapping Subscribe did nothing. Root cause was a stack of
silent failure modes: `BigButtonStyle` ignored `isEnabled` so a disabled button looked
live; the product catalog loaded once per process with no retry, so one bad load left
nothing to sell; no foreground refresh existed; and the guards in the purchase path
swallowed taps without feedback.

### The fix (in `main`, ships as 1.0 (3))

- Plan rows lead with the price at heavy weight; the plan name is the secondary line.
  The CTA is always **"Subscribe"**; the fineprint leads with the billed amount:
  "$49.99 USD a year after a 7-day free trial. Cancel any time."
- Disabled `BigButtonStyle` buttons now dim (opacity 0.45).
- The paywall and resubscribe screens retry a failed catalog load on appear
  (`ensureProductsLoaded`), and the app re-checks entitlements + products every time it
  returns to the foreground (`refreshOnForeground` via `scenePhase`).
- `purchase()`/`restore()` got separate in-flight flags, so a restore no longer makes
  Subscribe look busy; Restore disables during either flow.
- Unverified transaction updates are logged, deliberately not finished (finishing is
  permanent; redelivery is the retry we want).
- Regression tests: five SKTestSession tests covering purchase → expiry → repurchase,
  the foreground refresh, and catalog-load recovery; the paywall UI test now asserts the
  CTA is "Subscribe", the trial button is gone, and the fineprint leads with the price.

**Known non-fix:** right after a purchase, StoreKit's own "You're all set" alert can
briefly overlap the app swapping to the unlocked UI (their screenshot showed a spinner
under the system alert). That's standard StoreKit 2 timing — `Transaction.updates` lands
before `purchase()` returns — cosmetic, and not the failure they reproduced. Don't chase it.

**1.0 (3) must be built from `main`** — it also finally ships the `7b85435` restore fix
noted below, which round 2 deliberately left out.

### Resubmission

1. Bump build to **1.0 (3)**, archive Release from `main`, upload, wait for processing.
2. Version page ▸ select build 1.0 (3) ▸ **Add for Review** with all four items attached
   (app, both subscriptions, the Volume Pro group) ▸ Submit.
3. Reply in the Resolution Center (draft — attach a current paywall screenshot):

   > Both issues are addressed in build 1.0 (3). For 3.1.2(c): the billed amount is now
   > the most prominent pricing element — it leads each plan row in the heaviest type on
   > the card, the purchase button reads "Subscribe", and the disclosure beneath it leads
   > with the price ("$49.99 USD a year after a 7-day free trial. Cancel any time.").
   > For 2.1(b): the app now reloads the product catalog whenever the paywall or
   > resubscribe screen appears and re-checks entitlements on every return to the
   > foreground, and the purchase button visibly disables when there is nothing to buy.
   > We reproduced the expired-sandbox-subscription flow and verified Subscribe now
   > completes a repurchase.

### Round 2: resubmitted 23 July 2026 — rejected 25 July

The description now carries the EULA link; the build is the same 1.0 (2). All four
items went back in review.

### ⚠️ `main` is ahead of the build under review

Commit `7b85435` fixes **Restore purchases** and is **not in 1.0 (2)**. Whatever goes up
next — a rejection resubmission or 1.0.1 — must be built from `main` so it carries this.

Tapping Restore while already subscribed forced an `AppStore.sync()`, which prompts for an
App Store password and, in the sandbox, asks for production credentials it can't validate:
"Unable to Complete Request". The fix checks `currentEntitlements` first and returns
immediately when entitled, so the common case needs no prompt at all.

Deliberately not uploaded on 23 July: adding a build sends the version back to *Waiting for
Review*, a certain 24–48 hour reset, and the old code is the textbook StoreKit 2 restore
that Apple's own sample uses. In production it works — it just asks for a password it didn't
need. An annoyance, not a broken feature.

Also queued for 1.0.1: Restore gives no positive confirmation on success, it just stays
*Active* silently.

### Round 1: rejected 23 July 2026 — metadata only

Submitted 22 July (iOS App 1.0 (2), both subscriptions, the **Volume Pro group**). Rejected
the next day by an automated check:

> The submission offers auto-renewable subscriptions but does not include a functional link
> to the Terms of Use (EULA) in the app's metadata.

The three subscription items show **Rejected** only as collateral — nothing is wrong with
them. They come back for review automatically when the app is resubmitted.

### Why it happened

Guideline 3.1.2 wants the Terms of Use in **two** places, and we only did one:

| Where | State at submission |
|---|---|
| In the binary | ✅ Paywall links to `terms.html`, which carries every subscription disclosure |
| In the store metadata | ❌ Nothing |

App Information ▸ License Agreement is Apple's **Standard EULA**, so Apple's checker looks
for *that* EULA's URL in the App Description and found none. Having our own terms hosted and
linked inside the app does not satisfy it.

### The fix that was applied — no new build, no re-upload

The build was untouched; this is a text field. Description edits do not require a new binary.

1. App Store Connect ▸ your app ▸ the **1.0** version page ▸ **Description**
2. Replace it with the description in [LISTING.md](LISTING.md) — the only change is the
   `SUBSCRIPTION` paragraph plus these two lines at the end:

   ```
   Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
   Privacy Policy: https://dilfatehs-lgtm.github.io/volume/privacy.html
   ```

3. **Save**
4. **Add for Review** ▸ confirm all four items are attached again (app, both subscriptions,
   the Volume Pro group) ▸ **Submit**

Leave License Agreement on Standard EULA. The alternative — pasting a custom EULA into App
Store Connect — also satisfies the guideline, but it's read by a person rather than a
checker, so it's the slower and riskier of the two paths.

Release is still set to **manual**, so approval lands at *Pending Developer Release* and
nothing goes public until you press the button.

### Three gotchas hit during submission, for next time

- **A link inside the app is not a link in the metadata.** Guideline 3.1.2 wants the Terms
  of Use in both places, and the store-side one is checked automatically. This is what cost
  the first round.

- **The subscription *group* is its own submittable item** and needs its own Localization
  (a Subscription Group Display Name). Without it, submission fails with "your
  auto-renewable subscription must be submitted with its subscription group", which does
  not obviously mean "the group is missing a display name".
- **App Privacy has a separate Publish button.** Answering the questions isn't enough; the
  requirement stays unmet until it's published.

### StoreKit testing: two different accounts, and why the paywall "vanished"

23 July: the TestFlight build walked straight past the paywall. It was not a bug. A
TestFlight build and an Xcode-signed build ask **different Apple Accounts** for entitlements:

| Build | Entitlements come from |
|---|---|
| Xcode-signed / `devicectl` install | the **Sandbox Apple Account** under Settings ▸ Developer |
| TestFlight | your real **App Store account**, in a free sandbox context |

So a free trial started on TestFlight is invisible under Settings ▸ Developer ▸ Sandbox
Apple Account, and survives deleting and reinstalling the app, because the entitlement is
server-side. Check Apple's own sheet via Settings ▸ Manage subscription inside the app
instead.

Proven along the way, by installing a Debug build with temporary `print` diagnostics in
`refreshEntitlements()` and reading it back with
`xcrun devicectl device process launch --console`:

- The gate is fail-closed. With no entitlement, status resolves to `.never` and `RootView`
  shows the paywall. A failed product load never unlocks anything.
- **Both products vend from App Store Connect** — `com.volume.pro.monthly` and
  `com.volume.pro.annual` loaded with `productLoadFailed=false` outside Xcode, so no local
  `.storekit` file was involved. The Paid Apps agreement is active and the subscriptions are
  configured correctly.

> `devicectl --console` forwards stdout/stderr only. `Logger`/`os_log` output never reaches
> it — use `print` for throwaway device diagnostics, or Console.app for the real log.

### CloudKit production schema — DONE 23 July 2026

All six record types (`CD_Exercise`, `CD_WorkoutTemplate`, `CD_WorkoutSession`,
`CD_ExerciseEntry`, `CD_SetEntry`, `CD_WeeklyGoal`) were present in Development, have been
deployed to **Production**, and were **verified listed in the Production environment**. This
was the one item that fails silently — sync would have been broken for every real user while
working perfectly on the owner's own phone.

> If the Production Record Types list ever reads "No record types found" alongside an
> **"Error performing DAW auth"** banner, that's the dashboard's own session failing, not an
> empty schema. Reload in a private window and it comes back. Don't re-deploy on the
> strength of that screen.

Two things worth knowing next time you touch the model:

- **TestFlight and App Store builds use the Production CloudKit environment.** Only
  Xcode-signed development builds use Development. So a schema change tested on your own
  phone is *not* live for testers until it's deployed again.
- **Production schema changes are additive and one-way.** You can add record types and
  fields; you cannot remove or rename them. Adding a property to a `@Model` means another
  deploy.

### If it's rejected again

Send the exact rejection text. Covered already: legal links live and verified, EULA link in
the description, restore button on the paywall, prices and trial terms shown before
purchase, subscription details in terms.html, privacy manifest in the binary.

### Known-good state at submission

- 81 tests green (74 unit + 7 UI) on Xcode 26.6 / iOS 26.5
- Prices **$4.99 / $49.99** with a 7-day free trial, consistent across App Store Connect,
  `Products.storekit`, terms.html, the store description and the README
- Legal pages live at `https://dilfatehs-lgtm.github.io/volume/`
- Screenshots regenerate with `swift AppStore/make-screenshots.swift AppStore/raw-captures AppStore/screenshots-6.9`
