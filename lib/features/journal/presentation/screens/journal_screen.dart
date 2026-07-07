import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../core/utils/utils.dart';
import '../../../notes/data/note_model.dart';
import '../../../notes/data/note_repository.dart';
import '../providers/journal_providers.dart';
import '../widgets/journal_calendar.dart';
import '../widgets/journal_entry_card.dart';
import '../widgets/journal_header.dart';
import '../widgets/journal_week_strip.dart';
import '../widgets/journal_streak_grid.dart';
import '../widgets/journal_templates_row.dart';
import '../widgets/journal_empty_state.dart';
import 'package:prism/l10n/l10n.dart';

final selectedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());
final focusedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  bool _showCalendar = false;

  // Cache of the last successfully loaded daily note data and date string
  ({Note note, String content})? _lastLoadedData;
  String? _lastLoadedDateStr;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedDay = ref.watch(selectedDayProvider);

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                JournalHeader(
                  selectedDay: selectedDay,
                  showCalendar: _showCalendar,
                  onToggleCalendar: () => setState(() => _showCalendar = !_showCalendar),
                ),
                if (_showCalendar)
                  JournalCalendar(
                    selectedDay: selectedDay,
                    selectedDayProvider: selectedDayProvider,
                    focusedDayProvider: focusedDayProvider,
                  ),
                // 7-day quick-navigation strip (visible only when calendar is closed)
                if (!_showCalendar)
                  const JournalWeekStrip(),
              ],
            ),
          ),
          Expanded(
            child: _buildJournalContent(colorScheme, selectedDay),
          ),
        ],
      ),
    );
  }

  // ─── Main journal content ────────────────────────────────────────────────────
  Widget _buildJournalContent(ColorScheme colorScheme, DateTime selectedDay) {
    final dateStr = formatDailyDate(selectedDay);
    // Use a proper named family provider — no inline anti-pattern
    final dailyAsync = ref.watch(dailyNoteProvider(dateStr));

    return dailyAsync.when(
      loading: () {
        // If we have cached data from another day, keep rendering it to prevent unmounting/flicker
        if (_lastLoadedDateStr != null) {
          return _buildJournalLayout(colorScheme, _lastLoadedData, _lastLoadedDateStr!);
        }
        // First-time load: show a clean, centered progress indicator
        return const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Loading'),
          ),
        );
      },
      error: (e, _) => Center(
        child: Text(context.l10n.journal_screen_error(e.toString()), style: TextStyle(color: colorScheme.error)),
      ),
      data: (data) {
        // Update cache on successful load
        _lastLoadedData = data;
        _lastLoadedDateStr = dateStr;
        return _buildJournalLayout(colorScheme, data, dateStr);
      },
    );
  }

  // Smooth cross-fade transition below the static streak grid
  Widget _buildDynamicContentSwitcher(ColorScheme colorScheme, ({Note note, String content})? data, String dateStr) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
      child: _buildDynamicContent(colorScheme, data, dateStr),
    );
  }

  Widget _buildDynamicContent(ColorScheme colorScheme, ({Note note, String content})? data, String dateStr) {
    final isFuture = DateTime.parse(dateStr).isAfter(DateTime.now());

    if (data != null) {
      return JournalEntryCard(
        key: ValueKey<String>('entry_${data.note.id}'),
        note: data.note,
        content: data.content,
      );
    } else if (!isFuture) {
      return Column(
        key: const ValueKey<String>('empty_past'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.journal_screen_start_with_template,
            style: DesignTypography.metadata(
              context,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          JournalTemplatesRow(onTemplateSelected: _createWithTemplate),
          const SizedBox(height: 32),
          JournalEmptyState(
            dateStr: dateStr,
            showCalendar: _showCalendar,
            onStartWriting: () => _createDailyNote(context, dateStr, null),
          ),
        ],
      );
    } else {
      return JournalEmptyState(
        key: const ValueKey<String>('empty_future'),
        dateStr: dateStr,
        showCalendar: _showCalendar,
        onStartWriting: () => _createDailyNote(context, dateStr, null),
      );
    }
  }

  Widget _buildJournalLayout(ColorScheme colorScheme, ({Note note, String content})? data, String dateStr) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        DesignSpacing.screenPadding,
        _showCalendar ? 8 : 4,
        DesignSpacing.screenPadding,
        100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Consistency Streak Grid ──────────────────────────────────
          const JournalStreakGrid(),
          const SizedBox(height: 12),
          // ── Switcher for dynamic content below the grid ───────────────
          _buildDynamicContentSwitcher(colorScheme, data, dateStr),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Future<void> _createDailyNote(
    BuildContext context,
    String dateStr,
    String? templateContent,
  ) async {
    final repo = ref.read(noteRepositoryProvider);
    final String initialContent;
    if (templateContent != null) {
      initialContent = templateContent;
    } else {
      final buffer = StringBuffer();
      buffer.writeln('---');
      buffer.writeln('title: "Daily Reflection"');
      buffer.writeln('date: $dateStr');
      buffer.writeln('---');
      buffer.writeln();
      initialContent = buffer.toString();
    }
    final note = await repo.createNote(
      title: context.l10n.journal_screen_default_template_title,
      initialContent: initialContent,
      isDaily: true,
      dailyDate: dateStr,
    );
    if (context.mounted) {
      context.push('/editor/${note.id}?date=$dateStr&new=true');
    }
  }

  void _createWithTemplate(String templateName) {
    final selectedDay = ref.read(selectedDayProvider);
    final dateStr = formatDailyDate(selectedDay);
    final templates = {
      'Gratitude': '---\ntitle: "Daily Reflection"\ndate: $dateStr\n---\n\n> "Gratitude turns what we have into enough."\n\n## Gratitude\n- I am grateful for: \n- Today\'s highlight: ==focus==\n\n## Mindful Space\n*Record a voice reflection using the microphone tool, or attach a photo.*\n\n## Daily Habits\n- [ ] Practice presence\n- [ ] Connect with a friend\n\n#journal/gratitude\n',
      'Daily Plan': '---\ntitle: "Daily Reflection"\ndate: $dateStr\n---\n\n## Today\'s Focus\n==Main objective for today: ==\n\n## Checklist\n- [ ] Priority task 1\n- [ ] Priority task 2\n- [ ] Priority task 3\n- [ ] Routine checklist item\n\n## Connected Context\n- Linked goals: [[Annual Goals]]\n- Ideas & notes: \n\n#journal/plan\n',
      'Reflection': '---\ntitle: "Daily Reflection"\ndate: $dateStr\n---\n\n## Reflection\n- **Wins & progress:** \n- **Lessons & challenges:** \n\n## Mindful Quote\n> What did today teach me?\n\n## End-of-Day Check\n- [ ] Reflection completed\n- [ ] Tomorrow planned\n\n- Linked review: [[Weekly Review]]\n\n#journal/reflection\n',
      'Goals': '---\ntitle: "Daily Reflection"\ndate: $dateStr\n---\n\n## Goal Progress\n- **Active focus:** ==Target goal==\n- Next actionable milestone: \n\n## Actions\n- [ ] Goal milestone task 1\n- [ ] Goal milestone task 2\n- [ ] Resolve any blockers\n\n- Projects board: [[Projects]]\n\n#journal/goals\n',
    };
    _createDailyNote(context, dateStr, templates[templateName]!);
  }
}