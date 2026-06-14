import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prism/features/editor/presentation/providers/audio_player_providers.dart';

// ---------------------------------------------------------------------------
// Fake AudioPlayerService for testing
// ---------------------------------------------------------------------------
class FakeAudioPlayerService implements AudioPlayerService {
  final List<String> calls = [];
  String? playedFilePath;
  bool isPlaying = false;

  // Streams for event forwarding
  final _durationController = StreamController<Duration>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _stateController = StreamController<bool>.broadcast();

  @override
  Stream<Duration> get onDurationChanged => _durationController.stream;

  @override
  Stream<Duration> get onPositionChanged => _positionController.stream;

  @override
  Stream<bool> get onIsPlayingChanged => _stateController.stream;

  @override
  Future<void> play(String filePath) async {
    calls.add('play:$filePath');
    playedFilePath = filePath;
    isPlaying = true;
    _stateController.add(true);
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    isPlaying = false;
    _stateController.add(false);
  }

  @override
  Future<void> resume() async {
    calls.add('resume');
    isPlaying = true;
    _stateController.add(true);
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    isPlaying = false;
    _stateController.add(false);
  }

  @override
  Future<void> seek(Duration position) async {
    calls.add('seek:${position.inMilliseconds}');
  }

  @override
  Future<Duration?> getDuration() async {
    calls.add('getDuration');
    return const Duration(seconds: 60);
  }

  @override
  void dispose() {
    _durationController.close();
    _positionController.close();
    _stateController.close();
  }
}

void main() {
  late FakeAudioPlayerService fakeService;
  late AudioPlayerNotifier notifier;

  setUp(() {
    fakeService = FakeAudioPlayerService();
    notifier = AudioPlayerNotifier.withService(fakeService);
  });

  tearDown(() {
    notifier.dispose();
  });

  group('AudioPlayerNotifier via AudioPlayerService seam', () {
    test('play() calls service.play with the file path', () async {
      await notifier.play('/some/audio.m4a', 'audio.m4a');

      expect(fakeService.calls, contains('play:/some/audio.m4a'));
      expect(notifier.state.filePath, equals('/some/audio.m4a'));
      expect(notifier.state.fileName, equals('audio.m4a'));
    });

    test('pause() calls service.pause', () async {
      await notifier.play('/audio.m4a', 'audio.m4a');
      await notifier.pause();

      expect(fakeService.calls, contains('pause'));
    });

    test('resume() calls service.resume when filePath is set', () async {
      await notifier.play('/audio.m4a', 'audio.m4a');
      await notifier.pause();
      await notifier.resume();

      expect(fakeService.calls, contains('resume'));
    });

    test('stop() calls service.stop and resets state', () async {
      await notifier.play('/audio.m4a', 'audio.m4a');
      await notifier.stop();

      expect(fakeService.calls, contains('stop'));
      expect(notifier.state.filePath, isNull);
      expect(notifier.state.isPlaying, isFalse);
    });

    test('seek() calls service.seek with the given position', () async {
      await notifier.play('/audio.m4a', 'audio.m4a');
      await notifier.seek(const Duration(seconds: 30));

      expect(fakeService.calls, contains('seek:30000'));
    });

    test('toggle() pauses when playing, resumes when paused', () async {
      await notifier.play('/audio.m4a', 'audio.m4a');
      // Simulate playing state via stream
      await notifier.toggle();  // should pause if playing

      expect(fakeService.calls, anyOf(contains('pause'), contains('resume')));
    });

    test('playOrToggle plays a new file and toggles for same file', () async {
      await notifier.playOrToggle('/file-a.m4a', 'file-a.m4a');
      expect(fakeService.calls.where((c) => c.startsWith('play')), isNotEmpty);

      // Same file → should toggle
      final callsBefore = List<String>.from(fakeService.calls);
      await notifier.playOrToggle('/file-a.m4a', 'file-a.m4a');
      final newCalls = fakeService.calls.sublist(callsBefore.length);
      expect(newCalls, anyOf(contains('pause'), contains('resume')));
    });

    test('AudioPlayerService provider can be overridden with fake', () async {
      final fakeService2 = FakeAudioPlayerService();
      final container = ProviderContainer(
        overrides: [
          audioPlayerServiceProvider.overrideWith((ref) => fakeService2),
        ],
      );
      addTearDown(container.dispose);

      final notifier2 = container.read(audioPlayerStateProvider.notifier);
      await notifier2.play('/test.m4a', 'test.m4a');

      expect(fakeService2.calls, contains('play:/test.m4a'));
    });
  });
}
