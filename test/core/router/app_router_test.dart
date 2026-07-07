import 'package:prism/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/router/app_router.dart';
import 'package:prism/features/folders/presentation/screens/add_folder_screen.dart';
import 'package:prism/features/folders/presentation/screens/edit_folder_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/folders/data/folder_model.dart';
import 'package:prism/features/folders/data/folder_repository.dart';
import 'package:prism/core/database/database_providers.dart';
import 'package:prism/features/onboarding/data/tutorial_provider.dart';
import 'package:prism/features/onboarding/data/onboarding_provider.dart';
import 'package:sqflite/sqflite.dart';

class FakeDatabase extends Fake implements Database {
  @override
  bool get isOpen => true;
}

class FakeNoteRepository extends Fake implements NoteRepository {
  @override
  Future<List<Note>> getAllNotes({NoteSort sort = NoteSort.updated}) async => [];
  @override
  Future<Note?> getDailyNote(String dateStr) async => null;
  Stream<List<Note>> watchAllNotes() => Stream.value([]);
}

class FakeFolderRepository extends Fake implements FolderRepository {
  @override
  Future<List<VirtualFolder>> getAllFolders() async => [
        VirtualFolder(id: '123', name: 'Work', colorHex: '#7C6FF7', icon: 'folder', noteCount: 0, createdAt: DateTime.now(), sortOrder: 0),
      ];
  @override
  Future<Map<String, List<String>>> getNoteFolderMappings() async => {};
  Stream<List<VirtualFolder>> watchAllFolders() => Stream.value([
        VirtualFolder(id: '123', name: 'Work', colorHex: '#7C6FF7', icon: 'folder', noteCount: 0, createdAt: DateTime.now(), sortOrder: 0),
      ]);
}

class FakeTutorialState extends TutorialState {
  @override
  bool build() {
    return true;
  }
}

class FakeJournalTutorialState extends JournalTutorialState {
  @override
  bool build() {
    return true;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'hasOnboarded': true,
    });
  });

  Widget buildTestApp(WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  testWidgets('GoRouter routes to /folders/create and /folders/edit/:id', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWith((ref) async => FakeDatabase()),
        noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
        folderRepositoryProvider.overrideWithValue(FakeFolderRepository()),
        tutorialStateProvider.overrideWith(() => FakeTutorialState()),
        journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState()),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) => buildTestApp(ref),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final router = container.read(appRouterProvider);

    // Navigating to /folders/create
    router.push('/folders/create');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AddFolderScreen), findsOneWidget);

    // Navigating to /folders/edit/123
    router.push('/folders/edit/123');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(EditFolderScreen), findsOneWidget);
  });
}
