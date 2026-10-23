import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/idea.dart';

class ExportService {
  // Plain text: one idea per line with category prefix
  static String toPlainText(List<Idea> ideas) {
    final buf = StringBuffer();
    buf.writeln('MY KEEL IDEAS');
    buf.writeln(
      'Exported from Keel — ${DateTime.now().toLocal().toString().substring(0, 10)}',
    );
    buf.writeln('─' * 40);
    buf.writeln();
    final pinned = ideas.where((i) => i.isPinned).toList();
    final rest = ideas.where((i) => !i.isPinned).toList();
    if (pinned.isNotEmpty) {
      buf.writeln('★ PINNED');
      for (final idea in pinned) {
        buf.writeln('[${idea.category.toUpperCase()}] ${idea.content}');
      }
      buf.writeln();
    }
    for (final idea in rest) {
      buf.writeln('[${idea.category.toUpperCase()}] ${idea.content}');
    }
    return buf.toString();
  }

  // Markdown: sections by category, pinned first
  static String toMarkdown(List<Idea> ideas) {
    final buf = StringBuffer();
    buf.writeln('# My Keel Ideas');
    buf.writeln(
      '> Exported from Keel · ${DateTime.now().toLocal().toString().substring(0, 10)}',
    );
    buf.writeln();
    final pinned = ideas.where((i) => i.isPinned).toList();
    if (pinned.isNotEmpty) {
      buf.writeln('## ★ Pinned');
      for (final idea in pinned) {
        buf.writeln('- **[${idea.category}]** ${idea.content}');
      }
      buf.writeln();
    }
    final categories = ['product', 'marketing', 'growth', 'personal', 'other'];
    for (final cat in categories) {
      final catIdeas = ideas
          .where((i) => i.category == cat && !i.isPinned)
          .toList();
      if (catIdeas.isEmpty) continue;
      buf.writeln('## ${cat[0].toUpperCase()}${cat.substring(1)}');
      for (final idea in catIdeas) {
        buf.writeln('- ${idea.content}');
      }
      buf.writeln();
    }
    return buf.toString();
  }

  // CSV: id, category, content, pinned, createdAt
  static String toCsv(List<Idea> ideas) {
    final buf = StringBuffer();
    buf.writeln('id,category,content,pinned,created_at');
    for (final idea in ideas) {
      final content = idea.content.replaceAll('"', '""');
      buf.writeln(
        '${idea.id},${idea.category},"$content",${idea.isPinned},${idea.createdAt.toIso8601String()}',
      );
    }
    return buf.toString();
  }

  // Write to temp file and share or open share sheet
  static Future<void> shareAsFile(
    String content,
    String filename,
    String mimeType,
    BuildContext context,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path, mimeType: mimeType)],
        subject: 'My Keel Ideas',
      ),
    );
  }

  static Future<void> shareAsText(String content, BuildContext context) async {
    await SharePlus.instance.share(
      ShareParams(text: content, subject: 'My Keel Ideas'),
    );
  }
}
