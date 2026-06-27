import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../providers/notes_providers.dart';
import '../../../folders/presentation/providers/folders_providers.dart';
import 'search_bar_widget.dart';
import 'notes_sort_bottom_sheet.dart';

class NotesListSearchBar extends ConsumerStatefulWidget {
  const NotesListSearchBar({super.key});

  @override
  ConsumerState<NotesListSearchBar> createState() => _NotesListSearchBarState();
}

class _NotesListSearchBarState extends ConsumerState<NotesListSearchBar> {
  bool _isSearching = false;
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(searchFocusProvider, (previous, next) {
      if (next) {
        setState(() => _isSearching = true);
        Future.delayed(const Duration(milliseconds: 100), () {
          _searchFocusNode.requestFocus();
        });
        ref.read(searchFocusProvider.notifier).state = false;
      }
    });

    final selectedFolderId = ref.watch(selectedFolderIdProvider);
    final showSortButton = selectedFolderId != null && selectedFolderId != '__folders__';

    return Padding(
      padding: const EdgeInsets.fromLTRB(DesignSpacing.screenPadding, 0, DesignSpacing.screenPadding, 8),
      child: Row(
        children: [
          Expanded(
            child: SearchBarWidget(
              onChanged: (q) => ref.read(searchQueryProvider.notifier).state = q,
              onClear: () {
                ref.read(searchQueryProvider.notifier).state = '';
                setState(() => _isSearching = false);
              },
              onFocused: () => setState(() => _isSearching = true),
              focusNode: _searchFocusNode,
            ),
          ),
          if (!_isSearching && showSortButton) ...[
            const SizedBox(width: 8),
            const NotesSortButton(),
          ],
        ],
      ),
    );
  }
}
