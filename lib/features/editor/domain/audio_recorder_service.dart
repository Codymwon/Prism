/// Abstract contract for recording audio dictations and note annotations.
abstract class AudioRecorderService {
  /// Returns `true` if the app has microphone permission.
  Future<bool> hasPermission();

  /// Starts recording to [path].
  Future<void> start(String path);

  /// Stops recording and returns the file path of the recorded audio, if any.
  Future<String?> stop();

  /// Returns `true` if a recording is in progress.
  Future<bool> isRecording();

  /// Releases native resources.
  void dispose();
}
