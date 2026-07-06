import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/graph_models.dart';
import 'graph_providers.dart';
import '../../data/graph_node_repository.dart';
import '../../../onboarding/data/onboarding_provider.dart';

// ─── Graph Color Mode Provider ──────────────────────────────────────────────
final graphColorModeProvider =
    AsyncNotifierProvider<GraphColorModeNotifier, String>(
        GraphColorModeNotifier.new);

class GraphColorModeNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('graphColorMode') ?? 'none';
  }

  Future<void> setColorMode(String mode) async {
    state = AsyncData(mode);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('graphColorMode', mode);
  }
}

// ─── Tag Colors Provider (maps tagName -> hexColor) ──────────────────────────
final tagColorsProvider =
    AsyncNotifierProvider<TagColorsNotifier, Map<String, String>>(
        TagColorsNotifier.new);

class TagColorsNotifier extends AsyncNotifier<Map<String, String>> {
  @override
  Future<Map<String, String>> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    final jsonStr = prefs.getString('graphTagColors');
    if (jsonStr == null) return {};
    try {
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> setTagColor(String tag, String hexColor) async {
    final current = state.valueOrNull ?? {};
    final updated = Map<String, String>.from(current)..[tag] = hexColor;
    state = AsyncData(updated);
    
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('graphTagColors', json.encode(updated));
  }
}

// ─── Discovered Tags Provider (List of distinct tags from note_tags) ──────────
final discoveredTagsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final repo = ref.watch(graphNodeRepositoryProvider);
  final tagMap = await repo.getNoteTagsMap();
  final allTags = tagMap.values.expand((tags) => tags).toSet().toList()..sort();
  return allTags;
});

// ─── Graph Node Resolved Colors Provider ──────────────────────────────────────
final graphNodeColorsProvider = FutureProvider.autoDispose<Map<String, String?>>((ref) async {
  final colorMode = ref.watch(graphColorModeProvider).valueOrNull ?? 'none';
  if (colorMode == 'none') {
    return const {};
  }

  final repo = ref.watch(graphNodeRepositoryProvider);

  if (colorMode == 'folders') {
    final folderMap = await repo.getNoteFoldersMap();
    final result = <String, String?>{};
    for (final entry in folderMap.entries) {
      final noteId = entry.key;
      final folders = entry.value;
      if (folders.isNotEmpty) {
        // First folder alphabetically wins
        final firstFolder = folders.first;
        result[noteId] = firstFolder['color_hex'];
      }
    }
    return result;
  }

  if (colorMode == 'tags') {
    final tagMap = await repo.getNoteTagsMap();
    final userTagColors = ref.watch(tagColorsProvider).valueOrNull ?? {};
    final result = <String, String?>{};
    for (final entry in tagMap.entries) {
      final noteId = entry.key;
      final tags = entry.value;
      if (tags.isNotEmpty) {
        // First tag alphabetically that has a user-defined color wins.
        // If none have user-defined colors, use deterministic HSL hue derived from the first tag's name.
        String? chosenColor;
        for (final tag in tags) {
          if (userTagColors.containsKey(tag)) {
            chosenColor = userTagColors[tag];
            break;
          }
        }
        
        if (chosenColor == null && tags.isNotEmpty) {
          final firstTag = tags.first;
          // Deterministic HSL hue from tag hash code:
          final int hash = firstTag.hashCode.abs();
          final int hue = hash % 360;
          chosenColor = _hslToHex(hue.toDouble(), 0.7, 0.6);
        }
        
        result[noteId] = chosenColor;
      }
    }
    return result;
  }

  return const {};
});

// Helper to generate tag colors deterministically in HSL and output Hex
String _hslToHex(double h, double s, double l) {
  final double c = (1.0 - (2.0 * l - 1.0).abs()) * s;
  final double x = c * (1.0 - ((h / 60.0) % 2.0 - 1.0).abs());
  final double m = l - c / 2.0;
  
  double r = 0, g = 0, b = 0;
  if (0 <= h && h < 60) {
    r = c; g = x; b = 0;
  } else if (60 <= h && h < 120) {
    r = x; g = c; b = 0;
  } else if (120 <= h && h < 180) {
    r = 0; g = c; b = x;
  } else if (180 <= h && h < 240) {
    r = 0; g = x; b = c;
  } else if (240 <= h && h < 300) {
    r = x; g = 0; b = c;
  } else if (300 <= h && h < 360) {
    r = c; g = 0; b = x;
  }
  
  final int ri = ((r + m) * 255).round();
  final int gi = ((g + m) * 255).round();
  final int bi = ((b + m) * 255).round();
  
  return '#${ri.toRadixString(16).padLeft(2, '0')}${gi.toRadixString(16).padLeft(2, '0')}${bi.toRadixString(16).padLeft(2, '0')}';
}
