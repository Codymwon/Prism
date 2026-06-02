import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../core/utils/utils.dart';
import '../../../notes/data/note_model.dart';
import '../../../notes/data/note_repository.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../widgets/journal_calendar.dart';
import '../widgets/journal_entry_card.dart';
import '../widgets/journal_header.dart';
import '../widgets/journal_week_strip.dart';
import '../widgets/journal_word_count_progress.dart';
import '../widgets/journal_templates_row.dart';
import '../widgets/journal_empty_state.dart';

final selectedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());

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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              ),
            // 7-day quick-navigation strip (visible only when calendar is closed)
            if (!_showCalendar)
              const JournalWeekStrip(),
            Expanded(
              child: _buildJournalContent(colorScheme, selectedDay),
            ),
          ],
        ),
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
          return _buildContentSwitcher(colorScheme, _lastLoadedData, _lastLoadedDateStr!);
        }
        // First-time load: show a clean, centered progress indicator
        return const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      error: (e, _) => Center(
        child: Text('Error: $e', style: TextStyle(color: colorScheme.error)),
      ),
      data: (data) {
        // Update cache on successful load
        _lastLoadedData = data;
        _lastLoadedDateStr = dateStr;
        return _buildContentSwitcher(colorScheme, data, dateStr);
      },
    );
  }

  // Smooth cross-fade transition when day changes
  Widget _buildContentSwitcher(ColorScheme colorScheme, ({Note note, String content})? data, String dateStr) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
      child: Container(
        key: ValueKey<String>(dateStr),
        child: _buildJournalLayout(colorScheme, data, dateStr),
      ),
    );
  }

  Widget _buildJournalLayout(ColorScheme colorScheme, ({Note note, String content})? data, String dateStr) {
    final isFuture = DateTime.parse(dateStr).isAfter(DateTime.now());
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        DesignSpacing.screenPadding,
        _showCalendar ? 8 : 12,
        DesignSpacing.screenPadding,
        100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data != null) ...[
            // ── Word Count Progress Bar ──────────────────────────────────
            JournalWordCountProgress(wordCount: data.note.wordCount),
            const SizedBox(height: 12),
            // ── Entry card (scrollable content preview) ──────────────────
            JournalEntryCard(note: data.note, content: data.content),
          ] else if (!isFuture) ...[
            // ── Template picker (no entry yet) ───────────────────────────
            Text(
              'START WITH A TEMPLATE',
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
          ] else ...[
            // ── Future day ───────────────────────────────────────────────
            JournalEmptyState(
              dateStr: dateStr,
              showCalendar: _showCalendar,
              onStartWriting: () => _createDailyNote(context, dateStr, null),
            ),
          ],
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
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.createNote(
      title: dateStr,
      initialContent: templateContent ?? '# $dateStr\n\n',
      isDaily: true,
      dailyDate: dateStr,
    );
    if (context.mounted) {
      if (isDesktop) {
        ref.read(activeDesktopNoteIdProvider.notifier).state = note.id;
      } else {
        context.push('/editor/${note.id}?date=$dateStr&new=true');
      }
    }
  }

  void _createWithTemplate(String emoji, String templateName) {
    final selectedDay = ref.read(selectedDayProvider);
    final dateStr = formatDailyDate(selectedDay);
    final templates = {
      'Gratitude': '# $dateStr\n\n## 🙏 Gratitude\n\n- I am grateful for...\n- Something that made me smile...\n- A person I appreciate...\n\n',
      'Daily Plan': '# $dateStr\n\n## 📋 Today\'s Plan\n\n### 🎯 Top 3 priorities\n1. \n2. \n3. \n\n### 📅 Schedule\n\n\n### 🌙 End of day reflection\n\n',
      'Reflection': '# $dateStr\n\n## 💭 Reflection\n\n### What went well?\n\n\n### What could be better?\n\n\n### Key learnings\n\n',
      'Goals': '# $dateStr\n\n## 🎯 Goals Check-in\n\n### Progress on current goals\n\n\n### New goal ideas\n\n\n### Blockers\n\n',
    };
    _createDailyNote(context, dateStr, templates[templateName]);
  }
}
