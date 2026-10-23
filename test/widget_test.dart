import 'package:flutter_test/flutter_test.dart';

import 'package:keel/main.dart';

void main() {
  testWidgets('shows startup diagnostics when Firebase is unavailable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const KeelApp(
        startupState: StartupState(
          hiveReady: true,
          firebaseReady: false,
          revenueCatReady: false,
          errors: <String>['FIREBASE ERROR: test'],
        ),
      ),
    );

    expect(find.text('Keel'), findsOneWidget);
    expect(find.text('Startup configuration failed'), findsOneWidget);
  });
}
