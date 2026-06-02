import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as p;
import 'package:audioplayers/audioplayers.dart';
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
import '../../../settings/presentation/providers/custom_macro_provider.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';


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
  final ValueNotifier<bool> _isSavingNotifier = ValueNotifier<bool>(false);
  bool _isLoaded = false;
  String _lastSaved = '';

  // Wikilink autocomplete state
  bool _showWikilinkPopup = false;
  String _wikilinkQuery = '';

  // Dictation & Audio State
  final SpeechToText _speechToText = SpeechToText();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isDictating = false;
  bool _speechInitialized = false;
  int _dictationStartOffset = 0;
  String _dictationPreSpeechText = '';
  String _dictationAudioPath = '';
  String _currentWords = '';
  String _dictationSessionId = '';

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
    _isSavingNotifier.value = true;
    await ref.read(noteRepositoryProvider).saveNote(widget.noteId, content);
    _lastSaved = content;
    if (mounted) _isSavingNotifier.value = false;
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
    _isSavingNotifier.dispose();
    
    // Dispose dictation utilities
    _audioRecorder.dispose();
    
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

    // StateNotifier — watch synchronously
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
                      ? Column(
                          children: [
                            Expanded(
                              child: _buildWriteMode(isDark, colorScheme, fontFamily, sizeVal, paddingVal),
                            ),
                            _isDictating
                                ? _buildDictationOverlay(context, colorScheme)
                                : _buildFormattingToolbar(context, colorScheme),
                          ],
                        )
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
        ValueListenableBuilder<bool>(
          valueListenable: _isSavingNotifier,
          builder: (context, isSaving, _) {
            return AnimatedOpacity(
              opacity: isSaving ? 1 : 0,
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
            );
          },
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
      onTapLink: (text, href, title) async {
        if (href != null && (href.endsWith('.m4a') || href.endsWith('.mp3') || href.contains('attachments/'))) {
          try {
            final vaultPath = await getVaultPath();
            final fullPath = p.join(vaultPath, href);
            final file = File(fullPath);
            if (!mounted) return;
            if (await file.exists()) {
              if (!mounted) return;
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => _AudioPlayerBottomSheet(
                  filePath: fullPath,
                  fileName: p.basename(fullPath),
                ),
              );
            } else {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Audio file does not exist on disk.')),
              );
            }
          } catch (e) {
            debugPrint('Error opening audio player: $e');
          }
        } else {
          handleWikilinkTap(
            href: href,
            ref: ref,
            context: context,
          );
        }
      },
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
        h4: _getFont(
          family,
          fontSize: size * 0.95,
          fontWeight: FontWeight.w600,
          color: DesignColors.text(context),
        ),
        h5: _getFont(
          family,
          fontSize: size * 0.88,
          fontWeight: FontWeight.w600,
          color: DesignColors.text(context),
        ),
        h6: _getFont(
          family,
          fontSize: size * 0.81,
          fontWeight: FontWeight.w600,
          color: DesignColors.text(context),
        ),
        p: _getFont(
          family,
          fontSize: size,
          height: 1.7,
          color: DesignColors.text(context),
        ),
        strong: _getFont(
          family,
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: DesignColors.text(context),
        ),
        em: _getFont(
          family,
          fontSize: size,
          color: DesignColors.text(context),
        ).copyWith(fontStyle: FontStyle.italic),
        listBullet: _getFont(
          family,
          fontSize: size,
          color: DesignColors.text(context),
        ),
        blockquote: _getFont(
          family,
          fontSize: size,
          color: DesignColors.textSecondary(context),
        ),
        tableHead: _getFont(
          family,
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: DesignColors.text(context),
        ),
        tableBody: _getFont(
          family,
          fontSize: size,
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

  void _insertFormatting(String prefix, [String suffix = '']) {
    final text = _controller.text;
    final selection = _controller.selection;
    
    if (!selection.isValid) {
      final newText = text + prefix + suffix;
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length - suffix.length),
      );
      return;
    }
    
    final start = selection.start;
    final end = selection.end;
    final selectedText = text.substring(start, end);
    
    final newSelectedText = prefix + selectedText + suffix;
    final newText = text.replaceRange(start, end, newSelectedText);
    
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: start + prefix.length,
        extentOffset: start + prefix.length + selectedText.length,
      ),
    );
    
    _focusNode.requestFocus();
  }

  void _insertMacro(CustomMacro macro) {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final dateStr = '$year-$month-$day';

    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    final resolvedText = macro.text
        .replaceAll('{{date}}', dateStr)
        .replaceAll('{{time}}', timeStr)
        .replaceAll('{{datetime}}', '$dateStr $timeStr');

    _insertFormatting(resolvedText);
  }

  Widget _buildFormattingToolbar(BuildContext context, ColorScheme colorScheme) {
    final customMacros = ref.watch(customMacrosProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      height: 50,
      decoration: BoxDecoration(
        color: DesignColors.surfaceVariant(context).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: DesignColors.border(context), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            _buildFormattingButton(
              icon: Icons.format_bold_rounded,
              tooltip: 'Bold',
              onTap: () => _insertFormatting('**', '**'),
            ),
            _buildFormattingButton(
              icon: Icons.format_italic_rounded,
              tooltip: 'Italic',
              onTap: () => _insertFormatting('*', '*'),
            ),
            _buildFormattingButton(
              icon: Icons.format_size_rounded,
              tooltip: 'Heading',
              onTap: () => _insertFormatting('# '),
            ),
            _buildFormattingButton(
              icon: Icons.link_rounded,
              tooltip: 'Wikilink',
              onTap: () => _insertFormatting('[[', ']]'),
            ),
            _buildFormattingButton(
              icon: Icons.label_outline_rounded,
              tooltip: 'Tag',
              onTap: () => _insertFormatting('#'),
            ),
            _buildFormattingButton(
              icon: Icons.format_list_bulleted_rounded,
              tooltip: 'Bullet List',
              onTap: () => _insertFormatting('\n- '),
            ),
            _buildFormattingButton(
              icon: Icons.checklist_rounded,
              tooltip: 'Checklist',
              onTap: () => _insertFormatting('\n- [ ] '),
            ),
            _buildFormattingButton(
              icon: Icons.code_rounded,
              tooltip: 'Code',
              onTap: () => _insertFormatting('`', '`'),
            ),
            _buildFormattingButton(
              icon: Icons.format_quote_rounded,
              tooltip: 'Blockquote',
              onTap: () => _insertFormatting('\n> '),
            ),
            _buildFormattingButton(
              icon: Icons.strikethrough_s_rounded,
              tooltip: 'Strikethrough',
              onTap: () => _insertFormatting('~~', '~~'),
            ),
            _buildFormattingButton(
              icon: Icons.border_color_rounded,
              tooltip: 'Highlight',
              onTap: () => _insertFormatting('==', '=='),
            ),
            _buildFormattingButton(
              icon: Icons.horizontal_rule_rounded,
              tooltip: 'Divider',
              onTap: () => _insertFormatting('\n---\n'),
            ),
            if (Platform.isAndroid)
              _buildFormattingButton(
                icon: Icons.mic_none_rounded,
                tooltip: 'Dictate (Voice-to-Text)',
                onTap: () => _toggleDictation(),
              ),

            // Vertical Divider separating standard actions and custom macros
            if (customMacros.isNotEmpty) ...[
              Container(
                height: 22,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: DesignColors.border(context),
              ),
              ...customMacros.map((macro) {
                return _buildCustomMacroButton(
                  label: macro.label,
                  tooltip: 'Insert: ${macro.text.replaceAll('\n', ' ')}',
                  onTap: () => _insertMacro(macro),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormattingButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return TactileWrapper(
      style: TactileFeedbackStyle.standard,
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          height: 38,
          width: 38,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: DesignColors.textSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomMacroButton({
    required String label,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return TactileWrapper(
      style: TactileFeedbackStyle.standard,
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DesignColors.surface(context),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: DesignColors.border(context),
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: DesignTypography.body(
              context,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: DesignColors.textSecondary(context),
            ),
          ),
        ),
      ),
    );
  }

  // ── Dictation Actions & Overlay ──────────────────────────────────────────

  Future<void> _toggleDictation() async {
    if (_isDictating) {
      _stopDictation(commit: true);
      return;
    }

    try {
      if (!_speechInitialized) {
        bool available = await _speechToText.initialize(
          onStatus: (status) {
            if (status == 'notListening' && _isDictating) {
              if (_isDictating) {
                _startListening();
              }
            }
          },
          onError: (error) {
            debugPrint('Speech error: $error');
          },
        );
        if (!mounted) return;
        if (!available) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition is not available on this device.')),
          );
          return;
        }
        _speechInitialized = true;
      }

      final hasAudioPermission = await _audioRecorder.hasPermission();
      if (!mounted) return;
      if (hasAudioPermission) {
        _startListening();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required for dictation.')),
        );
      }
    } catch (e) {
      debugPrint('Error starting dictation: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start dictation: $e')),
      );
    }
  }

  void _startListening() async {
    final selection = _controller.selection;
    _dictationStartOffset = selection.isValid ? selection.baseOffset : _controller.text.length;
    _dictationPreSpeechText = _controller.text;
    _currentWords = '';

    setState(() {
      _isDictating = true;
    });

    final keepVoice = ref.read(keepVoiceRecordingsProvider).valueOrNull ?? true;
    if (keepVoice) {
      try {
        final vaultPath = await getVaultPath();
        final attachmentsDir = Directory(p.join(vaultPath, 'attachments'));
        if (!await attachmentsDir.exists()) {
          await attachmentsDir.create(recursive: true);
        }

        _dictationSessionId = generateId().substring(0, 8);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final audioPath = p.join(attachmentsDir.path, 'audio_${timestamp}_$_dictationSessionId.m4a');
        _dictationAudioPath = audioPath;

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: audioPath,
        );
      } catch (e) {
        debugPrint('Audio recording error: $e');
      }
    }

    await _speechToText.listen(
      onResult: (result) {
        if (!mounted || !_isDictating) return;

        final newWords = result.recognizedWords;
        _currentWords = newWords;

        final before = _dictationPreSpeechText.substring(0, _dictationStartOffset);
        final after = _dictationPreSpeechText.substring(_dictationStartOffset);

        _controller.value = TextEditingValue(
          text: before + newWords + after,
          selection: TextSelection.collapsed(offset: _dictationStartOffset + newWords.length),
        );
      },
      listenFor: const Duration(minutes: 10),
      pauseFor: const Duration(seconds: 15),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> _stopDictation({required bool commit}) async {
    if (!_isDictating) return;

    setState(() {
      _isDictating = false;
    });

    await _speechToText.stop();
    final audioPath = await _audioRecorder.stop();

    if (!commit) {
      _controller.value = TextEditingValue(
        text: _dictationPreSpeechText,
        selection: TextSelection.collapsed(offset: _dictationStartOffset),
      );

      if (_dictationAudioPath.isNotEmpty) {
        final file = File(_dictationAudioPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } else {
      final keepVoice = ref.read(keepVoiceRecordingsProvider).valueOrNull ?? true;
      if (keepVoice && audioPath != null && _dictationAudioPath.isNotEmpty) {
        final filename = p.basename(_dictationAudioPath);
        
        final text = _controller.text;
        final cursor = _controller.selection.baseOffset;
        final before = text.substring(0, cursor);
        final after = text.substring(cursor);

        final audioLink = '\n\n[Audio Note](attachments/$filename)\n';
        _controller.value = TextEditingValue(
          text: before + audioLink + after,
          selection: TextSelection.collapsed(offset: cursor + audioLink.length),
        );
      }
    }

    _dictationAudioPath = '';
    _currentWords = '';
    _focusNode.requestFocus();
  }

  Widget _buildDictationOverlay(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      height: 50,
      decoration: BoxDecoration(
        color: DesignColors.surfaceVariant(context).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: DesignColors.border(context), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            TactileWrapper(
              style: TactileFeedbackStyle.standard,
              onTap: () => _stopDictation(commit: false),
              child: const Tooltip(
                message: 'Cancel & Discard',
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const _SubtlePulseIcon(),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _currentWords.isEmpty ? 'Listening...' : _currentWords,
                style: DesignTypography.body(
                  context,
                  fontSize: 13,
                  color: DesignColors.text(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            TactileWrapper(
              style: TactileFeedbackStyle.standard,
              onTap: () => _stopDictation(commit: true),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dictation UI Helper Widgets ──────────────────────────────────────────────

class _SubtlePulseIcon extends StatefulWidget {
  const _SubtlePulseIcon();

  @override
  State<_SubtlePulseIcon> createState() => _SubtlePulseIconState();
}

class _SubtlePulseIconState extends State<_SubtlePulseIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _AudioPlayerBottomSheet extends StatefulWidget {
  final String filePath;
  final String fileName;

  const _AudioPlayerBottomSheet({
    required this.filePath,
    required this.fileName,
  });

  @override
  State<_AudioPlayerBottomSheet> createState() => _AudioPlayerBottomSheetState();
}

class _AudioPlayerBottomSheetState extends State<_AudioPlayerBottomSheet> {
  late final AudioPlayer _player;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
  }

  void _initPlayer() async {
    try {
      await _player.setSource(DeviceFileSource(widget.filePath));
      
      _durationSubscription = _player.onDurationChanged.listen((d) {
        setState(() => _duration = d);
      });
      _positionSubscription = _player.onPositionChanged.listen((p) {
        setState(() => _position = p);
      });
      _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
        setState(() => _isPlaying = state == PlayerState.playing);
      });

      await _player.play(DeviceFileSource(widget.filePath));
    } catch (e) {
      debugPrint('Audio player initialization error: $e');
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: BoxDecoration(
        color: DesignColors.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DesignSheetDragHandle(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.audiotrack_rounded, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice Recording',
                        style: DesignTypography.heading(
                          context,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.fileName,
                        style: DesignTypography.details(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble()),
                max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                onChanged: (val) async {
                  await _player.seek(Duration(milliseconds: val.toInt()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position), style: DesignTypography.metadata(context, fontSize: 11)),
                  Text(_formatDuration(_duration), style: DesignTypography.metadata(context, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10_rounded, size: 28),
                  onPressed: () async {
                    final newPos = _position - const Duration(seconds: 10);
                    await _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
                  },
                ),
                const SizedBox(width: 16),
                TactileWrapper(
                  style: TactileFeedbackStyle.standard,
                  onTap: () async {
                    if (_isPlaying) {
                      await _player.pause();
                    } else {
                      await _player.resume();
                    }
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: colorScheme.onPrimary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.forward_10_rounded, size: 28),
                  onPressed: () async {
                    final newPos = _position + const Duration(seconds: 10);
                    await _player.seek(newPos > _duration ? _duration : newPos);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

