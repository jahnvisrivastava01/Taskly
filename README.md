# Todo App

A modern, animated Flutter to‑do list with local reminder notifications, built
on top of the original starter project.

## What's in it

- **Add / edit / delete tasks** — title, optional notes, optional reminder date & time.
- **Reminders that actually fire** — powered by `flutter_local_notifications`, scheduled
  in the device's real timezone (`timezone` + `flutter_timezone`), even if the app is closed.
- **Tick‑and‑gone completion** — tap the checkbox, it fills in with a little bounce,
  pauses for a beat so you see it's done, then the whole row shrinks and fades out.
  Nothing is deleted — completed tasks move into a **Completed** sheet (tap the icon
  top‑right) where you can restore or permanently delete them.
- **Swipe to delete** — swipe a task left to remove it immediately.
- **Animations throughout**:
  - Tasks cascade in one‑by‑one when the app opens or a new task is added.
  - Header fades/slides in on launch.
  - A progress bar animates as you complete tasks.
  - An idle bobbing icon on the empty state.
- **Local persistence** — tasks are saved on‑device with `shared_preferences`, so
  they survive app restarts (no backend/server needed).
- **Light & dark theme** — Material 3, follows the system setting.

## Project structure

```
lib/
  models/task.dart              Task data model + JSON (de)serialization
  services/
    task_storage.dart           Save/load tasks from SharedPreferences
    notification_service.dart   Schedule/cancel reminder notifications
  providers/task_provider.dart  App state (ChangeNotifier) — add/edit/complete/delete/restore
  theme/app_theme.dart          Material 3 light + dark theme
  widgets/
    task_tile.dart              Single task row + all its animations
    add_edit_task_sheet.dart    Bottom sheet for creating/editing a task
    completed_tasks_sheet.dart  Bottom sheet listing completed tasks
    empty_state.dart            "All clear!" placeholder
  screens/tasks_screen.dart     Main screen tying it all together
  main.dart                     App entry point
```

## How to run it

You'll need the Flutter SDK installed (this project targets a recent stable
Flutter/Dart release — run `flutter --version` to check, `flutter upgrade` if
it's old).

```bash
# 1. Get into the project
cd todo_app

# 2. Install dependencies
flutter pub get

# 3. Run it — pick a connected device/emulator, or omit -d to be prompted
flutter run
```

To build a release APK:

```bash
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## Notes on reminders (please read before testing)

Local notifications behave differently by platform and OS version — a couple
of one‑time things to be aware of:

- **Android 13+**: the app requests the `POST_NOTIFICATIONS` permission at
  first launch. If you deny it, reminders won't show — you can re‑enable it
  from the app's system notification settings.
- **Android 12+**: exact‑time alarms need the "Alarms & reminders" permission.
  The app requests it automatically via `requestExactAlarmsPermission()`; on
  some OEM skins (Xiaomi, Oppo, etc.) you may also need to disable battery
  optimization for the app so the OS doesn't kill the scheduled alarm.
- **iOS**: the permission prompt (alert/badge/sound) appears on first launch.
  If you accidentally deny it, re‑enable notifications for the app in iOS
  Settings.
- **Emulators**: notification delivery can be flaky on some Android emulator
  images — testing on a physical device is more reliable.
- A reminder set in the past is simply ignored (the app won't schedule it).

## Honesty note on this build

This code was written and reviewed carefully, but there's no Flutter SDK in
the sandbox I worked in, so I could not run `flutter pub get` / `flutter run`
/ `flutter analyze` to compile-check it myself. The logic and widget APIs are
based on current, stable Flutter/Dart and package APIs, but if you hit a
compile error on your machine, it's most likely one of:

- A pinned package version in `pubspec.yaml` that's slightly behind/ahead of
  what's on pub.dev right now — run `flutter pub upgrade --major-versions` if
  `flutter pub get` complains about version resolution.
- A Flutter SDK version mismatch for a Material 3 API (e.g. `surfaceVariant`,
  `IconButton.filledTonal`) — these are stable as of recent Flutter releases;
  update Flutter if your SDK is older.

If you run into an error, paste it back to me and I'll fix it directly.

## Possible next steps

- Categories/tags and filtering
- Recurring reminders (daily/weekly tasks)
- Drag‑to‑reorder active tasks
- Cloud sync (Firebase, Supabase, etc.) instead of local‑only storage
