import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

// ─── Service Interface ────────────────────────────────────────────────────────

/// Abstract seam for audio playback, decoupling the notifier from
/// the concrete `audioplayers` plugin.
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

// ─── Adapter ─────────────────────────────────────────────────────────────────

/// Production adapter wrapping the `audioplayers` [AudioPlayer].
class AudioplayersService implements AudioPlayerService {
  final AudioPlayer _player;

  late final StreamController<bool> _isPlayingController =
      StreamController<bool>.broadcast();

  StreamSubscription? _stateSub;

  AudioplayersService() : _player = AudioPlayer() {
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      _isPlayingController.add(s == PlayerState.playing);
    });
  }

  @override
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;

  @override
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;

  @override
  Stream<bool> get onIsPlayingChanged => _isPlayingController.stream;

  @override
  Future<void> play(String filePath) async {
    final source = DeviceFileSource(filePath);
    await _player.play(source);
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<Duration?> getDuration() => _player.getDuration();

  @override
  void dispose() {
    _stateSub?.cancel();
    _isPlayingController.close();
    _player.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioplayersService();
  ref.onDispose(service.dispose);
  return service;
});

// ─── State ────────────────────────────────────────────────────────────────────

class AudioPlayerState {
  final String? filePath;
  final String? fileName;
  final Duration duration;
  final Duration position;
  final bool isPlaying;

  const AudioPlayerState({
    this.filePath,
    this.fileName,
    this.duration = Duration.zero,
    this.position = Duration.zero,
    this.isPlaying = false,
  });

  double get progress {
    if (duration == Duration.zero) return 0.0;
    final ratio = position.inMilliseconds / duration.inMilliseconds;
    return ratio.clamp(0.0, 1.0);
  }

  AudioPlayerState copyWith({
    String? filePath,
    String? fileName,
    Duration? duration,
    Duration? position,
    bool? isPlaying,
  }) {
    return AudioPlayerState(
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final AudioPlayerService _service;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;

  /// Default constructor used by the Riverpod provider — injects the
  /// concrete [AudioPlayerService] from the provider tree.
  AudioPlayerNotifier(AudioPlayerService service)
      : _service = service,
        super(const AudioPlayerState()) {
    _initListeners();
  }

  /// Named constructor for unit tests — accepts any [AudioPlayerService] directly.
  AudioPlayerNotifier.withService(AudioPlayerService service)
      : _service = service,
        super(const AudioPlayerState()) {
    _initListeners();
  }

  void _initListeners() {
    _durationSub = _service.onDurationChanged.listen((d) {
      if (mounted) state = state.copyWith(duration: d);
    });
    _positionSub = _service.onPositionChanged.listen((p) {
      if (mounted) state = state.copyWith(position: p);
    });
    _stateSub = _service.onIsPlayingChanged.listen((playing) {
      if (mounted) state = state.copyWith(isPlaying: playing);
    });
  }

  Future<void> play(String filePath, String fileName) async {
    if (state.filePath == filePath) {
      if (!state.isPlaying) await resume();
      return;
    }

    await _service.stop();

    state = AudioPlayerState(
      filePath: filePath,
      fileName: fileName,
    );

    try {
      await _service.play(filePath);
      final d = await _service.getDuration();
      if (d != null && d != Duration.zero && mounted) {
        state = state.copyWith(duration: d);
      }
    } catch (e) {
      debugPrint('AudioPlayer error: $e');
    }
  }

  Future<void> pause() => _service.pause();

  Future<void> resume() async {
    if (state.filePath != null) await _service.resume();
  }

  Future<void> toggle() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> playOrToggle(String filePath, String fileName) async {
    if (state.filePath == filePath) {
      await toggle();
    } else {
      await play(filePath, fileName);
    }
  }

  Future<void> seek(Duration position) => _service.seek(position);

  Future<void> seekRelative(Duration offset) async {
    final target = state.position + offset;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > state.duration ? state.duration : target);
    await seek(clamped);
  }

  Future<void> stop() async {
    await _service.stop();
    if (mounted) state = const AudioPlayerState();
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    // Note: _service.dispose() is NOT called here because the service
    // lifecycle is managed by audioPlayerServiceProvider.  When used with
    // AudioPlayerNotifier.withService() in tests the caller is responsible
    // for disposing the fake service.
    super.dispose();
  }
}

final audioPlayerStateProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return AudioPlayerNotifier(service);
});
