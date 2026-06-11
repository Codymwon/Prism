import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prism/features/editor/presentation/providers/audio_bookmark_providers.dart';
import 'package:prism/features/editor/data/audio_bookmark_repository.dart';
import 'package:prism/features/notes/data/audio_bookmark_model.dart';

class FakeAudioBookmarkRepository implements AudioBookmarkRepository {
  @override
  Future<List<AudioBookmark>> getBookmarksForAttachment(
    String noteId,
    String attachmentPath,
  ) async {
    return [
      AudioBookmark(
        id: '1',
        noteId: noteId,
        attachmentPath: attachmentPath,
        timestampMs: 1000,
        annotationText: 'Test Annotation',
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<void> addBookmark(AudioBookmark bookmark) async {}

  @override
  Future<void> deleteBookmark(String bookmarkId) async {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('audioBookmarkProvider auto-disposes correctly when not listened to anymore', () async {
    final fakeRepo = FakeAudioBookmarkRepository();
    final container = ProviderContainer(
      overrides: [
        audioBookmarkRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    final key = const BookmarkKey(noteId: 'note-123', attachmentPath: 'path/to/audio.mp3');

    // Watch the provider
    final subscription = container.listen(
      audioBookmarkProvider(key),
      (previous, next) {},
    );

    // Force wait for refresh to load the data
    await container.read(audioBookmarkProvider(key).notifier).refresh();

    // Verify it contains the bookmark from our fake repo
    expect(container.read(audioBookmarkProvider(key)).bookmarks, isNotEmpty);

    // Close the subscription to trigger auto-dispose
    subscription.close();

    // Pump microtasks so autoDispose runs
    await Future.delayed(Duration.zero);

    // Read the provider again. Since it was auto-disposed, it should reinitialize
    // and return the initial empty/loading state before load finishes.
    final newState = container.read(audioBookmarkProvider(key));
    expect(newState.bookmarks, isEmpty);
    expect(newState.isLoading, isTrue);
  });
}
