import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../core/utils/utils.dart';
import '../utils/editor_helpers.dart';
import '../../../notes/data/note_repository.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../../../notes/data/note_model.dart';
import '../widgets/wikilink_autocomplete.dart';
import '../widgets/backlinks_panel.dart';
import '../../../folders/presentation/widgets/folder_assign_dialog.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

enum EditorMode { write, preview }

final editorModeProvider = StateProvider<EditorMode>((_) => EditorMode.write);

class EditorScreen extends ConsumerStatefulWidget {
  final String noteId;
  final bool isNew;
  final String? dailyDate;

  const EditorScreen({
    super.key,
    required this.noteId,
    this.isNew = false,
    this.dailyDate,
  });

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  Timer? _saveTimer;
  bool _isSaving = false;
  bool _isLoaded = false;
  String _lastSaved = '';

  // Wikilink autocomplete state
  bool _showWikilinkPopup = false;
  String _wikilinkQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNote();
    _controller.addListener(_onTextChanged);

    // Set mode: Edit mode for new notes, View mode for existing notes
    Future.microtask(() {
      if (mounted) {
        ref.read(editorModeProvider.notifier).state =
            widget.isNew ? EditorMode.write : EditorMode.preview;
      }
    });
  }

  Future<void> _loadNote() async {
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.getNoteById(widget.noteId);
    if (note == null) return;

    String content = '';
    final file = File(note.filePath);
    if (await file.exists()) {
      content = await file.readAsString();
    } else {
      content = '# ${note.title}\n\n';
    }

    if (mounted) {
      _controller.text = content;
      _lastSaved = content;
      setState(() => _isLoaded = true);

      // Auto-focus when new
      if (widget.isNew) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _focusNode.requestFocus();
          // Position cursor at end
          _controller.selection = TextSelection.collapsed(offset: content.length);
        });
      }
    }
  }

  void _onTextChanged() {
    final text = _controller.text;

    // Wikilink detection
    _detectWikilink(text);

    // Debounced save (500ms after last keystroke)
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () => _save());
  }

  void _detectWikilink(String text) {
    final selection = _controller.selection;
    if (!selection.isValid) return;

    final cursor = selection.baseOffset;
    if (cursor <= 0) return;

    final before = text.substring(0, cursor);
    final openBracket = before.lastIndexOf('[[');

    if (openBracket != -1 && !before.substring(openBracket).contains(']]')) {
      final query = before.substring(openBracket + 2);
      if (query.isNotEmpty) {
        setState(() {
          _showWikilinkPopup = true;
          _wikilinkQuery = query;
        });
        return;
      }
    }

    if (_showWikilinkPopup) {
      setState(() => _showWikilinkPopup = false);
    }
  }

  Future<void> _save() async {
    final content = _controller.text;
    if (content == _lastSaved) return;
    setState(() => _isSaving = true);
    await ref.read(noteRepositoryProvider).saveNote(widget.noteId, content);
    _lastSaved = content;
    if (mounted) setState(() => _isSaving = false);
  }

  void _insertWikilink(String noteTitle) {
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;
    final before = text.substring(0, cursor);
    final openBracket = before.lastIndexOf('[[');

    if (openBracket != -1) {
      final after = text.substring(cursor);
      final newText =
          '${text.substring(0, openBracket)}[[$noteTitle]]$after';
      final newCursor = openBracket + noteTitle.length + 4;
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursor),
      );
    }
    setState(() => _showWikilinkPopup = false);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _save(); // final save on close
    
    // Reset editor mode to View mode when exiting
    ref.read(editorModeProvider.notifier).state = EditorMode.preview;

    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final mode = ref.watch(editorModeProvider);
    final noteAsync = ref.watch(noteByIdProvider(widget.noteId));
    final note = noteAsync.valueOrNull;
    final isConflicted = note?.isConflicted ?? false;

    // Watch and retrieve custom settings
    final fontFamily = ref.watch(fontFamilyProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final lineWidth = ref.watch(lineWidthProvider);

    final sizeVal = double.tryParse(fontSize.replaceAll('pt', '')) ?? 16.0;
    final paddingVal = switch (lineWidth) {
      'Narrow' => 48.0,
      'Wide' => 8.0,
      'Comfortable' => 20.0,
      _ => 20.0,
    };

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      appBar: _buildAppBar(colorScheme, mode, noteAsync),
      body: Stack(
        children: [
          if (!_isLoaded)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                if (isConflicted) _buildConflictBanner(context, colorScheme, isDark),
                Expanded(
                  child: mode == EditorMode.write
                      ? _buildWriteMode(isDark, colorScheme, fontFamily, sizeVal, paddingVal)
                      : _buildPreviewMode(isDark, colorScheme, fontFamily, sizeVal, paddingVal),
                ),
                // Backlinks panel
                BacklinksPanel(noteId: widget.noteId),
              ],
            ),

          // Wikilink autocomplete floating popup
          if (_showWikilinkPopup)
            WikilinkAutocomplete(
              query: _wikilinkQuery,
              onSelect: _insertWikilink,
              onDismiss: () => setState(() => _showWikilinkPopup = false),
            ),
        ],
      ),
    );
  }

  Widget _buildConflictBanner(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: isDark ? 0.15 : 0.08),
        border: Border(
          bottom: BorderSide(
            color: Colors.orange.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(DesignIcons.warning, color: isDark ? Colors.orange[300] : Colors.orange[800], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Conflicted Copy: Review and resolve changes.',
              style: DesignTypography.heading(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.orange[200] : Colors.orange[900],
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/editor/${widget.noteId}/merge'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: isDark ? Colors.orange[800]!.withValues(alpha: 0.3) : Colors.orange[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Resolve',
                  style: DesignTypography.heading(
                    context,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.orange[200] : Colors.orange[900],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(DesignIcons.chevronRight, size: 14, color: isDark ? Colors.orange[200] : Colors.orange[900]),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  PreferredSizeWidget _buildAppBar(
    ColorScheme colorScheme,
    EditorMode mode,
    AsyncValue<Note?> noteAsync,
  ) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(DesignIcons.back),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      backgroundColor: DesignColors.background(context),
      title: Row(
        children: [
          Expanded(
            child: noteAsync.when(
              data: (note) => Text(
                note?.title ?? '',
                style: DesignTypography.heading(
                  context,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      actions: [
        // Save indicator
        AnimatedOpacity(
          opacity: _isSaving ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Saving',
                  style: DesignTypography.metadata(
                    context,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Organize note folder assignment button
        IconButton(
          icon: const Icon(DesignIcons.folderOpen, size: 20),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => FolderAssignDialog(noteId: widget.noteId),
            );
          },
          tooltip: 'Organize into folders',
        ),
        // Toggle write/preview
        IconButton(
          icon: Icon(
            mode == EditorMode.write ? DesignIcons.preview : DesignIcons.edit,
            size: 20,
          ),
          onPressed: () => ref.read(editorModeProvider.notifier).state =
              mode == EditorMode.write ? EditorMode.preview : EditorMode.write,
          tooltip: mode == EditorMode.write ? 'Preview' : 'Edit',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildWriteMode(bool isDark, ColorScheme colorScheme, String family, double size, double paddingHorizontal) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        scrollController: _scrollController,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        style: _getFont(
          family,
          fontSize: size,
          height: 1.7,
          color: DesignColors.text(context),
        ),
        decoration: InputDecoration(
          hintText: 'Start writing… use # for headings, [[note]] for links, #tag for tags',
          hintStyle: _getFont(
            family,
            fontSize: size - 1.0,
            color: DesignColors.textTertiary(context),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 12, bottom: 100),
          fillColor: Colors.transparent,
          filled: true,
        ),
      ),
    );
  }

  Widget _buildPreviewMode(bool isDark, ColorScheme colorScheme, String family, double size, double paddingHorizontal) {
    final processedData = processWikilinks(_controller.text);
    return Markdown(
      controller: _scrollController,
      data: processedData,
      onTapLink: (text, href, title) => handleWikilinkTap(
        href: href,
        ref: ref,
        context: context,
      ),
      padding: EdgeInsets.fromLTRB(paddingHorizontal, 12, paddingHorizontal, 100),
      styleSheet: MarkdownStyleSheet(
        h1: _getFont(
          family,
          fontSize: size * 1.625,
          fontWeight: FontWeight.w700,
          color: DesignColors.text(context),
        ),
        h2: _getFont(
          family,
          fontSize: size * 1.25,
          fontWeight: FontWeight.w600,
          color: DesignColors.text(context),
        ),
        h3: _getFont(
          family,
          fontSize: size * 1.0625,
          fontWeight: FontWeight.w600,
          color: DesignColors.text(context),
        ),
        p: _getFont(
          family,
          fontSize: size,
          height: 1.7,
          color: DesignColors.text(context),
        ),
        code: GoogleFonts.robotoMono(
          fontSize: size * 0.8125,
          color: DesignColors.accentGreen(context),
          backgroundColor: DesignColors.surfaceVariant(context),
        ),
        a: _getFont(
          family,
          fontSize: size,
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w600,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: colorScheme.primary,
              width: 3,
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _getFont(String family, {double? fontSize, double? height, Color? color, FontWeight? fontWeight, TextDecoration? decoration}) {
    switch (family) {
      case 'Roboto Mono (Mono)':
        return GoogleFonts.robotoMono(fontSize: fontSize, height: height, color: color, fontWeight: fontWeight, decoration: decoration);
      case 'Lora (Serif)':
        return GoogleFonts.lora(fontSize: fontSize, height: height, color: color, fontWeight: fontWeight, decoration: decoration);
      case 'Merriweather (Serif)':
        return GoogleFonts.merriweather(fontSize: fontSize, height: height, color: color, fontWeight: fontWeight, decoration: decoration);
      case 'Inter (Sans)':
      default:
        return GoogleFonts.inter(fontSize: fontSize, height: height, color: color, fontWeight: fontWeight, decoration: decoration);
    }
  }
}
