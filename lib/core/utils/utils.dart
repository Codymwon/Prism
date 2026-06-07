import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _uuid = Uuid();

/// Generates a new unique UUID v4.
String generateId() => _uuid.v4();

/// Returns the vault folder path (DocumentDirectory/prism_vaults/activeVault).
Future<String> getVaultPath() async {
  final prefs = await SharedPreferences.getInstance();
  String? baseDir = prefs.getString('baseVaultsDirectory');
  if (baseDir == null || baseDir.isEmpty) {
    final docDir = await getApplicationDocumentsDirectory();
    baseDir = p.join(docDir.path, 'prism_vaults');
  }
  final activeVault = prefs.getString('activeVaultName') ?? 'My Vault';
  final vaultPath = p.join(baseDir, activeVault);
  final vault = Directory(vaultPath);
  
  bool isNew = !await vault.exists();
  if (isNew) {
    await vault.create(recursive: true);
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
    } catch (e) {
      debugPrint('Error seeding default welcome notes: $e');
    }
  }

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
        }
        return value;
      }
    }
  }
  return null;
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
      // Preprocess non-code block content line-by-line
      final lines = parts[i].split('\n');
      final length = (lines.isNotEmpty && lines.last.isEmpty) ? lines.length - 1 : lines.length;
      for (int j = 0; j < length; j++) {
        if (lines[j].trim().isEmpty) {
          lines[j] = '\n&nbsp;\n';
        }
      }
      parts[i] = lines.join('\n');
    }
  }

  return parts.join('```');
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
