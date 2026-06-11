import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/settings/presentation/screens/backup_and_sync_screen.dart';

void main() {
  testWidgets('BackupAndSyncScreen displays title and sync/export tiles', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: BackupAndSyncScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title is present
    expect(find.text('Backup & Sync'), findsOneWidget);

    // Verify moved tiles are present
    expect(find.text('Google Drive Sync'), findsOneWidget);
    expect(find.text('Export vault'), findsOneWidget);
  });
}
