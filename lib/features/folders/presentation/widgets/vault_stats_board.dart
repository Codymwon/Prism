import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../notes/presentation/providers/notes_providers.dart';

class VaultStatsBoard extends ConsumerWidget {
  const VaultStatsBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(vaultStatsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(
            'VAULT STATISTICS',
            style: DesignTypography.metadata(
              context,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: DesignColors.textTertiary(context),
            ).copyWith(letterSpacing: 1.0),
          ),
        ),
        statsAsync.maybeWhen(
          data: (stats) => _buildStatsContent(context, colorScheme, stats),
          orElse: () {
            if (statsAsync.hasValue) {
              return _buildStatsContent(context, colorScheme, statsAsync.value!);
            }
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Error loading stats: $err',
              style: TextStyle(color: colorScheme.error, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsContent(
    BuildContext context,
    ColorScheme colorScheme,
    ({int totalNotes, int totalWords, int totalLinks}) stats,
  ) {
    final items = [
      (stats.totalNotes, 'Notes Created', Icons.article_outlined),
      (stats.totalWords, 'Words Written', Icons.edit_note_rounded),
      (stats.totalLinks, 'Backlinks Formed', Icons.hub_outlined),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DesignColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignColors.border(context),
          width: 0.5,
        ),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.value;
          final isLast = entry.key == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(i.$3, size: 14, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      i.$2,
                      style: DesignTypography.body(
                        context,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: DesignColors.textSecondary(context),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${i.$1}',
                      style: DesignTypography.mono(
                        fontSize: 12,
                        color: DesignColors.text(context),
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 12,
                  color: DesignColors.border(context).withValues(alpha: 0.5),
                  indent: 32,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
