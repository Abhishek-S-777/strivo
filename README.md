# Strivo

**Premium, offline‑first gym workout tracker for serious lifters.** Fast logging, strength analytics, smart insights, and cloud backup — dark‑mode only, no social clutter.

![status](https://img.shields.io/badge/flutter-3.38-blue) ![status](https://img.shields.io/badge/state-Riverpod-7c4dff) ![status](https://img.shields.io/badge/backend-Firebase-orange)

## Highlights

- ⚡ **Fastest logging UX** — every set pre‑filled from last time; one‑tap +/− for weight & reps; auto rest timer; auto‑save.
- 📈 **Strength analytics** — estimated 1RM curves, weekly volume, muscle distribution, 12‑week consistency heatmap.
- 🧠 **Smart Insights** — automatic coaching: PRs, plateaus, imbalances, overtraining, streaks, recovery.
- ☁️ **Offline‑first + cloud sync** — works with no connection; backs up to Firestore per account.
- 🎨 **"Elite Performance" design** — deep‑black canvas, periwinkle primary, lime accent.

## Tech Stack

Flutter · Riverpod · go_router · Hive (local) · Firebase Auth + Cloud Firestore · fl_chart

Clean, feature‑first architecture under `lib/features/*/{domain,presentation}` with a shared theme in `lib/core/theme`.

## Documentation

- 📘 **[GUIDE.md](GUIDE.md)** — complete end‑to‑end guide: every feature, how to use it, the formulas/algorithms, where the exercise library comes from, and how to use the app to actually progress.
- 🗄️ **[DATA_MODEL.md](DATA_MODEL.md)** — local + Firestore schema and why it's scalable.

## Run

Flutter is managed via FVM on this machine:

```powershell
& "C:\Users\Abhishek.S\fvm\default\bin\flutter.bat" pub get
& "C:\Users\Abhishek.S\fvm\default\bin\flutter.bat" run
```

Firebase project: `strivo-gym` (Email/Password auth + Cloud Firestore enabled).
