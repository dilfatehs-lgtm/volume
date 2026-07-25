# Show HN post

**When:** a weekday morning US Eastern time, ideally Tue–Thu. Post the text below, then stay
available for 3–4 hours — HN threads are won in the comments.

**Title:**
Show HN: Volume – an iPhone workout logger where everything is derived, nothing cached

**URL:** [App Store link] (text goes in the first comment if using a URL post, or make it a
text post with the link inline — text post recommended for the story)

---

I lift four days a week and got tired of workout apps managing me — coaching plans, social
feeds, AI suggestions. The only mechanism that makes lifting work is progressive overload,
so I built an app where that's the entire product: every set is reps × weight, a session
sums to one number, and the app's single job is telling you whether you beat last time.

The architectural decision I'm most attached to: nothing is cached. Scores, two kinds of
streaks, personal records, calendar dots, charts — all recomputed at read time from the raw
set data. It costs almost nothing at this scale and it means backdating a workout or
switching lb/kg is always correct everywhere, because there's no stored aggregate to
invalidate. Every time I was tempted to cache something, the temptation was really a bug
report from the future.

Stack: SwiftUI, SwiftData, CloudKit sync, StoreKit 2. Things that fail at runtime rather
than compile time and cost me days: CloudKit terminates the process (no thrown error to
catch) when the entitlement is missing; SwiftData's CloudKit backend rejects unique
constraints and non-optional relationships only when the container loads; and to-many
relationship mutations don't reliably notify SwiftUI observers, so you mutate through the
parent array or your UI silently goes stale.

Product decisions that were hard to hold: no cardio (one "rep" of treadmill is a
meaningless score), no muscle-group taxonomy (your template names already carry that
meaning), equal-isn't-beating (strictly >), and the current week can never break your
streak — you're only judged on completed weeks.

It's $4.99/mo or $49.99/yr with a 7-day trial — no ads, no data collection ("Data Not
Collected" privacy label), no account. Happy to answer anything about SwiftData+CloudKit,
App Store review, or the one-number design.

---

## Comment prep

- **"Subscription for a logger?" will be the top comment.** Answer once, honestly, don't
  re-litigate: solo dev, no ads/data/investor, subscription or nothing; trial is free.
  Offer: "If the model kills it for you, that's a fair outcome for me to learn."
- **Someone will ask for the web/Android version.** "One platform done properly" — and it's
  true, CloudKit lock-in makes iPhone-first rational for a solo dev.
- **Someone will link a spreadsheet.** Agree with them cheerfully — a spreadsheet is the
  honest competitor. The app is the spreadsheet plus a scoreboard and zero friction at
  the rack.
- **Technical questions are the win condition** — the longer the thread stays on
  SwiftData/CloudKit war stories, the better it does.
