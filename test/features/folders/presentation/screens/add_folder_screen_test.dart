import 'package:prism/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/folders/presentation/screens/add_folder_screen.dart';
import 'package:prism/features/folders/data/folder_repository.dart';
import 'package:prism/features/folders/data/folder_model.dart';
import 'package:prism/shared/design_system/design_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeFolderRepository extends Fake implements FolderRepository {
  bool createFolderCalled = false;
  String? passedName;
  String? passedColorHex;
  String? passedIcon;

  @override
  Future<VirtualFolder> createFolder(
    String name, {
    String colorHex = '#7C6FF7',
    String icon = 'folder',
  }) async {
    createFolderCalled = true;
    passedName = name;
    passedColorHex = colorHex;
    passedIcon = icon;
    return VirtualFolder(
      id: 'fake-id',
      name: name,
      colorHex: colorHex,
      icon: icon,
      createdAt: DateTime.now(),
      sortOrder: 0,
      noteCount: 0,
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestScreen(FolderRepository repo) {
    return ProviderScope(
      overrides: [
        folderRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AddFolderScreen(),
      ),
    );
  }

  testWidgets('renders all UI components and submits successfully', (tester) async {
    final fakeRepo = FakeFolderRepository();
    await tester.pumpWidget(buildTestScreen(fakeRepo));
    await tester.pumpAndSettle();

    // Verify Title in AppBar
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Create Folder')), findsOneWidget);

    // Verify Name TextField
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    // Verify Create button
    final submitButtonFinder = find.byType(DesignPrimaryButton);
    expect(submitButtonFinder, findsOneWidget);

    // Enter name
    await tester.enterText(textFieldFinder, 'Work Projects');
    await tester.pump();

    // Submit
    await tester.tap(submitButtonFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify createFolder was called on repository
    expect(fakeRepo.createFolderCalled, isTrue);
    expect(fakeRepo.passedName, 'Work Projects');
    expect(fakeRepo.passedColorHex, '#7C6FF7'); // Default indigo swatch color
    expect(fakeRepo.passedIcon, ''); // Default empty icon key
  });
}
