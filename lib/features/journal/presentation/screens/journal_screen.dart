import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/utils.dart';
import '../../../notes/data/note_repository.dart';
import '../../../notes/data/note_model.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final selectedDay = ref.watch(_selectedDayProvider);

    return Scaffold(
      backgroundColor: isDark ? MeridianColors.darkBackground : MeridianColors.lightBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark, colorScheme, selectedDay),
            if (_showCalendar) _buildCalendar(isDark, colorScheme, selectedDay),
            Expanded(child: _buildJournalContent(isDark, colorScheme, selectedDay)),
          ],
        ),
      ),
      floatingActionButton: _buildTodayFAB(context, isDark, colorScheme),
    );
  }

  Widget _buildHeader(bool isDark, ColorScheme colorScheme, DateTime selectedDay) {
    final isToday_ = isToday(formatDailyDate(selectedDay));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Journal',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                isToday_ ? 'Today' : DateFormat('EEEE, MMMM d').format(selectedDay),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
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
                    : (isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary),
              ),
            ),
            onPressed: () => setState(() => _showCalendar = !_showCalendar),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(bool isDark, ColorScheme colorScheme, DateTime selectedDay) {
    return TableCalendar(
      firstDay: DateTime(2020),
      lastDay: DateTime(2030),
      focusedDay: selectedDay,
      selectedDayPredicate: (day) => isSameDay(day, selectedDay),
      calendarFormat: CalendarFormat.month,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
        ),
        leftChevronIcon: Icon(
          Icons.chevron_left_rounded,
          color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right_rounded,
          color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
        ),
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        todayTextStyle: GoogleFonts.inter(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        selectedDecoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: GoogleFonts.inter(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
        defaultTextStyle: GoogleFonts.inter(
          color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
        ),
        weekendTextStyle: GoogleFonts.inter(
          color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
        ),
        outsideTextStyle: GoogleFonts.inter(
          color: isDark ? MeridianColors.darkTextTertiary : MeridianColors.lightTextTertiary,
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
        ),
        weekendStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? MeridianColors.darkTextTertiary : MeridianColors.lightTextTertiary,
        ),
      ),
      onDaySelected: (selected, focused) {
        ref.read(_selectedDayProvider.notifier).state = selected;
      },
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05);
  }

  Widget _buildJournalContent(bool isDark, ColorScheme colorScheme, DateTime selectedDay) {
    final dateStr = formatDailyDate(selectedDay);
    final dailyNoteAsync = ref.watch(
      FutureProvider.autoDispose(
        (ref) => ref.read(noteRepositoryProvider).getDailyNote(dateStr),
      ).future,
    );

    return FutureBuilder<Note?>(
      future: dailyNoteAsync,
      builder: (context, snapshot) {
        final note = snapshot.data;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              // Templates row
              _buildTemplatesRow(isDark, colorScheme),
              const SizedBox(height: 16),
              // Entry state
              Expanded(
                child: note != null
                    ? _buildExistingEntry(context, isDark, colorScheme, note)
                    : _buildEmptyDay(context, isDark, colorScheme, dateStr),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplatesRow(bool isDark, ColorScheme colorScheme) {
    final templates = [
      const _TemplateItem(
        icon: Icons.favorite_rounded,
        label: 'Gratitude',
        emoji: '🙏',
        baseColor: MeridianColors.darkAccentRose,
      ),
      const _TemplateItem(
        icon: Icons.checklist_rounded,
        label: 'Daily Plan',
        emoji: '📋',
        baseColor: MeridianColors.darkAccentGreen,
      ),
      const _TemplateItem(
        icon: Icons.self_improvement_rounded,
        label: 'Reflection',
        emoji: '💭',
        baseColor: MeridianColors.darkAccentAmber,
      ),
      const _TemplateItem(
        icon: Icons.track_changes_rounded,
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
              child: _JournalTemplateButton(
                template: t,
                isDark: isDark,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExistingEntry(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    Note note,
  ) {
    return GestureDetector(
      onTap: () => context.push('/editor/${note.id}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? MeridianColors.darkSurface : MeridianColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
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
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${note.wordCount} words',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? MeridianColors.darkTextTertiary : MeridianColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Tap to continue writing…',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.97, 0.97));
  }

  Widget _buildEmptyDay(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    String dateStr,
  ) {
    final isFuture = DateTime.parse(dateStr).isAfter(DateTime.now());
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EmptyStateIllustration(
            isFuture: isFuture,
            colorScheme: colorScheme,
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          Text(
            isFuture ? 'A future day' : 'No entry yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFuture
                ? 'Come back on this day to start writing'
                : 'Tap the button below to start your entry',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isFuture) ...[
            const SizedBox(height: 24),
            TactileWrapper(
              style: TactileFeedbackStyle.highImpact,
              onTap: () => _createDailyNote(context, dateStr, null),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
                label: Text('Start Writing', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildTodayFAB(BuildContext context, bool isDark, ColorScheme colorScheme) {
    final isToday_ = isToday(formatDailyDate(ref.watch(_selectedDayProvider)));
    if (!isToday_) return const SizedBox.shrink();

    return TactileWrapper(
      style: TactileFeedbackStyle.highImpact,
      onTap: () => _openOrCreateToday(context),
      child: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.edit_rounded),
        label: Text("Today's Entry", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
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

// ─── Beautiful Premium Icons & Animations for Emojis ──────────────────────────

class _TemplateItem {
  final IconData icon;
  final String label;
  final String emoji;
  final Color baseColor;

  const _TemplateItem({
    required this.icon,
    required this.label,
    required this.emoji,
    required this.baseColor,
  });
}

// Removed redundant _InteractiveJournalButton class in favor of reusable TactileWrapper

class _JournalTemplateButton extends StatelessWidget {
  final _TemplateItem template;
  final bool isDark;

  const _JournalTemplateButton({
    required this.template,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final baseBgColor = isDark ? MeridianColors.darkSurface : MeridianColors.lightSurface;
    final baseBorderColor = isDark ? MeridianColors.darkBorder : MeridianColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: baseBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: baseBorderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: template.baseColor.withValues(alpha: isDark ? 0.04 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: template.baseColor.withValues(alpha: isDark ? 0.15 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              template.icon,
              size: 13,
              color: template.baseColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            template.label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateIllustration extends StatelessWidget {
  final bool isFuture;
  final ColorScheme colorScheme;
  final bool isDark;

  const _EmptyStateIllustration({
    required this.isFuture,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = colorScheme.primary;
    final accentColor = isDark ? MeridianColors.darkAccentAmber : MeridianColors.lightAccentAmber;

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft glowing circle (Static, premium glow)
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  baseColor.withValues(alpha: 0.12),
                  baseColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),

          // Secondary floating decorative ring (Static, elegant border)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withValues(alpha: isDark ? 0.15 : 0.25),
                width: 1.2,
              ),
            ),
          ),

          // Central decorative container
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? MeridianColors.darkSurface : MeridianColors.lightSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? MeridianColors.darkBorder : MeridianColors.lightBorder,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: baseColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isFuture ? Icons.calendar_month_rounded : Icons.edit_note_rounded,
              size: 30,
              color: baseColor,
            ),
          ).animate()
            .fadeIn(duration: 400.ms)
            .slideY(
              begin: 0.1,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeOutBack,
            ),
        ],
      ),
    );
  }
}
