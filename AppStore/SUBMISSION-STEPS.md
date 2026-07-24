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
- [ ] "Try free for 7 days" starts the trial and unlocks the app
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

## STATUS: resubmitted 23 July 2026, in review

Round 2. The description now carries the EULA link; the build is the same 1.0 (2). All four
items back in review.

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
