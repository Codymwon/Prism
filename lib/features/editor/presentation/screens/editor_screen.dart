import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../core/utils/utils.dart';
import '../utils/editor_helpers.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../widgets/wikilink_autocomplete.dart';
import '../widgets/backlinks_panel.dart';
import '../widgets/formatting_toolbar.dart';
import '../widgets/inline_audio_waveform_player.dart';
import '../../../folders/presentation/widgets/folder_assign_dialog.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/editor_controller.dart';
import '../widgets/conflict_banner.dart';
import '../widgets/editor_write_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final _titleController = TextEditingController();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  late EditorController _editorController;
  late StateController<EditorMode> _editorModeController;

  // Caching processed markdown text (avoiding redundant processWikilinks RegExp execution)
  String? _processedWikilinksText;
  String? _lastProcessedText;

  Set<String> _collapsedHeadings = {};

  Future<void> _loadCollapsedHeadings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('collapsed_${widget.noteId}') ?? [];
      if (mounted) {
        setState(() {
          _collapsedHeadings = list.toSet();
        });
      }
    } catch (e) {
      debugPrint('Error loading collapsed headings: $e');
    }
  }

  Future<void> _toggleHeadingCollapse(String headingText) async {
    setState(() {
      if (_collapsedHeadings.contains(headingText)) {
        _collapsedHeadings.remove(headingText);
      } else {
        _collapsedHeadings.add(headingText);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('collapsed_${widget.noteId}', _collapsedHeadings.toList());
    } catch (e) {
      debugPrint('Error saving collapsed headings: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _editorController = ref.read(editorControllerProvider(widget.noteId).notifier);
    _editorModeController = ref.read(editorModeProvider.notifier);
    _loadNote();
    _loadCollapsedHeadings();
    _titleController.addListener(_onTextChanged);
    _controller.addListener(_onTextChanged);

    // Set mode: Edit mode for new notes, View mode for existing notes
    Future.microtask(() {
      if (mounted) {
        _editorModeController.state =
            widget.isNew ? EditorMode.write : EditorMode.preview;
      }
    });
  }

  Future<void> _loadNote() async {
    final stateResult = await ref
        .read(editorControllerProvider(widget.noteId).notifier)
        .loadNote(isNew: widget.isNew, defaultDailyDate: widget.dailyDate);
    if (stateResult == null) return;

    if (mounted) {
      _titleController.text = stateResult.loadedTitle;
      _controller.text = stateResult.loadedBody;

      // Auto-focus when new
      if (widget.isNew) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _focusNode.requestFocus();
            // Position cursor at end
            _controller.selection =
                TextSelection.collapsed(offset: stateResult.loadedBody.length);
          }
        });
      }
    }
  }

  void _onTextChanged() {
    final dictationState = ref.read(dictationControllerProvider(widget.noteId));
    ref.read(editorControllerProvider(widget.noteId).notifier).onTextChanged(
          _titleController.text,
          _controller.text,
          _controller.selection,
          dictationState.isDictating,
        );
  }

  void _toggleCheckbox(int index) {
    final text = _controller.text;
    final regex = RegExp(r'^\s*([-*+]|\d+\.)\s+\[([ xX])\]', multiLine: true);
    final matches = regex.allMatches(text).toList();
    if (index >= 0 && index < matches.length) {
      final match = matches[index];
      final charIndex = match.end - 2;
      if (charIndex >= 0 && charIndex < text.length) {
        final currentChar = text[charIndex];
        final newChar = (currentChar == ' ') ? 'x' : ' ';
        final newText =
            text.substring(0, charIndex) + newChar + text.substring(charIndex + 1);
        _controller.value = TextEditingValue(
          text: newText,
          selection: _controller.selection.copyWith(
            baseOffset: _controller.selection.baseOffset.clamp(0, newText.length),
            extentOffset: _controller.selection.extentOffset.clamp(0, newText.length),
          ),
        );
        ref.read(editorControllerProvider(widget.noteId).notifier).save(
              _titleController.text,
              _controller.text,
            );
      }
    }
  }

  void _insertWikilink(String noteTitle) {
    final newValue = ref
        .read(editorControllerProvider(widget.noteId).notifier)
        .insertWikilink(noteTitle, _controller.text, _controller.selection);
    if (newValue != null) {
      _controller.value = newValue;
    }
  }

  @override
  void dispose() {
    _editorController.saveIfNeeded(
      _titleController.text,
      _controller.text,
    );

    // Reset editor mode to View mode when exiting
    try {
      _editorModeController.state = EditorMode.preview;
    } catch (_) {}

    _titleController.removeListener(_onTextChanged);
    _titleController.dispose();
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

    final editorState = ref.watch(editorControllerProvider(widget.noteId));
    final dictationState = ref.watch(dictationControllerProvider(widget.noteId));

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
      appBar: _buildAppBar(colorScheme, mode, editorState),
      body: Stack(
        children: [
          if (!editorState.isLoaded)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final isConflicted = ref.watch(
                      noteByIdProvider(widget.noteId).select(
                        (asyncNote) =>
                            asyncNote.valueOrNull?.isConflicted ?? false,
                      ),
                    );
                    if (!isConflicted) return const SizedBox.shrink();
                    return ConflictBanner(noteId: widget.noteId);
                  },
                ),
                Expanded(
                  child: mode == EditorMode.write
                      ? Column(
                          children: [
                            Expanded(
                              child: EditorWriteMode(
                                titleController: _titleController,
                                controller: _controller,
                                focusNode: _focusNode,
                                scrollController: _scrollController,
                                family: fontFamily,
                                size: sizeVal,
                                paddingHorizontal: paddingVal,
                              ),
                            ),
                            dictationState.isDictating
                                ? DictationOverlay(
                                    currentWords: ref
                                                .read(keepVoiceRecordingsProvider)
                                                .valueOrNull ??
                                            false
                                        ? 'Recording audio note...'
                                        : (dictationState.currentWords.isEmpty
                                            ? 'Listening...'
                                            : dictationState.currentWords),
                                    onCancel: () => _stopDictation(commit: false),
                                    onCommit: () => _stopDictation(commit: true),
                                  )
                                : FormattingToolbar(
                                    controller: _controller,
                                    focusNode: _focusNode,
                                    onToggleDictation: _toggleDictation,
                                    onAttachImage: _attachImage,
                                  ),
                          ],
                        )
                      : _buildPreviewMode(
                          isDark, colorScheme, fontFamily, sizeVal, paddingVal, editorState),
                ),
                // Backlinks panel
                if (MediaQuery.of(context).viewInsets.bottom == 0)
                  BacklinksPanel(noteId: widget.noteId),
              ],
            ),

          // Wikilink autocomplete floating popup
          if (editorState.showWikilinkPopup)
            WikilinkAutocomplete(
              query: editorState.wikilinkQuery,
              onSelect: _insertWikilink,
              onDismiss: () => ref
                  .read(editorControllerProvider(widget.noteId).notifier)
                  .dismissWikilinkPopup(),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    ColorScheme colorScheme,
    EditorMode mode,
    EditorState editorState,
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
            child: Consumer(
              builder: (context, ref, _) {
                final note =
                    ref.watch(noteByIdProvider(widget.noteId)).valueOrNull;
                return Text(
                  note?.title ?? '',
                  style: DesignTypography.heading(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        // Save indicator
        AnimatedOpacity(
          opacity: editorState.isSaving ? 1 : 0,
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

  String _getProcessedMarkdown() {
    final text = _controller.text;
    if (_lastProcessedText == text && _processedWikilinksText != null) {
      return _processedWikilinksText!;
    }
    _lastProcessedText = text;
    _processedWikilinksText = preprocessMarkdown(text);
    return _processedWikilinksText!;
  }

  Widget _buildPreviewMode(
    bool isDark,
    ColorScheme colorScheme,
    String family,
    double size,
    double paddingHorizontal,
    EditorState editorState,
  ) {
    final processedData = _getProcessedMarkdown();
    final segments = splitAudioLinks(processedData);
    final sections = groupSegmentsByH1(segments);

    final styleSheet = buildMarkdownStyleSheet(context, family, size, colorScheme);

    return SingleChildScrollView(
      controller: _scrollController,
      padding:
          EdgeInsets.fromLTRB(paddingHorizontal, 12, paddingHorizontal, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titleController.text.isEmpty ? 'Untitled' : _titleController.text,
            style: getEditorFont(
              family,
              fontSize: size * 1.8,
              fontWeight: FontWeight.w800,
              color: DesignColors.text(context),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: DesignColors.border(context),
          ),
          const SizedBox(height: 16),
          for (final section in sections) ...[
            if (section.headingText != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: AnimatedRotation(
                      turns: _collapsedHeadings.contains(section.headingText) ? 0.0 : 0.25,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.chevron_right, size: 24),
                    ),
                    onPressed: () => _toggleHeadingCollapse(section.headingText!),
                    splashRadius: 20,
                  ),
                  Expanded(
                    child: MarkdownBody(
                      data: '# ${section.headingText}',
                      inlineSyntaxes: [HighlightSyntax(), HashtagSyntax()],
                      builders: {
                        'mark': HighlightElementBuilder(context),
                        'hashtag': HashtagElementBuilder(context),
                      },
                      styleSheet: styleSheet,
                      onTapLink: (text, href, title) async {
                        handleWikilinkTap(
                          href: href,
                          ref: ref,
                          context: context,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topLeft,
              child: _collapsedHeadings.contains(section.headingText)
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final segment in section.segments)
                          if (segment.isAudio)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: InlineAudioWaveformPlayer(
                                key: ValueKey('audio_${segment.audioPath}'),
                                filePath: segment.audioPath!,
                                fileName: segment.audioLabel ?? p.basename(segment.audioPath!),
                                noteId: widget.noteId,
                              ),
                            )
                          else
                            Builder(
                              builder: (context) {
                                int localCheckboxIndex = 0;
                                return MarkdownBody(
                                  data: segment.text!,
                                  softLineBreak: true,
                                  inlineSyntaxes: [HighlightSyntax(), HashtagSyntax()],
                                  builders: {
                                    'mark': HighlightElementBuilder(context),
                                    'hashtag': HashtagElementBuilder(context),
                                  },
                                  imageBuilder: (uri, title, alt) {
                                    return buildMarkdownImage(
                                      uri: uri,
                                      noteId: widget.noteId,
                                      ref: ref,
                                      context: context,
                                    );
                                  },
                                  onTapLink: (text, href, title) async {
                                    handleWikilinkTap(
                                      href: href,
                                      ref: ref,
                                      context: context,
                                    );
                                  },
                                  styleSheet: styleSheet,
                                  checkboxBuilder: (bool value) {
                                    final index = segment.startingCheckboxIndex + localCheckboxIndex++;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6, top: 3),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: Checkbox(
                                          value: value,
                                          activeColor: colorScheme.primary,
                                          checkColor: colorScheme.onPrimary,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          side: BorderSide(
                                            color: DesignColors.textSecondary(context)
                                                .withValues(alpha: 0.7),
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          onChanged: (bool? newValue) {
                                            _toggleCheckbox(index);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _attachImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result == null || result.files.single.path == null) {
        return;
      }

      final pickedPath = result.files.single.path!;
      final note = ref.read(noteByIdProvider(widget.noteId)).valueOrNull;
      if (note == null) return;

      final vaultPath = p.dirname(note.filePath);
      final attachmentsDir = Directory(p.join(vaultPath, 'attachments'));
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      final originalName = p.basename(pickedPath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'image_${timestamp}_$originalName';
      final destPath = p.join(attachmentsDir.path, fileName);

      await File(pickedPath).copy(destPath);

      final relativePath = 'attachments/$fileName';
      final imageLink = '\n\n![image]($relativePath)\n';

      final text = _controller.text;
      final selection = _controller.selection;
      final cursor = selection.isValid ? selection.baseOffset : text.length;

      final before = text.substring(0, cursor);
      final after = text.substring(cursor);

      _controller.value = TextEditingValue(
        text: before + imageLink + after,
        selection: TextSelection.collapsed(offset: cursor + imageLink.length),
      );

      ref.read(editorControllerProvider(widget.noteId).notifier).save(
            _titleController.text,
            _controller.text,
          );
    } catch (e) {
      debugPrint('Error attaching image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to attach image: $e')),
        );
      }
    }
  }

  Future<void> _toggleDictation() async {
    try {
      await ref
          .read(dictationControllerProvider(widget.noteId).notifier)
          .toggleDictation(
            textController: _controller,
            focusNode: _focusNode,
            onSave: () {
              ref.read(editorControllerProvider(widget.noteId).notifier).save(
                    _titleController.text,
                    _controller.text,
                  );
            },
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _stopDictation({required bool commit}) async {
    try {
      await ref
          .read(dictationControllerProvider(widget.noteId).notifier)
          .stopDictation(
            commit: commit,
            textController: _controller,
            focusNode: _focusNode,
            onSave: () {
              ref.read(editorControllerProvider(widget.noteId).notifier).save(
                    _titleController.text,
                    _controller.text,
                  );
            },
          );
    } catch (e) {
      debugPrint('Error stopping dictation: $e');
    }
  }
}
