import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/utils.dart';
import '../utils/editor_helpers.dart';
import '../../../notes/data/note_repository.dart';
import '../../../notes/data/note_model.dart';

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
          _error = 'Conflict note not found.';
          _isLoading = false;
        });
        return;
      }

      if (!conflict.isConflicted || conflict.originalNoteId == null) {
        setState(() {
          _error = 'This note is not marked as conflicted.';
          _isLoading = false;
        });
        return;
      }

      // Fetch original note
      final original = await repo.getNoteById(conflict.originalNoteId!);
      if (original == null) {
        setState(() {
          _error = 'Original note was deleted or not found.';
          _isLoading = false;
        });
        return;
      }

      // Read contents from files
      String conflictText = '';
      final conflictFile = File(conflict.filePath);
      if (conflictFile.existsSync()) {
        conflictText = await conflictFile.readAsString();
      }

      String originalText = '';
      final originalFile = File(original.filePath);
      if (originalFile.existsSync()) {
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
        _error = 'Failed to load note contents: $e';
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
              'Conflicted copy discarded. Keeping original note.',
              style: GoogleFonts.inter(),
            ),
          ),
        );
        context.go('/notes');
      }
    } catch (e) {
      setState(() {
        _error = 'Error discarding conflicted copy: $e';
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
              'Original note replaced with conflicted copy contents.',
              style: GoogleFonts.inter(),
            ),
          ),
        );
        context.go('/editor/${_originalNote!.id}');
      }
    } catch (e) {
      setState(() {
        _error = 'Error resolving conflict: $e';
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
              'Notes merged with Git conflict markers. Please resolve manually.',
              style: GoogleFonts.inter(),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        context.go('/editor/${_originalNote!.id}?new=true'); // auto-focuses
      }
    } catch (e) {
      setState(() {
        _error = 'Error merging notes: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? MeridianColors.darkBackground : MeridianColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Compare & Resolve',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        bottom: _isLoading || _error.isNotEmpty
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: colorScheme.primary,
                labelColor: colorScheme.primary,
                unselectedLabelColor: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
                tabs: const [
                  Tab(text: 'Original Note'),
                  Tab(text: 'Conflicted Copy'),
                ],
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? _buildErrorState(isDark)
              : _buildCompareBody(isDark, colorScheme),
    );
  }

  Widget _buildCompareBody(bool isDark, ColorScheme colorScheme) {
    return Column(
      children: [
        // Tab views showing scrollable markdown previews of the notes
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMarkdownPreview(_originalContent, isDark, colorScheme, 'Original Note'),
              _buildMarkdownPreview(_conflictContent, isDark, colorScheme, 'Conflicted Copy'),
            ],
          ),
        ),

        // Action Buttons Panel
        _buildActionPanel(isDark, colorScheme),
      ],
    );
  }

  Widget _buildMarkdownPreview(String content, bool isDark, ColorScheme colorScheme, String title) {
    if (content.trim().isEmpty) {
      return Center(
        child: Text(
          'Note is empty.',
          style: GoogleFonts.inter(
            color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
          ),
        ),
      );
    }

    final processedData = processWikilinks(content);
    return Markdown(
      data: processedData,
      onTapLink: (text, href, title) => handleWikilinkTap(
        href: href,
        ref: ref,
        context: context,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      styleSheet: MarkdownStyleSheet(
        h1: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
        ),
        h2: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
        ),
        p: GoogleFonts.inter(
          fontSize: 15,
          height: 1.7,
          color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
        ),
        code: GoogleFonts.robotoMono(
          fontSize: 13,
          color: isDark ? MeridianColors.darkAccentGreen : MeridianColors.lightAccentGreen,
          backgroundColor: isDark ? MeridianColors.darkSurfaceVariant : MeridianColors.lightSurfaceVariant,
        ),
        a: GoogleFonts.inter(
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionPanel(bool isDark, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? MeridianColors.darkSurface : MeridianColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? MeridianColors.darkBorder : MeridianColors.lightBorder,
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
              'How would you like to resolve this conflict?',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
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
                      'Keep Original',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
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
                      'Keep Conflicted',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
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
                'Merge Both Copies',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Resolution Error',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              style: GoogleFonts.inter(color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/notes'),
              child: const Text('Back to Notes'),
            ),
          ],
        ),
      ),
    );
  }
}
