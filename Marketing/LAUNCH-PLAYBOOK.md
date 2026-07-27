# Launch playbook — from zero to posting

Volume is live: https://apps.apple.com/us/app/volume-workout-log/id6793364218
Site: https://dilfatehs-lgtm.github.io/volume/

Work top to bottom. Day 0 is accounts, day 1 is your first video, week 1 is the rest.
Scripts live in [tiktok-scripts.md](tiktok-scripts.md); posts in [reddit-posts.md](reddit-posts.md)
and [show-hn.md](show-hn.md); press pitch in [press-pitch-email.md](press-pitch-email.md).

---

## Day 0 — Accounts (60–90 min, once)

Use the **same handle everywhere** so people can find you. First choice `volumeapp`,
fallbacks `getvolumeapp`, `volumeworkoutlog`, `volume.app`. Check availability on all four
platforms before committing to one.

Sign up for all four with **`volumeworkoutlog@gmail.com`** — the Volume account, made for
exactly this. Not a personal address you'd rather keep separate. That inbox is now the root
credential for every social account, so keep 2-Step Verification on it and don't lose it.

### The four that matter

| Platform | Why | Where |
|---|---|---|
| **TikTok** | Highest ceiling. Fitness is the biggest category on it. | tiktok.com/signup |
| **Instagram** (Reels) | Same clips, second audience. Best for the builder-story format. | instagram.com |
| **YouTube** (Shorts) | Same clips again, long tail — Shorts resurface for months. | youtube.com, create a channel |
| **Reddit** | Where honest launch posts actually convert. | reddit.com/register |

Optional later: X/Twitter (good for the HN/indie crowd), Threads. Don't spread thinner
than four to start.

### Profile setup — identical on all three video platforms

- **Profile photo:** the app icon. Export it from `Volume/Assets.xcassets/AppIcon.appiconset`
  or screenshot it from the App Store listing.
- **Name field:** `Volume — Workout Log`
- **Bio:** *Log your sets. Get one number. Beat it next time. No coaching, no feed.*
- **Link:** `https://dilfatehs-lgtm.github.io/volume/` (the site, not the App Store link —
  the site works on every device and has the download button on it)
- **Category** (TikTok/IG business account): Health & Fitness. Switch to a Business or
  Creator account — it unlocks the link field and basic analytics. Free, takes a minute.

### Reddit — different rules, read carefully

Reddit bans accounts that show up only to promote. Before posting anything about Volume:

1. Create the account, and **do not** name it `volumeapp`. Use a personal-sounding handle.
2. Spend 20 minutes commenting genuinely in r/fitness, r/GYM, r/SideProject. Answer
   questions, be useful. You need a little karma and history or your post gets auto-removed.
3. Read each subreddit's rules page for self-promotion. r/fitness bans it outright — do not
   post there. Others allow it only in weekly threads.

---

## Day 1 — Your first video (about an hour, most of it one-time setup)

### 1. Get the footage onto your phone

The clips are on this Mac at `Marketing/clips/`. AirDrop `clip-BC-log-and-beat.mov` to your
iPhone (Finder → right-click → Share → AirDrop). It lands in Photos.

That clip is 42 seconds and contains: picking a workout → sets logging → score climbing →
confetti when it beats last time → NEW RECORD summary. You'll cut it down to ~18 seconds.

### 2. Install CapCut (free) and build the video

Follow **Script 1** in [tiktok-scripts.md](tiktok-scripts.md) — it has the exact hook text,
timing and caption. Mechanically:

1. New project, import the clip.
2. Trim to the four beats: score visible → sets going in → number crossing last time's →
   confetti. Cut everything else. Target 15–20 seconds.
3. **Hook text on screen from frame one**: `Your entire workout is one number.` White, bold,
   top third. This is the single most important element — most people decide in 1.5 seconds.
4. Add the overlay `last time: 12,140` just before the number crosses it, so the beat lands.
5. Auto-captions → fix any typos → style once → save as a preset for future videos.
6. Add a trending sound at ~10% volume (browse TikTok's Sounds tab, pick something with
   momentum, save it). Optional: record a voiceover reading Script 1's lines.
7. Export 1080×1920.

**Do not** spend more than an hour on this. Retention beats polish, and video #1 is
mostly practice for videos #2–20.

### 3. Post it

**TikTok:** + button → Upload → pick the video → caption below → add hashtags → Post.

> Caption: My workout app has one job: tell me if I beat last week.
> #gymtok #progressiveoverload #workoutapp #lifting

**Instagram Reels:** + → Reel → same file → same caption → share to Feed as well.

**YouTube Shorts:** Create → Upload → same file. Title = the hook line. Add
`#Shorts` in the description.

Post the file natively to each platform — never share a TikTok-watermarked export to
Instagram, the algorithm buries it.

### 4. Then stay for an hour

Reply to every comment for the first hour, and check back for the first 24 hours.
Early comment velocity is a ranking signal, and hostile comments are free material
(see Script 7 — the "why pay when Hevy is free?" reply video).

---

## Week 1 — the rest of the launch

Space these out. Doing them all on day one wastes them.

| Day | Do this |
|---|---|
| 1 | Video #1 (above). Nothing else. |
| 2 | **r/SideProject** post — text is written in [reddit-posts.md](reddit-posts.md). Stay in comments 24h. |
| 3 | Video #2 — Script 2 (builder story) or Script 3 (anti-feature list). |
| 4 | **Show HN** — text in [show-hn.md](show-hn.md). Post Tue–Thu, ~9am US Eastern, then stay available 3–4 hours. |
| 5 | Video #3 — Script 5 (the 8-second confetti loop, made to loop). |
| 6 | **Press emails** — [press-pitch-email.md](press-pitch-email.md). Send individually to MacStories, The Sweet Setup, 9to5Mac. Personalize line one. Include a promo code. |
| 7 | **r/iosapps** post + Video #4. Review your numbers (below). |

### Promo codes for press and creators

App Store Connect ▸ your app ▸ **Promo Codes** — you get 100 per version, free. Generate
10 for press and creators. Also consider **Offer Codes** (Subscriptions ▸ your subscription
▸ Offer Codes) for a custom code like `LAUNCH50` that creators can share with their audience.

---

## Weeks 2–8 — the actual work

**3–5 videos per week.** This is a volume game (yes). Most videos do nothing; one in twenty
carries everything. Ten scripts are written — reuse formats that worked, drop what didn't.

Film real gym B-roll on your phone whenever you train: rack, plates loading, chalk, your
hand tapping the phone between sets. 5–10 seconds each, vertical. Mixing one real shot into
screen recordings roughly doubles how authentic they feel.

Need fresh app footage? Recapture any clip in a minute — the rig is
`VolumeUITests/MarketingFootageUITests.swift`, instructions in its header.

---

## What to watch (and what to ignore)

Ignore follower count. Watch these, in App Store Connect ▸ Analytics and Trends:

| Metric | Where | What it tells you |
|---|---|---|
| **Impressions → downloads** | Analytics | Whether your listing converts browsers |
| **Trial starts / downloads** | Trends ▸ Subscriptions | Whether people who see the paywall want it |
| **Trial → paid conversion** | Trends ▸ Subscriptions | Whether they'll pay. **The number that decides everything.** |
| **Day-7 retention** | Analytics | Whether the loop actually holds people |

Trial→paid takes 7+ days to mean anything (that's the trial length). Don't panic before
day 14. Industry-typical trial→paid for a paid utility is 20–40%; below 15% means the
paywall or the price is wrong, not the app.

If downloads are low but trial→paid is high → marketing problem, make more videos.
If downloads are fine but trial→paid is low → pricing or paywall problem, and that's
worth a conversation before making more videos.

---

## December — the one calendar item

**Early December:** submit the Apple featuring nomination
([apple-featuring.md](apple-featuring.md) has the answers written), explicitly pitched at
New Year fitness editorial. Apple builds those collections weeks ahead.

**Dec 26 – Jan 15:** Script 10 is written for exactly this window. January is the Super Bowl
for fitness apps; whatever is working by then, pour fuel on it.

---

## Things not to bother with

- Product Hunt (low value for consumer fitness)
- Paid "app review" sites (scams)
- Press-release distribution services
- Instagram grid posts (Reels only)
- Apple Search Ads **for now** — revisit once trial→paid proves the funnel converts. Ads
  amplify a working funnel; they can't fix a broken one. Budget ceiling when you do:
  ~$15–20 per subscriber against a $49.99/yr price.
