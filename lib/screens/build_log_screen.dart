import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/build_log.dart';
import '../services/hive_service.dart';
import '../services/score_service.dart';
import '../services/notification_service.dart';
import '../widgets/save_success_overlay.dart';

class BuildLogScreen extends StatefulWidget {
  const BuildLogScreen({super.key});

  @override
  State<BuildLogScreen> createState() => _BuildLogScreenState();
}

class _BuildLogScreenState extends State<BuildLogScreen> {
  static const Color _bg = Color(0xFF080808);
  static const Color _card = Color(0xFF0D0D0D);
  static const Color _accent = Color(0xFFF0FF00);

  final HiveService _hiveService = HiveService();
  final DateFormat _dateFormatter = DateFormat('EEEE, MMM d');

  bool _isLoading = true;
  bool _isSaving = false;

  BuildLog? _existingLog;

  int _tasksShipped = 0;
  bool _movedNeedle = false;
  bool _talkedToUser = false;
  double _revenue = 0;
  final TextEditingController _winController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  @override
  void dispose() {
    _winController.dispose();
    super.dispose();
  }

  Future<void> _loadToday() async {
    final BuildLog? log = await _hiveService.getBuildLogForDate(DateTime.now());
    if (!mounted) return;

    setState(() {
      _existingLog = log;
      _tasksShipped = log?.tasksShipped ?? 0;
      _movedNeedle = log?.movedNeedle ?? false;
      _talkedToUser = log?.talkedToUser ?? false;
      _revenue = log?.revenueAdded ?? 0;
      _winController.text = log?.winOfDay ?? '';
      _isLoading = false;
    });
  }

  int get _previewScore => ScoreService.calculateBuildScore(
    tasksShipped: _tasksShipped,
    talkedToUser: _talkedToUser,
    movedNeedle: _movedNeedle,
    revenueAdded: _revenue,
  );

  Future<void> _saveLog() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final BuildLog log = BuildLog(
      id: _existingLog?.id ?? BuildLog.keyForDate(DateTime.now()),
      date: _existingLog?.date ?? DateTime.now(),
      tasksShipped: _tasksShipped,
      talkedToUser: _talkedToUser,
      movedNeedle: _movedNeedle,
      revenueAdded: _revenue,
      winOfDay: _winController.text.trim(),
      ideasCaptured: _existingLog?.ideasCaptured ?? <String>[],
    );

    final OverlayState overlay = Overlay.of(context, rootOverlay: true);
    await _hiveService.saveBuildLog(log);

    // Nudges
    if (_movedNeedle) {
      await NotificationService.checkAndNudge(type: 'needle', value: true);
    }
    await NotificationService.checkAndNudge(
      type: 'build',
      value: log.buildScore,
      previousValue: _existingLog?.buildScore,
    );

    SaveSuccessOverlay.show(overlay, message: 'Build Log Saved!');

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Column(
            children: <Widget>[
              const Text(
                'LOG BUILD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _dateFormatter.format(DateTime.now()).toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.3),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTasks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'TASKS SHIPPED',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(255, 255, 255, 0.35),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _countBtn(Icons.remove, () {
              if (_tasksShipped > 0) setState(() => _tasksShipped--);
            }),
            Text(
              '$_tasksShipped',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
            _countBtn(Icons.add, () {
              if (_tasksShipped < 20) setState(() => _tasksShipped++);
            }),
          ],
        ),
      ],
    );
  }

  Widget _countBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _card,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildNeedle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'MOVED THE NEEDLE?',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(255, 255, 255, 0.35),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: _boolCardCinematic(true, _movedNeedle, 'YES', _accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _boolCardCinematic(
                false,
                !_movedNeedle,
                'NO',
                Colors.transparent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUsers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'USER CONVERSATIONS?',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(255, 255, 255, 0.35),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: _boolCardCinematic(
                true,
                _talkedToUser,
                'YES',
                _accent,
                onTap: () => setState(() => _talkedToUser = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _boolCardCinematic(
                false,
                !_talkedToUser,
                'NO',
                Colors.transparent,
                onTap: () => setState(() => _talkedToUser = false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _boolCardCinematic(
    bool isYes,
    bool isSelected,
    String text,
    Color selectedColor, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () => setState(() => _movedNeedle = isYes),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _accent : _card,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? _bg : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildRevenue() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'REVENUE ADDED (INR)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(255, 255, 255, 0.35),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            '₹${_revenue.round()}',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _accent,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
            thumbColor: _accent,
            overlayColor: _accent.withValues(alpha: 0.12),
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: _revenue.clamp(0, 10000),
            min: 0,
            max: 10000,
            divisions: 100,
            onChanged: (val) => setState(() => _revenue = val),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [0, 500, 1000, 5000, 10000].map((amount) {
              final selected = _revenue.round() == amount;
              return GestureDetector(
                onTap: () => setState(() => _revenue = amount.toDouble()),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? _accent : _card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? _accent
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    '₹$amount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: selected ? _bg : Colors.white,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'WIN OF THE DAY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(255, 255, 255, 0.35),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: _winController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 2,
            maxLength: 80,
            decoration: InputDecoration(
              hintText: 'One thing you actually crushed...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
              contentPadding: EdgeInsets.all(16),
              border: InputBorder.none,
              counterText: "",
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScorePreview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'ESTIMATED BUILD SCORE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Color.fromRGBO(255, 255, 255, 0.4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_previewScore',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
          Text(
            ScoreService.getScoreEmoji(_previewScore),
            style: const TextStyle(fontSize: 32),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildTasks(),
                    const SizedBox(height: 40),
                    _buildNeedle(),
                    const SizedBox(height: 40),
                    _buildUsers(),
                    const SizedBox(height: 40),
                    _buildRevenue(),
                    const SizedBox(height: 40),
                    _buildWin(),
                    const SizedBox(height: 40),
                    _buildScorePreview(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GestureDetector(
          onTap: _saveLog,
          child: Container(
            height: 54,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _bg,
                    ),
                  )
                : const Text(
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
    );
  }
}
