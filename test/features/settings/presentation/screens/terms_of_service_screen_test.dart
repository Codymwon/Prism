import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/settings/presentation/screens/terms_of_service_screen.dart';
import 'package:prism/l10n/l10n.dart';

void main() {
  Widget buildTestableWidget() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const TermsOfServiceScreen(),
    );
  }

  testWidgets('TermsOfServiceScreen renders title and all legal sections', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Verify AppBar Title
    expect(find.text('Terms of Service'), findsOneWidget);

    // Verify Conspicuous Section Headers
    expect(find.text('1. ACCEPTANCE OF TERMS & ELIGIBILITY'), findsOneWidget);
    expect(find.text('2. DISCLAIMER OF WARRANTIES ("AS IS")'), findsOneWidget);
    expect(find.text('3. LIMITATION OF LIABILITY & USER BACKUP DUTY'), findsOneWidget);
    expect(find.text('STATUTORY WARRANTY DISCLAIMER'), findsOneWidget);
    expect(find.text('CRITICAL LIABILITY LIMITATION & BACKUP OBLIGATION'), findsOneWidget);

    // Verify Inactive/Hidden Features and US-specific clauses are absent
    expect(find.textContaining('SUBSCRIPTION SERVICES'), findsNothing);
    expect(find.textContaining('TOTAL FEES ACTUALLY PAID'), findsNothing);
    expect(find.textContaining('SYNCHRONIZATION VIA GOOGLE DRIVE'), findsNothing);
    expect(find.textContaining('LOCAL-FIRST FILE SYSTEM UTILITY'), findsNothing);
    expect(find.textContaining('Santa Clara County, California'), findsNothing);
    expect(find.textContaining('American Arbitration Association'), findsNothing);

    // Scroll to see downstream sections
    await tester.scrollUntilVisible(
      find.text('6. BINDING ARBITRATION & CLASS ACTION WAIVER'),
      300,
    );
    expect(find.text('4. AUDIO RECORDING & WIRETAP INDEMNIFICATION'), findsOneWidget);
    expect(find.text('5. DATA OWNERSHIP & INTELLECTUAL PROPERTY'), findsOneWidget);
    expect(find.text('6. BINDING ARBITRATION & CLASS ACTION WAIVER'), findsOneWidget);

    // Scroll to see public URL and Copy URL button
    await tester.scrollUntilVisible(
      find.text('Copy URL'),
      300,
    );
    expect(find.text('https://smallgiantstudio.com/prism/terms'), findsOneWidget);
    expect(find.text('Copy URL'), findsOneWidget);
  });
}
