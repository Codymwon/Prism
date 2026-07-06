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
import '../../../onboarding/data/onboarding_provider.dart';
import '../controllers/live_preview_controller.dart';
import '../utils/markdown_line_parser.dart';

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
  bool get _isTemplate => widget.noteId.startsWith('template:');
  final _titleController = TextEditingController();
  late final LivePreviewController _controller;
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  late EditorController _editorController;

  // Caching processed markdown text (avoiding redundant processWikilinks RegExp execution)
  String? _processedWikilinksText;
  String? _lastProcessedText;

  Set<String> _collapsedHeadings = {};
  bool _showEditorDrawer = false;

  Future<void> _loadCollapsedHeadings() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
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

  Future<void> _toggleHeadingCollapse(String headingPath) async {
    debugPrint('*** _toggleHeadingCollapse called for: $headingPath, current: $_collapsedHeadings');
    setState(() {
      if (_collapsedHeadings.contains(headingPath)) {
        _collapsedHeadings.remove(headingPath);
      } else {
        _collapsedHeadings.add(headingPath);
      }
    });

    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setStringList('collapsed_${widget.noteId}', _collapsedHeadings.toList());
    } catch (e) {
      debugPrint('Error saving collapsed headings: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _editorController = ref.read(editorControllerProvider(widget.noteId).notifier);
    
    _controller = LivePreviewController(
      noteId: widget.noteId,
      mode: EditorMode.livePreview,
      audioPlayerBuilder: (path, label) {
        return InlineAudioWaveformPlayer(
          key: ValueKey('audio_waveform_$path'),
          filePath: path,
          fileName: label ?? p.basename(path),
          noteId: widget.noteId,
        );
      },
      imageBuilder: (path, alt) {
        return buildMarkdownImage(
          uri: Uri.parse(path),
          noteId: widget.noteId,
          ref: ref,
          context: context,
        );
      },
      tableBuilder: (tableLines) {
        return MarkdownBody(
          data: tableLines.join('\n'),
          styleSheet: buildMarkdownStyleSheet(
            context,
            ref.read(fontFamilyProvider),
            double.tryParse(ref.read(fontSizeProvider).replaceAll('pt', '')) ?? 16.0,
            Theme.of(context).colorScheme,
          ),
        );
      },
      checkboxBuilder: (lineIndex, checked) {
        return GestureDetector(
          onTap: () => _toggleCheckbox(lineIndex),
          child: Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: checked,
                onChanged: (val) => _toggleCheckbox(lineIndex),
                activeColor: DesignColors.primary(context),
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        );
      },
    );

    _loadNote();
    _loadCollapsedHeadings();
    _titleController.addListener(_onTextChanged);
    _controller.addListener(_onTextChanged);
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
    final audioRecordState = ref.read(audioRecordControllerProvider(widget.noteId));
    ref.read(editorControllerProvider(widget.noteId).notifier).onTextChanged(
          _titleController.text,
          _controller.text,
          _controller.selection,
          audioRecordState.isRecording,
        );
  }

  void _toggleCheckbox(int lineIndex) {
    final text = _controller.text;
    final newText = toggleMarkdownCheckboxAtLine(text, lineIndex);
    if (newText != text) {
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

    final editorState = ref.watch(editorControllerProvider(widget.noteId));
    final audioRecordState = ref.watch(audioRecordControllerProvider(widget.noteId));

    final mode = editorState.editorMode;
    _controller.mode = mode;

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
                  child: mode != EditorMode.reading
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
                            audioRecordState.isRecording
                                ? AudioRecordOverlay(
                                    durationSeconds: audioRecordState.durationSeconds,
                                    onCancel: () => _stopAudioRecording(commit: false),
                                    onCommit: () => _stopAudioRecording(commit: true),
                                  )
                                : FormattingToolbar(
                                    controller: _controller,
                                    focusNode: _focusNode,
                                    onToggleDictation: _toggleAudioRecording,
                                    onAttachImage: _attachImage,
                                  ),
                          ],
                        )
                      : _buildReadingView(
                          isDark, colorScheme, fontFamily, sizeVal, paddingVal, editorState),
                ),
                // Backlinks panel
                if (MediaQuery.of(context).viewInsets.bottom == 0 && editorState.showBacklinks)
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

          // Editor Drawer Overlay Panel
          if (_showEditorDrawer)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showEditorDrawer = false),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.15),
                ),
              ),
            ),
          if (_showEditorDrawer)
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: DesignColors.surface(context).withValues(alpha: 0.95),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DesignColors.border(context)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'EDITOR MODE',
                          style: DesignTypography.metadata(
                            context,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: DesignColors.textTertiary(context),
                          ),
                        ),
                      ),
                      _buildDrawerModeButton(
                        context,
                        label: 'Live Preview',
                        icon: Icons.edit_note,
                        isActive: mode == EditorMode.livePreview,
                        onTap: () {
                          _editorController.setEditorMode(EditorMode.livePreview);
                          setState(() => _showEditorDrawer = false);
                        },
                      ),
                      const SizedBox(height: 4),
                      _buildDrawerModeButton(
                        context,
                        label: 'Source Mode',
                        icon: Icons.code,
                        isActive: mode == EditorMode.source,
                        onTap: () {
                          _editorController.setEditorMode(EditorMode.source);
                          setState(() => _showEditorDrawer = false);
                        },
                      ),
                      const SizedBox(height: 4),
                      _buildDrawerModeButton(
                        context,
                        label: 'Reading View',
                        icon: Icons.menu_book,
                        isActive: mode == EditorMode.reading,
                        onTap: () {
                          _editorController.setEditorMode(EditorMode.reading);
                          setState(() => _showEditorDrawer = false);
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6.0),
                        child: Divider(height: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: Text(
                          'SETTINGS',
                          style: DesignTypography.metadata(
                            context,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: DesignColors.textTertiary(context),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _editorController.toggleShowBacklinks();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.link_rounded,
                                    size: 18,
                                    color: DesignColors.textSecondary(context),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Backlinks',
                                    style: DesignTypography.body(
                                      context,
                                      fontSize: 14,
                                      color: DesignColors.text(context),
                                    ),
                                  ),
                                ],
                              ),
                              Transform.scale(
                                scale: 0.8,
                                child: Switch.adaptive(
                                  value: editorState.showBacklinks,
                                  activeColor: DesignColors.primary(context),
                                  onChanged: (val) {
                                    _editorController.toggleShowBacklinks();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDrawerModeButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? DesignColors.primary(context).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? DesignColors.primary(context) : DesignColors.textSecondary(context),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: DesignTypography.body(context).copyWith(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? DesignColors.primary(context) : DesignColors.text(context),
              ),
            ),
          ],
        ),
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
          if (_isTemplate)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: DesignColors.primary(context).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined, size: 12, color: DesignColors.primary(context)),
                  const SizedBox(width: 4),
                  Text(
                    'TEMPLATE',
                    style: DesignTypography.metadata(
                      context,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: DesignColors.primary(context),
                    ),
                  ),
                ],
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
        // Editor settings drawer trigger button
        IconButton(
          icon: const Icon(Icons.settings, size: 20),
          onPressed: () {
            setState(() {
              _showEditorDrawer = !_showEditorDrawer;
            });
          },
          tooltip: 'Editor Settings',
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
  Widget _buildReadingView(
    bool isDark,
    ColorScheme colorScheme,
    String family,
    double size,
    double paddingHorizontal,
    EditorState editorState,
  ) {
    final processedData = _getProcessedMarkdown();
    final segments = splitAudioLinks(processedData);
    final rootNode = parseHierarchicalSections(segments);

    final styleSheet = buildMarkdownStyleSheet(context, family, size, colorScheme);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
            child: Text(
              _titleController.text.isEmpty ? 'Untitled' : _titleController.text,
              style: getEditorFont(
                family,
                fontSize: size * 1.8,
                fontWeight: FontWeight.w800,
                color: DesignColors.text(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
            child: Container(
              height: 1,
              color: DesignColors.border(context),
            ),
          ),
          const SizedBox(height: 16),
          // 1. Render root level segments (text before any heading)
          for (final segment in rootNode.segments)
            if (segment.isAudio)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 4),
                child: InlineAudioWaveformPlayer(
                  key: ValueKey('audio_${segment.audioPath}'),
                  filePath: segment.audioPath!,
                  fileName: segment.audioLabel ?? p.basename(segment.audioPath!),
                  noteId: widget.noteId,
                ),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
                child: Builder(
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
                        handleMarkdownLinkTap(
                          href: href,
                          ref: ref,
                          context: context,
                        );
                      },
                      styleSheet: styleSheet,
                      checkboxBuilder: (bool value) {
                        final lineIndex = segment.checkboxLineIndices[localCheckboxIndex++];
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
                                _toggleCheckbox(lineIndex);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          // 2. Render subheadings recursively
          for (final child in rootNode.children)
            _buildHeadingNode(child, styleSheet, colorScheme, family, size, paddingHorizontal),
        ],
      ),
    );
  }

  Widget _buildHeadingNode(
    HeadingNode node,
    MarkdownStyleSheet styleSheet,
    ColorScheme colorScheme,
    String family,
    double size,
    double paddingHorizontal,
  ) {
    final isCollapsed = _collapsedHeadings.contains(node.path);
    // The chevron is placed in the gutter, so we adjust the left padding of the row
    final leftPadding = paddingHorizontal > 24.0 ? paddingHorizontal - 24.0 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(left: leftPadding, right: paddingHorizontal),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 28, // Matches heading height alignment
                child: Center(
                  child: IconButton(
                    icon: AnimatedRotation(
                      turns: isCollapsed ? 0.0 : 0.25,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.chevron_right, size: 20),
                    ),
                    onPressed: () => _toggleHeadingCollapse(node.path),
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
              Expanded(
                child: MarkdownBody(
                  data: '${'#' * node.level} ${node.headingText}',
                  inlineSyntaxes: [HighlightSyntax(), HashtagSyntax()],
                  builders: {
                    'mark': HighlightElementBuilder(context),
                    'hashtag': HashtagElementBuilder(context),
                  },
                  styleSheet: styleSheet,
                  onTapLink: (text, href, title) async {
                    handleMarkdownLinkTap(
                      href: href,
                      ref: ref,
                      context: context,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topLeft,
          child: isCollapsed
              ? const SizedBox.shrink()
              : Padding(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final segment in node.segments)
                        if (segment.isAudio)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 4),
                            child: InlineAudioWaveformPlayer(
                              key: ValueKey('audio_${segment.audioPath}'),
                              filePath: segment.audioPath!,
                              fileName: segment.audioLabel ?? p.basename(segment.audioPath!),
                              noteId: widget.noteId,
                            ),
                          )
                        else
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
                            child: Builder(
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
                                    handleMarkdownLinkTap(
                                      href: href,
                                      ref: ref,
                                      context: context,
                                    );
                                  },
                                  styleSheet: styleSheet,
                                  checkboxBuilder: (bool value) {
                                    final lineIndex = segment.checkboxLineIndices[localCheckboxIndex++];
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
                                            _toggleCheckbox(lineIndex);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                      for (final child in node.children)
                        _buildHeadingNode(child, styleSheet, colorScheme, family, size, paddingHorizontal),
                    ],
                  ),
                ),
        ),
      ],
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

  Future<void> _toggleAudioRecording() async {
    try {
      await ref
          .read(audioRecordControllerProvider(widget.noteId).notifier)
          .toggleRecording(
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

  Future<void> _stopAudioRecording({required bool commit}) async {
    try {
      await ref
          .read(audioRecordControllerProvider(widget.noteId).notifier)
          .stopRecording(
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
      debugPrint('Error stopping audio recording: $e');
    }
  }
}
