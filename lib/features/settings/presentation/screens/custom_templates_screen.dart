import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../core/services/template_service.dart';
import '../../../../core/utils/utils.dart' as utils;
import '../../../subscription/presentation/providers/subscription_providers.dart';

final templatesListProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  ref.watch(templatesVersionProvider);
  final service = ref.watch(templateServiceProvider);
  final result = await service.listTemplates();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (list) => list,
  );
});

class CustomTemplatesScreen extends ConsumerStatefulWidget {
  const CustomTemplatesScreen({super.key});

  @override
  ConsumerState<CustomTemplatesScreen> createState() => _CustomTemplatesScreenState();
}

class _CustomTemplatesScreenState extends ConsumerState<CustomTemplatesScreen> {
  @override
  void initState() {
    super.initState();
    // Defense-in-depth runtime guard: redirect to paywall if not Pro
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final status = await ref.read(subscriptionStatusProvider.future);
      if (!mounted) return;
      if (!status.isPro) {
        context.go('/settings/paywall');
      }
    });
  }

  String _formatDisplayName(String slug) {
    if (slug.isEmpty) return '';
    return slug
        .split('-')
        .map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final templatesAsync = ref.watch(templatesListProvider);

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      appBar: AppBar(
        backgroundColor: DesignColors.background(context),
        leading: IconButton(
          icon: const Icon(DesignIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Custom Templates',
          style: DesignTypography.heading(
            context,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(DesignIcons.add),
            tooltip: 'Create Template',
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: templatesAsync.when(
          data: (templates) {
            if (templates.isEmpty) {
              return _buildEmptyState(context);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DesignColors.surfaceVariant(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: DesignColors.border(context)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.note_add_rounded,
                          color: DesignColors.primary(context),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Template Manager',
                                style: DesignTypography.body(
                                  context,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Manage reusable page templates for note creation.',
                                style: DesignTypography.details(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                  child: Text(
                    'TEMPLATES',
                    style: DesignTypography.metadata(
                      context,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: DesignColors.textTertiary(context),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 80),
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final slug = templates[index];
                      final displayName = _formatDisplayName(slug);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildTemplateCard(context, slug, displayName),
                      ).animate(delay: (30 * index).ms).fadeIn(duration: 250.ms).slideY(begin: 0.05);
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Error loading templates: $e',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DesignColors.primary(context),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () => _showCreateDialog(context),
        child: const Icon(DesignIcons.add),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, String slug, String displayName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DesignColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: DesignColors.surfaceVariant(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 18,
              color: DesignColors.textSecondary(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: DesignTypography.body(
                    context,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'template:$slug',
                  style: DesignTypography.details(context),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () {
              context.push('/editor/template:$slug?new=false');
            },
            tooltip: 'Edit Template Content',
            color: DesignColors.primary(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            onPressed: () => _confirmDelete(context, slug, displayName),
            tooltip: 'Delete Template',
            color: Colors.redAccent.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DesignColors.surfaceVariant(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.note_add_outlined,
                size: 40,
                color: DesignColors.textTertiary(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Custom Templates',
              style: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Create reusable note structures for your journals and workspaces.',
              style: DesignTypography.details(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignColors.background(context),
        title: Text(
          'Create Template',
          style: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a name for the new template:',
              style: DesignTypography.body(context, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Weekly Review',
                hintStyle: TextStyle(color: DesignColors.textTertiary(context)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: DesignColors.primary(context)),
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: DesignColors.border(context)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: DesignTypography.body(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: DesignTypography.body(context)),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);

              final slug = utils.titleToSlug(name);
              final content = '---\ntitle: "$name"\n---\n\n';

              final result = await ref.read(templateServiceProvider).writeTemplate(name, content);
              result.fold(
                (failure) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create template: ${failure.message}')),
                    );
                  }
                },
                (_) {
                  ref.invalidate(templatesListProvider);
                  if (context.mounted) {
                    context.push('/editor/template:$slug?new=true');
                  }
                },
              );
            },
            child: Text(
              'Create',
              style: DesignTypography.body(context, color: DesignColors.primary(context), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String slug, String displayName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignColors.background(context),
        title: Text(
          'Delete Template',
          style: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to permanently delete the template "$displayName"? This action cannot be undone.',
          style: DesignTypography.body(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: DesignTypography.body(context)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await ref.read(templateServiceProvider).deleteTemplate(slug);
              result.fold(
                (failure) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete template: ${failure.message}')),
                    );
                  }
                },
                (_) {
                  ref.invalidate(templatesListProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Template deleted.')),
                    );
                  }
                },
              );
            },
            child: Text(
              'Delete',
              style: DesignTypography.body(context, color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
