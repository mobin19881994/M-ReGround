import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:m_reground/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('basic navigation and demo seed', (WidgetTester tester) async {
    await tester.pumpWidget(const MUnloopApp());
    await tester.pumpAndSettle();

    // Wait for bootloader to finish
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Tap profile tab
    final Finder profileTab = find.text('Profile');
    expect(profileTab, findsOneWidget);
    await tester.tap(profileTab);
    await tester.pumpAndSettle();

    // Find Seed Demo Data button if present
    final Finder seedButton = find.text('Seed Demo Data');
    if (await tester.pumpAndSettle().then((_) => seedButton.evaluate().isNotEmpty)) {
      await tester.tap(seedButton);
      await tester.pumpAndSettle();
      // SnackBar confirmation should appear
      expect(find.byType(SnackBar), findsOneWidget);
    }
  });
}
