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
  final _controller = TextEditingController();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _controller.dispose();
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

    ref.listen<String>(searchQueryProvider, (previous, next) {
      if (next.isEmpty && _controller.text.isNotEmpty) {
        _controller.clear();
      }
    });

    final selectedFolderId = ref.watch(selectedFolderIdProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final isHome = selectedFolderId == null;

    if (!isDesktop && isHome) {
      final query = ref.watch(searchQueryProvider);
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(DesignSpacing.screenPadding, 8, DesignSpacing.screenPadding, 8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: DesignColors.surfaceVariant(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _searchFocusNode.hasFocus
                    ? DesignColors.primary(context).withValues(alpha: 0.6)
                    : DesignColors.border(context),
                width: _searchFocusNode.hasFocus ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(DesignIcons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Open drawer',
                  color: DesignColors.text(context),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _searchFocusNode,
                    onChanged: (q) {
                      ref.read(searchQueryProvider.notifier).state = q;
                      if (q.isNotEmpty && !_isSearching) {
                        setState(() => _isSearching = true);
                      }
                    },
                    style: DesignTypography.body(context, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      hintStyle: DesignTypography.body(
                        context,
                        fontSize: 14,
                        color: DesignColors.textTertiary(context),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
                if (query.isNotEmpty)
                  IconButton(
                    icon: const Icon(DesignIcons.close, size: 16),
                    onPressed: () {
                      _controller.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                      _searchFocusNode.unfocus();
                      setState(() => _isSearching = false);
                    },
                    color: DesignColors.textSecondary(context),
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      );
    }

    final showSortButton = selectedFolderId != null && selectedFolderId != '__folders__';

    return Padding(
      padding: const EdgeInsets.fromLTRB(DesignSpacing.screenPadding, 0, DesignSpacing.screenPadding, 8),
      child: Row(
        children: [
          Expanded(
            child: SearchBarWidget(
              onChanged: (q) {
                _controller.text = q;
                ref.read(searchQueryProvider.notifier).state = q;
              },
              onClear: () {
                _controller.clear();
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
