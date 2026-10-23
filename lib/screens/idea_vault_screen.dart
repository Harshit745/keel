import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/idea.dart';
import '../services/hive_service.dart';
import '../services/export_service.dart';

class IdeaLockerScreen extends StatefulWidget {
  const IdeaLockerScreen({
    super.key,
    this.showBackButton = true,
  });

  final bool showBackButton;

  @override
  State<IdeaLockerScreen> createState() => _IdeaLockerScreenState();
}

class _IdeaLockerScreenState extends State<IdeaLockerScreen> {
  static const Color _bg = Color(0xFF080808);
  static const Color _card = Color(0xFF0D0D0D);
  static const Color _accent = Color(0xFFF0FF00);
  static const Color _muted = Color(0x73FFFFFF);

  final HiveService _hiveService = HiveService();
  final DateFormat _dateFormatter = DateFormat('MMM d, h:mm a');

  List<Idea> _allIdeas = <Idea>[];
  String _selectedCategory = 'All';

  final List<String> _categories = <String>[
    'All',
    'Product',
    'Marketing',
    'Growth',
    'Personal',
    'Other',
  ];

  final TextEditingController _ideaController = TextEditingController();
  String _newIdeaCategory = 'Product';

  @override
  void initState() {
    super.initState();
    _loadIdeas();
  }

  @override
  void dispose() {
    _ideaController.dispose();
    super.dispose();
  }

  Future<void> _loadIdeas() async {
    final List<Idea> ideas = await _hiveService.getAllIdeas();
    if (!mounted) return;
    setState(() {
      _allIdeas = ideas;
    });
  }

  List<Idea> get _filteredIdeas {
    if (_selectedCategory == 'All') return _allIdeas;
    return _allIdeas
        .where(
          (Idea i) =>
              i.category.toLowerCase() == _selectedCategory.toLowerCase(),
        )
        .toList();
  }

  Future<void> _togglePin(Idea idea) async {
    idea.isPinned = !idea.isPinned;
    await _hiveService.saveIdea(idea);
    _loadIdeas();
  }

  Future<void> _archiveIdea(Idea idea) async {
    idea.isArchived = true;
    await _hiveService.saveIdea(idea);
    _loadIdeas();
  }

  Future<void> _deleteIdea(Idea idea) async {
    await _hiveService.deleteIdea(idea.id);
    _loadIdeas();
  }

  String _resolveCategoryLabel(String? category) {
    if (category == null || category.isEmpty) {
      return 'Product';
    }

    return _categories.firstWhere(
      (String item) => item.toLowerCase() == category.toLowerCase(),
      orElse: () => 'Other',
    );
  }

  void _showIdeaSheet({Idea? idea}) {
    _ideaController.text = idea?.content ?? '';
    _newIdeaCategory = _resolveCategoryLabel(idea?.category);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        idea == null ? 'Lock in a new idea' : 'Edit idea',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ideaController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 4,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _bg,
                          hintText: "What's the idea?",
                          hintStyle: const TextStyle(color: Colors.white30),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories
                              .where((String c) => c != 'All')
                              .map((String c) {
                                final bool isSelected = _newIdeaCategory == c;
                                return GestureDetector(
                                  onTap: () =>
                                      setSheetState(() => _newIdeaCategory = c),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected ? _accent : _bg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: isSelected
                                          ? null
                                          : Border.all(
                                              color: Colors.white24,
                                              width: 1,
                                            ),
                                    ),
                                    child: Text(
                                      c,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () async {
                            if (_ideaController.text.trim().isEmpty) {
                              return;
                            }
                            final NavigatorState navigator = Navigator.of(
                              context,
                            );
                            final Idea updatedIdea = Idea(
                              id:
                                  idea?.id ??
                                  DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                              content: _ideaController.text.trim(),
                              createdAt: idea?.createdAt ?? DateTime.now(),
                              category: _newIdeaCategory.toLowerCase(),
                              isPinned: idea?.isPinned ?? false,
                              isArchived: idea?.isArchived ?? false,
                            );
                            await _hiveService.saveIdea(updatedIdea);
                            if (!mounted) {
                              return;
                            }
                            navigator.pop();
                            _loadIdeas();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: _accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'LOCK IT IN',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: _bg,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddSheet() => _showIdeaSheet();

  void _showOptions(Idea idea) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _card,
      builder: (BuildContext c) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.white),
                title: const Text(
                  'Edit idea',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showIdeaSheet(idea: idea);
                },
              ),
              ListTile(
                leading: Icon(
                  idea.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  color: Colors.white,
                ),
                title: Text(
                  idea.isPinned ? 'Unpin idea' : 'Pin idea',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _togglePin(idea);
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive, color: Colors.white),
                title: const Text(
                  'Archive idea',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _archiveIdea(idea);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text(
                  'Delete permanently',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteIdea(idea);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExportSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    "Export Ideas",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Choose format",
                    style: TextStyle(fontSize: 13, color: Colors.white54),
                  ),
                  const SizedBox(height: 24),
                  _buildExportOption(
                    icon: Icons.text_snippet_outlined,
                    bg: Colors.white.withValues(alpha: 0.06),
                    title: "Plain Text (.txt)",
                    subtitle: "One idea per line",
                    onTap: () => _exportAsText(context, _allIdeas),
                  ),
                  _buildExportOption(
                    icon: Icons.code_rounded,
                    bg: Color(0xFFF0FF00).withValues(alpha: 0.08),
                    iconColor: const Color(0xFFF0FF00),
                    title: "Markdown (.md)",
                    subtitle:
                        "Formatted with categories — opens in Notion, Obsidian",
                    onTap: () => _exportAsMarkdown(context, _allIdeas),
                  ),
                  _buildExportOption(
                    icon: Icons.table_chart_outlined,
                    bg: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                    iconColor: const Color(0xFF00E5FF),
                    title: "CSV Spreadsheet",
                    subtitle: "Open in Excel, Google Sheets",
                    onTap: () => _exportAsCsv(context, _allIdeas),
                  ),
                  _buildExportOption(
                    icon: Icons.ios_share_rounded,
                    bg: Color(0xFFF0FF00).withValues(alpha: 0.08),
                    iconColor: const Color(0xFFF0FF00),
                    title: "Share to any app",
                    subtitle: "WhatsApp, Telegram, Notes, Email...",
                    onTap: () => _shareIdeas(context, _allIdeas),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required Color bg,
    Color? iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white24,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAsText(BuildContext context, List<Idea> ideas) async {
    Navigator.pop(context);
    final text = ExportService.toPlainText(ideas);
    await ExportService.shareAsFile(
      text,
      'keel_ideas.txt',
      'text/plain',
      context,
    );
  }

  Future<void> _exportAsMarkdown(BuildContext context, List<Idea> ideas) async {
    Navigator.pop(context);
    final md = ExportService.toMarkdown(ideas);
    await ExportService.shareAsFile(
      md,
      'keel_ideas.md',
      'text/markdown',
      context,
    );
  }

  Future<void> _exportAsCsv(BuildContext context, List<Idea> ideas) async {
    Navigator.pop(context);
    final csv = ExportService.toCsv(ideas);
    await ExportService.shareAsFile(csv, 'keel_ideas.csv', 'text/csv', context);
  }

  Future<void> _shareIdeas(BuildContext context, List<Idea> ideas) async {
    Navigator.pop(context);
    final text = ExportService.toPlainText(ideas);
    await ExportService.shareAsText(text, context);
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: widget.showBackButton
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'IDEA LOCKER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'YOUR RAW INTEL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: Color.fromRGBO(255, 255, 255, 0.3),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.ios_share_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
                onPressed: _showExportSheet,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((String c) {
          final bool isSelected = _selectedCategory == c;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _accent : _card,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                c.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? _bg : Colors.white.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIdea(Idea idea) {
    return GestureDetector(
      onLongPress: () => _showOptions(idea),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: idea.isPinned
              ? Border.all(color: _accent.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    idea.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: _accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _dateFormatter.format(idea.createdAt),
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              idea.content,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.6,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                if (idea.isPinned)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.push_pin,
                      color: Colors.white30,
                      size: 16,
                    ),
                  ),
                _IdeaActionButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit idea',
                  onTap: () => _showIdeaSheet(idea: idea),
                ),
                const SizedBox(width: 8),
                _IdeaActionButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Delete idea',
                  color: Colors.redAccent,
                  onTap: () => _deleteIdea(idea),
                ),
                const SizedBox(width: 8),
                _IdeaActionButton(
                  icon: Icons.more_horiz,
                  tooltip: 'More options',
                  onTap: () => _showOptions(idea),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 80),
          Icon(
            Icons.lock_outline,
            color: Colors.white.withValues(alpha: 0.1),
            size: 48,
          ),
          const SizedBox(height: 24),
          const Text(
            'LOCKER EMPTY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color.fromRGBO(255, 255, 255, 0.2),
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildTopBar(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildCategories(),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _filteredIdeas.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                      itemCount: _filteredIdeas.length,
                      itemBuilder: (BuildContext context, int index) =>
                          _buildIdea(_filteredIdeas[index]),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: _showAddSheet,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.add, color: _bg),
        ),
      ),
    );
  }
}

class _IdeaActionButton extends StatelessWidget {
  const _IdeaActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color = Colors.white54,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}
