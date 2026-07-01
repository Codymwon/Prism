import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../utils/editor_helpers.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class EditorWriteMode extends ConsumerWidget {
  final TextEditingController titleController;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final String family;
  final double size;
  final double paddingHorizontal;

  const EditorWriteMode({
    super.key,
    required this.titleController,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.family,
    required this.size,
    required this.paddingHorizontal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineNumbersEnabled = ref.watch(lineNumbersGutterProvider).valueOrNull ?? false;
    final autoPairBrackets = ref.watch(autoPairBracketsProvider).valueOrNull ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
          child: TextField(
            controller: titleController,
            style: getEditorFont(
              family,
              fontSize: size * 1.5,
              fontWeight: FontWeight.bold,
              color: DesignColors.text(context),
            ),
            decoration: InputDecoration(
              hintText: 'Note Title',
              hintStyle: getEditorFont(
                family,
                fontSize: size * 1.5,
                fontWeight: FontWeight.bold,
                color: DesignColors.textTertiary(context),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
          child: Divider(
            color: DesignColors.border(context),
            height: 1,
            thickness: 1,
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lineNumbersEnabled) ...[
                  _LineNumbersGutter(
                    controller: controller,
                    scrollController: scrollController,
                    family: family,
                    size: size,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    scrollController: scrollController,
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    inputFormatters: [
                      BracketsPairingFormatter(enabled: autoPairBrackets),
                    ],
                    style: getEditorFont(
                      family,
                      fontSize: size,
                      height: 1.7,
                      color: DesignColors.text(context),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Start writing… use [[note]] for links, #tag for tags',
                      hintStyle: getEditorFont(
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
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LineNumbersGutter extends StatefulWidget {
  final TextEditingController controller;
  final ScrollController scrollController;
  final String family;
  final double size;

  const _LineNumbersGutter({
    required this.controller,
    required this.scrollController,
    required this.family,
    required this.size,
  });

  @override
  State<_LineNumbersGutter> createState() => _LineNumbersGutterState();
}

class _LineNumbersGutterState extends State<_LineNumbersGutter> {
  late final ScrollController _gutterScrollController;

  @override
  void initState() {
    super.initState();
    _gutterScrollController = ScrollController();
    widget.scrollController.addListener(_syncScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_syncScroll);
    _gutterScrollController.dispose();
    super.dispose();
  }

  void _syncScroll() {
    if (_gutterScrollController.hasClients && widget.scrollController.hasClients) {
      _gutterScrollController.jumpTo(widget.scrollController.offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        final lineCount = value.text.split('\n').length;
        final linesText = List.generate(lineCount, (i) => '${i + 1}').join('\n');

        return IgnorePointer(
          child: SingleChildScrollView(
            controller: _gutterScrollController,
            physics: const NeverScrollableScrollPhysics(),
            child: Container(
              width: 32,
              padding: const EdgeInsets.only(top: 12, bottom: 100),
              child: Text(
                linesText,
                style: getEditorFont(
                  widget.family,
                  fontSize: widget.size,
                  height: 1.7,
                  color: DesignColors.textTertiary(context),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        );
      },
    );
  }
}
