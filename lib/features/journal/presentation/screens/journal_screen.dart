import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/utils.dart';
import '../../../notes/data/note_repository.dart';
import '../../../notes/data/note_model.dart';
import '../../../../core/database/database_providers.dart';
import '../widgets/journal_template_button.dart';
import '../widgets/journal_empty_illustration.dart';
import '../widgets/journal_calendar.dart';
import '../widgets/journal_entry_card.dart';

final _selectedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  bool _showCalendar = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedDay = ref.watch(_selectedDayProvider);

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colorScheme, selectedDay),
            if (_showCalendar)
              JournalCalendar(
                selectedDay: selectedDay,
                selectedDayProvider: _selectedDayProvider,
              ),
            Expanded(child: _buildJournalContent(colorScheme, selectedDay)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, DateTime selectedDay) {
    final isToday_ = isToday(formatDailyDate(selectedDay));
    return Padding(
      padding: const EdgeInsets.fromLTRB(DesignSpacing.screenPadding + 2, 16, DesignSpacing.screenPadding, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Journal',
                style: DesignTypography.display(
                  context,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                isToday_ ? 'Today' : DateFormat('EEEE, MMMM d').format(selectedDay),
                style: DesignTypography.body(
                  context,
                  fontSize: 14,
                  color: DesignColors.textSecondary(context),
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _showCalendar ? Icons.calendar_today : Icons.calendar_month_outlined,
                key: ValueKey(_showCalendar),
                size: 22,
                color: _showCalendar
                    ? colorScheme.primary
                    : DesignColors.textSecondary(context),
              ),
            ),
            onPressed: () => setState(() => _showCalendar = !_showCalendar),
          ),
        ],
      ),
    );
  }



  Widget _buildJournalContent(ColorScheme colorScheme, DateTime selectedDay) {
    final dateStr = formatDailyDate(selectedDay);
    final dailyNoteAsync = ref.watch(
      FutureProvider.autoDispose(
        (ref) async {
          ref.watch(notesVersionProvider); // React to version updates reactively
          final note = await ref.read(noteRepositoryProvider).getDailyNote(dateStr);
          if (note == null) return null;

          final file = File(note.filePath);
          String content = '';
          if (await file.exists()) {
            content = await file.readAsString();
          }
          return (note: note, content: content);
        },
      ).future,
    );

    return FutureBuilder<({Note note, String content})?>(
      future: dailyNoteAsync,
      builder: (context, snapshot) {
        final data = snapshot.data;

        return Padding(
          padding: const EdgeInsets.fromLTRB(DesignSpacing.screenPadding, 16, DesignSpacing.screenPadding, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data == null) ...[
                // Uppercase contextual header for templates
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
                _buildTemplatesRow(colorScheme),
                const SizedBox(height: 24),
              ],
              
              // Entry state
              data != null
                  ? JournalEntryCard(note: data.note, content: data.content)
                  : Expanded(
                      child: _buildEmptyDay(context, colorScheme, dateStr),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplatesRow(ColorScheme colorScheme) {
    final templates = [
      const JournalTemplateItem(
        icon: DesignIcons.gratitude,
        label: 'Gratitude',
        emoji: '🙏',
        baseColor: MeridianColors.darkAccentRose,
      ),
      const JournalTemplateItem(
        icon: DesignIcons.dailyPlan,
        label: 'Daily Plan',
        emoji: '📋',
        baseColor: MeridianColors.darkAccentGreen,
      ),
      const JournalTemplateItem(
        icon: DesignIcons.reflection,
        label: 'Reflection',
        emoji: '💭',
        baseColor: MeridianColors.darkAccentAmber,
      ),
      const JournalTemplateItem(
        icon: DesignIcons.goals,
        label: 'Goals',
        emoji: '🎯',
        baseColor: Color(0xFF8AB4F8),
      ),
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final t = templates[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TactileWrapper(
              style: TactileFeedbackStyle.highImpact,
              onTap: () => _createWithTemplate(t.emoji, t.label),
              child: JournalTemplateButton(
                template: t,
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildEmptyDay(
    BuildContext context,
    ColorScheme colorScheme,
    String dateStr,
  ) {
    final isFuture = DateTime.parse(dateStr).isAfter(DateTime.now());
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          JournalEmptyIllustration(
            isFuture: isFuture,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 24),
          Text(
            isFuture ? 'A future day' : 'No entry yet',
            style: DesignTypography.heading(
              context,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFuture
                ? 'Come back on this day to start writing'
                : 'Tap the button below to start your entry',
            style: DesignTypography.body(
              context,
              fontSize: 14,
              color: DesignColors.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          if (!isFuture) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: DesignPrimaryButton(
                label: 'Start Writing',
                icon: DesignIcons.add,
                onTap: () => _createDailyNote(context, dateStr, null),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }


  Future<void> _createDailyNote(
    BuildContext context,
    String dateStr,
    String? templateContent,
  ) async {
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.createNote(
      title: dateStr,
      initialContent: templateContent ?? '# $dateStr\n\n',
      isDaily: true,
      dailyDate: dateStr,
    );
    if (context.mounted) context.push('/editor/${note.id}?date=$dateStr');
  }

  void _createWithTemplate(String emoji, String templateName) {
    final selectedDay = ref.read(_selectedDayProvider);
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
