import 'package:prism/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/folders/presentation/screens/edit_folder_screen.dart';
import 'package:prism/features/folders/data/folder_repository.dart';
import 'package:prism/features/folders/data/folder_model.dart';
import 'package:prism/core/database/database_providers.dart';
import 'package:prism/shared/design_system/design_system.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class FakeDatabase extends Fake implements Database {
  @override
  bool get isOpen => true;
}

class FakeFolderRepository extends Fake implements FolderRepository {
  bool updateFolderCalled = false;
  String? passedId;
  String? passedName;
  String? passedColorHex;
  String? passedIcon;

  @override
  Future<List<VirtualFolder>> getAllFolders() async => [
        VirtualFolder(
          id: '123',
          name: 'Personal Stuff',
          colorHex: '#EF4444', // Red
          icon: 'home',
          createdAt: DateTime.now(),
          sortOrder: 0,
          noteCount: 0,
        ),
      ];

  Stream<List<VirtualFolder>> watchAllFolders() => Stream.value([
        VirtualFolder(
          id: '123',
          name: 'Personal Stuff',
          colorHex: '#EF4444',
          icon: 'home',
          createdAt: DateTime.now(),
          sortOrder: 0,
          noteCount: 0,
        ),
      ]);

  @override
  Future<void> updateFolder(
    String id,
    String name,
    String colorHex,
    String icon,
  ) async {
    updateFolderCalled = true;
    passedId = id;
    passedName = name;
    passedColorHex = colorHex;
    passedIcon = icon;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestScreen(FolderRepository repo) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) async => FakeDatabase()),
        folderRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EditFolderScreen(folderId: '123'),
      ),
    );
  }

  testWidgets('renders folder details and updates successfully', (tester) async {
    final fakeRepo = FakeFolderRepository();
    await tester.pumpWidget(buildTestScreen(fakeRepo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title in AppBar
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Edit Folder')), findsOneWidget);

    // Verify Name TextField has pre-filled value
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);
    final TextField textField = tester.widget(textFieldFinder);
    expect(textField.controller?.text, 'Personal Stuff');

    // Change name
    await tester.enterText(textFieldFinder, 'Personal Tasks');
    await tester.pump();

    // Verify Save Changes button
    final submitButtonFinder = find.byType(DesignPrimaryButton);
    expect(submitButtonFinder, findsOneWidget);

    // Submit
    await tester.tap(submitButtonFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify updateFolder was called on repository
    expect(fakeRepo.updateFolderCalled, isTrue);
    expect(fakeRepo.passedId, '123');
    expect(fakeRepo.passedName, 'Personal Tasks');
    expect(fakeRepo.passedColorHex, '#EF4444');
    expect(fakeRepo.passedIcon, 'home');
  });
}
