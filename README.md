# GrubOut — calorie & macro tracker

A premium diet tracker in the spirit of MyFitnessPal, with Filipino foods built in.
Flutter app for **iOS** and **Android**.

## Features

| Free | Premium |
|---|---|
| Personal calorie/macro/water plan (Mifflin-St Jeor) | Diet plans with daily meal schedules |
| Food diary: Goal − Food + Exercise = Remaining | Intermittent fasting timer + history |
| Food search: USDA + Open Food Facts + 68 Filipino foods | 30/90-day trends and all smart insights |
| Barcode scanner, quick add, custom foods, recent foods | Custom macro split |
| Copy meals from yesterday, edit/undo entries | |
| Exercise (MET-based), water, weight with charts | |
| Streaks, 5-week weight projection, reminders | |
| Recipes with nutrition, voice and "what I have" search | |
| Light/dark mode, account deletion, local-only data | |

## Run it

```powershell
flutter pub get
flutter run                 # on a connected Android phone / emulator
flutter test                # unit + screen smoke tests
flutter build apk --release # installable Android APK
```

Optional: `--dart-define=USDA_API_KEY=yourkey` (free key from https://fdc.nal.usda.gov/api-key-signup).

## iPhone / App Store

See **[DEPLOY_IOS.md](DEPLOY_IOS.md)**. Builds run on Codemagic's cloud Macs (`codemagic.yaml`)
and upload straight to TestFlight.

## Project layout

```
lib/
  main.dart                 app + 5-slot tab bar (Today · Diary · + · Progress · Discover)
  theme/app_theme.dart      design tokens, light/dark themes
  models/                   data classes
  providers/app_provider.dart  app state
  services/                 SQLite, auth, nutrition math, food APIs, notifications, purchases
  screens/                  one folder per feature
  widgets/                  shared components
assets/icon/                app icon + splash artwork (regenerate: python tool/generate_icon.py assets/icon)
```

All user data lives in an on-device SQLite database. No backend is required.
