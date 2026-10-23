import 'package:prism/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/router/app_router.dart';
import 'package:prism/features/folders/presentation/screens/add_folder_screen.dart';
import 'package:prism/features/folders/presentation/widgets/folder_drawer.dart';
import 'package:prism/features/folders/data/folder_model.dart';
import 'package:prism/features/folders/data/folder_repository.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/core/database/database_providers.dart';
import 'package:prism/features/onboarding/data/tutorial_provider.dart';
import 'package:prism/features/onboarding/data/onboarding_provider.dart';
import 'package:prism/features/notes/presentation/providers/notes_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:prism/core/services/vault_service.dart';
import 'package:prism/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:prism/core/config/app_config.dart';

class FakeDatabase extends Fake implements Database {
  @override
  bool get isOpen => true;
}

class FakeNoteRepository extends Fake implements NoteRepository {
  @override
  Future<List<Note>> getAllNotes({
    NoteSort sort = NoteSort.updated,
    int? limit,
    int? offset,
  }) async => [];
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

class FakeOnboardingState extends OnboardingState {
  @override
  bool build() {
    return true;
  }
}

void main() {
  setUp(() {
    AppConfig.enableSubscriptions = true;
    SharedPreferences.setMockInitialValues({
      'hasOnboarded': true,
      'hasCompletedTutorial': true,
      'hasCompletedJournalTutorial': true,
    });
  });

  tearDown(() {
    AppConfig.enableSubscriptions = false;
  });

  Widget buildTestApp(WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  testWidgets('tapping inline Folder add button navigates to folders/create', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWith((ref) async => FakeDatabase()),
        noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
        folderRepositoryProvider.overrideWithValue(FakeFolderRepository()),
        tutorialStateProvider.overrideWith(() => FakeTutorialState()),
        journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState()),
        onboardingStateProvider.overrideWith(() => FakeOnboardingState()),
        availableVaultsProvider.overrideWith((ref) async => ['Default']),
        homeScreenDataProvider.overrideWith((ref) => AsyncData(HomeScreenData(
          notes: [],
          folders: [
            VirtualFolder(id: '123', name: 'Work', colorHex: '#7C6FF7', icon: 'folder', noteCount: 0, createdAt: DateTime.now(), sortOrder: 0),
          ],
          mappings: {},
        ))),
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

    await tester.pump(const Duration(seconds: 1));

    // Tap the inline "+" button on NotesListScreen to add a folder
    final inlineAddFinder = find.byTooltip('New Folder');
    expect(inlineAddFinder, findsOneWidget);

    await tester.tap(inlineAddFinder);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify it navigated to AddFolderScreen
    expect(find.byType(AddFolderScreen), findsOneWidget);
  });

  testWidgets('FolderDrawer renders Vault Dashboard elements', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWith((ref) async => FakeDatabase()),
        noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
        folderRepositoryProvider.overrideWithValue(FakeFolderRepository()),
        tutorialStateProvider.overrideWith(() => FakeTutorialState()),
        journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState()),
        onboardingStateProvider.overrideWith(() => FakeOnboardingState()),
        availableVaultsProvider.overrideWith((ref) async => ['Default']),
        homeScreenDataProvider.overrideWith((ref) => AsyncData(HomeScreenData(
          notes: [],
          folders: [],
          mappings: {},
        ))),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            drawer: FolderDrawer(),
            body: SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open the drawer
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    // Verify header PRISM is shown
    expect(find.text('PRISM'), findsOneWidget);

    // Verify shortcuts are shown
    expect(find.text('Manage Templates'), findsOneWidget);
    expect(find.text('Manage Macros'), findsOneWidget);
    expect(find.text('Serendipity'), findsOneWidget);
  });

  testWidgets('FolderDrawer gates templates and macros for non-Pro users (shows lock icons)', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWith((ref) async => FakeDatabase()),
        noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
        folderRepositoryProvider.overrideWithValue(FakeFolderRepository()),
        tutorialStateProvider.overrideWith(() => FakeTutorialState()),
        journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState()),
        onboardingStateProvider.overrideWith(() => FakeOnboardingState()),
        availableVaultsProvider.overrideWith((ref) async => ['Default']),
        homeScreenDataProvider.overrideWith((ref) => AsyncData(HomeScreenData(
          notes: [],
          folders: [],
          mappings: {},
        ))),
        isProProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            drawer: const FolderDrawer(),
            body: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open the drawer
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    // Verify lock icons are shown for templates and macros, but not serendipity
    expect(find.byIcon(Icons.lock_outline_rounded), findsNWidgets(2));
  });

  testWidgets('FolderDrawer shows chevrons for Pro users (no lock icons)', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWith((ref) async => FakeDatabase()),
        noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
        folderRepositoryProvider.overrideWithValue(FakeFolderRepository()),
        tutorialStateProvider.overrideWith(() => FakeTutorialState()),
        journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState()),
        onboardingStateProvider.overrideWith(() => FakeOnboardingState()),
        availableVaultsProvider.overrideWith((ref) async => ['Default']),
        homeScreenDataProvider.overrideWith((ref) => AsyncData(HomeScreenData(
          notes: [],
          folders: [],
          mappings: {},
        ))),
        isProProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            drawer: const FolderDrawer(),
            body: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open the drawer
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    // Verify no lock icons are shown
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(3)); // 2 shortcuts + 1 serendipity
  });

  testWidgets('v1.0 release: hides Manage Templates and Manage Macros when enableSubscriptions is false', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    AppConfig.enableSubscriptions = false;

    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWith((ref) async => FakeDatabase()),
        noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
        folderRepositoryProvider.overrideWithValue(FakeFolderRepository()),
        tutorialStateProvider.overrideWith(() => FakeTutorialState()),
        journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState()),
        onboardingStateProvider.overrideWith(() => FakeOnboardingState()),
        availableVaultsProvider.overrideWith((ref) async => ['Default']),
        homeScreenDataProvider.overrideWith((ref) => AsyncData(HomeScreenData(
          notes: [],
          folders: [],
          mappings: {},
        ))),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            drawer: const FolderDrawer(),
            body: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Manage Templates'), findsNothing);
    expect(find.text('Manage Macros'), findsNothing);
  });
}
