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

Two things worth doing once, easy to forget:

1. **CloudKit Console ▸ Schema ▸ Deploy to Production.** Sync silently fails for real users
   until you do this — the development schema doesn't carry over.
2. Change `aps-environment` in `Volume/Volume.entitlements` from `development` to
   `production` if push-driven sync misbehaves in the live build.
