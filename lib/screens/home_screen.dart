import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/build_log.dart';
import '../models/idea.dart';
import '../models/self_log.dart';
import '../services/hive_service.dart';
import '../services/score_service.dart';
import '../services/streak_service.dart';
import '../services/user_service.dart';
import '../widgets/streak_badge.dart';
import 'ai_chat_screen.dart';
import 'build_log_screen.dart';
import 'idea_vault_screen.dart';
import 'self_log_screen.dart';
import 'share_card_screen.dart';
import 'settings_screen.dart';
import 'weekly_report_screen.dart';
import '../services/subscription_service.dart';

enum _HomePillar { build, self }
enum _LaunchTab { today, locker, reports, profile }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const Color _backgroundColor = Color(0xFF080808);
  static const Color _cardColor = Color(0xFF0D0D0D);
  static const Color _accent = Color(0xFFF0FF00);
  static const Color _selfAccent = Color(0xFF00E5FF);
  static const Color _mutedWhite = Color(0x73FFFFFF); // 45% white

  final HiveService _hiveService = HiveService();
  final TextEditingController _ideaController = TextEditingController();

  bool _isLoading = true;
  BuildLog? _todayBuildLog;
  SelfLog? _todaySelfLog;
  List<BuildLog> _weekBuildLogs = <BuildLog>[];
  List<SelfLog> _weekSelfLogs = <SelfLog>[];
  List<Idea> _recentIdeas = <Idea>[];

  _HomePillar _selectedPillar = _HomePillar.build;
  _LaunchTab _selectedTab = _LaunchTab.today;

  String _userName = 'Founder';
  String _projectName = 'your startup';
  String _goal = '';
  String _currentPriority = 'Protect momentum';
  String _todayBuildFocus = '';
  String _todaySelfFocus = '';
  User? _firebaseUser;
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserProfile();
    _loadStreakData();
    _loadHomeData(showLoader: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUserProfile(); // re-fetch budget on resume
      _loadHomeData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ideaController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeData({bool showLoader = false}) async {
    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final DateTime now = DateTime.now();
    final BuildLog? todayBuild = await _hiveService.getBuildLogForDate(now);
    SelfLog? todaySelf = await _hiveService.getSelfLogForDate(now);

    // Sync budget if changed in settings
    final double currentBudget = await UserService.getDailyBudget();
    if (todaySelf != null && todaySelf.dailyBudget != currentBudget) {
      todaySelf.dailyBudget = currentBudget;
      todaySelf.selfScore = ScoreService.calculateSelfScore(
        sleepHours: todaySelf.sleepHours,
        energyLevel: todaySelf.energyLevel,
        moodRating: todaySelf.moodRating,
        moneySpent: todaySelf.moneySpent,
        dailyBudget: currentBudget,
        exercised: todaySelf.exercised,
      );
      await _hiveService.saveSelfLog(todaySelf);
    }

    final List<BuildLog> weekBuild = await _hiveService.getBuildLogsForWeek(
      now,
    );
    final List<SelfLog> weekSelf = await _hiveService.getSelfLogsForWeek(now);
    final List<Idea> ideas = await _hiveService.getAllIdeas();

    if (!mounted) {
      return;
    }

    final List<int> dailyScores = <int>[];
    for (int i = 0; i < 7; i++) {
      final DateTime d = _startOfWeek(now).add(Duration(days: i));
      final BuildLog? b = weekBuild
          .where((BuildLog l) => _isSameDay(l.date, d))
          .firstOrNull;
      final SelfLog? s = weekSelf
          .where((SelfLog l) => _isSameDay(l.date, d))
          .firstOrNull;
      if (b != null || s != null) {
        dailyScores.add(
          ScoreService.calculateFounderScore(
            b?.buildScore ?? 0,
            s?.selfScore ?? 0,
          ),
        );
      }
    }

    setState(() {
      _todayBuildLog = todayBuild;
      _todaySelfLog = todaySelf;
      _weekBuildLogs = weekBuild;
      _weekSelfLogs = weekSelf;
      _recentIdeas = ideas.take(2).toList();
      _isLoading = false;
    });
  }

  DateTime _startOfWeek(DateTime date) {
    final DateTime d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _loadStreakData() async {
    final int currentStreak = await StreakService.getCurrentStreak();
    if (!mounted) {
      return;
    }
    setState(() {
      _currentStreak = currentStreak;
    });
  }

  Future<void> _loadUserProfile() async {
    final String name = await UserService.getName();
    final String project = await UserService.getProject();
    final String goal = await UserService.getGoal();
    final String currentPriority = await UserService.getCurrentPriority();
    final String todayBuildFocus = await UserService.getTodayBuildFocus();
    final String todaySelfFocus = await UserService.getTodaySelfFocus();
    final double budget = await UserService.getDailyBudget();
    final User? user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() {
        _firebaseUser = user;
        _userName = name;
        _projectName = project;
        _goal = goal;
        _currentPriority = currentPriority;
        _todayBuildFocus = todayBuildFocus;
        _todaySelfFocus = todaySelfFocus;
        _dailyBudget = budget;
      });
    }
  }

  double _dailyBudget = 1000;

  int get _todayBuildScore => _todayBuildLog?.buildScore ?? 0;
  int get _todaySelfScore => _todaySelfLog?.selfScore ?? 0;
  int get _todayKeelScore =>
      ScoreService.calculateFounderScore(_todayBuildScore, _todaySelfScore);

  String get _resolvedBuildFocus =>
      _todayBuildFocus.isNotEmpty ? _todayBuildFocus : _defaultBuildFocus();

  String get _resolvedSelfFocus =>
      _todaySelfFocus.isNotEmpty ? _todaySelfFocus : _defaultSelfFocus();

  String _defaultBuildFocus() {
    if (_currentPriority.isNotEmpty && _currentPriority != 'Protect momentum') {
      return _currentPriority;
    }
    switch (_goal) {
      case 'pre_idea':
        return 'Talk to one real user and capture the strongest problem.';
      case 'pre_revenue':
        return 'Ship one step that moves $_projectName closer to usable.';
      case 'revenue':
        return 'Improve the part of $_projectName that paying users feel.';
      case 'scaling':
        return 'Remove one bottleneck that is slowing the system down.';
      default:
        return 'Ship one concrete task that matters.';
    }
  }

  String _defaultSelfFocus() {
    if (_todaySelfScore < 45) {
      return 'Protect recovery before forcing more output.';
    }
    if (_todayBuildScore >= 70 && _todaySelfScore < 60) {
      return 'Keep momentum, but defend sleep and energy tonight.';
    }
    return 'Keep your floor high: sleep, movement, and budget discipline.';
  }

  Future<void> _openShareCard() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const ShareCardScreen(),
      ),
    );
  }

  Future<void> _showFocusEditor({required bool isBuild}) async {
    final TextEditingController controller = TextEditingController(
      text: isBuild ? _resolvedBuildFocus : _resolvedSelfFocus,
    );
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: _cardColor,
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
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      isBuild ? 'Build focus' : 'Self guardrail',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isBuild
                          ? 'Define the one outcome that matters most today.'
                          : 'Set the one recovery move that keeps you stable.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _backgroundColor,
                        hintText: isBuild
                            ? 'Ship onboarding copy'
                            : 'Sleep before midnight',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final String value = controller.text.trim();
                          if (isBuild) {
                            await UserService.setTodayBuildFocus(value);
                          } else {
                            await UserService.setTodaySelfFocus(value);
                          }
                          if (!mounted) return;
                          setState(() {
                            if (isBuild) {
                              _todayBuildFocus = value;
                            } else {
                              _todaySelfFocus = value;
                            }
                          });
                          if (!sheetContext.mounted) return;
                          Navigator.pop(sheetContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: _backgroundColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Save focus',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    controller.dispose();
  }

  Future<void> _showAccountSheet() async {
    final User? user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : _userName;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      _buildAvatar(radius: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'No email',
                              style: const TextStyle(
                                fontSize: 13,
                                color: _mutedWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 0.5,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        Navigator.pop(context);
                        final isPro = await SubscriptionService.isPro();
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => WeeklyReportScreen(isPro: isPro),
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 12,
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.insights_rounded,
                              color: _accent,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Weekly Report',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  color: _accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white.withValues(alpha: 0.45),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        Navigator.pop(context);
                        await _openShareCard();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 12,
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.share,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Share your week',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white.withValues(alpha: 0.45),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        Navigator.pop(context);
                        final bool? didUpdate = await Navigator.of(context)
                            .push<bool>(
                              MaterialPageRoute<bool>(
                                builder: (BuildContext context) =>
                                    const SettingsScreen(),
                              ),
                            );
                        if (didUpdate == true && mounted) {
                          await _loadUserProfile();
                          await _loadHomeData();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 12,
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.settings_outlined,
                              color: _mutedWhite,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white.withValues(alpha: 0.45),
                              size: 14,
                            ),
                          ],
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
  }

  Widget _buildAvatar({double radius = 18}) {
    if (_firebaseUser?.photoURL != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: _cardColor,
        backgroundImage: NetworkImage(_firebaseUser!.photoURL!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _accent.withValues(alpha: 0.2),
      child: Text(
        UserService.getInitials(_userName),
        style: TextStyle(
          color: _accent,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Keel',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Good morning, $_userName',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              if (_currentStreak > 0)
                StreakBadge(
                  streak: _currentStreak,
                  longestStreak: _currentStreak,
                  freezes: 0,
                ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTab = _LaunchTab.profile;
                  });
                },
                child: _buildAvatar(radius: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillarSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _buildPillarTab(
              label: 'Build',
              pillar: _HomePillar.build,
              indicatorColor: _accent,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildPillarTab(
              label: 'Self',
              pillar: _HomePillar.self,
              indicatorColor: _selfAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarTab({
    required String label,
    required _HomePillar pillar,
    required Color indicatorColor,
  }) {
    final bool isSelected = _selectedPillar == pillar;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _selectedPillar = pillar;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 2,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isSelected ? indicatorColor : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreHero() {
    final int currentScore = _selectedPillar == _HomePillar.build
        ? _todayBuildScore
        : _todaySelfScore;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              tween: Tween<double>(begin: 0, end: currentScore.toDouble()),
              builder: (context, value, child) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(
                    fontSize: 96,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -4,
                    color: Colors.white,
                    height: 1,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              ScoreService.getScoreLabel(currentScore).toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: _selectedPillar == _HomePillar.build
                    ? _accent
                    : _selfAccent,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Week of ${DateFormat('MMM dd').format(_startOfWeek(DateTime.now()))}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySignalCard() {
    final String trend = ScoreService.getKeelState(
      buildScore: _todayBuildScore,
      selfScore: _todaySelfScore,
    );
    final String insight = ScoreService.getScoreInsight(
      buildScore: _todayBuildScore,
      selfScore: _todaySelfScore,
      keelScore: _todayKeelScore,
    );
    final String nextAction = ScoreService.getNextAction(
      buildScore: _todayBuildScore,
      selfScore: _todaySelfScore,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Text(
                  'TODAY',
                  style: TextStyle(
                    color: Color.fromRGBO(255, 255, 255, 0.35),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  'Keel Score $_todayKeelScore',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              trend,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              insight,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 13,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: _accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      nextAction,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayFocusCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'TODAY FOCUS',
            style: TextStyle(
              color: Color.fromRGBO(255, 255, 255, 0.35),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildFocusTile(
            title: 'Build intention',
            value: _resolvedBuildFocus,
            color: _accent,
            icon: Icons.rocket_launch,
            onTap: () => _showFocusEditor(isBuild: true),
          ),
          const SizedBox(height: 10),
          _buildFocusTile(
            title: 'Self guardrail',
            value: _resolvedSelfFocus,
            color: _selfAccent,
            icon: Icons.favorite_border,
            onTap: () => _showFocusEditor(isBuild: false),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusTile({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit_outlined,
                color: Colors.white.withValues(alpha: 0.32),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillarData() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: <Widget>[
          if (_selectedPillar == _HomePillar.build) ...[
            _buildMetricRow(
              color: _accent,
              label: 'Shipped',
              value: '${_todayBuildLog?.tasksShipped ?? 0} tasks',
              progress: ((_todayBuildLog?.tasksShipped ?? 0) / 5).clamp(
                0.0,
                1.0,
              ),
            ),
            const SizedBox(height: 8),
            _buildMetricRow(
              color: _selfAccent,
              label: 'Users',
              value: (_todayBuildLog?.talkedToUser ?? false)
                  ? 'Talked'
                  : 'None',
              progress: (_todayBuildLog?.talkedToUser ?? false) ? 1.0 : 0.0,
            ),
            const SizedBox(height: 8),
            _buildMetricRow(
              color: Colors.white,
              label: 'Needle',
              value: (_todayBuildLog?.movedNeedle ?? false) ? 'Moved' : 'Stuck',
              progress: (_todayBuildLog?.movedNeedle ?? false) ? 1.0 : 0.0,
            ),
          ] else ...[
            _buildMetricRow(
              color: _accent,
              label: 'Sleep',
              value:
                  '${_todaySelfLog?.sleepHours.toStringAsFixed(1) ?? '0.0'} hrs',
              progress: ((_todaySelfLog?.sleepHours ?? 0) / 8).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 8),
            _buildMetricRow(
              color: _selfAccent,
              label: 'Energy',
              value: _todaySelfLog != null
                  ? <String>[
                      'Low',
                      'Low',
                      'Okay',
                      'Good',
                      'Peak',
                    ][(_todaySelfLog!.energyLevel - 1).clamp(0, 4)]
                  : 'Okay',
              progress: ((_todaySelfLog?.energyLevel ?? 3) / 5).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 8),
            _buildMetricRow(
              color: Colors.white,
              label: 'Budget',
              value: _todaySelfLog != null
                  ? '₹${(_todaySelfLog!.dailyBudget - _todaySelfLog!.moneySpent).toStringAsFixed(0)} left'
                  : '₹${_dailyBudget.toStringAsFixed(0)} left',
              progress: _todaySelfLog != null && _todaySelfLog!.dailyBudget > 0
                  ? (1 -
                            (_todaySelfLog!.moneySpent /
                                _todaySelfLog!.dailyBudget))
                        .clamp(0.0, 1.0)
                  : 1.0,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required Color color,
    required String label,
    required String value,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: <Widget>[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 2,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                tween: Tween<double>(begin: 0, end: progress),
                builder: (context, val, child) {
                  return FractionallySizedBox(
                    widthFactor: val,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaLockerQuickCapture() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'IDEA LOCKER',
                style: TextStyle(
                  color: Color.fromRGBO(255, 255, 255, 0.35),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedTab = _LaunchTab.locker;
                  });
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: Colors.white.withValues(alpha: 0.45),
                ),
                icon: Icon(
                  Icons.lock_outline,
                  color: Colors.white.withValues(alpha: 0.2),
                  size: 14,
                ),
                label: const Text(
                  'View all',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: TextField(
              controller: _ideaController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: "Drop an idea...",
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: InputBorder.none,
                suffixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    iconSize: 18,
                    icon: const Icon(Icons.bolt, color: _backgroundColor),
                    onPressed: () async {
                      final String text = _ideaController.text.trim();
                      if (text.isNotEmpty) {
                        final Idea idea = Idea(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          content: text,
                          createdAt: DateTime.now(),
                        );
                        await _hiveService.saveIdea(idea);
                        if (!mounted) {
                          return;
                        }
                        _ideaController.clear();
                        FocusScope.of(context).unfocus();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: _backgroundColor,
                            content: Text(
                              'Locked in 🔒',
                              style: TextStyle(color: _accent),
                            ),
                          ),
                        );
                        _loadHomeData();
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          if (_recentIdeas.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._recentIdeas.map(
                    (idea) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTab = _LaunchTab.locker;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔒 ', style: TextStyle(fontSize: 10)),
                              Text(
                                idea.content.length > 15
                                    ? '${idea.content.substring(0, 15)}...'
                                    : idea.content,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart() {
    final DateTime now = DateTime.now();
    final DateTime startOfWeek = _startOfWeek(now);
    final List<BarChartGroupData> barGroups = <BarChartGroupData>[];
    final bool isBuild = _selectedPillar == _HomePillar.build;

    for (int i = 0; i < 7; i++) {
      final DateTime d = startOfWeek.add(Duration(days: i));
      final BuildLog? b = _weekBuildLogs
          .where((BuildLog l) => _isSameDay(l.date, d))
          .firstOrNull;
      final SelfLog? s = _weekSelfLogs
          .where((SelfLog l) => _isSameDay(l.date, d))
          .firstOrNull;
      final int sc = isBuild ? (b?.buildScore ?? 0) : (s?.selfScore ?? 0);
      final bool isToday = _isSameDay(d, now);

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: <BarChartRodData>[
            BarChartRodData(
              toY: sc.toDouble(),
              color: isBuild
                  ? _accent.withValues(alpha: isToday ? 1.0 : 0.4)
                  : _selfAccent.withValues(alpha: isToday ? 1.0 : 0.4),
              width: 12,
              borderRadius: BorderRadius.circular(2),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'THIS WEEK',
            style: TextStyle(
              color: Color.fromRGBO(255, 255, 255, 0.35),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 100,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, _) {
                        final List<String> days = <String>[
                          'M',
                          'T',
                          'W',
                          'T',
                          'F',
                          'S',
                          'S',
                        ];
                        final bool isToday = _isSameDay(
                          startOfWeek.add(Duration(days: value.toInt())),
                          now,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[value.toInt()],
                            style: TextStyle(
                              color: isToday
                                  ? (isBuild ? _accent : _selfAccent)
                                  : Colors.white.withValues(alpha: 0.25),
                              fontSize: 11,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 96,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 180,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 36),
              Center(
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 140,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 220,
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        color: _accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ...List<Widget>.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextLogButton() {
    final bool isBuild = _selectedPillar == _HomePillar.build;
    return GestureDetector(
      onTap: () async {
        if (isBuild) {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => const BuildLogScreen()),
          );
        } else {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => const SelfLogScreen()),
          );
        }
        if (mounted) _loadHomeData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          color: isBuild ? _accent : _cardColor,
          borderRadius: BorderRadius.circular(10),
          border: isBuild
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              isBuild ? Icons.rocket_launch : Icons.person_outline,
              color: isBuild ? _backgroundColor : Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              isBuild ? "Log today's build" : 'Log self check-in',
              style: TextStyle(
                color: isBuild ? _backgroundColor : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildPillarSelector(),
                    _buildScoreHero(),
                    _buildTodaySignalCard(),
                    _buildTodayFocusCard(),
                    _buildMetricRowHeader(
                      isBuild: _selectedPillar == _HomePillar.build,
                    ),
                    _buildPillarData(),
                    _buildIdeaLockerQuickCapture(),
                    _buildWeeklyBarChart(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        child: Row(
          children: <Widget>[
            Expanded(child: _buildContextLogButton()),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const AiChatScreen()),
                );
                if (mounted) _loadHomeData();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: _backgroundColor,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRowHeader({required bool isBuild}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        'METRICS',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
