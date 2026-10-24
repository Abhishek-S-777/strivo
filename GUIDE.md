# Strivo — Complete Guide

**Strivo** is a premium, offline‑first gym workout tracker for serious lifters. It is built for *fast logging* during a session and *intelligent analysis* afterwards. No social feed, no clutter — just your training and your progress.

- **Platform:** Flutter (Android target configured), dark‑mode only
- **State:** Riverpod · **Navigation:** go_router · **Local DB:** Hive · **Cloud:** Firebase (Auth + Firestore)
- **Design:** "Elite Performance" — deep‑black canvas, periwinkle‑blue primary, lime‑green accent

> Weights display in **kilograms or pounds** — your choice (Profile → Weight Unit). Data is always stored in kg internally and converted on the fly, so you can switch anytime without losing or corrupting anything. Strivo does **not** track height, age, BMI, or body‑fat — "weight" everywhere means the load on the bar/dumbbell. (The only body‑weight field is an optional tag on progress photos, a feature currently disabled.)

---

## 1. Getting Started

1. **Launch → Login screen.** Strivo requires an account (cloud backup + cross‑device sync are core to the experience).
2. **Create Account** with name, email, password (min 6 chars), or **Log In** if you already have one. "Forgot Password?" sends a reset email.
3. On sign‑in, Strivo **pulls your cloud data** into the device. On a fresh account it starts empty.
4. You land on the **Home** dashboard.

Auth is handled by Firebase Authentication (Email/Password). Your session persists, so you go straight to Home on subsequent launches.

---

## 2. The App, Tab by Tab

The bottom bar has four tabs: **Home · Routines · Analytics · Profile.** *(A Progress‑Photos tab exists in the codebase but is temporarily disabled.)*

### 🏠 Home — your dashboard
- **Welcome header** with your name and the date.
- **Volume This Week** hero card: total kg lifted this week, a trend pill vs last week (▲/▼ %), a sparkline of recent weeks, and Workouts / Sets / PRs counters.
- **Today's Workout** card: if you have an **active program**, this shows the program's current session (e.g. "Week 3 · Push Day") with its exercises and prescribed targets, and a one‑tap **Start**. With no active program it falls back to a **Next Routine** card (your most‑recently‑used routine). Either becomes **Resume Workout** if a session is already in progress.
- **Quick Start**: begin an empty (ad‑hoc) workout with no routine.
- **Your Routines**: horizontal quick‑access list.
- **Recent Workouts**: your last sessions with duration, exercise count, volume, and PR badges.

### 📋 Routines — reusable templates
- Tap **New** to open the **Routine Builder**.
- Give it a name (e.g. "Push Day") and optional description.
- **Add Exercise** opens a searchable picker (filter by muscle group, or create a custom exercise).
- For each exercise set **target sets** and **target reps** with +/− steppers.
- **Drag to reorder** exercises. Delete with the ✕.
- **Save.** Start a routine anytime from Home, Routines, or the builder.

### 🗓️ Programs — multi-week structured plans
Open the **Programs** toggle at the top of the Routines tab. A **Program** is a multi-week plan (e.g. a 12-week hypertrophy block, or an ongoing Push/Pull/Legs rotation):

- Tap **New** → name it, set **length in weeks** (or flip **"No fixed end"** for an endless rotation), then add **training days** (Upper A, Lower A, Push, Pull…).
- For each day, **add exercises**. Tap an exercise to set **per-week targets** — sets × reps @ RPE for every week (use **"Wk1 → all"** to fill fast, then tweak the weeks that progress).
- **Set Active** to make it your current plan. Only one program is active at a time.

**Running a program:** Home shows **"Today's Workout"** = the active program's current day, with this week's prescribed sets/reps/RPE. Start it → the sets are pre-built to the prescription, and **weight is pre-filled from your last time on that lift** so you simply work to the target and add load. Finishing **advances the program** to the next day (and rolls to the next week automatically); finite programs finish with 🎉 (and can be restarted). The exact same day next week pre-fills from this week — true week-over-week progression.

### 💪 Active Workout — the core logging screen
This is where speed matters. When you start a routine, Strivo **pre‑fills every set with your last session's weight and reps** for that exercise, so most sets need *zero typing*.

- **Per set:** a `PREVIOUS` column (what you did last time), an inline **weight** field, an inline **reps** field, and a **✓ complete** button.
- **One‑tap adjust:** tap the small −/+ on either side of a number to nudge weight by **2.5 kg** or reps by **1**. Tap the number itself to type an exact value. Long‑press to decrement.
- **Live delta:** when a value differs from last time, a tiny `+x`/`−x` shows under it (green up / red down).
- **Complete a set (✓):** marks it done, fires a light haptic, and **auto‑starts the rest timer**.
- **Add Set** duplicates the last set's values. **Swipe a set left** to delete it.
- **Rest timer** appears as a pill: circular countdown, **+30s**, and stop. Turns red in the last 10 seconds.
- **Reorder** exercises by drag; **⋮** menu adds notes or removes an exercise.
- **Add Exercise** mid‑workout via the bottom action bar (with live Sets/Volume tally).
- **Auto‑save:** the in‑progress session is saved every 10 seconds, so a crash or accidental exit never loses data — you'll be offered to resume.
- **Finish** → confirmation → **Workout Summary**.

### 🏁 Workout Summary
- Celebration header (🏆 if you hit any PRs).
- Stat grid: Duration, Volume, Sets, Exercises — each with a **vs‑previous‑session delta**.
- **Personal Records** list for the session.
- **Exercise Breakdown**: every set, with PR and RPE tags, and per‑exercise volume change.

### 📊 Analytics
- **Volume This Week** hero (number + trend + stats).
- **Smart Insights**: auto‑generated coaching cards (see §4).
- **Strength Trend**: a 1RM curve for a selected lift, with an **EST. 1RM** badge and a horizontal exercise selector. Tap any lift to switch.
- **Weekly Volume**: 8‑week bar chart.
- **Muscle Distribution**: this week's volume split across muscle groups.
- **Consistency**: a 12‑week × 7‑day heatmap (GitHub‑style) colored by daily training load, with an active‑days count.
- **Overall Trend** badge and an **Exercise Progress** list. Tap any exercise → **Exercise History** with a weight/volume chart toggle and a full session table.

### 👤 Profile
- Account card (name/email, cloud‑sync status).
- **All‑Time Stats**: workouts, total volume, total sets, time trained.
- **Settings** (all functional, persisted): **Weight Unit (kg ⟷ lbs)** — switch anytime, the whole app re‑labels and converts instantly; **Default Rest Timer** (0:45–5:00) — used between sets; **Weight Increment** — how much +/- adds when logging (kg: 0.5/1/2.5/5 · lbs: 1/2.5/5/10).
- **Plate Calculator**: enter a target weight; Strivo shows the plates to load **per side**. Unit‑aware: 20 kg bar with kg plates, or 45 lb bar with lb plates.
- **Export Data**: see §6 — CSV, JSON, or an AI‑ready report.
- **Cloud Sync**: backup status and **Sign Out**.
- **About Strivo**.

---

## 3. Where the Exercise Library Comes From

Strivo ships with a **built‑in library of 112 exercises** (the original staples plus the Jeff Nippard 12‑week program movements and their alternatives), seeded into local storage on first launch (`HiveService._seedDefaultExercises`) and refreshed when the bundled library version is bumped. Each carries a **primary muscle**, optional **secondary muscle**, **equipment type**, and an optional set of **alternatives** (substitute lifts shown when the required machine/setup isn't available). Core staples:

- **Chest:** Bench Press, Incline Bench, DB Bench, Incline DB Press, Cable Fly, Chest Dip, Pec Deck
- **Back:** Deadlift, Barbell Row, Pull Up, Lat Pulldown, Seated Cable Row, DB Row, T‑Bar Row, Face Pull
- **Shoulders:** Overhead Press, DB Shoulder Press, Lateral Raise, Front Raise, Rear Delt Fly
- **Biceps:** Barbell/DB/Hammer/Preacher/Cable Curl
- **Triceps:** Pushdown, Skull Crusher, Overhead Extension, Close‑Grip Bench
- **Legs:** Squat, Front Squat, Leg Press, RDL, Leg Curl, Leg Extension, Calf Raise, Lunge, Bulgarian Split Squat, Hack Squat
- **Glutes:** Hip Thrust, Cable Kickback
- **Core:** Plank, Cable Crunch, Hanging Leg Raise, Ab Wheel

You can **add your own** custom exercises (name + muscle + equipment) from the exercise picker. Custom exercises are saved to your library **and backed up to the cloud** (`users/{uid}/exercises`), so they survive a reinstall and follow you to a new device — built‑in exercises ship with the app and don't need per‑user storage. When an exercise has alternatives, a **swap (⟲) button** in the picker lists them so you can pick a substitute in one tap.

---

## 4. How It Works — Formulas & Algorithms

All metrics are computed locally from your logged sets. Only **completed, non‑warmup** sets count toward volume/PRs.

| Metric | Formula / Rule |
| --- | --- |
| **Set volume** | `weight × reps` |
| **Exercise volume** | Σ set volume (completed, non‑warmup) |
| **Session volume** | Σ exercise volume |
| **Estimated 1RM** | **Epley:** `weight × (1 + reps / 30)`, using your heaviest set |
| **Weekly comparison** | This ISO week vs last ISO week (Mon 00:00 boundary). `Δ% = (this − last) / last × 100` |
| **Weekly trend** | `> +5%` = increase, `< −5%` = decrease, else stagnant |
| **Personal Record (PR)** | A completed set whose **weight or volume beats your all‑time best for that exercise**, measured *before* the current session. History updates after. |
| **Training streak** | Number of **consecutive ISO weeks** with ≥ 1 completed workout (current + longest) |
| **Muscle distribution** | Each muscle's share of this week's total volume |
| **Consistency level (per day)** | `0` rest · `1` light · `2` ≥ 33% of your peak day · `3` ≥ 66% of your peak day |
| **Plate calculator** | `per_side = (target − bar) / 2`, greedily filled by plate size. Unit‑aware: 20 kg bar + `[25,20,15,10,5,2.5,1.25]` kg, or 45 lb bar + `[45,35,25,10,5,2.5]` lb |
| **Unit conversion** | Stored in kg; display = `kg × 2.20462` for lbs. 1 plate step = 2.5 kg or 5 lb |
| **Workout intensity** | Relative effort vs your tracked maxes (shown during sessions) |

### Smart Insights engine
After each session Strivo analyzes your history and surfaces prioritized coaching cards:
- 🏆 **PR achieved** (within the last 2 weeks)
- 📈 **Strength climbing** — a lift up **> 2.5 kg** over 4 weeks (needs ≥ 3 sessions of that lift)
- ⏸ **Plateau** — weight flat for 4+ weeks → suggests varying rep ranges/intensity
- 📉 **Strength dropping** — down over 4 weeks → check recovery/sleep/nutrition
- 🎯 **Volume milestones** — lifetime totals (10k → 1,000,000 kg)
- 🔥 **Consistency streak** — escalating emphasis at 4 and 8 weeks
- ⚖️ **Muscle imbalance** — one group's weekly volume > 3× another's
- ⚠️ **Overtraining risk** — same muscle trained ≥ 4× in a week → rest suggestion
- 💪 **Recovery nudge** — 5+ days since your last workout

---

## 5. How to Use Strivo to Actually Progress

Strivo is built around **progressive overload** — doing a little more over time. Here's the loop:

1. **Build a routine** per training day (Push / Pull / Legs, Upper / Lower, etc.).
2. **Start from the routine** so every set is pre‑filled with last time's numbers. Your only job: **beat one number** — add a rep, add 2.5 kg, or add a set.
3. **Watch the PREVIOUS column and the green deltas** in real time — they tell you exactly whether you're progressing this session.
4. **Complete sets with ✓** and let the **rest timer** standardize your recovery between sets (consistent rest = comparable performance).
5. **Check the Summary** — the vs‑last deltas and PR badges confirm the session beat the last one.
6. **Weekly, open Analytics:**
   - Use **Strength Trend / Est. 1RM** to confirm your main lifts are trending up.
   - If you see a **Plateau** insight, change the stimulus (rep range, tempo, an intensity technique, or a small deload).
   - Use **Muscle Distribution** + the **imbalance** insight to keep your programming balanced.
   - Heed **Overtraining** and **Recovery** nudges — gains happen during recovery.
   - Keep the **Consistency heatmap** dark‑to‑bright: showing up beats perfect programming.
7. **Use the Plate Calculator** so you load the bar correctly and quickly.

**Rule of thumb:** every week, aim to beat *something* on each main lift — more reps at the same weight, then more weight. Strivo's pre‑fill + deltas make that the path of least resistance.

---

## 6. Data, Privacy & Sync

- **Offline‑first:** everything works with no connection; the local Hive store is the working source of truth.
- **Cloud backup:** completed workouts, routines, and PR caches sync to **Cloud Firestore** under your account. Signing in on a new device restores everything.
- **Account isolation:** signing in as a *different* user on a device clears the previous user's local training data before restoring (no data mixing).
- **Security:** Firestore rules make every record strictly **owner‑only**.
- See [`DATA_MODEL.md`](DATA_MODEL.md) for the exact collection structure and why it's scalable.

### Exporting your data (Profile → Export Data)

Three formats, shared via the system share sheet (send to yourself, save to Drive, or paste into an AI):

- **AI Training Report (Markdown)** — a readable summary: snapshot (totals, streak), this‑week‑vs‑last, your key lifts with **estimated 1RM** and 4‑week change, muscle focus, and recent sessions. It even includes a **ready‑made prompt** so you can hand it to an AI (like this one) and ask it to fine‑tune your **diet (calories/protein)** and **recovery (sleep, rest days, deloads)**, and flag over/undertrained muscles.
- **CSV** — one row per set (date, exercise, weight, reps, RPE, volume, PR…) in your display unit — open in Excel/Sheets or import into diet/macro apps.
- **JSON** — complete structured backup in canonical kg (lossless), with a summary block.

CSV and the report use your chosen unit (kg/lbs) and label it clearly; JSON is always kg.

---

## 7. Running the Project

Flutter is managed via FVM:

```powershell
& "C:\Users\Abhishek.S\fvm\default\bin\flutter.bat" pub get
& "C:\Users\Abhishek.S\fvm\default\bin\flutter.bat" run        # launch on a device/emulator
& "C:\Users\Abhishek.S\fvm\default\bin\flutter.bat" analyze    # static analysis
& "C:\Users\Abhishek.S\fvm\default\bin\flutter.bat" test       # unit tests
```

**Firebase** project: `strivo-gym`. Email/Password auth and Cloud Firestore must be enabled in the console (already done). Deploy rules with `firebase deploy --only firestore:rules`.

---

## 8. Current Limitations / Disabled

- **Progress Photos** tab — implemented but temporarily commented out.
- **Firebase** is configured for **Android**; other platforms aren't set up.
