import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:prism/l10n/l10n.dart';

void main() {
  Widget buildTestableWidget() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const PrivacyPolicyScreen(),
    );
  }

  testWidgets('PrivacyPolicyScreen renders title and all sections including Limited Use, COPPA, and Data Controller', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Verify AppBar Title
    expect(find.text('Privacy Policy'), findsOneWidget);

    // Verify Sections 1, 2, 3
    expect(find.text('1. WHAT WE COLLECT'), findsOneWidget);
    expect(find.text('Anonymous Usage Telemetry (opt-in)'), findsOneWidget);
    expect(find.text('Crash Reports (opt-in)'), findsOneWidget);
    expect(find.text('Subscription Status'), findsNothing);
    expect(find.text('2. DEVICE PERMISSIONS'), findsOneWidget);
    expect(find.text('Storage / Filesystem Access'), findsNothing);
    expect(find.text('3. OPTIONAL CLOUD INTEGRATION'), findsOneWidget);

    // Verify Limited Use Callout
    expect(find.text('GOOGLE API SERVICES LIMITED USE COMPLIANCE'), findsOneWidget);
    expect(find.text('Google Drive Data Safeguards'), findsOneWidget);
    expect(find.textContaining('Sole Purpose of Synchronization'), findsOneWidget);
    expect(find.textContaining('No Advertising, Retargeting, or Profiling'), findsOneWidget);
    expect(find.textContaining('No AI/ML Model Training'), findsOneWidget);
    expect(find.textContaining('No Human Inspection'), findsOneWidget);

    // Scroll to see downstream sections
    await tester.scrollUntilVisible(
      find.text('6. DATA CONTROLLER & CONTACT'),
      300,
    );

    expect(find.text('4. COMPLIANCE WITH LAWS'), findsOneWidget);
    expect(find.text("5. CHILDREN'S PRIVACY (COPPA & GDPR ART. 8)"), findsOneWidget);
    expect(find.text('Age Limitations & Child Data Protection'), findsOneWidget);
    expect(find.text('6. DATA CONTROLLER & CONTACT'), findsOneWidget);
    expect(find.text('Data Controller Identity & Address'), findsOneWidget);
    expect(find.textContaining('Country of Operation: India'), findsOneWidget);
    expect(find.textContaining('548 Market St'), findsNothing);
    expect(find.text('Grievance Officer (India IT Rules 2021)'), findsOneWidget);
    expect(find.textContaining('privacy@smallgiantstudio.com'), findsWidgets);

    // Verify Copy Privacy Link button
    expect(find.text('Copy Privacy Link'), findsOneWidget);
    expect(find.text('https://smallgiantstudio.com/prism/privacy'), findsOneWidget);
  });
}
