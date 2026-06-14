import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/utils.dart';
import '../../../../features/notes/data/audio_bookmark_model.dart';
import '../../data/audio_bookmark_repository.dart';

part 'audio_bookmark_providers.freezed.dart';

/// Provider for the [AudioBookmarkRepository] singleton.
final audioBookmarkRepositoryProvider = Provider<AudioBookmarkRepository>((ref) {
  return AudioBookmarkRepository();
});

// ── State for a specific (noteId, attachmentPath) pair ───────────────────────

/// Immutable parameters identifying a bookmark set.
@freezed
class BookmarkKey with _$BookmarkKey {
  const factory BookmarkKey({
    required String noteId,
    required String attachmentPath,
  }) = _BookmarkKey;
}

/// State held by [AudioBookmarkNotifier].
@freezed
class AudioBookmarkState with _$AudioBookmarkState {
  const factory AudioBookmarkState({
    @Default([]) List<AudioBookmark> bookmarks,
    @Default(false) bool isLoading,
    String? error,
  }) = _AudioBookmarkState;
}

/// Manages bookmark CRUD for one (noteId, attachmentPath) pair.
class AudioBookmarkNotifier extends StateNotifier<AudioBookmarkState> {
  final AudioBookmarkRepository _repository;
  final String _noteId;
  final String _attachmentPath;

  AudioBookmarkNotifier(
    this._repository,
    this._noteId,
    this._attachmentPath,
  ) : super(const AudioBookmarkState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bookmarks = await _repository.getBookmarksForAttachment(
        _noteId,
        _attachmentPath,
      );
      state = AudioBookmarkState(bookmarks: bookmarks);
    } catch (e) {
      state = AudioBookmarkState(error: e.toString());
    }
  }

  /// Refreshes the bookmark list from the database.
  Future<void> refresh() => _load();

  /// Adds a new bookmark at the given [timestampMs] with optional [annotation].
  Future<void> addBookmark({
    required int timestampMs,
    String annotation = '',
  }) async {
    final bookmark = AudioBookmark(
      id: generateId(),
      noteId: _noteId,
      attachmentPath: _attachmentPath,
      timestampMs: timestampMs,
      annotationText: annotation,
      createdAt: DateTime.now(),
    );
    try {
      await _repository.addBookmark(bookmark);
      await _load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Deletes the bookmark identified by [bookmarkId].
  Future<void> deleteBookmark(String bookmarkId) async {
    try {
      await _repository.deleteBookmark(bookmarkId);
      // Optimistically remove before reload for snappy UI
      state = state.copyWith(
        bookmarks: state.bookmarks
            .where((b) => b.id != bookmarkId)
            .toList(),
      );
      await _load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Family provider: one [AudioBookmarkNotifier] per [BookmarkKey].
///
/// Usage:
/// ```dart
/// final key = BookmarkKey(noteId: noteId, attachmentPath: attachmentPath);
/// ref.watch(audioBookmarkProvider(key));
/// ```
final audioBookmarkProvider = StateNotifierProvider.autoDispose.family<
    AudioBookmarkNotifier,
    AudioBookmarkState,
    BookmarkKey>((ref, key) {
  final repo = ref.watch(audioBookmarkRepositoryProvider);
  return AudioBookmarkNotifier(repo, key.noteId, key.attachmentPath);
});
