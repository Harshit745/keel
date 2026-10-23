import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/build_log.dart';
import 'models/self_log.dart';
import 'models/idea.dart';
import 'constants/app_constants.dart';
import 'services/notification_service.dart';
import 'services/subscription_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/user_service.dart';

class StartupState {
  const StartupState({
    required this.hiveReady,
    required this.firebaseReady,
    required this.revenueCatReady,
    required this.errors,
  });

  final bool hiveReady;
  final bool firebaseReady;
  final bool revenueCatReady;
  final List<String> errors;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch all errors before app starts
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER ERROR: ${details.exceptionAsString()}');
  };

  // Handle async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PLATFORM ERROR: $error\n$stack');
    return true;
  };
  ErrorWidget.builder = _buildGlobalErrorScreen;

  final StartupState startupState = await _bootstrap();

  debugPrint(
    'STARTUP: runApp hiveReady=${startupState.hiveReady} '
    'firebaseReady=${startupState.firebaseReady} '
    'revenueCatReady=${startupState.revenueCatReady} '
    'errors=${startupState.errors.length}',
  );

  runApp(KeelApp(startupState: startupState));

  unawaited(NotificationService.initialize());
}

Future<StartupState> _bootstrap() async {
  debugPrint('STARTUP: begin');

  final List<String> errors = <String>[];
  final List<bool> results = await Future.wait<bool>(<Future<bool>>[
    _initUserPrefs(errors),
    _initHive(errors),
    _initFirebase(errors),
    _initRevenueCat(errors),
  ]);

  return StartupState(
    hiveReady: results[1],
    firebaseReady: results[2],
    revenueCatReady: results[3],
    errors: errors,
  );
}

Future<bool> _initUserPrefs(List<String> errors) async {
  try {
    debugPrint('STARTUP: shared_preferences init start');
    await UserService.init();
    debugPrint('STARTUP: shared_preferences init complete');
    return true;
  } catch (e) {
    final String message = 'PREFERENCES ERROR: $e';
    errors.add(message);
    debugPrint(message);
    return false;
  }
}

Future<bool> _initHive(List<String> errors) async {
  try {
    debugPrint('STARTUP: hive init start');
    final Directory dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(BuildLogAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SelfLogAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(IdeaAdapter());
    if (!Hive.isBoxOpen(AppConstants.buildLogsBox)) {
      await Hive.openBox<BuildLog>(AppConstants.buildLogsBox);
    }
    if (!Hive.isBoxOpen(AppConstants.selfLogsBox)) {
      await Hive.openBox<SelfLog>(AppConstants.selfLogsBox);
    }
    if (!Hive.isBoxOpen(AppConstants.ideasBox)) {
      await Hive.openBox<Idea>(AppConstants.ideasBox);
    }
    debugPrint('STARTUP: hive init complete');
    return true;
  } catch (e) {
    final String message = 'HIVE ERROR: $e';
    errors.add(message);
    debugPrint(message);
    return false;
  }
}

Future<bool> _initFirebase(List<String> errors) async {
  try {
    debugPrint('STARTUP: firebase init start');
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('STARTUP: firebase init complete via Dart options');
    } else {
      debugPrint('STARTUP: firebase already configured natively');
    }
    return true;
  } catch (e) {
    final String message = 'FIREBASE ERROR: $e';
    errors.add(message);
    debugPrint(message);
    return false;
  }
}

Future<bool> _initRevenueCat(List<String> errors) async {
  try {
    debugPrint('STARTUP: revenuecat init start');
    await SubscriptionService.init();
    debugPrint('STARTUP: revenuecat init complete');
    return true;
  } catch (e) {
    final String message = 'REVENUECAT SKIPPED: $e';
    errors.add(message);
    debugPrint(message);
    return false;
  }
}

class KeelApp extends StatelessWidget {
  const KeelApp({super.key, required this.startupState});

  final StartupState startupState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080808),
        fontFamily: 'DM Sans',
      ),
      home: startupState.firebaseReady
          ? const AuthGate()
          : _StartupDiagnosticsScreen(startupState: startupState),
    );
  }
}

Widget _buildGlobalErrorScreen(FlutterErrorDetails details) {
  return Scaffold(
    backgroundColor: const Color(0xFF080808),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Keel',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF0FF00),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.error_outline, color: Color(0xFFF0FF00), size: 40),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              details.exceptionAsString(),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => SystemNavigator.pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FF00),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Restart app',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          try {
            debugPrint(
              'AUTH GATE: state=${snapshot.connectionState} '
              'hasError=${snapshot.hasError} user=${snapshot.data?.uid}',
            );
            // Show branded splash while connecting
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF080808),
                body: Center(
                  child: Text(
                    'Keel',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFF0FF00),
                      letterSpacing: -1.5,
                    ),
                  ),
                ),
              );
            }
            // Error state — show branded screen not white
            if (snapshot.hasError) {
              return const Scaffold(
                backgroundColor: Color(0xFF080808),
                body: Center(
                  child: Text(
                    'Keel',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFF0FF00),
                    ),
                  ),
                ),
              );
            }
            // Route based on auth state
            if (snapshot.data != null) {
              return FutureBuilder<bool>(
                future: UserService.isOnboarded(),
                builder: (context, onboardedSnapshot) {
                  if (onboardedSnapshot.hasError) {
                    debugPrint(
                      'AUTH GATE ONBOARDING ERROR: ${onboardedSnapshot.error}',
                    );
                    return const _KeelLoadingScreen();
                  }
                  if (onboardedSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Scaffold(
                      backgroundColor: Color(0xFF080808),
                      body: Center(
                        child: Text(
                          'Keel',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF0FF00),
                            letterSpacing: -1.5,
                          ),
                        ),
                      ),
                    );
                  }

                  final bool onboarded = onboardedSnapshot.data ?? false;
                  return onboarded
                      ? const HomeScreen()
                      : const OnboardingScreen();
                },
              );
            }
            return const LoginScreen();
          } catch (e) {
            debugPrint('AUTH GATE BUILD ERROR: $e');
            return const _KeelLoadingScreen();
          }
        },
      );
    } catch (e) {
      debugPrint('AUTH GATE ERROR: $e');
      return const _KeelLoadingScreen();
    }
  }
}

class _StartupDiagnosticsScreen extends StatelessWidget {
  const _StartupDiagnosticsScreen({required this.startupState});

  final StartupState startupState;

  @override
  Widget build(BuildContext context) {
    final String details = startupState.errors.isEmpty
        ? 'Startup is incomplete. Check native iOS configuration.'
        : startupState.errors.join('\n');

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Keel',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF0FF00),
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Startup configuration failed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                details,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeelLoadingScreen extends StatelessWidget {
  const _KeelLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF080808),
      body: Center(
        child: Text(
          'Keel',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: Color(0xFFF0FF00),
            letterSpacing: -1.5,
          ),
        ),
      ),
    );
  }
}