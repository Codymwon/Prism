import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _uuid = Uuid();

/// Generates a new unique UUID v4.
String generateId() => _uuid.v4();

/// Returns the vault folder path (DocumentDirectory/meridian_vaults/activeVault).
Future<String> getVaultPath() async {
  final prefs = await SharedPreferences.getInstance();
  String? baseDir = prefs.getString('baseVaultsDirectory');
  if (baseDir == null || baseDir.isEmpty) {
    final docDir = await getApplicationDocumentsDirectory();
    baseDir = p.join(docDir.path, 'meridian_vaults');
  }
  final activeVault = prefs.getString('activeVaultName') ?? 'My Vault';
  final vaultPath = p.join(baseDir, activeVault);
  final vault = Directory(vaultPath);
  if (!vault.existsSync()) vault.createSync(recursive: true);
  return vault.path;
}

/// Converts a note title to a safe filename slug.
String titleToSlug(String title) {
  return title
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .trim();
}

/// Extracts the title from a markdown string.
/// Looks for a # heading first, falls back to first non-empty line.
String extractTitle(String content) {
  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('# ')) return trimmed.substring(2).trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return 'Untitled';
}

/// Counts words in a string.
int countWords(String text) {
  return text.trim().isEmpty
      ? 0
      : text.trim().split(RegExp(r'\s+')).length;
}

/// Extracts all #tags from markdown content (e.g. #productivity, #ideas).
List<String> extractTags(String content) {
  final regex = RegExp(r'(?<!\w)#([a-zA-Z][a-zA-Z0-9_]*)');
  return regex.allMatches(content).map((m) => m.group(1)!.toLowerCase()).toList();
}

/// Extracts all [[wikilink]] targets from content.
List<String> extractWikilinks(String content) {
  final regex = RegExp(r'\[\[([^\]]+)\]\]');
  return regex.allMatches(content).map((m) => m.group(1)!.trim()).toList();
}

/// Gets the context snippet around a wikilink mention.
String? getWikilinkContext(String content, String target, {int radius = 60}) {
  final pattern = '[[$target]]';
  final idx = content.indexOf(pattern);
  if (idx == -1) return null;
  final start = (idx - radius).clamp(0, content.length);
  final end = (idx + pattern.length + radius).clamp(0, content.length);
  return '…${content.substring(start, end)}…';
}

/// Formats a DateTime as the daily note filename date string (YYYY-MM-DD).
String formatDailyDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// Returns whether a date string matches today.
bool isToday(String dateStr) {
  return dateStr == formatDailyDate(DateTime.now());
}

/// Processes [[wikilinks]] within markdown content to make them standard Markdown links.
String processWikilinks(String text) {
  return text.replaceAllMapped(RegExp(r'\[\[([^\]]+)\]\]'), (match) {
    final title = match.group(1)!;
    final encodedTitle = Uri.encodeComponent(title);
    return '[$title](wikilink:$encodedTitle)';
  });
}

/// Extension to parse HEX color strings safely.
extension ColorParsing on String {
  Color toColor({Color defaultColor = const Color(0xFF7C6FF7)}) {
    final cleanHex = replaceAll('#', '');
    final colorVal = int.tryParse('FF$cleanHex', radix: 16);
    return colorVal != null ? Color(colorVal) : defaultColor;
  }
}
