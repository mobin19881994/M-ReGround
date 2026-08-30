import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_reground/widgets/demo_banner.dart';
import 'package:m_reground/features/debug/demo_profiles_screen.dart';
import 'package:m_reground/features/profile/profile_screen.dart';

void main() {
  testWidgets('DemoBanner shows message when isDemo true', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: DemoBanner(isDemo: true))));
    expect(find.textContaining('Demo customer bypass active'), findsOneWidget);
  });

  testWidgets('DemoProfilesScreen apply button shows confirmation', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: DemoProfilesScreen()));
    // Wait for initial load
    await tester.pumpAndSettle();
    // Tap apply (will be resilient to missing storage)
    final Finder apply = find.text('Apply Selected Profile');
    expect(apply, findsOneWidget);
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(find.text('Demo profile applied'), findsOneWidget);
  });

  testWidgets('Profile screen shows demo ignore-locks toggle in local mode', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();
    // The toggle label should be present when local-only UI is shown.
    expect(find.text('Ignore locks for demo user'), findsOneWidget);
  });
}
