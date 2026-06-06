import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

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

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final AudioPlayer _player;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;

  AudioPlayerNotifier() : _player = AudioPlayer(), super(const AudioPlayerState()) {
    _initListeners();
  }

  void _initListeners() {
    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) {
        state = state.copyWith(duration: d);
      }
    });
    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) {
        state = state.copyWith(position: p);
      }
    });
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (mounted) {
        state = state.copyWith(isPlaying: s == PlayerState.playing);
      }
    });
  }

  Future<void> play(String filePath, String fileName) async {
    if (state.filePath == filePath) {
      if (!state.isPlaying) {
        await resume();
      }
      return;
    }

    // Stop current playback
    await _player.stop();

    state = AudioPlayerState(
      filePath: filePath,
      fileName: fileName,
      duration: Duration.zero,
      position: Duration.zero,
      isPlaying: false,
    );

    try {
      final source = DeviceFileSource(filePath);
      await _player.setSource(source);
      await _player.play(source);
      
      final d = await _player.getDuration();
      if (d != null && d != Duration.zero) {
        if (mounted) {
          state = state.copyWith(duration: d);
        }
      }
    } catch (e) {
      debugPrint('AudioPlayer error: $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    if (state.filePath != null) {
      await _player.resume();
    }
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

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> seekRelative(Duration offset) async {
    final target = state.position + offset;
    final clamped = target < Duration.zero 
        ? Duration.zero 
        : (target > state.duration ? state.duration : target);
    await seek(clamped);
  }

  Future<void> stop() async {
    await _player.stop();
    if (mounted) {
      state = const AudioPlayerState();
    }
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}

final audioPlayerStateProvider = StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
  final notifier = AudioPlayerNotifier();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});
