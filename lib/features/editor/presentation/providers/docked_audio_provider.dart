import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Data model representing an audio attachment docked at the top of the editor.
class DockedAudio {
  final String filePath;
  final String fileName;
  final String? noteId;
  final String? relativeFilePath;

  const DockedAudio({
    required this.filePath,
    required this.fileName,
    this.noteId,
    this.relativeFilePath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DockedAudio &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath &&
          fileName == other.fileName &&
          noteId == other.noteId &&
          relativeFilePath == other.relativeFilePath;

  @override
  int get hashCode =>
      filePath.hashCode ^
      fileName.hashCode ^
      noteId.hashCode ^
      relativeFilePath.hashCode;
}

/// Riverpod notifier coordinating active docked audio evidence in the editor.
class DockedAudioNotifier extends Notifier<DockedAudio?> {
  @override
  DockedAudio? build() => null;

  void dock({
    required String filePath,
    required String fileName,
    String? noteId,
    String? relativeFilePath,
  }) {
    state = DockedAudio(
      filePath: filePath,
      fileName: fileName,
      noteId: noteId,
      relativeFilePath: relativeFilePath,
    );
  }

  void undock() {
    state = null;
  }
}

final dockedAudioProvider =
    NotifierProvider<DockedAudioNotifier, DockedAudio?>(
  DockedAudioNotifier.new,
);
