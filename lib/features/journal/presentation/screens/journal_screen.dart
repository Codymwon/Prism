import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
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
            if (_showCalendar) _buildCalendar(colorScheme, selectedDay),
            Expanded(child: _buildJournalContent(colorScheme, selectedDay)),
          ],
        ),
      ),
      floatingActionButton: _buildTodayFAB(context, colorScheme),
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
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05),
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

  Widget _buildCalendar(ColorScheme colorScheme, DateTime selectedDay) {
    return TableCalendar(
      firstDay: DateTime(2020),
      lastDay: DateTime(2030),
      focusedDay: selectedDay,
      selectedDayPredicate: (day) => isSameDay(day, selectedDay),
      calendarFormat: CalendarFormat.month,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: DesignTypography.heading(
          context,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        leftChevronIcon: Icon(
          DesignIcons.back,
          color: DesignColors.textSecondary(context),
        ),
        rightChevronIcon: Icon(
          DesignIcons.chevronRight,
          color: DesignColors.textSecondary(context),
        ),
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        todayTextStyle: DesignTypography.body(
          context,
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        selectedDecoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: DesignTypography.body(
          context,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        defaultTextStyle: DesignTypography.body(
          context,
        ),
        weekendTextStyle: DesignTypography.body(
          context,
          color: DesignColors.textSecondary(context),
        ),
        outsideTextStyle: DesignTypography.body(
          context,
          color: DesignColors.textTertiary(context),
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: DesignTypography.body(
          context,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: DesignColors.textSecondary(context),
        ),
        weekendStyle: DesignTypography.body(
          context,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: DesignColors.textTertiary(context),
        ),
      ),
      onDaySelected: (selected, focused) {
        ref.read(_selectedDayProvider.notifier).state = selected;
      },
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05);
  }

  Widget _buildJournalContent(ColorScheme colorScheme, DateTime selectedDay) {
    final dateStr = formatDailyDate(selectedDay);
    final dailyNoteAsync = ref.watch(
      FutureProvider.autoDispose(
        (ref) {
          ref.watch(notesVersionProvider); // React to version updates reactively
          return ref.read(noteRepositoryProvider).getDailyNote(dateStr);
        },
      ).future,
    );

    return FutureBuilder<Note?>(
      future: dailyNoteAsync,
      builder: (context, snapshot) {
        final note = snapshot.data;

        return Padding(
          padding: const EdgeInsets.fromLTRB(DesignSpacing.screenPadding, 16, DesignSpacing.screenPadding, 0),
          child: Column(
            children: [
              // Templates row
              _buildTemplatesRow(colorScheme),
              const SizedBox(height: 16),
              // Entry state
              Expanded(
                child: note != null
                    ? _buildExistingEntry(context, colorScheme, note)
                    : _buildEmptyDay(context, colorScheme, dateStr),
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

  Widget _buildExistingEntry(
    BuildContext context,
    ColorScheme colorScheme,
    Note note,
  ) {
    return GestureDetector(
      onTap: () => context.push('/editor/${note.id}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DesignColors.surface(context),
          borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusLarge),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Entry written',
                  style: DesignTypography.heading(
                    context,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${note.wordCount} words',
                  style: DesignTypography.metadata(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Tap to continue writing…',
              style: DesignTypography.body(
                context,
                fontSize: 14,
                color: DesignColors.textSecondary(context),
              ).copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.97, 0.97));
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

  Widget _buildTodayFAB(BuildContext context, ColorScheme colorScheme) {
    final isToday_ = isToday(formatDailyDate(ref.watch(_selectedDayProvider)));
    if (!isToday_) return const SizedBox.shrink();

    return DesignFloatingActionButton(
      label: "Today's Entry",
      icon: DesignIcons.edit,
      onTap: () => _openOrCreateToday(context),
    ).animate().scale(begin: const Offset(0.8, 0.8), duration: 300.ms, curve: Curves.elasticOut);
  }

  Future<void> _openOrCreateToday(BuildContext context) async {
    final today = formatDailyDate(DateTime.now());
    final repo = ref.read(noteRepositoryProvider);
    var note = await repo.getDailyNote(today);
    note ??= await repo.createNote(
      title: today,
      isDaily: true,
      dailyDate: today,
    );
    if (context.mounted) context.push('/editor/${note.id}?date=$today');
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
