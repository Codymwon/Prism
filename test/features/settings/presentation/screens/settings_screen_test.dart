import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/settings/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'baseVaultsDirectory': '/mock/vaults',
    });
  });

  testWidgets('SettingsScreen displays Backup & Sync tile and does not display Google Drive Sync or Export vault tiles', (WidgetTester tester) async {
    // Set a large viewport to ensure all settings tiles are built and laid out
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Backup & Sync tile is present
    expect(find.text('Backup & Sync'), findsOneWidget);

    // Verify Google Drive Sync and Export vault tiles are NOT present directly on settings screen
    expect(find.text('Google Drive Sync'), findsNothing);
    expect(find.text('Export vault'), findsNothing);
  });
}
