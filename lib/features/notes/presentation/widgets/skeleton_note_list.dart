import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';

class SkeletonNoteList extends StatelessWidget {
  const SkeletonNoteList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(DesignSpacing.screenPadding, 8, DesignSpacing.screenPadding, 100),
      itemCount: 6,
      itemBuilder: (context, i) => const SkeletonNoteCard(),
    );
  }
}

class SkeletonNoteCard extends StatelessWidget {
  const SkeletonNoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = DesignColors.surfaceVariant(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(DesignSpacing.cardPadding),
      decoration: BoxDecoration(
        color: DesignColors.surface(context),
        borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
        border: Border.all(
          color: DesignColors.border(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 14, width: 160, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 8),
          Container(height: 10, width: double.infinity, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 5),
          Container(height: 10, width: 220, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4))),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: bg.withValues(alpha: 0.5));
  }
}
