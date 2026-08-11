# Scheduler - Copilot Instructions

## Overview
Flutter app that builds TEDU course schedules from asset JSON datasets. It loads datasets, builds section combinations with conflict checks, supports free-day filtering, persists schedules, and compares course stats across terms. Web (WASM) is the primary target, but Android/iOS/desktop are supported.

## Stack & Conventions
- Flutter + Material 3; default locale is `tr-TR`.
- State: Riverpod + Hooks (`@Riverpod`/`@riverpod`).
- Generated files: `*.g.dart` (do not edit).
- After provider changes run:
  - `flutter pub run build_runner build --delete-conflicting-outputs`
- UI strings are Turkish unless explicitly requested otherwise.

## Data & Models
- Course data lives in `assets/schedules/*.json` with a `courses` array.
  - Required keys (per `Course.fromJson`): `Code`, `Name`, `Section`, `Schedule`.
  - Optional top-level `metadata` is supported (created by `convert_excel_to_json.py`).
- Dataset discovery: `lib/features/datasets/providers/asset_datasets_provider.dart`
  - Uses `AssetManifest.json`, ignores files starting with `example`.
  - Parses `YYYY-YYYY_NNN.json` for year/period; falls back to `Year`/`Period`.
  - Period codes like `001` are normalized to `1`.
- Update `AppConstants.datasetUpdateDate` when adding new datasets.
- Models: `Course`, `TimeSlot`, `SavedSchedule`.
- Comparison stats expect fields like `# of Students`, `Successfull/Successful`,
  `Unsuccessfull/Unsuccessful`, `Conditional`.

## Schedule Logic (Critical)
- Primary field is `Course.schedule` (string). `Course.timeSlot` only covers
  single-slot formats.
- Always use `_parseMultipleTimeSlots()` in
  `lib/features/course_selection/providers/course_providers.dart` for
  conflicts and timetable filling. For other files use
  `parseMultipleTimeSlots()` (public wrapper).
  - Supports multi-day groups like `Tu/Fr 13 - 15`.
  - End hour is exclusive.
  - Day normalization accepts TR/EN full names and abbreviations.
- Free-day filter counts weekdays only (Pazartesi–Cuma).

## Providers & Flow
```
assets/schedules/*.json -> coursesProvider
-> filteredCoursesProvider -> courseGroupsProvider
-> selectedCoursesProvider -> scheduleCombinationsProvider
-> activeCombinationIndexProvider -> activeScheduleProvider
```
- Selected courses + filter settings are persisted and restored on startup.
- Active dataset path is persisted in `active_dataset_path` and defaults to the
  most recent dataset (year/period sort).

## Persistence
- `StorageService` uses `shared_preferences` on all platforms.
- Prefer `storageService` (global) for app data; use `InMemoryStorageService`
  in tests.
- Saved schedules: `_kKeyItems`; active schedule: `_kKeyActiveSchedule` and
  `_kKeyActiveScheduleId`.
- Saved schedules store dataset path/year/period plus filter settings.

## Analytics (Web)
- `AnalyticsService` wraps Firebase Analytics with user consent
  (`analytics_consent` in SharedPreferences).
- `main.dart` initializes Firebase; failures are caught so the app can run
  without analytics.
- `MetricsService` (Firestore `course_stats`) is gated by the same consent.
- Build scripts inject Firebase env via `--dart-define-from-file=firebase_config.env`.

## Build & Tooling
- Web builds:
  - `./build_dev.sh` (WASM dev)
  - `./build_production.sh` (WASM release)
  - `./build_js_only.sh` (JS-only release)
- Web builds (PowerShell):
  - `.\build_dev.ps1` (WASM dev)
  - `.\build_production.ps1` (WASM release)
  - `.\build_js_only.ps1` (JS-only release)
- Firebase config: create `.env` from `.env.example` and keep
  `firebase_config.env` in sync.
- Dataset conversion: `python convert_excel_to_json.py` writes to
  `assets/schedules/` and updates `AppConstants.datasetUpdateDate`.

## Tests
- `flutter test`
- Key coverage: time slot parsing, schedule combinations, saved schedules,
  theme persistence, export format.

## When editing
- Update tests when changing schedule parsing, dataset selection, or storage keys.
- Keep dataset warnings and comparison logic aligned with dataset metadata.
- If dataset shape or conversion changes, update `convert_excel_to_json.py` and
  `README.md` together.
