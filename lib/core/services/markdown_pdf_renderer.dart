import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/utils.dart' as utils;

/// Builds a [pw.Document] from a list of note pages.
///
/// Each page is rendered as a multi-page PDF section. Markdown is classified
/// line-by-line into headings, bullets, block quotes, code blocks, inline
/// images, and paragraphs. Frontmatter is stripped internally before rendering.
class MarkdownPdfRenderer {
  // Prevent instantiation — all methods are static.
  MarkdownPdfRenderer._();

  /// Builds and returns a [pw.Document] containing all [notes].
  ///
  /// [attachmentsDir] is used to resolve `![alt](path)` image references.
  /// [onProgress] reports a 0.0–1.0 fraction per note rendered.
  static pw.Document buildPdf(
    List<({String title, String body})> notes, {
    String? attachmentsDir,
    void Function(double progress)? onProgress,
  }) {
    final doc = pw.Document();

    for (var i = 0; i < notes.length; i++) {
      final note = notes[i];
      final widgets = _renderNote(note.title, note.body, attachmentsDir);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 60, vertical: 50),
          build: (context) => widgets,
        ),
      );

      onProgress?.call((i + 1) / notes.length);
    }

    return doc;
  }

  // ── Per-note rendering ─────────────────────────────────────────────────────

  static List<pw.Widget> _renderNote(
    String title,
    String rawBody,
    String? attachmentsDir,
  ) {
    final widgets = <pw.Widget>[];

    // Note title as H1
    widgets.add(pw.Header(
      level: 0,
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 22,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    ));
    widgets.add(pw.SizedBox(height: 8));

    // Strip frontmatter before rendering body
    final body = utils.stripFrontmatter(rawBody);
    final lines = body.split('\n');

    bool inCodeBlock = false;
    final codeLines = <String>[];

    for (var lineIdx = 0; lineIdx < lines.length; lineIdx++) {
      final line = lines[lineIdx];
      final trimmed = line.trim();

      // ── Code block toggle ────────────────────────────────────────────────
      if (trimmed.startsWith('```')) {
        if (inCodeBlock) {
          // Close code block
          inCodeBlock = false;
          widgets.add(_buildCodeBlock(codeLines.join('\n')));
          codeLines.clear();
        } else {
          inCodeBlock = true;
        }
        continue;
      }

      if (inCodeBlock) {
        codeLines.add(line);
        continue;
      }

      // ── Headings ─────────────────────────────────────────────────────────
      if (trimmed.startsWith('### ')) {
        widgets.add(pw.Header(
          level: 2,
          child: pw.Text(trimmed.substring(4), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ));
      } else if (trimmed.startsWith('## ')) {
        widgets.add(pw.Header(
          level: 1,
          child: pw.Text(trimmed.substring(3), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        ));
      } else if (trimmed.startsWith('# ')) {
        widgets.add(pw.Header(
          level: 0,
          child: pw.Text(trimmed.substring(2), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        ));
      }

      // ── Block quote ───────────────────────────────────────────────────────
      else if (trimmed.startsWith('> ')) {
        widgets.add(_buildBlockQuote(trimmed.substring(2)));
      }

      // ── Bullet list ────────────────────────────────────────────────────────
      else if (trimmed.startsWith('- ') || trimmed.startsWith('* ') || trimmed.startsWith('+ ')) {
        widgets.add(pw.Bullet(text: trimmed.substring(2)));
      }

      // ── Image ─────────────────────────────────────────────────────────────
      else if (trimmed.startsWith('![') && trimmed.contains('](') && trimmed.endsWith(')')) {
        final imageWidget = _tryBuildImage(trimmed, attachmentsDir);
        if (imageWidget != null) {
          widgets.add(imageWidget);
        } else {
          // Fall back to paragraph if image cannot be loaded
          widgets.add(pw.Paragraph(text: trimmed));
        }
      }

      // ── Horizontal rule ───────────────────────────────────────────────────
      else if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
        widgets.add(pw.Divider());
      }

      // ── Blank line ────────────────────────────────────────────────────────
      else if (trimmed.isEmpty) {
        widgets.add(pw.SizedBox(height: 6));
      }

      // ── Normal paragraph ──────────────────────────────────────────────────
      else {
        widgets.add(pw.Paragraph(text: trimmed));
      }
    }

    // Close any unclosed code block
    if (inCodeBlock && codeLines.isNotEmpty) {
      widgets.add(_buildCodeBlock(codeLines.join('\n')));
    }

    return widgets;
  }

  // ── Widget builders ────────────────────────────────────────────────────────

  static pw.Widget _buildCodeBlock(String code) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        code,
        style: const pw.TextStyle(
          fontSize: 9,
          // monospace fallback — pdf package uses Courier by default for fixed-width
        ),
      ),
    );
  }

  static pw.Widget _buildBlockQuote(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(left: 10, top: 4, bottom: 4),
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: PdfColors.grey500, width: 3),
        ),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontStyle: pw.FontStyle.italic,
          color: PdfColors.grey700,
        ),
      ),
    );
  }

  static pw.Widget? _tryBuildImage(String markdownLine, String? attachmentsDir) {
    if (attachmentsDir == null) return null;

    // Extract path from ![alt](path)
    final start = markdownLine.indexOf('](');
    final end = markdownLine.lastIndexOf(')');
    if (start == -1 || end == -1 || end <= start + 2) return null;

    final rawPath = markdownLine.substring(start + 2, end).trim();
    // Resolve relative to attachments dir
    final resolved = File(rawPath).isAbsolute ? rawPath : '$attachmentsDir/$rawPath';
    final file = File(resolved);

    if (!file.existsSync()) return null;

    try {
      final imageBytes = file.readAsBytesSync();
      final image = pw.MemoryImage(imageBytes);
      return pw.Center(
        child: pw.Image(image, fit: pw.BoxFit.contain, width: 400),
      );
    } catch (_) {
      return null;
    }
  }
}
