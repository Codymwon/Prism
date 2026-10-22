import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/editor/domain/audio_player_service.dart';
import 'package:prism/features/editor/data/audio_player_service_impl.dart';
import 'package:prism/features/editor/presentation/providers/audio_player_providers.dart';
import 'package:prism/features/editor/presentation/providers/docked_audio_provider.dart';
import 'package:prism/features/editor/presentation/widgets/audio_evidence_panel.dart';
import 'package:prism/l10n/l10n.dart';

class FakeAudioPlayerService implements AudioPlayerService {
  String? currentUrl;
  bool isPlayingState = false;
  double currentRate = 1.0;
  final StreamController<Duration> _posController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durController =
      StreamController<Duration>.broadcast();
  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast();

  @override
  Stream<Duration> get onPositionChanged => _posController.stream;
  @override
  Stream<Duration> get onDurationChanged => _durController.stream;
  @override
  Stream<bool> get onIsPlayingChanged => _playingController.stream;

  @override
  Future<void> play(String url) async {
    currentUrl = url;
    isPlayingState = true;
    _playingController.add(true);
  }

  @override
  Future<void> pause() async {
    isPlayingState = false;
    _playingController.add(false);
  }

  @override
  Future<void> resume() async {
    isPlayingState = true;
    _playingController.add(true);
  }

  @override
  Future<void> stop() async {
    isPlayingState = false;
    _playingController.add(false);
  }

  @override
  Future<void> seek(Duration position) async {
    _posController.add(position);
  }

  @override
  Future<Duration?> getDuration() async {
    return const Duration(minutes: 2);
  }

  @override
  Future<void> setPlaybackRate(double rate) async {
    currentRate = rate;
  }

  @override
  void dispose() {
    _posController.close();
    _durController.close();
    _playingController.close();
  }
}

void main() {
  late FakeAudioPlayerService fakePlayerService;

  setUp(() {
    fakePlayerService = FakeAudioPlayerService();
  });

  tearDown(() {
    fakePlayerService.dispose();
  });

  Widget buildTestWidget({
    required DockedAudio dockedAudio,
    required VoidCallback onUndock,
    void Function(int timestampMs)? onAddBookmark,
  }) {
    return ProviderScope(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(fakePlayerService),
        audioPlayerStateProvider.overrideWith(
          (ref) => AudioPlayerNotifier.withService(fakePlayerService),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AudioEvidencePanel(
            dockedAudio: dockedAudio,
            onUndock: onUndock,
            onAddBookmark: onAddBookmark,
          ),
        ),
      ),
    );
  }

  testWidgets('AudioEvidencePanel renders docked audio details and controls',
      (tester) async {
    const docked = DockedAudio(
      filePath: '/path/to/meeting.m4a',
      fileName: 'meeting.m4a',
      noteId: 'test-note-1',
    );

    await tester.pumpWidget(
      buildTestWidget(
        dockedAudio: docked,
        onUndock: () {},
      ),
    );

    expect(find.byKey(const ValueKey('audio_evidence_panel')), findsOneWidget);
    expect(find.text('meeting.m4a'), findsOneWidget);
    expect(find.text('00:00 / 00:00'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.byKey(const ValueKey('audio_evidence_speed_button')),
        findsOneWidget);
    expect(find.text('1.0x'), findsOneWidget);
    expect(find.byKey(const ValueKey('audio_evidence_add_bookmark')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('audio_evidence_close')), findsOneWidget);
  });

  testWidgets('AudioEvidencePanel play button starts playback', (tester) async {
    const docked = DockedAudio(
      filePath: '/path/to/meeting.m4a',
      fileName: 'meeting.m4a',
      noteId: 'test-note-1',
    );

    await tester.pumpWidget(
      buildTestWidget(
        dockedAudio: docked,
        onUndock: () {},
      ),
    );

    final playButton = find.byKey(const ValueKey('audio_evidence_play_pause'));
    expect(playButton, findsOneWidget);

    await tester.tap(playButton);
    await tester.pump();

    expect(fakePlayerService.currentUrl, '/path/to/meeting.m4a');
    expect(fakePlayerService.isPlayingState, isTrue);
  });

  testWidgets('AudioEvidencePanel speed button cycles playback rate',
      (tester) async {
    const docked = DockedAudio(
      filePath: '/path/to/meeting.m4a',
      fileName: 'meeting.m4a',
      noteId: 'test-note-1',
    );

    await tester.pumpWidget(
      buildTestWidget(
        dockedAudio: docked,
        onUndock: () {},
      ),
    );

    // Initial is 1.0x
    expect(find.text('1.0x'), findsOneWidget);

    // Tap speed button -> cycles to 1.5x
    await tester.tap(find.byKey(const ValueKey('audio_evidence_speed_button')));
    await tester.pump();
    expect(fakePlayerService.currentRate, 1.5);
    expect(find.text('1.5x'), findsOneWidget);

    // Tap speed button -> cycles to 2.0x
    await tester.tap(find.byKey(const ValueKey('audio_evidence_speed_button')));
    await tester.pump();
    expect(fakePlayerService.currentRate, 2.0);
    expect(find.text('2.0x'), findsOneWidget);

    // Tap speed button -> cycles to 0.8x
    await tester.tap(find.byKey(const ValueKey('audio_evidence_speed_button')));
    await tester.pump();
    expect(fakePlayerService.currentRate, 0.8);
    expect(find.text('0.8x'), findsOneWidget);
  });

  testWidgets('AudioEvidencePanel 1-tap bookmark invokes onAddBookmark callback',
      (tester) async {
    int? receivedTimestamp;
    const docked = DockedAudio(
      filePath: '/path/to/meeting.m4a',
      fileName: 'meeting.m4a',
      noteId: 'template:note-id', // Template note to skip repository call
    );

    await tester.pumpWidget(
      buildTestWidget(
        dockedAudio: docked,
        onUndock: () {},
        onAddBookmark: (ts) {
          receivedTimestamp = ts;
        },
      ),
    );

    final bookmarkBtn = find.byKey(const ValueKey('audio_evidence_add_bookmark'));
    expect(bookmarkBtn, findsOneWidget);

    await tester.tap(bookmarkBtn);
    await tester.pump();

    expect(receivedTimestamp, isNotNull);
    expect(receivedTimestamp, 0);
  });

  testWidgets('AudioEvidencePanel undock and close buttons invoke onUndock',
      (tester) async {
    int undockCallCount = 0;
    const docked = DockedAudio(
      filePath: '/path/to/meeting.m4a',
      fileName: 'meeting.m4a',
      noteId: 'test-note-1',
    );

    await tester.pumpWidget(
      buildTestWidget(
        dockedAudio: docked,
        onUndock: () {
          undockCallCount++;
        },
      ),
    );

    // Tap close button
    final closeBtn = find.byKey(const ValueKey('audio_evidence_close'));
    await tester.tap(closeBtn);
    await tester.pump();
    expect(undockCallCount, 1);

    // Tap pin toggle button
    final pinBtn = find.byKey(const ValueKey('audio_evidence_undock'));
    await tester.tap(pinBtn);
    await tester.pump();
    expect(undockCallCount, 2);
  });
}
