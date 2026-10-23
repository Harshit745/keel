# Keel

A Flutter application for founders and builders to record product progress, personal wellbeing, ideas, and weekly reflections.

This is the larger Keel implementation from the local `vault` project. It replaces the earlier LifeOS-derived prototype on `main`. The earlier implementation remains available on the `legacy-lifeos` branch and in Git history.

## Implemented features

- Build logs: shipped tasks, user conversations, progress, revenue, and daily wins.
- Self logs: sleep, energy, mood, spending, and exercise.
- Build, Self, and combined FounderScore calculations with charts and analytics.
- Hive persistence for build logs, self logs, and ideas; shared preferences for profile/onboarding settings.
- Idea vault with text, Markdown, and CSV export/share services.
- Firebase authentication with email/password, Google/Apple service integrations, and password reset.
- Onboarding, settings, streaks, celebrations, weekly reports, and share-card screens.
- Gemini HTTP integration for structured log extraction, conversational responses, and generated insights.
- RevenueCat entitlement checks, purchase flow, and purchase restoration.
- Local notification scheduling for daily prompts, morning reminders, and weekly recaps.
- Startup diagnostics for failed configuration or initialization.

Source implementation does not establish that external sign-in providers, paid entitlements, notifications, or every native target have been verified on devices. AI requests require a configured, available model endpoint. No model accuracy or commercial adoption claim is made.

## Setup

Requires Flutter with a Dart SDK compatible with `^3.8.1`, plus native tooling for your target.

```sh
git clone https://github.com/Harshit745/keel.git
cd keel
flutter pub get
```

Create your own Firebase project, enable the authentication providers you need, install the Firebase and FlutterFire CLIs, then:

```sh
firebase login
flutterfire configure
```

The checked-in `lib/firebase_options.dart` is an intentionally unconfigured placeholder. FlutterFire replaces it with your configuration. Add the required Android/Apple platform configuration locally. Keep signing files and private service-account credentials out of Git.

Optional integrations use build-time settings:

```sh
flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY --dart-define=REVENUECAT_API_KEY=YOUR_KEY
```

Build-time values are embedded in client binaries; they are not server-side secrets. Use a server proxy and appropriate access controls before distributing a production build. Confirm the Gemini endpoint in `lib/constants/app_constants.dart` is available for your account. Configure RevenueCat products and the `vault_pro` entitlement before testing purchases. Do not commit real values.

## Repository layout

```text
lib/
  main.dart        # Startup, diagnostics, routing
  constants/       # Branding, box names, integration configuration
  models/          # Build/self logs, ideas, reports, Hive adapters
  services/        # Auth, persistence, scoring, AI, export, subscriptions, notifications
  screens/         # Logs, analytics, auth, onboarding, reports, settings, ideas
  widgets/         # Score cards, save feedback, streak UI
backend/           # Separate Express/SQLite waitlist service
keel/              # Promotional website, not the Flutter application
test/              # Automated checks
```

## Waitlist service and website

`backend/` is a separate Node/Express service storing waitlist submissions in SQLite. It is not a cloud-sync backend for app records.

```sh
cd backend
npm install
ADMIN_TOKEN=YOUR_LOCAL_TOKEN node index.js
```

Set `PORT` if needed. The service exposes `POST /api/waitlist` and a token-protected `/admin` view. No signup database is included. The website under `keel/` uses a separate Firebase waitlist integration with placeholder configuration; configure it independently. A deployed website is not claimed by this repository.

## Validation and remaining work

```sh
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
```

The app remains a prototype. Review account isolation for local data, validate AI outputs before persisting them, test native integrations on devices, and strengthen domain tests before release. Existing generated adapters are included.

## Author and license

[Harshit Sharma](https://github.com/Harshit745). No open-source license has been granted by this repository.
