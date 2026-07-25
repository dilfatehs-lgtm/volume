# Apple editorial featuring pitch

**Where:** App Store Connect ▸ your app ▸ "Promote Your App" / the Getting Featured
nomination form (also reachable via developer.apple.com/app-store/getting-featured/).
**When:** once at launch, and again in **early December** explicitly pitched at New Year
fitness editorial — Apple plans those collections weeks ahead. Nominations are free and
repeatable; editors read them.

Ready-to-paste answers:

**App description (short):**
Volume is a workout logger built on one idea: your session is one number. Every set is
reps × weight; they sum to a volume score; the app's only job is telling you whether you
beat last time. Streaks reward consistency, records celebrate progress — and there is
deliberately no coaching, no plans, and no social feed.

**What makes your app unique:**
Restraint. Fitness apps compete by adding — coaching, AI, feeds. Volume competes by
subtracting: one number, two streaks, and nothing that tells the user what to do. Every
stat is a fact about the user's own log, never advice. The design premise is that
progressive overload — beat last time — is motivating enough when it's made perfectly
legible. Small details carry it: bodyweight sets score their reps rather than zero,
warm-ups are logged but never inflate the score, equal never counts as beating, and an
unfinished week can never break a streak, so the app never guilt-trips on a Monday.

**Technology adoption:**
Native SwiftUI throughout. SwiftData with CloudKit for automatic cross-device sync with no
account or login. StoreKit 2 for subscriptions with a 7-day free trial. Nothing is cached:
scores, streaks, records and charts are all derived from raw set data at read time, so
backdated workouts and lb/kg switching are always consistent. Full light/dark mode support
following the system. Privacy manifest included; the App Privacy label is "Data Not
Collected" — accurate, since data lives only in the user's own iCloud.

**Accessibility:**
VoiceOver is supported throughout, with composite views exposed as single combined
accessibility elements with meaningful labels rather than fragments of text. Dynamic Type
respected. High-contrast orange accent tested in both appearances.

**Upcoming moments (December nomination):**
New Year's resolution season is precisely Volume's argument: users don't need another
program in January, they need last week's number and a reason to beat it by one rep. The
app's streak design (only completed weeks are judged) is built for resolution-keepers'
long-term consistency rather than a two-week burst.
