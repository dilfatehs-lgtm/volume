# Volume — TikTok / Reels / Shorts playbook

## Ground rules (read once, then just execute)

- **The first 1.5 seconds decide everything.** Hook text must be on screen in frame one,
  before anything else happens. Never open with a logo.
- **9:16, captions always on** (CapCut auto-captions, then fix typos by hand). Most viewers
  watch muted.
- **≤ 30 seconds** for everything until something hits. Retention % beats production value.
- **Cadence:** 3–5 posts/week for 6–8 weeks before judging anything. Post the same clip to
  TikTok, Reels, and Shorts — native upload each time, no watermarks crossing platforms.
- **Never delete flops.** The algorithm doesn't punish them and old videos resurface.
- **Audio:** use a low-volume trending sound under your VO. In-app sounds off; the confetti
  moment gets a sound effect in the edit instead.
- **Comments are the second channel.** Reply to every comment for the first 24h; turn the
  best hostile comment into next week's reply-video (script 7 is the template).

## Footage — CAPTURED, in `Marketing/clips/` (1206×2622 portrait, 9:41 status bar)

| File | What's on screen | Used by scripts |
|---|---|---|
| clip-A-home.mov (18s) | Home: score + streak, slow scroll | 1, 2, 4, 10 |
| clip-BC-log-and-beat.mov (42s) | The hero take: pick workout → sets logged, score climbing → confetti beat moment → NEW RECORD summary | 1, 2, 4, 5, 6, 10 |
| clip-D-records.mov (25s) | Records tab: streaks, PRs, into one workout's chart | 3, 6, 7 |
| clip-E-calendar-backdate.mov (42s) | Calendar dots → backdating a forgotten workout, dot appears | 6, 8 |
| clip-F-unit-switch.mov (29s) | Settings lb→kg, Home scores converted | 3, 9 |

Recapture any time: `TEST_RUNNER_MARKETING_FOOTAGE=1 xcodebuild test-without-building
-only-testing:VolumeUITests/MarketingFootageUITests/<clip> …` while
`xcrun simctl io <udid> recordVideo` runs (see MarketingFootageUITests.swift header).

Film real-gym B-roll on your phone whenever you train (rack, plates loading, chalk) — 5–10
seconds each, vertical. Mixing one real shot into screen recordings doubles authenticity.

---

## Script 1 — "One number" (the flagship demo — post this first)
**Format:** screen recording + VO · ~18s
**Hook (frame 1):** `Your entire workout is one number.`
| Time | Screen | Overlay / VO |
|---|---|---|
| 0–2s | Clip A, score big | VO: "This is my whole workout. One number." |
| 2–8s | Clip B, sets going in, number climbing | VO: "Every set — reps times weight — added up. That's it." |
| 8–13s | Score passes last time's | Overlay: `last time: 12,140` → number crosses it |
| 13–16s | Clip C confetti | VO: "Beat last time. That's the entire app." |
| 16–18s | Home screen | Overlay: `Volume — on the App Store` |
**Caption:** My workout app has one job: tell me if I beat last week. #gymtok #progressiveoverload #workoutapp #lifting

## Script 2 — Builder story (post week 1; best Reels performer)
**Format:** face-to-cam or text-over-footage · ~28s
**Hook:** `Every workout app annoyed me. So I built my own.`
Beats: (0–5s) "Coaching plans I didn't ask for. A social feed. Twelve charts." — quick cuts,
exasperated. (5–12s) "The only thing that makes lifting work is doing slightly more than
last time. So that's the whole app." (12–22s) Clips B+C. (22–28s) "No account, no feed, no
coaching. It's called Volume. If it sounds like your kind of thing, it's on the App Store."
**Caption:** Solo-built. One number. #buildinpublic #indiedev #gymtok #workoutapp

## Script 3 — Anti-feature list (trend-friendly, remixable)
**Format:** list video, text overlays punch in one by one · ~20s
**Hook:** `Things my workout app refuses to do:`
Overlays in rhythm with the sound: `❌ coach you` · `❌ sell you a plan` · `❌ social feed` ·
`❌ AI anything` · `❌ tell you what "counts"` — then beat drop → `✅ one number. beat it.`
over Clip C. End card: `Volume`.
**Caption:** Features are a distraction. #minimalism #gymtok #workoutapp #antifitness

## Script 4 — The psychology one (highest save-rate potential)
**Format:** VO over Clips A+B · ~22s
**Hook:** `The dumbest reason you're not progressing:`
VO: "You don't remember what you did last week. That's it. That's the reason. Progressive
overload isn't a program — it's a memory problem. Write down every set, get one total,
and walk in next week with a number to beat. You don't need more knowledge. You need a
scoreboard."
**Caption:** It's a memory problem, not a knowledge problem. #progressiveoverload #gymtok #hypertrophy

## Script 5 — The confetti loop (8 seconds, made to loop)
**Format:** pure screen recording, slow-mo · 8–10s
**Hook:** `most satisfying 2 seconds of my gym session`
Clip B final set → score ticks over last time's → Clip C confetti in slow-mo → cut so the
loop restarts seamlessly. No VO. One sound effect on the beat.
**Caption:** beat last week. that's the game. #satisfying #gymtok #pr

## Script 6 — Don't break the chain
**Format:** screen recording + VO · ~20s
**Hook:** `Don't break the chain — gym edition.`
Clip E calendar dots → Clip D streaks. VO: "Pick how many days a week you train. Hit it,
streak grows. And a detail I care about: the current week can never break your streak —
you're only judged on finished weeks. No app guilt on a Monday."
**Caption:** Only finished weeks count. #habits #dontbreakthechain #gymstreak #gymtok

## Script 7 — Reply video: "why pay when Hevy is free?"
**Format:** reply-to-comment sticker, face or VO · ~22s
**Hook:** the pinned comment itself.
VO: "Totally fair — Hevy's good, and if you use its features, use it. You're not paying me
for more features. You're paying for fewer. No feed, no coaching, no ads, nothing between
you and one number. Some people want a Swiss army knife. I wanted a knife." → Clip A.
**Caption:** Fewer features is the feature. #workoutapp #gymtok
*(Post only as an actual reply once a real comment like this exists — it will.)*

## Script 8 — Forgot to log Tuesday?
**Format:** screen recording + VO · ~15s
**Hook:** `Forgot to log Tuesday's workout?`
Clip E: backdate a session. VO: "Backdate it. Streaks, records, charts — everything
recalculates like it was always there. Nothing in the app is cached; it's all recomputed
from your actual sets." Overlay: `your log is facts, not vibes`.
**Caption:** Backdating just works. #workoutapp #gymtok #indiedev

## Script 9 — The 0 lb detail
**Format:** screen recording + VO · ~14s
**Hook:** `My app knows 0 lb doesn't mean 0 effort.`
Clip F / logging pull-ups at bodyweight. VO: "Pull-ups don't score as zero — bodyweight
sets count their reps. Warm-ups get saved but don't inflate your score. Small details, but
they're the difference between a number you trust and a number you ignore."
**Caption:** Details make the number honest. #calisthenics #gymtok #workoutapp

## Script 10 — New Year (bank it now, post Dec 26 – Jan 15)
**Format:** VO over Clips A+C + gym B-roll · ~20s
**Hook:** `You don't need a program in January.`
VO: "Every January the apps sell you plans, coaching, transformations. You need one thing:
last week's number, and the will to beat it by one rep. That's sustainable past February.
That's the whole app." → Clip C.
**Caption:** Beat last week. Repeat 52 times. #newyearsresolution #gymtok #2027goals

---

## Editing recipe (CapCut, ~15 min/video once practiced)
1. New project, 9:16. Import sim recording + B-roll.
2. Sim footage: either fullscreen (crop tastefully) or in a device frame at ~85% width on a
   dark background — pick one style and keep it for every video (brand consistency).
3. Hook text: white, bold, top third, on from frame 1. Use the same font every video.
4. Auto-captions → fix errors → style them once → "save as preset".
5. Trending audio at ~10% volume under VO. VO recorded on iPhone mic ~10 cm away.
6. Export 1080×1920, upload natively per platform. Post morning or lunchtime; consistency
   beats optimal timing.
