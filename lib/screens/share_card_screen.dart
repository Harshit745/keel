import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/build_log.dart';
import '../models/self_log.dart';
import '../services/ai_service.dart';
import '../services/hive_service.dart';
import '../services/score_service.dart';
import '../widgets/score_card_widget.dart';

class ShareCardScreen extends StatefulWidget {
  const ShareCardScreen({super.key});

  @override
  State<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends State<ShareCardScreen> {
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _accent = Color(0xFFF0FF00);

  final HiveService _hiveService = HiveService();
  final DateFormat _weekFormatter = DateFormat('MMM dd');
  final GlobalKey _scoreCardKey = GlobalKey();

  bool _isLoadingData = true;
  bool _isLoadingInsight = true;
  bool _isSharing = false;

  int _buildScore = 0;
  int _selfScore = 0;
  int _founderScore = 0;
  String _winOfDay = '';
  String _weekLabel = '';
  String _aiInsight = '';

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    final DateTime now = DateTime.now();
    final List<BuildLog> buildLogs = await _hiveService.getBuildLogsForWeek(
      now,
    );
    final List<SelfLog> selfLogs = await _hiveService.getSelfLogsForWeek(now);

    final DateTime startOfWeek = _startOfWeek(now);
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    final BuildLog? todayBuild = await _hiveService.getBuildLogForDate(now);

    int buildTotal = 0;
    int selfTotal = 0;
    int founderTotal = 0;

    int validDays = 0;
    for (int i = 0; i < 7; i++) {
      final DateTime d = startOfWeek.add(Duration(days: i));
      final BuildLog? b = buildLogs
          .where(
            (BuildLog l) =>
                l.date.year == d.year &&
                l.date.month == d.month &&
                l.date.day == d.day,
          )
          .firstOrNull;
      final SelfLog? s = selfLogs
          .where(
            (SelfLog l) =>
                l.date.year == d.year &&
                l.date.month == d.month &&
                l.date.day == d.day,
          )
          .firstOrNull;

      if (b != null || s != null) {
        validDays++;
        final int bs = b?.buildScore ?? 0;
        final int ss = s?.selfScore ?? 0;
        buildTotal += bs;
        selfTotal += ss;
        founderTotal += ScoreService.calculateFounderScore(bs, ss);
      }
    }

    if (validDays > 0) {
      _buildScore = (buildTotal / validDays).round();
      _selfScore = (selfTotal / validDays).round();
      _founderScore = (founderTotal / validDays).round();
    }

    if (!mounted) return;

    setState(() {
      _winOfDay = todayBuild?.winOfDay ?? '';
      _weekLabel =
          '${_weekFormatter.format(startOfWeek)} – ${_weekFormatter.format(endOfWeek)}';
      _isLoadingData = false;
      _isLoadingInsight = true;
    });

    final String insight = await AiService.generateWeeklyInsight(
      buildScore: _buildScore,
      selfScore: _selfScore,
      founderScore: _founderScore,
    );

    if (!mounted) return;

    setState(() {
      _aiInsight = insight;
      _isLoadingInsight = false;
    });
  }

  DateTime _startOfWeek(DateTime date) {
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  Future<void> _shareCard() async {
    if (_isSharing || _isLoadingData) return;
    setState(() => _isSharing = true);

    try {
      final RenderRepaintBoundary? boundary =
          _scoreCardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('capture_failed');
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List? imageBytes = byteData?.buffer.asUint8List();
      if (imageBytes == null) throw Exception('bytes_failed');

      final Directory tempDirectory = await getTemporaryDirectory();
      final File file = File(
        '${tempDirectory.path}/keel-week-${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(imageBytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(files: <XFile>[XFile(file.path)], text: 'My FounderWeek'),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share your week right now.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 44,
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'FounderWeek',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Spacer(),
            if (_isLoadingData)
              const CircularProgressIndicator(color: _accent)
            else
              Center(
                child: ScoreCardWidget(
                  repaintKey: _scoreCardKey,
                  founderScore: _founderScore,
                  buildScore: _buildScore,
                  selfScore: _selfScore,
                  winOfDay: _winOfDay,
                  weekLabel: _weekLabel,
                  aiInsight: _aiInsight,
                  isLoadingInsight: _isLoadingInsight,
                ),
              ),
            const Spacer(),
            if (!_isLoadingData)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSharing ? null : _shareCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isSharing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Share my week',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
