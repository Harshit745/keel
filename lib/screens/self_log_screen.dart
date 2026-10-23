import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/self_log.dart';
import '../services/hive_service.dart';
import '../services/score_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import '../widgets/save_success_overlay.dart';

class SelfLogScreen extends StatefulWidget {
  const SelfLogScreen({super.key});

  @override
  State<SelfLogScreen> createState() => _SelfLogScreenState();
}

class _SelfLogScreenState extends State<SelfLogScreen> {
  static const Color _bg = Color(0xFF080808);
  static const Color _card = Color(0xFF0D0D0D);
  static const Color _accent = Color(0xFF00E5FF);

  final HiveService _hiveService = HiveService();
  final DateFormat _dateFormatter = DateFormat('EEEE, MMM d');
  final NumberFormat _currencyFormatter = NumberFormat('#,##,###');

  bool _isLoading = true;
  bool _isSaving = false;
  SelfLog? _existingLog;

  double _sleepHours = 0;
  int _energyLevel = 3;
  int _moodRating = 3;
  double _moneySpent = 0;
  double _dailyBudget = 1000;
  bool _exercised = false;
  final TextEditingController _journalController = TextEditingController();

  static const List<double> _sleepPicks = <double>[5, 6, 7, 8, 9];
  static const List<double> _moneyChips = <double>[50, 100, 250, 500];

  final List<String> _energyLabels = <String>[
    'Low',
    'Low',
    'Okay',
    'Good',
    'Peak',
  ];
  final List<String> _moodLabels = <String>[
    'Awful',
    'Awful',
    'Meh',
    'Good',
    'Great',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final budget = await UserService.getDailyBudget();
    final log = await _hiveService.getSelfLogForDate(DateTime.now());

    if (!mounted) return;

    setState(() {
      _dailyBudget = budget;
      if (log != null) {
        _existingLog = log;
        _sleepHours = log.sleepHours;
        _energyLevel = log.energyLevel;
        _moodRating = log.moodRating;
        _moneySpent = log.moneySpent;
        _exercised = log.exercised;
        _journalController.text = log.journalEntry;
      }
      _isLoading = false;
    });
  }

  int get _previewScore => ScoreService.calculateSelfScore(
    sleepHours: _sleepHours,
    energyLevel: _energyLevel,
    moodRating: _moodRating,
    moneySpent: _moneySpent,
    dailyBudget: _dailyBudget,
    exercised: _exercised,
  );

  Future<void> _saveLog() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final SelfLog log = SelfLog(
      id: _existingLog?.id ?? SelfLog.keyForDate(DateTime.now()),
      date: _existingLog?.date ?? DateTime.now(),
      sleepHours: _sleepHours,
      energyLevel: _energyLevel,
      moodRating: _moodRating,
      moneySpent: _moneySpent,
      dailyBudget: _dailyBudget,
      exercised: _exercised,
      journalEntry: _journalController.text.trim(),
    );

    final OverlayState overlay = Overlay.of(context, rootOverlay: true);
    await _hiveService.saveSelfLog(log);

    // Nudges
    await NotificationService.checkAndNudge(
      type: 'self',
      value: log.selfScore,
      previousValue: _existingLog?.selfScore,
    );

    SaveSuccessOverlay.show(overlay, message: 'Self Log Saved!');

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
                'LOG SELF',
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

  Widget _buildSleep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'SLEEP HOURS',
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
            _sleepHours.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            activeTrackColor: _accent,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
            thumbColor: _accent,
            overlayColor: _accent.withValues(alpha: 0.12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: _sleepHours,
            min: 0,
            max: 12,
            divisions: 24,
            onChanged: (double value) => setState(() => _sleepHours = value),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _sleepPicks.map((double val) {
              final bool isSelected = _sleepHours == val;
              return GestureDetector(
                onTap: () => setState(() => _sleepHours = val),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? _accent : _card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? _accent
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    '${val.toInt()}h',
                    style: TextStyle(
                      color: isSelected ? _bg : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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

  Widget _buildEnergyMood() {
    return Column(
      children: [
        _buildMetricSelector(
          'ENERGY',
          _energyLevel,
          _energyLabels,
          _accent,
          (val) => setState(() => _energyLevel = val),
        ),
        const SizedBox(height: 24),
        _buildMetricSelector(
          'MOOD',
          _moodRating,
          _moodLabels,
          _accent,
          (val) => setState(() => _moodRating = val),
        ),
      ],
    );
  }

  Widget _buildMetricSelector(
    String label,
    int value,
    List<String> labels,
    Color color,
    Function(int) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(255, 255, 255, 0.35),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final val = index + 1;
            final isSelected = value == val;
            return GestureDetector(
              onTap: () => onSelect(val),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? color : _card,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isSelected ? _bg : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              labels[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                color: Color.fromRGBO(255, 255, 255, 0.2),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              labels[4].toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                color: Color.fromRGBO(255, 255, 255, 0.2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMoney() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'DAILY SPEND (INR)',
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
            '₹${_moneySpent.round()}',
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
            value: _moneySpent.clamp(0, _dailyBudget * 1.5),
            min: 0,
            max: _dailyBudget * 1.5,
            divisions: 100,
            onChanged: (val) => setState(() => _moneySpent = val),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              ' ₹${_currencyFormatter.format((_dailyBudget - _moneySpent).clamp(0, _dailyBudget).round())} REMAINING',
              style: TextStyle(
                fontSize: 10,
                color: _accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'LIMIT: ₹${_currencyFormatter.format(_dailyBudget.round())}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _moneyChips.map((double val) {
              return GestureDetector(
                onTap: () => setState(() => _moneySpent += val),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    '+₹${val.toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'MOVED THE BODY?',
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
              child: _boolCardCinematic(true, _exercised, 'YES', _accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _boolCardCinematic(
                false,
                !_exercised,
                'NO',
                Colors.transparent,
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
    Color selectedColor,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _exercised = isYes),
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

  Widget _buildReflection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'DAILY REFLECTION',
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
            controller: _journalController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 2,
            maxLength: 80,
            decoration: const InputDecoration(
              hintText: 'Today was...',
              hintStyle: TextStyle(color: Color.fromRGBO(255, 255, 255, 0.2)),
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
                'ESTIMATED SELF SCORE',
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
                    _buildSleep(),
                    const SizedBox(height: 48),
                    _buildEnergyMood(),
                    const SizedBox(height: 48),
                    _buildMoney(),
                    const SizedBox(height: 48),
                    _buildBody(),
                    const SizedBox(height: 48),
                    _buildReflection(),
                    const SizedBox(height: 48),
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
