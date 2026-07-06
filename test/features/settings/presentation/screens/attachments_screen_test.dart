import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/settings/presentation/screens/attachments_screen.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/features/onboarding/data/onboarding_provider.dart';

class MockNoteRepository implements NoteRepository {
  final List<Note> notes;
  MockNoteRepository(this.notes);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Note>> getAllNotes({NoteSort sort = NoteSort.updated}) async => notes;
}

void main() {
  late Directory tempDir;
  late Directory attachmentsDir;
  late SharedPreferences prefs;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('prism_attachments_test');
    attachmentsDir = Directory(p.join(tempDir.path, 'My Vault', 'attachments'));
    await attachmentsDir.create(recursive: true);

    SharedPreferences.setMockInitialValues({
      'baseVaultsDirectory': tempDir.path,
      'activeVaultName': 'My Vault',
    });
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('attachmentsProvider lists and identifies both image and audio files in vault', () async {
    // 1. Create attachments on disk
    final audioFile = File(p.join(attachmentsDir.path, 'audio1.m4a'));
    await audioFile.writeAsString('audio');

    final imageFile = File(p.join(attachmentsDir.path, 'image1.png'));
    await imageFile.writeAsString('image');

    final orphanedImageFile = File(p.join(attachmentsDir.path, 'orphaned_image.jpg'));
    await orphanedImageFile.writeAsString('orphaned');

    // 2. Create mock notes
    final note = Note(
      id: 'note-1',
      title: 'Notes',
      filePath: p.join(tempDir.path, 'My Vault', 'Notes.md'),
      wordCount: 10,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Mock note content containing references to audio1.m4a and image1.png
    final noteFile = File(note.filePath);
    await noteFile.writeAsString('# Notes\n[Audio](attachments/audio1.m4a) and ![Image](attachments/image1.png)');

    final mockRepo = MockNoteRepository([note]);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        noteRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    // 3. Read attachmentsProvider
    final attachments = await container.read(attachmentsProvider.future);

    // 4. Verify results
    expect(attachments.length, 3);

    final audioAttachment = attachments.firstWhere((a) => a.name == 'audio1.m4a');
    expect(audioAttachment.isImage, isFalse);
    expect(audioAttachment.isReferenced, isTrue);

    final imageAttachment = attachments.firstWhere((a) => a.name == 'image1.png');
    expect(imageAttachment.isImage, isTrue);
    expect(imageAttachment.isReferenced, isTrue);

    final orphanedAttachment = attachments.firstWhere((a) => a.name == 'orphaned_image.jpg');
    expect(orphanedAttachment.isImage, isTrue);
    expect(orphanedAttachment.isReferenced, isFalse);
  });

  testWidgets('AttachmentsScreen renders image cards with thumbnails and no play button, and audio cards with play button', (WidgetTester tester) async {
    final mockImageFile = File('image.png');
    final mockAudioFile = File('audio.m4a');
    final attachments = [
      AttachmentFile(
        file: mockImageFile,
        name: 'image.png',
        sizeBytes: 1024,
        lastModified: DateTime.now(),
        isReferenced: true,
      ),
      AttachmentFile(
        file: mockAudioFile,
        name: 'audio.m4a',
        sizeBytes: 2048,
        lastModified: DateTime.now(),
        isReferenced: false,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attachmentsProvider.overrideWith((ref) => attachments),
        ],
        child: const MaterialApp(
          home: AttachmentsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify "image.png" is rendered
    expect(find.text('image.png'), findsOneWidget);
    // Verify "audio.m4a" is rendered
    expect(find.text('audio.m4a'), findsOneWidget);

    // Verify there is one Image widget in the tree (for the image thumbnail)
    expect(find.byType(Image), findsOneWidget);

    // Verify there is one play button (for audio, none for image)
    final playButtonFinder = find.byTooltip('Play Recording');
    expect(playButtonFinder, findsOneWidget);
  });
}
