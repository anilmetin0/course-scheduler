# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Flutter app that builds TEDU course schedules from asset JSON datasets: loads datasets, generates section combinations with conflict checks, supports free-day filtering, persists schedules, and compares course stats across terms. Web (WASM) is the primary target; Android/iOS/desktop also supported. UI strings are Turkish (default locale `tr-TR`); keep them Turkish unless explicitly requested otherwise. This is an unofficial student project, not affiliated with the university.

## Commands

```bash
flutter pub get                                        # install deps
flutter test                                           # all tests
flutter test test/course_service_test.dart             # single test file
flutter test --plain-name "combination"                # tests matching a name
flutter analyze                                        # lint
dart run build_runner build --delete-conflicting-outputs  # regenerate *.g.dart after provider/model changes

# Run web locally (Firebase optional; app degrades gracefully without it)
flutter run -d chrome --dart-define-from-file=firebase_config.env \
  --dart-define=GIT_SHA=$(git rev-parse --short HEAD)

# Web builds (PowerShell twins exist: build_*.ps1)
./build_dev.sh          # WASM dev
./build_production.sh   # WASM release
./build_js_only.sh      # JS-only release

# Dataset conversion (Excel/CSV/TSV/XML -> JSON in assets/schedules/)
python convert_excel_to_json.py

# Deploy (Firebase Hosting; predeploy runs build_production.sh)
firebase deploy --project course-scheduler-25
```

Firebase config: copy `.env.example` to `.env`, keep `firebase_config.env` in sync (same keys, gitignored). `lib/firebase_options.dart` contains no keys — everything comes from `--dart-define` env at build time; missing config throws at startup, but `main.dart` catches Firebase init failures so the app runs without analytics.

## Architecture

State: Riverpod + Hooks (`@riverpod` annotations). Generated `*.g.dart` files are committed — never edit them, rerun build_runner instead.

Provider data flow (the spine of the app):

```
assets/schedules/*.json -> coursesProvider
-> filteredCoursesProvider -> courseGroupsProvider
-> selectedCoursesProvider -> scheduleCombinationsProvider
-> activeCombinationIndexProvider -> activeScheduleProvider
```

Selected courses + filter settings are persisted and restored on startup. Active dataset path persists under `active_dataset_path`, defaulting to the most recent dataset by year/period sort.

### Schedule parsing (critical)

- `Course.schedule` (string) is the primary field; `Course.timeSlot` only covers single-slot formats.
- Conflict checks and timetable filling must go through `_parseMultipleTimeSlots()` in `lib/features/course_selection/providers/course_providers.dart` (public wrapper: `parseMultipleTimeSlots()` for other files). It handles multi-day groups like `Tu/Fr 13 - 15`; end hour is exclusive; day names accept TR/EN full names and abbreviations.
- Free-day filter counts weekdays only (Pazartesi–Cuma).

### Datasets

- `assets/schedules/*.json` with a `courses` array. Required keys per `Course.fromJson`: `Code`, `Name`, `Section`, `Schedule`. Optional top-level `metadata` (written by `convert_excel_to_json.py`).
- Real datasets are gitignored; only `example_past.json` / `example_future.json` are tracked.
- Discovery in `lib/features/datasets/providers/asset_datasets_provider.dart`: reads `AssetManifest.json`, ignores files starting with `example`, parses `YYYY-YYYY_NNN.json` for year/period (falls back to `Year`/`Period` fields), normalizes period `001` -> `1`.
- When adding datasets, update `AppConstants.datasetUpdateDate`. Comparison stats expect fields like `# of Students`, `Successfull/Successful`, `Unsuccessfull/Unsuccessful`, `Conditional`.

### Persistence

`StorageService` wraps `shared_preferences` on all platforms. Use the global `storageService` for app data; use `InMemoryStorageService` in tests. Saved schedules live under `_kKeyItems`, active schedule under `_kKeyActiveSchedule` / `_kKeyActiveScheduleId`, and store dataset path/year/period plus filter settings.

### Analytics (web, consent-gated)

`AnalyticsService` (Firebase Analytics) and `MetricsService` (Firestore `course_stats`) are both gated behind user consent stored in `analytics_consent`. No consent, no writes.

## When editing

- Update tests when changing schedule parsing, dataset selection, or storage keys.
- If dataset shape or conversion changes, update `convert_excel_to_json.py` and `README.md` together.
- `.github/copilot-instructions.md` mirrors this guidance; keep the two aligned when conventions change.
