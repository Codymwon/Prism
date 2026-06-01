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
import '../../../notes/presentation/providers/notes_providers.dart';
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
            // 7-day quick-navigation strip (visible only when calendar is closed)
            if (!_showCalendar)
              _buildWeekStrip(colorScheme, selectedDay)
                  .animate()
                  .fadeIn(duration: 250.ms)
                  .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
            Expanded(child: _buildJournalContent(colorScheme, selectedDay)),
          ],
        ),
      ),
    );
  }

  // ─── Header with streak badge + total count ──────────────────────────────────
  Widget _buildHeader(ColorScheme colorScheme, DateTime selectedDay) {
    final isToday_ = isToday(formatDailyDate(selectedDay));
    final streakAsync = ref.watch(journalStreakProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(DesignSpacing.screenPadding + 2, 16, DesignSpacing.screenPadding, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      isToday_ ? 'Today' : DateFormat('EEEE, MMMM d').format(selectedDay),
                      style: DesignTypography.body(
                        context,
                        fontSize: 14,
                        color: DesignColors.textSecondary(context),
                      ),
                    ),
                    streakAsync.maybeWhen(
                      data: (stats) {
                        if (stats.totalCount == 0) return const SizedBox.shrink();
                        return Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 7),
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: DesignColors.textTertiary(context),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Icon(Icons.history_edu_rounded, size: 13, color: DesignColors.textSecondary(context)),
                            const SizedBox(width: 3),
                            Text(
                              '${stats.totalCount} entries',
                              style: DesignTypography.body(
                                context,
                                fontSize: 13,
                                color: DesignColors.textSecondary(context),
                              ),
                            ),
                          ],
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Interactive themed streak pill placed next to calendar button
          streakAsync.maybeWhen(
            data: (stats) {
              if (stats.streak == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: TactileWrapper(
                  style: TactileFeedbackStyle.highImpact,
                  onTap: () => _showStreakDialog(context, stats.streak, stats.totalCount),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.15),
                          colorScheme.tertiary.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.whatshot_rounded,
                          size: 13,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${stats.streak}d streak',
                          style: DesignTypography.metadata(
                            context,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.elasticOut),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _showCalendar ? Icons.calendar_today : Icons.calendar_month_outlined,
                key: ValueKey(_showCalendar),
                size: 22,
                color: _showCalendar ? colorScheme.primary : DesignColors.textSecondary(context),
              ),
            ),
            onPressed: () => setState(() => _showCalendar = !_showCalendar),
          ),
        ],
      ),
    );
  }

  // ─── 7-Day Week Strip (Perfectly responsive, zero scroll) ───────────────────
  Widget _buildWeekStrip(ColorScheme colorScheme, DateTime selectedDay) {
    final today = DateTime.now();
    final writtenDates = ref.watch(allDailyDatesProvider).valueOrNull ?? const <String>{};

    // Show today + 6 days back
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSpacing.screenPadding, vertical: 8),
      child: Row(
        children: List.generate(days.length, (i) {
          final day = days[i];
          final dateStr = formatDailyDate(day);
          final isSelected = isSameDay(day, selectedDay);
          final isToday_ = isSameDay(day, today);
          final hasEntry = writtenDates.contains(dateStr);
          final isFuture = day.isAfter(today);

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == days.length - 1 ? 0 : 5),
              child: TactileWrapper(
                style: TactileFeedbackStyle.standard,
                onTap: isFuture ? null : () {
                  ref.read(_selectedDayProvider.notifier).state = day;
                  if (_showCalendar) setState(() => _showCalendar = false);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : DesignColors.surface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : isToday_
                              ? colorScheme.primary.withValues(alpha: 0.4)
                              : DesignColors.border(context),
                      width: isToday_ && !isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(day).substring(0, 1), // M, T, W…
                        style: DesignTypography.metadata(
                          context,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.75)
                              : DesignColors.textTertiary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${day.day}',
                        style: DesignTypography.heading(
                          context,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : isToday_
                                  ? colorScheme.primary
                                  : DesignColors.text(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Entry dot indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasEntry
                              ? (isSelected ? Colors.white : colorScheme.primary)
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Main journal content ────────────────────────────────────────────────────
  Widget _buildJournalContent(ColorScheme colorScheme, DateTime selectedDay) {
    final dateStr = formatDailyDate(selectedDay);
    // Use a proper named family provider — no inline anti-pattern
    final dailyAsync = ref.watch(dailyNoteProvider(dateStr));

    return dailyAsync.when(
      loading: () => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e', style: TextStyle(color: colorScheme.error)),
      ),
      data: (data) {
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
                _buildWordCountProgress(colorScheme, data.note.wordCount),
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
                _buildTemplatesRow(colorScheme),
                const SizedBox(height: 32),
                _buildEmptyDay(context, colorScheme, dateStr),
              ] else ...[
                // ── Future day ───────────────────────────────────────────────
                _buildEmptyDay(context, colorScheme, dateStr),
              ],
            ],
          ),
        );
      },
    );
  }

  // ─── Word Count Progress Bar (toward 250-word daily goal) ───────────────────
  Widget _buildWordCountProgress(ColorScheme colorScheme, int wordCount) {
    const goal = 250;
    final progress = (wordCount / goal).clamp(0.0, 1.0);
    final isDone = wordCount >= goal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DesignColors.surface(context),
        borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
        border: Border.all(color: DesignColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.edit_rounded,
            size: 14,
            color: isDone ? Colors.green : colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isDone ? 'Daily goal reached!' : '$wordCount / $goal words',
                      style: DesignTypography.body(
                        context,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDone ? Colors.green : DesignColors.text(context),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      isDone ? '✓ $wordCount words' : '${(goal - wordCount).clamp(0, goal)} to go',
                      style: DesignTypography.metadata(
                        context,
                        fontSize: 10,
                        color: DesignColors.textTertiary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: DesignColors.surfaceVariant(context),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? Colors.green : colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty day state ─────────────────────────────────────────────────────────
  Widget _buildEmptyDay(BuildContext context, ColorScheme colorScheme, String dateStr) {
    final isFuture = DateTime.parse(dateStr).isAfter(DateTime.now());

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_showCalendar) ...[
            JournalEmptyIllustration(
              isFuture: isFuture,
              colorScheme: colorScheme,
              size: 110.0,
            ),
            const SizedBox(height: 20),
          ],
          Text(
            isFuture ? 'A future day' : 'No entry yet',
            style: DesignTypography.heading(
              context,
              fontSize: _showCalendar ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFuture
                ? 'Come back on this day to start writing'
                : 'Tap below to start your entry for today',
            style: DesignTypography.body(
              context,
              fontSize: _showCalendar ? 13 : 14,
              color: DesignColors.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          if (!isFuture) ...[
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _showCalendar ? 40.0 : 20.0),
              child: DesignPrimaryButton(
                label: 'Start Writing',
                icon: DesignIcons.add,
                height: _showCalendar ? 44.0 : 52.0,
                onTap: () => _createDailyNote(context, dateStr, null),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  // ─── Template strip ──────────────────────────────────────────────────────────
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
              child: JournalTemplateButton(template: t),
            ),
          );
        },
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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
    if (context.mounted) context.push('/editor/${note.id}?date=$dateStr&new=true');
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

  void _showStreakDialog(BuildContext context, int streak, int totalCount) {
    final colorScheme = Theme.of(context).colorScheme;
    
    String encouragement;
    if (streak <= 2) {
      encouragement = 'Off to a fantastic start! Keep writing daily to build a powerful self-reflection habit.';
    } else if (streak <= 5) {
      encouragement = 'Incredible dedication! You are forming a powerful ritual. Every word is a step inward.';
    } else {
      encouragement = 'A legendary writing habit! You are unstoppable. Keep exploring your thoughts daily.';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: DesignColors.surface(context),
      barrierColor: Colors.black.withValues(alpha: 0.4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const DesignSheetDragHandle(),
                const SizedBox(height: 8),
                // Pulsing themed fire icon
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.whatshot_rounded,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .scale(end: const Offset(1.1, 1.1), duration: 1000.ms, curve: Curves.easeInOut),
                const SizedBox(height: 20),
                Text(
                  '$streak-Day Writing Streak!',
                  style: DesignTypography.heading(
                    context,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  encouragement,
                  style: DesignTypography.body(
                    context,
                    fontSize: 14,
                    color: DesignColors.textSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Stats breakdown cards
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: DesignColors.surfaceVariant(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: DesignColors.border(context)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$streak Days',
                              style: DesignTypography.heading(
                                context,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Active Streak',
                              style: DesignTypography.details(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: DesignColors.surfaceVariant(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: DesignColors.border(context)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$totalCount',
                              style: DesignTypography.heading(
                                context,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total Entries',
                              style: DesignTypography.details(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                DesignPrimaryButton(
                  label: 'Keep it going!',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
