# Reddit launch posts

**Before posting anywhere:** read each subreddit's rules that day. Fitness subs especially —
r/fitness bans self-promo outright (don't post there), others allow it only in weekly
threads. Getting banned in week one costs more than any post gains. Space these out over
several days, and stay in the comments for 24 hours after each — the comments are where
these posts win or die. Never post the same text twice; each below is written for its sub.

---

## 1. r/SideProject (also fits r/indiehackers) — the builder story

**Title:** I built a workout logger that refuses to coach you — one number, beat it next time

Two years of using popular workout apps left me with the same feeling: I'm being managed.
Coaching plans I didn't ask for, a social feed, AI suggestions, charts of everything.

The only thing that actually makes lifting work is progressive overload — do slightly more
than last time. So I built an app where that's the entire product. You log your sets, every
set is reps × weight, they add up to one number, and next session you try to beat it. Streaks
for consistency, confetti when you beat yourself. That's it.

Deliberate omissions, all one-way doors I wrote down before building: no accounts, no social,
no coaching, no cardio (one "rep" of treadmill is a meaningless score), no muscle-group
taxonomy (your own template names carry that meaning already).

Tech, since this sub asks: SwiftUI + SwiftData + CloudKit sync, and one architectural rule —
everything is derived, nothing is cached. Streaks, records, charts are all recomputed from
raw sets at read time, which is why backdating a workout or switching lb/kg "just works."

It's iPhone-only, subscription with a 7-day free trial ($4.99/mo or $49.99/yr). Happy to
answer anything about the build or the App Store submission process (two genuinely
undocumented gotchas in that one).

[App Store link]

## 2. r/iosapps — the straight launch post

**Title:** [Free trial] Volume — a workout log that gives you one number to beat

Just launched. Volume is a deliberately minimal workout logger: log sets → get your total
volume (reps × weight, summed) → beat it next session. Two streaks (a per-workout record
streak and a weekly consistency streak), PRs, and a per-workout chart. Nothing else.

Native SwiftUI, iCloud sync, no account, App Privacy label is "Data Not Collected." Light
and dark mode, lb/kg, VoiceOver support.

7-day free trial, then $4.99/mo or $49.99/yr. Would love feedback from this sub —
especially on the paywall flow, which I've only ever tested with sandbox accounts.

[App Store link]

## 3. Fitness subs (r/GYM, r/workout, r/naturalbodybuilding — weekly/self-promo threads ONLY)

**Title (or thread comment):** I made a workout app with no coaching in it, on purpose

Genuine question wrapped in a launch: does anyone else feel like workout apps have too many
opinions? I lift 4 days a week and wanted exactly one thing from an app: what did I do last
time, and did I beat it.

So I made one. Each session is one number — total volume — and the app's only job is
remembering it and telling you if you topped it. It will never tell you what to lift, when
to rest, or what a "good" week is. You pick your own weekly goal; it just counts.

If that's how your brain works too, it's called Volume, iPhone, free week to try it. And
if you think one number is reductive — fair, tell me why, the tradeoff genuinely interests
me. (Deloads and strength blocks are the strongest objection I know of; the app treats a
new workout's first session as neutral, but a planned lower-volume week will read as a
miss. I chose honesty-of-the-number over smartness. Debate welcome.)

## Comment ammunition (answers you'll need repeatedly)

- **"Why not free?"** — No ads, no data collection, no investor. The subscription is the
  business model. Trial's free; if one number isn't worth it, no hard feelings.
- **"Volume isn't the only progress metric."** — True. It's the most legible one. The app
  measures the log; it doesn't claim to measure you.
- **"Android?"** — iPhone-only for now; it's a solo project and I'd rather do one platform
  properly.
- **"What about deload weeks?"** — See script above; be honest, don't get defensive. "The
  number is honest even when the plan says go lighter" has won this argument before.
