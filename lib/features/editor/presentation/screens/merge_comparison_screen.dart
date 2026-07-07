import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../core/utils/utils.dart';
import '../utils/editor_helpers.dart';
import '../../../notes/data/note_repository.dart';
import '../../../notes/data/note_model.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import 'package:prism/l10n/l10n.dart';

class MergeComparisonScreen extends ConsumerStatefulWidget {
  final String noteId;

  const MergeComparisonScreen({super.key, required this.noteId});

  @override
  ConsumerState<MergeComparisonScreen> createState() => _MergeComparisonScreenState();
}

class _MergeComparisonScreenState extends ConsumerState<MergeComparisonScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _error = '';

  Note? _conflictNote;
  Note? _originalNote;
  String _conflictContent = '';
  String _originalContent = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContents() async {
    try {
      final repo = ref.read(noteRepositoryProvider);
      
      // Fetch conflict copy note
      final conflict = await repo.getNoteById(widget.noteId);
      if (conflict == null) {
        setState(() {
          _error = context.l10n.editor_merge_comparison_note_not_found;
          _isLoading = false;
        });
        return;
      }

      if (!conflict.isConflicted || conflict.originalNoteId == null) {
        setState(() {
          _error = context.l10n.editor_merge_comparison_not_conflicted;
          _isLoading = false;
        });
        return;
      }

      // Fetch original note
      final original = await repo.getNoteById(conflict.originalNoteId!);
      if (original == null) {
        setState(() {
          _error = context.l10n.editor_merge_comparison_original_deleted;
          _isLoading = false;
        });
        return;
      }

      // Read contents from files asynchronously
      String conflictText = '';
      final conflictFile = File(conflict.filePath);
      if (await conflictFile.exists()) {
        conflictText = await conflictFile.readAsString();
      }

      String originalText = '';
      final originalFile = File(original.filePath);
      if (await originalFile.exists()) {
        originalText = await originalFile.readAsString();
      }

      setState(() {
        _conflictNote = conflict;
        _originalNote = original;
        _conflictContent = conflictText;
        _originalContent = originalText;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = context.l10n.editor_merge_comparison_failed_load(e.toString());
        _isLoading = false;
      });
    }
  }

  // Action 1: Discard conflicted copy, keep original
  Future<void> _keepOriginal() async {
    if (_conflictNote == null) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(noteRepositoryProvider);
      await repo.deleteNote(_conflictNote!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.editor_merge_comparison_discarded_success,
              style: GoogleFonts.inter(),
            ),
          ),
        );
        context.go('/notes');
      }
    } catch (e) {
      setState(() {
        _error = context.l10n.editor_merge_comparison_discard_error(e.toString());
        _isLoading = false;
      });
    }
  }

  // Action 2: Overwrite original with conflicted copy
  Future<void> _keepConflicted() async {
    if (_conflictNote == null || _originalNote == null) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(noteRepositoryProvider);
      
      // Save original note with conflicted copy's content
      await repo.saveNote(_originalNote!.id, _conflictContent);

      // Delete conflict copy
      await repo.deleteNote(_conflictNote!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.editor_merge_comparison_replaced_success,
              style: GoogleFonts.inter(),
            ),
          ),
        );
        context.go('/editor/${_originalNote!.id}');
      }
    } catch (e) {
      setState(() {
        _error = context.l10n.editor_merge_comparison_replace_error(e.toString());
        _isLoading = false;
      });
    }
  }

  // Action 3: Merge both using Git-style conflict markers
  Future<void> _mergeBoth() async {
    if (_conflictNote == null || _originalNote == null) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(noteRepositoryProvider);

      final mergedContent = '''# Conflict Resolved: ${_originalNote!.title}

<<<<<<< ORIGINAL COPY
$_originalContent
=======
$_conflictContent
>>>>>>> CONFLICTED COPY
''';

      // Save original note with merged content
      await repo.saveNote(_originalNote!.id, mergedContent);

      // Delete conflict copy
      await repo.deleteNote(_conflictNote!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.editor_merge_comparison_merged_markers,
              style: GoogleFonts.inter(),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        context.go('/editor/${_originalNote!.id}?new=true'); // auto-focuses
      }
    } catch (e) {
      setState(() {
        _error = context.l10n.editor_merge_comparison_merge_error(e.toString());
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fontFamily = ref.watch(fontFamilyProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final sizeVal = double.tryParse(fontSize.replaceAll('pt', '')) ?? 16.0;

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      appBar: AppBar(
        title: Text(
          context.l10n.editor_merge_comparison_compare_resolve,
          style: getEditorFont(
            fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: DesignColors.text(context),
          ),
        ),
        bottom: _isLoading || _error.isNotEmpty
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: colorScheme.primary,
                labelColor: colorScheme.primary,
                unselectedLabelColor: DesignColors.textSecondary(context),
                tabs: [
                  Tab(text: context.l10n.editor_merge_comparison_tab_original),
                  Tab(text: context.l10n.editor_merge_comparison_tab_conflict),
                ],
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading'))
          : _error.isNotEmpty
              ? _buildErrorState(fontFamily)
              : _buildCompareBody(colorScheme, fontFamily, sizeVal),
    );
  }

  Widget _buildCompareBody(ColorScheme colorScheme, String fontFamily, double sizeVal) {
    return Column(
      children: [
        // Tab views showing scrollable markdown previews of the notes
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMarkdownPreview(_originalContent, colorScheme, context.l10n.editor_merge_comparison_tab_original, fontFamily, sizeVal),
              _buildMarkdownPreview(_conflictContent, colorScheme, context.l10n.editor_merge_comparison_tab_conflict, fontFamily, sizeVal),
            ],
          ),
        ),

        // Action Buttons Panel
        _buildActionPanel(colorScheme, fontFamily),
      ],
    );
  }

  Widget _buildMarkdownPreview(String content, ColorScheme colorScheme, String title, String family, double size) {
    if (content.trim().isEmpty) {
      return Center(
        child: Text(
          context.l10n.editor_merge_comparison_empty_note,
          style: getEditorFont(
            family,
            fontSize: size,
            color: DesignColors.textSecondary(context),
          ),
        ),
      );
    }

    final processedData = preprocessMarkdown(content);
    return Markdown(
      data: processedData,
      softLineBreak: true,
      inlineSyntaxes: [HighlightSyntax(), HashtagSyntax()],
      builders: {
        'mark': HighlightElementBuilder(context),
        'hashtag': HashtagElementBuilder(context),
      },
      onTapLink: (text, href, title) => handleMarkdownLinkTap(
        href: href,
        ref: ref,
        context: context,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      styleSheet: buildMarkdownStyleSheet(context, family, size, colorScheme),
    );
  }

  Widget _buildActionPanel(ColorScheme colorScheme, String fontFamily) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignColors.surface(context),
        border: Border(
          top: BorderSide(
            color: DesignColors.border(context),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.editor_merge_comparison_how_to_resolve,
              style: getEditorFont(
                fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: DesignColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Side-by-side or stacked grid of options
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _keepOriginal,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.outline),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      context.l10n.editor_merge_comparison_keep_original,
                      style: getEditorFont(
                        fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _keepConflicted,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.outline),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      context.l10n.editor_merge_comparison_keep_conflicted,
                      style: getEditorFont(
                        fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Primary Merge Action
            ElevatedButton(
              onPressed: _mergeBoth,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 2,
              ),
              child: Text(
                context.l10n.editor_merge_comparison_merge_both,
                style: getEditorFont(
                  fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String fontFamily) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              context.l10n.editor_merge_comparison_resolution_error,
              style: getEditorFont(
                fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: DesignColors.text(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              style: getEditorFont(
                fontFamily,
                color: DesignColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/notes'),
              child: Text(context.l10n.editor_merge_comparison_back_to_notes),
            ),
          ],
        ),
      ),
    );
  }
}