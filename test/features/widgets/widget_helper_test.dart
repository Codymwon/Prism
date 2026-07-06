import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/core/router/app_router.dart';
import 'package:prism/core/utils/utils.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/notes/presentation/providers/notes_providers.dart';
import 'package:prism/features/widgets/widget_helper.dart';
import 'package:prism/features/onboarding/data/onboarding_provider.dart';

class MockNoteRepository implements NoteRepository {
  final List<Note> notes = [];
  Note? createdNote;
  String? queriedDailyDate;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Note?> getDailyNote(String dateStr) async {
    queriedDailyDate = dateStr;
    final index = notes.indexWhere((n) => n.dailyDate == dateStr);
    return index != -1 ? notes[index] : null;
  }

  @override
  Future<Note> createNote({
    String? title,
    String initialContent = '',
    bool isDaily = false,
    String? dailyDate,
  }) async {
    final note = Note(
      id: 'mock-note-${notes.length + 1}',
      title: title ?? 'Untitled',
      filePath: '/mock/path/${title ?? 'Untitled'}.md',
      wordCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDaily: isDaily,
      dailyDate: dailyDate,
    );
    notes.add(note);
    createdNote = note;
    return note;
  }
}

class MockGoRouter implements GoRouter {
  String? lastGoPath;
  String? lastPushPath;

  @override
  void go(String location, {Object? extra}) {
    lastGoPath = location;
  }

  @override
  Future<T?> push<T>(String location, {Object? extra}) async {
    lastPushPath = location;
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WidgetHelper SharedPreferences Key Serialization', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('updateWidgetData writes values to keys WITHOUT manual "flutter." prefix', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await container.read(widgetHelperProvider).updateWidgetData(
        streak: 7,
        todayReflected: true,
        bgHex: '#121214',
        accentHex: '#8B5CF6',
        textPrimaryHex: '#F3F4F6',
        textSecondaryHex: '#9CA3AF',
      );

      expect(prefs.getInt('journal_streak'), equals(7));
      expect(prefs.getBool('today_reflected'), isTrue);
      expect(prefs.getString('theme_widget_bg'), equals('#121214'));
      expect(prefs.getString('theme_widget_accent'), equals('#8B5CF6'));
      expect(prefs.getString('theme_widget_text_primary'), equals('#F3F4F6'));
      expect(prefs.getString('theme_widget_text_secondary'), equals('#9CA3AF'));

      expect(prefs.containsKey('flutter.journal_streak'), isFalse);
    });
  });

  group('WidgetHelper Action Handling & Navigation', () {
    late MockNoteRepository mockRepo;
    late MockGoRouter mockRouter;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockNoteRepository();
      mockRouter = MockGoRouter();

      container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(mockRepo),
          appRouterProvider.overrideWithValue(mockRouter),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('handleWidgetAction "quick_capture" creates Untitled note and pushes editor', () async {
      await container.read(widgetHelperProvider).handleWidgetAction('quick_capture');

      expect(mockRepo.createdNote, isNotNull);
      expect(mockRepo.createdNote!.title, equals('Untitled'));
      expect(mockRouter.lastPushPath, equals('/editor/${mockRepo.createdNote!.id}?new=true'));
    });

    test('handleWidgetAction "create_daily" when daily note DOES NOT exist creates and pushes editor', () async {
      final todayStr = formatDailyDate(DateTime.now());

      await container.read(widgetHelperProvider).handleWidgetAction('create_daily');

      expect(mockRepo.queriedDailyDate, equals(todayStr));
      expect(mockRepo.createdNote, isNotNull);
      expect(mockRepo.createdNote!.isDaily, isTrue);
      expect(mockRepo.createdNote!.dailyDate, equals(todayStr));
      expect(mockRouter.lastPushPath, equals('/editor/${mockRepo.createdNote!.id}?date=$todayStr&new=true'));
    });

    test('handleWidgetAction "create_daily" when daily note ALREADY exists pushes editor without creating', () async {
      final todayStr = formatDailyDate(DateTime.now());
      final existingNote = Note(
        id: 'existing-daily',
        title: todayStr,
        filePath: '/mock/path/$todayStr.md',
        wordCount: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDaily: true,
        dailyDate: todayStr,
      );
      mockRepo.notes.add(existingNote);

      await container.read(widgetHelperProvider).handleWidgetAction('create_daily');

      expect(mockRepo.queriedDailyDate, equals(todayStr));
      expect(mockRepo.createdNote, isNull);
      expect(mockRouter.lastPushPath, equals('/editor/existing-daily?date=$todayStr'));
    });

    test('handleWidgetAction "search" navigates to /notes and updates search providers', () async {
      container.read(searchQueryProvider.notifier).state = 'some query';
      container.read(searchFocusProvider.notifier).state = false;

      await container.read(widgetHelperProvider).handleWidgetAction('search');

      expect(mockRouter.lastGoPath, equals('/notes'));
      expect(container.read(searchQueryProvider), equals(''));
      expect(container.read(searchFocusProvider), isTrue);
    });

    test('init calls checkPendingAction and handles incoming widgets actions from platform launch', () async {
      String? invokedMethod;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.prism.app/widget'),
        (methodCall) async {
          invokedMethod = methodCall.method;
          if (methodCall.method == 'getPendingWidgetAction') {
            return 'quick_capture';
          }
          return null;
        },
      );

      final helper = container.read(widgetHelperProvider);
      helper.init();

      await Future.delayed(Duration.zero);

      expect(invokedMethod, equals('getPendingWidgetAction'));
      expect(mockRepo.createdNote, isNotNull);
      expect(mockRepo.createdNote!.title, equals('Untitled'));
      expect(mockRouter.lastPushPath, equals('/editor/${mockRepo.createdNote!.id}?new=true'));
    });
  });
}
