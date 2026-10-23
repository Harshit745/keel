// Replace this placeholder by running flutterfire configure for your project.
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get ios => currentPlatform;
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
    'Run flutterfire configure to connect your own Firebase project.',
  );
}
