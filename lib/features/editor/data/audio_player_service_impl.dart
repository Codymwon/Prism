import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/audio_player_service.dart';

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
  Future<void> setPlaybackRate(double rate) => _player.setPlaybackRate(rate);

  @override
  void dispose() {
    _stateSub?.cancel();
    _isPlayingController.close();
    _player.dispose();
  }
}

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioplayersService();
  ref.onDispose(service.dispose);
  return service;
});
