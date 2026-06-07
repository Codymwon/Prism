import 'package:flutter/material.dart';
import '../../../../shared/design_system/design_system.dart';
import '../utils/editor_helpers.dart';

class EditorWriteMode extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              scrollController: scrollController,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
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
        ),
      ],
    );
  }
}
