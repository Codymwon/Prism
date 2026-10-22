import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:markdown/markdown.dart' as md;

const _uuid = Uuid();

/// Generates a new unique UUID v4.
String generateId() => _uuid.v4();

/// Returns the vault folder path (DocumentDirectory/prism_vaults/activeVault).
Future<String> getVaultPath({SharedPreferences? prefs}) async {
  final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
  String? baseDir = resolvedPrefs.getString('baseVaultsDirectory');
  if (baseDir == null || baseDir.isEmpty) {
    final docDir = await getApplicationDocumentsDirectory();
    baseDir = p.join(docDir.path, 'prism_vaults');
  }
  final activeVault = resolvedPrefs.getString('activeVaultName') ?? 'My Vault';
  final vaultPath = p.join(baseDir, activeVault);
  await seedWelcomeNotes(vaultPath, prefs: resolvedPrefs);
  return vaultPath;
}

/// Seeds default welcome notes inside the vault if it is new or empty.
Future<void> seedWelcomeNotes(String vaultPath, {SharedPreferences? prefs}) async {
  // Always ensure the directory exists first to prevent database open/setup failures
  final vault = Directory(vaultPath);
  bool isNew = !await vault.exists();
  if (isNew) {
    await vault.create(recursive: true);
  }

  final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
  // Use a per-vault key so fresh/custom vaults get welcome notes seeded as well
  final vaultKey = 'welcomeNotesSeeded_${vaultPath.hashCode}';
  final alreadySeeded = resolvedPrefs.getBool(vaultKey) ?? false;
  if (alreadySeeded) {
    return;
  }

  // Seed default notes if new or completely empty
  bool isEmpty = true;
  try {
    if (!isNew) {
      await for (final _ in vault.list()) {
        isEmpty = false;
        break;
      }
    }
  } catch (_) {
    isEmpty = true;
  }

  if (isNew || isEmpty) {
    try {
      final welcomeFile = File(p.join(vaultPath, 'Welcome to Prism.md'));
      await welcomeFile.writeAsString(_welcomeNoteContent);

      final guideFile = File(p.join(vaultPath, 'Productivity Tools Guide.md'));
      await guideFile.writeAsString(_productivityGuideContent);

      await resolvedPrefs.setBool(vaultKey, true);
    } catch (e) {
      debugPrint('Error seeding default welcome notes: $e');
    }
  }
}


/// Converts a note title to a safe filename slug supporting Unicode letters and numbers.
String titleToSlug(String title) {
  var slug = title
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s_-]', unicode: true), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .trim();
  slug = slug.replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.isEmpty) {
    return 'untitled';
  }
  return slug;
}

/// Extracts the title from a markdown string.
/// Looks for frontmatter first, falls back to # heading, and finally to first non-empty line.
String extractTitle(String content) {
  final fmTitle = extractFrontmatterValue(content, 'title');
  if (fmTitle != null && fmTitle.isNotEmpty) {
    return fmTitle;
  }
  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('# ')) return trimmed.substring(2).trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return 'Untitled';
}

/// Strips the YAML frontmatter block from a markdown string if it exists.
String stripFrontmatter(String content) {
  final cleanContent = content.trimLeft();
  final hasFrontmatter = cleanContent.startsWith('---\n') || cleanContent.startsWith('---\r\n');
  if (!hasFrontmatter) return content;
  
  final lines = cleanContent.split('\n');
  int closingIndex = -1;
  for (int i = 1; i < lines.length; i++) {
    if (lines[i].trim() == '---') {
      closingIndex = i;
      break;
    }
  }
  
  if (closingIndex != -1) {
    final remainingLines = lines.sublist(closingIndex + 1);
    var rest = remainingLines.join('\n');
    // Also trim leading blank lines of body content if any
    if (rest.startsWith('\r\n')) {
      rest = rest.substring(2);
    } else if (rest.startsWith('\n')) {
      rest = rest.substring(1);
    }
    return rest;
  }
  return content;
}

/// Extracts the raw YAML frontmatter block (lines between '---' delimiters) if present.
String? extractFrontmatterBlock(String content) {
  final cleanContent = content.trimLeft();
  final hasFrontmatter = cleanContent.startsWith('---\n') || cleanContent.startsWith('---\r\n');
  if (!hasFrontmatter) return null;

  final lines = cleanContent.split('\n');
  int closingIndex = -1;
  for (int i = 1; i < lines.length; i++) {
    if (lines[i].trim() == '---') {
      closingIndex = i;
      break;
    }
  }

  if (closingIndex != -1) {
    return lines.sublist(1, closingIndex).join('\n');
  }
  return null;
}

/// Extracts a value for a specific key from YAML frontmatter if present.
String? extractFrontmatterValue(String content, String key) {
  final cleanContent = content.trimLeft();
  final hasFrontmatter = cleanContent.startsWith('---\n') || cleanContent.startsWith('---\r\n');
  if (!hasFrontmatter) return null;
  
  final lines = cleanContent.split('\n');
  int closingIndex = -1;
  for (int i = 1; i < lines.length; i++) {
    if (lines[i].trim() == '---') {
      closingIndex = i;
      break;
    }
  }
  
  if (closingIndex != -1) {
    final frontmatterLines = lines.sublist(1, closingIndex);
    final keyPattern = RegExp('^${RegExp.escape(key)}\\s*:\\s*(.*)\$');
    for (final line in frontmatterLines) {
      final match = keyPattern.firstMatch(line.trim());
      if (match != null) {
        var value = match.group(1)!.trim();
        if ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'"))) {
          value = value.substring(1, value.length - 1);
          value = value.replaceAll(r'\"', '"').replaceAll(r'\\', r'\');
        }
        return value;
      }
    }
  }
  return null;
}

/// Updates or injects frontmatter (with [id], [title], and optional [date]) into [body],
/// preserving all existing user-defined frontmatter keys, comments, and structure.
String updateOrInjectFrontmatter({
  String? existingFrontmatterBlock,
  required String body,
  String? id,
  required String title,
  String? date,
}) {
  final cleanTitle = title.trim().isEmpty ? 'Untitled' : title.trim();
  final escapedTitle = cleanTitle.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

  final lines = existingFrontmatterBlock != null
      ? existingFrontmatterBlock.split('\n')
      : <String>[];

  bool hasId = false;
  bool hasTitle = false;
  bool hasDate = false;

  final updatedLines = <String>[];
  final keyRegex = RegExp(r'^([a-zA-Z0-9_-]+)\s*:(.*)$');

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final match = keyRegex.firstMatch(line);
    if (match != null) {
      final key = match.group(1)!.trim();
      if (key == 'id' && id != null) {
        updatedLines.add('id: "$id"');
        hasId = true;
        continue;
      } else if (key == 'title') {
        updatedLines.add('title: "$escapedTitle"');
        hasTitle = true;
        continue;
      } else if (key == 'date') {
        if (date != null) {
          updatedLines.add('date: $date');
          hasDate = true;
        } else {
          updatedLines.add(line);
        }
        continue;
      }
    }
    updatedLines.add(line);
  }

  final injected = <String>[];
  if (id != null && !hasId) {
    injected.add('id: "$id"');
  }
  if (!hasTitle) {
    injected.add('title: "$escapedTitle"');
  }
  if (date != null && !hasDate) {
    injected.add('date: $date');
  }

  final finalFrontmatterLines = [...injected, ...updatedLines];

  while (finalFrontmatterLines.isNotEmpty && finalFrontmatterLines.first.trim().isEmpty) {
    finalFrontmatterLines.removeAt(0);
  }
  while (finalFrontmatterLines.isNotEmpty && finalFrontmatterLines.last.trim().isEmpty) {
    finalFrontmatterLines.removeLast();
  }

  final buffer = StringBuffer();
  buffer.writeln('---');
  for (final l in finalFrontmatterLines) {
    buffer.writeln(l);
  }
  buffer.writeln('---');
  buffer.writeln();
  buffer.write(body);

  return buffer.toString();
}

/// Counts words in a string.
int countWords(String text) {
  return text.trim().isEmpty
      ? 0
      : text.trim().split(RegExp(r'\s+')).length;
}

class _MetadataVisitor implements md.NodeVisitor {
  final Set<String> tags = {};
  final Set<String> wikilinks = {};

  final RegExp tagRegExp = RegExp(r'(?<!\w)#([a-zA-Z][a-zA-Z0-9_]*(?:\/[a-zA-Z][a-zA-Z0-9_]*)*)');
  final RegExp wikilinkRegExp = RegExp(r'\[\[([^\[\]\r\n]+)\]\]');

  @override
  bool visitElementBefore(md.Element element) {
    // Ignore code blocks (pre, code), link elements, and HTML blocks
    if (element.tag == 'pre' || element.tag == 'code' || element.tag == 'html' || element.tag == 'a') {
      return false;
    }
    return true;
  }

  @override
  void visitText(md.Text text) {
    // Only search for tags and wikilinks in visible text nodes
    for (final match in tagRegExp.allMatches(text.text)) {
      tags.add(match.group(1)!.toLowerCase());
    }
    for (final match in wikilinkRegExp.allMatches(text.text)) {
      wikilinks.add(match.group(1)!.trim());
    }
  }

  @override
  void visitElementAfter(md.Element element) {}
}

/// Extracts all #tags from markdown content (e.g. #productivity, #ideas).
List<String> extractTags(String content) {
  final cleanContent = stripFrontmatter(content).replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
  final document = md.Document();
  final nodes = document.parseLines(cleanContent.split('\n'));
  final visitor = _MetadataVisitor();
  for (final node in nodes) {
    node.accept(visitor);
  }
  return visitor.tags.toList();
}

/// Extracts all [[wikilink]] targets from content.
List<String> extractWikilinks(String content) {
  final cleanContent = stripFrontmatter(content).replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
  final document = md.Document();
  final nodes = document.parseLines(cleanContent.split('\n'));
  final visitor = _MetadataVisitor();
  for (final node in nodes) {
    node.accept(visitor);
  }
  return visitor.wikilinks.toList();
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
  final pattern = RegExp(r'(```[\s\S]*?```)|(`+[^`]+`+)|(\[\[([^\[\]\r\n]+)\]\])');
  return text.replaceAllMapped(pattern, (match) {
    if (match.group(1) != null) {
      return match.group(1)!;
    }
    if (match.group(2) != null) {
      return match.group(2)!;
    }
    final title = match.group(4)!;
    final encodedTitle = Uri.encodeComponent(title);
    return '[$title](wikilink:$encodedTitle)';
  });
}

/// Preprocesses markdown text by converting wikilinks and preserving blank lines
/// with `&nbsp;` (excluding fenced code blocks) to prevent checklist checkbox
/// rendering bugs and ensure correct empty line spacing in view mode.
String preprocessMarkdown(String text) {
  // 1. Process wikilinks
  final processedLinks = processWikilinks(text);

  // 2. Split by fenced code blocks to avoid modifying them
  final parts = processedLinks.split('```');
  for (int i = 0; i < parts.length; i++) {
    if (i % 2 == 0) {
      final processedPart = parts[i];
      if (processedPart.isEmpty) {
        continue;
      }
      final lines = processedPart.split('\n');
      final newLines = <String>[];

      bool isBlockBoundary(String line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) return false;
        // Thematic breaks (---, ***, ___)
        if (RegExp(r'^[-*_]{3,}$').hasMatch(trimmed)) return true;
        // Lines containing custom inline widgets also act as block boundaries
        // to prevent collapsing of surrounding text.
        final hasHashtag = RegExp(r'(?<!\w)#([a-zA-Z][a-zA-Z0-9_]*)').hasMatch(trimmed);
        final hasHighlight = RegExp(r'==[^=\n]+==').hasMatch(trimmed);
        final hasImage = RegExp(r'!\[[^\]\n]*\]\([^)\n]+\)').hasMatch(trimmed);
        return hasHashtag || hasHighlight || hasImage;
      }

      bool containsInlineWidget(String line) {
        final hasHashtag = RegExp(r'(?<!\w)#([a-zA-Z][a-zA-Z0-9_]*)').hasMatch(line);
        final hasHighlight = RegExp(r'==[^=\n]+==').hasMatch(line);
        final hasImage = RegExp(r'!\[[^\]\n]*\]\([^)\n]+\)').hasMatch(line);
        return hasHashtag || hasHighlight || hasImage;
      }

      final length = (lines.isNotEmpty && lines.last.isEmpty) ? lines.length - 1 : lines.length;

      for (int j = 0; j < length; j++) {
        final line = lines[j];

        // Check if current line contains a custom inline widget
        if (containsInlineWidget(line)) {
          // If previous line is not empty and is not a block boundary, insert a blank line
          if (newLines.isNotEmpty && newLines.last.trim().isNotEmpty && !isBlockBoundary(newLines.last)) {
            newLines.add('');
          }
        }

        // Also if the CURRENT line is a thematic break (---, ***, ___),
        // we must make sure the line before it is a blank line so it gets parsed as a horizontal rule,
        // and NOT a Setext heading underline!
        if (j > 0 && isBlockBoundary(line) && RegExp(r'^[-*_]{3,}$').hasMatch(line.trim())) {
          if (newLines.isNotEmpty && newLines.last.trim().isNotEmpty && !isBlockBoundary(newLines.last)) {
            newLines.add('');
          }
        }

        newLines.add(line);

        // If current line contains a custom inline widget, and the next line is not empty and not a block boundary,
        // we will insert a blank line after it.
        if (containsInlineWidget(line) && j < length - 1) {
          final nextLine = lines[j + 1];
          if (nextLine.trim().isNotEmpty && !isBlockBoundary(nextLine)) {
            newLines.add('');
          }
        }
      }

      if (lines.isNotEmpty && lines.last.isEmpty) {
        newLines.add('');
      }

      // Now replace empty lines with &nbsp; ONLY if they are NOT adjacent to a block-level boundary
      // Note: we don't replace the trailing empty line
      final blankCheckLength = (newLines.isNotEmpty && newLines.last.isEmpty) ? newLines.length - 1 : newLines.length;
      for (int j = 0; j < blankCheckLength; j++) {
        if (newLines[j].trim().isEmpty) {
          bool isAdjacentToBlock = false;
          if (j > 0 && isBlockBoundary(newLines[j - 1])) {
            isAdjacentToBlock = true;
          }
          if (j < blankCheckLength - 1 && isBlockBoundary(newLines[j + 1])) {
            isAdjacentToBlock = true;
          }

          if (!isAdjacentToBlock) {
            newLines[j] = '&nbsp;';
          }
        }
      }

      parts[i] = newLines.join('\n');
    }
  }

  final result = parts.join('```');
  return result;
}

/// Extension to parse HEX color strings safely.
extension ColorParsing on String {
  Color toColor({Color defaultColor = const Color(0xFF7C6FF7)}) {
    final cleanHex = replaceAll('#', '');
    final colorVal = int.tryParse('FF$cleanHex', radix: 16);
    return colorVal != null ? Color(colorVal) : defaultColor;
  }
}

const String _welcomeNoteContent = '''# Welcome to Prism

Welcome to your new digital garden! Prism is a premium, privacy-first markdown journal and notebook that runs entirely offline. All your notes are saved as standard `.md` text files inside your local vault folder.

## 🚀 Key Features

### 1. Relational Thinking with Wikilinks
Connect your thoughts dynamically. Try typing two brackets `[[` followed by the name of another note. For example:
- Read the [[Productivity Tools Guide]] to learn about dictation and macros.
- Create a new link: `[[My Future Ideas]]`. Tapping a link automatically creates and opens that note.
- Check the **Backlinks** section at the bottom of a note or open the **Graph Map** to see how your thoughts connect!

### 2. Voice-to-Text Dictation
Speak your mind. When editing a note, look at the formatting toolbar above your keyboard:
- Tap the 🎙️ **Microphone** icon to start recording.
- Talk naturally; your speech is transcribed offline in real-time.
- Tap **Done** (checkmark) to save. You can also choose to save the high-fidelity `.m4a` audio file directly in your vault as an attachment!

### 3. Customizable Macro Toolbar
Speed up your writing using macros. The horizontal toolbar has custom macro buttons to insert text variables:
- Tap `📅 Date` to insert today's date.
- Tap `☑️ Todo` to insert a markdown checkbox `[ ]`.
- Tap `📝 Summary` to insert a template block.
- Customize your own macros (up to 5!) in **Settings -> Custom Macros**. Define templates, custom tags, or dynamic dates.

### 4. Interactive Thought Graph
Tap the **Graph** tab in the bottom bar to see your notes as nodes and links as edges. Swipe, zoom, and explore your mind map dynamically.

### 5. Daily Reflection Logs
Tap the **Journal** tab in the bottom bar to start a daily reflection. Prism tracks your daily writing streak 🔥 and word count progress!

---
Tag this note to organize it: #tutorial #welcome
''';

const String _productivityGuideContent = '''# Productivity Tools Guide

This guide explains how to master the smart productivity tools in Prism: offline voice-to-text dictation and customizable macros.

## 🎙️ Offline Voice Dictation

Prism features built-in offline dictation that respects your privacy.
- **How to use**: Tap the text editor to open the keyboard. On the formatting toolbar, tap the 🎙️ icon.
- **Real-time transcription**: Speak clearly. The text is inserted right where your cursor is.
- **Audio Attachments**: When you finish dictation, Prism asks if you want to keep the raw audio file. If you save it, it is saved as an `.m4a` file in your vault's `attachments/` folder and linked in your note like this: `[Audio Note](attachments/audio_xxxx.m4a)`.

## ⚡ Custom Macros & Shortcuts

Save time on repetitive typing by creating custom shortcuts.
- **Accessing Macros**: Standard macros are available on the right side of the formatting toolbar.
- **Supported Variables**:
  - `{{date}}`: Resolves to today's date.
  - `{{time}}`: Resolves to the current time.
  - Standard text like `## Section Title` or `- [ ] ` for checklists.
- **How to Customize**:
  1. Navigate to the **Settings** tab.
  2. Select **Custom Macros**.
  3. Edit existing ones or add a new macro with a custom label (e.g. `🎯 Goal`) and template content.
  4. The macro will instantly appear on your editor toolbar!

---
Go back to the main page: [[Welcome to Prism]]

#tutorial #productivity #guide
''';

class DailyChecklistItem {
  final String label;
  final bool isChecked;
  final int lineIndex;
  const DailyChecklistItem(this.label, this.isChecked, this.lineIndex);
}

List<DailyChecklistItem> extractChecklist(String content) {
  final lines = content.split('\n');
  final items = <DailyChecklistItem>[];
  final checkboxRegExp = RegExp(r'^\s*[-*+]\s+\[([ xX])\](?:\s+(.*))?$');

  bool isInCodeBlock = false;
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();
    if (trimmed.startsWith('```')) {
      isInCodeBlock = !isInCodeBlock;
      continue;
    }
    if (isInCodeBlock) {
      continue;
    }

    final match = checkboxRegExp.firstMatch(line);
    if (match != null) {
      final isChecked = match.group(1)!.trim().isNotEmpty;
      final label = match.group(2)?.trim() ?? '';
      items.add(DailyChecklistItem(label, isChecked, i));
    }
  }
  return items;
}

String toggleMarkdownCheckboxAtLine(String content, int lineIndex) {
  final lines = content.split('\n');
  if (lineIndex < 0 || lineIndex >= lines.length) return content;

  final line = lines[lineIndex];
  final checkboxRegExp = RegExp(r'^(\s*[-*+]\s+\[)([ xX])(\])(?:\s+(.*))?$');
  final match = checkboxRegExp.firstMatch(line);

  if (match != null) {
    final prefix = match.group(1)!;
    final currentStatus = match.group(2)!;
    final suffix = line.substring(match.group(1)!.length + match.group(2)!.length);
    final newStatus = currentStatus.trim().isEmpty ? 'x' : ' ';
    lines[lineIndex] = '$prefix$newStatus$suffix';
  }
  return lines.join('\n');
}

String? extractPreviewImage(String content) {
  final cleanContent = stripFrontmatter(content);
  final lines = cleanContent.split('\n');
  final imageRegExp = RegExp(r'!\[.*?\]\((.*?)\)');

  bool isInCodeBlock = false;
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('```')) {
      isInCodeBlock = !isInCodeBlock;
      continue;
    }
    if (isInCodeBlock) {
      continue;
    }

    final match = imageRegExp.firstMatch(line);
    if (match != null) {
      return match.group(1);
    }
  }
  return null;
}
