import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/audio_player_service.dart';
import '../../data/audio_player_service_impl.dart';

part 'audio_player_providers.g.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class AudioPlayerState {
  final String? filePath;
  final String? fileName;
  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final double playbackRate;

  const AudioPlayerState({
    this.filePath,
    this.fileName,
    this.duration = Duration.zero,
    this.position = Duration.zero,
    this.isPlaying = false,
    this.playbackRate = 1.0,
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
    double? playbackRate,
  }) {
    return AudioPlayerState(
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackRate: playbackRate ?? this.playbackRate,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

@riverpod
class AudioPlayerNotifier extends _$AudioPlayerNotifier {
  final AudioPlayerService? _customService;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;
  AudioPlayerState _unmanagedState = const AudioPlayerState();
  bool _isDisposed = false;

  AudioPlayerNotifier([AudioPlayerService? service]) : _customService = service;

  AudioPlayerNotifier.withService(AudioPlayerService service) : _customService = service {
    _initListeners(service);
  }

  bool get _isManaged {
    try {
      // ignore: unnecessary_null_comparison
      return ref != null;
    } catch (_) {
      return false;
    }
  }

  @override
  AudioPlayerState get state {
    if (!_isManaged) return _unmanagedState;
    return super.state;
  }

  @override
  set state(AudioPlayerState value) {
    if (!_isManaged) {
      _unmanagedState = value;
      return;
    }
    super.state = value;
  }

  bool get mounted => !_isDisposed;

  @override
  AudioPlayerState build() {
    _isDisposed = false;
    final service = _customService ?? ref.watch(audioPlayerServiceProvider);
    _initListeners(service);
    ref.onDispose(() {
      _isDisposed = true;
      _durationSub?.cancel();
      _positionSub?.cancel();
      _stateSub?.cancel();
    });
    return const AudioPlayerState();
  }

  void _initListeners(AudioPlayerService? service) {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    if (service == null) return;

    _durationSub = service.onDurationChanged.listen((d) {
      if (mounted) state = state.copyWith(duration: d);
    });
    _positionSub = service.onPositionChanged.listen((p) {
      if (mounted) state = state.copyWith(position: p);
    });
    _stateSub = service.onIsPlayingChanged.listen((playing) {
      if (mounted) state = state.copyWith(isPlaying: playing);
    });
  }

  AudioPlayerService get _service {
    if (_customService != null) return _customService;
    if (_isManaged) return ref.read(audioPlayerServiceProvider);
    throw StateError('No AudioPlayerService available');
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

  Future<void> setPlaybackRate(double rate) async {
    await _service.setPlaybackRate(rate);
    if (mounted) state = state.copyWith(playbackRate: rate);
  }

  Future<void> stop() async {
    await _service.stop();
    if (mounted) state = const AudioPlayerState();
  }

  void dispose() {
    _isDisposed = true;
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
  }
}

/// Backwards compatibility alias for the legacy provider name.
final audioPlayerStateProvider = audioPlayerNotifierProvider;
