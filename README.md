# Keel

A Flutter productivity prototype for daily reflection, goals, routines, focus sessions, and weekly reviews. Built by [Harshit Sharma](https://github.com/Harshit745).

## Features

| Feature | Current implementation |
| --- | --- |
| Accounts | Firebase email/password sign-up, sign-in, and authentication routing |
| Daily reflection | Energy, focus, distraction, clarity, notes, validation, and one locally stored entry per day |
| History and charts | Browse reflections, visualize scores, and view weekly reports |
| Insights | Deterministic reflection-index and self-trust calculations; rule-based pattern analysis |
| Daily command center | Tasks, priorities, energy-based suggestions, habits, and calendar overview |
| Life areas scorecard | Editable health, work, relationship, learning, and finance scores |
| Goal breakdown | Goals with template weekly/daily actions and task creation |
| Routine builder | Morning/evening routines, completion controls, and experimental streak tracking |
| Focus sessions | Foreground countdown timer, session records, and distraction logging |
| Reflection journal | Rotating prompts and journal responses |
| Decision journal | Expected outcomes, review dates, and actual outcomes |
| Weekly review | Local summary of tasks, focus, reflections, and life areas |
| Context reminders | Context/location labels and time fields; no native notifications or geofencing |
| Knowledge vault | Notes linked to goals |
| Accountability | Generate progress snapshots and manually mark them sent; no delivery integration |

The home screen links to four core reflection views and eleven additional productivity screens.

## Status and limitations

This is a prototype. Reflections persist locally using Hive. The newer feature module uses static lists and maps with starter examples: tasks, goals, routines, journal records, reminders, notes, and snapshots reset when the process restarts.

Insights use rules, not a trained model or external AI service. Cloud Firestore and Google Sign-In dependencies are present, but cloud synchronization and Google authentication are not connected in the current application flow.

The local reflection box is not scoped to individual Firebase users. Account-specific storage and deletion controls are needed before sensitive data or shared-device use. Platform folders are included, but individual platform builds have not been verified for this snapshot.

## Stack

Flutter, Dart (SDK constraint `^3.8.1`), Firebase Core/Authentication, Hive, generated Hive adapters, `fl_chart`, and Material widgets with a dark theme.

## Setup

Install Flutter and native tooling for your target, then:

```sh
git clone https://github.com/Harshit745/keel.git
cd keel
flutter pub get
```

Create your own Firebase project and enable **Authentication → Email/Password**. Install the Firebase CLI and configure your target platforms with FlutterFire:

```sh
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
flutter run
```

`flutterfire configure` generates `lib/firebase_options.dart` and platform configuration for your Firebase project. Use your own resources and matching application identifiers. Local Firebase configuration files are excluded from new commits.

Regenerate the reflection adapter after model changes:

```sh
dart run build_runner build --delete-conflicting-outputs
```

## Structure

```text
lib/
  main.dart              # Firebase/Hive startup and auth routing
  auth_service.dart      # Email/password authentication
  app_state.dart         # Persistent reflection state
  home_screen.dart       # Navigation
  reflection*.dart       # Entry, history, and charts
  weekly_report*.dart    # Reports and calculations
  models/                # Reflection and goal models, Hive adapter
  engines/               # Deterministic analysis rules
  features/              # Eleven screens and in-memory feature state
  services/              # Goal insight logic
  ui/                    # Colors and typography
  widgets/               # Reusable widgets
```

## Validation

```sh
flutter analyze
flutter test
```

The existing test is an obsolete Flutter counter scaffold referencing `MyApp`; the application root is now `KeelApp`. It needs replacement and does not validate current behavior. No passing Flutter test suite or cross-platform build is claimed.

## Roadmap

- Persist feature records and isolate storage by account.
- Replace the scaffold test with state, reflection, timer, and navigation tests.
- Add native notifications and optional snapshot sharing.
- Improve validation, accessibility, error handling, and date-aware streak logic.
- Verify builds and document supported platforms.

## Related Keel project

This repository contains the Flutter application, previously named LifeOS. A separate Keel promotional website contains animations and a Firebase waitlist. Features advertised on that website should only be treated as implemented in this app when documented in the feature table above.

The app name and Dart package are now Keel (`keel`). Existing native application identifiers and Firebase project identifiers are retained so the rename does not disconnect the configured Firebase apps.

## License

No license is currently specified; public source availability does not grant an open-source license.

