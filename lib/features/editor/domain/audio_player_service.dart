import 'dart:async';

/// Abstract contract for playing back audio dictations.
abstract class AudioPlayerService {
  /// Fired whenever the total duration of the loaded track changes.
  Stream<Duration> get onDurationChanged;

  /// Fired as the playback position advances.
  Stream<Duration> get onPositionChanged;

  /// Fired when playback starts (`true`) or stops/pauses (`false`).
  Stream<bool> get onIsPlayingChanged;

  /// Loads and plays the audio file at [filePath].
  Future<void> play(String filePath);

  /// Pauses playback.
  Future<void> pause();

  /// Resumes a paused track.
  Future<void> resume();

  /// Stops playback and releases resources.
  Future<void> stop();

  /// Seeks to [position] within the current track.
  Future<void> seek(Duration position);

  /// Returns the total duration of the current track, if available.
  Future<Duration?> getDuration();

  /// Releases native resources.
  void dispose();
}
