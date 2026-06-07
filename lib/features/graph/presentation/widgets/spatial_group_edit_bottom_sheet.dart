import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../notes/data/note_model.dart';
import '../../../notes/data/note_repository.dart';
import '../../data/graph_models.dart';
import '../../data/spatial_group_repository.dart';

final allNotesListProvider = FutureProvider.autoDispose<List<Note>>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getAllNotes(sort: NoteSort.title);
});

class SpatialGroupEditBottomSheet extends ConsumerStatefulWidget {
  final SpatialGroup? group;

  const SpatialGroupEditBottomSheet({
    super.key,
    this.group,
  });

  @override
  ConsumerState<SpatialGroupEditBottomSheet> createState() => _SpatialGroupEditBottomSheetState();
}

class _SpatialGroupEditBottomSheetState extends ConsumerState<SpatialGroupEditBottomSheet> {
  late TextEditingController _nameController;
  late String _colorHex;
  late TextEditingController _customColorController;
  Note? _selectedRootNote;
  String _searchQuery = '';
  List<String> _selectedNoteIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group?.name ?? '');
    _colorHex = widget.group?.colorHex ?? '#PRIMARY';
    
    final isCustomColor = !['#PRIMARY', '#ROSE', '#GREEN', '#AMBER'].contains(_colorHex.toUpperCase());
    _customColorController = TextEditingController(text: isCustomColor ? _colorHex : '');
    
    _loadGroupMembers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customColorController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupMembers() async {
    if (widget.group != null) {
      final mappings = await ref.read(spatialGroupRepositoryProvider).getSpatialGroupNodeMappings();
      setState(() {
        _selectedNoteIds = mappings[widget.group!.id] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _resolveColor(String key) {
    final theme = Theme.of(context);
    switch (key.toUpperCase()) {
      case '#PRIMARY':
        return theme.colorScheme.primary;
      case '#ROSE':
        return theme.colorScheme.error;
      case '#GREEN':
        return theme.colorScheme.secondary;
      case '#AMBER':
        return theme.colorScheme.tertiary;
      default:
        var hexColor = key.replaceAll('#', '');
        if (hexColor.length == 6) {
          hexColor = 'FF$hexColor';
        }
        final val = int.tryParse(hexColor, radix: 16);
        return val != null ? Color(val) : theme.colorScheme.primary;
    }
  }

  Future<void> _include1HopNotes() async {
    if (_selectedRootNote == null) return;
    final rootId = _selectedRootNote!.id;
    final connections = await ref.read(spatialGroupRepositoryProvider).get1HopConnections(rootId);
    
    setState(() {
      final newSet = _selectedNoteIds.toSet();
      newSet.add(rootId);
      newSet.addAll(connections);
      _selectedNoteIds = newSet.toList();
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    String colorToSave = _colorHex;
    final customVal = _customColorController.text.trim();
    if (customVal.isNotEmpty) {
      if (!customVal.startsWith('#')) {
        colorToSave = '#$customVal';
      } else {
        colorToSave = customVal;
      }
    }

    final repo = ref.read(spatialGroupRepositoryProvider);
    if (widget.group != null) {
      await repo.updateSpatialGroup(
        id: widget.group!.id,
        name: name,
        colorHex: colorToSave,
        memberNodeIds: _selectedNoteIds,
      );
    } else {
      await repo.createSpatialGroup(
        name: name,
        colorHex: colorToSave,
        memberNodeIds: _selectedNoteIds,
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final notesAsync = ref.watch(allNotesListProvider);

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? PrismColors.darkSurface : PrismColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? PrismColors.darkBorder : PrismColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.group != null ? 'Edit Spatial Group' : 'Create Spatial Group',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? PrismColors.darkText : PrismColors.lightText,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Name Input
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Group Name',
                    hintText: 'e.g., Design Patterns, Personal Projects',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Color Selection
                Text(
                  'Group Accent Color',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? PrismColors.darkTextSecondary : PrismColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ...['#PRIMARY', '#ROSE', '#GREEN', '#AMBER'].map((key) {
                      final isSelected = _colorHex.toUpperCase() == key;
                      final resolvedColor = _resolveColor(key);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _colorHex = key;
                            _customColorController.clear();
                          });
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: resolvedColor.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? resolvedColor : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? Icon(Icons.check_rounded, color: resolvedColor, size: 20)
                              : null,
                        ),
                      );
                    }),
                    // Custom Hex field
                    SizedBox(
                      width: 120,
                      height: 44,
                      child: TextField(
                        controller: _customColorController,
                        onChanged: (val) {
                          if (val.trim().isNotEmpty) {
                            setState(() {
                              _colorHex = val;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: '#7C6FF7',
                          labelText: 'Custom Hex',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1-Hop Selector
                Text(
                  'Auto-Include 1-Hop Connected Notes',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? PrismColors.darkTextSecondary : PrismColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                notesAsync.when(
                  data: (notes) {
                    return Row(
                      children: [
                        Expanded(
                          child: Autocomplete<Note>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<Note>.empty();
                              }
                              return notes.where((note) =>
                                  note.title.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                            },
                            displayStringForOption: (Note note) => note.title,
                            onSelected: (Note note) {
                              setState(() {
                                _selectedRootNote = note;
                              });
                            },
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: 'Select root note...',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _selectedRootNote != null ? _include1HopNotes : null,
                          icon: const Icon(Icons.hub_rounded, size: 16),
                          label: const Text('Add 1-Hop'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.onPrimaryContainer,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading notes: $e'),
                ),
                const SizedBox(height: 16),

                // Manual fine-tuning header
                Text(
                  'Group Members Selection',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? PrismColors.darkTextSecondary : PrismColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search notes to filter...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Checklist of notes
                Expanded(
                  child: notesAsync.when(
                    data: (notes) {
                      final filteredNotes = notes.where((note) =>
                          note.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                      if (filteredNotes.isEmpty) {
                        return const Center(child: Text('No notes found'));
                      }
                      return ListView.builder(
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];
                          final isChecked = _selectedNoteIds.contains(note.id);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              note.title,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark ? PrismColors.darkText : PrismColors.lightText,
                              ),
                            ),
                            value: isChecked,
                            onChanged: (bool? checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedNoteIds.add(note.id);
                                } else {
                                  _selectedNoteIds.remove(note.id);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ),
                const SizedBox(height: 16),

                // Sticky Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save Group'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
