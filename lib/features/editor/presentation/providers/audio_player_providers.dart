import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/audio_player_service.dart';
import '../../data/audio_player_service_impl.dart';



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
