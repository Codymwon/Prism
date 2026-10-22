import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/database/vault_providers.dart';
import 'package:prism/features/editor/presentation/widgets/inline_audio_waveform_player.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/presentation/providers/notes_providers.dart';
import 'package:prism/l10n/l10n.dart';

void main() {
  late Directory tempVaultDir;
  late File audioFile;

  setUp(() async {
    tempVaultDir = Directory.systemTemp.createTempSync('prism_audio_test_');
    final attachmentsDir = Directory('${tempVaultDir.path}/attachments');
    attachmentsDir.createSync(recursive: true);
    audioFile = File('${attachmentsDir.path}/audio_test_123.m4a');
    audioFile.writeAsStringSync('dummy audio content for test');
  });

  tearDown(() {
    try {
      if (tempVaultDir.existsSync()) {
        tempVaultDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  testWidgets('renders waveform when audio file exists in vault attachments', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeVaultPathProvider.overrideWith((ref) async => tempVaultDir.path),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: InlineAudioWaveformPlayer(
              filePath: 'attachments/audio_test_123.m4a',
              fileName: 'Audio Note',
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump();

    for (int i = 0; i < 20; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      if (find.byType(InlineWaveformWidget).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.textContaining('Audio file not found'), findsNothing);
    expect(find.byType(InlineWaveformWidget), findsOneWidget);
  });

  testWidgets('renders waveform when audio file exists in note-specific folder attachments', (tester) async {
    final subfolder = Directory('${tempVaultDir.path}/projects');
    final subAttachments = Directory('${subfolder.path}/attachments');
    subAttachments.createSync(recursive: true);
    final noteAudioFile = File('${subAttachments.path}/project_audio.m4a');
    noteAudioFile.writeAsStringSync('project audio content');

    final mockNote = Note(
      id: 'note-subfolder-1',
      title: 'Project Note',
      filePath: '${subfolder.path}/project_note.md',
      wordCount: 10,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeVaultPathProvider.overrideWith((ref) async => tempVaultDir.path),
          noteByIdProvider('note-subfolder-1').overrideWith((ref) async => mockNote),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: InlineAudioWaveformPlayer(
              filePath: 'attachments/project_audio.m4a',
              fileName: 'Project Audio',
              noteId: 'note-subfolder-1',
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    for (int i = 0; i < 20; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      if (find.byType(InlineWaveformWidget).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.textContaining('Audio file not found'), findsNothing);
    expect(find.byType(InlineWaveformWidget), findsOneWidget);
  });

  testWidgets('renders error UI when audio file does not exist on disk', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeVaultPathProvider.overrideWith((ref) async => tempVaultDir.path),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: InlineAudioWaveformPlayer(
              filePath: 'attachments/non_existent.m4a',
              fileName: 'Missing Audio',
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    for (int i = 0; i < 20; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      if (find.textContaining('Audio file not found').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.textContaining('Audio file not found'), findsOneWidget);
    expect(find.byType(InlineWaveformWidget), findsNothing);
  });
}
